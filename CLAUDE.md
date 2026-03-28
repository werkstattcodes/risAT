# CLAUDE.md

This file provides guidance for AI coding assistants working in this
repository.

------------------------------------------------------------------------

## Project overview

`risAT` is an R package that provides a tidyverse-friendly interface to
the Austrian RIS (Rechtsinformationssystem) Open Government Data REST
API v2.6. It focuses on the `/Judikatur` endpoint (case law /
jurisprudence) and is designed for reproducible legal research.

- **Language**: R
- **Package version**: 0.0.0.9000 (development)
- **License**: MIT
- **API base URL**: `https://data.bka.gv.at/ris/api/v2.6/`

------------------------------------------------------------------------

## Repository structure

    R/                          # Source code
      ris_case_law_utils.R      # Internal utility helpers (validation, mapping, pagination)
      ris_parse_search.R        # Response parser → tidy tibble
      ris_perform_case_law.R    # Execute httr2 requests with pagination
      ris_req_case_law.R        # Build httr2 request objects
      ris_search_case_law.R     # Generic search wrapper (all applications)
      ris_search_vfgh.R         # VfGH court convenience wrapper
      ris_search_vwgh.R         # VwGH court convenience wrapper
    man/                        # Auto-generated roxygen2 documentation (do not edit)
    tests/testthat/             # testthat unit tests
      test-ris_parse_search.R
      test-ris_search_validation.R
    background_docs/            # Reference PDFs and architecture notes (not shipped)
      architecture.md           # Component architecture with Mermaid diagram
    pkgdown/                    # Custom pkgdown website assets
    .github/workflows/          # GitHub Actions CI/CD
      pkgdown.yaml              # Builds and deploys pkgdown site to gh-pages
    DESCRIPTION                 # Package metadata and dependencies
    NAMESPACE                   # Exported functions (managed by roxygen2)
    _pkgdown.yml                # pkgdown website configuration
    NEWS.md                     # Changelog

------------------------------------------------------------------------

## Common commands

All development tasks are run from within R. Run these in an R session
or via `Rscript -e`:

### Testing

``` r
# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-ris_parse_search.R")
```

### Documentation

``` r
# Regenerate man/ pages and NAMESPACE from roxygen2 comments
devtools::document()
```

### Package check

``` r
# Full R CMD check (build + test + documentation check)
devtools::check()
```

### Build pkgdown website

``` r
# Build full pkgdown site into docs/
pkgdown::build_site()
```

### Load package for interactive development

``` r
devtools::load_all()
```

------------------------------------------------------------------------

## Architecture

The package uses a **two-step request pattern** inspired by `httr2`:

1.  **Build** – Construct an `httr2` request object
    ([`ris_req_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_req_case_law.md))
2.  **Perform** – Execute the request with automatic pagination
    ([`ris_perform_case_law()`](https://werkstattcodes.github.io/risAT/reference/ris_perform_case_law.md))

This separation allows users to inspect the request before hitting the
network and facilitates testing without live API calls.

### Call chain

    ris_search_vwgh()        }
    ris_search_vfgh()        }  Court-specific wrappers with validated, typed args
                             }
        ↓ calls
    ris_search_case_law()       Generic search: normalises args, calls req + perform + parse

        ↓ calls
    ris_req_case_law()          Builds httr2 request (URL, query params, headers)
    ris_perform_case_law()      Executes request, paginates via httr2::req_perform_iterative()
    ris_parse_search()          Parses JSON response list → flat tidy tibble

### Internal utilities (`ris_case_law_utils.R`)

- Input validation via `checkmate`
- English → German parameter mapping (e.g. `"administrative_court"` →
  `"Vwgh"`)
- Page size enum mapping (`ris_docproseite()`)
- Pagination helpers

------------------------------------------------------------------------

## Design principles

1.  **English user-facing API** — all function names, argument names,
    and accepted string values are English. German RIS parameter names
    are mapped internally.

2.  **Tidyverse style** — functions return `tibble`, nested data as
    list-columns, compatible with dplyr/tidyr/purrr workflows.

3.  **Normalize early** — validate and translate all inputs at the top
    of the call stack; pass canonical values downstream.

4.  **Preserve function interfaces** — do not change exported function
    signatures or argument names without strong justification and
    version bump.

5.  **Robust parsing** — the parser must handle missing or `NULL` fields
    gracefully; never assume all API response fields are present.

6.  **Minimal dependencies** — only add packages to `Imports` when
    genuinely necessary. Current core deps: `checkmate`, `dplyr`,
    `httr2`, `purrr`, `rlang`, `stringr`, `tibble`.

7.  **Consistency with ParlAT** — naming, structure, and output format
    should match the ParlAT package conventions.

------------------------------------------------------------------------

## Output schema

All search functions return a `tibble` with:

| Column          | Type        | Description                          |
|-----------------|-------------|--------------------------------------|
| `id`            | character   | Unique document ID                   |
| `application`   | character   | RIS application (e.g. `"Vwgh"`)      |
| `court`         | character   | Court name                           |
| `decision_date` | Date        | Date of the decision                 |
| `case_number`   | character   | Geschäftszahl                        |
| `decision_type` | character   | Type of decision                     |
| `title`         | character   | Document title                       |
| `ris_url`       | character   | Link to RIS web page                 |
| `content_urls`  | list-column | Tibble of `data_type` + `url`        |
| `app_metadata`  | list-column | Application-specific nested metadata |
| `page`          | integer     | Source page number                   |
| `per_page`      | integer     | Page size used                       |

Result tibbles carry attributes: `total_hits`, `page_number`,
`page_size`.

------------------------------------------------------------------------

## Coding style

- Follow [tidyverse style guide](https://style.tidyverse.org/)
- Use `snake_case` for all names
- Prefer `purrr` functional style over base R loops where it improves
  clarity
- Use the pipe `|>` (native R pipe) or `%>%` consistently with the
  existing file
- Use [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html) /
  [`rlang::warn()`](https://rlang.r-lib.org/reference/abort.html) for
  errors and warnings (not [`stop()`](https://rdrr.io/r/base/stop.html)
  / [`warning()`](https://rdrr.io/r/base/warning.html))
- Use `checkmate` assertions for input validation at function entry
  points
- Write descriptive, explicit variable names — avoid abbreviations
  unless widely established
- Keep functions focused on a single responsibility

------------------------------------------------------------------------

## Documentation

All exported functions must have complete roxygen2 documentation:

``` r
#' @title Short title
#' @description One-paragraph description.
#' @param arg_name Description of the argument.
#' @return Description of the return value.
#' @examples
#' \dontrun{
#'   ris_search_vwgh(query = "Baurecht", per_page = 10)
#' }
#' @export
```

- Markdown is enabled (`Roxygen: list(markdown = TRUE)` in DESCRIPTION)
- After editing roxygen2 comments, run `devtools::document()` to
  regenerate `man/` and `NAMESPACE`
- Never edit `.Rd` files or `NAMESPACE` by hand

------------------------------------------------------------------------

## Testing

- Framework: `testthat` edition 3
- Test files live in `tests/testthat/` with the prefix `test-`
- Tests should not make live API calls — mock responses or use fixtures
  where needed
- Minimum test coverage expectations:
  - All exported functions have at least one test
  - Parser handles missing/NULL fields without error
  - Validation rejects invalid arguments with a clear error message

------------------------------------------------------------------------

## API constraints

- **Respect rate limits** — the RIS OGD API is a public service; do not
  hammer it with parallel or rapid sequential requests
- **OGD netiquette** — follow the terms of the RIS OGD API; do not
  attempt to bulk-download the entire database
- **Pagination** — the package handles multi-page results automatically
  via
  [`httr2::req_perform_iterative()`](https://httr2.r-lib.org/reference/req_perform_iterative.html);
  callers should use `max_pages` to cap results during development and
  testing

------------------------------------------------------------------------

## CI/CD

The GitHub Actions workflow (`.github/workflows/pkgdown.yaml`) runs on
push to `main`/`master`, on PRs, and on published releases. It:

1.  Installs R and Pandoc
2.  Installs package dependencies
3.  Builds the pkgdown site
4.  Deploys to the `gh-pages` branch under `docs/`

The `background_docs/` directory and `AGENTS.md` are excluded from the
built package (see `.Rbuildignore`).

------------------------------------------------------------------------

## Commit and pull request guidelines

- Do not include any references to Claude, Anthropic, or AI authorship
  in commit messages, pull request titles, descriptions, or comments.
  All contributions should appear as standard human-authored work.
- Write commit messages in the imperative mood
  (e.g. `Add pagination support for Vwgh`, not `Added` or `Adding`)
- Keep the subject line under 72 characters
- Reference issue numbers where relevant (e.g. `Fix date parsing (#12)`)
- Each commit should represent a single logical change
- Do not commit generated files (`man/`, `docs/`) unless specifically
  required

------------------------------------------------------------------------

## Implemented court endpoints

All 9 Judikatur court applications are supported with convenience
wrappers: VfGH, VwGH, Justiz (OGH, OLG, LG, BG), BVwG, LVwG, DSK/DSB,
DOK, PVAK, GBK.

## Future roadmap (planned)

- Bundesrecht endpoint (`BrKons`)
- Bundesgesetzblatt (`BGBl`)
- Sonstige Kundmachungen endpoint (`/Sonstige`) — includes UPTS
  (Unabhängiger Parteien-Transparenz-Senat), which appears on the RIS
  Judikatur overview page but uses the `/Sonstige` API endpoint, not
  `/Judikatur`
- Content helpers: `ris_fetch_html()`, `ris_fetch_pdf()`,
  `ris_pick_content_url()`
