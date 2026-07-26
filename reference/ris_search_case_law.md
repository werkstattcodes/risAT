# Search Austrian Case Law in RIS

Query the Austrian RIS OGD REST API v2.6 endpoint `/Judikatur`. This is
a convenience wrapper around
[`ris_req_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_req_case_law.md)
and
[`ris_perform_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_perform_case_law.md).

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
  search_decision_text = NULL,
  search_legal_principles = NULL,
  sort_by = NULL,
  sort_direction = NULL,
  echo = FALSE,
  base_url = ris_base_url()
)
```

## Arguments

- application:

  Judikatur application. Accepts RIS codes or English aliases
  (case-insensitive):

  |  |  |  |
  |----|----|----|
  | Code | English Alias | Court / Body |
  | `"Vfgh"` | `"constitutional_court"` | Constitutional Court (VfGH) |
  | `"Vwgh"` | `"administrative_court"` | Supreme Administrative Court (VwGH) |
  | `"Justiz"` | `"justice"` | Ordinary courts (OGH, OLG, LG, BG, OPMS, AUSL) |
  | `"Bvwg"` | `"federal_administrative_court"` | Federal Administrative Court (BVwG) |
  | `"Lvwg"` | `"state_administrative_courts"` | State Administrative Courts (LVwG) |
  | `"Normenliste"` | `"norm_list"` | VwGH Norm List |
  | `"Dsk"` | `"data_protection_authority"` | Data protection authorities (DSK/DSB/PDK) |
  | `"Dok"` | `"disciplinary_bodies"` | Federal Disciplinary Authority & commissions |
  | `"Pvak"` | `"staff_representation_oversight"` | Staff Representation Oversight Authority |
  | `"Gbk"` | `"equal_treatment_commission"` | Equal Treatment Commissions (since 2014) |
  | `"Uvs"` | `"independent_administrative_panels"` | Independent Administrative Panels (1991–2013) |
  | `"AsylGH"` | `"asylum_court"` | Asylum Court (2008–2013) |
  | `"Ubas"` | `"independent_federal_asylum_panel"` | Independent Federal Asylum Panel (1998–2008) |
  | `"Umse"` | `"environmental_panel"` | Environmental Panel (1994–2013) |
  | `"Bks"` | `"federal_communications_panel"` | Federal Communications Panel (2001–2013) |
  | `"Verg"` | `"procurement_review_bodies"` | Procurement Review Bodies (until 2013) |

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

  Optional decision type (`Entscheidungsart`). Allowed values depend on
  `application`:

  - **VfGH**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
    `"Vergleich"`, `"KeineAngabe"` (English aliases: `"order"`,
    `"judgment"`, `"settlement"`, `"not_specified"`).

  - **VwGH**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
    `"BeschlussVS"`, `"ErkenntnisVS"`.

  - **BVwG**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`.

  - **LVwG / UVS**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
    `"Bescheid"`.

  - **Justiz**: `"Ordentliche Erledigung (Sachentscheidung)"`,
    `"Zurückweisung mangels erheblicher Rechtsfrage"`,
    `"Zurückweisung aus anderen Gründen"`, `"Verstärkter Senat"`.

  - **AsylGH**: `"Undefined"`, `"Beschluss"`, `"Erkenntnis"`,
    `"ErkenntnisGrundsatzentscheidung"`,
    `"ErkenntnisVerstaerkterSenat"`, `"Bescheid"`.

  - **Ubas**: `"Undefined"`, `"Bescheid"`, `"Ersatzbescheid"`.

  - **Gbk**: `"Undefined"`, `"Einzelfallpruefungsergebnis"`,
    `"Gutachten"`.

  - **Dsk**: `"Undefined"`, `"BescheidBeschwerde"`,
    `"BescheidAmtswegigesPruefverfahren"`,
    `"VerwaltungsstraferkenntnisVerwarnungErmahnung"`,
    `"BescheidWissenschaftStatistikArchiv"`,
    `"BescheidInternatDatenverkehr"`,
    `"BescheidAkkreditierungZertifizierung"`,
    `"BescheidVerhaltensregeln"`, `"BescheidWarnung"`,
    `"BescheidRegistrierung"`, `"BescheidSonstiger"`, `"Empfehlung"`,
    `"BescheidIFG"`, `"Verfahrensschriftsaetze"`.

  Values for VfGH, VwGH, BVwG, LVwG, Justiz, Dsk, and Gbk are validated
  client-side. Values for all other applications (including AsylGH and
  Ubas) are passed to the API as-is and validated server-side only.

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
  `Gbk`. Accepted German values: `"Geschlecht"`,
  `"Ethnische Zugehörigkeit"`, `"Religion"`, `"Weltanschauung"`,
  `"Alter"`, `"Sexuelle Orientierung"`, `"Behinderung"`, and
  `"Mehrfachdiskriminierung"`. English aliases: `"gender"`/`"sex"` -\>
  `"Geschlecht"`, `"ethnicity"`/ `"ethnic_origin"` -\>
  `"EthnischeZugehoerigkeit"`, `"religion"` -\> `"Religion"`,
  `"worldview"` -\> `"Weltanschauung"`, `"age"` -\> `"Alter"`,
  `"sexual_orientation"` -\> `"SexuelleOrientierung"`, `"disability"`
  -\> `"Behinderung"`, and `"multiple"`/ `"multiple_discrimination"` -\>
  `"Mehrfachdiskriminierung"`. Matching is case-insensitive and ignores
  spaces, underscores, and hyphens.

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

- search_decision_text:

  Optional flag for decision text search (`SucheInEntscheidungstexten`).

- search_legal_principles:

  Optional flag for legal principles search (`SucheInRechtssaetzen`).
  When both flags are omitted, both document types are searched. When
  only one flag is given, the other defaults to its complement, so a
  single flag selects exactly one document type (e.g.
  `search_decision_text = FALSE` searches legal principles only).
  Setting both to `FALSE` is an error.

- sort_by:

  Sort column (`SortierungSortedByColumn`). When omitted, defaults to
  `"Datum"` (decision date) for all applications except `Normenliste`,
  whose only sortable column is `"Kurzinformation"` — there the sort
  parameters are omitted and the API default order applies. For VfGH and
  VwGH the value is validated client-side against `"Geschaeftszahl"`,
  `"Datum"`, `"Art"`, `"Typ"` (English aliases
  `"business_number"`/`"case_number"`, `"decision_date"`,
  `"decision_type"`, `"document_type"`); for `Normenliste` against
  `"Kurzinformation"` (alias `"brief_info"`); other applications pass
  the value to the API as-is.

- sort_direction:

  Sort direction (`SortierungSortDirection`): `"Ascending"` or
  `"Descending"`. Defaults to `"Descending"` whenever a sort column is
  in effect.

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
ris_search_case_law(
  application = "federal_administrative_court",
  query = "Asyl"
)
}
```
