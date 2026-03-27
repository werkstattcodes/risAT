# Search Data Protection Authority Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Dsk"`.

## Usage

``` r
ris_search_dsk(
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

  Optional decision type (`Entscheidungsart`). Dsk accepts (pass the
  string exactly as shown): `"Undefined"`, `"BescheidBeschwerde"`,
  `"BescheidAmtswegigesPruefverfahren"`,
  `"VerwaltungsstraferkenntnisVerwarnungErmahnung"`,
  `"BescheidWissenschaftStatistikArchiv"`,
  `"BescheidInternatDatenverkehr"`,
  `"BescheidAkkreditierungZertifizierung"`,
  `"BescheidVerhaltensregeln"`, `"BescheidWarnung"`,
  `"BescheidRegistrierung"`, `"BescheidSonstiger"`, `"Empfehlung"`,
  `"BescheidIFG"`, `"Verfahrensschriftsaetze"`.

- deciding_authority:

  Optional filter for the deciding body (`EntscheidendeBehoerde`), e.g.
  `"Datenschutzbehörde"`.

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

Covers decisions of Austria's data protection authorities: the
Datenschutzkommission (DSK, 1990–2013), the Datenschutzbehörde (DSB,
since 2014), and the Parlamentarisches Datenschutzkomitee (PDK, since
2025).

## Examples

``` r
if (FALSE) { # \dontrun{
# Search across all data protection authority decisions
ris_search_dsk(query = "Videoüberwachung")

# GDPR-era DSB decisions only
ris_search_dsk(
  query = "DSGVO",
  decision_date_from = "2018-05-25"
)

# Filter to a specific decision type
ris_search_dsk(decision_type = "BescheidBeschwerde")

# Filter by deciding authority (DSB since 2014)
ris_search_dsk(
  query = "Auskunftsrecht",
  deciding_authority = "Datenschutzbehörde"
)

# Decisions added to RIS within the last six months
ris_search_dsk(in_ris_since = "six_months")
} # }
```
