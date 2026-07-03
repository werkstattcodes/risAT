# ============================================================================
# ris_search_case_law.R — One-call convenience wrapper for case law search
# ============================================================================
#
# This function combines the two-step req/perform pattern into a single call
# for users who don't need to inspect or modify the request before execution.
#
# Under the hood it simply calls:
#   1. ris_req_case_law(...)      — build the httr2 request
#   2. ris_perform_case_law(req)  — execute and parse
#
# All parameters are forwarded verbatim.  This is the recommended entry point
# for interactive/exploratory use; the req/perform split is preferred for
# programmatic pipelines where users want to inspect, dry-run, or customize
# the request object before execution.
# ============================================================================

#' Search Austrian Case Law in RIS
#'
#' Query the Austrian RIS OGD REST API v2.6 endpoint `/Judikatur`.
#' This is a convenience wrapper around [ris_req_case_law()] and
#' [ris_perform_case_law()].
#'
#' Results are fetched iteratively across all pages in scope using
#' `httr2::req_perform_iterative()`.
#'
#' @inheritParams ris_req_case_law
#' @inheritParams ris_perform_case_law
#' @param echo Logical. If `TRUE`, prints the equivalent RIS website URLs
#'   (`https://www.ris.bka.gv.at/<Applikation>/` and the corresponding
#'   `Ergebnis.wxe` query URL) and the number of returned rows, so users can
#'   double-check the result set in the browser.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-column `content_urls`.
#' @export
#'
#' @examples
#' \dontrun{
#' ris_search_case_law(
#'   application = "federal_administrative_court",
#'   query = "Asyl"
#' )
#' }
ris_search_case_law <- function(
  application,
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  collection_number = NULL,
  title = NULL,
  document_kind = NULL,
  publication_organ = NULL,
  legal_area = NULL,
  specialist_area = NULL,
  court = NULL,
  legal_principle_number = NULL,
  legal_assessment = NULL,
  ruling = NULL,
  citation = NULL,
  changed_since_period = NULL,
  federal_state = NULL,
  deciding_authority = NULL,
  commission = NULL,
  senate = NULL,
  discrimination_ground = NULL,
  author = NULL,
  short_title = NULL,
  domain = NULL,
  in_ris_since = NULL,
  search_decision_text = NULL,
  search_legal_principles = NULL,
  sort_by = "Datum",
  sort_direction = "Descending",
  echo = FALSE,
  max_pages = Inf,
  base_url = ris_base_url()
) {
  # Build the httr2 request with all search parameters.  Validation and
  # normalization happen inside ris_req_case_law().
  req <- ris_req_case_law(
    application = application,
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    index_term = index_term,
    collection_number = collection_number,
    title = title,
    document_kind = document_kind,
    publication_organ = publication_organ,
    legal_area = legal_area,
    specialist_area = specialist_area,
    court = court,
    legal_principle_number = legal_principle_number,
    legal_assessment = legal_assessment,
    ruling = ruling,
    citation = citation,
    changed_since_period = changed_since_period,
    federal_state = federal_state,
    deciding_authority = deciding_authority,
    commission = commission,
    senate = senate,
    discrimination_ground = discrimination_ground,
    author = author,
    short_title = short_title,
    domain = domain,
    in_ris_since = in_ris_since,
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles,
    sort_by = sort_by,
    sort_direction = sort_direction,
    base_url = base_url
  )

  # Execute the request and return the parsed tibble.
  ris_perform_case_law(req, echo = echo, max_pages = max_pages)
}
