# ============================================================================
# ris_search_vfgh.R — Court-specific wrapper for VfGH (Verfassungsgerichtshof)
# ============================================================================
#
# The Verfassungsgerichtshof (VfGH) is Austria's Constitutional Court.
# This wrapper pre-fills application = "Vfgh" and exposes only the parameters
# relevant to VfGH searches.
#
# Key defaults specific to VfGH (aligned with the official VfGH RIS handbook):
#   - search_decision_text = FALSE   (do NOT search in Entscheidungstexte)
#   - search_legal_principles = TRUE  (search in Rechtssaetze only)
#
# This differs from the VwGH wrapper where both default to TRUE.  The VfGH
# handbook recommends searching Rechtssaetze by default because VfGH legal
# principles (Rechtssaetze) are particularly well-curated and are the primary
# way practitioners look up constitutional jurisprudence.
#
# The VfGH application supports its own set of decision types:
#   "Undefined", "Beschluss", "Erkenntnis", "Vergleich", "KeineAngabe"
# with English aliases: "order", "judgment", "settlement", "not_specified".
#
# sort_by for VfGH/VwGH supports:
#   German: "Geschaeftszahl", "Datum", "Art", "Typ"
#   English: "business_number", "decision_date", "decision_type", "document_type"
# ============================================================================

#' Search VfGH Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Vfgh"`.
#'
#' Defaults are aligned with the VfGH RIS handbook:
#' `search_legal_principles = TRUE` and `search_decision_text = FALSE`
#' (default search in Rechtssaetze).
#'
#' `decision_type` for VfGH accepts:
#' `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`, `"Vergleich"`,
#' `"KeineAngabe"`, and English aliases
#' `"order"`, `"judgment"`, `"settlement"`, `"not_specified"`.
#'
#' `sort_by` for VfGH accepts:
#' `"Geschaeftszahl"`, `"Datum"`, `"Art"`, `"Typ"`,
#' and English aliases
#' `"business_number"`, `"decision_date"`, `"decision_type"`,
#' `"document_type"`.
#'
#' @inheritParams ris_search_case_law
#'
#' @return A tidy tibble with parsed search results from all pages in scope.
#'   Includes `page`, `per_page`, and list-columns `content_urls`,
#'   `app_metadata`.
#' @export
ris_search_vfgh <- function(
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
    search_decision_text = FALSE,
    search_legal_principles = TRUE,
    per_page = 20L,
    echo = FALSE,
    base_url = "https://data.bka.gv.at/ris/api/v2.6"
) {
  # Delegate to the generic case law search with application fixed to "Vfgh".
  ris_search_case_law(
    application = "Vfgh",
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
