# ============================================================================
# Tests for the Bundesrecht (BrKons) request side: parameter building,
# normalizers, cross-argument validation, and website URL building.
# No live API calls.
# ============================================================================

test_that("english args map to documented German BrKons parameters", {
  params <- risAT:::ris_build_federal_params(
    query = "Mietzins",
    title = "ABGB",
    index = "20/01",
    type = "BG",
    law_number = "10001622",
    promulgation_organ = "BGBl. Nr.",
    promulgation_number = "946/1811",
    signature_date = "1811-06-01",
    in_ris_since = "one_month",
    sort_by = "effective_date",
    sort_direction = "Descending",
    page = 2,
    per_page = 100
  )

  expect_equal(params$Applikation, "BrKons")
  expect_equal(params$Suchworte, "Mietzins")
  expect_equal(params$Titel, "ABGB")
  expect_equal(params$Index, "20/01")
  expect_equal(params$Typ, "BG")
  expect_equal(params$Gesetzesnummer, "10001622")
  expect_equal(params$Kundmachungsorgan, "BGBl. Nr.")
  expect_equal(params$Kundmachungsorgannummer, "946/1811")
  expect_equal(params$Unterzeichnungsdatum, "1811-06-01")
  expect_equal(params$ImRisSeit, "EinemMonat")
  expect_equal(params[["Sortierung.SortDirection"]], "Descending")
  expect_equal(params[["Sortierung.SortedByColumn"]], "Inkrafttretensdatum")
  expect_equal(params$Seitennummer, 2)
  expect_equal(params$DokumenteProSeite, "OneHundred")
})

test_that("Fassung version_date maps to dotted FassungVom param", {
  params <- risAT:::ris_build_federal_params(version_date = "2020-01-01")
  expect_equal(params[["Fassung.FassungVom"]], "2020-01-01")
  expect_false("Fassung.VonInkrafttretensdatum" %in% names(params))
})

test_that("Fassung date ranges map to dotted Inkrafttreten/Ausserkrafttreten params", {
  params <- risAT:::ris_build_federal_params(
    effective_from = "2024-01-01",
    effective_to = "2024-12-31",
    expiry_from = "2025-01-01",
    expiry_to = "2025-12-31"
  )
  expect_equal(params[["Fassung.VonInkrafttretensdatum"]], "2024-01-01")
  expect_equal(params[["Fassung.BisInkrafttretensdatum"]], "2024-12-31")
  expect_equal(params[["Fassung.VonAusserkrafttretensdatum"]], "2025-01-01")
  expect_equal(params[["Fassung.BisAusserkrafttretensdatum"]], "2025-12-31")
})

test_that("Abschnitt range maps to dotted params with normalized Typ", {
  params <- risAT:::ris_build_federal_params(
    section_from = "1",
    section_to = "10",
    section_type = "paragraph"
  )
  expect_equal(params[["Abschnitt.Von"]], "1")
  expect_equal(params[["Abschnitt.Bis"]], "10")
  expect_equal(params[["Abschnitt.Typ"]], "Paragraph")
})

test_that("NULL/empty params are dropped from the query list", {
  params <- risAT:::ris_build_federal_params(title = "ABGB")
  expect_false("Suchworte" %in% names(params))
  expect_false("Fassung.FassungVom" %in% names(params))
  expect_false("Index" %in% names(params))
})

# ---- normalizers ------------------------------------------------------------

test_that("ris_normalize_abschnitt_typ accepts German values and English aliases", {
  expect_equal(risAT:::ris_normalize_abschnitt_typ("Alle"), "Alle")
  expect_equal(risAT:::ris_normalize_abschnitt_typ("artikel"), "Artikel")
  expect_equal(risAT:::ris_normalize_abschnitt_typ("paragraph"), "Paragraph")
  expect_equal(risAT:::ris_normalize_abschnitt_typ("annex"), "Anlage")
  expect_null(risAT:::ris_normalize_abschnitt_typ(NULL))
})

