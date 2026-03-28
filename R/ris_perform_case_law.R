# ============================================================================
# ris_perform_case_law.R — Execute a RIS Judikatur request and parse results
# ============================================================================
#
# This is the second step of the req/perform pattern:
#
#   1. ris_req_case_law()   — build an httr2_request  (ris_req_case_law.R)
#   2. ris_perform_case_law() — execute & parse       (this file)
#
# The RIS API paginates results.  This file also contains three internal
# pagination helpers that are only used here:
#
#   - ris_iterate_case_law_pages()  — drives httr2::req_perform_iterative()
#   - ris_next_case_law_page()      — computes the next page number from
#                                      the API response metadata
#   - ris_bind_case_law_pages()     — rbinds page tibbles, handling the fact
#                                      that different pages may return
#                                      different column sets
# ============================================================================

#' Perform a RIS Case Law Search
#'
#' Execute a request built by [ris_req_case_law()] and return parsed results.
#' All available pages are fetched iteratively using
#' `httr2::req_perform_iterative()`.
#'
#' @param req An `httr2_request` object, typically built with
#'   [ris_req_case_law()].
#' @param echo Logical. If `TRUE`, prints the equivalent RIS website URLs
#'   and the number of returned rows.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#' @export
#'
#' @examples
#' \dontrun{
#' req <- ris_req_case_law(
#'   application = "federal_administrative_court",
#'   query = "Asyl"
#' )
#' results <- ris_perform_case_law(req)
#' }
ris_perform_case_law <- function(req, echo = FALSE) {
  checkmate::assert_flag(echo, .var.name = "echo")

  # -- Step 1: Extract metadata from the request ------------------------------
  # ris_req_case_law() attaches an "ris_meta" attribute containing the
  # application code, page size, and pre-built website URLs.  If this
  # attribute is missing, the request wasn't built by our constructor.
  meta <- attr(req, "ris_meta")
  if (is.null(meta)) {
    rlang::abort(
      "`req` must be built with `ris_req_case_law()` (missing `ris_meta` attribute)."
    )
  }

  application_code <- meta$application_code
  per_page <- meta$per_page
  website_urls <- meta$website_urls

  # When echo = TRUE, print the RIS website URLs so the user can open the
  # same search in a browser to cross-check the results.
  if (isTRUE(echo)) {
    message("RIS application URL: ", website_urls$app_url)
    message("Equivalent RIS search URL: ", website_urls$search_url)
  }

  # -- Step 2: Fetch all pages iteratively ------------------------------------
  # ris_iterate_case_law_pages() wraps httr2::req_perform_iterative() and
  # automatically follows pagination by inspecting each response's page
  # metadata.  It returns a list of httr2_response objects, one per page.
  responses <- ris_iterate_case_law_pages(req)

  # -- Step 3: Parse each page response into a tibble -------------------------
  # ris_parse_search() (from ris_parse_search.R) handles the JSON-to-tibble
  # conversion for a single page.  We tag each row with its page number and
  # page size, then discard empty pages (NULL).
  page_results <- purrr::imap(
    responses,
    function(resp, idx) {
      page_tbl <- ris_parse_search(
        resp,
        requested_page = as.integer(idx),
        requested_per_page = per_page
      )
      if (nrow(page_tbl) == 0L) {
        return(NULL)
      }
      page_tbl$.page_idx <- as.integer(idx)
      page_tbl
    }
  )

  # -- Step 4: Combine pages --------------------------------------------------
  # ris_bind_case_law_pages() handles the non-trivial task of rbinding tibbles
  # that may have different column sets across pages (e.g. a field that only
  # appears in some documents).
  out <- ris_bind_case_law_pages(page_results)

  # -- Step 5: Handle empty results -------------------------------------------
  # Return a zero-row tibble with the expected column structure rather than
  # an unstructured empty tibble.  This ensures downstream code that expects
  # specific columns (content_urls, app_metadata) won't break.
  if (nrow(out) == 0L) {
    empty_out <- tibble::tibble(
      content_urls = list(),
      app_metadata = list()
    )
    attr(empty_out, "ris_app_url") <- website_urls$app_url
    attr(empty_out, "ris_search_url") <- website_urls$search_url
    if (isTRUE(echo)) {
      message("Rows returned: 0")
    }
    return(empty_out)
  }

  # -- Step 6: Enrich app_metadata with request provenance --------------------
  # Each row's app_metadata list-column already contains document-level
  # metadata from the API.  Here we append a `request` sub-list so users
  # can trace which endpoint, application, page, and RIS URLs produced each
  # row.  This is invaluable for debugging and reproducibility.
  out$app_metadata <- purrr::map2(
    out$app_metadata,
    out$.page_idx,
    ~ c(
      .x,
      list(
        request = list(
          endpoint = "/Judikatur",
          application = application_code,
          seitennummer = as.integer(.y),
          dokumente_pro_seite = ris_per_page_to_api_value(per_page),
          ris_app_url = website_urls$app_url,
          ris_search_url = website_urls$search_url
        )
      )
    )
  )

  # Drop the temporary page index column used for app_metadata enrichment.
  out$.page_idx <- NULL

  # Attach RIS URLs as top-level attributes on the output tibble for easy
  # programmatic access (e.g. attr(result, "ris_search_url")).
  attr(out, "ris_app_url") <- website_urls$app_url
  attr(out, "ris_search_url") <- website_urls$search_url

  if (isTRUE(echo)) {
    message("Rows returned: ", nrow(out))
  }

  out
}

