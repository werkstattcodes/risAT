fixture_payload <- function(name) {
  path <- testthat::test_path("fixtures", name)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

test_that("ris_req_case_law builds Judikatur request with mapped parameters", {
  req <- ris_req_case_law(
    application = "Vwgh",
    query = "Asyl",
    business_number = "Ra 2026/01/0001",
    decision_date_from = "2026-01-01",
    decision_date_to = "2026-01-31",
    search_decision_text = TRUE,
    search_legal_principles = TRUE
  )

  expect_s3_class(req, "httr2_request")
  expect_match(req$url, "/Judikatur$")
  expect_match(req$url, "Applikation=Vwgh")
  expect_match(req$url, "Suchworte=Asyl")
  expect_match(req$url, "Geschaeftszahl=Ra%202026%2F01%2F0001")
  expect_match(req$url, "EntscheidungsdatumVon=2026-01-01")
  expect_match(req$url, "EntscheidungsdatumBis=2026-01-31")
  expect_match(req$url, "DokumenttypSucheInEntscheidungstexten=true")
  expect_match(req$url, "DokumenttypSucheInRechtssaetzen=true")

  meta <- attr(req, "ris_meta")
  expect_equal(meta$application_code, "Vwgh")
  expect_equal(meta$per_page, 100L)
  expect_match(meta$website_urls$app_url, "https://www.ris.bka.gv.at/Vwgh/")
})

test_that("ris_perform_case_law parses one-page fixture with stable list-columns", {
  req <- ris_req_case_law(application = "Vwgh", query = "Asyl")
  payload <- fixture_payload("case_law_one_page.json")

  out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req) list(payload),
    ris_perform_case_law(req)
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_true(all(c("content_urls", "app_metadata") %in% names(out)))
  expect_type(out$content_urls[[1]], "character")
  expect_gte(length(out$content_urls[[1]]), 1L)
  expect_type(out$app_metadata[[1]], "list")
  expect_equal(out$id[[1]], "Vwgh-2026-0001")
  expect_equal(out$application[[1]], "Vwgh")
  expect_equal(attr(out, "ris_app_url"), "https://www.ris.bka.gv.at/Vwgh/")
})

test_that("ris_perform_case_law combines paginated fixtures", {
  req <- ris_req_case_law(
    application = "Vfgh",
    query = "Grundrecht"
  )
  page1 <- fixture_payload("case_law_multi_page_page1.json")
  page2 <- fixture_payload("case_law_multi_page_page2.json")

  out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req) list(page1, page2),
    ris_perform_case_law(req)
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_equal(out$id, c("Vfgh-2026-0001", "Vfgh-2026-0002"))
  expect_true(is.list(out$index_term))
  expect_equal(out$index_term[[1]], "07/01")
  expect_equal(out$index_term[[2]], c("07/01", "07/02"))
  expect_equal(out$app_metadata[[1]]$request$seitennummer, 1L)
  expect_equal(out$app_metadata[[2]]$request$seitennummer, 2L)
  expect_equal(attr(out, "ris_search_url"), attr(req, "ris_meta")$website_urls$search_url)
})

test_that("ris_perform_case_law returns structured empty tibble for empty fixture", {
  req <- ris_req_case_law(application = "Vwgh", query = "NoHitNeedle")
  empty_payload <- fixture_payload("case_law_empty.json")

  out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req) list(empty_payload),
    ris_perform_case_law(req)
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
  expect_named(out, c("content_urls", "app_metadata"))
  expect_true(is.list(out$content_urls))
  expect_true(is.list(out$app_metadata))
})

test_that("ris_perform_case_law surfaces API error payloads", {
  req <- ris_req_case_law(application = "Vwgh", query = "Asyl")
  err_payload <- fixture_payload("case_law_error.json")

  expect_error(
    testthat::with_mocked_bindings(
      ris_iterate_case_law_pages = function(req) list(err_payload),
      ris_perform_case_law(req)
    ),
    "RIS API error \\\[Vwgh\\\]"
  )
})

test_that("wrapper smoke tests call perform path for VwGH and VfGH", {
  vwgh_payload <- fixture_payload("case_law_one_page.json")
  vfgh_payload <- fixture_payload("case_law_multi_page_page1.json")

  vwgh_out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req) list(vwgh_payload),
    ris_search_vwgh(query = "Asyl")
  )

  vfgh_out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req) list(vfgh_payload),
    ris_search_vfgh(query = "Grundrecht")
  )

  expect_s3_class(vwgh_out, "tbl_df")
  expect_s3_class(vfgh_out, "tbl_df")
  expect_equal(vwgh_out$application[[1]], "Vwgh")
  expect_equal(vfgh_out$application[[1]], "Vfgh")
  expect_true(all(c("content_urls", "app_metadata") %in% names(vwgh_out)))
  expect_true(all(c("content_urls", "app_metadata") %in% names(vfgh_out)))
})
