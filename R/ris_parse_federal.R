# ============================================================================
# ris_parse_federal.R — Parse RIS Bundesrecht (BrKons) search responses
# ============================================================================
#
# The /Bundesrecht endpoint returns the *same response envelope* as /Judikatur:
#
#   OgdSearchResult > OgdDocumentResults > {Hits, OgdDocumentReference >
#                                           Data > Metadaten}
#
# so this parser reuses the generic, application-agnostic walkers defined in
# ris_parse_search.R (payload extraction, root/error/reference/page helpers,
# flattening, snake_case conversion, content-URL extraction, row harmonizing).
#
# What is Bundesrecht-specific:
#   - the metadata block is `Metadaten$Bundesrecht` (with a nested `BrKons`
#     sub-block) instead of `Metadaten$Judikatur`;
#   - the German -> English column name map (ris_federal_column_name_map);
#   - app_metadata also carries the `bundesrecht` block.
# ============================================================================

#' Parse RIS Bundesrecht Search Responses
#'
#' Parse a RIS OGD REST API `/Bundesrecht` (BrKons, consolidated federal law)
#' search response into a tidy tibble. Works with either an `httr2_response`
#' object or an already decoded response list.
#'
#' @param x An `httr2_response` or a decoded list.
#' @param requested_page Optional requested page number for metadata fallback.
#' @param requested_per_page Optional requested page size for metadata fallback.
#'
#' @return A tibble parsed from one RIS Bundesrecht response payload.
#'   Includes list-columns `content_urls` and `app_metadata`.
#'   The `effective_date` and `expiry_date` columns, when present, are
#'   parsed to `Date`.
#' @importFrom rlang %||%
#' @export
#'
#' @examples
#' payload <- list(
#'   OgdSearchResult = list(
#'     OgdDocumentResults = list(
#'       Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1"),
#'       OgdDocumentReference = list(
#'         list(
#'           Data = list(
#'             Metadaten = list(
#'               Technisch = list(ID = "NOR-1", Applikation = "BrKons"),
#'               Bundesrecht = list(
#'                 Titel = "Allgemeines bürgerliches Gesetzbuch",
#'                 Kurztitel = "ABGB"
#'               )
#'             ),
#'             Dokumentliste = list(
#'               ContentReference = list(
#'                 list(
#'                   Urls = list(
#'                     ContentUrl = list(
#'                       list(DataType = "Html", Url = "https://example.org/1.html")
#'                     )
#'                   )
#'                 )
#'               )
#'             )
#'           )
#'         )
#'       )
#'     )
#'   )
#' )
#' ris_parse_federal(payload)
ris_parse_federal <- function(
  x,
  requested_page = NULL,
  requested_per_page = NULL
) {
  payload <- ris_as_payload(x)
  root <- ris_extract_root(payload)
  ris_stop_on_api_error(root)

  document_refs <- ris_extract_document_references(root)
  page_info <- ris_extract_page_info(root)
  response_meta <- list(
    status = root$status %||% root$Status %||% NA_character_,
    hits = ris_extract_hits_count(root),
    page_number = page_info$page_number %||% requested_page,
    page_size = page_info$page_size %||% requested_per_page
  )

  if (length(document_refs) == 0L) {
    return(ris_empty_result())
  }

  rows <- purrr::map(
    document_refs,
    \(doc) ris_reference_to_federal_row(doc, response_meta)
  )

  out <- ris_bind_rows_harmonized(rows)
  ris_parse_date_columns(out, c("effective_date", "expiry_date"))
}

