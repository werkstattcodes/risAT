# ============================================================================
# ris_search_dsk.R — Court-specific wrapper for Dsk (data protection authorities)
# ============================================================================
#
# The Dsk application covers three successive Austrian data protection bodies:
#   - Datenschutzkommission (DSK), 1990–2013
#   - Datenschutzbehörde (DSB), since 1 January 2014
#   - Parlamentarisches Datenschutzkomitee (PDK), since 2025
#
# The `deciding_authority` parameter can filter to a specific body.
#
# Decision types (Entscheidungsart) for Dsk:
#   "Undefined",
#   "BescheidBeschwerde",
#   "BescheidAmtswegigesPruefverfahren",
#   "VerwaltungsstraferkenntnisVerwarnungErmahnung",
#   "BescheidWissenschaftStatistikArchiv",
#   "BescheidInternatDatenverkehr",
#   "BescheidAkkreditierungZertifizierung",
#   "BescheidVerhaltensregeln",
#   "BescheidWarnung",
#   "BescheidRegistrierung",
#   "BescheidSonstiger",
#   "Empfehlung",
#   "BescheidIFG",
#   "Verfahrensschriftsaetze"
# ============================================================================

#' Search Data Protection Authority Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Dsk"`.
#'
#' Covers decisions of Austria's data protection authorities:
#' the Datenschutzkommission (DSK, 1990–2013), the Datenschutzbehörde
#' (DSB, since 2014), and the Parlamentarisches Datenschutzkomitee
#' (PDK, since 2025).
#'
#' @inheritParams ris_search_case_law
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   Dsk accepts (pass the string exactly as shown):
#'   `"Undefined"`, `"BescheidBeschwerde"`,
#'   `"BescheidAmtswegigesPruefverfahren"`,
#'   `"VerwaltungsstraferkenntnisVerwarnungErmahnung"`,
#'   `"BescheidWissenschaftStatistikArchiv"`,
#'   `"BescheidInternatDatenverkehr"`,
#'   `"BescheidAkkreditierungZertifizierung"`,
#'   `"BescheidVerhaltensregeln"`, `"BescheidWarnung"`,
#'   `"BescheidRegistrierung"`, `"BescheidSonstiger"`,
#'   `"Empfehlung"`, `"BescheidIFG"`, `"Verfahrensschriftsaetze"`.
#' @param deciding_authority Optional filter for the deciding body
#'   (`EntscheidendeBehoerde`), e.g. `"Datenschutzbehörde"`.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#'
#' @examples
#' \dontrun{
#' # Search across all data protection authority decisions
#' ris_search_dsk(query = "Videoüberwachung")
#'
#' # GDPR-era DSB decisions only
#' ris_search_dsk(
#'   query = "DSGVO",
#'   decision_date_from = "2018-05-25"
#' )
#'
#' # Filter to a specific decision type
#' ris_search_dsk(decision_type = "BescheidBeschwerde")
#'
#' # Filter by deciding authority (DSB since 2014)
#' ris_search_dsk(
#'   query = "Auskunftsrecht",
#'   deciding_authority = "Datenschutzbehörde"
#' )
#'
#' # Decisions added to RIS within the last six months
#' ris_search_dsk(in_ris_since = "six_months")
#' }
#' @export
ris_search_dsk <- function(
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
    application = "Dsk",
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
