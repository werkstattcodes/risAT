# ============================================================================
# ris_bundesrecht_utils.R — Shared internal helpers for the Bundesrecht endpoint
# ============================================================================
#
# Internal (non-exported) utilities used by ris_req_bundesrecht(),
# ris_perform_bundesrecht(), and ris_search_federal().  These mirror the
# Judikatur helpers in ris_case_law_utils.R but target the consolidated federal
# law application "BrKons" served from the /Bundesrecht endpoint.
#
# Organization:
#   1. Parameter builder      — maps R arguments to RIS API query parameters
#   2. Normalization helpers  — Bundesrecht-specific enums (Abschnitt, sort)
#   3. Website URL builder     — constructs the equivalent ris.bka.gv.at URLs
#
# Several generic helpers are reused verbatim from ris_case_law_utils.R rather
# than duplicated, because they are application-agnostic:
#   ris_normalize_date(), ris_per_page_to_api_value(),
#   ris_normalize_named_interval(), ris_normalize_sort_direction(),
#   ris_normalize_key(), ris_url_encode_query(), ris_format_website_date().
#
# Design principle (shared with the Judikatur side): "normalize early, pass
# canonical values downstream."
# ============================================================================

# ============================================================================
# Section 1: API parameter builder
# ============================================================================
# Unlike the flat Judikatur parameters, BrKons exposes a few *complex* query
# parameters whose sub-fields are joined to the parameter name with a "."
# separator (the API's documented <spec> separator), e.g.:
#
#   Fassung.FassungVom, Fassung.VonInkrafttretensdatum,
#   Abschnitt.Von, Abschnitt.Bis, Abschnitt.Typ,
#   Sortierung.SortDirection, Sortierung.SortedByColumn
#
# Parameters that are NULL or empty string are removed so they don't appear in
# the URL — the API treats absent parameters as "no filter".
# ============================================================================

# Map R-friendly argument names to the German API parameter names, normalize
# dates/intervals/enums, and strip NULL/empty values.  The result is a named
# list ready to be spliced into httr2::req_url_query().
ris_build_bundesrecht_params <- function(
  query = NULL,
  title = NULL,
  index = NULL,
  type = NULL,
  law_number = NULL,
  promulgation_organ = NULL,
  promulgation_number = NULL,
  signature_date = NULL,
  version_date = NULL,
  effective_from = NULL,
  effective_to = NULL,
  expiry_from = NULL,
  expiry_to = NULL,
  section_from = NULL,
  section_to = NULL,
  section_type = NULL,
  in_ris_since = NULL,
  sort_by = NULL,
  sort_direction = NULL,
  page = 1L,
  per_page = 100L
) {
  params <- list(
    # -- Fixed application code --
    Applikation = "BrKons",
    # -- Full-text and exact-match search fields --
    Suchworte = query,
    Titel = title,
    Index = index,
    Typ = type,
    Gesetzesnummer = law_number,
    Kundmachungsorgan = promulgation_organ,
    Kundmachungsorgannummer = promulgation_number,
    Unterzeichnungsdatum = ris_normalize_date(signature_date),
    # -- Complex "Fassung" (version) parameter --
    # Either a point-in-time version (FassungVom) OR entry-into-force /
    # expiry date ranges.  Mutual exclusivity is enforced upstream in
    # ris_req_bundesrecht().
    `Fassung.FassungVom` = ris_normalize_date(version_date),
    `Fassung.VonInkrafttretensdatum` = ris_normalize_date(effective_from),
    `Fassung.BisInkrafttretensdatum` = ris_normalize_date(effective_to),
    `Fassung.VonAusserkrafttretensdatum` = ris_normalize_date(expiry_from),
    `Fassung.BisAusserkrafttretensdatum` = ris_normalize_date(expiry_to),
    # -- Complex "Abschnitt" (section) parameter --
    # Narrows to a specific article/paragraph/annex range within a law.
    `Abschnitt.Von` = section_from,
    `Abschnitt.Bis` = section_to,
    `Abschnitt.Typ` = ris_normalize_abschnitt_typ(section_type),
    # -- Filtering, sorting, and pagination --
    ImRisSeit = ris_normalize_named_interval(in_ris_since),
    `Sortierung.SortDirection` = ris_normalize_sort_direction(sort_direction),
    `Sortierung.SortedByColumn` = ris_normalize_bundesrecht_sort_column(sort_by),
    Seitennummer = as.integer(page),
    DokumenteProSeite = ris_per_page_to_api_value(as.integer(per_page))
  )

  # Remove NULL and empty-string entries so they don't clutter the URL.
  purrr::discard(params, ~ is.null(.x) || identical(.x, ""))
}


