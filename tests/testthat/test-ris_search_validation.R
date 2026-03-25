test_that("pagination arguments are validated before API calls", {
  expect_error(
    ris_search_vfgh(per_page = 0),
    "`per_page` must be one of: 10, 20, 50, 100."
  )

  expect_error(
    ris_search_vfgh(per_page = 15),
    "`per_page` must be one of: 10, 20, 50, 100."
  )
})

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
    per_page = 50
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
  expect_equal(params$SucheInEntscheidungstexten, "true")
  expect_false("SucheInRechtssaetzen" %in% names(params))
  expect_equal(params$Seitennummer, 2)
  expect_equal(params$DokumenteProSeite, "Fifty")
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
    per_page = 20
  )

  expect_false("SucheInEntscheidungstexten" %in% names(params))
  expect_false("SucheInRechtssaetzen" %in% names(params))
  expect_equal(params$Applikation, "Normenliste")
  expect_equal(params$Titel, "Example")
  expect_equal(params$Typ, "Norm")
  expect_equal(params$Kundmachungsorgan, "BGBl.")
})

test_that("case law page binding harmonizes mixed list/scalar columns", {
  page_1 <- tibble::tibble(
    page = 1L,
    per_page = 10L,
    judikatur_vfgh_indizes_item = "41/02",
    content_urls = list(c("https://example.org/1")),
    app_metadata = list(list(request = list(application = "Vfgh")))
  )

  page_2 <- tibble::tibble(
    page = 2L,
    per_page = 10L,
    judikatur_vfgh_indizes_item = list(c("41/02", "41/03")),
    content_urls = list(c("https://example.org/2")),
    app_metadata = list(list(request = list(application = "Vfgh")))
  )

  out <- risAT:::ris_bind_case_law_pages(list(page_1, page_2))
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_true(is.list(out$judikatur_vfgh_indizes_item))
  expect_equal(out$judikatur_vfgh_indizes_item[[1]], "41/02")
  expect_equal(out$judikatur_vfgh_indizes_item[[2]], c("41/02", "41/03"))
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
    query = "Grundrecht",
    per_page = 50
  )

  expect_s3_class(req, "httr2_request")

  meta <- attr(req, "ris_meta")
  expect_type(meta, "list")
  expect_equal(meta$application_code, "Vfgh")
  expect_equal(meta$per_page, 50L)
  expect_type(meta$website_urls, "list")
  expect_match(meta$website_urls$app_url, "Vfgh")
  expect_match(meta$website_urls$search_url, "Ergebnis\\.wxe")
})

test_that("ris_req_case_law validates per_page", {
  expect_error(
    ris_req_case_law(application = "Vfgh", per_page = 15),
    "`per_page` must be one of: 10, 20, 50, 100."
  )
})

test_that("ris_req_case_law encodes query params in the URL", {
  req <- ris_req_case_law(
    application = "Vwgh",
    query = "Baurecht",
    decision_type = "Erkenntnis",
    per_page = 20
  )

  url <- req$url
  expect_match(url, "Applikation=Vwgh")
  expect_match(url, "Suchworte=Baurecht")
  expect_match(url, "Entscheidungsart=Erkenntnis")
  expect_match(url, "DokumenteProSeite=Twenty")
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
