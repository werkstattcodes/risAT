# ============================================================================
# ris_case_law_utils.R — Shared internal helpers for the Judikatur endpoint
# ============================================================================
#
# This file contains all internal (non-exported) utility functions used by
# ris_req_case_law(), ris_perform_case_law(), and the court-specific wrappers.
#
# Organization:
#   1. Website URL builder   — constructs equivalent ris.bka.gv.at URLs
#   2. Parameter builder     — maps R arguments to RIS API query parameters
#   3. Normalization helpers  — validate and canonicalize user inputs
#
# Design principle: "normalize early, pass canonical values downstream."
# All user-facing strings (application names, decision types, sort columns,
# intervals, etc.) are normalized to their exact API-expected form as early
# as possible.  This means downstream code never needs to worry about case
# sensitivity, aliases, or whitespace variations.
# ============================================================================


# ============================================================================
# Section 1: Website URL builder
# ============================================================================
# The RIS OGD REST API (data.bka.gv.at) and the RIS website
# (www.ris.bka.gv.at) use different URL structures and parameter names.
# These helpers build the *website* URL that corresponds to a given API query,
# so users can open the same search in a browser to cross-check results.
#
# The website URL format is:
#   https://www.ris.bka.gv.at/Ergebnis.wxe?Abfrage=<App>&Suchworte=<query>&...
#
# Notable differences from the API:
#   - Dates use DD.MM.YYYY (not YYYY-MM-DD)
#   - Booleans use "True"/"False" (not "true"/omitted)
#   - The website URL-encodes reserved characters in parameter values
# ============================================================================

# Build both the application landing page URL and the full search results URL
# for the RIS website.  These are attached as metadata to the output tibble
# and optionally printed when echo = TRUE.
ris_build_case_law_website_urls <- function(
    application_code,
    query = NULL,
    business_number = NULL,
    norm = NULL,
    decision_date_from = NULL,
    decision_date_to = NULL,
    decision_type = NULL,
    index_term = NULL,
    collection_number = NULL,
    in_ris_since = NULL,
    search_decision_text = NULL,
    search_legal_principles = NULL,
    per_page = 20L,
    # -- Application-specific parameters --
    federal_state = NULL,
    court = NULL,
    legal_area = NULL,
    specialist_area = NULL,
    deciding_authority = NULL,
    commission = NULL,
    senate = NULL,
    discrimination_ground = NULL
) {
  # The application landing page (e.g. https://www.ris.bka.gv.at/Vfgh/)
  app_url <- paste0("https://www.ris.bka.gv.at/", application_code, "/")

  # Build the query string for the Ergebnis.wxe search results page.
  # Parameters use %||% to substitute empty strings for NULLs, matching
  # the website's convention of including all parameters (even empty ones).
  q <- list(
    Abfrage = application_code,
    Entscheidungsart = decision_type %||% "Undefined",
    Sammlungsnummer = collection_number %||% "",
    Index = index_term %||% "",
    SucheNachRechtssatz = ris_bool_to_title_case(search_legal_principles),
    SucheNachText = ris_bool_to_title_case(search_decision_text),
    GZ = business_number %||% "",
    VonDatum = ris_format_website_date(decision_date_from),
    BisDatum = ris_format_website_date(decision_date_to, fallback_today = TRUE),
    Norm = norm %||% "",
    ImRisSeitVonDatum = "",
    ImRisSeitBisDatum = "",
    ImRisSeit = ris_normalize_named_interval(in_ris_since) %||% "Undefined",
    ResultPageSize = as.character(as.integer(per_page)),
    Suchworte = query %||% "",
    Position = "1",
    SkipToDocumentPage = "true"
  )

  # Append application-specific parameters when provided.  These are only
  # meaningful for certain Judikatur applications (e.g. Bundesland for Lvwg,
  # Gericht for Justiz) but are silently ignored by the website for others.
  app_specific <- list(
    Bundesland = federal_state,
    Gericht = court,
    Rechtsgebiet = legal_area,
    Fachgebiet = specialist_area,
    EntscheidendeBehoerde = deciding_authority,
    Kommission = commission,
    Senat = senate,
    Diskriminierungsgrund = discrimination_ground
  )
  app_specific <- purrr::discard(app_specific, is.null)
  q <- c(q, app_specific)

  search_url <- paste0(
    "https://www.ris.bka.gv.at/Ergebnis.wxe?",
    ris_url_encode_query(q)
  )

  list(app_url = app_url, search_url = search_url)
}

