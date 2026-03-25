# ============================================================================
# ris_search_vwgh.R — Court-specific wrapper for VwGH (Verwaltungsgerichtshof)
# ============================================================================
#
# The Verwaltungsgerichtshof (VwGH) is Austria's Supreme Administrative Court.
# This wrapper pre-fills application = "Vwgh" and exposes only the parameters
# relevant to VwGH searches, providing a cleaner interface than the generic
# ris_search_case_law().
#
# Key defaults specific to VwGH:
#   - search_decision_text = TRUE   (search in Entscheidungstexte)
#   - search_legal_principles = TRUE (search in Rechtssaetze)
#
# The VwGH application supports its own set of decision types:
#   "Undefined", "Beschluss", "Erkenntnis", "BeschlussVS", "ErkenntnisVS"
# where "VS" denotes decisions by a Verstaerkter Senat (reinforced senate).
#
# Parameters only meaningful for other applications (e.g. court, legal_area,
# federal_state) are intentionally omitted from this wrapper's signature.
# ============================================================================

#' Search VwGH Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Vwgh"`.
#'
#' `decision_type` for VwGH accepts:
#' `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`, `"BeschlussVS"`,
#' `"ErkenntnisVS"`.
#'
#' @inheritParams ris_search_case_law
#'
#' @return A tidy tibble with parsed search results from all pages in scope.
#'   Includes `page`, `per_page`, and list-columns `content_urls`,
#'   `app_metadata`.
#' @export
ris_search_vwgh <- function(
    query = NULL,
    business_number = NULL,
    norm = NULL,
    decision_date_from = NULL,
    decision_date_to = NULL,
    decision_type = NULL,
    index_term = NULL,
    collection_number = NULL,
    in_ris_since = NULL,
    sort_by = NULL,
    sort_direction = NULL,
    search_decision_text = TRUE,
    search_legal_principles = TRUE,
    per_page = 20L,
    echo = FALSE,
    base_url = "https://data.bka.gv.at/ris/api/v2.6"
) {
  # Delegate to the generic case law search with application fixed to "Vwgh".
  ris_search_case_law(
    application = "Vwgh",
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    index_term = index_term,
    collection_number = collection_number,
    in_ris_since = in_ris_since,
    sort_by = sort_by,
    sort_direction = sort_direction,
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles,
    per_page = per_page,
    echo = echo,
    base_url = base_url
  )
}
