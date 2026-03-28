# risAT

<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
<!-- badges: end -->

The risAT package provides a tidyverse-friendly interface to the Austrian
[RIS](https://www.ris.bka.gv.at/) (Rechtsinformationssystem) Open Government
Data REST API v2.6. It covers the `/Judikatur` endpoint (case law /
jurisprudence) across all supported court applications and is designed for
reproducible legal research.

Please note that the package is **in a development stage**. Upcoming changes
may break existing code. If you encounter any bug, you are welcome to file an
issue at the package's
[GitHub repo](https://github.com/werkstattcodes/risAT/issues).

Also note that neither the package nor its author is affiliated with the
Austrian Federal Chancellery (BKA) or the RIS.

## Installation

You can install risAT from [GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("werkstattcodes/risAT")
```

## Available court applications and functions

The RIS Judikatur endpoint covers multiple court applications. risAT provides
convenience wrappers for all of them, plus a generic search function that
accepts any application code:

| Court / Application | Function | Notes |
|---|---|---|
| All Judikatur applications | `ris_search_case_law()` | Generic; accepts any application code |
| VfGH (Constitutional Court) | `ris_search_vfgh()` | Defaults to Rechtssätze |
| VwGH (Administrative Court) | `ris_search_vwgh()` | |
| Justiz (OGH, OLG, LG, BG) | `ris_search_justiz()` | Richest parameter set |
| BVwG (Federal Administrative Court) | `ris_search_bvwg()` | Since 2014 |
| LVwG (9 state administrative courts) | `ris_search_lvwg()` | Use `federal_state` to narrow |
| DSK / DSB / PDK (data protection) | `ris_search_dsk()` | |
| BDB / DK / DOK / BK (disciplinary) | `ris_search_dok()` | |
| PVAK / PVAB (staff representation) | `ris_search_pvak()` | |
| GBK (equal treatment commissions) | `ris_search_gbk()` | No doc-type flags |

Lower-level building blocks for advanced use:

| Step | Function |
|---|---|
| Build request | `ris_req_case_law()` |
| Execute request (with pagination) | `ris_perform_case_law()` |
| Parse response | `ris_parse_search()` |

## Minimal example

``` r
library(risAT)

# Convenience wrapper: Administrative Court (VwGH)
results_vwgh <- ris_search_vwgh(query = "Baurecht")

# Convenience wrapper: Constitutional Court (VfGH)
# Defaults to Rechtssätze (RS). Set `search_decision_text = TRUE`
# to include Entscheidungstexte (TE).
results_vfgh <- ris_search_vfgh(query = "Grundrecht")

# Convenience wrapper: Federal Administrative Court (BVwG)
results_bvwg <- ris_search_bvwg(
  query = "Asyl",
  decision_type = "Erkenntnis",
  decision_date_from = "2023-01-01"
)

# Ordinary courts: OGH and below
results_ogh <- ris_search_justiz(
  query = "Schadenersatz",
  court = "OGH"
)

# Generic search across all Judikatur applications
results_all <- ris_search_case_law(
  application = "data_protection",
  query = "Videoüberwachung"
)
```

## Output

Search functions automatically iterate through all RIS pages and return results
as a tidy tibble with columns including `id`, `court`, `decision_date`,
`case_number`, `content_urls` (list-column), and `app_metadata` (list-column).
See the [reference documentation](https://werkstattcodes.github.io/risAT/reference/)
for full details.

## Column name reference

The RIS API returns metadata in German. risAT converts these to snake_case
column names. The table below documents all observed columns and their planned
English translations, grouped by scope.

### Common columns

These columns appear across most or all court applications.

| Current column name | Planned English name | German source field | Description |
|---|---|---|---|
| `technisch_id` | `id` | `Technisch > ID` | Unique RIS document identifier |
| `technisch_applikation` | `application` | `Technisch > Applikation` | RIS application code (e.g. `"Vwgh"`, `"Justiz"`) |
| `technisch_organ` | `authority` | `Technisch > Organ` | Issuing authority / court name |
| `technisch_import_timestamp_xsi_nil` | — (drop) | `Technisch > ImportTimestamp` | XML nil flag (serialization artifact) |
| `technisch_import_timestamp_xmlns_xsi` | — (drop) | `Technisch > ImportTimestamp` | XML namespace (serialization artifact) |
| `allgemein_veroeffentlicht` | `published` | `Allgemein > Veroeffentlicht` | Publication date |
| `allgemein_geaendert` | `modified` | `Allgemein > Geaendert` | Last modification date |
| `allgemein_dokument_url` | `document_url` | `Allgemein > DokumentUrl` | RIS web page URL for the document |
| `judikatur_dokumenttyp` | `document_type` | `Dokumenttyp` | Document type (`"Rechtssatz"`, `"Entscheidungstext"`, etc.) |
| `judikatur_geschaeftszahl_item` | `case_number` | `Geschaeftszahl` | Business / case number (Geschäftszahl) |
| `judikatur_normen_item` | `norms` | `Normen` | Referenced legal norms (list-column) |
| `judikatur_entscheidungsdatum` | `decision_date` | `Entscheidungsdatum` | Decision date |
| `judikatur_schlagworte` | `keywords` | `Schlagworte` | Keywords / index terms |
| `judikatur_european_case_law_identifier` | `ecli` | `EuropeanCaseLawIdentifier` | ECLI identifier |
| `judikatur_gesamte_entscheidung_url` | `full_decision_url` | `GesamteEntscheidungUrl` | URL to the full decision page |
| `judikatur_rechtssaetze_url` | `legal_principles_url` | `RechtssaetzeUrl` | URL to the legal principles page |
| `judikatur_entscheidungstext_url` | `decision_text_url` | `EntscheidungstextUrl` | URL to the decision text |
| `content_urls` | `content_urls` | `Dokumentliste > ContentReference` | Content download URLs (list-column) |
| `app_metadata` | `app_metadata` | — | Package-generated metadata (list-column) |

### VwGH (Administrative Court)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_vwgh_entscheidungsart` | `vwgh_decision_type` | Decision type (Beschluss, Erkenntnis, etc.) |
| `judikatur_vwgh_gericht` | `vwgh_court` | Court name |
| `judikatur_vwgh_indizes_item` | `vwgh_indices` | Legal index entries (list-column) |
| `judikatur_vwgh_sammlungsnummer` | `vwgh_collection_number` | Official collection number (VwSlg) |
| `judikatur_vwgh_dokumentnummer_typ` | `vwgh_document_number_type` | Document number type code |
| `judikatur_vwgh_stammrechtssatznummer` | `vwgh_primary_legal_principle_number` | Primary legal principle number |
| `judikatur_vwgh_rechtssatznummer` | `vwgh_legal_principle_number` | Legal principle number |
| `judikatur_vwgh_hinweis_auf_stammrechtssatz` | `vwgh_primary_principle_reference` | Reference to the primary legal principle |
| `judikatur_vwgh_rechtssatzkette_url` | `vwgh_legal_principle_chain_url` | URL to the legal principle chain |
| `judikatur_vwgh_beachte` | `vwgh_note` | Editorial notes (Beachte) |
| `judikatur_vwgh_gerichtsentscheidungen_item` | `vwgh_court_decisions` | Related court decisions (list-column) |

### VfGH (Constitutional Court)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_vfgh_entscheidungsart` | `vfgh_decision_type` | Decision type (Beschluss, Erkenntnis, Vergleich) |
| `judikatur_vfgh_gericht` | `vfgh_court` | Court name |
| `judikatur_vfgh_indizes_item` | `vfgh_indices` | Legal index entries (list-column) |
| `judikatur_vfgh_sammlungsnummer` | `vfgh_collection_number` | Official collection number (VfSlg) |
| `judikatur_vfgh_leitsatz` | `vfgh_headnote` | Headnote / guiding principle |
| `judikatur_vfgh_entscheidungstexte_item` | `vfgh_decision_texts` | Linked decision texts (list-column) |
| `judikatur_vfgh_entscheidungstexte_item_geschaeftszahl` | `vfgh_decision_text_case_number` | Case number of linked decision text |
| `judikatur_vfgh_entscheidungstexte_item_dokumenttyp` | `vfgh_decision_text_document_type` | Document type of linked text |
| `judikatur_vfgh_entscheidungstexte_item_gericht` | `vfgh_decision_text_court` | Court of linked decision text |
| `judikatur_vfgh_entscheidungstexte_item_entscheidungsdatum` | `vfgh_decision_text_decision_date` | Decision date of linked text |
| `judikatur_vfgh_entscheidungstexte_item_dokument_url` | `vfgh_decision_text_document_url` | URL of linked decision text |
| `judikatur_vfgh_entscheidungstexte_item_dokumentnummer` | `vfgh_decision_text_document_number` | Document number of linked text |
| `judikatur_vfgh_entscheidungstexte_item_entscheidungsart` | `vfgh_decision_text_decision_type` | Decision type of linked text |

### BVwG (Federal Administrative Court)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_bvwg_entscheidungsart` | `bvwg_decision_type` | Decision type |
| `judikatur_bvwg_gericht` | `bvwg_court` | Court name |
| `judikatur_bvwg_anmerkung` | `bvwg_note` | Editorial note |

### LVwG (State Administrative Courts)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_lvwg_entscheidungsart` | `lvwg_decision_type` | Decision type |
| `judikatur_lvwg_gericht` | `lvwg_court` | Court name |
| `judikatur_lvwg_indizes_item` | `lvwg_indices` | Legal index entries (list-column) |
| `judikatur_lvwg_bundesland` | `lvwg_federal_state` | Federal state |
| `judikatur_lvwg_anmerkung` | `lvwg_note` | Editorial note |
| `judikatur_lvwg_rechtssatznummern_item` | `lvwg_legal_principle_numbers` | Legal principle numbers (list-column) |

### Justiz (Ordinary Courts: OGH, OLG, LG, BG)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_justiz_entscheidungsart` | `justiz_decision_type` | Decision type |
| `judikatur_justiz_gericht` | `justiz_court` | Court name |
| `judikatur_justiz_rechtsgebiete_item` | `justiz_legal_areas` | Legal areas (list-column) |
| `judikatur_justiz_fachgebiete_item` | `justiz_specialist_areas` | Specialist areas (list-column) |
| `judikatur_justiz_textnummern_item` | `justiz_text_numbers` | Text numbers (list-column) |
| `judikatur_justiz_rechtssatznummern_item` | `justiz_legal_principle_numbers` | Legal principle numbers (list-column) |
| `judikatur_justiz_fundstelle` | `justiz_citation` | Citation / reference |
| `judikatur_justiz_anmerkung` | `justiz_note` | Editorial note |
| `judikatur_justiz_entscheidungstexte_item` | `justiz_decision_texts` | Linked decision texts (list-column) |
| `judikatur_justiz_entscheidungstexte_item_geschaeftszahl` | `justiz_decision_text_case_number` | Case number of linked text |
| `judikatur_justiz_entscheidungstexte_item_dokumenttyp` | `justiz_decision_text_document_type` | Document type of linked text |
| `judikatur_justiz_entscheidungstexte_item_gericht` | `justiz_decision_text_court` | Court of linked text |
| `judikatur_justiz_entscheidungstexte_item_entscheidungsart` | `justiz_decision_text_decision_type` | Decision type of linked text |
| `judikatur_justiz_entscheidungstexte_item_entscheidungsdatum` | `justiz_decision_text_decision_date` | Decision date of linked text |
| `judikatur_justiz_entscheidungstexte_item_anmerkung` | `justiz_decision_text_note` | Note on linked text |
| `judikatur_justiz_entscheidungstexte_item_dokument_url` | `justiz_decision_text_document_url` | URL of linked text |

### DSK / DSB (Data Protection Authority)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_dsk_entscheidungsart` | `dsk_decision_type` | Decision type |
| `judikatur_dsk_kurzinformation` | `dsk_brief_info` | Brief information / summary |
| `judikatur_dsk_entscheidende_behoerde` | `dsk_deciding_authority` | Deciding authority |
| `judikatur_dsk_anfechtung` | `dsk_appeal` | Appeal status |
| `judikatur_dsk_staat` | `dsk_country` | Country |
| `judikatur_dsk_sprache` | `dsk_language` | Language |
| `judikatur_dsk_zugang` | `dsk_access` | Access level |
| `judikatur_dsk_entscheidung_ueber_dsb_dokument` | `dsk_decision_on_dsb_document` | Decision on DSB document |
| `judikatur_dsk_anmerkung` | `dsk_note` | Editorial note |
| `judikatur_dsk_rechtssatznummern_item` | `dsk_legal_principle_numbers` | Legal principle numbers (list-column) |

### DOK (Disciplinary Bodies)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_dok_entscheidungsart` | `dok_decision_type` | Decision type |
| `judikatur_dok_kurzinformation` | `dok_brief_info` | Brief information / summary |
| `judikatur_dok_entscheidende_behoerde` | `dok_deciding_authority` | Deciding authority |

### GBK (Equal Treatment Commission)

| Current column name | Planned English name | Description |
|---|---|---|
| `judikatur_gbk_entscheidungsart` | `gbk_decision_type` | Decision type |
| `judikatur_gbk_kommission` | `gbk_commission` | Commission |
| `judikatur_gbk_senat` | `gbk_senate` | Senate |
| `judikatur_gbk_diskriminierungsgrund` | `gbk_discrimination_ground` | Discrimination ground |
| `judikatur_gbk_diskriminierungstatbestand` | `gbk_discrimination_offense` | Discrimination offense type |
