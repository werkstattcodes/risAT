# ============================================================================
# ris_search_bvwg.R — Court-specific wrapper for BVwG (Bundesverwaltungsgericht)
# ============================================================================
#
# The Bundesverwaltungsgericht (BVwG) is Austria's Federal Administrative
# Court.  It was established on 1 January 2014 and handles administrative
# matters at the federal level — primarily asylum and immigration law (with
# the Federal Office for Immigration and Asylum, BFA), as well as procurement,
# telecommunications, and other regulatory matters.
#
# The BVwG application shares the same common parameter set as VfGH/VwGH
# (query, norm, business number, dates, decision type, etc.) and does not
# expose any application-specific extra parameters.
#
# Decision types for BVwG: "Undefined", "Beschluss", "Erkenntnis".
# ============================================================================

#' Search BVwG Decisions in RIS
#'
#' Convenience wrapper around [ris_search_case_law()] with
#' `application = "Bvwg"`.
#'
#' The Bundesverwaltungsgericht (BVwG) was established on 1 January 2014 and
#' covers federal administrative matters, including asylum, immigration,
#' procurement, and telecommunications decisions.
#'
#' @inheritParams ris_search_case_law
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   BVwG accepts: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`.
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-column `content_urls`.
#'
#' @examplesIf interactive()
#' # Keyword search across decision texts and Rechtssaetze (default).
#' # The query field supports full-text operators: space/"und" = AND,
#' # "oder" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
#' ris_search_bvwg(query = "Asyl")
#'
#' # Filter to Erkenntnis decisions within a date range
#' ris_search_bvwg(
#'   decision_type = "Erkenntnis",
#'   decision_date_from = "2023-01-01",
#'   decision_date_to = "2023-12-31"
#' )
#'
#' # Search by norm (BVwG frequently applies VwGVG, AsylG 2005, BFA-VG)
#' ris_search_bvwg(norm = "AsylG 2005 §3")
#'
#' # Decisions added to RIS within the last month
#' ris_search_bvwg(in_ris_since = "one_month")
#'
#' # Look up a specific decision by business number and echo the browser URL.
#' # BVwG business number format: "W NNN NNNNNNNN-N/YYYYX" or similar.
#' ris_search_bvwg(business_number = "W175 2221503-1", echo = TRUE)
#' @export
ris_search_bvwg <- function(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  collection_number = NULL,
  in_ris_since = NULL,
  search_decision_text = TRUE,
  search_legal_principles = TRUE,
  echo = FALSE,
  base_url = ris_base_url()
) {
  ris_search_case_law(
    application = "Bvwg",
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    index_term = index_term,
    collection_number = collection_number,
    in_ris_since = in_ris_since,
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles,
    echo = echo,
    base_url = base_url
  )
}