# Convert an ISO date (YYYY-MM-DD) to the Austrian DD.MM.YYYY format used
# by the RIS website.  When fallback_today = TRUE and no date is provided,
# uses today's date (the website's default behavior for BisDatum).
ris_format_website_date <- function(x, fallback_today = FALSE) {
  if (is.null(x) || identical(x, "")) {
    if (isTRUE(fallback_today)) {
      return(format(Sys.Date(), "%d.%m.%Y"))
    }
    return("")
  }
  format(as.Date(x), "%d.%m.%Y")
}

# Convert a logical to the RIS website's title-case string representation.
# The website uses "True"/"False" (not "true"/"false") for boolean parameters
# like SucheNachRechtssatz and SucheNachText.  Returns "" for NULL/non-logical.
ris_bool_to_title_case <- function(x) {
  if (isTRUE(x)) {
    return("True")
  }
  if (isFALSE(x)) {
    return("False")
  }
  ""
}

# Custom URL query encoder for the RIS website URLs.  We can't use
# httr2::req_url_query() here because we're building a plain string URL
# (not modifying an httr2 request object).  Both parameter names and values
# are percent-encoded with reserved characters.
ris_url_encode_query <- function(params) {
  pieces <- purrr::imap_chr(
    params,
    ~ paste0(
      utils::URLencode(as.character(.y), reserved = TRUE),
      "=",
      utils::URLencode(as.character(.x), reserved = TRUE)
    )
  )
  paste(pieces, collapse = "&")
}


# ============================================================================
# Section 2: API parameter builder
# ============================================================================
# The RIS OGD API uses German-language parameter names.  This function maps
# our English R argument names to their API equivalents and applies any
# last-mile normalization (dates, intervals, booleans, pagination).
#
# Parameters that are NULL or empty string are removed from the final list
# so they don't appear in the URL query string — the API treats absent
# parameters as "no filter" for that field.
# ============================================================================

