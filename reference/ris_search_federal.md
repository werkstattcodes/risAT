# Search Austrian Consolidated Federal Law in RIS

Query the Austrian RIS OGD REST API v2.6 `/Bundesrecht` endpoint,
application **BrKons** ("Bundesrecht in konsolidierter Fassung",
consolidated federal law). This is a convenience wrapper around
[`ris_req_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_req_federal.md)
and
[`ris_perform_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_perform_federal.md).

## Usage

``` r
ris_search_federal(
  query = NULL,
  title = NULL,
  index = NULL,
  type = NULL,
  law_number = NULL,
  promulgation_organ = NULL,
  promulgation_number = NULL,
  signature_date = NULL,
  version_date = NULL,
  effective_from = NULL,
  effective_to = NULL,
  expiry_from = NULL,
  expiry_to = NULL,
  section_from = NULL,
  section_to = NULL,
  section_type = NULL,
  in_ris_since = NULL,
  sort_by = NULL,
  sort_direction = NULL,
  echo = FALSE,
  base_url = ris_base_url()
)
```

## Arguments

- query:

  Optional full-text query (`Suchworte`). Supports the RIS full-text
  operators (space/`und` = AND, `OR`/`ODER` = OR, `nicht` = NOT, `*` =
  wildcard, `'phrase'` for exact phrase).

- title:

  Optional title or abbreviation of the legal norm (`Titel`).

- index:

  Optional index reference from the systematic directory of federal law
  (`Index`, e.g. `"20/01"`).

- type:

  Optional norm type (`Typ`).

- law_number:

  Optional law number (`Gesetzesnummer`), an exact-match identifier for
  the consolidated norm.

- promulgation_organ:

  Optional promulgation organ (`Kundmachungsorgan`), e.g.
  `"BGBl. I Nr."`, `"BGBl. II Nr."`, `"RGBl. Nr."`.

- promulgation_number:

  Optional promulgation number (`Kundmachungsorgannummer`, e.g.
  `"25/2012"`).

- signature_date:

  Optional signature date (`Unterzeichnungsdatum`, `YYYY-MM-DD`).

- version_date:

  Optional point-in-time version date (`Fassung.FassungVom`,
  `YYYY-MM-DD`): retrieve the consolidated text as it stood on this
  date. Cannot be combined with the `effective_*` / `expiry_*` range
  arguments.

- effective_from, effective_to:

  Optional entry-into-force date range (`Fassung.VonInkrafttretensdatum`
  / `Fassung.BisInkrafttretensdatum`, `YYYY-MM-DD`).

- expiry_from, expiry_to:

  Optional expiry (out-of-force) date range
  (`Fassung.VonAusserkrafttretensdatum` /
  `Fassung.BisAusserkrafttretensdatum`, `YYYY-MM-DD`).

- section_from, section_to:

  Optional section (article/paragraph/annex) range to narrow within a
  norm (`Abschnitt.Von` / `Abschnitt.Bis`).

- section_type:

  Optional section type (`Abschnitt.Typ`). One of `"Alle"`, `"Artikel"`,
  `"Paragraph"`, `"Anlage"` (English aliases `"all"`, `"article"`,
  `"paragraph"`, `"annex"`). Required by the API when a section range is
  given; defaults to `"Alle"` in that case.

- in_ris_since:

  Optional RIS recency filter (`ImRisSeit`). Accepts API values
  (`"Undefined"`, `"EinerWoche"`, `"ZweiWochen"`, `"EinemMonat"`,
  `"DreiMonaten"`, `"SechsMonaten"`, `"EinemJahr"`) and English aliases
  (`"one_week"`, `"two_weeks"`, `"one_month"`, `"three_months"`,
  `"six_months"`, `"one_year"`).

- sort_by:

  Optional sort column (`Sortierung.SortedByColumn`). One of
  `"ArtikelParagraphAnlage"`, `"Kurzinformation"`,
  `"Inkrafttretensdatum"`, `"Ausserkrafttretensdatum"`.

- sort_direction:

  Optional sort direction (`Sortierung.SortDirection`): `"Ascending"` or
  `"Descending"`.

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

Results are fetched iteratively across all pages in scope using
[`httr2::req_perform_iterative()`](https://httr2.r-lib.org/reference/req_perform_iterative.html).

## Examples

``` r
if (FALSE) { # interactive()
# Look up a law by its (short) title
ris_search_federal(title = "ABGB")

# Full-text search with the consolidated text as it stood on a given date
ris_search_federal(query = "Mietzins", version_date = "2020-01-01")

# Norms that entered into force within a date range, echoing the browser URL
ris_search_federal(
  effective_from = "2024-01-01",
  effective_to = "2024-12-31",
  echo = TRUE
)
}
```
