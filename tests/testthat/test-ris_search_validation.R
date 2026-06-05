test_that("echo must be a logical flag", {
  expect_error(
    ris_search_case_law(application = "Vwgh", echo = "yes"),
    "Assertion on 'echo' failed"
  )
  expect_error(
    ris_search_vwgh(echo = "yes"),
    "Assertion on 'echo' failed"
  )
  expect_error(
    ris_search_vfgh(echo = "yes"),
    "Assertion on 'echo' failed"
  )
})

test_that("at least one document type flag must be enabled", {
  expect_error(
    ris_search_vwgh(
      search_decision_text = FALSE,
      search_legal_principles = FALSE
    ),
    "At least one of `search_decision_text` or `search_legal_principles` must be TRUE."
  )
})

test_that("website URL helper builds expected RIS Ergebnis.wxe URL", {
  urls <- risAT:::ris_build_case_law_website_urls(
    application_code = "Vfgh",
    query = "Grundrecht",
    business_number = "U485/2012",
    norm = "AsylG 2005 §3",
    decision_date_from = "2026-01-01",
    decision_date_to = "2026-02-28",
    decision_type = "Undefined",
    index_term = "41/02",
    collection_number = "19752",
    in_ris_since = "one_week",
    search_decision_text = FALSE,
    search_legal_principles = TRUE,
    per_page = 100
  )

  expect_equal(urls$app_url, "https://www.ris.bka.gv.at/Vfgh/")
  expect_match(urls$search_url, "^https://www\\.ris\\.bka\\.gv\\.at/Ergebnis\\.wxe\\?")
  expect_match(urls$search_url, "Abfrage=Vfgh")
  expect_match(urls$search_url, "Entscheidungsart=Undefined")
  expect_match(urls$search_url, "SucheNachRechtssatz=True")
  expect_match(urls$search_url, "SucheNachText=False")
  expect_match(urls$search_url, "VonDatum=01\\.01\\.2026")
  expect_match(urls$search_url, "BisDatum=28\\.02\\.2026")
  expect_match(urls$search_url, "ImRisSeit=EinerWoche")
  expect_match(urls$search_url, "ResultPageSize=100")
  expect_match(urls$search_url, "Position=1")
  expect_match(urls$search_url, "SkipToDocumentPage=true")
})

test_that("english args are mapped to documented German RIS parameters", {
  params <- risAT:::ris_build_case_law_params(
    application_code = "Vwgh",
    query = "Baurecht",
    business_number = "Ra 2024/01/0001",
    norm = "B-VG",
    decision_date_from = "2024-01-01",
    decision_date_to = "2024-12-31",
    decision_type = "Erkenntnis",
    index_term = "81/01",
    collection_number = "12345",
    search_decision_text = TRUE,
    search_legal_principles = FALSE,
    page = 2,
    per_page = 100
  )

  expect_equal(params$Applikation, "Vwgh")
  expect_equal(params$Suchworte, "Baurecht")
  expect_equal(params$Geschaeftszahl, "Ra 2024/01/0001")
  expect_equal(params$Norm, "B-VG")
  expect_equal(params$EntscheidungsdatumVon, "2024-01-01")
  expect_equal(params$EntscheidungsdatumBis, "2024-12-31")
  expect_equal(params$Entscheidungsart, "Erkenntnis")
  expect_equal(params$Index, "81/01")
  expect_equal(params$Sammlungsnummer, "12345")
  expect_equal(params$DokumenttypSucheInEntscheidungstexten, "true")
  expect_false("DokumenttypSucheInRechtssaetzen" %in% names(params))
  expect_equal(params$Seitennummer, 2)
  expect_equal(params$DokumenteProSeite, "OneHundred")
})

