test_that("VfGH progress is enabled only when echo is TRUE", {
  expect_true(
    risAT:::ris_case_law_progress_is_enabled(
      risAT:::ris_create_case_law_progress("Vfgh", TRUE)
    )
  )
  expect_false(
    risAT:::ris_case_law_progress_is_enabled(
      risAT:::ris_create_case_law_progress("Vfgh", FALSE)
    )
  )
  expect_false(
    risAT:::ris_case_law_progress_is_enabled(
      risAT:::ris_create_case_law_progress("Vwgh", TRUE)
    )
  )
})

test_that("single-page progress completes spinner without creating a bar", {
  events <- list()
  local_mocked_bindings(
    ris_cli_progress_bar = function(total, clear, format, ...) {
      id <- paste0("id-", length(events) + 1L)
      events[[length(events) + 1L]] <<- list(
        fn = "bar",
        id = id,
        total = total,
        clear = clear,
        format = format
      )
      id
    },
    ris_cli_progress_done = function(id, ...) {
      events[[length(events) + 1L]] <<- list(fn = "done", id = id)
      invisible(id)
    },
    .package = "risAT"
  )

  state <- risAT:::ris_create_case_law_progress("Vfgh", TRUE)
  risAT:::ris_case_law_progress_begin(state)
  risAT:::ris_case_law_progress_after_response(
    state,
    list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1")
      )
    )
  )

  expect_length(events, 2L)
  expect_true(is.na(events[[1]]$total))
  expect_match(events[[1]]$format, "spinner")
  expect_equal(events[[2]], list(fn = "done", id = "id-1"))
  expect_null(state$spinner_id)
  expect_null(state$bar_id)
})

test_that("multi-page progress upgrades spinner to a progress bar", {
  events <- list()
  local_mocked_bindings(
    ris_cli_progress_bar = function(total, clear, format, ...) {
      id <- paste0("id-", length(events) + 1L)
      events[[length(events) + 1L]] <<- list(
        fn = "bar",
        id = id,
        total = total,
        clear = clear,
        format = format
      )
      id
    },
    ris_cli_progress_update = function(id, set = NULL, ...) {
      events[[length(events) + 1L]] <<- list(fn = "update", id = id, set = set)
      invisible(id)
    },
    ris_cli_progress_done = function(id, ...) {
      events[[length(events) + 1L]] <<- list(fn = "done", id = id)
      invisible(id)
    },
    .package = "risAT"
  )

  state <- risAT:::ris_create_case_law_progress("Vfgh", TRUE)
  risAT:::ris_case_law_progress_begin(state)
  risAT:::ris_case_law_progress_after_response(
    state,
    list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "10", `#text` = "25")
      )
    )
  )
  risAT:::ris_case_law_progress_after_response(
    state,
    list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "2", pageSize = "10", `#text` = "25")
      )
    )
  )

  expect_equal(events[[1]]$fn, "bar")
  expect_true(is.na(events[[1]]$total))
  expect_equal(events[[2]], list(fn = "done", id = "id-1"))
  expect_equal(events[[3]]$fn, "bar")
  expect_equal(events[[3]]$total, 3L)
  expect_equal(events[[4]], list(fn = "update", id = "id-3", set = 1L))
  expect_equal(events[[5]], list(fn = "update", id = "id-3", set = 2L))
  expect_equal(state$bar_id, "id-3")
  expect_equal(state$total_pages, 3L)
})

test_that("progress finalize closes active spinner and bar", {
  events <- list()
  local_mocked_bindings(
    ris_cli_progress_done = function(id, ...) {
      events[[length(events) + 1L]] <<- id
      invisible(id)
    },
    .package = "risAT"
  )

  state <- risAT:::ris_create_case_law_progress("Vfgh", TRUE)
  state$spinner_id <- "spinner"
  state$bar_id <- "bar"

  risAT:::ris_case_law_progress_finalize(state)

  expect_equal(events, list("spinner", "bar"))
  expect_null(state$spinner_id)
  expect_null(state$bar_id)
})

