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

## Details

The Bundesverwaltungsgericht (BVwG) was established on 1 January 2014
and covers federal administrative matters, including asylum,
immigration, procurement, and telecommunications decisions.

## Examples

``` r
if (FALSE) { # interactive()
# Keyword search across decision texts and Rechtssaetze (default).
# The query field supports full-text operators: space/"und" = AND,
# "OR"/"ODER" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
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
}
```