test_that("all Judikatur applications can be mapped from english or RIS codes", {
  expect_equal(risAT:::ris_case_law_application_to_code("administrative_court"), "Vwgh")
  expect_equal(risAT:::ris_case_law_application_to_code("constitutional_court"), "Vfgh")
  expect_equal(risAT:::ris_case_law_application_to_code("justice"), "Justiz")
  expect_equal(risAT:::ris_case_law_application_to_code("federal_administrative_court"), "Bvwg")
  expect_equal(risAT:::ris_case_law_application_to_code("state_administrative_courts"), "Lvwg")
  expect_equal(risAT:::ris_case_law_application_to_code("procurement_review_bodies"), "Verg")
  expect_equal(risAT:::ris_case_law_application_to_code("AsylGH"), "AsylGH")

  expect_error(
    risAT:::ris_case_law_application_to_code("invalid_app"),
    "`application` is invalid."
  )
})

test_that("VfGH defaults search legal principles only (RS)", {
  expect_identical(formals(ris_search_vfgh)$search_decision_text, FALSE)
  expect_identical(formals(ris_search_vfgh)$search_legal_principles, TRUE)
})

test_that("named interval parameters accept english aliases", {
  expect_equal(risAT:::ris_normalize_named_interval("one_week"), "EinerWoche")
  expect_equal(risAT:::ris_normalize_named_interval("two_weeks"), "ZweiWochen")
  expect_equal(risAT:::ris_normalize_named_interval("one_month"), "EinemMonat")
  expect_equal(risAT:::ris_normalize_named_interval("three_months"), "DreiMonaten")
  expect_equal(risAT:::ris_normalize_named_interval("six_months"), "SechsMonaten")
  expect_equal(risAT:::ris_normalize_named_interval("one_year"), "EinemJahr")
})

test_that("VfGH decision_type and sort_by can use english aliases", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Vfgh", "judgment"),
    "Erkenntnis"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Vfgh", "not_specified"),
    "KeineAngabe"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_sort_by("Vfgh", "business_number"),
    "Geschaeftszahl"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_sort_by("Vfgh", "decision_type"),
    "Art"
  )

  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Vfgh", "invalid_type"),
    "Assertion on 'decision_type' failed"
  )
  expect_error(
    risAT:::ris_normalize_case_law_sort_by("Vfgh", "invalid_sort"),
    "Assertion on 'sort_by' failed"
  )
})

test_that("VwGH decision_type is validated against documented values", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Vwgh", "BeschlussVS"),
    "BeschlussVS"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Vwgh", "erkenntnisvs"),
    "ErkenntnisVS"
  )
  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Vwgh", "Vergleich"),
    "Assertion on 'decision_type' failed"
  )
})

test_that("VwGH and VfGH sort_by is validated against documented values", {
  expect_equal(
    risAT:::ris_normalize_case_law_sort_by("Vwgh", "Datum"),
    "Datum"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_sort_by("Vwgh", "decision_date"),
    "Datum"
  )
  expect_error(
    risAT:::ris_normalize_case_law_sort_by("Vwgh", "invalid_sort"),
    "Assertion on 'sort_by' failed"
  )
})

test_that("document type flags are ignored for apps without Dokumenttyp", {
  flags <- expect_warning(
    risAT:::ris_normalize_document_type_flags(
      application_code = "Normenliste",
      search_decision_text = TRUE,
      search_legal_principles = TRUE
    ),
    "are ignored for this Judikatur application"
  )
  expect_null(flags$search_decision_text)
  expect_null(flags$search_legal_principles)

  params <- risAT:::ris_build_case_law_params(
    application_code = "Normenliste",
    query = "Baurecht",
    norm = "B-VG",
    title = "Example",
    document_kind = "Norm",
    publication_organ = "BGBl.",
    search_decision_text = flags$search_decision_text,
    search_legal_principles = flags$search_legal_principles,
    page = 1,
    per_page = 100
  )

  expect_false("DokumenttypSucheInEntscheidungstexten" %in% names(params))
  expect_false("DokumenttypSucheInRechtssaetzen" %in% names(params))
  expect_equal(params$Applikation, "Normenliste")
  expect_equal(params$Titel, "Example")
  expect_equal(params$Typ, "Norm")
  expect_equal(params$Kundmachungsorgan, "BGBl.")
})

