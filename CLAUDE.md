# CLAUDE.md

This file provides guidance for AI coding assistants working in this repository.

---

## Project overview

`risAT` is an R package that provides a tidyverse-friendly interface to the Austrian RIS (Rechtsinformationssystem) Open Government Data REST API v2.6. It covers the `/Judikatur` endpoint (case law / jurisprudence, all 9 court applications) and the `/Bundesrecht` endpoint (consolidated federal law, `BrKons`), and is designed for reproducible legal research.

- **Language**: R
- **Package version**: 0.0.1
- **License**: MIT
- **API base URL**: `https://data.bka.gv.at/ris/api/v2.6/`

---

## Repository structure

```
R/                          # Source code
  risAT-package.R           # Package-level documentation
  ris_request_utils.R       # Endpoint-agnostic helpers: base URL, request skeleton
                            #   (user agent, retry, throttle), empty-result constructor,
                            #   date parsing, website-URL accessors
  ris_case_law_utils.R      # Internal utility helpers (validation, mapping, pagination)
  ris_parse_search.R        # Response parser → tidy tibble
  ris_perform_case_law.R    # Execute httr2 requests with pagination
  ris_req_case_law.R        # Build httr2 request objects
  ris_search_case_law.R     # Generic search wrapper (all applications)
  ris_search_<court>.R      # 9 court convenience wrappers: vfgh, vwgh, justiz,
                            #   bvwg, lvwg, dsk, dok, pvak, gbk
  ris_federal_utils.R       # Internal helpers for the Bundesrecht endpoint
  ris_req_federal.R         # Build httr2 request (BrKons / consolidated federal law)
  ris_perform_federal.R     # Execute Bundesrecht request with pagination
  ris_parse_federal.R       # Parse Bundesrecht response → tidy tibble
  ris_search_federal.R      # Bundesrecht (federal law) search wrapper
man/                        # Auto-generated roxygen2 documentation (do not edit)
vignettes/                  # Package vignettes (risAT.Rmd)
tests/testthat/             # testthat unit tests
  fixtures/                 # JSON API response fixtures (no live calls in tests)
  test-ris_parse_search.R
  test-ris_search_validation.R
  test-ris_request_utils.R
  test-ris_case_law_fixtures.R
  test-ris_federal_params.R
  test-ris_parse_federal.R
background_docs/            # Reference PDFs and architecture notes (not shipped)
  architecture.md           # Component architecture with Mermaid diagram
  pkg-hardening-changes.md  # Rationale for the pkg-hardening changes
pkgdown/                    # Custom pkgdown website assets
.github/workflows/          # GitHub Actions CI/CD
  pkgdown.yaml              # Builds and deploys pkgdown site to gh-pages
  R-CMD-check.yaml          # R CMD check on push/PR
  test-coverage.yaml        # covr test coverage, uploaded to Codecov
  pkgcheck.yaml             # rOpenSci pkgcheck
DESCRIPTION                 # Package metadata and dependencies
NAMESPACE                   # Exported functions (managed by roxygen2)
_pkgdown.yml                # pkgdown website configuration
NEWS.md                     # Changelog
```

---

## Common commands

All development tasks are run from within R. Run these in an R session or via `Rscript -e`:

### Testing
```r
# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-ris_parse_search.R")
```

### Documentation
```r
# Regenerate man/ pages and NAMESPACE from roxygen2 comments
devtools::document()
```

### Package check
```r
# Full R CMD check (build + test + documentation check)
devtools::check()
```

### Build pkgdown website
```r
# Build full pkgdown site into docs/
pkgdown::build_site()
```

### Load package for interactive development
```r
devtools::load_all()
```

---

## Architecture

The package uses a **two-step request pattern** inspired by `httr2`:

1. **Build** – Construct an `httr2` request object (`ris_req_case_law()`)
2. **Perform** – Execute the request with automatic pagination (`ris_perform_case_law()`)

This separation allows users to inspect the request before hitting the network and facilitates testing without live API calls.

### Call chain

```
ris_search_vfgh()        }
ris_search_vwgh()        }  9 court-specific wrappers with validated, typed args
ris_search_justiz() ...  }  (vfgh, vwgh, justiz, bvwg, lvwg, dsk, dok, pvak, gbk)
    ↓ calls
ris_search_case_law()       Generic search: normalises args, calls req + perform + parse

    ↓ calls
ris_req_case_law()          Builds httr2 request (URL, query params, headers)
ris_perform_case_law()      Executes request, paginates via httr2::req_perform_iterative()
ris_parse_search()          Parses JSON response list → flat tidy tibble
```

### Shared request infrastructure (`ris_request_utils.R`)

Endpoint-agnostic helpers used by both the Judikatur and Bundesrecht sides:

