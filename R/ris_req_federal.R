# ============================================================================
# ris_req_federal.R — Build (but do not execute) a RIS Bundesrecht request
# ============================================================================
#
# First step of the two-step req/perform pattern for the consolidated federal
# law endpoint:
#
#   1. ris_req_federal()     — build an httr2_request (this file)
#   2. ris_perform_federal() — execute the request and parse the response
#
# The RIS OGD REST API v2.6 serves consolidated federal law ("Bundesrecht in
# konsolidierter Fassung", application code "BrKons") from the /Bundesrecht
# endpoint.  Unlike the Judikatur endpoint, BrKons uses a few complex query
# parameters (Fassung, Abschnitt, Sortierung) whose sub-fields are joined to
# the parameter name with a "." separator.  The mapping and normalization of
# these parameters live in ris_federal_utils.R.
# ============================================================================

#' Build a RIS Bundesrecht API Request
#'
#' Construct an `httr2_request` object for the Austrian RIS OGD REST API v2.6
#' `/Bundesrecht` endpoint, application **BrKons** (consolidated federal law).
#' The request is **not executed**; call [ris_perform_federal()] to send it
#' and parse the results, or use [httr2::req_dry_run()] to inspect the URL.
#'
#' @param query Optional full-text query (`Suchworte`). Supports the RIS
#'   full-text operators (space/`und` = AND, `oder` = OR, `nicht` = NOT,
#'   `*` = wildcard, `'phrase'` for exact phrase).
#' @param title Optional title or abbreviation of the legal norm (`Titel`).
#' @param index Optional index reference from the systematic directory of
#'   federal law (`Index`, e.g. `"20/01"`).
#' @param type Optional norm type (`Typ`).
#' @param law_number Optional law number (`Gesetzesnummer`), an exact-match
#'   identifier for the consolidated norm.
#' @param promulgation_organ Optional promulgation organ (`Kundmachungsorgan`),
#'   e.g. `"BGBl. I Nr."`, `"BGBl. II Nr."`, `"RGBl. Nr."`.
#' @param promulgation_number Optional promulgation number
#'   (`Kundmachungsorgannummer`, e.g. `"25/2012"`).
#' @param signature_date Optional signature date (`Unterzeichnungsdatum`,
#'   `YYYY-MM-DD`).
#' @param version_date Optional point-in-time version date
#'   (`Fassung.FassungVom`, `YYYY-MM-DD`): retrieve the consolidated text as it
#'   stood on this date. Cannot be combined with the `effective_*` / `expiry_*`
#'   range arguments.
#' @param effective_from,effective_to Optional entry-into-force date range
#'   (`Fassung.VonInkrafttretensdatum` / `Fassung.BisInkrafttretensdatum`,
#'   `YYYY-MM-DD`).
#' @param expiry_from,expiry_to Optional expiry (out-of-force) date range
#'   (`Fassung.VonAusserkrafttretensdatum` /
#'   `Fassung.BisAusserkrafttretensdatum`, `YYYY-MM-DD`).
#' @param section_from,section_to Optional section (article/paragraph/annex)
#'   range to narrow within a norm (`Abschnitt.Von` / `Abschnitt.Bis`).
#' @param section_type Optional section type (`Abschnitt.Typ`). One of
#'   `"Alle"`, `"Artikel"`, `"Paragraph"`, `"Anlage"` (English aliases
#'   `"all"`, `"article"`, `"paragraph"`, `"annex"`). Required by the API when
#'   a section range is given; defaults to `"Alle"` in that case.
#' @param in_ris_since Optional RIS recency filter (`ImRisSeit`). Accepts API
#'   values (`"Undefined"`, `"EinerWoche"`, `"ZweiWochen"`, `"EinemMonat"`,
#'   `"DreiMonaten"`, `"SechsMonaten"`, `"EinemJahr"`) and English aliases
#'   (`"one_week"`, `"two_weeks"`, `"one_month"`, `"three_months"`,
#'   `"six_months"`, `"one_year"`).
#' @param sort_by Optional sort column (`Sortierung.SortedByColumn`). One of
#'   `"ArtikelParagraphAnlage"`, `"Kurzinformation"`, `"Inkrafttretensdatum"`,
#'   `"Ausserkrafttretensdatum"`.
#' @param sort_direction Optional sort direction (`Sortierung.SortDirection`):
#'   `"Ascending"` or `"Descending"`.
#' @param base_url API base URL. Defaults to [ris_base_url()], which can be
#'   overridden for a session via `options(risAT.base_url = ...)`.
#'
#' @return An `httr2_request` object with an additional `"ris_meta"` attribute
#'   containing the application code, page size, endpoint, and website URLs.
#'   Pass this to [ris_perform_federal()] to execute the search.
#' @export
#'
#' @examplesIf interactive()
#' # Build request, then inspect the URL without hitting the network
#' req <- ris_req_federal(title = "ABGB")
#' httr2::req_dry_run(req)
#'
#' # The consolidated text as it stood on a given date
#' req <- ris_req_federal(title = "MRG", version_date = "2020-01-01")
#'
#' # Execute
#' results <- ris_perform_federal(req)
ris_req_federal <- function(
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
  base_url = ris_base_url()
) {
  # -- Step 0: Assert input types ---------------------------------------------
  checkmate::assert_string(query, null.ok = TRUE, .var.name = "query")
  checkmate::assert_string(title, null.ok = TRUE, .var.name = "title")
  checkmate::assert_string(index, null.ok = TRUE, .var.name = "index")
  checkmate::assert_string(type, null.ok = TRUE, .var.name = "type")
  checkmate::assert_string(law_number, null.ok = TRUE, .var.name = "law_number")
  checkmate::assert_string(
    promulgation_organ,
    null.ok = TRUE,
    .var.name = "promulgation_organ"
  )
  checkmate::assert_string(
    promulgation_number,
    null.ok = TRUE,
    .var.name = "promulgation_number"
  )
  checkmate::assert_string(
    section_from,
    null.ok = TRUE,
    .var.name = "section_from"
  )
  checkmate::assert_string(section_to, null.ok = TRUE, .var.name = "section_to")
  date_args <- list(
    signature_date = signature_date,
    version_date = version_date,
    effective_from = effective_from,
    effective_to = effective_to,
    expiry_from = expiry_from,
    expiry_to = expiry_to
  )
  for (nm in names(date_args)) {
    checkmate::assert_string(
      date_args[[nm]],
      null.ok = TRUE,
      pattern = "^\\d{4}-\\d{2}-\\d{2}$",
      .var.name = nm
    )
  }
  checkmate::assert_string(base_url, .var.name = "base_url")

  # -- Step 1: Cross-argument validation --------------------------------------
  # The API's Fassung parameter is "either/or": a point-in-time version
  # (version_date) OR entry-into-force / expiry ranges, never both.
  has_range <- !is.null(effective_from) ||
    !is.null(effective_to) ||
    !is.null(expiry_from) ||
    !is.null(expiry_to)
  if (!is.null(version_date) && has_range) {
    rlang::abort(
      paste0(
        "`version_date` (point-in-time version) cannot be combined with ",
        "`effective_*` / `expiry_*` date ranges. Use one or the other."
      ),
      class = "risat_invalid_argument"
    )
  }

  # Abschnitt.Typ is mandatory whenever a section range is supplied.  Default
  # it to "Alle" (all section types) when the caller gave a range but no type.
  if ((!is.null(section_from) || !is.null(section_to)) && is.null(section_type)) {
    section_type <- "Alle"
  }

  # -- Step 2: Assemble API query parameters ----------------------------------
  params <- ris_build_federal_params(
    query = query,
    title = title,
    index = index,
    type = type,
    law_number = law_number,
    promulgation_organ = promulgation_organ,
    promulgation_number = promulgation_number,
    signature_date = signature_date,
    version_date = version_date,
    effective_from = effective_from,
    effective_to = effective_to,
    expiry_from = expiry_from,
    expiry_to = expiry_to,
    section_from = section_from,
    section_to = section_to,
    section_type = section_type,
    in_ris_since = in_ris_since,
    sort_by = sort_by,
    sort_direction = sort_direction,
    page = 1L,
    per_page = 100L
  )

  # -- Step 3: Build equivalent RIS website URLs ------------------------------
  website_urls <- ris_build_federal_website_urls(
    query = query,
    title = title,
    index = index,
    type = type,
    law_number = law_number,
    promulgation_organ = promulgation_organ,
    promulgation_number = promulgation_number,
    version_date = version_date,
    effective_from = effective_from,
    effective_to = effective_to,
    expiry_from = expiry_from,
    expiry_to = expiry_to,
    in_ris_since = in_ris_since,
    per_page = 100L
  )

  # -- Step 4: Construct the httr2 request object -----------------------------
  # ris_base_request() applies the shared request policy (user agent, retry,
  # throttling).  Query-parameter names containing "." (e.g.
  # "Fassung.FassungVom") are valid and are spliced verbatim into the URL.
  req <- ris_base_request(base_url, "/Bundesrecht") |>
    httr2::req_url_query(!!!params)

  # Bridge metadata between the req and perform steps.
  attr(req, "ris_meta") <- list(
    application_code = "BrKons",
    per_page = 100L,
    endpoint = "/Bundesrecht",
    website_urls = website_urls
  )

  req
}
