# Search Austrian Case Law in RIS

Query the Austrian RIS OGD REST API v2.6 endpoint `/Judikatur`.

## Usage

``` r
ris_search_case_law(
  application,
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  collection_number = NULL,
  title = NULL,
  document_kind = NULL,
  publication_organ = NULL,
  legal_area = NULL,
  specialist_area = NULL,
  court = NULL,
  legal_principle_number = NULL,
  legal_assessment = NULL,
  ruling = NULL,
  citation = NULL,
  changed_since_period = NULL,
  federal_state = NULL,
  deciding_authority = NULL,
  commission = NULL,
  senate = NULL,
  discrimination_ground = NULL,
  author = NULL,
  short_title = NULL,
  domain = NULL,
  in_ris_since = NULL,
  sort_by = NULL,
  sort_direction = NULL,
  search_decision_text = NULL,
  search_legal_principles = NULL,
  page = 1L,
  per_page = 20L,
  base_url = "https://data.bka.gv.at/ris/api/v2.6"
)
```

## Arguments

- application:

  Judikatur application. Accepts RIS codes (`"Vfgh"`, `"Vwgh"`,
  `"Normenliste"`, `"Justiz"`, `"Bvwg"`, `"Lvwg"`, `"Dsk"`, `"Dok"`,
  `"Pvak"`, `"Gbk"`, `"Uvs"`, `"AsylGH"`, `"Ubas"`, `"Umse"`, `"Bks"`,
  `"Verg"`) and English aliases (for example `"constitutional_court"`,
  `"administrative_court"`, `"justice"`,
  `"federal_administrative_court"`, `"state_administrative_courts"`).

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

- title:

  Optional title (`Titel`), used for `Normenliste`.

- document_kind:

  Optional document kind (`Typ`), used for `Normenliste`.

- publication_organ:

  Optional publication organ (`Kundmachungsorgan`), used for
  `Normenliste`.

- legal_area:

  Optional legal area (`Rechtsgebiet`), used for `Justiz`.

- specialist_area:

  Optional specialist area (`Fachgebiet`), used for `Justiz`.

- court:

  Optional court (`Gericht`), used for `Justiz`.

- legal_principle_number:

  Optional legal principle number (`Rechtssatznummer`), used for
  `Justiz`.

- legal_assessment:

  Optional legal assessment (`RechtlicheBeurteilung`), used for
  `Justiz`.

- ruling:

  Optional ruling text (`Spruch`), used for `Justiz` and `Ubas`.

- citation:

  Optional citation (`Fundstelle`), used for `Justiz`.

- changed_since_period:

  Optional change window (`AenderungenSeitPeriode`), used for `Justiz`.

- federal_state:

  Optional federal state (`Bundesland`), used for `Lvwg` and `Uvs`.

- deciding_authority:

  Optional deciding authority (`EntscheidendeBehoerde`), used for `Dsk`,
  `Dok`, `Pvak`, `Verg`.

- commission:

  Optional commission (`Kommission`), used for `Gbk`.

- senate:

  Optional senate (`Senat`), used for `Gbk`.

- discrimination_ground:

  Optional discrimination ground (`Diskriminierungsgrund`), used for
  `Gbk`.

- author:

  Optional author (`Verfasser`), used for `Ubas`.

- short_title:

  Optional short title (`Kurzbezeichnung`), used for `Umse`.

- domain:

  Optional domain (`Bereich`), used for `Bks`.

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

## Details

Results are fetched iteratively across all pages in scope using
[`httr2::req_perform_iterative()`](https://httr2.r-lib.org/reference/req_perform_iterative.html).

## Examples

``` r
if (FALSE) { # \dontrun{
ris_search_case_law(
  application = "federal_administrative_court",
  query = "Asyl",
  per_page = 20
)
} # }
```