# Map R-friendly argument names to the German API parameter names, normalize
# dates/intervals/booleans, and strip NULL/empty values.  The result is a
# named list ready to be spliced into httr2::req_url_query().
ris_build_case_law_params <- function(
    application_code,
    query = NULL,
    business_number = NULL,
    norm = NULL,
    decision_date_from = NULL,
    decision_date_to = NULL,
    decision_type = NULL,
    index_term = NULL,
    collection_number = NULL,
    title = NULL,
    document_kind = NULL,
    publication_organ = NULL,
    legal_area = NULL,
    specialist_area = NULL,
    court = NULL,
    legal_principle_number = NULL,
    legal_assessment = NULL,
    ruling = NULL,
    citation = NULL,
    changed_since_period = NULL,
    federal_state = NULL,
    deciding_authority = NULL,
    commission = NULL,
    senate = NULL,
    discrimination_ground = NULL,
    author = NULL,
    short_title = NULL,
    domain = NULL,
    in_ris_since = NULL,
    sort_by = NULL,
    sort_direction = NULL,
    search_decision_text = NULL,
    search_legal_principles = NULL,
    page = 1L,
    per_page = 20L
) {
  params <- list(
    # -- Core parameters (all applications) --
    Applikation = application_code,
    Suchworte = query,
    Geschaeftszahl = business_number,
    Norm = norm,
    EntscheidungsdatumVon = ris_normalize_date(decision_date_from),
    EntscheidungsdatumBis = ris_normalize_date(decision_date_to),
    Entscheidungsart = decision_type,
    Index = index_term,
    Sammlungsnummer = collection_number,
    # -- Application-specific parameters --
    # These are only meaningful for certain Judikatur applications but the API
    # silently ignores parameters that don't apply, so we include them all.
    Titel = title,                          # Normenliste
    Typ = document_kind,                    # Normenliste
    Kundmachungsorgan = publication_organ,  # Normenliste
    Rechtsgebiet = legal_area,              # Justiz
    Fachgebiet = specialist_area,           # Justiz
    Gericht = court,                        # Justiz
    Rechtssatznummer = legal_principle_number, # Justiz
    RechtlicheBeurteilung = legal_assessment,  # Justiz
    Spruch = ruling,                        # Justiz, Ubas
    Fundstelle = citation,                  # Justiz
    AenderungenSeitPeriode = ris_normalize_named_interval(changed_since_period), # Justiz
    Bundesland = federal_state,             # Lvwg, Uvs
    EntscheidendeBehoerde = deciding_authority, # Dsk, Dok, Pvak, Verg
    Kommission = commission,                # Gbk
    Senat = senate,                         # Gbk
    Diskriminierungsgrund = discrimination_ground, # Gbk
    Verfasser = author,                     # Ubas
    Kurzbezeichnung = short_title,          # Umse
    Bereich = domain,                       # Bks
    # -- Sorting, filtering, and pagination --
    ImRisSeit = ris_normalize_named_interval(in_ris_since),
    SortierungSortDirection = ris_normalize_sort_direction(sort_direction),
    SortierungSortedByColumn = sort_by,
    # The API expects "true" (lowercase string) for these boolean flags, or
    # the parameter should be absent entirely (not "false").
    # These are compound parameters under "Dokumenttyp" — the API requires
    # the parent prefix (e.g. DokumenttypSucheInRechtssaetzen, not just
    # SucheInRechtssaetzen).  Without the prefix, the API silently ignores
    # the flags.
    DokumenttypSucheInEntscheidungstexten = ris_bool_to_true_or_null(search_decision_text),
    DokumenttypSucheInRechtssaetzen = ris_bool_to_true_or_null(search_legal_principles),
    Seitennummer = as.integer(page),
    # The API uses English word names for page sizes: "Ten", "Twenty", etc.
    DokumenteProSeite = ris_per_page_to_api_value(as.integer(per_page))
  )

  # Remove NULL and empty-string entries so they don't clutter the URL.
  purrr::discard(params, ~ is.null(.x) || identical(.x, ""))
}


# ============================================================================
# Section 3: Normalization helpers
# ============================================================================
# These functions validate and canonicalize user inputs.  The general pattern:
#
#   1. Accept flexible input (case-insensitive, English aliases, etc.)
#   2. Normalize to a canonical lookup key (lowercase, no spaces/underscores)
#   3. Map to the exact string the API expects
#   4. Error with a helpful message if no match is found
#
# This "normalize early" approach means all downstream code can rely on
# receiving exact API-ready values.
# ============================================================================

