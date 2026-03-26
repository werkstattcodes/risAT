# risAT

<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
<!-- badges: end -->

The `risAT` package provides a tidyverse-friendly interface to the Austrian
[RIS](https://www.ris.bka.gv.at/) (Rechtsinformationssystem) Open Government
Data REST API v2.6. It covers the `/Judikatur` endpoint (case law /
jurisprudence) across all supported court applications and is designed for
reproducible legal research.

Please note that the package is **in a development stage**. Upcoming changes
may break existing code. If you encounter any bug, you are welcome to file an
issue at the package's
[GitHub repo](https://github.com/werkstattcodes/risAT/issues).

Also note that neither the package nor its author is affiliated with the
Austrian Federal Chancellery (BKA) or the RIS.

## Installation

You can install `risAT` from [GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("werkstattcodes/risAT")
```

## Available court applications and functions

The RIS Judikatur endpoint covers multiple court applications. risAT provides
convenience wrappers for all of them, plus a generic search function that
accepts any application code:

| Court / Application | Function | Notes |
|---|---|---|
| All Judikatur applications | `ris_search_case_law()` | Generic; accepts any application code |
| VfGH (Constitutional Court) | `ris_search_vfgh()` | Defaults to Rechtssätze |
| VwGH (Administrative Court) | `ris_search_vwgh()` | |
| Justiz (OGH, OLG, LG, BG) | `ris_search_justiz()` | Richest parameter set |
| BVwG (Federal Administrative Court) | `ris_search_bvwg()` | Since 2014 |
| LVwG (9 state administrative courts) | `ris_search_lvwg()` | Use `federal_state` to narrow |
| DSK / DSB / PDK (data protection) | `ris_search_dsk()` | |
| BDB / DK / DOK / BK (disciplinary) | `ris_search_dok()` | |
| PVAK / PVAB (staff representation) | `ris_search_pvak()` | |
| GBK (equal treatment commissions) | `ris_search_gbk()` | No doc-type flags |

Lower-level building blocks for advanced use:

| Step | Function |
|---|---|
| Build request | `ris_req_case_law()` |
| Execute request (with pagination) | `ris_perform_case_law()` |
| Parse response | `ris_parse_search()` |

## Minimal example

``` r
library(risAT)

# Convenience wrapper: Administrative Court (VwGH)
results_vwgh <- ris_search_vwgh(query = "Baurecht")

# Convenience wrapper: Constitutional Court (VfGH)
# Defaults to Rechtssätze (RS). Set `search_decision_text = TRUE`
# to include Entscheidungstexte (TE).
results_vfgh <- ris_search_vfgh(query = "Grundrecht")

# Convenience wrapper: Federal Administrative Court (BVwG)
results_bvwg <- ris_search_bvwg(
  query = "Asyl",
  decision_type = "Erkenntnis",
  decision_date_from = "2023-01-01"
)

# Ordinary courts: OGH and below
results_ogh <- ris_search_justiz(
  query = "Schadenersatz",
  court = "OGH"
)

# Generic search across all Judikatur applications
results_all <- ris_search_case_law(
  application = "data_protection",
  query = "Videoüberwachung"
)

# `content_urls` is a list-column, so unnest or map as needed
dplyr::glimpse(results_vwgh)

# Example: keep first available content URL per document
results_vwgh |>
  dplyr::mutate(
    first_content_url = purrr::map_chr(
      content_urls,
      ~ purrr::pluck(.x, 1, .default = NA_character_)
    )
  )
```

## Output and conventions

Search functions automatically iterate through all RIS pages and return results
as a tidy tibble with columns including `id`, `court`, `decision_date`,
`case_number`, `content_urls` (list-column), and `app_metadata` (list-column).
The output is designed to work well in tidyverse pipelines (`dplyr`, `tidyr`,
`purrr`) and follows these conventions:

- English user-facing function names and arguments (`snake_case`).
- Internal mapping to German RIS API parameters.
- List-columns for nested API payload parts (`content_urls`, `app_metadata`).

See the pkgdown site for full documentation:

- [Get started](https://werkstattcodes.github.io/risAT/)
- [Function reference](https://werkstattcodes.github.io/risAT/reference/)
- [Changelog](https://werkstattcodes.github.io/risAT/news/index.html)
