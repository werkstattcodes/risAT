# ============================================================================
# ris_request_utils.R — Endpoint-agnostic request and result helpers
# ============================================================================
#
# Shared infrastructure used by both the Judikatur and Bundesrecht sides:
#
#   1. ris_base_url()        — single source of truth for the API base URL
#   2. ris_base_request()    — httr2 request skeleton (user agent, retry,
#                              throttling) applied to every RIS request
#   3. ris_empty_result()    — type-stable zero-row result tibble
#   4. ris_app_url() /
#      ris_search_url()      — accessors for the RIS website URL attributes
#   5. ris_parse_date_columns() — coerce known date columns to Date
# ============================================================================

#' RIS API Base URL
#'
#' Returns the base URL of the Austrian RIS OGD REST API used by all risAT
#' request builders. Defaults to the v2.6 API; can be overridden for a whole
#' session via `options(risAT.base_url = ...)` (e.g. when the API version
#' changes or for testing against a mock server).
#'
#' @return A single string with the API base URL.
#' @export
#'
#' @examples
#' ris_base_url()
ris_base_url <- function() {
  getOption("risAT.base_url", "https://data.bka.gv.at/ris/api/v2.6")
}

# Build the request skeleton shared by all RIS endpoints: a package-identifying
# user agent (courtesy to the public OGD service), retries against transient
# network errors, and client-side throttling so iterative pagination cannot
# hammer the API (30 requests per minute across all risAT requests to the same
# host).
ris_base_request <- function(base_url, endpoint) {
  httr2::request(paste0(base_url, endpoint)) |>
    httr2::req_user_agent(
      "risAT R package (https://github.com/werkstattcodes/risAT)"
    ) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_throttle(capacity = 30, fill_time_s = 60)
}

# Validate the max_pages argument shared by the perform/search functions.
# Accepts a single positive number, including Inf (fetch all pages).
ris_normalize_max_pages <- function(max_pages) {
  checkmate::assert_number(max_pages, lower = 1, .var.name = "max_pages")
  floor(max_pages)
}

# Type-stable zero-row result: guarantees the columns that every RIS search
# result contains, so downstream code can rely on `out$id` etc. even when a
# search returns no hits.  website_urls is NULL when called from the parsers
# (which have no request context); the URL attributes are then omitted.
ris_empty_result <- function(website_urls = NULL) {
  out <- tibble::tibble(
    id = character(),
    application = character(),
    content_urls = list(),
    app_metadata = list()
  )
  if (!is.null(website_urls)) {
    attr(out, "ris_app_url") <- website_urls$app_url
    attr(out, "ris_search_url") <- website_urls$search_url
  }
  out
}

# After pagination stopped at max_pages, check whether the API had more pages
# and tell the user how to get them.  `responses` may contain httr2_response
# objects (live requests) or decoded payload lists (tests); ris_as_payload()
# handles both.
ris_inform_if_truncated <- function(responses, max_pages) {
  if (!is.finite(max_pages) || length(responses) < max_pages) {
    return(invisible(NULL))
  }

  last_root <- ris_extract_root(ris_as_payload(responses[[length(responses)]]))
  if (is.null(ris_next_case_law_page(last_root))) {
    return(invisible(NULL))
  }

  hits <- ris_extract_hits_count(last_root)
  hits_note <- if (length(hits) == 1L && !is.na(hits)) {
    paste0(" (", hits, " total hits)")
  } else {
    ""
  }
  rlang::inform(
    paste0(
      "Stopped after `max_pages = ", max_pages, "` pages", hits_note,
      "; more results are available. Increase `max_pages` to fetch them."
    ),
    class = "risat_truncated_results"
  )
}

#' Get the RIS Website URLs of a Search Result
#'
#' Every tibble returned by the risAT search functions carries the equivalent
#' RIS website URLs as attributes (`ris_app_url`, `ris_search_url`), so the
#' same search can be opened in a browser for cross-checking. These accessors
#' retrieve them.
#'
#' Note that most dplyr operations (`filter()`, `mutate()`, ...) drop custom
#' attributes, so call these accessors on the unmodified search result. The
#' same URLs are also stored per row in `app_metadata$request`, which survives
#' data wrangling.
#'
#' @param x A tibble returned by a risAT search function such as
#'   [ris_search_case_law()] or [ris_search_federal()].
#'
#' @return A single string (the URL), or `NULL` if the attribute is absent.
#' @export
#'
#' @examples
#' \dontrun{
#' results <- ris_search_vwgh(business_number = "Ra 2021/01/0001")
#' ris_search_url(results)
#' ris_app_url(results)
#' }
ris_search_url <- function(x) {
  attr(x, "ris_search_url", exact = TRUE)
}

#' @rdname ris_search_url
#' @export
ris_app_url <- function(x) {
  attr(x, "ris_app_url", exact = TRUE)
}

# Coerce the named columns to Date where present.  The API returns ISO 8601
# strings (YYYY-MM-DD); if a column is a list-column (repeated field) or any
# value fails to parse, it is left unchanged rather than erroring
# (robust-parsing principle).
ris_parse_date_columns <- function(tbl, cols) {
  for (col in intersect(cols, names(tbl))) {
    if (is.list(tbl[[col]])) {
      next
    }
    parsed <- tryCatch(
      as.Date(tbl[[col]]),
      error = function(e) NULL
    )
    if (!is.null(parsed)) {
      tbl[[col]] <- parsed
    }
  }
  tbl
}