# ============================================================================
# Section 2: Normalization helpers
# ============================================================================

# -- Abschnitt (section) type normalization ------------------------------------
# The Abschnitt.Typ sub-field is mandatory whenever an Abschnitt range is
# supplied.  Accepts the German API values and English aliases.
#
# API values:  Alle, Artikel, Paragraph, Anlage
# Aliases:     all, article, paragraph, annex
ris_normalize_abschnitt_typ <- function(x) {
  if (is.null(x) || identical(x, "")) {
    return(NULL)
  }
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    rlang::abort("`section_type` must be a single string.")
  }

  lookup <- c(
    alle = "Alle",
    artikel = "Artikel",
    paragraph = "Paragraph",
    anlage = "Anlage",
    all = "Alle",
    article = "Artikel",
    annex = "Anlage"
  )

  key <- ris_normalize_key(x)
  if (!key %in% names(lookup)) {
    rlang::abort(paste0(
      "`section_type` is invalid. Use one of: ",
      "'Alle', 'Artikel', 'Paragraph', 'Anlage' ",
      "(English aliases 'all', 'article', 'paragraph', 'annex' are also accepted)."
    ))
  }

  unname(lookup[[key]])
}

# -- Sort column normalization -------------------------------------------------
# BrKons sortable columns.  Accepts the German API values and English aliases.
#
# API values:  ArtikelParagraphAnlage, Kurzinformation,
#              Inkrafttretensdatum, Ausserkrafttretensdatum
ris_normalize_bundesrecht_sort_column <- function(x) {
  if (is.null(x) || identical(x, "")) {
    return(NULL)
  }
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    rlang::abort("`sort_by` must be a single string.")
  }

  lookup <- c(
    artikelparagraphanlage = "ArtikelParagraphAnlage",
    kurzinformation = "Kurzinformation",
    inkrafttretensdatum = "Inkrafttretensdatum",
    ausserkrafttretensdatum = "Ausserkrafttretensdatum",
    # English aliases
    section = "ArtikelParagraphAnlage",
    briefinfo = "Kurzinformation",
    effectivedate = "Inkrafttretensdatum",
    expirydate = "Ausserkrafttretensdatum"
  )

  key <- ris_normalize_key(x)
  if (!key %in% names(lookup)) {
    rlang::abort(paste0(
      "`sort_by` is invalid. Use one of: ",
      "'ArtikelParagraphAnlage', 'Kurzinformation', ",
      "'Inkrafttretensdatum', 'Ausserkrafttretensdatum'."
    ))
  }

  unname(lookup[[key]])
}


# ============================================================================
# Section 3: Website URL builder
# ============================================================================
# Build the application landing page and a best-effort equivalent search URL
# on the RIS website (www.ris.bka.gv.at).  The consolidated federal law search
# uses the "Bundesnormen" Ergebnis.wxe query.  These URLs are supplementary
# (printed when echo = TRUE and stored in app_metadata) so callers can
# cross-check results in a browser.
ris_build_bundesrecht_website_urls <- function(
  query = NULL,
  title = NULL,
  index = NULL,
  type = NULL,
  law_number = NULL,
  promulgation_organ = NULL,
  promulgation_number = NULL,
  version_date = NULL,
  effective_from = NULL,
  effective_to = NULL,
  expiry_from = NULL,
  expiry_to = NULL,
  in_ris_since = NULL,
  per_page = 100L
) {
  app_url <- "https://www.ris.bka.gv.at/Bundesrecht/"

  q <- list(
    Abfrage = "Bundesnormen",
    Titel = title %||% "",
    Index = index %||% "",
    Gesetzesnummer = law_number %||% "",
    Kundmachungsorgan = promulgation_organ %||% "",
    Kundmachungsorgannummer = promulgation_number %||% "",
    Typ = type %||% "",
    Suchworte = query %||% "",
    FassungVom = ris_format_website_date(version_date),
    VonInkrafttretensdatum = ris_format_website_date(effective_from),
    BisInkrafttretensdatum = ris_format_website_date(effective_to),
    VonAusserkrafttretensdatum = ris_format_website_date(expiry_from),
    BisAusserkrafttretensdatum = ris_format_website_date(expiry_to),
    ImRisSeit = ris_normalize_named_interval(in_ris_since) %||% "Undefined",
    ResultPageSize = as.character(as.integer(per_page)),
    Position = "1",
    SkipToDocumentPage = "true"
  )

  search_url <- paste0(
    "https://www.ris.bka.gv.at/Ergebnis.wxe?",
    ris_url_encode_query(q)
  )

  list(app_url = app_url, search_url = search_url)
}
