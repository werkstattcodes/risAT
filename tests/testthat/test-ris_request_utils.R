fixture_payload <- function(name) {
  path <- testthat::test_path("fixtures", name)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

# ── Base URL ─────────────────────────────────────────────────────────────────

test_that("ris_base_url returns the v2.6 API by default", {
  expect_equal(ris_base_url(), "https://data.bka.gv.at/ris/api/v2.6")
})

test_that("ris_base_url can be overridden via option", {
  rlang::local_options(risAT.base_url = "https://example.org/ris")
  expect_equal(ris_base_url(), "https://example.org/ris")

  req <- ris_req_case_law(application = "Vwgh")
  expect_match(req$url, "^https://example\\.org/ris/Judikatur")
})

# ── Shared request policy (user agent, retry, throttle) ─────────────────────

test_that("case law and federal requests share user agent and throttling", {
  case_law_req <- ris_req_case_law(application = "Vwgh")
  federal_req <- ris_req_federal(title = "ABGB")

  for (req in list(case_law_req, federal_req)) {
    expect_match(req$options$useragent, "risAT")
    expect_false(is.null(req$policies$retry_max_tries))
    expect_false(is.null(req$policies$throttle))
  }
})

# ── max_pages validation ─────────────────────────────────────────────────────

test_that("ris_normalize_max_pages accepts positive numbers and Inf", {
  expect_equal(risAT:::ris_normalize_max_pages(Inf), Inf)
  expect_equal(risAT:::ris_normalize_max_pages(3), 3)
  expect_equal(risAT:::ris_normalize_max_pages(2.7), 2)
})

test_that("ris_normalize_max_pages rejects invalid values", {
  expect_error(risAT:::ris_normalize_max_pages(0))
  expect_error(risAT:::ris_normalize_max_pages(-1))
  expect_error(risAT:::ris_normalize_max_pages("ten"))
  expect_error(risAT:::ris_normalize_max_pages(NA))
  expect_error(risAT:::ris_normalize_max_pages(c(1, 2)))
})

# ── Pagination against mocked httr2 responses ────────────────────────────────

test_that("ris_perform_case_law paginates via httr2 and combines pages", {
  resp1 <- httr2::response_json(
    body = fixture_payload("case_law_multi_page_page1.json")
  )
  resp2 <- httr2::response_json(
    body = fixture_payload("case_law_multi_page_page2.json")
  )
  httr2::local_mocked_responses(list(resp1, resp2))

  req <- ris_req_case_law(application = "Vfgh", query = "Grundrecht")
  out <- ris_perform_case_law(req)

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_equal(out$id, c("Vfgh-2026-0001", "Vfgh-2026-0002"))
  expect_equal(out$app_metadata[[2]]$request$seitennummer, 2L)
})

test_that("max_pages truncates pagination and informs the user", {
  resp1 <- httr2::response_json(
    body = fixture_payload("case_law_multi_page_page1.json")
  )
  httr2::local_mocked_responses(list(resp1))

  req <- ris_req_case_law(application = "Vfgh", query = "Grundrecht")
  expect_message(
    out <- ris_perform_case_law(req, max_pages = 1),
    class = "risat_truncated_results"
  )
  expect_equal(nrow(out), 1L)
})

test_that("no truncation message when all pages fit within max_pages", {
  resp <- httr2::response_json(
    body = fixture_payload("case_law_one_page.json")
  )
  httr2::local_mocked_responses(list(resp))

  req <- ris_req_case_law(application = "Vwgh", query = "Asyl")
  expect_no_message(
    ris_perform_case_law(req, max_pages = 1),
    class = "risat_truncated_results"
  )
})

# ── Sort arguments (case law) ────────────────────────────────────────────────

test_that("ris_req_case_law exposes sort_by and sort_direction", {
  req <- ris_req_case_law(
    application = "Vwgh",
    sort_by = "case_number",
    sort_direction = "ascending"
  )
  expect_match(req$url, "SortierungSortedByColumn=Geschaeftszahl")
  expect_match(req$url, "SortierungSortDirection=Ascending")

  default_req <- ris_req_case_law(application = "Vwgh")
  expect_match(default_req$url, "SortierungSortedByColumn=Datum")
  expect_match(default_req$url, "SortierungSortDirection=Descending")
})

# ── Website URL accessors ────────────────────────────────────────────────────

test_that("ris_search_url and ris_app_url read result attributes", {
  payload <- fixture_payload("case_law_one_page.json")
  out <- testthat::with_mocked_bindings(
    ris_iterate_case_law_pages = function(req, max_pages) list(payload),
    ris_search_vwgh(query = "Asyl")
  )

  expect_equal(ris_app_url(out), "https://www.ris.bka.gv.at/Vwgh/")
  expect_match(ris_search_url(out), "^https://www\\.ris\\.bka\\.gv\\.at/Ergebnis\\.wxe\\?")

  expect_null(ris_app_url(tibble::tibble()))
  expect_null(ris_search_url(tibble::tibble()))
})

# ── Type-stable empty results ────────────────────────────────────────────────

test_that("empty parse results carry the guaranteed column schema", {
  empty_payload <- fixture_payload("case_law_empty.json")
  out <- ris_parse_search(empty_payload)
  expect_named(out, c("id", "application", "content_urls", "app_metadata"))
  expect_type(out$id, "character")
  expect_type(out$application, "character")
})

# ── Date column parsing ──────────────────────────────────────────────────────

test_that("ris_parse_date_columns coerces present columns and skips others", {
  tbl <- tibble::tibble(
    effective_date = "2024-01-01",
    note = "unchanged",
    nested = list("2024-01-01")
  )
  out <- risAT:::ris_parse_date_columns(
    tbl,
    c("effective_date", "expiry_date", "nested")
  )
  expect_s3_class(out$effective_date, "Date")
  expect_type(out$note, "character")
  expect_true(is.list(out$nested))
})

test_that("ris_parse_federal returns effective/expiry dates as Date", {
  payload <- list(
    OgdSearchResult = list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1"),
        OgdDocumentReference = list(
          list(
            Data = list(
              Metadaten = list(
                Technisch = list(ID = "NOR-1", Applikation = "BrKons"),
                Bundesrecht = list(
                  Kurztitel = "ABGB",
                  BrKons = list(
                    Inkrafttretensdatum = "2020-01-01",
                    Ausserkrafttretensdatum = "2030-12-31"
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  out <- ris_parse_federal(payload)
  expect_s3_class(out$effective_date, "Date")
  expect_s3_class(out$expiry_date, "Date")
  expect_equal(out$effective_date[[1]], as.Date("2020-01-01"))
})

# ── Error classes ────────────────────────────────────────────────────────────

test_that("validation errors carry the risat_invalid_argument class", {
  expect_error(
    ris_req_case_law(application = "invalid_app"),
    class = "risat_invalid_argument"
  )
  expect_error(
    risAT:::ris_normalize_federal_state("Bavaria"),
    class = "risat_invalid_argument"
  )
  expect_error(
    risAT:::ris_normalize_gbk_senate("IV"),
    class = "risat_invalid_argument"
  )
  expect_error(
    risAT:::ris_normalize_named_interval("fortnight"),
    class = "risat_invalid_argument"
  )
})

test_that("API error payloads raise risat_api_error", {
  payload <- list(
    OgdSearchResult = list(
      Error = list(Applikation = "Vwgh", Message = "Boom")
    )
  )
  expect_error(ris_parse_search(payload), class = "risat_api_error")
})
