# Perform a RIS Bundesrecht Search

Execute a request built by
[`ris_req_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_req_federal.md)
and return parsed results. Pages are fetched iteratively using
[`httr2::req_perform_iterative()`](https://httr2.r-lib.org/reference/req_perform_iterative.html)
until all pages in scope have been retrieved.

## Usage

``` r
ris_perform_federal(req, echo = FALSE)
```

## Arguments

- req:

  An `httr2_request` object, typically built with
  [`ris_req_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_req_federal.md).

- echo:

  Logical. If `TRUE`, prints two progress messages: the equivalent RIS
  website search URL (the `Ergebnis.wxe` query on
  `https://www.ris.bka.gv.at`) before any request is sent; and the total
  hit and page count as soon as the first page's response arrives. This
  lets the result set be double-checked in the browser and gives an
  early sense of scope for broad queries without waiting for every page.

## Value

A tidy tibble with parsed search results. Includes list-column
`content_urls`.

## Examples

``` r
if (FALSE) { # interactive()
req <- ris_req_federal(title = "ABGB")
results <- ris_perform_federal(req)
}
```
