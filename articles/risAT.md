# Getting started with risAT

## What is risAT?

risAT provides a tidyverse-friendly interface to the Austrian
[RIS](https://www.ris.bka.gv.at/) (Rechtsinformationssystem) Open
Government Data REST API v2.6. It covers the `/Judikatur` endpoint (case
law / jurisprudence) across all supported court applications and is
designed for reproducible legal research.

## Installation

``` r
# install.packages("pak")
pak::pak("werkstattcodes/risAT")
```

## Quick search

The easiest way to search is with a court-specific wrapper. Each wrapper
targets a single court application and provides typed, validated
arguments:

``` r
library(risAT)

# Search the Administrative Court (VwGH) for decisions about "Baurecht"
results <- ris_search_vwgh(query = "Baurecht")
results
```

All search functions return a tibble. Key columns include `id`,
`application`, `decision_date`, `case_number`, `document_type`, and two
list-columns: `content_urls` (download links) and `app_metadata`
(court-specific fields and response metadata).

## Available court wrappers

risAT provides convenience wrappers for all 9 Judikatur applications:

| Court / Application                 | Function                                                                                       |
|-------------------------------------|------------------------------------------------------------------------------------------------|
| VfGH (Constitutional Court)         | [`ris_search_vfgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vfgh.md)     |
| VwGH (Administrative Court)         | [`ris_search_vwgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vwgh.md)     |
| Justiz (OGH, OLG, LG, BG)           | [`ris_search_justiz()`](https://werkstattcodes.github.io/risAT/reference/ris_search_justiz.md) |
| BVwG (Federal Administrative Court) | [`ris_search_bvwg()`](https://werkstattcodes.github.io/risAT/reference/ris_search_bvwg.md)     |
| LVwG (State Administrative Courts)  | [`ris_search_lvwg()`](https://werkstattcodes.github.io/risAT/reference/ris_search_lvwg.md)     |
| DSK / DSB (Data Protection)         | [`ris_search_dsk()`](https://werkstattcodes.github.io/risAT/reference/ris_search_dsk.md)       |
| DOK (Disciplinary Bodies)           | [`ris_search_dok()`](https://werkstattcodes.github.io/risAT/reference/ris_search_dok.md)       |
| PVAK (Staff Representation)         | [`ris_search_pvak()`](https://werkstattcodes.github.io/risAT/reference/ris_search_pvak.md)     |
| GBK (Equal Treatment Commission)    | [`ris_search_gbk()`](https://werkstattcodes.github.io/risAT/reference/ris_search_gbk.md)       |

Plus a generic function that accepts any application code:

``` r
results <- ris_search_case_law(
  application = "data_protection",
  query = "DSGVO"
)
```

## Filtering results

All wrappers accept common filter arguments:

``` r
results <- ris_search_vwgh(
  query = "Asyl",
  decision_date_from = "2024-01-01",
  decision_date_to = "2024-06-30",
  decision_type = "Erkenntnis",
  per_page = 50
)
```

Some courts have additional parameters. For example,
[`ris_search_justiz()`](https://werkstattcodes.github.io/risAT/reference/ris_search_justiz.md)
accepts `court`, `legal_area`, and `specialist_area`:

``` r
results <- ris_search_justiz(
  query = "Schadenersatz",
  court = "OGH"
)
```

## The two-step pattern

Under the hood, each search wrapper calls two lower-level functions:

1.  [`ris_req_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_req_case_law.md)
    – builds an `httr2` request object
2.  [`ris_perform_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_perform_case_law.md)
    – executes it with automatic pagination

You can use these directly for more control:

``` r
# Build the request (no network call yet)
req <- ris_req_case_law(
  application = "Vwgh",
  query = "Baurecht",
  per_page = 20
)

# Inspect the URL before sending
req$url

# Execute with pagination
results <- ris_perform_case_law(req)
```

## Pagination

The RIS API returns results in pages. risAT handles pagination
automatically, fetching all available pages by default. Use `max_pages`
to limit the number of pages retrieved (useful during development or for
large result sets):

``` r
# Fetch at most 3 pages (60 results at 20 per page)
results <- ris_search_vwgh(
  query = "Baurecht",
  max_pages = 3,
  per_page = 20
)
```

The total number of hits reported by the API is stored in the response
metadata and can be accessed via the `app_metadata` list-column:

``` r
results$app_metadata[[1]]$response$hits
```

## Working with results

The output tibble is designed for use with dplyr and tidyr:

``` r
library(dplyr)

results |>
  filter(decision_date >= "2024-01-01") |>
  select(id, case_number, decision_date, decision_type)
```

Content download URLs are stored as a character vector in the
`content_urls` list-column:

``` r
# Get URLs for the first result
results$content_urls[[1]]
```

## Echo mode

Set `echo = TRUE` in any search function to print the equivalent RIS
website URL. This lets you open the same search in a browser to
cross-check results:

``` r
results <- ris_search_vwgh(
  query = "Baurecht",
  echo = TRUE
)
```

## Column name reference

The RIS API returns metadata in German. risAT translates these to
English column names. The tables below document all columns grouped by
scope, showing the English column name used by risAT, the original
German API field, and a short description. Columns not listed here are
passed through in their original snake_case form.

### Common columns

These columns appear across most or all court applications.

| Column                 | German source field                | Description                                                 |
|------------------------|------------------------------------|-------------------------------------------------------------|
| `id`                   | `Technisch > ID`                   | Unique RIS document identifier                              |
| `application`          | `Technisch > Applikation`          | RIS application code (e.g. `"Vwgh"`, `"Justiz"`)            |
| `authority`            | `Technisch > Organ`                | Issuing authority / court name                              |
| `published`            | `Allgemein > Veroeffentlicht`      | Publication date                                            |
| `modified`             | `Allgemein > Geaendert`            | Last modification date                                      |
| `document_url`         | `Allgemein > DokumentUrl`          | RIS web page URL for the document                           |
| `document_type`        | `Dokumenttyp`                      | Document type (`"Rechtssatz"`, `"Entscheidungstext"`, etc.) |
| `case_number`          | `Geschaeftszahl`                   | Business / case number                                      |
| `norms`                | `Normen`                           | Referenced legal norms (list-column)                        |
| `decision_date`        | `Entscheidungsdatum`               | Decision date                                               |
| `keywords`             | `Schlagworte`                      | Keywords / index terms                                      |
| `ecli`                 | `EuropeanCaseLawIdentifier`        | ECLI identifier                                             |
| `full_decision_url`    | `GesamteEntscheidungUrl`           | URL to the full decision page                               |
| `legal_principles_url` | `RechtssaetzeUrl`                  | URL to the legal principles page                            |
| `decision_text_url`    | `EntscheidungstextUrl`             | URL to the decision text                                    |
| `content_urls`         | `Dokumentliste > ContentReference` | Content download URLs (list-column)                         |
| `app_metadata`         | —                                  | Package-generated metadata (list-column)                    |

### VwGH (Administrative Court)

| Column                                | Description                                 |
|---------------------------------------|---------------------------------------------|
| `vwgh_decision_type`                  | Decision type (Beschluss, Erkenntnis, etc.) |
| `vwgh_court`                          | Court name                                  |
| `vwgh_indices`                        | Legal index entries (list-column)           |
| `vwgh_collection_number`              | Official collection number (VwSlg)          |
| `vwgh_document_number_type`           | Document number type code                   |
| `vwgh_primary_legal_principle_number` | Primary legal principle number              |
| `vwgh_legal_principle_number`         | Legal principle number                      |
| `vwgh_primary_principle_reference`    | Reference to the primary legal principle    |
| `vwgh_legal_principle_chain_url`      | URL to the legal principle chain            |
| `vwgh_note`                           | Editorial notes (Beachte)                   |
| `vwgh_court_decisions`                | Related court decisions (list-column)       |

### VfGH (Constitutional Court)

| Column                               | Description                                      |
|--------------------------------------|--------------------------------------------------|
| `vfgh_decision_type`                 | Decision type (Beschluss, Erkenntnis, Vergleich) |
| `vfgh_court`                         | Court name                                       |
| `vfgh_indices`                       | Legal index entries (list-column)                |
| `vfgh_collection_number`             | Official collection number (VfSlg)               |
| `vfgh_headnote`                      | Headnote / guiding principle                     |
| `vfgh_decision_texts`                | Linked decision texts (list-column)              |
| `vfgh_decision_text_case_number`     | Case number of linked decision text              |
| `vfgh_decision_text_document_type`   | Document type of linked text                     |
| `vfgh_decision_text_court`           | Court of linked decision text                    |
| `vfgh_decision_text_decision_date`   | Decision date of linked text                     |
| `vfgh_decision_text_document_url`    | URL of linked decision text                      |
| `vfgh_decision_text_document_number` | Document number of linked text                   |
| `vfgh_decision_text_decision_type`   | Decision type of linked text                     |

### BVwG (Federal Administrative Court)

| Column               | Description    |
|----------------------|----------------|
| `bvwg_decision_type` | Decision type  |
| `bvwg_court`         | Court name     |
| `bvwg_note`          | Editorial note |

### LVwG (State Administrative Courts)

| Column                         | Description                           |
|--------------------------------|---------------------------------------|
| `lvwg_decision_type`           | Decision type                         |
| `lvwg_court`                   | Court name                            |
| `lvwg_indices`                 | Legal index entries (list-column)     |
| `lvwg_federal_state`           | Federal state                         |
| `lvwg_note`                    | Editorial note                        |
| `lvwg_legal_principle_numbers` | Legal principle numbers (list-column) |

### Justiz (Ordinary Courts: OGH, OLG, LG, BG)

| Column                               | Description                           |
|--------------------------------------|---------------------------------------|
| `justiz_decision_type`               | Decision type                         |
| `justiz_court`                       | Court name                            |
| `justiz_legal_areas`                 | Legal areas (list-column)             |
| `justiz_specialist_areas`            | Specialist areas (list-column)        |
| `justiz_text_numbers`                | Text numbers (list-column)            |
| `justiz_legal_principle_numbers`     | Legal principle numbers (list-column) |
| `justiz_citation`                    | Citation / reference                  |
| `justiz_note`                        | Editorial note                        |
| `justiz_decision_texts`              | Linked decision texts (list-column)   |
| `justiz_decision_text_case_number`   | Case number of linked text            |
| `justiz_decision_text_document_type` | Document type of linked text          |
| `justiz_decision_text_court`         | Court of linked text                  |
| `justiz_decision_text_decision_type` | Decision type of linked text          |
| `justiz_decision_text_decision_date` | Decision date of linked text          |
| `justiz_decision_text_note`          | Note on linked text                   |
| `justiz_decision_text_document_url`  | URL of linked text                    |

### DSK / DSB (Data Protection Authority)

| Column                         | Description                           |
|--------------------------------|---------------------------------------|
| `dsk_decision_type`            | Decision type                         |
| `dsk_brief_info`               | Brief information / summary           |
| `dsk_deciding_authority`       | Deciding authority                    |
| `dsk_appeal`                   | Appeal status                         |
| `dsk_country`                  | Country                               |
| `dsk_language`                 | Language                              |
| `dsk_access`                   | Access level                          |
| `dsk_decision_on_dsb_document` | Decision on DSB document              |
| `dsk_note`                     | Editorial note                        |
| `dsk_legal_principle_numbers`  | Legal principle numbers (list-column) |

### DOK (Disciplinary Bodies)

| Column                   | Description                 |
|--------------------------|-----------------------------|
| `dok_decision_type`      | Decision type               |
| `dok_brief_info`         | Brief information / summary |
| `dok_deciding_authority` | Deciding authority          |

### GBK (Equal Treatment Commission)

| Column                       | Description                 |
|------------------------------|-----------------------------|
| `gbk_decision_type`          | Decision type               |
| `gbk_commission`             | Commission                  |
| `gbk_senate`                 | Senate                      |
| `gbk_discrimination_ground`  | Discrimination ground       |
| `gbk_discrimination_offense` | Discrimination offense type |
