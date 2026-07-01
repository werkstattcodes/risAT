# ============================================================================
# ris_perform_federal.R — Execute a RIS Bundesrecht request and parse results
# ============================================================================
#
# Second step of the req/perform pattern for consolidated federal law:
#
#   1. ris_req_federal()     — build an httr2_request  (ris_req_federal.R)
#   2. ris_perform_federal() — execute & parse          (this file)
#
# Because the /Bundesrecht response uses the same paginated envelope as
# /Judikatur, this reuses the generic, application-agnostic pagination helpers
# from ris_perform_case_law.R (ris_iterate_case_law_pages(),
# ris_next_case_law_page(), ris_bind_case_law_pages()).  Only the per-page
# parser (ris_parse_federal()) and request provenance differ.
# ============================================================================

#' Perform a RIS Bundesrecht Search
#'
#' Execute a request built by [ris_req_federal()] and return parsed results.
#' Pages are fetched iteratively using `httr2::req_perform_iterative()`,
#' up to `max_pages` pages.
#'
#' @param req An `httr2_request` object, typically built with
#'   [ris_req_federal()].
#' @param echo Logical. If `TRUE`, prints the equivalent RIS website URLs
#'   and the number of returned rows.
#' @inheritParams ris_perform_case_law
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#' @export
#'
#' @examples
#' \dontrun{
#' req <- ris_req_federal(title = "ABGB")
#' results <- ris_perform_federal(req)
#' }
ris_perform_federal <- function(req, echo = FALSE, max_pages = Inf) {
  checkmate::assert_flag(echo, .var.name = "echo")
  max_pages <- ris_normalize_max_pages(max_pages)

  # -- Step 1: Extract metadata from the request ------------------------------
  meta <- attr(req, "ris_meta")
  if (is.null(meta)) {
    rlang::abort(
      "`req` must be built with `ris_req_federal()` (missing `ris_meta` attribute)."
    )
  }

  application_code <- meta$application_code
  per_page <- meta$per_page
  endpoint <- meta$endpoint %||% "/Bundesrecht"
  website_urls <- meta$website_urls

  if (isTRUE(echo)) {
    message("RIS application URL: ", website_urls$app_url)
    message("Equivalent RIS search URL: ", website_urls$search_url)
  }

  # -- Step 2: Fetch pages iteratively ----------------------------------------
  # Reuses the generic iterator: it only inspects OgdDocumentResults$Hits,
  # which is identical across RIS applications.
  responses <- ris_iterate_case_law_pages(req, max_pages = max_pages)
  ris_inform_if_truncated(responses, max_pages)

  # -- Step 3: Parse each page response into a tibble -------------------------
  page_results <- purrr::imap(
    responses,
    function(resp, idx) {
      page_tbl <- ris_parse_federal(
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
  out <- ris_bind_case_law_pages(page_results)

  # -- Step 5: Handle empty results -------------------------------------------
  # Zero-row tibble with the guaranteed column structure (id, application,
  # content_urls, app_metadata) so downstream code sees the same schema as
  # for non-empty results.
  if (nrow(out) == 0L) {
    empty_out <- ris_empty_result(website_urls)
    if (isTRUE(echo)) {
      message("Rows returned: 0")
    }
    return(empty_out)
  }

  # -- Step 6: Enrich app_metadata with request provenance --------------------
  out$app_metadata <- purrr::map2(
    out$app_metadata,
    out$.page_idx,
    ~ c(
      .x,
      list(
        request = list(
          endpoint = endpoint,
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

  attr(out, "ris_app_url") <- website_urls$app_url
  attr(out, "ris_search_url") <- website_urls$search_url

  if (isTRUE(echo)) {
    message("Rows returned: ", nrow(out))
  }

  out
}