test_that("ris_normalize_abschnitt_typ errors on invalid value", {
  expect_snapshot(
    risAT:::ris_normalize_abschnitt_typ("Kapitel"),
    error = TRUE
  )
})

test_that("ris_normalize_federal_sort_column accepts values and aliases", {
  expect_equal(
    risAT:::ris_normalize_federal_sort_column("Inkrafttretensdatum"),
    "Inkrafttretensdatum"
  )
  expect_equal(
    risAT:::ris_normalize_federal_sort_column("effective_date"),
    "Inkrafttretensdatum"
  )
  expect_equal(
    risAT:::ris_normalize_federal_sort_column("expiry_date"),
    "Ausserkrafttretensdatum"
  )
  expect_null(risAT:::ris_normalize_federal_sort_column(NULL))
})

test_that("ris_normalize_federal_sort_column errors on invalid value", {
  expect_snapshot(
    risAT:::ris_normalize_federal_sort_column("Datum"),
    error = TRUE
  )
})

# ---- ris_req_federal ----------------------------------------------------

test_that("ris_req_federal returns an httr2_request with ris_meta", {
  req <- ris_req_federal(title = "ABGB")

  expect_s3_class(req, "httr2_request")

  meta <- attr(req, "ris_meta")
  expect_type(meta, "list")
  expect_equal(meta$application_code, "BrKons")
  expect_equal(meta$per_page, 100L)
  expect_equal(meta$endpoint, "/Bundesrecht")
  expect_match(meta$website_urls$app_url, "Bundesrecht")
})

test_that("ris_req_federal encodes query params (incl. dotted) in the URL", {
  req <- ris_req_federal(
    title = "ABGB",
    version_date = "2020-01-01"
  )
  url <- req$url
  expect_match(url, "/Bundesrecht")
  expect_match(url, "Applikation=BrKons")
  expect_match(url, "Titel=ABGB")
  expect_match(url, "Fassung\\.FassungVom=2020-01-01")
  expect_match(url, "DokumenteProSeite=OneHundred")
})

test_that("ris_req_federal rejects version_date combined with a date range", {
  expect_snapshot(
    ris_req_federal(
      version_date = "2020-01-01",
      effective_from = "2019-01-01"
    ),
    error = TRUE
  )
})

test_that("ris_req_federal defaults Abschnitt.Typ to Alle when range given", {
  req <- ris_req_federal(section_from = "1", section_to = "5")
  expect_match(req$url, "Abschnitt\\.Typ=Alle")
})

test_that("ris_req_federal rejects malformed date strings", {
  expect_snapshot(
    ris_req_federal(version_date = "01.01.2020"),
    error = TRUE
  )
  expect_snapshot(
    ris_req_federal(effective_from = "2020/01/01"),
    error = TRUE
  )
})

test_that("ris_req_federal rejects non-string params", {
  expect_snapshot(
    ris_req_federal(title = 123),
    error = TRUE
  )
})

test_that("ris_perform_federal rejects requests without ris_meta", {
  plain_req <- httr2::request("https://example.org")
  expect_snapshot(
    ris_perform_federal(plain_req),
    error = TRUE
  )
})

# ---- website URL builder ----------------------------------------------------

test_that("website URL helper builds expected RIS Bundesnormen URL", {
  urls <- risAT:::ris_build_federal_website_urls(
    title = "ABGB",
    version_date = "2020-01-01",
    in_ris_since = "one_month",
    per_page = 100
  )

  expect_equal(urls$app_url, "https://www.ris.bka.gv.at/Bundesrecht/")
  expect_match(
    urls$search_url,
    "^https://www\\.ris\\.bka\\.gv\\.at/Ergebnis\\.wxe\\?"
  )
  expect_match(urls$search_url, "Abfrage=Bundesnormen")
  expect_match(urls$search_url, "Titel=ABGB")
  expect_match(urls$search_url, "FassungVom=01\\.01\\.2020")
  expect_match(urls$search_url, "ImRisSeit=EinemMonat")
  expect_match(urls$search_url, "ResultPageSize=100")
})