test_that("case law page binding harmonizes mixed list/scalar columns", {
  page_1 <- tibble::tibble(
    vfgh_indices = "41/02",
    content_urls = list(c("https://example.org/1")),
    app_metadata = list(list(request = list(application = "Vfgh")))
  )

  page_2 <- tibble::tibble(
    vfgh_indices = list(c("41/02", "41/03")),
    content_urls = list(c("https://example.org/2")),
    app_metadata = list(list(request = list(application = "Vfgh")))
  )

  out <- risAT:::ris_bind_case_law_pages(list(page_1, page_2))
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_true(is.list(out$vfgh_indices))
  expect_equal(out$vfgh_indices[[1]], "41/02")
  expect_equal(out$vfgh_indices[[2]], c("41/02", "41/03"))
})

test_that("next page calculation for iterative pagination is correct", {
  root_more <- list(
    OgdDocumentResults = list(
      Hits = list(
        pageNumber = "1",
        pageSize = "10",
        `#text` = "25"
      )
    )
  )
  expect_equal(risAT:::ris_next_case_law_page(root_more), 2L)

  root_last <- list(
    OgdDocumentResults = list(
      Hits = list(
        pageNumber = "3",
        pageSize = "10",
        `#text` = "25"
      )
    )
  )
  expect_null(risAT:::ris_next_case_law_page(root_last))

  root_empty <- list(
    OgdDocumentResults = list(
      Hits = list(
        pageNumber = "1",
        pageSize = "10",
        `#text` = "0"
      )
    )
  )
  expect_null(risAT:::ris_next_case_law_page(root_empty))
})

# ---- ris_req_case_law / ris_perform_case_law split --------------------------

test_that("ris_req_case_law returns an httr2_request with ris_meta", {
  req <- ris_req_case_law(
    application = "Vfgh",
    query = "Grundrecht"
  )

  expect_s3_class(req, "httr2_request")

  meta <- attr(req, "ris_meta")
  expect_type(meta, "list")
  expect_equal(meta$application_code, "Vfgh")
  expect_equal(meta$per_page, 100L)
  expect_type(meta$website_urls, "list")
  expect_match(meta$website_urls$app_url, "Vfgh")
  expect_match(meta$website_urls$search_url, "Ergebnis\\.wxe")
})

test_that("ris_req_case_law encodes query params in the URL", {
  req <- ris_req_case_law(
    application = "Vwgh",
    query = "Baurecht",
    decision_type = "Erkenntnis"
  )

  url <- req$url
  expect_match(url, "Applikation=Vwgh")
  expect_match(url, "Suchworte=Baurecht")
  expect_match(url, "Entscheidungsart=Erkenntnis")
  expect_match(url, "DokumenteProSeite=OneHundred")
})

test_that("ris_perform_case_law rejects requests without ris_meta", {
  plain_req <- httr2::request("https://example.org")
  expect_error(
    ris_perform_case_law(plain_req),
    "missing `ris_meta` attribute"
  )
})

test_that("ris_req_case_law accepts English aliases for application", {
  req <- ris_req_case_law(application = "constitutional_court")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Vfgh")
})

# ── New court-specific wrapper tests ──────────────────────────────────────────

test_that("ris_search_justiz routes to Justiz application", {
  req <- ris_req_case_law(application = "Justiz", query = "Schadenersatz")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Justiz")
})

test_that("ris_search_justiz forwards court-specific params to request URL", {
  req <- ris_req_case_law(
    application = "Justiz",
    court = "OGH",
    legal_area = "Zivilrecht",
    legal_principle_number = "0000001",
    citation = "SZ 75/123"
  )
  url <- req$url
  expect_match(url, "Applikation=Justiz")
  expect_match(url, "Gericht=OGH")
  expect_match(url, "Rechtsgebiet=Zivilrecht")
  expect_match(url, "Rechtssatznummer=0000001")
  expect_match(url, "Fundstelle=SZ")
})

