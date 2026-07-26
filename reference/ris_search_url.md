# Get the RIS Website URLs of a Search Result

Every tibble returned by the risAT search functions carries the
equivalent RIS website URLs as attributes (`ris_app_url`,
`ris_search_url`), so the same search can be opened in a browser for
cross-checking. These accessors retrieve them.

## Usage

``` r
ris_search_url(x)

ris_app_url(x)
```

## Arguments

- x:

  A tibble returned by a risAT search function such as
  [`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
  or
  [`ris_search_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_search_federal.md).

## Value

A single string (the URL), or `NULL` if the attribute is absent.

## Details

Note that most dplyr operations
([`filter()`](https://rdrr.io/r/stats/filter.html), `mutate()`, ...)
drop custom attributes, so call these accessors on the unmodified search
result.

## Examples

``` r
if (FALSE) { # interactive()
results <- ris_search_vwgh(business_number = "Ra 2021/01/0001")
ris_search_url(results)
ris_app_url(results)
}
```