# -- Application code resolution -----------------------------------------------
# Translate a user-facing application identifier into the canonical RIS code.
# Accepts:
#   - Canonical codes (case-insensitive): "Vfgh", "Vwgh", "Justiz", etc.
#   - English aliases: "constitutional_court", "administrative_court", etc.
#
# The 16 Judikatur applications cover Austria's full spectrum of
# administrative and judicial bodies, from the Constitutional Court (Vfgh)
# to specialized bodies like the Equal Treatment Commission (Gbk).
ris_case_law_application_to_code <- function(application) {
  if (!is.character(application) || length(application) != 1L || is.na(application)) {
    rlang::abort("`application` must be a single string.")
  }

  # The official RIS application codes, in their canonical casing.
  canonical_codes <- c(
    "Vfgh", "Vwgh", "Normenliste", "Justiz", "Bvwg", "Lvwg", "Dsk", "Dok",
    "Pvak", "Gbk", "Uvs", "AsylGH", "Ubas", "Umse", "Bks", "Verg"
  )

  # English aliases for international users who may not know the German
  # abbreviations.  Each alias maps to exactly one canonical code.
  #
  # Note on naming:
  #   - Dsk covers three bodies: Datenschutzkommission (DSK, 1990-2013),
  #     Datenschutzbehoerde (DSB, since 2014), and Parlamentarisches
  #     Datenschutzkomitee (PDK, since 2025 on the RIS website).
  #   - Dok covers Bundesdisziplinarbehoerde (since Oct 2020) and the
  #     earlier Disziplinarkommissionen, Disziplinaroberkommission, and
  #     Berufungskommission (until 2013).
  alias_to_code <- c(
    constitutional_court = "Vfgh",
    administrative_court = "Vwgh",
    norm_list = "Normenliste",
    justice = "Justiz",
    federal_administrative_court = "Bvwg",
    state_administrative_courts = "Lvwg",
    data_protection_authority = "Dsk",
    disciplinary_bodies = "Dok",
    staff_representation_oversight = "Pvak",
    equal_treatment_commission = "Gbk",
    independent_administrative_panels = "Uvs",
    asylum_court = "AsylGH",
    independent_federal_asylum_panel = "Ubas",
    environmental_panel = "Umse",
    federal_communications_panel = "Bks",
    procurement_review_bodies = "Verg"
  )

  candidate <- trimws(application)
  candidate_lower <- tolower(candidate)

  # Try matching against canonical codes first (case-insensitive).
  if (candidate_lower %in% tolower(canonical_codes)) {
    idx <- match(candidate_lower, tolower(canonical_codes))
    return(canonical_codes[[idx]])
  }

  # Then try English aliases (already lowercase).
  if (candidate_lower %in% names(alias_to_code)) {
    return(alias_to_code[[candidate_lower]])
  }

  # No match — build a helpful error message listing all valid options.
  valid_values <- c(canonical_codes, names(alias_to_code))
  rlang::abort(paste0(
    "`application` is invalid. Use one of: ",
    paste(valid_values, collapse = ", "),
    "."
  ))
}

# -- Document type support check -----------------------------------------------
# Not all Judikatur applications support the search_decision_text /
# search_legal_principles flags.  Normenliste and Gbk do not have this
# concept; passing these flags to those applications would be misleading.
ris_case_law_supports_document_type <- function(application_code) {
  !(application_code %in% c("Normenliste", "Gbk"))
}

# -- Key normalization ---------------------------------------------------------
# Standardize a user-provided string for lookup matching: lowercase, trim
# whitespace, and collapse all spaces/underscores/hyphens.  This allows
# users to write "BeschlussVS", "beschluss_vs", "Beschluss VS", or
# "beschluss-vs" and have them all match the same lookup key.
ris_normalize_key <- function(x) {
  gsub("[[:space:]_-]+", "", tolower(trimws(x)))
}

# -- Decision type normalization -----------------------------------------------
# The decision_type parameter has different allowed values depending on the
# court application.  VfGH and VwGH each have a specific set of valid types;
# other applications accept any string (the API validates it server-side).
ris_normalize_case_law_decision_type <- function(application_code, decision_type) {
  if (is.null(decision_type) || identical(decision_type, "")) {
    return(NULL)
  }
  checkmate::assert_character(
    decision_type,
    len = 1L,
    any.missing = FALSE,
    .var.name = "decision_type"
  )

  if (identical(application_code, "Vfgh")) {
    return(ris_normalize_vfgh_decision_type(decision_type))
  }

  if (identical(application_code, "Vwgh")) {
    return(ris_normalize_vwgh_decision_type(decision_type))
  }

  if (identical(application_code, "Bvwg")) {
    return(ris_normalize_bvwg_decision_type(decision_type))
  }

  if (identical(application_code, "Lvwg")) {
    return(ris_normalize_lvwg_decision_type(decision_type))
  }

  if (identical(application_code, "Justiz")) {
    return(ris_normalize_justiz_decision_type(decision_type))
  }

  if (identical(application_code, "Dsk")) {
    return(ris_normalize_dsk_decision_type(decision_type))
  }

  if (identical(application_code, "Gbk")) {
    return(ris_normalize_gbk_decision_type(decision_type))
  }

  # For applications without a defined decision type enum (Dok, Pvak, etc.),
  # pass through as-is — the API validates server-side.
  decision_type
}

