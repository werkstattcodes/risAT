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
  values: `"Geschlecht"`, `"Ethnische Zugehörigkeit"`, `"Religion"`,
  `"Weltanschauung"`, `"Alter"`, `"Sexuelle Orientierung"`,
  `"Behinderung"`, `"Mehrfachdiskriminierung"`. English aliases
  (`"gender"`, `"age"`, `"disability"`, `"ethnicity"`,
  `"sexual_orientation"`, etc.) are also accepted (case-insensitive).

- in_ris_since:

  Optional RIS recency filter (`ImRisSeit`). Accepts API values
  (`"Undefined"`, `"EinerWoche"`, `"ZweiWochen"`, `"EinemMonat"`,
  `"DreiMonaten"`, `"SechsMonaten"`, `"EinemJahr"`) and English aliases
  (`"one_week"`, `"two_weeks"`, `"one_month"`, `"three_months"`,
  `"six_months"`, `"one_year"`).

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

Covers anonymised decisions of the Bundes-Gleichbehandlungskommission
(Senate I and II) and the Gleichbehandlungskommission für die
Privatwirtschaft (Senate I, II, and III) since 1 January 2014.

Note: the Gbk application does not support `search_decision_text` or
`search_legal_principles` filtering. Those parameters are not available
for this wrapper.

## Examples

``` r
if (FALSE) { # \dontrun{
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
} # }
```
