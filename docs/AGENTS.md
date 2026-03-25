# risAT — R interface to the Austrian RIS (Rechtsinformationssystem)

## 🎯 Project goal

`risAT` is an R package that provides a tidyverse-friendly interface to
the Austrian RIS Open Government Data API (OGD-RIS API v2.6).

The package focuses on: - reproducible research - tidy data structures -
easy access to Austrian legal texts and jurisprudence

The API is documented here: <https://data.bka.gv.at/ris/api/v2.6/>

------------------------------------------------------------------------

## 📦 Design principles

The package follows these principles:

1.  **User-facing API in English**
    - Function names and arguments are English
    - snake_case naming
2.  **Internal mapping to RIS parameters**
    - RIS API parameters are in German
    - The package translates internally
3.  **Tidyverse style**
    - Functions return `tibble`
    - nested data stored as list-columns
    - compatible with dplyr / tidyr / purrr workflows
4.  **Consistency with ParlAT**
    - same philosophy as the ParlAT package
    - predictable naming scheme
    - reproducible data pipelines

------------------------------------------------------------------------

## 🔍 Scope (v0.1)

Initial focus: **Jurisprudence**

Endpoints: - Judikatur / VwGH - Judikatur / VfGH

Functions to implement:

- [`ris_search_vwgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vwgh.md)
- [`ris_search_vfgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vfgh.md)
- [`ris_parse_search()`](https://werkstattcodes.github.io/risAT/reference/ris_parse_search.md)

------------------------------------------------------------------------

## 🌐 API structure

Base URL:

<https://data.bka.gv.at/ris/api/v2.6/>

Jurisprudence endpoint:

/Judikatur

Required parameter:

Applikation = “Vwgh” or “Vfgh”

------------------------------------------------------------------------

## 🧩 Function interface design

### Example: ris_search_vwgh()

User-facing arguments (English):

- query
- case_number
- legal_norm
- decision_date_from
- decision_date_to
- decision_type
- search_in
- page
- per_page

Internal mapping:

| English arg        | RIS parameter         |
|--------------------|-----------------------|
| query              | Suchworte             |
| case_number        | Geschaeftszahl        |
| legal_norm         | Norm                  |
| decision_date_from | EntscheidungsdatumVon |
| decision_date_to   | EntscheidungsdatumBis |
| decision_type      | Entscheidungsart      |
| page               | Seitennummer          |
| per_page           | DokumenteProSeite     |

Search location mapping:

search_in → RIS Dokumenttyp:

- “both”
- “headnotes” → SucheInRechtssaetzen
- “decision_texts” → SucheInEntscheidungstexten

------------------------------------------------------------------------

## 📊 Output format

All search functions return a tibble with:

Core columns:

- id
- application
- court
- decision_date
- case_number
- decision_type
- title
- ris_url

List columns:

- content_urls (tibble with data_type + url)
- app_metadata (nested metadata)

Attributes:

- total_hits
- page_number
- page_size

------------------------------------------------------------------------

## 🧠 Parser behavior

Function:
[`ris_parse_search()`](https://werkstattcodes.github.io/risAT/reference/ris_parse_search.md)

Responsibilities:

- extract OgdSearchResult

- flatten OgdDocumentReference list

- extract metadata from:

  - Metadaten/Technisch
  - Metadaten/Allgemein
  - application-specific metadata

- extract content URLs from: Dokumentliste → ContentReference →
  ContentUrl

- convert to tidy tibble

------------------------------------------------------------------------

## ⚙️ Internal helper functions

The package should include:

- `ris_req()` → build httr2 request
- `ris_perform_json()` → perform request + parse JSON
- `ris_docproseite()` → map numeric page size to RIS enum
- [`ris_parse_search()`](https://werkstattcodes.github.io/risAT/reference/ris_parse_search.md)
  → tidy parser

------------------------------------------------------------------------

## 🧪 Testing

Use:

- `testthat`
- optionally `httptest2` for mocking API calls

Basic tests:

- functions return tibble
- pagination works
- parser returns expected columns

------------------------------------------------------------------------

## 📘 Documentation

Use roxygen2.

Each exported function must include:

- description
- parameters
- return value
- examples

------------------------------------------------------------------------

## 🚀 Future roadmap

Planned extensions:

- Justiz (OGH, LG, BG, …)
- BVwG / LVwG
- Bundesrecht (BrKons)
- BGBl
- History endpoint

Helpers:

- `ris_fetch_html()`
- `ris_fetch_pdf()`
- `ris_pick_content_url()`

------------------------------------------------------------------------

## 🧑‍💻 Coding style

- tidyverse style
- pipe-friendly
- no base R loops where purrr is clearer
- explicit names
- minimal dependencies

------------------------------------------------------------------------

## 🛑 Important constraints

- Respect RIS API rate limits
- avoid large parallel downloads
- follow OGD netiquette

------------------------------------------------------------------------

## 🧭 Guidance for AI agents (Codex)

When modifying this repo:

1.  Preserve function interfaces
2.  Keep English user-facing API
3.  Maintain tidy tibble output
4.  Do not break backward compatibility
5.  Keep parsing logic robust to missing fields
6.  Prefer clarity over cleverness
