# Search VfGH Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Vfgh"`.

## Usage

``` r
ris_search_vfgh(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  index_term = NULL,
  collection_number = NULL,
  in_ris_since = NULL,
  search_decision_text = FALSE,
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

  Optional decision type (`Entscheidungsart`). VfGH accepts:
  `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`, `"Vergleich"`,
  `"KeineAngabe"` (English aliases: `"order"`, `"judgment"`,
  `"settlement"`, `"not_specified"`).

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

Defaults are aligned with the VfGH RIS handbook:
`search_legal_principles = TRUE` and `search_decision_text = FALSE`
(default search in Rechtssaetze).

## Examples

``` r
if (FALSE) { # interactive()
# Search Rechtssaetze (default per VfGH handbook) for a constitutional keyword.
# The query field supports full-text operators: space/"und" = AND,
# "OR"/"ODER" = OR, "nicht" = NOT, * = wildcard, 'phrase' for exact phrase.
ris_search_vfgh(query = "Meinungsfreiheit")

# Wildcard and phrase search examples
ris_search_vfgh(query = "Grundrecht*")
ris_search_vfgh(query = "'wahlwerbenden Parteien'")

# Also search full decision texts (overrides the VfGH default of RS only)
ris_search_vfgh(
  query = "Eigentumsrecht",
  search_decision_text = TRUE,
  search_legal_principles = TRUE
)

# Judgments on a specific norm. Results are always sorted by decision date
# descending (most recent first).
# Norm notation: include the year where it is part of the official
# abbreviation (e.g. "StGG Art2", "EStG 1988 §29 Z1", "AsylG 2005 §5").
# For multiple norms wrap each in single quotes: 'StGG Art2' ODER 'B-VG Art7'
ris_search_vfgh(
  norm = "B-VG Art7",
  decision_type = "judgment"
)

# Search by Sammlungsnummer (collection number from the official VfGH
# series VfSlg). Enter digits only, without dot, space, or slash.
ris_search_vfgh(collection_number = "18743")

# Decisions added to RIS within the last six months
ris_search_vfgh(in_ris_since = "six_months")

# Search by Index (numeric classification of Austrian law).
# Federal law index values start with a number (e.g. "32/02" for Steuerrecht,
# "07/01" for Verfassungsrecht), state law index values start with "L"
# (e.g. "L6500"). The full index list is linked from the VfGH search page.
ris_search_vfgh(index_term = "07/01")

# Look up a specific case by business number and echo the equivalent
# browser URL on www.ris.bka.gv.at.
# VfGH decisions are available from 1980 in full text; selected decisions
# from 1919-1933 and 1946-1979 are available as PDF scans.
# Business number formats (four-digit year since 08.04.2013):
#   G NNNN/YYYY  (constitutional review of laws, Gesetzesprüfung)
#   V NNN/YYYY   (review of ordinances, Verordnungsprüfung)
#   U NNN/YYYY   (individual complaint, Art144 B-VG)
#   E NNN/YYYY   (complaint under EU Charter of Fundamental Rights)
#   B NNN/YY     (old-style individual complaint, pre-2013)
ris_search_vfgh(
  business_number = "G 97/2021",
  echo = TRUE
)
}
```
