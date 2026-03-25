# risAT

<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
<!-- badges: end -->

The risAT package provides a tidyverse-friendly interface to the Austrian
[RIS](https://www.ris.bka.gv.at/) (Rechtsinformationssystem) Open Government
Data REST API v2.6. It currently focuses on the `/Judikatur` endpoint (case
law / jurisprudence) and is designed for reproducible legal research.

Please note that the package is **in a development stage**. Upcoming changes
may break existing code. If you encounter any bug, you are welcome to file an
issue at the package's
[GitHub repo](https://github.com/werkstattcodes/risAT/issues).

Also note that neither the package nor its author is affiliated with the
Austrian Federal Chancellery (BKA) or the RIS.

## Installation

You can install risAT from [GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("werkstattcodes/risAT")
```

## Available court applications and functions

The RIS Judikatur endpoint covers multiple court applications. risAT currently
provides convenience wrappers for the following, plus a generic search function
that covers all applications:

| Court / Application | risAT Function |
|---|---|
| All Judikatur applications | `ris_search_case_law()` |
| VwGH (Administrative Court) | `ris_search_vwgh()` |
| VfGH (Constitutional Court) | `ris_search_vfgh()` |

Lower-level building blocks for advanced use:

| Step | Function |
|---|---|
| Build request | `ris_req_case_law()` |
| Execute request (with pagination) | `ris_perform_case_law()` |
| Parse response | `ris_parse_search()` |

## Minimal example

``` r
library(risAT)

# Search all Judikatur applications via a single english API
results_bvwg <- ris_search_case_law(
  application = "federal_administrative_court",
  query = "Asyl",
  per_page = 20
)

# Convenience wrapper: Administrative Court (VwGH)
results_vwgh <- ris_search_vwgh(
  query = "Baurecht",
  per_page = 10
)

# Convenience wrapper: Constitutional Court (VfGH)
# Defaults to Rechtssätze (RS). Set `search_decision_text = TRUE`
# to include Entscheidungstexte (TE).
results_vfgh <- ris_search_vfgh(
  query = "Grundrecht",
  per_page = 10
)
```

## Output

Search functions automatically iterate through all RIS pages and return results
as a tidy tibble with columns including `id`, `court`, `decision_date`,
`case_number`, `content_urls` (list-column), and `app_metadata` (list-column).
See the [reference documentation](https://werkstattcodes.github.io/risAT/reference/)
for full details.
