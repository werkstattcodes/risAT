# risAT 0.0.0.9000

- Initial development version.
- `decision_date` (and `court`/`title` from the general metadata block) are
  now returned as dedicated columns; `decision_date` is parsed to `Date`.
- Requests now identify the package via a `User-Agent` header.
- Fixed pagination errors when the API response lacks `Hits` page metadata
  or serializes `Hits` as a bare scalar count; such responses now stop
  pagination gracefully instead of erroring.
- Added `/Judikatur` search and parsing helpers for RIS OGD API v2.6.
- Added `/Bundesrecht` support for consolidated federal law (application
  `BrKons`): `ris_search_federal()`, plus the `ris_req_federal()` /
  `ris_perform_federal()` request/perform pair and `ris_parse_federal()`.
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
