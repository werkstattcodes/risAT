# ============================================================================
# ris_request_utils.R — Endpoint-agnostic request and result helpers
# ============================================================================
#
# Shared infrastructure used by both the Judikatur and Bundesrecht sides:
#
#   1. ris_base_url()        — single source of truth for the API base URL
#   2. ris_throttle_params() — client-side pacing resolved from package options
#   3. ris_base_request()    — httr2 request skeleton (user agent, retry,
#                              throttling) applied to every RIS request
#   4. ris_empty_result()    — type-stable zero-row result tibble
#   5. ris_app_url() /
#      ris_search_url()      — accessors for the RIS website URL attributes
#   6. ris_parse_date_columns() — coerce known date columns to Date
#   7. ris_normalize_or_operator() — translate OR/ODER to the RIS-native
#      full-text OR operator
# ============================================================================

#' RIS API Base URL
#'
#' Returns the base URL of the Austrian RIS OGD REST API used by all risAT
#' request builders. Defaults to the v2.6 API; can be overridden for a whole
#' session via `options(risAT.base_url = ...)` (e.g. when the API version
#' changes or for testing against a mock server).
#'
#' @section Package options:
#'
#' `risAT.base_url`
#' : The API base URL. Defaults to `"https://data.bka.gv.at/ris/api/v2.6"`.
#'
#' `risAT.throttle_capacity`
#' : Number of requests that may be sent back-to-back before pacing begins.
#'   Defaults to `1`, so *every* request is spaced. Raising it re-introduces an
#'   initial burst and is rarely what you want.
#'
#' `risAT.throttle_fill_time_s`
#' : Seconds it takes to refill `risAT.throttle_capacity` requests, i.e. the
#'   pause between requests at the default capacity. Defaults to `2`.
#'   Set `0` to disable client-side pacing entirely (intended for local mock
#'   servers, not for the live API).
#'
#' The RIS OGD FAQ asks clients to pause roughly 1--2 seconds between
#' paginated page fetches, so the defaults sit at the cautious end of that
#' range. Configuring risAT to request faster than one per second is allowed
#' but raises a `risat_throttle_override` warning once per session.
#'
#' @return A single string with the API base URL.
#' @export
#'
#' @examples
#' ris_base_url()
#'
#' # Pace requests more gently for a long bulk run
#' \dontrun{
#' options(risAT.throttle_fill_time_s = 5)
#' }
ris_base_url <- function() {
  getOption("risAT.base_url", "https://data.bka.gv.at/ris/api/v2.6")
}

# Default request pacing: one request every 2 seconds.  This is the
# conservative end of the "kurze Pausen von etwa 1-2 Sekunden" that the RIS OGD
# FAQ asks clients to insert between paginated page fetches
# (background_docs/ris-ogd-faq.pdf, "Technische Rahmenbedingungen").
ris_throttle_default_capacity <- 1L
ris_throttle_default_fill_time_s <- 2

# Resolve the client-side throttle settings from package options.
#
# capacity = 1 is deliberate, not arbitrary.  httr2's token bucket starts
# *full*, so a capacity of n lets the first n requests fire back-to-back with
# no pause at all before any spacing kicks in.  Only capacity = 1 produces a
# genuine gap between every request, which is what the FAQ asks for.
#
# Both settings are user-overridable so callers can slow risAT down further for
# a long bulk run, or switch pacing off entirely (fill_time_s = 0) when
# pointing `risAT.base_url` at a local mock server.  Requesting faster than the
# FAQ's one-second floor is permitted but warned about once per session.
ris_throttle_params <- function(call = rlang::caller_env()) {
  capacity <- getOption(
    "risAT.throttle_capacity",
    ris_throttle_default_capacity
  )
  fill_time_s <- getOption(
    "risAT.throttle_fill_time_s",
    ris_throttle_default_fill_time_s
  )

  # checkmate supplies the predicates; rlang::abort() supplies the condition
  # class, so callers can catch these structurally like every other risAT error.
  if (!checkmate::test_count(capacity, positive = TRUE)) {
    rlang::abort(
      "Option `risAT.throttle_capacity` must be a single positive whole number.",
      class = "risat_invalid_argument",
      call = call
    )
  }
  if (!checkmate::test_number(fill_time_s, lower = 0, finite = TRUE)) {
    rlang::abort(
      "Option `risAT.throttle_fill_time_s` must be a single non-negative number.",
      class = "risat_invalid_argument",
      call = call
    )
  }

  # Sustained pacing once the bucket has drained.
  seconds_per_request <- fill_time_s / capacity
  if (seconds_per_request < 1) {
    rlang::warn(
      c(
        "risAT is configured to request faster than the RIS OGD FAQ asks for.",
        i = paste0(
          "Current pacing: ~",
          signif(seconds_per_request, 3),
          "s between requests."
        ),
        i = "The FAQ asks for pauses of about 1-2 seconds between paginated fetches.",
        i = paste0(
          "Restore the default with `options(risAT.throttle_capacity = 1, ",
          "risAT.throttle_fill_time_s = 2)`."
        )
      ),
      class = "risat_throttle_override",
      .frequency = "once",
      .frequency_id = "risat_throttle_override"
    )
  }

  list(capacity = capacity, fill_time_s = fill_time_s)
}

