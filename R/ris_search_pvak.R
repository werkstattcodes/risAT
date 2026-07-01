# ============================================================================
# ris_search_pvak.R — Court-specific wrapper for Pvak (staff representation
#                     oversight authority)
# ============================================================================
#
# The Pvak application covers:
#   - Personalvertretungs-Aufsichtskommission (PVAK), 1999–2013
#   - Personalvertretungsaufsichtsbehörde (PVAB), since 2014
#
# The authority oversees staff representation (Personalvertretung) in the
# Austrian federal public service and issues binding decisions on complaints
# about compliance with the Bundes-Personalvertretungsgesetz (BPVG).
#
# The `deciding_authority` parameter can filter to a specific body.
# ============================================================================

#' Search Staff Representation Oversight Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Pvak"`.
#'
#' Covers decisions of Austria's staff representation oversight bodies: the
#' Personalvertretungs-Aufsichtskommission (PVAK, 1999–2013) and the
#' Personalvertretungsaufsichtsbehörde (PVAB, since 2014).
#'
#' @inheritParams ris_search_case_law
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   Free-text; the API validates server-side.
#' @param deciding_authority Optional filter for the deciding body
#'   (`EntscheidendeBehoerde`), e.g. `"Personalvertretungsaufsichtsbehörde"`.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#'
#' @examples
#' \dontrun{
#' # Search all staff representation oversight decisions
#' ris_search_pvak(query = "Wahlrecht")
#'
#' # Filter to PVAB decisions (since 2014)
#' ris_search_pvak(
#'   deciding_authority = "Personalvertretungsaufsichtsbehörde",
#'   decision_date_from = "2014-01-01"
#' )
#'
#' # Search by norm
#' ris_search_pvak(norm = "BPVG §22")
#' }
#' @export
ris_search_pvak <- function(
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
  max_pages = Inf,
  base_url = ris_base_url()
) {
  checkmate::assert_string(
    deciding_authority,
    null.ok = TRUE,
    .var.name = "deciding_authority"
  )

  ris_search_case_law(
    application = "Pvak",
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
    max_pages = max_pages,
    base_url = base_url
  )
}