# VwGH decision types: Undefined, Beschluss, Erkenntnis, BeschlussVS,
# ErkenntnisVS.  The "VS" suffix denotes a Verstaerkter Senat (reinforced
# senate) decision, which carries special legal weight.
ris_normalize_vwgh_decision_type <- function(x) {
  lookup <- c(
    undefined = "Undefined",
    beschluss = "Beschluss",
    erkenntnis = "Erkenntnis",
    beschlussvs = "BeschlussVS",
    erkenntnisvs = "ErkenntnisVS"
  )

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "decision_type"
  )

  unname(lookup[[key]])
}

# -- Sort column normalization -------------------------------------------------
# Only VfGH and VwGH have a defined set of sortable columns; other
# applications pass sort_by through unchanged.
ris_normalize_case_law_sort_by <- function(application_code, sort_by) {
  if (is.null(sort_by) || identical(sort_by, "")) {
    return(NULL)
  }
  checkmate::assert_character(
    sort_by,
    len = 1L,
    any.missing = FALSE,
    .var.name = "sort_by"
  )

  if (!application_code %in% c("Vfgh", "Vwgh")) {
    return(sort_by)
  }

  ris_normalize_court_sort_by(sort_by)
}

# VfGH decision types: Undefined, Beschluss, Erkenntnis, Vergleich,
# KeineAngabe.  English aliases ("order", "judgment", "settlement",
# "not_specified") are mapped to their German API equivalents.
ris_normalize_vfgh_decision_type <- function(x) {
  lookup <- c(
    undefined = "Undefined",
    beschluss = "Beschluss",
    erkenntnis = "Erkenntnis",
    vergleich = "Vergleich",
    keineangabe = "KeineAngabe",
    order = "Beschluss",
    judgment = "Erkenntnis",
    settlement = "Vergleich",
    notspecified = "KeineAngabe"
  )

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "decision_type"
  )

  unname(lookup[[key]])
}

# BVwG decision types: Undefined, Beschluss, Erkenntnis.
ris_normalize_bvwg_decision_type <- function(x) {
  lookup <- c(
    undefined = "Undefined",
    beschluss = "Beschluss",
    erkenntnis = "Erkenntnis"
  )

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "decision_type"
  )

  unname(lookup[[key]])
}

# LVwG decision types: Undefined, Beschluss, Erkenntnis, Bescheid.
ris_normalize_lvwg_decision_type <- function(x) {
  lookup <- c(
    undefined = "Undefined",
    beschluss = "Beschluss",
    erkenntnis = "Erkenntnis",
    bescheid = "Bescheid"
  )

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "decision_type"
  )

  unname(lookup[[key]])
}

# Justiz decision types are German phrases.  Because ris_normalize_key()
# collapses all spaces, we need to build lookup keys by applying the same
# transform to the canonical values.
ris_normalize_justiz_decision_type <- function(x) {
  canonical <- c(
    "Ordentliche Erledigung (Sachentscheidung)",
    "Zur\u00fcckweisung mangels erheblicher Rechtsfrage",
    "Zur\u00fcckweisung aus anderen Gr\u00fcnden",
    "Verst\u00e4rkter Senat"
  )
  lookup <- stats::setNames(canonical, vapply(canonical, ris_normalize_key, character(1)))

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "decision_type"
  )

  unname(lookup[[key]])
}

