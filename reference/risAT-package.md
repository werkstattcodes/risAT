# risAT: Interface to the Austrian RIS OGD REST API

Search helpers for Austrian legal information from the
Rechtsinformationssystem (RIS) Open Government Data REST API v2.6.

## Details

risAT uses a two-step request pattern:

1.  **Build** a request with
    [`ris_req_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_req_case_law.md)

2.  **Perform** it with
    [`ris_perform_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_perform_case_law.md)

Convenience wrappers like
[`ris_search_vwgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vwgh.md)
and
[`ris_search_vfgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vfgh.md)
combine both steps for common court applications.

## See also

- [`ris_search_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_search_case_law.md)
  – generic search across all applications

- [`ris_search_vwgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vwgh.md),
  [`ris_search_vfgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vfgh.md),
  [`ris_search_justiz()`](https://werkstattcodes.github.io/risAT/reference/ris_search_justiz.md)
  – court-specific wrappers

- [`ris_parse_search()`](https://werkstattcodes.github.io/risAT/reference/ris_parse_search.md)
  – response parser

- Online documentation: <https://werkstattcodes.github.io/risAT>

## Author

**Maintainer**: Roland Schmidt <rs2903@gmail.com>