test_that("ris_search_justiz rejects invalid echo argument", {
  expect_error(
    ris_search_justiz(echo = "yes"),
    "Assertion on 'echo' failed"
  )
})

test_that("ris_search_bvwg routes to Bvwg application", {
  req <- ris_req_case_law(application = "Bvwg")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Bvwg")
})

test_that("ris_search_bvwg encodes application in URL", {
  req <- ris_req_case_law(application = "Bvwg", query = "Asyl")
  expect_match(req$url, "Applikation=Bvwg")
  expect_match(req$url, "Suchworte=Asyl")
})

test_that("ris_search_bvwg rejects invalid echo argument", {
  expect_error(
    ris_search_bvwg(echo = "yes"),
    "Assertion on 'echo' failed"
  )
})

test_that("ris_search_lvwg routes to Lvwg application", {
  req <- ris_req_case_law(application = "Lvwg")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Lvwg")
})

test_that("ris_search_lvwg forwards federal_state param to request URL", {
  req <- ris_req_case_law(application = "Lvwg", federal_state = "Wien")
  expect_match(req$url, "Applikation=Lvwg")
  expect_match(req$url, "Bundesland=Wien")
})

test_that("ris_search_lvwg rejects invalid echo argument", {
  expect_error(
    ris_search_lvwg(echo = "yes"),
    "Assertion on 'echo' failed"
  )
})

test_that("ris_search_dsk routes to Dsk application", {
  req <- ris_req_case_law(application = "Dsk")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Dsk")
})

test_that("ris_search_dsk forwards deciding_authority param to request URL", {
  req <- ris_req_case_law(
    application = "Dsk",
    deciding_authority = "Datenschutzbeh\u00f6rde"
  )
  expect_match(req$url, "Applikation=Dsk")
  expect_match(req$url, "EntscheidendeBehoerde=")
})

test_that("ris_search_dsk rejects invalid echo argument", {
  expect_error(
    ris_search_dsk(echo = "yes"),
    "Assertion on 'echo' failed"
  )
})

test_that("ris_search_dok routes to Dok application", {
  req <- ris_req_case_law(application = "Dok")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Dok")
})

test_that("ris_search_dok forwards deciding_authority param to request URL", {
  req <- ris_req_case_law(
    application = "Dok",
    deciding_authority = "Bundesdisziplinarbeh\u00f6rde"
  )
  expect_match(req$url, "Applikation=Dok")
  expect_match(req$url, "EntscheidendeBehoerde=")
})

test_that("ris_search_pvak routes to Pvak application", {
  req <- ris_req_case_law(application = "Pvak")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Pvak")
})

test_that("ris_search_pvak forwards deciding_authority param to request URL", {
  req <- ris_req_case_law(
    application = "Pvak",
    deciding_authority = "Personalvertretungsaufsichtsbeh\u00f6rde"
  )
  expect_match(req$url, "Applikation=Pvak")
  expect_match(req$url, "EntscheidendeBehoerde=")
})

test_that("ris_search_gbk routes to Gbk application", {
  req <- ris_req_case_law(application = "Gbk")
  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Gbk")
})

test_that("ris_search_gbk forwards commission, senate, and discrimination_ground to URL", {
  req <- ris_req_case_law(
    application = "Gbk",
    commission = "Gleichbehandlungskommission",
    senate = "Senat I",
    discrimination_ground = "Geschlecht"
  )
  url <- req$url
  expect_match(url, "Applikation=Gbk")
  expect_match(url, "Kommission=Gleichbehandlungskommission")
  expect_match(url, "Senat=Senat")
  expect_match(url, "Diskriminierungsgrund=Geschlecht")
})

test_that("ris_search_gbk does not accept search_decision_text or search_legal_principles", {
  # Gbk wrapper intentionally omits these params — verify the function
  # signature does not include them by checking formals()
  gbk_args <- names(formals(ris_search_gbk))
  expect_false("search_decision_text" %in% gbk_args)
  expect_false("search_legal_principles" %in% gbk_args)
})

