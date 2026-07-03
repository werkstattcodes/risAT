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
  expect_match(req$url, "/Judikatur\\?")
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
    ris_iterate_case_law_pages = function(req, max_pages) list(payload),
    ris_perform_case_law(req)
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_true("content_urls" %in% names(out))
  expect_false("app_metadata" %in% names(out))
  expect_type(out$content_urls[[1]], "character")
  expect_gte(length(out$content_urls[[1]]), 1L)
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
    ris_iterate_case_law_pages = function(req, max_pages) list(page1, page2),
    ris_perform_case_law(req)
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_equal(out$id, c("Vfgh-2026-0001", "Vfgh-2026-0002"))
  expect_true(is.list(out$judikatur_vfgh_index))
  expect_equal(out$judikatur_vfgh_index[[1]], "07/01")
  expect_equal(out$judikatur_vfgh_index[[2]], list("07/01", "07/02"))
  expect_false("app_metadata" %in% names(out))
  expect_equal(
    attr(out, "ris_search_url"),
    attr(req, "ris_meta")$website_urls$search_url
  )
})

test_that("ris_parse_search returns decision_date as Date", {
  payload <- fixture_payload("case_law_one_page.json")
  out <- ris_parse_search(payload)

  expect_true("decision_date" %in% names(out))
  expect_s3_class(out$decision_date, "Date")
  expect_equal(out$decision_date[[1]], as.Date("2026-01-10"))
  expect_equal(out$court[[1]], "VwGH")
  expect_equal(out$title[[1]], "VwGH Entscheidung")
})

test_that("ris_perform_case_law returns structured empty tibble for empty fixture", {
  req <- ris_req_case_law(application = "Vwgh", query = "NoHitNeedle")
  empty_payload <- fixture_payload("case_law_empty.json")

  out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req, max_pages) list(empty_payload),
    ris_perform_case_law(req)
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
  expect_named(out, c("id", "application", "content_urls"))
  expect_type(out$id, "character")
  expect_type(out$application, "character")
  expect_true(is.list(out$content_urls))
})

test_that("ris_perform_case_law surfaces API error payloads", {
  req <- ris_req_case_law(application = "Vwgh", query = "Asyl")
  err_payload <- fixture_payload("case_law_error.json")

  expect_error(
    testthat::with_mocked_bindings(
      ris_iterate_case_law_pages = function(req, max_pages) list(err_payload),
      ris_perform_case_law(req)
    ),
    class = "risat_api_error"
  )
})

test_that("wrapper smoke tests call perform path for VwGH and VfGH", {
  vwgh_payload <- fixture_payload("case_law_one_page.json")
  vfgh_payload <- fixture_payload("case_law_multi_page_page1.json")

  vwgh_out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req, max_pages) list(vwgh_payload),
    ris_search_vwgh(query = "Asyl")
  )

  vfgh_out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req, max_pages) list(vfgh_payload),
    ris_search_vfgh(query = "Grundrecht")
  )

  expect_s3_class(vwgh_out, "tbl_df")
  expect_s3_class(vfgh_out, "tbl_df")
  expect_equal(vwgh_out$application[[1]], "Vwgh")
  expect_equal(vfgh_out$application[[1]], "Vfgh")
  expect_true("content_urls" %in% names(vwgh_out))
  expect_true("content_urls" %in% names(vfgh_out))
  expect_false("app_metadata" %in% names(vwgh_out))
  expect_false("app_metadata" %in% names(vfgh_out))
})

test_that("case law exported tibble outputs never include app_metadata", {
  payload <- fixture_payload("case_law_one_page.json")

  outputs <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req, max_pages) list(payload),
    list(
      parse = ris_parse_search(payload),
      perform = ris_perform_case_law(
        ris_req_case_law(application = "Vwgh", query = "Asyl")
      ),
      search_case_law = ris_search_case_law(application = "Vwgh", query = "Asyl"),
      search_vwgh = ris_search_vwgh(query = "Asyl"),
      search_vfgh = ris_search_vfgh(query = "Asyl"),
      search_bvwg = ris_search_bvwg(query = "Asyl"),
      search_lvwg = ris_search_lvwg(query = "Asyl"),
      search_justiz = ris_search_justiz(query = "Asyl"),
      search_dsk = ris_search_dsk(query = "Asyl"),
      search_dok = ris_search_dok(query = "Asyl"),
      search_pvak = ris_search_pvak(query = "Asyl"),
      search_gbk = ris_search_gbk(query = "Asyl")
    )
  )

  purrr::walk(outputs, \(out) {
    expect_s3_class(out, "tbl_df")
    expect_false("app_metadata" %in% names(out))
  })
})