# Build the request skeleton shared by all RIS endpoints: a package-identifying
# user agent (courtesy to the public OGD service), retries against transient
# network errors, and client-side throttling so iterative pagination paces
# itself the way the RIS OGD FAQ asks — by default one request every 2 seconds,
# shared across all risAT requests to the same host.  See ris_throttle_params()
# for the pacing settings and how to override them.
ris_base_request <- function(base_url, endpoint) {
  throttle <- ris_throttle_params()

  req <- httr2::request(paste0(base_url, endpoint)) |>
    httr2::req_user_agent(
      "risAT R package (https://github.com/werkstattcodes/risAT)"
    ) |>
    httr2::req_retry(max_tries = 3)

  # fill_time_s = 0 means "no pacing at all", which httr2 has no way to
  # express, so drop the policy rather than handing it an infinite fill rate.
  if (throttle$fill_time_s == 0) {
    return(req)
  }

  httr2::req_throttle(
    req,
    capacity = throttle$capacity,
    fill_time_s = throttle$fill_time_s
  )
}

# Type-stable zero-row result: guarantees the columns that every public RIS
# search result contains, so downstream code can rely on `out$id` etc. even
# when a search returns no hits.  website_urls is NULL when called from the
# parsers (which have no request context); the URL attributes are then omitted.
ris_empty_result <- function(website_urls = NULL) {
  out <- tibble::tibble(
    id = character(),
    application = character(),
    content_urls = list()
  )
  if (!is.null(website_urls)) {
    attr(out, "ris_app_url") <- website_urls$app_url
    attr(out, "ris_search_url") <- website_urls$search_url
  }
  out
}

ris_drop_app_metadata <- function(tbl) {
  if ("app_metadata" %in% names(tbl)) {
    tbl$app_metadata <- NULL
  }
  tbl
}

