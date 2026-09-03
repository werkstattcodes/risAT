# The `pkg-hardening` branch, explained

This document walks through everything the `pkg-hardening` branch (commit
`c1ef8ec`, branched off `dev`) changes, why each change was made, and what
you — or a user of the package — will notice differently. It is written as
free text rather than a changelog; the terse version of the same content is
in `NEWS.md`.

The branch grew out of a package review against tidyverse package-development
practice. The changes fall into five groups:

1. Protecting the public RIS API (throttling and a page cap)
2. Fixing inconsistencies between the Judikatur and Bundesrecht code paths
3. Making the user-facing interface more complete and predictable
4. Reducing internal duplication and classifying error conditions
5. Testing and CI infrastructure

Nothing in the branch changes what a correct existing call returns, with two
small, deliberate exceptions that are called out below (federal date columns
becoming `Date`, and the column set of *empty* results).

---

## 1. Protecting the public RIS API

### Client-side throttling on every request

The RIS OGD API is a free public service, and the package's own guidelines
say not to hammer it. Before this branch, nothing enforced that: the
pagination loop in `ris_perform_case_law()` fired requests back-to-back, as
fast as the network allowed, for as many pages as a query matched. A broad
query like `ris_search_vwgh(query = "Asyl")` could translate into hundreds
of rapid sequential requests without the user realising it.

Every request is now built through a single shared constructor,
`ris_base_request()` (new file `R/ris_request_utils.R`), which applies three
policies:

- a package-identifying **User-Agent** header,
- **retries** against transient network errors (`req_retry(max_tries = 3)`,
  as before),
- **throttling** via `httr2::req_throttle(capacity = 30, fill_time_s = 60)`,
  i.e. at most 30 requests per minute against the RIS host.

The throttle is a token bucket shared across all risAT requests in the
session, so even a long pagination run drains it gradually instead of
bursting. Thirty requests per minute at 100 documents per page still fetches
3,000 documents a minute — generous for legitimate research use, but no
longer capable of accidentally flooding the API.

> **Correction (2026-09-03).** The paragraph above is wrong, and the settings
> it describes have since been changed. httr2's token bucket is initialised
> *full* (`TokenBucket$initialize()` sets `self$tokens <- capacity`), so
> `capacity = 30` did **not** drain gradually — it allowed the first 30
> requests of a session to fire back-to-back with zero delay, and only then
> settled to one every two seconds. Since a page holds 100 documents, any
> search returning fewer than ~3,000 hits never engaged the throttle at all.
> The settings are now `capacity = 1, fill_time_s = 2`, which spaces every
> request including the first, and are user-overridable via
> `options(risAT.throttle_capacity = )` / `options(risAT.throttle_fill_time_s = )`.
> See `ris_throttle_params()` in `R/ris_request_utils.R`.

This required a versioned dependency: `httr2 (>= 1.1.0)` in `DESCRIPTION`,
because the `capacity`/`fill_time_s` interface of `req_throttle()` was
introduced there.

### A `max_pages` cap on pagination

Previously the package *always* fetched *all* pages
(`req_perform_iterative(max_reqs = Inf)`), with no way to say "just give me
the first couple of hundred results". Every search and perform function —
`ris_search_case_law()`, `ris_search_federal()`, all nine court wrappers,
`ris_perform_case_law()`, and `ris_perform_federal()` — now accepts
`max_pages`. The default is `Inf`, so existing code behaves exactly as
before.

When the cap actually truncates a result set, the user is told. After the
last fetched page, the internal helper `ris_inform_if_truncated()` inspects
that page's `Hits` metadata; if more pages existed, it emits a message like:

> Stopped after `max_pages = 2` pages (4,317 total hits); more results are
> available. Increase `max_pages` to fetch them.

The message is a classed condition (`risat_truncated_results`), so
programmatic callers can detect truncation with
`withCallingHandlers()`/`tryCatch()` rather than by parsing message text.
It is a message, not a warning: the user asked for the cap, so hitting it
is information, not a problem.

---

## 2. Judikatur/Bundesrecht consistency fixes

These are cases where the two endpoint implementations had silently drifted
apart. All three were found by reading the two code paths side by side.

### Bundesrecht requests now identify themselves

`ris_req_case_law()` set a User-Agent; `ris_req_federal()` did not — federal
requests went out with httr2's generic default. Because both builders now go
through `ris_base_request()`, the federal side gets the same User-Agent
(and throttle) automatically, and the two sides can no longer drift: there
is exactly one place where request policy lives.

### Duplicate column names in federal results

When the parser translates flattened German metadata names to English, two
different source fields can map to the same English name. The Judikatur
parser guarded against this with `make.unique()`; the federal parser did
not — and its name map even contains such a pair
(`bundesrecht_br_kons_indizes` and `bundesrecht_br_kons_indizes_item` both
translate to `indices`, depending on how the API serialises the field). If
both ever co-occurred in one document, the result would have been a tibble
with two identical column names, which breaks most downstream code in
confusing ways. The federal parser now applies the same `make.unique()`
guard (`R/ris_parse_federal.R`).

