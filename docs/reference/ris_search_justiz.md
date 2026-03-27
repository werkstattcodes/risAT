# Search Justiz Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Justiz"`.

## Usage

``` r
ris_search_justiz(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  legal_area = NULL,
  specialist_area = NULL,
  court = NULL,
  legal_principle_number = NULL,
  legal_assessment = NULL,
  ruling = NULL,
  citation = NULL,
  changed_since_period = NULL,
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

  Optional decision type (`Entscheidungsart`). Justiz accepts (pass the
  string exactly as shown):
  `"Ordentliche Erledigung (Sachentscheidung)"`,
  `"Zurückweisung mangels erheblicher Rechtsfrage"`,
  `"Zurückweisung aus anderen Gründen"`, `"Verstärkter Senat"`.

- index_term:

  Optional index term (`Index`).

- legal_area:

  Optional legal area filter (`Rechtsgebiet`), e.g. `"Zivilrecht"` or
  `"Strafrecht"`.

- specialist_area:

  Optional specialist area (`Fachgebiet`), e.g. `"Arbeitsrecht"` or
  `"Mietrecht"`.

- court:

  Optional court name (`Gericht`), e.g. `"OGH"`, `"OLG Wien"`.

- legal_principle_number:

  Optional legal principle number (`Rechtssatznummer`), e.g.
  `"0000001"`.

- legal_assessment:

  Optional legal assessment text (`RechtlicheBeurteilung`).

- ruling:

  Optional ruling text (`Spruch`).

- citation:

  Optional citation reference (`Fundstelle`), e.g. `"SZ 75/123"`.

- changed_since_period:

  Optional time window for changes (`AenderungenSeitPeriode`). Same
  interval keywords as `in_ris_since`.

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

Covers decisions from the Oberster Gerichtshof (OGH), Oberlandesgerichte
(OLG), Landesgerichte (LG), Bezirksgerichte (BG), Oberster Patent- und
Markensenat (OPMS, until 2013), and selected foreign decisions (AUSL).

## Examples

``` r
if (FALSE) { # \dontrun{
# Keyword search across decision texts and Rechtssaetze (default).
# The query field supports full-text operators: space/"und" = AND,
# "oder" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
ris_search_justiz(query = "Schadenersatz")

# Filter to OGH decisions only
ris_search_justiz(query = "Schadenersatz", court = "OGH")

# Filter by legal area and date range
ris_search_justiz(
  legal_area = "Zivilrecht",
  decision_date_from = "2022-01-01",
  decision_date_to = "2023-12-31"
)

# Search by legal principle number (Rechtssatznummer)
ris_search_justiz(legal_principle_number = "0000001")

# Search by citation (Fundstelle)
ris_search_justiz(citation = "SZ 75/123")

# Search by norm and restrict to OGH decisions in a specialist area
ris_search_justiz(
  norm = "ABGB §1295",
  specialist_area = "Schadenersatzrecht",
  court = "OGH"
)

# Look up a specific OGH case by business number
# OGH business number format: "N Ob NNN/YY" or "N Ob N/YYg" etc.
ris_search_justiz(business_number = "1Ob1/23g", echo = TRUE)
} # }
```