test_that("ris_search_gbk rejects invalid echo argument", {
  expect_error(
    ris_search_gbk(echo = "yes"),
    "Assertion on 'echo' failed"
  )
})

# ── Input type validation (checkmate assertions) ────────────────────────────

test_that("common string params reject non-string input", {
  expect_error(
    ris_req_case_law(application = "Vwgh", query = 123),
    "Assertion on 'query' failed"
  )
  expect_error(
    ris_req_case_law(application = "Vwgh", business_number = TRUE),
    "Assertion on 'business_number' failed"
  )
  expect_error(
    ris_req_case_law(application = "Vwgh", norm = 42),
    "Assertion on 'norm' failed"
  )
  expect_error(
    ris_req_case_law(application = "Vwgh", index_term = list("a")),
    "Assertion on 'index_term' failed"
  )
  expect_error(
    ris_req_case_law(application = "Vwgh", collection_number = 123),
    "Assertion on 'collection_number' failed"
  )
  expect_error(
    ris_req_case_law(application = "Vwgh", base_url = NULL),
    "Assertion on 'base_url' failed"
  )
})

test_that("date params reject malformed strings", {
  expect_error(
    ris_req_case_law(application = "Vwgh", decision_date_from = "01-2024-01"),
    "Assertion on 'decision_date_from' failed"
  )
  expect_error(
    ris_req_case_law(application = "Vwgh", decision_date_to = "2024/01/01"),
    "Assertion on 'decision_date_to' failed"
  )
  expect_error(
    ris_req_case_law(application = "Vwgh", decision_date_from = 20240101),
    "Assertion on 'decision_date_from' failed"
  )
})

test_that("date params accept valid ISO dates", {
  req <- ris_req_case_law(
    application = "Vwgh",
    decision_date_from = "2024-01-01",
    decision_date_to = "2024-12-31"
  )
  expect_s3_class(req, "httr2_request")
})

test_that("common string params accept NULL", {
  req <- ris_req_case_law(
    application = "Vwgh",
    query = NULL,
    business_number = NULL,
    norm = NULL,
    decision_date_from = NULL,
    decision_date_to = NULL
  )
  expect_s3_class(req, "httr2_request")
})

# ── Decision type validation for newly covered courts ───────────────────────

test_that("BVwG decision_type is validated against documented values", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Bvwg", "Erkenntnis"),
    "Erkenntnis"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Bvwg", "beschluss"),
    "Beschluss"
  )
  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Bvwg", "BeschlussVS"),
    "Assertion on 'decision_type' failed"
  )
  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Bvwg", "Vergleich"),
    "Assertion on 'decision_type' failed"
  )
})

test_that("LVwG decision_type is validated against documented values", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Lvwg", "Bescheid"),
    "Bescheid"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Lvwg", "erkenntnis"),
    "Erkenntnis"
  )
  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Lvwg", "BeschlussVS"),
    "Assertion on 'decision_type' failed"
  )
})

test_that("Justiz decision_type is validated against documented values", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type(
      "Justiz", "Ordentliche Erledigung (Sachentscheidung)"
    ),
    "Ordentliche Erledigung (Sachentscheidung)"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type(
      "Justiz", "Verst\u00e4rkter Senat"
    ),
    "Verst\u00e4rkter Senat"
  )
  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Justiz", "Erkenntnis"),
    "Assertion on 'decision_type' failed"
  )
})

test_that("Dsk decision_type is validated against documented values", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Dsk", "BescheidBeschwerde"),
    "BescheidBeschwerde"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Dsk", "Empfehlung"),
    "Empfehlung"
  )
  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Dsk", "Erkenntnis"),
    "Assertion on 'decision_type' failed"
  )
})