test_that("echo still prints RIS URLs and row count for VfGH searches", {
  req <- structure(
    list(),
    ris_meta = list(
      application_code = "Vfgh",
      per_page = 100L,
      website_urls = list(
        app_url = "https://www.ris.bka.gv.at/Vfgh/",
        search_url = "https://www.ris.bka.gv.at/Ergebnis.wxe?Abfrage=Vfgh"
      )
    )
  )

  local_mocked_bindings(
    ris_iterate_case_law_pages = function(req, progress_state = NULL) {
      expect_true(risAT:::ris_case_law_progress_is_enabled(progress_state))
      list("page-1")
    },
    ris_parse_search = function(resp, requested_page, requested_per_page) {
      tibble::tibble(
        id = "vfgh-1",
        content_urls = list("https://example.org/doc/1"),
        app_metadata = list(list(source = "mock"))
      )
    },
    .package = "risAT"
  )

  expect_message(
    expect_message(
      expect_message(
        out <- ris_perform_case_law(req, echo = TRUE),
        "RIS application URL: https://www\\.ris\\.bka\\.gv\\.at/Vfgh/"
      ),
      "Equivalent RIS search URL: https://www\\.ris\\.bka\\.gv\\.at/Ergebnis\\.wxe\\?Abfrage=Vfgh"
    ),
    "Rows returned: 1"
  )

  expect_equal(nrow(out), 1L)
  expect_equal(attr(out, "ris_app_url"), "https://www.ris.bka.gv.at/Vfgh/")
})

test_that("echo FALSE keeps VfGH progress disabled", {
  req <- structure(
    list(),
    ris_meta = list(
      application_code = "Vfgh",
      per_page = 100L,
      website_urls = list(
        app_url = "https://www.ris.bka.gv.at/Vfgh/",
        search_url = "https://www.ris.bka.gv.at/Ergebnis.wxe?Abfrage=Vfgh"
      )
    )
  )

  local_mocked_bindings(
    ris_iterate_case_law_pages = function(req, progress_state = NULL) {
      expect_false(risAT:::ris_case_law_progress_is_enabled(progress_state))
      list("page-1")
    },
    ris_parse_search = function(resp, requested_page, requested_per_page) {
      tibble::tibble(
        id = "vfgh-1",
        content_urls = list("https://example.org/doc/1"),
        app_metadata = list(list(source = "mock"))
      )
    },
    .package = "risAT"
  )

  out <- ris_perform_case_law(req, echo = FALSE)

  expect_equal(nrow(out), 1L)
})

test_that("progress state is finalized when VfGH fetch errors", {
  events <- list()
  req <- structure(
    list(),
    ris_meta = list(
      application_code = "Vfgh",
      per_page = 100L,
      website_urls = list(
        app_url = "https://www.ris.bka.gv.at/Vfgh/",
        search_url = "https://www.ris.bka.gv.at/Ergebnis.wxe?Abfrage=Vfgh"
      )
    )
  )

  local_mocked_bindings(
    ris_iterate_case_law_pages = function(req, progress_state = NULL) {
      progress_state$spinner_id <- "spinner"
      stop("boom", call. = FALSE)
    },
    ris_cli_progress_done = function(id, ...) {
      events[[length(events) + 1L]] <<- id
      invisible(id)
    },
    .package = "risAT"
  )

  expect_error(ris_perform_case_law(req, echo = TRUE), "boom")
  expect_equal(events, list("spinner"))
})

test_that("real cli progress calls survive spinner-to-bar transition", {
  state <- risAT:::ris_create_case_law_progress("Vfgh", TRUE)

  expect_no_error({
    risAT:::ris_case_law_progress_begin(state)
    risAT:::ris_case_law_progress_after_response(
      state,
      list(
        OgdDocumentResults = list(
          Hits = list(pageNumber = "1", pageSize = "10", `#text` = "25")
        )
      )
    )
    risAT:::ris_case_law_progress_after_response(
      state,
      list(
        OgdDocumentResults = list(
          Hits = list(pageNumber = "2", pageSize = "10", `#text` = "25")
        )
      )
    )
    risAT:::ris_case_law_progress_finalize(state)
  })
})
