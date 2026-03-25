#' Parse RIS Search Responses
#'
#' Parse a RIS OGD REST API search response into a tidy tibble.
#' The parser works with either an `httr2_response` object or an already
#' decoded response list.
#'
#' @param x An `httr2_response` or a decoded list.
#' @param requested_page Optional requested page number for metadata fallback.
#' @param requested_per_page Optional requested page size for metadata fallback.
#'
#' @return A tibble parsed from one RIS response payload.
#'   Includes list-columns `content_urls` and `app_metadata`.
#' @export
#'
#' @examples
#' payload <- list(
#'   OgdSearchResult = list(
#'     status = "ok",
#'     OgdDocumentResults = list(
#'       OgdDocumentReference = list(
#'         list(
#'           Data = list(
#'             Metadaten = list(
#'               Technisch = list(ID = "DOC-1", Applikation = "Vwgh"),
#'               Allgemein = list(DokumentUrl = "https://example.org/meta/1")
#'             ),
#'             Dokumentliste = list(
#'               ContentReference = list(
#'                 list(
#'                   Urls = list(
#'                     ContentUrl = list(
#'                       list(DataType = "Html", Url = "https://example.org/doc/1.html")
#'                     )
#'                   )
#'                 )
#'               )
#'             )
#'           )
#'         )
#'       )
#'     )
#'   ),
#' )
#' ris_parse_search(payload)
ris_parse_search <- function(x, requested_page = NULL, requested_per_page = NULL) {
  payload <- ris_as_payload(x)
  root <- ris_extract_root(payload)
  ris_stop_on_api_error(root)

  document_refs <- ris_extract_document_references(root)
  page_info <- ris_extract_page_info(root)
  response_meta <- list(
    status = root$status %||% root$Status %||% NA_character_,
    hits = ris_extract_hits_count(root),
    page_number = page_info$page_number %||% requested_page,
    page_size = page_info$page_size %||% requested_per_page
  )

  if (length(document_refs) == 0L) {
    return(
      tibble::tibble(
        content_urls = list(),
        app_metadata = list()
      )
    )
  }

  rows <- purrr::map(document_refs, ~ ris_reference_to_tibble_row(.x, response_meta))

  ris_bind_rows_harmonized(rows)
}

ris_as_payload <- function(x) {
  if (inherits(x, "httr2_response")) {
    return(httr2::resp_body_json(x, simplifyVector = FALSE))
  }
  if (is.list(x)) {
    return(x)
  }
  stop("`x` must be an `httr2_response` or a list.", call. = FALSE)
}

ris_extract_root <- function(payload) {
  if (is.list(payload$OgdSearchResult)) {
    return(payload$OgdSearchResult)
  }
  payload
}

ris_stop_on_api_error <- function(root) {
  err <- root$Error
  if (!is.list(err) || length(err) == 0L) {
    return(invisible(TRUE))
  }

  application <- err$Applikation %||% "Unknown"
  message <- err$Message %||% "Unknown RIS API error."
  stop(paste0("RIS API error [", application, "]: ", message), call. = FALSE)
}

ris_extract_document_references <- function(root) {
  refs <- root$OgdDocumentResults$OgdDocumentReference

  if (is.null(refs)) {
    return(list())
  }

  if (is.list(refs) && !is.null(names(refs))) {
    if ("Data" %in% names(refs)) {
      return(list(refs))
    }
    if (all(purrr::map_lgl(refs, is.list))) {
      return(unname(refs))
    }
  }

  if (is.list(refs) && is.null(names(refs))) {
    return(refs)
  }

  list()
}

ris_extract_page_info <- function(root) {
  hits <- root$OgdDocumentResults$Hits
  if (is.null(hits)) {
    return(list(page_number = NULL, page_size = NULL))
  }

  page_number <- hits$pageNumber %||% hits$PageNumber %||% hits$`@pageNumber` %||% NULL
  page_size <- hits$pageSize %||% hits$PageSize %||% hits$`@pageSize` %||% NULL

  list(
    page_number = suppressWarnings(as.integer(page_number)),
    page_size = suppressWarnings(as.integer(page_size))
  )
}

ris_extract_hits_count <- function(root) {
  hits <- root$OgdDocumentResults$Hits
  if (is.null(hits)) {
    return(NA_integer_)
  }

  candidates <- c(
    hits$Count %||% NULL,
    hits$value %||% NULL,
    hits$`#text` %||% NULL
  )

  if (is.atomic(hits) && length(hits) == 1L) {
    return(suppressWarnings(as.integer(hits)))
  }

  value <- purrr::detect(candidates, ~ !is.null(.x))
  if (is.null(value)) {
    return(NA_integer_)
  }

  suppressWarnings(as.integer(value))
}

