# risAT 0.0.0.9000

- Initial development version.
- Added `/Judikatur` search and parsing helpers for RIS OGD API v2.6.
- Added `/Bundesrecht` support for consolidated federal law (application
  `BrKons`): `ris_search_federal()`, plus the `ris_req_bundesrecht()` /
  `ris_perform_bundesrecht()` request/perform pair and `ris_parse_bundesrecht()`.
  Supports title, full-text, index, type, law-number, promulgation organ, and
  version filters (point-in-time `version_date` or entry-into-force / expiry
  date ranges), section narrowing, and sorting.
- Updated documentation for finalized behavior:
  - `ris_search_vfgh()` defaults to Rechtssätze (RS).
  - Search functions always iterate over all pages in scope.
  - Result schema includes list-columns `content_urls` and `app_metadata`; pagination context is available in nested `app_metadata$response` and `app_metadata$request` metadata.
  - VfGH english aliases documented for `decision_type`, `sort_by`, and `in_ris_since`.
- Fixed mixed column-type binding across multi-page responses.
- `ris_search_gbk()` now normalizes `commission`, `senate`, and
  `discrimination_ground`, accepting short aliases and English translations
  (e.g. `"federal"`, `"gbk"`, `"gender"`, `"disability"`) alongside the
  canonical German API values.
- `ris_search_lvwg()` now accepts English aliases for `federal_state`
  (e.g. `"Vienna"`, `"Styria"`, `"Carinthia"`) as well as the German
  Bundesland names.