# Dsk decision types (14 values).
ris_normalize_dsk_decision_type <- function(x) {
  canonical <- c(
    "Undefined",
    "BescheidBeschwerde",
    "BescheidAmtswegigesPruefverfahren",
    "VerwaltungsstraferkenntnisVerwarnungErmahnung",
    "BescheidWissenschaftStatistikArchiv",
    "BescheidInternatDatenverkehr",
    "BescheidAkkreditierungZertifizierung",
    "BescheidVerhaltensregeln",
    "BescheidWarnung",
    "BescheidRegistrierung",
    "BescheidSonstiger",
    "Empfehlung",
    "BescheidIFG",
    "Verfahrensschriftsaetze"
  )
  lookup <- stats::setNames(canonical, vapply(canonical, ris_normalize_key, character(1)))

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "decision_type"
  )

  unname(lookup[[key]])
}

# Gbk decision types: Undefined, Einzelfallpruefungsergebnis, Gutachten.
ris_normalize_gbk_decision_type <- function(x) {
  lookup <- c(
    undefined = "Undefined",
    einzelfallpruefungsergebnis = "Einzelfallpruefungsergebnis",
    gutachten = "Gutachten"
  )

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "decision_type"
  )

  unname(lookup[[key]])
}

# Sort column lookup for VfGH/VwGH.  Accepts both the German API names
# (Geschaeftszahl, Datum, Art, Typ) and English aliases (business_number,
# decision_date, decision_type, document_type).  Note: "Art" maps to
# decision type and "Typ" maps to document type in the RIS UI.
ris_normalize_court_sort_by <- function(x) {
  lookup <- c(
    geschaeftszahl = "Geschaeftszahl",
    datum = "Datum",
    art = "Art",
    typ = "Typ",
    businessnumber = "Geschaeftszahl",
    casenumber = "Geschaeftszahl",
    decisiondate = "Datum",
    decisiontype = "Art",
    documenttype = "Typ"
  )

  key <- ris_normalize_key(x)
  checkmate::assert_choice(
    key,
    choices = names(lookup),
    .var.name = "sort_by"
  )

  unname(lookup[[key]])
}

# -- Document type flags normalization -----------------------------------------
# Resolves the search_decision_text and search_legal_principles flags into
# a consistent pair of TRUE/FALSE values.  Handles several cases:
#
#   1. Application doesn't support these flags (Normenliste, Gbk):
#      -> warn if user provided them, return NULL/NULL
#   2. User left both NULL:
#      -> default to TRUE/TRUE (search both document types)
#   3. User provided one but not the other:
#      -> the unprovided one defaults to FALSE
#   4. Both FALSE:
#      -> error (at least one must be TRUE, otherwise no results would return)
ris_normalize_document_type_flags <- function(
    application_code,
    search_decision_text = NULL,
    search_legal_principles = NULL
) {
  supports <- ris_case_law_supports_document_type(application_code)

  # Validate that any provided flags are scalar logicals.
  flags <- list(
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles
  )
  provided <- purrr::keep(flags, ~ !is.null(.x))

  if (length(provided) > 0L) {
    valid <- purrr::map_lgl(provided, ~ is.logical(.x) && length(.x) == 1L && !is.na(.x))
    if (!all(valid)) {
      rlang::abort("`search_decision_text` and `search_legal_principles` must be TRUE or FALSE.")
    }
  }

  # Applications that don't support document-type flags: warn and return NULLs.
  if (!supports) {
    if (length(provided) > 0L) {
      rlang::warn(
        "`search_decision_text` and `search_legal_principles` are ignored for this Judikatur application."
      )
    }
    return(list(search_decision_text = NULL, search_legal_principles = NULL))
  }

  # Default: both NULL -> search both document types.
  if (is.null(search_decision_text) && is.null(search_legal_principles)) {
    return(list(search_decision_text = TRUE, search_legal_principles = TRUE))
  }

  # If only one flag was provided, default the other to FALSE.
  search_decision_text <- if (is.null(search_decision_text)) FALSE else search_decision_text
  search_legal_principles <- if (is.null(search_legal_principles)) FALSE else search_legal_principles

  # Guard: at least one must be TRUE, otherwise the API returns no results.
  if (!isTRUE(search_decision_text) && !isTRUE(search_legal_principles)) {
    rlang::abort("At least one of `search_decision_text` or `search_legal_principles` must be TRUE.")
  }

  list(
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles
  )
}

