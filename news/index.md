# Changelog

## risAT 0.0.0.9000

- Initial development version.
- Added `/Judikatur` search and parsing helpers for RIS OGD API v2.6.
- Updated documentation for finalized behavior:
  - [`ris_search_vfgh()`](https://werkstattcodes.github.io/risAT/reference/ris_search_vfgh.md)
    defaults to Rechtssätze (RS).
  - Search functions always iterate over all pages in scope.
  - Result schema includes list-columns `content_urls` and
    `app_metadata`; pagination context is available in nested
    `app_metadata$response` and `app_metadata$request` metadata.
  - VfGH english aliases documented for `decision_type`, `sort_by`, and
    `in_ris_since`.
- Fixed mixed column-type binding across multi-page responses.
