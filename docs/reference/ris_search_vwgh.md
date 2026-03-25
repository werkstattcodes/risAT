# Search VwGH Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Vwgh"`.

## Usage

``` r
ris_search_vwgh(
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

  Optional decision type (`Entscheidungsart`). VwGH accepts:
  `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`, `"BeschlussVS"`,
  `"ErkenntnisVS"` (VS = Verstaerkter Senat / reinforced senate).

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

## Examples

``` r
if (FALSE) { # \dontrun{
# Keyword search across both decision texts and Rechtssaetze (default).
# The query field supports full-text operators: space/"und" = AND,
# "oder" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
ris_search_vwgh(query = "Asylrecht")

# Wildcard and phrase search examples
ris_search_vwgh(query = "Verwaltungsstrafe*")
ris_search_vwgh(query = "'unverhältnismäßiger Eingriff'")

# Search only in Rechtssaetze for a specific legal norm.
# Norm notation: include the year where it is part of the official
# abbreviation (e.g. "AsylG 2005", "StVO 1960", "EStG 1988").
ris_search_vwgh(
  norm = "AsylG 2005 §3",
  search_decision_text = FALSE,
  search_legal_principles = TRUE
)

# Multiple norms: wrap each in single quotes and join with "oder"
ris_search_vwgh(norm = "'AsylG 2005 §3' oder 'BFA-VG §21 Abs7'")
ris_search_vwgh(norm = "'AsylG 2005 §3' oder 'BFA-VG §21 Abs7'")
 
# Filter by decision type and date range.
# decision_type for VwGH: "Beschluss", "Erkenntnis", "BeschlussVS",
# "ErkenntnisVS" (VS = Verstaerkter Senat / reinforced senate).
ris_search_vwgh(
  query = "Ermessen",
  decision_type = "Erkenntnis",
  decision_date_from = "2022-01-01",
  decision_date_to = "2023-12-31"
)

# Reinforced senate judgments (ErkenntnisVS) added to RIS in the last month
ris_search_vwgh(
  decision_type = "ErkenntnisVS",
  in_ris_since = "one_month"
)

# Search by Index (numeric classification of Austrian law).
# Federal law index values start with a number (e.g. "40/01" for Steuerrecht),
# state law index values start with "L" (e.g. "L37152" for Tiroler Baurecht).
ris_search_vwgh(index_term = "40/01")

# Look up a specific case by business number and echo the equivalent
# browser URL on www.ris.bka.gv.at.
# VwGH business number formats: "Ra YYYY/XX/NNNN", "Ro YYYY/XX/NNNN",
# or older format "YYYY/XX/NNNN". VwGH decisions are available from 1990.
ris_search_vwgh(
  business_number = "Ra 2021/01/0001",
  echo = TRUE
)
} # }
```
