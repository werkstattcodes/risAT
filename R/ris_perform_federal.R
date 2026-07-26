# ============================================================================
# ris_perform_federal.R — Execute a RIS Bundesrecht request and parse results
# ============================================================================
#
# Second step of the req/perform pattern for consolidated federal law:
#
#   1. ris_req_federal()     — build an httr2_request  (ris_req_federal.R)
#   2. ris_perform_federal() — execute & parse          (this file)
#
# Because the /Bundesrecht response uses the same paginated envelope as
# /Judikatur, this reuses the generic, application-agnostic pagination helpers
# from ris_perform_case_law.R (ris_iterate_case_law_pages(),
# ris_next_case_law_page(), ris_bind_case_law_pages()).  Only the per-page
# parser (ris_parse_federal()) and request provenance differ.
# ============================================================================

#' Perform a RIS Bundesrecht Search
#'
#' Execute a request built by [ris_req_federal()] and return parsed results.
#' Pages are fetched iteratively using `httr2::req_perform_iterative()`
#' until all pages in scope have been retrieved.
#'
#' @param req An `httr2_request` object, typically built with
#'   [ris_req_federal()].
#' @inheritParams ris_perform_case_law
#'
#' @return A tidy tibble with parsed search results.
#'   Includes list-column `content_urls`.
#' @export
#'
#' @examplesIf interactive()
#' req <- ris_req_federal(title = "ABGB")
#' results <- ris_perform_federal(req)
ris_perform_federal <- function(req, echo = FALSE) {
  checkmate::assert_flag(echo, .var.name = "echo")

  ris_perform_ris_search(
    req,
    echo = echo,
    page_parser = ris_parse_federal_internal,
    builder_name = "ris_req_federal"
  )
}
