# risAT 0.0.0.9000

- Initial development version.
- The full-text `query` and `norm` arguments now accept `OR` and `ODER` as
  the OR operator; they are translated client-side to the RIS-native
  full-text operator. Text inside single-quoted exact phrases is left
  untouched.
- Fixed API schema-validation errors for the GBK filters: `senate`, the
  federal `commission`, and the multi-word `discrimination_ground` values
  ("Ethnische Zugehörigkeit", "Sexuelle Orientierung") were sent in their
  RIS-website display form; they are now mapped to the OGD API enum values
  (`I`/`II`/`III`, `BundesGleichbehandlungskommission`,
  `EthnischeZugehoerigkeit`, `SexuelleOrientierung`). Accepted user inputs
  are unchanged, and the API enum spellings are now accepted as input too.
- All requests are now throttled client-side (30 requests per minute) as a
  courtesy to the public RIS OGD API.
- All search and perform functions always fetch every page in scope; there is
  no `max_pages` argument to cap or truncate a result set.
- `ris_req_case_law()` and `ris_search_case_law()` gained `sort_by` and
  `sort_direction` arguments (previously hard-coded to date descending, which
  remains the default).
- New `ris_base_url()` helper is the single source of the API base URL; it
  can be overridden per session via `options(risAT.base_url = ...)`.
- New accessors `ris_search_url()` and `ris_app_url()` retrieve the RIS
  website URLs attached to search results.
- Bundesrecht requests now send the same package-identifying `User-Agent`
  header as Judikatur requests.
- Empty search results now return a zero-row tibble with the guaranteed
  common columns (`id`, `application`, `content_urls`),
  matching the schema of non-empty results.
- `ris_parse_federal()` parses `effective_date` and `expiry_date` to `Date`
  and guards against duplicate column names after translation.
- Validation errors now carry condition classes (`risat_invalid_argument`,
  `risat_api_error`, `risat_truncated_results`) so they can be caught with
  `tryCatch()`.
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
  - Result schema includes the `content_urls` list-column; internal `app_metadata` is not returned by exported functions.
  - VfGH english aliases documented for `decision_type`, `sort_by`, and `in_ris_since`.
- Fixed mixed column-type binding across multi-page responses.
- `ris_search_gbk()` now normalizes `commission`, `senate`, and
  `discrimination_ground`, accepting short aliases and English translations
  (e.g. `"federal"`, `"gbk"`, `"gender"`, `"disability"`) alongside the
  canonical German API values.
- `ris_search_lvwg()` now accepts English aliases for `federal_state`
  (e.g. `"Vienna"`, `"Styria"`, `"Carinthia"`) as well as the German
  Bundesland names.
