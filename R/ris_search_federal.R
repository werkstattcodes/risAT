# ============================================================================
# ris_search_federal.R — One-call convenience wrapper for federal law search
# ============================================================================
#
# Combines the two-step req/perform pattern into a single call:
#   1. ris_req_federal(...)      — build the httr2 request
#   2. ris_perform_federal(req)  — execute and parse
#
# This is the recommended entry point for interactive/exploratory use; the
# req/perform split is preferred for programmatic pipelines where users want to
# inspect, dry-run, or customize the request object before execution.
# ============================================================================

#' Search Austrian Consolidated Federal Law in RIS
#'
#' Query the Austrian RIS OGD REST API v2.6 `/Bundesrecht` endpoint,
#' application **BrKons** ("Bundesrecht in konsolidierter Fassung",
#' consolidated federal law). This is a convenience wrapper around
#' [ris_req_federal()] and [ris_perform_federal()].
#'
#' Results are fetched iteratively across all pages in scope using
#' `httr2::req_perform_iterative()`.
#'
#' @inheritParams ris_req_federal
#' @inheritParams ris_perform_case_law
#' @param echo Logical. If `TRUE`, prints the equivalent RIS website URLs
#'   (`https://www.ris.bka.gv.at/Bundesrecht/` and the corresponding
#'   `Ergebnis.wxe` query URL) and the number of returned rows, so users can
#'   double-check the result set in the browser.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#' @export
#'
#' @examples
#' \dontrun{
#' # Look up a law by its (short) title
#' ris_search_federal(title = "ABGB")
#'
#' # Full-text search with the consolidated text as it stood on a given date
#' ris_search_federal(query = "Mietzins", version_date = "2020-01-01")
#'
#' # Norms that entered into force within a date range, echoing the browser URL
#' ris_search_federal(
#'   effective_from = "2024-01-01",
#'   effective_to = "2024-12-31",
#'   echo = TRUE
#' )
#' }
ris_search_federal <- function(
  query = NULL,
  title = NULL,
  index = NULL,
  type = NULL,
  law_number = NULL,
  promulgation_organ = NULL,
  promulgation_number = NULL,
  signature_date = NULL,
  version_date = NULL,
  effective_from = NULL,
  effective_to = NULL,
  expiry_from = NULL,
  expiry_to = NULL,
  section_from = NULL,
  section_to = NULL,
  section_type = NULL,
  in_ris_since = NULL,
  sort_by = NULL,
  sort_direction = NULL,
  echo = FALSE,
  max_pages = Inf,
  base_url = ris_base_url()
) {
  # Build the httr2 request with all search parameters.  Validation and
  # normalization happen inside ris_req_federal().
  req <- ris_req_federal(
    query = query,
    title = title,
    index = index,
    type = type,
    law_number = law_number,
    promulgation_organ = promulgation_organ,
    promulgation_number = promulgation_number,
    signature_date = signature_date,
    version_date = version_date,
    effective_from = effective_from,
    effective_to = effective_to,
    expiry_from = expiry_from,
    expiry_to = expiry_to,
    section_from = section_from,
    section_to = section_to,
    section_type = section_type,
    in_ris_since = in_ris_since,
    sort_by = sort_by,
    sort_direction = sort_direction,
    base_url = base_url
  )

  # Execute the request and return the parsed tibble.
  ris_perform_federal(req, echo = echo, max_pages = max_pages)
}
