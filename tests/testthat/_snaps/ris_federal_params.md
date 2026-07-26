# ris_normalize_abschnitt_typ errors on invalid value

    Code
      risAT:::ris_normalize_abschnitt_typ("Kapitel")
    Condition
      Error in `risAT:::ris_normalize_abschnitt_typ()`:
      ! `section_type` is invalid. Use one of: 'Alle', 'Artikel', 'Paragraph', 'Anlage' (English aliases 'all', 'article', 'paragraph', 'annex' are also accepted).

# ris_normalize_federal_sort_column errors on invalid value

    Code
      risAT:::ris_normalize_federal_sort_column("Datum")
    Condition
      Error in `risAT:::ris_normalize_federal_sort_column()`:
      ! `sort_by` is invalid. Use one of: 'ArtikelParagraphAnlage', 'Kurzinformation', 'Inkrafttretensdatum', 'Ausserkrafttretensdatum'.

# ris_req_federal rejects version_date combined with a date range

    Code
      ris_req_federal(version_date = "2020-01-01", effective_from = "2019-01-01")
    Condition
      Error in `ris_req_federal()`:
      ! `version_date` (point-in-time version) cannot be combined with `effective_*` / `expiry_*` date ranges. Use one or the other.

# ris_req_federal rejects malformed date strings

    Code
      ris_req_federal(version_date = "01.01.2020")
    Condition
      Error in `ris_req_federal()`:
      ! Assertion on 'version_date' failed: Must comply to pattern '^\d{4}-\d{2}-\d{2}$'.

---

    Code
      ris_req_federal(effective_from = "2020/01/01")
    Condition
      Error in `ris_req_federal()`:
      ! Assertion on 'effective_from' failed: Must comply to pattern '^\d{4}-\d{2}-\d{2}$'.

# ris_req_federal rejects non-string params

    Code
      ris_req_federal(title = 123)
    Condition
      Error in `ris_req_federal()`:
      ! Assertion on 'title' failed: Must be of type 'string' (or 'NULL'), not 'double'.

# ris_perform_federal rejects requests without ris_meta

    Code
      ris_perform_federal(plain_req)
    Condition
      Error in `ris_perform_federal()`:
      ! `req` must be built with `ris_req_federal()` (missing `ris_meta` attribute).