test_that("Gbk decision_type is validated against documented values", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Gbk", "Gutachten"),
    "Gutachten"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type(
      "Gbk", "Einzelfallpruefungsergebnis"
    ),
    "Einzelfallpruefungsergebnis"
  )
  expect_error(
    risAT:::ris_normalize_case_law_decision_type("Gbk", "Beschluss"),
    "Assertion on 'decision_type' failed"
  )
})

test_that("Dok and Pvak pass decision_type through (free-text)", {
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Dok", "SomeType"),
    "SomeType"
  )
  expect_equal(
    risAT:::ris_normalize_case_law_decision_type("Pvak", "AnotherType"),
    "AnotherType"
  )
})

# ── Wrapper-specific param validation ───────────────────────────────────────

test_that("ris_search_justiz rejects non-string wrapper params", {
  expect_error(
    ris_search_justiz(court = 123),
    "Assertion on 'court' failed"
  )
  expect_error(
    ris_search_justiz(legal_area = TRUE),
    "Assertion on 'legal_area' failed"
  )
  expect_error(
    ris_search_justiz(citation = list("x")),
    "Assertion on 'citation' failed"
  )
})

test_that("ris_search_lvwg rejects non-string federal_state", {
  expect_error(
    ris_search_lvwg(federal_state = 42),
    "`federal_state` must be a single string"
  )
})

test_that("ris_search_dsk rejects non-string deciding_authority", {
  expect_error(
    ris_search_dsk(deciding_authority = TRUE),
    "Assertion on 'deciding_authority' failed"
  )
})

test_that("ris_search_gbk rejects non-string commission and senate", {
  expect_error(
    ris_search_gbk(commission = 123),
    "`commission` must be a single string"
  )
  expect_error(
    ris_search_gbk(senate = TRUE),
    "`senate` must be a single string"
  )
  expect_error(
    ris_search_gbk(discrimination_ground = list("x")),
    "`discrimination_ground` must be a single string"
  )
})

# ── federal_state normalizer ─────────────────────────────────────────────────

test_that("ris_normalize_federal_state accepts canonical German names", {
  expect_equal(risAT:::ris_normalize_federal_state("Wien"),             "Wien")
  expect_equal(risAT:::ris_normalize_federal_state("Steiermark"),       "Steiermark")
  expect_equal(risAT:::ris_normalize_federal_state("Burgenland"),       "Burgenland")
  expect_equal(risAT:::ris_normalize_federal_state("Tirol"),            "Tirol")
  expect_equal(risAT:::ris_normalize_federal_state("Vorarlberg"),       "Vorarlberg")
  expect_equal(risAT:::ris_normalize_federal_state("Salzburg"),         "Salzburg")
  expect_equal(risAT:::ris_normalize_federal_state("K\u00e4rnten"),     "K\u00e4rnten")
  expect_equal(risAT:::ris_normalize_federal_state("Nieder\u00f6sterreich"), "Nieder\u00f6sterreich")
  expect_equal(risAT:::ris_normalize_federal_state("Ober\u00f6sterreich"),   "Ober\u00f6sterreich")
})

test_that("ris_normalize_federal_state accepts English aliases", {
  expect_equal(risAT:::ris_normalize_federal_state("Vienna"),        "Wien")
  expect_equal(risAT:::ris_normalize_federal_state("Styria"),        "Steiermark")
  expect_equal(risAT:::ris_normalize_federal_state("Carinthia"),     "K\u00e4rnten")
  expect_equal(risAT:::ris_normalize_federal_state("Tyrol"),         "Tirol")
  expect_equal(risAT:::ris_normalize_federal_state("Lower Austria"), "Nieder\u00f6sterreich")
  expect_equal(risAT:::ris_normalize_federal_state("Upper Austria"), "Ober\u00f6sterreich")
})

test_that("ris_normalize_federal_state is case-insensitive", {
  expect_equal(risAT:::ris_normalize_federal_state("wien"),    "Wien")
  expect_equal(risAT:::ris_normalize_federal_state("WIEN"),    "Wien")
  expect_equal(risAT:::ris_normalize_federal_state("VIENNA"),  "Wien")
  expect_equal(risAT:::ris_normalize_federal_state("styria"),  "Steiermark")
})

