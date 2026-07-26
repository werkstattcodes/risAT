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
  base_url = ris_base_url()
)
```

## Arguments

- query:

  Optional full-text query (`Suchworte`). Supports the RIS full-text
  operators (space/`und` = AND, `OR`/`ODER` = OR, `nicht` = NOT, `*` =
  wildcard, `'phrase'` for exact phrase).

- business_number:

  Optional business number (`Geschaeftszahl`).

- norm:

  Optional legal norm query (`Norm`). Multiple norms can be combined
  with `OR`/`ODER` (wrap each norm in single quotes, e.g.
  `"'AsylG 2005 §3' ODER 'BFA-VG §21 Abs7'"`).

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
  When both flags are omitted, both document types are searched. When
  only one flag is given, the other defaults to its complement, so a
  single flag selects exactly one document type (e.g.
  `search_decision_text = FALSE` searches legal principles only).
  Setting both to `FALSE` is an error.

- echo:

  Logical. If `TRUE`, prints two progress messages: the equivalent RIS
  website search URL (the `Ergebnis.wxe` query on
  `https://www.ris.bka.gv.at`) before any request is sent; and the total
  hit and page count as soon as the first page's response arrives. This
  lets the result set be double-checked in the browser and gives an
  early sense of scope for broad queries without waiting for every page.

- base_url:

  API base URL. Defaults to
  [`ris_base_url()`](https://werkstattcodes.github.io/risAT/reference/ris_base_url.md),
  which can be overridden for a session via
  `options(risAT.base_url = ...)`.

## Value

A tidy tibble with parsed search results. Includes list-column
`content_urls`.

## Examples

``` r
if (FALSE) { # interactive()
# Keyword search across both decision texts and Rechtssaetze (default).
# The query field supports full-text operators: space/"und" = AND,
# "OR"/"ODER" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
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

# Multiple norms: wrap each in single quotes and join with "ODER" (or "OR")
ris_search_vwgh(norm = "'AsylG 2005 §3' ODER 'BFA-VG §21 Abs7'")

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
}
```
