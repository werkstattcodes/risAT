# risAT

`risAT` is an R package for querying Austrian court decisions from the
RIS OGD REST API v2.6 (`/Judikatur`).

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

# Convenience wrapper: Verfassungsgerichtshof (VfGH)
# Defaults to Rechtssätze (RS). Set `search_decision_text = TRUE`
# to include Entscheidungstexte (TE).
results_vfgh <- ris_search_vfgh(
  query = "Grundrecht",
  per_page = 10
)

# VfGH aliases (english) for decision_type, sort_by, and in_ris_since
results_vfgh_recent <- ris_search_vfgh(
  decision_type = "judgment",
  sort_by = "decision_date",
  sort_direction = "descending",
  in_ris_since = "one_week",
  per_page = 10
)
```

Search functions automatically iterate through all RIS pages and return
all results in scope. Returned tibbles include: - pagination columns:
`page`, `per_page` - `content_urls` - `app_metadata`