test_that("ris_normalize_federal_state returns NULL for NULL input", {
  expect_null(risAT:::ris_normalize_federal_state(NULL))
})

test_that("ris_normalize_federal_state errors on invalid value", {
  expect_error(
    risAT:::ris_normalize_federal_state("Bavaria"),
    "`federal_state` is invalid"
  )
  expect_error(
    risAT:::ris_normalize_federal_state("Nonsense"),
    "`federal_state` is invalid"
  )
})

test_that("ris_search_lvwg normalizes federal_state and encodes it in the URL", {
  req <- ris_req_case_law(application = "Lvwg", federal_state = "Vienna")
  expect_match(req$url, "Bundesland=Wien")

  req2 <- ris_req_case_law(application = "Lvwg", federal_state = "styria")
  expect_match(req2$url, "Bundesland=Steiermark")
})

test_that("ris_search_lvwg rejects invalid federal_state", {
  expect_error(
    ris_search_lvwg(federal_state = "Bavaria"),
    "`federal_state` is invalid"
  )
})

# ── GBK commission normalizer ────────────────────────────────────────────────

test_that("ris_normalize_gbk_commission accepts canonical German names", {
  expect_equal(
    risAT:::ris_normalize_gbk_commission("Bundes-Gleichbehandlungskommission"),
    "Bundes-Gleichbehandlungskommission"
  )
  expect_equal(
    risAT:::ris_normalize_gbk_commission("Gleichbehandlungskommission"),
    "Gleichbehandlungskommission"
  )
})

test_that("ris_normalize_gbk_commission accepts short aliases", {
  expect_equal(risAT:::ris_normalize_gbk_commission("bundesgbk"), "Bundes-Gleichbehandlungskommission")
  expect_equal(risAT:::ris_normalize_gbk_commission("bgbk"),      "Bundes-Gleichbehandlungskommission")
  expect_equal(risAT:::ris_normalize_gbk_commission("gbk"),       "Gleichbehandlungskommission")
})

test_that("ris_normalize_gbk_commission accepts English aliases", {
  expect_equal(risAT:::ris_normalize_gbk_commission("federal"),         "Bundes-Gleichbehandlungskommission")
  expect_equal(risAT:::ris_normalize_gbk_commission("private_sector"),  "Gleichbehandlungskommission")
})

test_that("ris_normalize_gbk_commission is case-insensitive", {
  expect_equal(risAT:::ris_normalize_gbk_commission("GBK"),    "Gleichbehandlungskommission")
  expect_equal(risAT:::ris_normalize_gbk_commission("BGBK"),   "Bundes-Gleichbehandlungskommission")
  expect_equal(risAT:::ris_normalize_gbk_commission("Federal"), "Bundes-Gleichbehandlungskommission")
})

test_that("ris_normalize_gbk_commission returns NULL for NULL input", {
  expect_null(risAT:::ris_normalize_gbk_commission(NULL))
})

test_that("ris_normalize_gbk_commission errors on invalid value", {
  expect_error(
    risAT:::ris_normalize_gbk_commission("Nonsense"),
    "`commission` is invalid"
  )
})

# ── GBK senate normalizer ────────────────────────────────────────────────────

test_that("ris_normalize_gbk_senate accepts full canonical names", {
  expect_equal(risAT:::ris_normalize_gbk_senate("Senat I"),   "Senat I")
  expect_equal(risAT:::ris_normalize_gbk_senate("Senat II"),  "Senat II")
  expect_equal(risAT:::ris_normalize_gbk_senate("Senat III"), "Senat III")
})

test_that("ris_normalize_gbk_senate accepts Roman numeral aliases", {
  expect_equal(risAT:::ris_normalize_gbk_senate("I"),   "Senat I")
  expect_equal(risAT:::ris_normalize_gbk_senate("II"),  "Senat II")
  expect_equal(risAT:::ris_normalize_gbk_senate("III"), "Senat III")
})

