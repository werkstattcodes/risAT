# ============================================================================
# ris_search_justiz.R — Court-specific wrapper for Justiz (ordinary courts)
# ============================================================================
#
# The Justiz application covers decisions from Austria's ordinary courts:
#   - Oberster Gerichtshof (OGH) — Supreme Court (civil & criminal)
#   - Oberlandesgerichte (OLG) — Courts of Appeal
#   - Landesgerichte (LG) — Regional Courts
#   - Bezirksgerichte (BG) — District Courts
#   - Oberster Patent- und Markensenat (OPMS, until end of 2013)
#   - Foreign decisions (AUSL)
#
# The Justiz application has the richest parameter set of all Judikatur
# applications.  In addition to the common parameters shared with VfGH/VwGH,
# it exposes court-specific filters for legal area, specialist area, the
# specific court, legal principle number, legal assessment, ruling text,
# citation, and a "changes since" time window.
#
# Decision type values (Entscheidungsart) for Justiz are German phrases, not
# single words:
#   "Ordentliche Erledigung (Sachentscheidung)"
#   "Zurückweisung mangels erheblicher Rechtsfrage"
#   "Zurückweisung aus anderen Gründen"
#   "Verstärkter Senat"
# ============================================================================

#' Search Justiz Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Justiz"`.
#'
#' Covers decisions from the Oberster Gerichtshof (OGH), Oberlandesgerichte
#' (OLG), Landesgerichte (LG), Bezirksgerichte (BG), Oberster Patent- und
#' Markensenat (OPMS, until 2013), and selected foreign decisions (AUSL).
#'
#' @inheritParams ris_search_case_law
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   Justiz accepts (pass the string exactly as shown):
#'   `"Ordentliche Erledigung (Sachentscheidung)"`,
#'   `"Zurückweisung mangels erheblicher Rechtsfrage"`,
#'   `"Zurückweisung aus anderen Gründen"`,
#'   `"Verstärkter Senat"`.
#' @param legal_area Optional legal area filter (`Rechtsgebiet`), e.g.
#'   `"Zivilrecht"` or `"Strafrecht"`.
#' @param specialist_area Optional specialist area (`Fachgebiet`), e.g.
#'   `"Arbeitsrecht"` or `"Mietrecht"`.
#' @param court Optional court name (`Gericht`), e.g. `"OGH"`, `"OLG Wien"`.
#' @param legal_principle_number Optional legal principle number
#'   (`Rechtssatznummer`), e.g. `"0000001"`.
#' @param legal_assessment Optional legal assessment text
#'   (`RechtlicheBeurteilung`).
#' @param ruling Optional ruling text (`Spruch`).
#' @param citation Optional citation reference (`Fundstelle`),
#'   e.g. `"SZ 75/123"`.
#' @param changed_since_period Optional time window for changes
#'   (`AenderungenSeitPeriode`). Same interval keywords as `in_ris_since`.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-column `content_urls`.
#'
#' @examplesIf interactive()
#' # Keyword search across decision texts and Rechtssaetze (default).
#' # The query field supports full-text operators: space/"und" = AND,
#' # "OR"/"ODER" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
#' ris_search_justiz(query = "Schadenersatz")
#'
#' # Filter to OGH decisions only
#' ris_search_justiz(query = "Schadenersatz", court = "OGH")
#'
#' # Filter by legal area and date range
#' ris_search_justiz(
#'   legal_area = "Zivilrecht",
#'   decision_date_from = "2022-01-01",
#'   decision_date_to = "2023-12-31"
#' )
#'
#' # Search by legal principle number (Rechtssatznummer)
#' ris_search_justiz(legal_principle_number = "0000001")
#'
#' # Search by citation (Fundstelle)
#' ris_search_justiz(citation = "SZ 75/123")
#'
#' # Search by norm and restrict to OGH decisions in a specialist area
#' ris_search_justiz(
#'   norm = "ABGB §1295",
#'   specialist_area = "Schadenersatzrecht",
#'   court = "OGH"
#' )
#'
#' # Look up a specific OGH case by business number
#' # OGH business number format: "N Ob NNN/YY" or "N Ob N/YYg" etc.
#' ris_search_justiz(business_number = "1Ob1/23g", echo = TRUE)
#' @export
ris_search_justiz <- function(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  legal_area = NULL,
  specialist_area = NULL,
  court = NULL,
  legal_principle_number = NULL,
  legal_assessment = NULL,
  ruling = NULL,
  citation = NULL,
  changed_since_period = NULL,
  in_ris_since = NULL,
  search_decision_text = TRUE,
  search_legal_principles = TRUE,
  echo = FALSE,
  base_url = ris_base_url()
) {
  checkmate::assert_string(legal_area, null.ok = TRUE, .var.name = "legal_area")
  checkmate::assert_string(
    specialist_area,
    null.ok = TRUE,
    .var.name = "specialist_area"
  )
  checkmate::assert_string(court, null.ok = TRUE, .var.name = "court")
  checkmate::assert_string(
    legal_principle_number,
    null.ok = TRUE,
    .var.name = "legal_principle_number"
  )
  checkmate::assert_string(
    legal_assessment,
    null.ok = TRUE,
    .var.name = "legal_assessment"
  )
  checkmate::assert_string(ruling, null.ok = TRUE, .var.name = "ruling")
  checkmate::assert_string(citation, null.ok = TRUE, .var.name = "citation")

  ris_search_case_law(
    application = "Justiz",
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    index_term = index_term,
    legal_area = legal_area,
    specialist_area = specialist_area,
    court = court,
    legal_principle_number = legal_principle_number,
    legal_assessment = legal_assessment,
    ruling = ruling,
    citation = citation,
    changed_since_period = changed_since_period,
    in_ris_since = in_ris_since,
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles,
    echo = echo,
    base_url = base_url
  )
}
