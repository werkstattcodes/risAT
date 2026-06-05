# ============================================================================
# ris_search_lvwg.R — Court-specific wrapper for LVwG (Landesverwaltungsgerichte)
# ============================================================================
#
# The Landesverwaltungsgerichte (LVwG) are Austria's nine state administrative
# courts, one for each Bundesland.  They were established on 1 January 2014
# as part of the Austrian administrative court reform (Verwaltungsgerichts-
# barkeit-Novelle 2012) that replaced the former Unabhängigen Verwaltungssenate
# (UVS).
#
# The nine courts are:
#   LVwG Burgenland, LVwG Kärnten, LVwG Niederösterreich,
#   LVwG Oberösterreich, LVwG Salzburg, LVwG Steiermark,
#   LVwG Tirol, LVwG Vorarlberg, Verwaltungsgericht Wien (VGW)
#
# The `federal_state` parameter restricts results to a single Bundesland.
# Decision types for LVwG: "Undefined", "Beschluss", "Erkenntnis", "Bescheid".
# ============================================================================

#' Search LVwG Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Lvwg"`.
#'
#' The Landesverwaltungsgerichte (LVwG) are Austria's nine state administrative
#' courts (one per Bundesland), established on 1 January 2014.  Use
#' `federal_state` to restrict results to a specific state.
#'
#' @inheritParams ris_search_case_law
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   LVwG accepts: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
#'   `"Bescheid"`.
#' @param federal_state Optional federal state (`Bundesland`) to restrict
#'   results to a single LVwG. Accepts the German name of any of the nine
#'   Austrian Bundesländer: `"Burgenland"`, `"Kärnten"`,
#'   `"Niederösterreich"`, `"Oberösterreich"`, `"Salzburg"`,
#'   `"Steiermark"`, `"Tirol"`, `"Vorarlberg"`, `"Wien"`. Common English
#'   aliases (`"Vienna"`, `"Styria"`, `"Carinthia"`, etc.) are also accepted
#'   (case-insensitive).
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-columns `content_urls` and `app_metadata`.
#'
#' @examples
#' \dontrun{
#' # Search across all nine LVwG
#' ris_search_lvwg(query = "Baubewilligung")
#'
#' # Restrict to the Verwaltungsgericht Wien (VGW)
#' ris_search_lvwg(query = "Baubewilligung", federal_state = "Wien")
#'
#' # Filter by decision type and state
#' ris_search_lvwg(
#'   decision_type = "Erkenntnis",
#'   federal_state = "Steiermark",
#'   decision_date_from = "2022-01-01"
#' )
#'
#' # Search by norm
#' ris_search_lvwg(norm = "VStG §19")
#'
#' # Decisions added to RIS within the last month
#' ris_search_lvwg(in_ris_since = "one_month", federal_state = "Tirol")
#' }
#' @export
ris_search_lvwg <- function(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  federal_state = NULL,
  in_ris_since = NULL,
  search_decision_text = TRUE,
  search_legal_principles = TRUE,
  echo = FALSE,
  base_url = "https://data.bka.gv.at/ris/api/v2.6"
) {
  federal_state <- ris_normalize_federal_state(federal_state)

  ris_search_case_law(
    application = "Lvwg",
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    index_term = index_term,
    federal_state = federal_state,
    in_ris_since = in_ris_since,
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles,
    echo = echo,
    base_url = base_url
  )
}