test_that("ris_normalize_gbk_senate accepts digit aliases", {
  expect_equal(risAT:::ris_normalize_gbk_senate("1"), "Senat I")
  expect_equal(risAT:::ris_normalize_gbk_senate("2"), "Senat II")
  expect_equal(risAT:::ris_normalize_gbk_senate("3"), "Senat III")
})

test_that("ris_normalize_gbk_senate returns NULL for NULL input", {
  expect_null(risAT:::ris_normalize_gbk_senate(NULL))
})

test_that("ris_normalize_gbk_senate errors on invalid value", {
  expect_error(
    risAT:::ris_normalize_gbk_senate("IV"),
    "`senate` is invalid"
  )
  expect_error(
    risAT:::ris_normalize_gbk_senate("4"),
    "`senate` is invalid"
  )
})

# ── GBK discrimination_ground normalizer ─────────────────────────────────────

test_that("ris_normalize_gbk_discrimination_ground accepts canonical German values", {
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("Geschlecht"),              "Geschlecht")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("Religion"),                "Religion")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("Weltanschauung"),          "Weltanschauung")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("Alter"),                   "Alter")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("Behinderung"),             "Behinderung")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("Mehrfachdiskriminierung"), "Mehrfachdiskriminierung")
  expect_equal(
    risAT:::ris_normalize_gbk_discrimination_ground("Ethnische Zugeh\u00f6rigkeit"),
    "Ethnische Zugeh\u00f6rigkeit"
  )
  expect_equal(
    risAT:::ris_normalize_gbk_discrimination_ground("Sexuelle Orientierung"),
    "Sexuelle Orientierung"
  )
})

test_that("ris_normalize_gbk_discrimination_ground accepts English aliases", {
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("gender"),             "Geschlecht")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("sex"),                "Geschlecht")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("age"),                "Alter")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("disability"),         "Behinderung")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("ethnicity"),          "Ethnische Zugeh\u00f6rigkeit")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("sexual_orientation"), "Sexuelle Orientierung")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("worldview"),          "Weltanschauung")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("multiple"),           "Mehrfachdiskriminierung")
})

test_that("ris_normalize_gbk_discrimination_ground is case-insensitive", {
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("Gender"),   "Geschlecht")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("GENDER"),   "Geschlecht")
  expect_equal(risAT:::ris_normalize_gbk_discrimination_ground("geschlecht"), "Geschlecht")
})

test_that("ris_normalize_gbk_discrimination_ground returns NULL for NULL input", {
  expect_null(risAT:::ris_normalize_gbk_discrimination_ground(NULL))
})

test_that("ris_normalize_gbk_discrimination_ground errors on invalid value", {
  expect_error(
    risAT:::ris_normalize_gbk_discrimination_ground("Nationalitaet"),
    "`discrimination_ground` is invalid"
  )
})

test_that("ris_search_gbk normalizes and encodes GBK-specific params in URL", {
  req <- ris_req_case_law(
    application = "Gbk",
    commission = "gbk",
    senate = "1",
    discrimination_ground = "gender"
  )
  url <- req$url
  expect_match(url, "Kommission=Gleichbehandlungskommission")
  expect_match(url, "Senat=Senat%20I")
  expect_match(url, "Diskriminierungsgrund=Geschlecht")
})

test_that("ris_search_gbk rejects invalid commission", {
  expect_error(
    ris_search_gbk(commission = "Nonsense"),
    "`commission` is invalid"
  )
})

test_that("ris_search_gbk rejects invalid senate", {
  expect_error(
    ris_search_gbk(senate = "IV"),
    "`senate` is invalid"
  )
})

test_that("ris_search_gbk rejects invalid discrimination_ground", {
  expect_error(
    ris_search_gbk(discrimination_ground = "Nationalitaet"),
    "`discrimination_ground` is invalid"
  )
})
