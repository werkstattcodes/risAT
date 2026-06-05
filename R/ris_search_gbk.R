# ============================================================================
# ris_search_gbk.R — Court-specific wrapper for Gbk (equal treatment commissions)
# ============================================================================
#
# The Gbk application covers:
#   - Bundes-Gleichbehandlungskommission (Senate I and II) — federal public service
#   - Gleichbehandlungskommission für die Privatwirtschaft (Senate I, II, III) —
#     private sector
#
# Both commissions issue opinions (Gutachten) and individual case review results
# (Einzelfallprüfungsergebnisse).  Decisions are available from 1 January 2014.
#
# Important: the Gbk application does NOT support the search_decision_text /
# search_legal_principles document-type flags (checked via
# ris_case_law_supports_document_type()).  Those parameters are therefore
# intentionally omitted from this wrapper's signature.
#
# Application-specific parameters:
#   commission  — which commission (Bundes-GBK or GBK Privatwirtschaft)
#   senate      — which senate within the commission
#   discrimination_ground — ground of discrimination searched for
#
# Decision types for Gbk:
#   "Undefined", "Einzelfallpruefungsergebnis", "Gutachten"
# ============================================================================

#' Search Equal Treatment Commission Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Gbk"`.
#'
#' Covers anonymised decisions of the Bundes-Gleichbehandlungskommission
#' (Senate I and II) and the Gleichbehandlungskommission für die
#' Privatwirtschaft (Senate I, II, and III) since 1 January 2014.
#'
#' Note: the Gbk application does not support `search_decision_text` or
#' `search_legal_principles` filtering.  Those parameters are not available
#' for this wrapper.
#'
#' @inheritParams ris_search_case_law
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   Gbk accepts: `"Undefined"`, `"Einzelfallpruefungsergebnis"`,
#'   `"Gutachten"`.
#' @param commission Optional commission filter (`Kommission`). Accepted
#'   values: `"Bundes-Gleichbehandlungskommission"` (federal public service)
#'   or `"Gleichbehandlungskommission"` (private sector). Short aliases
#'   `"bundesgbk"`/`"bgbk"` and `"gbk"`, and English aliases `"federal"`/
#'   `"private_sector"` are also accepted (case-insensitive).
#' @param senate Optional senate filter (`Senat`). Accepted values:
#'   `"Senat I"`, `"Senat II"`, `"Senat III"`. Roman numerals (`"I"`,
#'   `"II"`, `"III"`) and digits (`"1"`, `"2"`, `"3"`) are also accepted.
#' @param discrimination_ground Optional discrimination ground
#'   (`Diskriminierungsgrund`). Accepted values: `"Geschlecht"`,
#'   `"Ethnische Zugehörigkeit"`, `"Religion"`, `"Weltanschauung"`,
#'   `"Alter"`, `"Sexuelle Orientierung"`, `"Behinderung"`,
#'   `"Mehrfachdiskriminierung"`. English aliases (`"gender"`, `"age"`,
#'   `"disability"`, `"ethnicity"`, `"sexual_orientation"`, etc.) are
#'   also accepted (case-insensitive).
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#'
#' @examples
#' \dontrun{
#' # Search all equal treatment commission decisions
#' ris_search_gbk(query = "Diskriminierung")
#'
#' # Filter to opinions (Gutachten) on gender discrimination
#' ris_search_gbk(
#'   decision_type = "Gutachten",
#'   discrimination_ground = "Geschlecht"
#' )
#'
#' # Filter to individual case review results in the private sector commission
#' ris_search_gbk(
#'   decision_type = "Einzelfallpruefungsergebnis",
#'   commission = "Gleichbehandlungskommission"
#' )
#'
#' # Search by norm and senate
#' ris_search_gbk(
#'   norm = "GlBG §17",
#'   senate = "Senat I"
#' )
#' }
#' @export
ris_search_gbk <- function(
    query = NULL,
    business_number = NULL,
    norm = NULL,
    decision_date_from = NULL,
    decision_date_to = NULL,
    decision_type = NULL,
    commission = NULL,
    senate = NULL,
    discrimination_ground = NULL,
    in_ris_since = NULL,
    echo = FALSE,
    base_url = "https://data.bka.gv.at/ris/api/v2.6"
) {
  commission           <- ris_normalize_gbk_commission(commission)
  senate               <- ris_normalize_gbk_senate(senate)
  discrimination_ground <- ris_normalize_gbk_discrimination_ground(discrimination_ground)

  ris_search_case_law(
    application = "Gbk",
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    commission = commission,
    senate = senate,
    discrimination_ground = discrimination_ground,
    in_ris_since = in_ris_since,
    echo = echo,
    base_url = base_url
  )
}
