# Search Staff Representation Oversight Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Pvak"`.

## Usage

``` r
ris_search_pvak(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  deciding_authority = NULL,
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

  Optional decision type (`Entscheidungsart`). Free-text; the API
  validates server-side.

- deciding_authority:

  Optional filter for the deciding body (`EntscheidendeBehoerde`), e.g.
  `"Personalvertretungsaufsichtsbehörde"`.

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

Covers decisions of Austria's staff representation oversight bodies: the
Personalvertretungs-Aufsichtskommission (PVAK, 1999–2013) and the
Personalvertretungsaufsichtsbehörde (PVAB, since 2014).

## Examples

``` r
if (FALSE) { # \dontrun{
# Search all staff representation oversight decisions
ris_search_pvak(query = "Wahlrecht")

# Filter to PVAB decisions (since 2014)
ris_search_pvak(
  deciding_authority = "Personalvertretungsaufsichtsbehörde",
  decision_date_from = "2014-01-01"
)

# Search by norm
ris_search_pvak(norm = "BPVG §22")
} # }
```
