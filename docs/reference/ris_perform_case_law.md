# Perform a RIS Case Law Search

Execute a request built by
[`ris_req_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_req_case_law.md)
and return parsed results. All available pages are fetched iteratively
using
[`httr2::req_perform_iterative()`](https://httr2.r-lib.org/reference/req_perform_iterative.html).

## Usage

``` r
ris_perform_case_law(req, echo = FALSE)
```

## Arguments

- req:

  An `httr2_request` object, typically built with
  [`ris_req_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_req_case_law.md).

- echo:

  Logical. If `TRUE`, prints the equivalent RIS website URLs and the
  number of returned rows.

## Value

A tidy tibble with parsed search results. Includes list-columns
`content_urls` and `app_metadata`.

## Examples

``` r
if (FALSE) { # \dontrun{
req <- ris_req_case_law(
  application = "federal_administrative_court",
  query = "Asyl"
)
results <- ris_perform_case_law(req)
} # }
```