- `ris_base_url()` (exported) — single source of truth for the API base URL;
  overridable per session via `options(risAT.base_url = ...)`
- `ris_base_request()` — request skeleton applied to every RIS request:
  package-identifying User-Agent, `req_retry(max_tries = 3)`, and client-side
  throttling via `req_throttle(capacity = 30, fill_time_s = 60)` (30 requests
  per minute shared across the session)
- `ris_empty_result()` — type-stable zero-row result tibble
- `ris_parse_date_columns()` — coerce known date columns to `Date`
- `ris_app_url()` / `ris_search_url()` (exported) — accessors for the RIS
  website URL attributes on result tibbles

Note: `sort_by` / `sort_direction` are arguments on `ris_search_case_law()`
and `ris_req_case_law()` but deliberately not on the court wrappers — use the
generic function when custom sorting is needed.

### Internal utilities (`ris_case_law_utils.R`)

- Input validation via `checkmate`
- English → German parameter mapping (e.g. `"administrative_court"` → `"Vwgh"`)
- Page size enum mapping (`ris_docproseite()`)
- Pagination helpers

---

## Design principles

1. **English user-facing API** — all function names, argument names, and accepted string values are English. German RIS parameter names are mapped internally.

2. **Tidyverse style** — functions return `tibble`, nested data as list-columns, compatible with dplyr/tidyr/purrr workflows.

3. **Normalize early** — validate and translate all inputs at the top of the call stack; pass canonical values downstream.

4. **Preserve function interfaces** — do not change exported function signatures or argument names without strong justification and version bump.

5. **Robust parsing** — the parser must handle missing or `NULL` fields gracefully; never assume all API response fields are present.

6. **Minimal dependencies** — only add packages to `Imports` when genuinely necessary. Current core deps: `checkmate`, `dplyr`, `httr2 (>= 1.1.0)`, `purrr`, `rlang`, `stats`, `stringr`, `tibble`, `utils`.

7. **Consistency with ParlAT** — naming, structure, and output format should match the ParlAT package conventions.

---

## Output schema

All search functions return a `tibble`. The exact column set varies by
application and by which metadata fields the API returns; common columns
include:

| Column | Type | Description |
|---|---|---|
| `id` | character | Unique document ID |
| `application` | character | RIS application (e.g. `"Vwgh"`) |
| `court` | character | Court name |
| `decision_date` | Date | Date of the decision |
| `case_number` | character | Geschäftszahl |
| `title` | character | Document title |
| `document_url` | character | Link to the RIS web page of the document |
| `published` / `modified` | character | RIS publication/modification dates |
| `content_urls` | list-column | Character vector of download URLs (XML, HTML, RTF, PDF) |

Every result — including an empty one — is guaranteed to contain `id`,
`application`, and `content_urls` with correct types (see
`ris_empty_result()`).

Application-specific fields are prefixed with the application name (e.g.
`vwgh_decision_type`, `gbk_senate`). German metadata fields without an
English mapping are kept as snake_case German names. Bundesrecht results
type `effective_date` / `expiry_date` as `Date`; `published` / `modified`
deliberately stay character.

Result tibbles carry attributes: `ris_app_url`, `ris_search_url` (the
equivalent RIS website URLs), readable via the exported accessors
`ris_app_url(res)` / `ris_search_url(res)`. These must be called on the
unmodified result — most dplyr verbs drop attributes.

---

## Coding style

