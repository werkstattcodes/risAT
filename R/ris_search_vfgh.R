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
# Results are always sorted by decision date descending (most recent first).
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
#' @inheritParams ris_search_case_law
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   VfGH accepts: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
#'   `"Vergleich"`, `"KeineAngabe"` (English aliases: `"order"`, `"judgment"`,
#'   `"settlement"`, `"not_specified"`).
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-column `content_urls`.
#'
#' @examplesIf interactive()
#' # Search Rechtssaetze (default per VfGH handbook) for a constitutional keyword.
#' # The query field supports full-text operators: space/"und" = AND,
#' # "oder" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
#' ris_search_vfgh(query = "Meinungsfreiheit")
#'
#' # Wildcard and phrase search examples
#' ris_search_vfgh(query = "Grundrecht*")
#' ris_search_vfgh(query = "'wahlwerbenden Parteien'")
#'
#' # Also search full decision texts (overrides the VfGH default of RS only)
#' ris_search_vfgh(
#'   query = "Eigentumsrecht",
#'   search_decision_text = TRUE,
#'   search_legal_principles = TRUE
#' )
#'
#' # Judgments on a specific norm. Results are always sorted by decision date
#' # descending (most recent first).
#' # Norm notation: include the year where it is part of the official
#' # abbreviation (e.g. "StGG Art2", "EStG 1988 §29 Z1", "AsylG 2005 §5").
#' # For multiple norms wrap each in single quotes: 'StGG Art2' oder 'B-VG Art7'
#' ris_search_vfgh(
#'   norm = "B-VG Art7",
#'   decision_type = "judgment"
#' )
#'
#' # Search by Sammlungsnummer (collection number from the official VfGH
#' # series VfSlg). Enter digits only, without dot, space, or slash.
#' ris_search_vfgh(collection_number = "18743")
#'
#' # Decisions added to RIS within the last six months
#' ris_search_vfgh(in_ris_since = "six_months")
#'
#' # Search by Index (numeric classification of Austrian law).
#' # Federal law index values start with a number (e.g. "32/02" for Steuerrecht,
#' # "07/01" for Verfassungsrecht), state law index values start with "L"
#' # (e.g. "L6500"). The full index list is linked from the VfGH search page.
#' ris_search_vfgh(index_term = "07/01")
#'
#' # Look up a specific case by business number and echo the equivalent
#' # browser URL on www.ris.bka.gv.at.
#' # VfGH decisions are available from 1980 in full text; selected decisions
#' # from 1919-1933 and 1946-1979 are available as PDF scans.
#' # Business number formats (four-digit year since 08.04.2013):
#' #   G NNNN/YYYY  (constitutional review of laws, Gesetzesprüfung)
#' #   V NNN/YYYY   (review of ordinances, Verordnungsprüfung)
#' #   U NNN/YYYY   (individual complaint, Art144 B-VG)
#' #   E NNN/YYYY   (complaint under EU Charter of Fundamental Rights)
#' #   B NNN/YY     (old-style individual complaint, pre-2013)
#' ris_search_vfgh(
#'   business_number = "G 97/2021",
#'   echo = TRUE
#' )
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
  search_decision_text = FALSE,
  search_legal_principles = TRUE,
  echo = FALSE,
  base_url = ris_base_url()
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
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles,
    echo = echo,
    base_url = base_url
  )
}
