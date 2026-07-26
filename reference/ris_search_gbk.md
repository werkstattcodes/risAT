# Search Equal Treatment Commission Decisions in RIS

Convenience wrapper around
[`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
with `application = "Gbk"`.

## Usage

``` r
ris_search_gbk(
  query = NULL,
  business_number = NULL,
  norm = NULL,
  decision_date_from = NULL,
  decision_date_to = NULL,
  decision_type = NULL,
  commission = NULL,
  senate = NULL,
  discrimination_ground = NULL,
  in_ris_since = NULL,
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

  Optional decision type (`Entscheidungsart`). Gbk accepts:
  `"Undefined"`, `"Einzelfallpruefungsergebnis"`, `"Gutachten"`.

- commission:

  Optional commission filter (`Kommission`). Accepted values:
  `"Bundes-Gleichbehandlungskommission"` (federal public service) or
  `"Gleichbehandlungskommission"` (private sector). Short aliases
  `"bundesgbk"`/`"bgbk"` and `"gbk"`, and English aliases `"federal"`/
  `"private_sector"` are also accepted (case-insensitive).

- senate:

  Optional senate filter (`Senat`). Accepted values: `"Senat I"`,
  `"Senat II"`, `"Senat III"`. Roman numerals (`"I"`, `"II"`, `"III"`)
  and digits (`"1"`, `"2"`, `"3"`) are also accepted.

- discrimination_ground:

  Optional discrimination ground (`Diskriminierungsgrund`). Accepted
  German values: `"Geschlecht"`, `"Ethnische Zugehörigkeit"`,
  `"Religion"`, `"Weltanschauung"`, `"Alter"`,
  `"Sexuelle Orientierung"`, `"Behinderung"`, and
  `"Mehrfachdiskriminierung"`. English aliases: `"gender"`/`"sex"` -\>
  `"Geschlecht"`, `"ethnicity"`/`"ethnic_origin"` -\>
  `"EthnischeZugehoerigkeit"`, `"religion"` -\> `"Religion"`,
  `"worldview"` -\> `"Weltanschauung"`, `"age"` -\> `"Alter"`,
  `"sexual_orientation"` -\> `"SexuelleOrientierung"`, `"disability"`
  -\> `"Behinderung"`, and `"multiple"`/`"multiple_discrimination"` -\>
  `"Mehrfachdiskriminierung"`. Matching is case-insensitive and ignores
  spaces, underscores, and hyphens.

- in_ris_since:

  Optional RIS recency filter (`ImRisSeit`). Accepts API values
  (`"Undefined"`, `"EinerWoche"`, `"ZweiWochen"`, `"EinemMonat"`,
  `"DreiMonaten"`, `"SechsMonaten"`, `"EinemJahr"`) and English aliases
  (`"one_week"`, `"two_weeks"`, `"one_month"`, `"three_months"`,
  `"six_months"`, `"one_year"`).

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

Covers anonymised decisions of the Bundes-Gleichbehandlungskommission
(Senate I and II) and the Gleichbehandlungskommission für die
Privatwirtschaft (Senate I, II, and III) since 1 January 2014.

Note: the Gbk application does not support `search_decision_text` or
`search_legal_principles` filtering. Those parameters are not available
for this wrapper.

## Examples

``` r
if (FALSE) { # interactive()
# Search all equal treatment commission decisions
ris_search_gbk(query = "Diskriminierung")

# Filter to opinions (Gutachten) on gender discrimination
ris_search_gbk(
  decision_type = "Gutachten",
  discrimination_ground = "Geschlecht"
)

# Filter to individual case review results in the private sector commission
ris_search_gbk(
  decision_type = "Einzelfallpruefungsergebnis",
  commission = "Gleichbehandlungskommission"
)

# Search by norm and senate
ris_search_gbk(
  norm = "GlBG §17",
  senate = "Senat I"
)
}
```
