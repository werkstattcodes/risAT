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
#'   The `decision_date` column, when present, is parsed to `Date`.
#' @importFrom rlang %||%
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
#'   )
#' )
#' ris_parse_search(payload)
ris_parse_search <- function(
  x,
  requested_page = NULL,
  requested_per_page = NULL
) {
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
    return(ris_empty_result())
  }

  rows <- purrr::map(
    document_refs,
    \(doc) ris_reference_to_tibble_row(doc, response_meta)
  )

  out <- ris_bind_rows_harmonized(rows)
  ris_parse_date_columns(out, "decision_date")
}

ris_as_payload <- function(x) {
  if (inherits(x, "httr2_response")) {
    return(httr2::resp_body_json(x, simplifyVector = FALSE))
  }
  if (is.list(x)) {
    return(x)
  }
  rlang::abort(
    "`x` must be an `httr2_response` or a list.",
    class = "risat_invalid_argument"
  )
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
  rlang::abort(
    paste0("RIS API error [", application, "]: ", message),
    class = "risat_api_error"
  )
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
  # Hits may be absent, or a bare scalar count without page attributes
  # (`$` would error on an atomic vector).
  if (is.null(hits) || !is.list(hits)) {
    return(list(page_number = NULL, page_size = NULL))
  }

  page_number <- hits$pageNumber %||%
    hits$PageNumber %||%
    hits$`@pageNumber` %||%
    NULL
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

  # The API may serialize Hits as a bare scalar count; check this before any
  # `$` access, which errors on atomic vectors.
  if (is.atomic(hits)) {
    if (length(hits) == 1L) {
      return(suppressWarnings(as.integer(hits)))
    }
    return(NA_integer_)
  }

  candidates <- c(
    hits$Count %||% NULL,
    hits$value %||% NULL,
    hits$`#text` %||% NULL
  )

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

  # Drop XML serialization artifact columns before building the row.
  metadata_flat <- metadata_flat[!names(metadata_flat) %in% ris_columns_to_drop]

  # Translate German snake_case names to English.  make.unique() guards
  # against two source fields translating to the same English name (e.g.
  # Entscheidungsdatum appearing under both Allgemein and Judikatur).
  names(metadata_flat) <- make.unique(
    ris_translate_column_names(names(metadata_flat))
  )

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
      "\u00c4" = "Ae",
      "\u00d6" = "Oe",
      "\u00dc" = "Ue",
      "\u00e4" = "ae",
      "\u00f6" = "oe",
      "\u00fc" = "ue",
      "\u00df" = "ss"
    )) |>
    stringr::str_replace_all("([a-z0-9])([A-Z])", "\\1_\\2") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "_") |>
    stringr::str_replace_all("^_+|_+$", "")
}

# ============================================================================
# Column name translation: German snake_case -> English
# ============================================================================
# The RIS API returns metadata in German.  After flattening and converting to
# snake_case, we rename columns to English for a user-friendly tibble.
# Columns not in this map are returned as-is (preserving the snake_case form).
# The two XML serialization artifact columns are dropped entirely.

