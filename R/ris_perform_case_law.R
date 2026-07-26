# ============================================================================
# ris_perform_case_law.R — Execute a RIS Judikatur request and parse results
# ============================================================================
#
# This is the second step of the req/perform pattern:
#
#   1. ris_req_case_law()   — build an httr2_request  (ris_req_case_law.R)
#   2. ris_perform_case_law() — execute & parse       (this file)
#
# The RIS API paginates results.  This file also contains internal pagination
# helpers that are only used here:
#
#   - ris_iterate_case_law_pages()  — drives httr2::req_perform_iterative()
#   - ris_case_law_page_status()    — parses/validates page + hit-count
#                                      metadata from a response root
#   - ris_next_case_law_page()      — computes the next page number from
#                                      the API response metadata
#   - ris_report_hit_count()        — echo message reporting total hits and
#                                      page count, emitted after the first page
#   - ris_bind_case_law_pages()     — rbinds page tibbles, handling the fact
#                                      that different pages may return
#                                      different column sets
# ============================================================================

#' Perform a RIS Case Law Search
#'
#' Execute a request built by [ris_req_case_law()] and return parsed results.
#' Pages are fetched iteratively using `httr2::req_perform_iterative()`
#' until all pages in scope have been retrieved.
#'
#' @param req An `httr2_request` object, typically built with
#'   [ris_req_case_law()].
#' @param echo Logical. If `TRUE`, prints two progress messages: the
#'   equivalent RIS website search URL (the `Ergebnis.wxe` query on
#'   `https://www.ris.bka.gv.at`) before any request is sent; and the total
#'   hit and page count as soon as the first page's response arrives. This
#'   lets the result set be double-checked in the browser and gives an early
#'   sense of scope for broad queries without waiting for every page.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-column `content_urls`.
#' @export
#'
#' @examplesIf interactive()
#' req <- ris_req_case_law(
#'   application = "federal_administrative_court",
#'   query = "Asyl"
#' )
#' results <- ris_perform_case_law(req)
ris_perform_case_law <- function(req, echo = FALSE) {
  checkmate::assert_flag(echo, .var.name = "echo")

  ris_perform_ris_search(
    req,
    echo = echo,
    page_parser = ris_parse_search_internal,
    builder_name = "ris_req_case_law"
  )
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
    present <- purrr::keep(pages, \(page) col %in% names(page))
    any_list <- any(purrr::map_lgl(present, \(page) is.list(page[[col]])))
    any_non_list <- any(purrr::map_lgl(present, \(page) !is.list(page[[col]])))
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
# Fetches *all* pages in scope (the RIS API may return hundreds for broad
# queries).  When echo = TRUE, the total hit/page count is reported once, as
# soon as the first page's response metadata is available, rather than
# waiting for every page to be fetched.
ris_iterate_case_law_pages <- function(req, echo = FALSE) {
  reported <- FALSE

  httr2::req_perform_iterative(
    req = req,
    next_req = function(resp, req) {
      payload <- httr2::resp_body_json(resp, simplifyVector = FALSE)
      root <- ris_extract_root(payload)
      ris_stop_on_api_error(root)

      if (echo && !reported) {
        ris_report_hit_count(root)
        reported <<- TRUE
      }

      next_page <- ris_next_case_law_page(root)
      if (is.null(next_page)) {
        return(NULL)
      }

      httr2::req_url_query(req, Seitennummer = as.integer(next_page))
    },
    max_reqs = Inf,
    # Show the pagination progress bar only in interactive sessions so it
    # doesn't pollute knitted documents, logs, or CI output.
    progress = rlang::is_interactive()
  )
}

# -- ris_case_law_page_status() -----------------------------------------------
# Parses and validates the pagination metadata from an API response root:
#   - page_number: current 1-based page index
#   - page_size:   number of results per page
#   - total_hits:  total number of matching documents
#   - total_pages: ceil(total_hits / page_size), or NA when it can't be
#                  computed (missing metadata, zero hits, page_size < 1)
# The metadata fields may be NULL or zero-length when the API omits them, so
# each value is checked for length 1 before is.na().  Shared by
# ris_next_case_law_page() (pagination control) and ris_report_hit_count()
# (echo reporting) so the validity rules live in one place.
ris_case_law_page_status <- function(root) {
  page_info <- ris_extract_page_info(root)
  total_hits <- ris_extract_hits_count(root)

  is_valid_scalar <- function(x) length(x) == 1L && !is.na(x)

  page_number <- page_info$page_number
  if (!is_valid_scalar(page_number)) {
    page_number <- NA_integer_
  }

  page_size <- page_info$page_size
  if (!is_valid_scalar(page_size) || page_size < 1L) {
    page_size <- NA_integer_
  }

  if (!is_valid_scalar(total_hits) || total_hits < 0L) {
    total_hits <- NA_integer_
  }

  total_pages <- if (!is.na(page_size) && !is.na(total_hits) && total_hits > 0L) {
    as.integer(max(1L, ceiling(total_hits / page_size)))
  } else {
    NA_integer_
  }

  list(
    page_number = page_number,
    page_size = page_size,
    total_hits = total_hits,
    total_pages = total_pages
  )
}

# -- ris_next_case_law_page() -------------------------------------------------
# Computes the next page number from the parsed API response root, or returns
# NULL if we've reached the last page (or the metadata needed to tell is
# missing/invalid).
ris_next_case_law_page <- function(root) {
  status <- ris_case_law_page_status(root)

  if (is.na(status$page_number) || is.na(status$total_pages)) {
    return(NULL)
  }
  if (status$page_number >= status$total_pages) {
    return(NULL)
  }

  as.integer(status$page_number + 1L)
}

# -- ris_report_hit_count() ----------------------------------------------------
# Emits an echo message reporting the total hit count (and page count, when
# computable) for a search, using the same pagination metadata as
# ris_next_case_law_page().  Called once, right after the first page's
# response is decoded, so broad queries don't leave the user waiting until
# every page has been fetched to see how many results are in scope.
ris_report_hit_count <- function(root) {
  status <- ris_case_law_page_status(root)

  if (is.na(status$total_hits)) {
    return(invisible(NULL))
  }

  if (is.na(status$total_pages)) {
    message("Total hits: ", status$total_hits)
    return(invisible(NULL))
  }

  message(
    "Total hits: ", status$total_hits,
    " (", status$total_pages,
    " page", if (status$total_pages != 1L) "s" else "", ")"
  )
}