ris_reference_to_tibble_row <- function(reference, response_meta) {
  data <- reference$Data %||% list()
  metadata <- data$Metadaten %||% list()
  metadata_flat <- ris_flatten_named_list(metadata)
  metadata_flat <- purrr::modify(metadata_flat, ~ if (is.null(.x)) NA else .x)

  if (length(metadata_flat) == 0L) {
    metadata_flat <- list()
  }

  if (is.null(names(metadata_flat)) || any(names(metadata_flat) == "")) {
    names(metadata_flat) <- paste0("field_", seq_along(metadata_flat))
  }

  names(metadata_flat) <- make.unique(ris_to_snake_case(names(metadata_flat)))
  metadata_flat <- purrr::modify(metadata_flat, ris_to_scalar_or_list)

  row <- tibble::as_tibble_row(metadata_flat, .name_repair = "minimal")
  row$content_urls <- list(ris_extract_content_urls(data$Dokumentliste))
  row$app_metadata <- list(
    list(
      response = response_meta,
      technisch = metadata$Technisch %||% list(),
      allgemein = metadata$Allgemein %||% list()
    )
  )
  row
}

ris_bind_rows_harmonized <- function(rows) {
  if (length(rows) == 0L) {
    return(tibble::tibble())
  }

  all_cols <- unique(unlist(purrr::map(rows, names), use.names = FALSE))
  list_cols <- all_cols[purrr::map_lgl(all_cols, function(col) {
    any(purrr::map_lgl(rows, ~ col %in% names(.x) && is.list(.x[[col]])))
  })]

  rows <- purrr::map(rows, function(row) {
    missing_cols <- setdiff(all_cols, names(row))
    for (col in missing_cols) {
      if (col %in% list_cols) {
        row[[col]] <- list(NA)
      } else {
        row[[col]] <- NA
      }
    }

    row <- row[, all_cols, drop = FALSE]

    for (col in list_cols) {
      if (!is.list(row[[col]])) {
        row[[col]] <- list(row[[col]][[1L]])
      } else if (length(row[[col]]) == 0L) {
        row[[col]] <- list(NA)
      }
    }

    row
  })

  dplyr::bind_rows(rows)
}

ris_extract_content_urls <- function(dokumentliste) {
  if (!is.list(dokumentliste)) {
    return(character())
  }

  refs <- dokumentliste$ContentReference
  if (is.null(refs)) {
    return(character())
  }

  ref_list <- ris_normalize_list_of_records(refs)
  if (length(ref_list) == 0L) {
    return(character())
  }

  urls <- purrr::map(ref_list, function(ref) {
    content <- ref$Urls$ContentUrl
    entries <- ris_normalize_list_of_records(content)
    if (length(entries) == 0L && is.list(content) && !is.null(content$Url)) {
      entries <- list(content)
    }
    purrr::map_chr(entries, ~ as.character(.x$Url %||% NA_character_))
  }) |>
    unlist(use.names = FALSE)

  unique(stats::na.omit(urls))
}

ris_normalize_list_of_records <- function(x) {
  if (!is.list(x) || length(x) == 0L) {
    return(list())
  }
  if (is.null(names(x))) {
    return(x)
  }
  if (all(purrr::map_lgl(x, is.list))) {
    return(unname(x))
  }
  list(x)
}

ris_flatten_named_list <- function(x, prefix = NULL) {
  if (is.null(x)) {
    return(list())
  }
  if (!is.list(x)) {
    name <- prefix %||% "value"
    return(rlang::set_names(list(x), name))
  }

  out <- list()
  nms <- names(x)
  if (is.null(nms)) {
    nms <- paste0("field_", seq_along(x))
  }
  nms[nms == ""] <- paste0("field_", which(nms == ""))

  for (i in seq_along(x)) {
    name_i <- nms[[i]]
    full_name <- if (is.null(prefix)) name_i else paste0(prefix, "_", name_i)
    value_i <- x[[i]]
    if (is.list(value_i) && !is.null(names(value_i))) {
      out <- c(out, ris_flatten_named_list(value_i, full_name))
    } else {
      out[[full_name]] <- value_i
    }
  }

  out
}

ris_to_scalar_or_list <- function(x) {
  if (is.null(x)) {
    return(NA)
  }
  if (is.atomic(x) && length(x) <= 1L) {
    return(x)
  }
  list(x)
}

ris_to_snake_case <- function(x) {
  x |>
    stringr::str_replace_all(c(
      "Ä" = "Ae", "Ö" = "Oe", "Ü" = "Ue",
      "ä" = "ae", "ö" = "oe", "ü" = "ue",
      "ß" = "ss"
    )) |>
    stringr::str_replace_all("([a-z0-9])([A-Z])", "\\1_\\2") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "_") |>
    stringr::str_replace_all("^_+|_+$", "")
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