# ============================================================================
# Internal: pagination helpers
# ============================================================================
# The RIS API paginates via the `Seitennummer` (page number) query parameter.
# The response body includes metadata about the current page and total hit
# count, which we use to determine whether more pages exist.
# ============================================================================

# -- ris_bind_case_law_pages() ------------------------------------------------
# Safely row-bind a list of per-page tibbles into a single tibble.
#
# Challenge: different pages may return different column sets because not all
# API documents contain the same metadata fields.  For example, page 1 might
# have a "Sammlungsnummer" column that page 2 lacks entirely.
#
# Strategy:
#   1. Collect the union of all column names across pages.
#   2. Detect "mixed" columns — columns that are a list in some pages but an
#      atomic vector in others.  These arise when a field is sometimes a
#      single value and sometimes a nested structure.
#   3. Pad missing columns with NA (or list(NA) for mixed-type columns).
#   4. Coerce mixed columns to list everywhere so dplyr::bind_rows() can
#      combine them without type errors.
ris_bind_case_law_pages <- function(page_results) {
  pages <- purrr::discard(page_results, is.null)
  if (length(pages) == 0L) {
    return(tibble::tibble())
  }

  # Determine the superset of all columns across all pages.
  all_cols <- unique(unlist(purrr::map(pages, names), use.names = FALSE))

  # Identify columns where the type is inconsistent across pages (list in
  # some, atomic in others).  These must be coerced to list everywhere.
  mixed_list_cols <- all_cols[purrr::map_lgl(all_cols, function(col) {
    present <- purrr::keep(pages, ~ col %in% names(.x))
    any_list <- any(purrr::map_lgl(present, ~ is.list(.x[[col]])))
    any_non_list <- any(purrr::map_lgl(present, ~ !is.list(.x[[col]])))
    any_list && any_non_list
  })]

  # Normalize every page: add missing columns, enforce consistent column
  # order, and coerce mixed-type columns to list.
  pages <- purrr::map(pages, function(tbl) {
    missing_cols <- setdiff(all_cols, names(tbl))
    for (col in missing_cols) {
      if (col %in% mixed_list_cols) {
        tbl[[col]] <- rep(list(NA), nrow(tbl))
      } else {
        tbl[[col]] <- NA
      }
    }

    tbl <- tbl[, all_cols, drop = FALSE]

    for (col in mixed_list_cols) {
      if (!is.list(tbl[[col]])) {
        tbl[[col]] <- as.list(tbl[[col]])
      }
    }

    tbl
  })

  dplyr::bind_rows(pages)
}

# -- ris_iterate_case_law_pages() ---------------------------------------------
# Drives pagination using httr2::req_perform_iterative().
#
# The `next_req` callback inspects each API response to determine if another
# page exists.  If so, it modifies the request's `Seitennummer` parameter
# and returns the updated request; otherwise it returns NULL to stop iteration.
#
# max_reqs = Inf means we fetch *all* pages (the RIS API may return hundreds
# for broad queries).  progress = FALSE suppresses httr2's built-in progress
# bar since we may add our own later.
ris_iterate_case_law_pages <- function(req) {
  httr2::req_perform_iterative(
    req = req,
    next_req = function(resp, req) {
      payload <- httr2::resp_body_json(resp, simplifyVector = FALSE)
      root <- ris_extract_root(payload)
      ris_stop_on_api_error(root)

      next_page <- ris_next_case_law_page(root)
      if (is.null(next_page)) {
        return(NULL)
      }

      httr2::req_url_query(req, Seitennummer = as.integer(next_page))
    },
    max_reqs = Inf,
    progress = TRUE
  )
}

# -- ris_next_case_law_page() -------------------------------------------------
# Computes the next page number from the parsed API response root, or returns
# NULL if we've reached the last page.
#
# The API response includes:
#   - page_number: current 1-based page index
#   - page_size:   number of results per page
#   - total_hits:  total number of matching documents
#
# We calculate total_pages = ceil(total_hits / page_size) and check whether
# the current page_number has reached it.  Various edge cases (NA values,
# zero hits, page_size < 1) all return NULL to stop pagination.
ris_next_case_law_page <- function(root) {
  page_info <- ris_extract_page_info(root)
  total_hits <- ris_extract_hits_count(root)

  if (
    is.na(page_info$page_number) ||
      is.na(page_info$page_size) ||
      page_info$page_size < 1L
  ) {
    return(NULL)
  }
  if (is.na(total_hits) || total_hits <= 0L) {
    return(NULL)
  }

  total_pages <- as.integer(max(1L, ceiling(total_hits / page_info$page_size)))
  if (page_info$page_number >= total_pages) {
    return(NULL)
  }

  as.integer(page_info$page_number + 1L)
}