### Date columns are typed consistently

Case-law results parsed `decision_date` to `Date`; federal results left
`effective_date` and `expiry_date` (Inkrafttretens-/Ausserkrafttretensdatum)
as character strings. The one-off `ris_parse_decision_date()` helper was
generalised into `ris_parse_date_columns(tbl, cols)`, which both parsers now
use: case law for `decision_date`, federal for `effective_date` and
`expiry_date`. The helper keeps the package's robust-parsing stance — a
column that is a list-column (repeated field) or fails to parse is left
untouched rather than erroring.

**This is a small behavioral change**: code that compared
`effective_date` to a string (e.g. `filter(effective_date == "2020-01-01")`)
still works because R compares Date to character by coercion, but code that
did string operations on the column (e.g. `substr()`) would now need
`format()` first. `published`/`modified` deliberately stay character, as
documented in the output schema.

---

## 3. Interface completeness and predictability

### Sorting is no longer hard-coded for case law

`ris_req_case_law()` silently forced every query to sort by decision date,
descending — the values were hard-coded in the function body even though the
internal parameter builder and validators for `sort_by`/`sort_direction`
already existed (the federal side had exposed both all along). Both are now
real arguments on `ris_req_case_law()` and `ris_search_case_law()`, with the
old behavior as the default (`sort_by = "Datum"`,
`sort_direction = "Descending"`). For VfGH and VwGH the sort column is
validated client-side and accepts English aliases (`"decision_date"`,
`"case_number"`, ...); other applications pass the value through to the API.

The nine court wrappers were *not* given the sort arguments (to keep their
signatures focused); anyone needing custom sorting for, say, BVwG can use
`ris_search_case_law(application = "Bvwg", sort_by = ...)`.

### One source of truth for the API base URL

The literal `"https://data.bka.gv.at/ris/api/v2.6"` used to be the default
argument of about a dozen exported functions. When the API version bumps,
that is a dozen signatures to edit. There is now an exported helper:

```r
ris_base_url()
#> [1] "https://data.bka.gv.at/ris/api/v2.6"
```

which reads `getOption("risAT.base_url", <default>)`. Every function's
`base_url` argument defaults to `ris_base_url()`. Users can retarget the
whole session — for a future API version, or a mock server in tests — with
`options(risAT.base_url = "...")`, and a version bump becomes a one-line
change in the package.

### Accessors for the RIS website URLs

Result tibbles carry the equivalent RIS website URLs as attributes
(`ris_app_url`, `ris_search_url`) so a search can be cross-checked in the
browser. Attributes on tibbles are easy to lose (most dplyr verbs drop
them), and `attr(x, "ris_search_url")` is not discoverable. Two exported
accessors make the feature visible:

```r
res <- ris_search_vwgh(business_number = "Ra 2021/01/0001")
ris_search_url(res)
ris_app_url(res)
```

Their documentation states explicitly that they must be called on the
unmodified result, and points at `app_metadata$request`, where the same
URLs are stored per row and *do* survive data wrangling.

### Type-stable empty results

Previously a search with zero hits returned a tibble with only two columns
(`content_urls`, `app_metadata`), while any non-empty search also had `id`,
`application`, and more. That means `result$id` worked in every case except
the one nobody tests — the empty result — where it returned `NULL` and blew
up whatever came next. Empty results (from both perform functions *and*
both parsers) now come from a single `ris_empty_result()` constructor and
always contain the four guaranteed columns with correct types:

| column | type |
|---|---|
| `id` | character |
| `application` | character |
| `content_urls` | list |
| `app_metadata` | list |

This mirrors the tidyverse design principle that a function's output
*structure* should depend on its input's type, not on how many rows happen
to match.

---

## 4. Internal refactor and classed errors

### Enum normalizers collapsed into lookup tables

The old `ris_case_law_utils.R` contained seven nearly identical functions
(`ris_normalize_vwgh_decision_type()`, `..._vfgh_...`, `..._bvwg_...`,
`..._lvwg_...`, `..._justiz_...`, `..._dsk_...`, `..._gbk_...`), each ~20
lines wrapping a named lookup vector, plus a similar family for federal
states, GBK commission/senate/discrimination ground, named intervals, sort
direction, and section type. Two shared mechanisms replace them:

- **Decision types** are now data, not code: one constant,
  `ris_case_law_decision_type_lookups`, is a list keyed by application code
  (`Vfgh`, `Vwgh`, `Bvwg`, `Lvwg`, `Justiz`, `Dsk`, `Gbk`), and the single
  dispatcher `ris_normalize_case_law_decision_type()` looks up the right
  table, normalises the user's input, and validates it. Applications
  without a table (Dok, Pvak, ...) pass through unchanged as before.
  Supporting a new application's enum now means adding a lookup vector, not
  writing a function.

- **The abort-based normalizers** (federal state, GBK trio, intervals, sort
  direction, federal section type and sort column) all delegate to a new
  generic `ris_match_lookup(x, lookup, arg, invalid_message, ...)`, which
  implements the shared pattern: NULL/empty → `NULL`; non-string → type
  error; normalise key and match; no match → the caller-supplied error
  message. It takes `call = rlang::caller_env()` so error output still
  names the *specific* normalizer, not the generic helper.

