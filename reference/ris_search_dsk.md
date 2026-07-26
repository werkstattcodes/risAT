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

Covers decisions of Austria's data protection authorities: the
Datenschutzkommission (DSK, 1990–2013), the Datenschutzbehörde (DSB,
since 2014), and the Parlamentarisches Datenschutzkomitee (PDK, since
2025).

## Examples

``` r
if (FALSE) { # interactive()
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
}
```
