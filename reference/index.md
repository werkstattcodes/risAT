# Package index

## Search Functions — Generic

Search across all Judikatur applications with a single function.

- [`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
  : Search Austrian Case Law in RIS

## Search Functions — Court Wrappers

Convenience wrappers pre-filled with a specific application code.

- [`ris_search_vfgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vfgh.md)
  : Search VfGH Decisions in RIS
- [`ris_search_vwgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vwgh.md)
  : Search VwGH Decisions in RIS
- [`ris_search_justiz()`](https://werkstattcodes.github.io/risAT/reference/ris_search_justiz.md)
  : Search Justiz Decisions in RIS
- [`ris_search_bvwg()`](https://werkstattcodes.github.io/risAT/reference/ris_search_bvwg.md)
  : Search BVwG Decisions in RIS
- [`ris_search_lvwg()`](https://werkstattcodes.github.io/risAT/reference/ris_search_lvwg.md)
  : Search LVwG Decisions in RIS
- [`ris_search_dsk()`](https://werkstattcodes.github.io/risAT/reference/ris_search_dsk.md)
  : Search Data Protection Authority Decisions in RIS
- [`ris_search_dok()`](https://werkstattcodes.github.io/risAT/reference/ris_search_dok.md)
  : Search Disciplinary Body Decisions in RIS
- [`ris_search_pvak()`](https://werkstattcodes.github.io/risAT/reference/ris_search_pvak.md)
  : Search Staff Representation Oversight Decisions in RIS
- [`ris_search_gbk()`](https://werkstattcodes.github.io/risAT/reference/ris_search_gbk.md)
  : Search Equal Treatment Commission Decisions in RIS

## Search Functions — Bundesrecht

Search consolidated federal law (Bundesrecht in konsolidierter Fassung,
BrKons).

- [`ris_search_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_search_federal.md)
  : Search Austrian Consolidated Federal Law in RIS

## Request Building

- [`ris_req_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_req_case_law.md)
  : Build a RIS Case Law API Request
- [`ris_perform_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_perform_case_law.md)
  : Perform a RIS Case Law Search
- [`ris_req_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_req_federal.md)
  : Build a RIS Bundesrecht API Request
- [`ris_perform_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_perform_federal.md)
  : Perform a RIS Bundesrecht Search

## Parsers

- [`ris_parse_search()`](https://werkstattcodes.github.io/risAT/reference/ris_parse_search.md)
  : Parse RIS Search Responses
- [`ris_parse_federal()`](https://werkstattcodes.github.io/risAT/reference/ris_parse_federal.md)
  : Parse RIS Bundesrecht Search Responses

## Utilities

API base URL and RIS website URL accessors.

- [`ris_base_url()`](https://werkstattcodes.github.io/risAT/reference/ris_base_url.md)
  : RIS API Base URL
- [`ris_search_url()`](https://werkstattcodes.github.io/risAT/reference/ris_search_url.md)
  [`ris_app_url()`](https://werkstattcodes.github.io/risAT/reference/ris_search_url.md)
  : Get the RIS Website URLs of a Search Result