Net effect: about 250 lines of duplication removed, byte-identical error
message text, and a much smaller surface to extend when the Landesrecht and
BGBl endpoints from the roadmap arrive.

One visible consequence: because the seven per-application functions no
longer exist, ten testthat snapshots changed **in the reported frame only**
(e.g. ``Error in `ris_normalize_bvwg_decision_type()` `` became
``Error in `ris_normalize_case_law_decision_type()` ``). The message text is
unchanged, and the diff of the snapshot file was reviewed to confirm nothing
else moved.

### Errors and messages carry condition classes

All validation errors raised by the package are now classed
`risat_invalid_argument`; errors surfaced from the RIS API's own error
payloads are `risat_api_error`; the truncation notice is
`risat_truncated_results`. This changes nothing about what is printed, but
lets callers (and the package's own tests) handle conditions structurally:

```r
tryCatch(
  ris_search_lvwg(federal_state = "Bavaria"),
  risat_invalid_argument = function(cnd) NULL
)
```

The tests that previously matched error *messages* by regex (brittle —
improving a message would break the suite) now match by class where the
class is the point.

In keeping with the project's style rules, this was done by adding `class =`
to the existing `rlang::abort()` calls; the `checkmate` assertions and
rlang error style mandated by `CLAUDE.md` are untouched.

---

## 5. Tests and CI

### The httr2 layer is finally exercised

The existing tests mocked out the *entire* pagination function
(`ris_iterate_case_law_pages()`) and fed decoded JSON lists straight to the
parser. That meant the most failure-prone code in the package — the
`next_req` callback that reads page metadata and rewrites `Seitennummer`,
plus the `resp_body_json()` handling — never ran in tests.

The new `tests/testthat/test-ris_request_utils.R` uses
`httr2::local_mocked_responses()` with real `httr2_response` objects built
from the existing JSON fixtures. The pagination loop, the page-2 request,
the response decoding, and the row combining all run for real (with the
network transport mocked at the httr2 level). Additional tests cover:

- `max_pages = 1` truncation, asserting the `risat_truncated_results`
  message fires — and does *not* fire when the result fits;
- the User-Agent, retry, and throttle policies on both request builders;
- `sort_by`/`sort_direction` appearing (normalised) in the request URL;
- the `options(risAT.base_url = )` override propagating into built requests;
- the URL accessors, the empty-result schema, `max_pages` validation, and
  the new date parsing and error classes.

Existing mocks were updated for the new iterator signature
(`function(req, max_pages)`), and two expectations were updated for the
intended behavior changes (empty-result columns; federal `effective_date`
now a `Date`).

The suite stands at **438 passing tests**, and `devtools::check()` is clean:
0 errors, 0 warnings, 0 notes.

### CI and metadata

- **`.github/workflows/test-coverage.yaml`** (standard r-lib/actions
  workflow) runs covr on pushes and PRs and uploads to Codecov. Uploading
  needs a `CODECOV_TOKEN` repository secret; without it the coverage still
  computes and prints in the log.
- **README** gained the R-CMD-check badge (the workflow already existed;
  the badge did not).
- **DESCRIPTION**: the `Description` field was expanded to CRAN-friendly
  prose naming the data provider with the API URL in angle brackets, and
  `httr2` got the `>= 1.1.0` floor. (`Config/roxygen2/version` turned out
  to be maintained by roxygen2 itself and stays.)
- **LICENSE**: copyright holder corrected from "risAT Contributors" to the
  actual author, matching `Authors@R`.
- **`_pkgdown.yml`**: the new exports (`ris_base_url()`, `ris_search_url()`
  / `ris_app_url()`) were added to the reference index under a new
  "Utilities" section — pkgdown fails the site build if an exported topic
  is missing from the index. `pkgdown::check_pkgdown()` passes.
- **NEWS.md** summarises all of the above.

---

## What was deliberately *not* done

- **No migration to `cli::cli_abort()`** and no removal of `checkmate` —
  both were floated in the review, but the project's `CLAUDE.md` mandates
  checkmate assertions and `rlang::abort()`. Error classes deliver the main
  practical benefit within those constraints.
- **No `sort_by`/`sort_direction` on the court wrappers** — available via
  the generic function; an easy follow-up if wanted.
- **No `req_cache()`**, no `ris_tbl` print subclass, and no change to the
  `echo`/`message()` reporting style — all noted in the review as
  longer-term options.

## Compatibility summary

Everything is additive or default-preserving. The three things existing
code could notice:

1. `effective_date`/`expiry_date` in federal results are `Date`, not
   character.
2. Empty results have four columns (`id`, `application`, `content_urls`,
   `app_metadata`) instead of two.
3. Long multi-page fetches are slower by design because of the throttle — that
   is the point of the branch. (As of the 2026-09-03 correction above, pacing
   applies from the very first request, at one every two seconds, rather than
   only after an initial burst of 30.)
