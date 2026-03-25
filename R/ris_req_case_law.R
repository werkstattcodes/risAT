# ============================================================================
# ris_req_case_law.R — Build (but do not execute) a RIS Judikatur API request
# ============================================================================
#
# This file contains the first step of the two-step req/perform pattern used
# throughout this package, inspired by httr2's design philosophy:
#
#   1. ris_req_case_law()   — build an httr2_request (this file)
#   2. ris_perform_case_law() — execute the request and parse the response
#
# Splitting request construction from execution lets users inspect, modify,
# or dry-run the request before hitting the network (e.g. with
# httr2::req_dry_run()).
#
# The RIS OGD REST API v2.6 exposes a single /Judikatur endpoint that serves
# all 16 Judikatur "applications" (Vfgh, Vwgh, Justiz, Bvwg, etc.).  Which
# query parameters are meaningful depends on the application — for example,
# `Gericht` (court) is only used by Justiz, while `Senat` is only for Gbk.
# This function accepts the union of all parameters and leaves it to the
# internal helpers in ris_case_law_utils.R to validate and normalize them.
# ============================================================================

#' Build a RIS Case Law API Request
#'
#' Construct an `httr2_request` object for the Austrian RIS OGD REST API v2.6
#' `/Judikatur` endpoint. The request is **not executed**; call
#' [ris_perform_case_law()] to send it and parse the results, or use
#' [httr2::req_dry_run()] to inspect the URL.
#'
#' @param application Judikatur application. Accepts RIS codes or English aliases
#'   (case-insensitive):
#'
#'   | Code | English Alias | Court / Body |
#'   |------|---------------|--------------|
#'   | `"Vfgh"` | `"constitutional_court"` | Constitutional Court (VfGH) |
#'   | `"Vwgh"` | `"administrative_court"` | Supreme Administrative Court (VwGH) |
#'   | `"Justiz"` | `"justice"` | Ordinary courts (OGH, OLG, LG, BG, OPMS, AUSL) |
#'   | `"Bvwg"` | `"federal_administrative_court"` | Federal Administrative Court (BVwG) |
#'   | `"Lvwg"` | `"state_administrative_courts"` | State Administrative Courts (LVwG) |
#'   | `"Normenliste"` | `"norm_list"` | VwGH Norm List |
#'   | `"Dsk"` | `"data_protection_authority"` | Data protection authorities (DSK/DSB/PDK) |
#'   | `"Dok"` | `"disciplinary_bodies"` | Federal Disciplinary Authority & commissions |
#'   | `"Pvak"` | `"staff_representation_oversight"` | Staff Representation Oversight Authority |
#'   | `"Gbk"` | `"equal_treatment_commission"` | Equal Treatment Commissions (since 2014) |
#'   | `"Uvs"` | `"independent_administrative_panels"` | Independent Administrative Panels (1991--2013) |
#'   | `"AsylGH"` | `"asylum_court"` | Asylum Court (2008--2013) |
#'   | `"Ubas"` | `"independent_federal_asylum_panel"` | Independent Federal Asylum Panel (1998--2008) |
#'   | `"Umse"` | `"environmental_panel"` | Environmental Panel (1994--2013) |
#'   | `"Bks"` | `"federal_communications_panel"` | Federal Communications Panel (2001--2013) |
#'   | `"Verg"` | `"procurement_review_bodies"` | Procurement Review Bodies (until 2013) |
#' @param query Optional full-text query (`Suchworte`).
#' @param business_number Optional business number (`Geschaeftszahl`).
#' @param norm Optional legal norm query (`Norm`).
#' @param decision_date_from Optional lower date bound (`YYYY-MM-DD`,
#'   `EntscheidungsdatumVon`).
#' @param decision_date_to Optional upper date bound (`YYYY-MM-DD`,
#'   `EntscheidungsdatumBis`).
#' @param decision_type Optional decision type (`Entscheidungsart`).
#'   Allowed values depend on `application`:
#'   - **VfGH**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
#'     `"Vergleich"`, `"KeineAngabe"` (English aliases: `"order"`, `"judgment"`,
#'     `"settlement"`, `"not_specified"`).
#'   - **VwGH**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
#'     `"BeschlussVS"`, `"ErkenntnisVS"`.
#'   - **BVwG**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`.
#'   - **LVwG / UVS**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
#'     `"Bescheid"`.
#'   - **Justiz**: `"Ordentliche Erledigung (Sachentscheidung)"`,
#'     `"Zurückweisung mangels erheblicher Rechtsfrage"`,
#'     `"Zurückweisung aus anderen Gründen"`, `"Verstärkter Senat"`.
#'   - **AsylGH**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
#'     `"ErkenntnisGrundsatzentscheidung"`,
#'     `"ErkenntnisVerstaerkterSenat"`, `"Bescheid"`.
#'   - **Ubas**: `"Undefined"`, `"Bescheid"`, `"Ersatzbescheid"`.
#'   - **Gbk**: `"Undefined"`, `"Einzelfallpruefungsergebnis"`,
#'     `"Gutachten"`.
#'   - **Dsk**: `"Undefined"`, `"BescheidBeschwerde"`,
#'     `"BescheidAmtswegigesPruefverfahren"`,
#'     `"VerwaltungsstraferkenntnisVerwarnungErmahnung"`,
#'     `"BescheidWissenschaftStatistikArchiv"`,
#'     `"BescheidInternatDatenverkehr"`,
#'     `"BescheidAkkreditierungZertifizierung"`,
#'     `"BescheidVerhaltensregeln"`, `"BescheidWarnung"`,
#'     `"BescheidRegistrierung"`, `"BescheidSonstiger"`,
#'     `"Empfehlung"`, `"BescheidIFG"`,
#'     `"Verfahrensschriftsaetze"`.
#'
#'   Other applications accept free-text or have no decision type filter.
#' @param index_term Optional index term (`Index`).
#' @param collection_number Optional collection number (`Sammlungsnummer`).
#' @param title Optional title (`Titel`), used for `Normenliste`.
#' @param document_kind Optional document kind (`Typ`), used for `Normenliste`.
#' @param publication_organ Optional publication organ (`Kundmachungsorgan`),
#'   used for `Normenliste`.
#' @param legal_area Optional legal area (`Rechtsgebiet`), used for `Justiz`.
#' @param specialist_area Optional specialist area (`Fachgebiet`), used for
#'   `Justiz`.
#' @param court Optional court (`Gericht`), used for `Justiz`.
#' @param legal_principle_number Optional legal principle number
#'   (`Rechtssatznummer`), used for `Justiz`.
#' @param legal_assessment Optional legal assessment (`RechtlicheBeurteilung`),
#'   used for `Justiz`.
#' @param ruling Optional ruling text (`Spruch`), used for `Justiz` and `Ubas`.
#' @param citation Optional citation (`Fundstelle`), used for `Justiz`.
#' @param changed_since_period Optional change window (`AenderungenSeitPeriode`),
#'   used for `Justiz`.
#' @param federal_state Optional federal state (`Bundesland`), used for `Lvwg`
#'   and `Uvs`.
#' @param deciding_authority Optional deciding authority
#'   (`EntscheidendeBehoerde`), used for `Dsk`, `Dok`, `Pvak`, `Verg`.
#' @param commission Optional commission (`Kommission`), used for `Gbk`.
#' @param senate Optional senate (`Senat`), used for `Gbk`.
#' @param discrimination_ground Optional discrimination ground
#'   (`Diskriminierungsgrund`), used for `Gbk`.
#' @param author Optional author (`Verfasser`), used for `Ubas`.
#' @param short_title Optional short title (`Kurzbezeichnung`), used for `Umse`.
#' @param domain Optional domain (`Bereich`), used for `Bks`.
#' @param in_ris_since Optional RIS recency filter (`ImRisSeit`).
#'   Accepts API values (`"Undefined"`, `"EinerWoche"`, `"ZweiWochen"`,
#'   `"EinemMonat"`, `"DreiMonaten"`, `"SechsMonaten"`, `"EinemJahr"`) and
#'   English aliases (`"one_week"`, `"two_weeks"`, `"one_month"`,
#'   `"three_months"`, `"six_months"`, `"one_year"`).
#' @param search_decision_text Optional flag for decision text search
#'   (`SucheInEntscheidungstexten`).
#' @param search_legal_principles Optional flag for legal principles search
#'   (`SucheInRechtssaetzen`).
#' @param base_url API base URL.
#'
#' @return An `httr2_request` object with an additional `"ris_meta"` attribute
#'   containing the application code and website URLs. Pass this to
#'   [ris_perform_case_law()] to execute the search.
#' @export
#'
#' @examples
#' \dontrun{
#' # Build request, then inspect the URL without hitting the network
#' req <- ris_req_case_law(
#'   application = "constitutional_court",
#'   query = "Grundrecht"
#' )
#' httr2::req_dry_run(req)
#'
#' # Execute
#' results <- ris_perform_case_law(req)
#' }
ris_req_case_law <- function(
    application,
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
    search_decision_text = NULL,
    search_legal_principles = NULL,
    base_url = "https://data.bka.gv.at/ris/api/v2.6"
) {
  # -- Step 1: Validate & normalize inputs ------------------------------------
  # Translate the user-facing application name (which may be an English alias
  # like "constitutional_court") into the canonical RIS code (e.g. "Vfgh").
  application_code <- ris_case_law_application_to_code(application)
  per_page <- 100L

  # Normalize decision_type based on which court application was selected.
  # VwGH and VfGH have specific allowed enums; other applications pass through.
  decision_type <- ris_normalize_case_law_decision_type(
    application_code = application_code,
    decision_type = decision_type
  )

  # Resolve the document-type search flags (Entscheidungstexte vs.
  # Rechtssaetze).  Some applications (Normenliste, Gbk) don't support these
  # flags at all — in that case we warn and drop them.  When the application
  # *does* support them and the user left both NULL, we default to searching
  # both document types.
  document_type_flags <- ris_normalize_document_type_flags(
    application_code = application_code,
    search_decision_text = search_decision_text,
    search_legal_principles = search_legal_principles
  )

  # -- Step 2: Assemble API query parameters ----------------------------------
  # ris_build_case_law_params() maps R argument names to the German-language
  # API parameter names (e.g. business_number -> Geschaeftszahl) and removes
  # any NULLs so they don't appear in the URL.
  params <- ris_build_case_law_params(
    application_code = application_code,
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    index_term = index_term,
    collection_number = collection_number,
    title = title,
    document_kind = document_kind,
    publication_organ = publication_organ,
    legal_area = legal_area,
    specialist_area = specialist_area,
    court = court,
    legal_principle_number = legal_principle_number,
    legal_assessment = legal_assessment,
    ruling = ruling,
    citation = citation,
    changed_since_period = changed_since_period,
    federal_state = federal_state,
    deciding_authority = deciding_authority,
    commission = commission,
    senate = senate,
    discrimination_ground = discrimination_ground,
    author = author,
    short_title = short_title,
    domain = domain,
    in_ris_since = in_ris_since,
    sort_by = "Datum",
    sort_direction = "Descending",
    search_decision_text = document_type_flags$search_decision_text,
    search_legal_principles = document_type_flags$search_legal_principles,
    page = 1L,
    per_page = per_page
  )

  # -- Step 3: Build equivalent RIS website URLs ------------------------------
  # These are the URLs a user would see on https://www.ris.bka.gv.at if they
  # ran the same search in a browser.  We attach them as metadata so the
  # perform step can echo them (useful for debugging / cross-checking results).
  website_urls <- ris_build_case_law_website_urls(
    application_code = application_code,
    query = query,
    business_number = business_number,
    norm = norm,
    decision_date_from = decision_date_from,
    decision_date_to = decision_date_to,
    decision_type = decision_type,
    index_term = index_term,
    collection_number = collection_number,
    in_ris_since = in_ris_since,
    search_decision_text = document_type_flags$search_decision_text,
    search_legal_principles = document_type_flags$search_legal_principles,
    per_page = as.integer(per_page)
  )

  # -- Step 4: Construct the httr2 request object -----------------------------
  # We target the /Judikatur endpoint and splice all non-NULL params into the
  # URL query string.  req_retry(max_tries = 3) adds resilience against
  # transient network errors.
  req <- httr2::request(paste0(base_url, "/Judikatur")) |>
    httr2::req_url_query(!!!params) |>
    httr2::req_retry(max_tries = 3)

  # Attach metadata as a custom attribute on the request object.  This is the
  # bridge between the req and perform steps: ris_perform_case_law() reads
  # this attribute to know the application code, page size, and website URLs
  # without the user having to pass them again.
  attr(req, "ris_meta") <- list(
    application_code = application_code,
    per_page = as.integer(per_page),
    website_urls = website_urls
  )

  req
}
