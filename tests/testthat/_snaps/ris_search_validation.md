# echo must be a logical flag

    Code
      ris_search_case_law(application = "Vwgh", echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

---

    Code
      ris_search_vwgh(echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

---

    Code
      ris_search_vfgh(echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

# at least one document type flag must be enabled

    Code
      ris_search_vwgh(search_decision_text = FALSE, search_legal_principles = FALSE)
    Condition
      Error in `ris_normalize_document_type_flags()`:
      ! At least one of `search_decision_text` or `search_legal_principles` must be TRUE.

# all Judikatur applications can be mapped from english or RIS codes

    Code
      risAT:::ris_case_law_application_to_code("invalid_app")
    Condition
      Error in `risAT:::ris_case_law_application_to_code()`:
      ! `application` is invalid. Use one of: Vfgh, Vwgh, Normenliste, Justiz, Bvwg, Lvwg, Dsk, Dok, Pvak, Gbk, Uvs, AsylGH, Ubas, Umse, Bks, Verg, constitutional_court, administrative_court, norm_list, justice, federal_administrative_court, state_administrative_courts, data_protection_authority, disciplinary_bodies, staff_representation_oversight, equal_treatment_commission, independent_administrative_panels, asylum_court, independent_federal_asylum_panel, environmental_panel, federal_communications_panel, procurement_review_bodies.

# VfGH decision_type and sort_by can use english aliases

    Code
      risAT:::ris_normalize_case_law_decision_type("Vfgh", "invalid_type")
    Condition
      Error in `ris_normalize_vfgh_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'undefined','beschluss','erkenntnis','vergleich','keineangabe','order','judgment','settlement','notspecified'}, but is 'invalidtype'.

---

    Code
      risAT:::ris_normalize_case_law_sort_by("Vfgh", "invalid_sort")
    Condition
      Error in `ris_normalize_court_sort_by()`:
      ! Assertion on 'sort_by' failed: Must be element of set {'geschaeftszahl','datum','art','typ','businessnumber','casenumber','decisiondate','decisiontype','documenttype'}, but is 'invalidsort'.

# VwGH decision_type is validated against documented values

    Code
      risAT:::ris_normalize_case_law_decision_type("Vwgh", "Vergleich")
    Condition
      Error in `ris_normalize_vwgh_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'undefined','beschluss','erkenntnis','beschlussvs','erkenntnisvs'}, but is 'vergleich'.

# VwGH and VfGH sort_by is validated against documented values

    Code
      risAT:::ris_normalize_case_law_sort_by("Vwgh", "invalid_sort")
    Condition
      Error in `ris_normalize_court_sort_by()`:
      ! Assertion on 'sort_by' failed: Must be element of set {'geschaeftszahl','datum','art','typ','businessnumber','casenumber','decisiondate','decisiontype','documenttype'}, but is 'invalidsort'.

# document type flags are ignored for apps without Dokumenttyp

    Code
      risAT:::ris_normalize_document_type_flags(application_code = "Normenliste",
        search_decision_text = TRUE, search_legal_principles = TRUE)
    Condition
      Warning:
      `search_decision_text` and `search_legal_principles` are ignored for this Judikatur application.
    Output
      $search_decision_text
      NULL
      
      $search_legal_principles
      NULL
      

# ris_perform_case_law rejects requests without ris_meta

    Code
      ris_perform_case_law(plain_req)
    Condition
      Error in `ris_perform_case_law()`:
      ! `req` must be built with `ris_req_case_law()` (missing `ris_meta` attribute).

# ris_search_justiz rejects invalid echo argument

    Code
      ris_search_justiz(echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

# ris_search_bvwg rejects invalid echo argument

    Code
      ris_search_bvwg(echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

# ris_search_lvwg rejects invalid echo argument

    Code
      ris_search_lvwg(echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

# ris_search_dsk rejects invalid echo argument

    Code
      ris_search_dsk(echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

# ris_search_gbk rejects invalid echo argument

    Code
      ris_search_gbk(echo = "yes")
    Condition
      Error in `ris_perform_case_law()`:
      ! Assertion on 'echo' failed: Must be of type 'logical flag', not 'character'.

# common string params reject non-string input

    Code
      ris_req_case_law(application = "Vwgh", query = 123)
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'query' failed: Must be of type 'string' (or 'NULL'), not 'double'.

---

    Code
      ris_req_case_law(application = "Vwgh", business_number = TRUE)
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'business_number' failed: Must be of type 'string' (or 'NULL'), not 'logical'.

---

    Code
      ris_req_case_law(application = "Vwgh", norm = 42)
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'norm' failed: Must be of type 'string' (or 'NULL'), not 'double'.

---

    Code
      ris_req_case_law(application = "Vwgh", index_term = list("a"))
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'index_term' failed: Must be of type 'string' (or 'NULL'), not 'list'.

---

    Code
      ris_req_case_law(application = "Vwgh", collection_number = 123)
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'collection_number' failed: Must be of type 'string' (or 'NULL'), not 'double'.

---

    Code
      ris_req_case_law(application = "Vwgh", base_url = NULL)
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'base_url' failed: Must be of type 'string', not 'NULL'.

# date params reject malformed strings

    Code
      ris_req_case_law(application = "Vwgh", decision_date_from = "01-2024-01")
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'decision_date_from' failed: Must comply to pattern '^\d{4}-\d{2}-\d{2}$'.

---

    Code
      ris_req_case_law(application = "Vwgh", decision_date_to = "2024/01/01")
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'decision_date_to' failed: Must comply to pattern '^\d{4}-\d{2}-\d{2}$'.

---

    Code
      ris_req_case_law(application = "Vwgh", decision_date_from = 20240101)
    Condition
      Error in `ris_req_case_law()`:
      ! Assertion on 'decision_date_from' failed: Must be of type 'string' (or 'NULL'), not 'double'.

# BVwG decision_type is validated against documented values

    Code
      risAT:::ris_normalize_case_law_decision_type("Bvwg", "BeschlussVS")
    Condition
      Error in `ris_normalize_bvwg_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'undefined','beschluss','erkenntnis'}, but is 'beschlussvs'.

---

    Code
      risAT:::ris_normalize_case_law_decision_type("Bvwg", "Vergleich")
    Condition
      Error in `ris_normalize_bvwg_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'undefined','beschluss','erkenntnis'}, but is 'vergleich'.

# LVwG decision_type is validated against documented values

    Code
      risAT:::ris_normalize_case_law_decision_type("Lvwg", "BeschlussVS")
    Condition
      Error in `ris_normalize_lvwg_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'undefined','beschluss','erkenntnis','bescheid'}, but is 'beschlussvs'.

# Justiz decision_type is validated against documented values

    Code
      risAT:::ris_normalize_case_law_decision_type("Justiz", "Erkenntnis")
    Condition
      Error in `ris_normalize_justiz_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'ordentlicheerledigung(sachentscheidung)','zurückweisungmangelserheblicherrechtsfrage','zurückweisungausanderengründen','verstärktersenat'}, but is 'erkenntnis'.

# Dsk decision_type is validated against documented values

    Code
      risAT:::ris_normalize_case_law_decision_type("Dsk", "Erkenntnis")
    Condition
      Error in `ris_normalize_dsk_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'undefined','bescheidbeschwerde','bescheidamtswegigespruefverfahren','verwaltungsstraferkenntnisverwarnungermahnung','bescheidwissenschaftstatistikarchiv','bescheidinternatdatenverkehr','bescheidakkreditierungzertifizierung','bescheidverhaltensregeln','bescheidwarnung','bescheidregistrierung','bescheidsonstiger','empfehlung','bescheidifg','verfahrensschriftsaetze'}, but is 'erkenntnis'.

# Gbk decision_type is validated against documented values

    Code
      risAT:::ris_normalize_case_law_decision_type("Gbk", "Beschluss")
    Condition
      Error in `ris_normalize_gbk_decision_type()`:
      ! Assertion on 'decision_type' failed: Must be element of set {'undefined','einzelfallpruefungsergebnis','gutachten'}, but is 'beschluss'.

# ris_search_justiz rejects non-string wrapper params

    Code
      ris_search_justiz(court = 123)
    Condition
      Error in `ris_search_justiz()`:
      ! Assertion on 'court' failed: Must be of type 'string' (or 'NULL'), not 'double'.

---

    Code
      ris_search_justiz(legal_area = TRUE)
    Condition
      Error in `ris_search_justiz()`:
      ! Assertion on 'legal_area' failed: Must be of type 'string' (or 'NULL'), not 'logical'.

---

    Code
      ris_search_justiz(citation = list("x"))
    Condition
      Error in `ris_search_justiz()`:
      ! Assertion on 'citation' failed: Must be of type 'string' (or 'NULL'), not 'list'.

# ris_search_lvwg rejects non-string federal_state

    Code
      ris_search_lvwg(federal_state = 42)
    Condition
      Error in `ris_normalize_federal_state()`:
      ! `federal_state` must be a single string.

# ris_search_dsk rejects non-string deciding_authority

    Code
      ris_search_dsk(deciding_authority = TRUE)
    Condition
      Error in `ris_search_dsk()`:
      ! Assertion on 'deciding_authority' failed: Must be of type 'string' (or 'NULL'), not 'logical'.

# ris_search_gbk rejects non-string commission and senate

    Code
      ris_search_gbk(commission = 123)
    Condition
      Error in `ris_normalize_gbk_commission()`:
      ! `commission` must be a single string.

---

    Code
      ris_search_gbk(senate = TRUE)
    Condition
      Error in `ris_normalize_gbk_senate()`:
      ! `senate` must be a single string.

---

    Code
      ris_search_gbk(discrimination_ground = list("x"))
    Condition
      Error in `ris_normalize_gbk_discrimination_ground()`:
      ! `discrimination_ground` must be a single string.

# ris_normalize_federal_state errors on invalid value

    Code
      risAT:::ris_normalize_federal_state("Bavaria")
    Condition
      Error in `risAT:::ris_normalize_federal_state()`:
      ! `federal_state` is invalid. Use one of: Burgenland, Kärnten, Niederösterreich, Oberösterreich, Salzburg, Steiermark, Tirol, Vorarlberg, Wien. English aliases (e.g. 'Vienna', 'Styria') are also accepted.

---

    Code
      risAT:::ris_normalize_federal_state("Nonsense")
    Condition
      Error in `risAT:::ris_normalize_federal_state()`:
      ! `federal_state` is invalid. Use one of: Burgenland, Kärnten, Niederösterreich, Oberösterreich, Salzburg, Steiermark, Tirol, Vorarlberg, Wien. English aliases (e.g. 'Vienna', 'Styria') are also accepted.

# ris_search_lvwg rejects invalid federal_state

    Code
      ris_search_lvwg(federal_state = "Bavaria")
    Condition
      Error in `ris_normalize_federal_state()`:
      ! `federal_state` is invalid. Use one of: Burgenland, Kärnten, Niederösterreich, Oberösterreich, Salzburg, Steiermark, Tirol, Vorarlberg, Wien. English aliases (e.g. 'Vienna', 'Styria') are also accepted.

# ris_normalize_gbk_commission errors on invalid value

    Code
      risAT:::ris_normalize_gbk_commission("Nonsense")
    Condition
      Error in `risAT:::ris_normalize_gbk_commission()`:
      ! `commission` is invalid. Use one of: 'Bundes-Gleichbehandlungskommission' (federal public service) or 'Gleichbehandlungskommission' (private sector). Short aliases 'bundesgbk'/'bgbk' and 'gbk' are also accepted.

# ris_normalize_gbk_senate errors on invalid value

    Code
      risAT:::ris_normalize_gbk_senate("IV")
    Condition
      Error in `risAT:::ris_normalize_gbk_senate()`:
      ! `senate` is invalid. Use 'Senat I', 'Senat II', or 'Senat III' (or 'I'/'II'/'III' or '1'/'2'/'3').

---

    Code
      risAT:::ris_normalize_gbk_senate("4")
    Condition
      Error in `risAT:::ris_normalize_gbk_senate()`:
      ! `senate` is invalid. Use 'Senat I', 'Senat II', or 'Senat III' (or 'I'/'II'/'III' or '1'/'2'/'3').

# ris_normalize_gbk_discrimination_ground errors on invalid value

    Code
      risAT:::ris_normalize_gbk_discrimination_ground("Nationalitaet")
    Condition
      Error in `risAT:::ris_normalize_gbk_discrimination_ground()`:
      ! `discrimination_ground` is invalid. Use one of: Geschlecht, Ethnische Zugehörigkeit, Religion, Weltanschauung, Alter, Sexuelle Orientierung, Behinderung, Mehrfachdiskriminierung. English aliases (e.g. 'gender', 'age', 'disability') are also accepted.

# ris_search_gbk rejects invalid commission

    Code
      ris_search_gbk(commission = "Nonsense")
    Condition
      Error in `ris_normalize_gbk_commission()`:
      ! `commission` is invalid. Use one of: 'Bundes-Gleichbehandlungskommission' (federal public service) or 'Gleichbehandlungskommission' (private sector). Short aliases 'bundesgbk'/'bgbk' and 'gbk' are also accepted.

# ris_search_gbk rejects invalid senate

    Code
      ris_search_gbk(senate = "IV")
    Condition
      Error in `ris_normalize_gbk_senate()`:
      ! `senate` is invalid. Use 'Senat I', 'Senat II', or 'Senat III' (or 'I'/'II'/'III' or '1'/'2'/'3').

# ris_search_gbk rejects invalid discrimination_ground

    Code
      ris_search_gbk(discrimination_ground = "Nationalitaet")
    Condition
      Error in `ris_normalize_gbk_discrimination_ground()`:
      ! `discrimination_ground` is invalid. Use one of: Geschlecht, Ethnische Zugehörigkeit, Religion, Weltanschauung, Alter, Sexuelle Orientierung, Behinderung, Mehrfachdiskriminierung. English aliases (e.g. 'gender', 'age', 'disability') are also accepted.