# Shared execution engine behind ris_perform_case_law() and
# ris_perform_federal(): validate the request metadata, fetch all pages,
# parse each with `page_parser`, combine, enrich request provenance in the
# internal app metadata, and attach the website-URL attributes.  The two
# public perform functions only differ in their page parser and in the name
# of the request builder mentioned in error messages.
#
# `echo` is assumed to be already validated by the public perform functions,
# so assertion errors carry the name the user called.
ris_perform_ris_search <- function(
  req,
  echo,
  page_parser,
  builder_name,
  call = rlang::caller_env()
) {
  # The request builder attaches an "ris_meta" attribute containing the
  # application code, page size, endpoint, and pre-built website URLs.  If it
  # is missing, the request wasn't built by our constructor.  `call` points
  # the error at the public perform function the user actually called.
  meta <- attr(req, "ris_meta")
  if (is.null(meta)) {
    rlang::abort(
      paste0(
        "`req` must be built with `",
        builder_name,
        "()` (missing `ris_meta` attribute)."
      ),
      class = "risat_invalid_argument",
      call = call
    )
  }

  application_code <- meta$application_code
  per_page <- meta$per_page
  endpoint <- meta$endpoint %||% "/Judikatur"
  website_urls <- meta$website_urls

  # When echo = TRUE, print the RIS website URL so the user can open the
  # same search in a browser to cross-check the results.
  if (isTRUE(echo)) {
    message("Equivalent RIS search URL: ", website_urls$search_url)
  }

  # Fetch pages iteratively, following pagination via the response metadata.
  # When echo = TRUE, the total hit/page count is reported as soon as the
  # first page arrives (see ris_iterate_case_law_pages()), well before all
  # pages have been fetched.
  responses <- ris_iterate_case_law_pages(req, echo = echo)

  # Parse each page, tag rows with their page number, and drop empty pages.
  page_results <- purrr::imap(
    responses,
    function(resp, idx) {
      page_tbl <- page_parser(
        resp,
        requested_page = as.integer(idx),
        requested_per_page = per_page
      )
      if (nrow(page_tbl) == 0L) {
        return(NULL)
      }
      page_tbl$.page_idx <- as.integer(idx)
      page_tbl
    }
  )

  out <- ris_bind_case_law_pages(page_results)

  # Return a zero-row tibble with the guaranteed public column structure
  # rather than an unstructured empty tibble, so downstream code sees the
  # same schema as for non-empty results.
  if (nrow(out) == 0L) {
    empty_out <- ris_empty_result(website_urls)
    return(empty_out)
  }

  # Append a `request` sub-list to each row's app_metadata so users can trace
  # which endpoint, application, page, and RIS URLs produced each row.
  out$app_metadata <- purrr::map2(
    out$app_metadata,
    out$.page_idx,
    \(meta_entry, page_idx) c(
      meta_entry,
      list(
        request = list(
          endpoint = endpoint,
          application = application_code,
          seitennummer = as.integer(page_idx),
          dokumente_pro_seite = ris_per_page_to_api_value(per_page),
          ris_app_url = website_urls$app_url,
          ris_search_url = website_urls$search_url
        )
      )
    )
  )

  # Drop the temporary page index column used for app_metadata enrichment.
  out$.page_idx <- NULL

  # Attach RIS URLs as attributes for the ris_app_url()/ris_search_url()
  # accessors.
  attr(out, "ris_app_url") <- website_urls$app_url
  attr(out, "ris_search_url") <- website_urls$search_url

  ris_drop_app_metadata(out)
}

#' Get the RIS Website URLs of a Search Result
#'
#' Every tibble returned by the risAT search functions carries the equivalent
#' RIS website URLs as attributes (`ris_app_url`, `ris_search_url`), so the
#' same search can be opened in a browser for cross-checking. These accessors
#' retrieve them.
#'
#' Note that most dplyr operations (`filter()`, `mutate()`, ...) drop custom
#' attributes, so call these accessors on the unmodified search result.
#'
#' @param x A tibble returned by a risAT search function such as
#'   [ris_search_case_law()] or [ris_search_federal()].
#'
#' @return A single string (the URL), or `NULL` if the attribute is absent.
#' @export
#'
#' @examplesIf interactive()
#' results <- ris_search_vwgh(business_number = "Ra 2021/01/0001")
#' ris_search_url(results)
#' ris_app_url(results)
ris_search_url <- function(x) {
  attr(x, "ris_search_url", exact = TRUE)
}

#' @rdname ris_search_url
#' @export
ris_app_url <- function(x) {
  attr(x, "ris_app_url", exact = TRUE)
}

# Translate the uppercase OR operators accepted by risAT ("OR", "ODER") into
# the RIS-native full-text operator "oder" in a full-text field (Suchworte,
# Norm).  Only standalone all-uppercase tokens are rewritten: lowercase "oder"
# already works natively, and mixed-case variants ("Oder") remain ordinary
# search words.  Text inside single-quoted exact phrases ('...') is left
# untouched so phrase semantics are preserved — the alternation consumes
# quoted spans before the operator tokens can match.
ris_normalize_or_operator <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  stringr::str_replace_all(
    x,
    "'[^']*'|\\b(?:OR|ODER)\\b",
    \(matches) ifelse(matches %in% c("OR", "ODER"), "oder", matches)
  )
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
