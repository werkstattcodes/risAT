# ============================================================================
# ris_search_dok.R — Court-specific wrapper for Dok (disciplinary bodies)
# ============================================================================
#
# The Dok application covers Austrian federal disciplinary bodies:
#   - Bundesdisziplinarbehörde (BDB), since 1 October 2020
#   - Disziplinarkommissionen (DK), largely until 30 September 2020
#   - Disziplinaroberkommission (DOK), until 2013
#   - Berufungskommission (BK), until 2013
#
# The `deciding_authority` parameter can filter to a specific body or instance.
# ============================================================================

#' Search Disciplinary Body Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Dok"`.
#'
#' Covers decisions of Austrian federal disciplinary bodies: the
#' Bundesdisziplinarbehörde (BDB, since October 2020), the
#' Disziplinarkommissionen (DK, largely until September 2020), the
#' Disziplinaroberkommission (DOK, until 2013), and the Berufungskommission
#' (BK, until 2013).
#'
#' @inheritParams ris_search_case_law
#' @param deciding_authority Optional filter for the deciding body
#'   (`EntscheidendeBehoerde`), e.g. `"Bundesdisziplinarbehörde"`.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#'
#' @examples
#' \dontrun{
#' # Search all disciplinary body decisions
#' ris_search_dok(query = "Dienstpflichtverletzung")
#'
#' # Restrict to the Bundesdisziplinarbehörde (BDB, since Oct 2020)
#' ris_search_dok(
#'   deciding_authority = "Bundesdisziplinarbehörde",
#'   decision_date_from = "2020-10-01"
#' )
#'
#' # Search by norm and date
#' ris_search_dok(
#'   norm = "BDG 1979 §43",
#'   decision_date_from = "2015-01-01"
#' )
#' }
#' @export
ris_search_dok <- function(
    query = NULL,
    business_number = NULL,
    norm = NULL,
    decision_date_from = NULL,
    decision_date_to = NULL,
    decision_type = NULL,
    deciding_authority = NULL,
    in_ris_since = NULL,
    search_decision_text = TRUE,
    search_legal_principles = TRUE,
    echo = FALSE,
    base_url = "https://data.bka.gv.at/ris/api/v2.6"
) {
  ris_search_case_law(
    application = "Dok",
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    deciding_authority = deciding_authority,
    in_ris_since = in_ris_since,
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles,
    echo = echo,
    base_url = base_url
  )
}
