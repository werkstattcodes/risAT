# risAT

<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![R-CMD-check](https://github.com/werkstattcodes/risAT/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/werkstattcodes/risAT/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The risAT package provides a tidyverse-friendly interface to the Austrian
[RIS](https://www.ris.bka.gv.at/) (Rechtsinformationssystem) Open Government
Data REST API v2.6. It covers the `/Judikatur` endpoint (case law /
jurisprudence) across all supported court applications and the `/Bundesrecht`
endpoint for consolidated federal law (`BrKons`), and is designed for
reproducible legal research.

Please note that the package is **in a development stage**. Upcoming changes
may break existing code. If you encounter any bug, you are welcome to file an
issue at the package's
[GitHub repo](https://github.com/werkstattcodes/risAT/issues).

## Data source

This package accesses data from the
[RIS (Rechtsinformationssystem)](https://www.ris.bka.gv.at/) provided by
the Austrian Federal Chancellery (BKA) via its
[Open Government Data REST API](https://data.bka.gv.at/ris/api/v2.6/).
The data is published under the
[Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
licence as part of Austria's Open Data initiative.

Neither the package nor its author is affiliated with the BKA or the RIS.

## Installation

You can install risAT from [GitHub](https://github.com/werkstattcodes/risAT) with:

``` r
# install.packages("pak")
pak::pak("werkstattcodes/risAT")
```

## RIS coverage

The RIS website is organised into several content areas, each backed by one or
more API "applications". The table below shows which of them risAT currently
supports. Status legend: ✅ implemented · 🔜 planned · — not yet supported.

| RIS area | Applications | risAT |
|---|---|---|
| **Judikatur** (case law) | VfGH, VwGH, Justiz, BVwG, LVwG, Normenliste, DSK, DOK, PVAK, GBK, UVS, AsylGH, UBAS, UMSE, BKS, VERG | ✅ implemented |
| **Bundesrecht** – consolidated (`BrKons`) | Federal law in consolidated form | ✅ implemented |
| **Bundesrecht** – gazettes (`BgblAuth`, `BgblPdf`, `BgblAlt`) | Federal Law Gazettes (1848–present) | 🔜 planned |
| **Bundesrecht** – drafts (`Begut`, `RegV`, `Erv`) | Consultation drafts, government bills, Austrian laws in English | 🔜 planned |
| **Landesrecht** (`LrKons`, `LgblAuth`, `Lgbl`, `LgblNO`, `Vbl`) | State law (consolidated) and state gazettes | 🔜 planned |
| **Kundmachungen & Erlässe** (`Upts`, `Erlaesse`, `Avsv`, …) | Other notices and ministerial decrees (`/Sonstige`) | 🔜 planned |
| **Gemeinden** (`Gr`, `GrA`) | Municipal law and notices | — |
| **Bezirke** (`Bvb`) | District authority notices | — |

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

### Federal law (Bundesrecht)

| Application | Function | Notes |
|---|---|---|
| Consolidated federal law (BrKons) | `ris_search_federal()` | Title/full-text/index search, version (`Fassung`) and in-/out-of-force date filters |

Lower-level building blocks for advanced use:

| Step | Judikatur | Bundesrecht |
|---|---|---|
| Build request | `ris_req_case_law()` | `ris_req_federal()` |
| Execute request (with pagination) | `ris_perform_case_law()` | `ris_perform_federal()` |
| Parse response | `ris_parse_search()` | `ris_parse_federal()` |

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

# Consolidated federal law (Bundesrecht): look up a law by its short title
results_abgb <- ris_search_federal(title = "ABGB")

# The consolidated text as it stood on a given date (point-in-time version)
results_mrg <- ris_search_federal(query = "Mietzins", version_date = "2020-01-01")
```

## Output

Search functions automatically iterate through all RIS pages and return results
as a tidy tibble with columns including `id`, `court`, `decision_date`,
`case_number`, and `content_urls` (a list-column of download links).
See the [reference documentation](https://werkstattcodes.github.io/risAT/reference/)
for full details.

For a full column name reference mapping the original German RIS API fields to
their English risAT equivalents, see `vignette("risAT")`.

## Citation

If you use risAT in your research, please cite it:

``` r
citation("risAT")
```

> Schmidt R (2026). _risAT: An R package wrapping the API of the Austrian
> Legal Information System (RIS)_. R package version 0.0.1,
> <https://github.com/werkstattcodes/risAT>.