# Named vector: names = German snake_case, values = English name
ris_column_name_map <- c(
  # -- Common columns (most/all applications) --
  technisch_id = "id",
  technisch_applikation = "application",
  technisch_organ = "authority",
  allgemein_veroeffentlicht = "published",
  allgemein_geaendert = "modified",
  allgemein_dokument_url = "document_url",
  allgemein_titel = "title",
  allgemein_gericht = "court",
  allgemein_entscheidungsdatum = "decision_date",
  judikatur_dokumenttyp = "document_type",
  judikatur_geschaeftszahl_item = "case_number",
  judikatur_normen_item = "norms",
  judikatur_entscheidungsdatum = "decision_date",
  judikatur_schlagworte = "keywords",
  judikatur_european_case_law_identifier = "ecli",
  judikatur_gesamte_entscheidung_url = "full_decision_url",
  judikatur_rechtssaetze_url = "legal_principles_url",
  judikatur_entscheidungstext_url = "decision_text_url",

  # -- VwGH --
  judikatur_vwgh_entscheidungsart = "vwgh_decision_type",
  judikatur_vwgh_gericht = "vwgh_court",
  judikatur_vwgh_indizes_item = "vwgh_indices",
  judikatur_vwgh_sammlungsnummer = "vwgh_collection_number",
  judikatur_vwgh_dokumentnummer_typ = "vwgh_document_number_type",
  judikatur_vwgh_stammrechtssatznummer = "vwgh_primary_legal_principle_number",
  judikatur_vwgh_rechtssatznummer = "vwgh_legal_principle_number",
  judikatur_vwgh_hinweis_auf_stammrechtssatz = "vwgh_primary_principle_reference",
  judikatur_vwgh_rechtssatzkette_url = "vwgh_legal_principle_chain_url",
  judikatur_vwgh_beachte = "vwgh_note",
  judikatur_vwgh_gerichtsentscheidungen_item = "vwgh_court_decisions",

  # -- VfGH --
  judikatur_vfgh_entscheidungsart = "vfgh_decision_type",
  judikatur_vfgh_gericht = "vfgh_court",
  judikatur_vfgh_indizes_item = "vfgh_indices",
  judikatur_vfgh_sammlungsnummer = "vfgh_collection_number",
  judikatur_vfgh_leitsatz = "vfgh_headnote",
  judikatur_vfgh_entscheidungstexte_item = "vfgh_decision_texts",
  judikatur_vfgh_entscheidungstexte_item_geschaeftszahl = "vfgh_decision_text_case_number",
  judikatur_vfgh_entscheidungstexte_item_dokumenttyp = "vfgh_decision_text_document_type",
  judikatur_vfgh_entscheidungstexte_item_gericht = "vfgh_decision_text_court",
  judikatur_vfgh_entscheidungstexte_item_entscheidungsdatum = "vfgh_decision_text_decision_date",
  judikatur_vfgh_entscheidungstexte_item_dokument_url = "vfgh_decision_text_document_url",
  judikatur_vfgh_entscheidungstexte_item_dokumentnummer = "vfgh_decision_text_document_number",
  judikatur_vfgh_entscheidungstexte_item_entscheidungsart = "vfgh_decision_text_decision_type",

  # -- BVwG --
  judikatur_bvwg_entscheidungsart = "bvwg_decision_type",
  judikatur_bvwg_gericht = "bvwg_court",
  judikatur_bvwg_anmerkung = "bvwg_note",

  # -- LVwG --
  judikatur_lvwg_entscheidungsart = "lvwg_decision_type",
  judikatur_lvwg_gericht = "lvwg_court",
  judikatur_lvwg_indizes_item = "lvwg_indices",
  judikatur_lvwg_bundesland = "lvwg_federal_state",
  judikatur_lvwg_anmerkung = "lvwg_note",
  judikatur_lvwg_rechtssatznummern_item = "lvwg_legal_principle_numbers",

  # -- Justiz --
  judikatur_justiz_entscheidungsart = "justiz_decision_type",
  judikatur_justiz_gericht = "justiz_court",
  judikatur_justiz_rechtsgebiete_item = "justiz_legal_areas",
  judikatur_justiz_fachgebiete_item = "justiz_specialist_areas",
  judikatur_justiz_textnummern_item = "justiz_text_numbers",
  judikatur_justiz_rechtssatznummern_item = "justiz_legal_principle_numbers",
  judikatur_justiz_fundstelle = "justiz_citation",
  judikatur_justiz_anmerkung = "justiz_note",
  judikatur_justiz_entscheidungstexte_item = "justiz_decision_texts",
  judikatur_justiz_entscheidungstexte_item_geschaeftszahl = "justiz_decision_text_case_number",
  judikatur_justiz_entscheidungstexte_item_dokumenttyp = "justiz_decision_text_document_type",
  judikatur_justiz_entscheidungstexte_item_gericht = "justiz_decision_text_court",
  judikatur_justiz_entscheidungstexte_item_entscheidungsart = "justiz_decision_text_decision_type",
  judikatur_justiz_entscheidungstexte_item_entscheidungsdatum = "justiz_decision_text_decision_date",
  judikatur_justiz_entscheidungstexte_item_anmerkung = "justiz_decision_text_note",
  judikatur_justiz_entscheidungstexte_item_dokument_url = "justiz_decision_text_document_url",

  # -- DSK / DSB --
  judikatur_dsk_entscheidungsart = "dsk_decision_type",
  judikatur_dsk_kurzinformation = "dsk_brief_info",
  judikatur_dsk_entscheidende_behoerde = "dsk_deciding_authority",
  judikatur_dsk_anfechtung = "dsk_appeal",
  judikatur_dsk_staat = "dsk_country",
  judikatur_dsk_sprache = "dsk_language",
  judikatur_dsk_zugang = "dsk_access",
  judikatur_dsk_entscheidung_ueber_dsb_dokument = "dsk_decision_on_dsb_document",
  judikatur_dsk_anmerkung = "dsk_note",
  judikatur_dsk_rechtssatznummern_item = "dsk_legal_principle_numbers",

  # -- DOK --
  judikatur_dok_entscheidungsart = "dok_decision_type",
  judikatur_dok_kurzinformation = "dok_brief_info",
  judikatur_dok_entscheidende_behoerde = "dok_deciding_authority",

  # -- GBK --
  judikatur_gbk_entscheidungsart = "gbk_decision_type",
  judikatur_gbk_kommission = "gbk_commission",
  judikatur_gbk_senat = "gbk_senate",
  judikatur_gbk_diskriminierungsgrund = "gbk_discrimination_ground",
  judikatur_gbk_diskriminierungstatbestand = "gbk_discrimination_offense"
)

# Columns to drop entirely (XML serialization artifacts with no user value).
ris_columns_to_drop <- c(
  "technisch_import_timestamp_xsi_nil",
  "technisch_import_timestamp_xmlns_xsi"
)

# Rename columns using the mapping and drop artifact columns.
# Unknown columns are kept with their original snake_case name.
ris_translate_column_names <- function(nms) {
  nms <- nms[!nms %in% ris_columns_to_drop]
  matched <- match(nms, names(ris_column_name_map))
  ifelse(is.na(matched), nms, ris_column_name_map[matched])
}
