# Search LVwG Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Lvwg"`.

## Usage

``` r
ris_search_lvwg(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  federal_state = NULL,
  in_ris_since = NULL,
  search_decision_text = TRUE,
  search_legal_principles = TRUE,
  echo = FALSE,
  base_url = "https://data.bka.gv.at/ris/api/v2.6"
)
```

## Arguments

- query:

  Optional full-text query (`Suchworte`).

- business_number:

  Optional business number (`Geschaeftszahl`).

- norm:

  Optional legal norm query (`Norm`).

- decision_date_from:

  Optional lower date bound (`YYYY-MM-DD`, `EntscheidungsdatumVon`).

- decision_date_to:

  Optional upper date bound (`YYYY-MM-DD`, `EntscheidungsdatumBis`).

- decision_type:

  Optional decision type (`Entscheidungsart`). LVwG accepts:
  `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`, `"Bescheid"`.

- index_term:

  Optional index term (`Index`).

- federal_state:

  Optional federal state (`Bundesland`) to restrict results to a single
  LVwG, e.g. `"Wien"`, `"Steiermark"`, `"Niederösterreich"`.

- in_ris_since:

  Optional RIS recency filter (`ImRisSeit`). Accepts API values
  (`"Undefined"`, `"EinerWoche"`, `"ZweiWochen"`, `"EinemMonat"`,
  `"DreiMonaten"`, `"SechsMonaten"`, `"EinemJahr"`) and English aliases
  (`"one_week"`, `"two_weeks"`, `"one_month"`, `"three_months"`,
  `"six_months"`, `"one_year"`).

- search_decision_text:

  Optional flag for decision text search (`SucheInEntscheidungstexten`).

- search_legal_principles:

  Optional flag for legal principles search (`SucheInRechtssaetzen`).

- echo:

  Logical. If `TRUE`, prints the equivalent RIS website URLs
  (`https://www.ris.bka.gv.at/<Applikation>/` and the corresponding
  `Ergebnis.wxe` query URL) and the number of returned rows, so users
  can double-check the result set in the browser.

- base_url:

  API base URL.

## Value

A tidy tibble with parsed search results. Includes list-columns
`content_urls` and `app_metadata`.

## Details

The Landesverwaltungsgerichte (LVwG) are Austria's nine state
administrative courts (one per Bundesland), established on 1 January
2014. Use `federal_state` to restrict results to a specific state.

## Examples

``` r
if (FALSE) { # \dontrun{
# Search across all nine LVwG
ris_search_lvwg(query = "Baubewilligung")

# Restrict to the Verwaltungsgericht Wien (VGW)
ris_search_lvwg(query = "Baubewilligung", federal_state = "Wien")

# Filter by decision type and state
ris_search_lvwg(
  decision_type = "Erkenntnis",
  federal_state = "Steiermark",
  decision_date_from = "2022-01-01"
)

# Search by norm
ris_search_lvwg(norm = "VStG §19")

# Decisions added to RIS within the last month
ris_search_lvwg(in_ris_since = "one_month", federal_state = "Tirol")
} # }
```