# -- Date normalization --------------------------------------------------------
# Coerce dates to ISO 8601 (YYYY-MM-DD) strings for the API.  Accepts any
# input that as.Date() can parse (Date objects, "YYYY-MM-DD" strings, etc.).
# Returns NULL for NULL/empty input so the parameter is omitted from the URL.
ris_normalize_date <- function(x) {
  if (is.null(x) || identical(x, "")) {
    return(NULL)
  }
  as.character(as.Date(x))
}

# -- Boolean-to-API-string conversion -----------------------------------------
# The RIS API represents boolean search flags as either the string "true"
# (when enabled) or as an absent parameter (when disabled).  This differs from
# the website format which uses "True"/"False" (handled by ris_bool_to_title_case).
ris_bool_to_true_or_null <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    rlang::abort("Logical RIS search flags must be TRUE or FALSE.")
  }
  if (isTRUE(x)) "true" else NULL
}

# -- Named interval normalization ----------------------------------------------
# The ImRisSeit and AenderungenSeitPeriode parameters accept a fixed set of
# German time interval names.  We also support English aliases for
# international users.
#
# API values:  Undefined, EinerWoche, ZweiWochen, EinemMonat,
#              DreiMonaten, SechsMonaten, EinemJahr
# Aliases:     one_week, two_weeks, one_month, three_months,
#              six_months, one_year
ris_normalize_named_interval <- function(x) {
  if (is.null(x) || identical(x, "")) {
    return(NULL)
  }

  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    rlang::abort("Named interval parameters must be a single string.")
  }

  lookup <- c(
    undefined = "Undefined",
    einerwoche = "EinerWoche",
    zweiwochen = "ZweiWochen",
    einemmonat = "EinemMonat",
    dreimonaten = "DreiMonaten",
    sechsmonaten = "SechsMonaten",
    einemjahr = "EinemJahr",
    oneweek = "EinerWoche",
    twoweeks = "ZweiWochen",
    onemonth = "EinemMonat",
    threemonths = "DreiMonaten",
    sixmonths = "SechsMonaten",
    oneyear = "EinemJahr"
  )

  key <- ris_normalize_key(x)
  if (!key %in% names(lookup)) {
    rlang::abort(paste0(
      "Interval value is invalid. Use one of: ",
      paste(
        c(
          "Undefined", "EinerWoche", "ZweiWochen", "EinemMonat",
          "DreiMonaten", "SechsMonaten", "EinemJahr",
          "one_week", "two_weeks", "one_month", "three_months",
          "six_months", "one_year"
        ),
        collapse = ", "
      ),
      "."
    ))
  }

  unname(lookup[[key]])
}

# -- Sort direction normalization ----------------------------------------------
# Accepts "Ascending" or "Descending" (case-insensitive) and returns the
# correctly-cased API value.  Returns NULL when omitted so the API uses its
# default sort order.
ris_normalize_sort_direction <- function(x) {
  if (is.null(x) || identical(x, "")) {
    return(NULL)
  }
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    rlang::abort("`sort_direction` must be a single string.")
  }
  allowed <- c("Ascending", "Descending")
  idx <- match(tolower(x), tolower(allowed))
  if (is.na(idx)) {
    rlang::abort("`sort_direction` must be 'Ascending' or 'Descending'.")
  }
  allowed[[idx]]
}

# -- Per-page to API enum conversion -------------------------------------------
# The API uses English word names for page sizes rather than numeric values.
# This maps the integer page size to the DokumenteProSeite enum string.
ris_per_page_to_api_value <- function(per_page) {
  lookup <- c(
    `10` = "Ten",
    `20` = "Twenty",
    `50` = "Fifty",
    `100` = "OneHundred"
  )
  out <- unname(lookup[[as.character(as.integer(per_page))]])
  if (is.null(out)) {
    rlang::abort("`per_page` must be one of: 10, 20, 50, 100.")
  }
  out
}
