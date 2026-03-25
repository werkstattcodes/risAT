# Search BVwG Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Bvwg"`.

## Usage

``` r
ris_search_bvwg(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  collection_number = NULL,
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

  Optional decision type (`Entscheidungsart`). BVwG accepts:
  `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`.

- index_term:

  Optional index term (`Index`).

- collection_number:

  Optional collection number (`Sammlungsnummer`).

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

The Bundesverwaltungsgericht (BVwG) was established on 1 January 2014
and covers federal administrative matters, including asylum,
immigration, procurement, and telecommunications decisions.

## Examples

``` r
if (FALSE) { # \dontrun{
# Keyword search across decision texts and Rechtssaetze (default).
# The query field supports full-text operators: space/"und" = AND,
# "oder" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
ris_search_bvwg(query = "Asyl")

# Filter to Erkenntnis decisions within a date range
ris_search_bvwg(
  decision_type = "Erkenntnis",
  decision_date_from = "2023-01-01",
  decision_date_to = "2023-12-31"
)

# Search by norm (BVwG frequently applies VwGVG, AsylG 2005, BFA-VG)
ris_search_bvwg(norm = "AsylG 2005 §3")

# Decisions added to RIS within the last month
ris_search_bvwg(in_ris_since = "one_month")

# Look up a specific decision by business number and echo the browser URL.
# BVwG business number format: "W NNN NNNNNNNN-N/YYYYX" or similar.
ris_search_bvwg(business_number = "W175 2221503-1", echo = TRUE)
} # }
```
