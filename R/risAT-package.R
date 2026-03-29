#' @details
#' risAT uses a two-step request pattern:
#' 1. **Build** a request with [ris_req_case_law()]
#' 2. **Perform** it with [ris_perform_case_law()]
#'
#' Convenience wrappers like [ris_search_vwgh()] and [ris_search_vfgh()]
#' combine both steps for common court applications.
#'
#' @seealso
#' * [ris_search_case_law()] -- generic search across all applications
#' * [ris_search_vwgh()], [ris_search_vfgh()], [ris_search_justiz()] --
#'   court-specific wrappers
#' * [ris_parse_search()] -- response parser
#' * Online documentation: <https://werkstattcodes.github.io/risAT>
#'
#' @keywords internal
"_PACKAGE"
