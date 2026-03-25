# Search VwGH Decisions in RIS

Search VwGH Decisions in RIS

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
  sort_by = NULL,
  sort_direction = NULL,
  search_decision_text = TRUE,
  search_legal_principles = TRUE,
  page = 1L,
  per_page = 20L,
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

  Optional decision type (`Entscheidungsart`). For VfGH, accepted values
  are `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`, `"Vergleich"`,
  `"KeineAngabe"` and aliases `"order"`, `"judgment"`, `"settlement"`,
  `"not_specified"`.

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

- sort_by:

  Optional sort column (`SortierungSortedByColumn`). For VfGH, accepted
  values are `"Geschaeftszahl"`, `"Datum"`, `"Art"`, `"Typ"` and aliases
  `"business_number"`, `"decision_date"`, `"decision_type"`,
  `"document_type"`.

- sort_direction:

  Optional sort direction (`SortierungSortDirection`), one of
  `"Ascending"` or `"Descending"` (case-insensitive).

- search_decision_text:

  Optional flag for decision text search (`SucheInEntscheidungstexten`).

- search_legal_principles:

  Optional flag for legal principles search (`SucheInRechtssaetzen`).

- page:

  Legacy argument kept for backward compatibility. Search functions now
  always iterate all pages from page `1`.

- per_page:

  Results per page. Allowed values: `10`, `20`, `50`, `100` (mapped to
  `DokumenteProSeite` values `Ten`, `Twenty`, `Fifty`, `OneHundred`).

- base_url:

  API base URL.

## Value

A tidy tibble with parsed search results from all pages in scope.
Includes `page`, `per_page`, and list-columns `content_urls`,
`app_metadata`.