- Follow [tidyverse style guide](https://style.tidyverse.org/)
- Use `snake_case` for all names
- Prefer `purrr` functional style over base R loops where it improves clarity
- Use the pipe `|>` (native R pipe) or `%>%` consistently with the existing file
- Use `rlang::abort()` / `rlang::warn()` for errors and warnings (not `stop()` / `warning()`)
- All errors and messages raised by the package carry condition classes, set via `class =` on `rlang::abort()` etc.: `risat_invalid_argument` (input validation), `risat_api_error` (errors from RIS API error payloads), `risat_ignored_argument` (warning when provided arguments are ignored for the selected application). New conditions should follow this pattern so callers can handle them structurally with `tryCatch()`.
- Use `checkmate` assertions for input validation at function entry points
- Write descriptive, explicit variable names — avoid abbreviations unless widely established
- Keep functions focused on a single responsibility

---

## Documentation

All exported functions must have complete roxygen2 documentation:

```r
#' @title Short title
#' @description One-paragraph description.
#' @param arg_name Description of the argument.
#' @return Description of the return value.
#' @examples
#' \dontrun{
#'   ris_search_vwgh(query = "Baurecht")
#' }
#' @export
```

- Markdown is enabled (`Roxygen: list(markdown = TRUE)` in DESCRIPTION)
- After editing roxygen2 comments, run `devtools::document()` to regenerate `man/` and `NAMESPACE`
- Never edit `.Rd` files or `NAMESPACE` by hand

---

## Testing

- Framework: `testthat` edition 3
- Test files live in `tests/testthat/` with the prefix `test-`
- Tests should not make live API calls — mock responses or use fixtures where needed
- Minimum test coverage expectations:
  - All exported functions have at least one test
  - Parser handles missing/NULL fields without error
  - Validation rejects invalid arguments with a clear error message

---

## API constraints

- **Respect rate limits** — the RIS OGD API is a public service; every request goes through `ris_base_request()`, which applies client-side throttling (30 requests/minute, i.e. ~2s/request) and retries — do not bypass it or add parallel/rapid sequential requests. This matches the officially documented pacing: the RIS OGD FAQ (`background_docs/ris-ogd-faq.pdf`, "Technische Rahmenbedingungen") asks clients to insert "kurze Pausen von etwa 1–2 Sekunden" between paginated page fetches — sequential, not parallel. There is no documented allowance for concurrent requests, so `httr2::req_perform_parallel()` is not an option here even though the throttle bucket would still cap it (see `background_docs/ris-ogd-faq.pdf` before ever proposing to loosen or parallelize this).
- **OGD netiquette** — follow the terms of the RIS OGD API; do not attempt to bulk-download the entire database. The FAQ also asks that large/bulk fetches happen outside business hours (18:00–06:00) or on weekends, and that a genuine bulk-download need be announced in advance to `ris.it@bka.gv.at` so it isn't mistaken for a DDoS attack — flag this to the user rather than acting on it, since it requires contacting a third party.
- **Pagination** — the package handles multi-page results automatically via `httr2::req_perform_iterative()`; all search/perform functions always fetch every page in scope, with no user-facing cap. Narrow searches (e.g. with date ranges or specific filters) during development and testing to keep the number of requests small. Slowness on broad full-text queries (e.g. `search_decision_text`/`search_legal_principles` over a wide date range) is expected — it comes from the mandated per-page pacing across many pages, not a client bug; narrowing the query is the way to speed it up.

---

## CI/CD

Four GitHub Actions workflows live in `.github/workflows/`:

- **`pkgdown.yaml`** — runs on push to `main`/`master`, on PRs, and on published releases; installs R and Pandoc, installs package dependencies, builds the pkgdown site, and deploys it to the `gh-pages` branch under `docs/`
- **`R-CMD-check.yaml`** — runs `R CMD check` on pushes and PRs
- **`test-coverage.yaml`** — computes test coverage with covr and uploads to Codecov (needs the `CODECOV_TOKEN` repository secret for the upload)
- **`pkgcheck.yaml`** — runs rOpenSci `pkgcheck` on pushes to `main`

The `background_docs/` directory and `AGENTS.md` are excluded from the built package (see `.Rbuildignore`).

---

## Commit and pull request guidelines

- Do not include any references to Claude, Anthropic, or AI authorship in commit messages, pull request titles, descriptions, or comments. All contributions should appear as standard human-authored work.
- Write commit messages in the imperative mood (e.g. `Add pagination support for Vwgh`, not `Added` or `Adding`)
- Keep the subject line under 72 characters
- Reference issue numbers where relevant (e.g. `Fix date parsing (#12)`)
- Each commit should represent a single logical change
- Do not commit generated files (`man/`, `docs/`) unless specifically required

---

## Implemented endpoints

- **Judikatur** (`/Judikatur`): all 9 court applications are supported with
  convenience wrappers: VfGH, VwGH, Justiz (OGH, OLG, LG, BG), BVwG, LVwG,
  DSK/DSB, DOK, PVAK, GBK.
- **Bundesrecht** (`/Bundesrecht`, application `BrKons`): consolidated federal
  law via `ris_search_federal()` (and the `ris_req_federal()` /
  `ris_perform_federal()` / `ris_parse_federal()` building blocks).
  Bundesrecht reuses the generic response-envelope walkers and pagination
  helpers from the Judikatur side (the envelope shape is identical); only the
  request parameters, column-name map, and per-page parser differ.

## Future roadmap (planned)

- Bundesgesetzblatt (`BGBl`) and the other `/Bundesrecht` applications
  (BgblAuth, BgblPdf, BgblAlt, Begut, RegV, Erv)
- Landesrecht endpoint (`LrKons`, `LgblAuth`)
- Sonstige Kundmachungen endpoint (`/Sonstige`) — includes UPTS (Unabhängiger Parteien-Transparenz-Senat), which appears on the RIS Judikatur overview page but uses the `/Sonstige` API endpoint, not `/Judikatur`
- Content helpers: `ris_fetch_html()`, `ris_fetch_pdf()`, `ris_pick_content_url()`
