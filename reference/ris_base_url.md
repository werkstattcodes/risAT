# RIS API Base URL

Returns the base URL of the Austrian RIS OGD REST API used by all risAT
request builders. Defaults to the v2.6 API; can be overridden for a
whole session via `options(risAT.base_url = ...)` (e.g. when the API
version changes or for testing against a mock server).

## Usage

``` r
ris_base_url()
```

## Value

A single string with the API base URL.

## Examples

``` r
ris_base_url()
#> [1] "https://data.bka.gv.at/ris/api/v2.6"
```