# Convert a single OgdDocumentReference into a one-row tibble.  Mirrors
# ris_reference_to_tibble_row() but uses the Bundesrecht column map and keeps
# the `bundesrecht` metadata block in app_metadata.
ris_reference_to_federal_row <- function(reference, response_meta) {
  data <- reference$Data %||% list()
  metadata <- data$Metadaten %||% list()
  metadata_flat <- ris_flatten_named_list(metadata)
  metadata_flat <- purrr::modify(metadata_flat, ~ if (is.null(.x)) NA else .x)

  if (length(metadata_flat) == 0L) {
    metadata_flat <- list()
  }

  if (is.null(names(metadata_flat)) || any(names(metadata_flat) == "")) {
    names(metadata_flat) <- paste0("field_", seq_along(metadata_flat))
  }

  names(metadata_flat) <- make.unique(ris_to_snake_case(names(metadata_flat)))
  metadata_flat <- purrr::modify(metadata_flat, ris_to_scalar_or_list)

  # Drop XML serialization artifact columns before building the row.
  metadata_flat <- metadata_flat[!names(metadata_flat) %in% ris_columns_to_drop]

  # Translate German snake_case names to English.  make.unique() guards
  # against two source fields translating to the same English name (e.g.
  # Indizes serialized with and without an Item wrapper both map to
  # "indices").
  names(metadata_flat) <- make.unique(
    ris_translate_federal_column_names(names(metadata_flat))
  )

  row <- tibble::as_tibble_row(metadata_flat, .name_repair = "minimal")
  row$content_urls <- list(ris_extract_content_urls(data$Dokumentliste))
  row$app_metadata <- list(
    list(
      response = response_meta,
      technisch = metadata$Technisch %||% list(),
      allgemein = metadata$Allgemein %||% list(),
      bundesrecht = metadata$Bundesrecht %||% list()
    )
  )
  row
}

# ============================================================================
# Column name translation: German snake_case -> English (Bundesrecht / BrKons)
# ============================================================================
# Keys are the flattened, snake_cased metadata paths.  Bundesrecht keys are
# prefixed `bundesrecht_*` (and `bundesrecht_br_kons_*` for the nested BrKons
# sub-block), so they never collide with the Judikatur `judikatur_*` keys.
# Columns not in this map are returned as-is (snake_case), keeping the parser
# robust to schema additions.

ris_federal_column_name_map <- c(
  # -- Common columns (shared with Judikatur) --
  technisch_id = "id",
  technisch_applikation = "application",
  technisch_organ = "authority",
  allgemein_veroeffentlicht = "published",
  allgemein_geaendert = "modified",
  allgemein_dokument_url = "document_url",

  # -- Bundesrecht (top-level) --
  bundesrecht_kurztitel = "short_title",
  bundesrecht_titel = "title",
  bundesrecht_eli = "eli",

  # -- Bundesrecht / BrKons (consolidated federal law sub-block) --
  bundesrecht_br_kons_kundmachungsorgan = "promulgation_organ",
  bundesrecht_br_kons_typ = "type",
  bundesrecht_br_kons_dokumenttyp = "document_type",
  bundesrecht_br_kons_artikel_paragraph_anlage = "article_paragraph_annex",
  bundesrecht_br_kons_artikelnummer = "article_number",
  bundesrecht_br_kons_paragraphnummer = "paragraph_number",
  bundesrecht_br_kons_paragraphbuchstabe = "paragraph_letter",
  bundesrecht_br_kons_stammnorm_publikationsorgan = "base_norm_publication_organ",
  bundesrecht_br_kons_stammnorm_bgblnummer = "base_norm_bgbl_number",
  bundesrecht_br_kons_novellen_publikationsorgan = "amendment_publication_organ",
  bundesrecht_br_kons_novellen_bgblnummer = "amendment_bgbl_number",
  bundesrecht_br_kons_novellen_beziehung = "amendment_relation",
  bundesrecht_br_kons_inkrafttretensdatum = "effective_date",
  bundesrecht_br_kons_ausserkrafttretensdatum = "expiry_date",
  bundesrecht_br_kons_abkuerzung = "abbreviation",
  bundesrecht_br_kons_indizes = "indices",
  bundesrecht_br_kons_indizes_item = "indices",
  bundesrecht_br_kons_aenderung = "amendments",
  bundesrecht_br_kons_anmerkung = "note",
  bundesrecht_br_kons_beachte = "attention_note",
  bundesrecht_br_kons_uebergangsrecht = "transitional_law",
  bundesrecht_br_kons_schlagworte = "keywords",
  bundesrecht_br_kons_gesetzesnummer = "law_number",
  bundesrecht_br_kons_alte_dokumentnummer = "old_document_number",
  bundesrecht_br_kons_gesamte_rechtsvorschrift_url = "full_law_url"
)

# Rename columns using the Bundesrecht mapping and drop artifact columns.
# Unknown columns keep their original snake_case name.  Reuses the shared
# `ris_columns_to_drop` defined in ris_parse_search.R.
ris_translate_federal_column_names <- function(nms) {
  nms <- nms[!nms %in% ris_columns_to_drop]
  matched <- match(nms, names(ris_federal_column_name_map))
  ifelse(is.na(matched), nms, ris_federal_column_name_map[matched])
}
