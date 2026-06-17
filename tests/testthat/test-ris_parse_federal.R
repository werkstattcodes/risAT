# ============================================================================
# Tests for ris_parse_federal(): parsing the BrKons response envelope into
# a tidy tibble.  No live API calls — uses a fixture modelled on the real
# /Bundesrecht response shape.
# ============================================================================

make_federal_payload <- function() {
  list(
    OgdSearchResult = list(
      status = "ok",
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1"),
        OgdDocumentReference = list(
          list(
            Data = list(
              Metadaten = list(
                Technisch = list(
                  ID = "NOR12345678",
                  Applikation = "BrKons",
                  Organ = "BKA"
                ),
                Allgemein = list(
                  Geaendert = "2024-01-15",
                  DokumentUrl = "https://example.org/meta/1"
                ),
                Bundesrecht = list(
                  Kurztitel = "ABGB",
                  Titel = "Allgemeines bürgerliches Gesetzbuch",
                  Eli = "eli/at/jgs/1811/946",
                  BrKons = list(
                    Kundmachungsorgan = "JGS Nr.",
                    Typ = "BG",
                    Inkrafttretensdatum = "1812-01-01",
                    Abkuerzung = "ABGB",
                    Gesetzesnummer = "10001622",
                    GesamteRechtsvorschriftUrl = "https://example.org/law/1"
                  )
                )
              ),
              Dokumentliste = list(
                ContentReference = list(
                  list(
                    ContentType = "MainDocument",
                    Urls = list(
                      ContentUrl = list(
                        list(
                          DataType = "Html",
                          Url = "https://example.org/doc/1/html"
                        ),
                        list(
                          DataType = "Pdf",
                          Url = "https://example.org/doc/1/pdf"
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

test_that("ris_parse_federal returns a tibble with required list-columns", {
  out <- ris_parse_federal(make_federal_payload())

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_true("content_urls" %in% names(out))
  expect_true("app_metadata" %in% names(out))
  expect_type(out$content_urls[[1]], "character")
  expect_length(out$content_urls[[1]], 2)
  expect_type(out$app_metadata[[1]], "list")
})

test_that("ris_parse_federal translates German metadata to English columns", {
  out <- ris_parse_federal(make_federal_payload())

  expect_equal(out$id[[1]], "NOR12345678")
  expect_equal(out$application[[1]], "BrKons")
  expect_equal(out$short_title[[1]], "ABGB")
  expect_equal(out$title[[1]], "Allgemeines bürgerliches Gesetzbuch")
  expect_equal(out$eli[[1]], "eli/at/jgs/1811/946")
  expect_equal(out$type[[1]], "BG")
  expect_equal(out$promulgation_organ[[1]], "JGS Nr.")
  expect_equal(out$effective_date[[1]], "1812-01-01")
  expect_equal(out$law_number[[1]], "10001622")
  expect_equal(out$abbreviation[[1]], "ABGB")
  expect_equal(out$full_law_url[[1]], "https://example.org/law/1")
})

test_that("ris_parse_federal keeps the bundesrecht block in app_metadata", {
  out <- ris_parse_federal(make_federal_payload())
  meta <- out$app_metadata[[1]]
  expect_true("bundesrecht" %in% names(meta))
  expect_equal(meta$bundesrecht$Kurztitel, "ABGB")
  expect_true("technisch" %in% names(meta))
  expect_true("response" %in% names(meta))
})

test_that("ris_parse_federal handles empty results", {
  payload <- list(
    OgdSearchResult = list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "0")
      )
    )
  )
  out <- ris_parse_federal(payload)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
  expect_true(all(c("content_urls", "app_metadata") %in% names(out)))
})

test_that("ris_parse_federal tolerates missing optional fields", {
  payload <- list(
    OgdSearchResult = list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1"),
        OgdDocumentReference = list(
          list(
            Data = list(
              Metadaten = list(
                Technisch = list(ID = "NOR-X", Applikation = "BrKons"),
                Bundesrecht = list(Titel = "Minimal Norm")
              )
            )
          )
        )
      )
    )
  )
  out <- ris_parse_federal(payload)
  expect_equal(nrow(out), 1L)
  expect_equal(out$title[[1]], "Minimal Norm")
  # No Dokumentliste -> empty content_urls, not an error.
  expect_length(out$content_urls[[1]], 0)
})

test_that("ris_parse_federal raises for RIS API errors", {
  payload <- list(
    OgdSearchResult = list(
      Error = list(
        Applikation = "BrKons",
        Message = "Die Seitennummer ist höher als die Anzahl der verfügbaren Seiten"
      )
    )
  )
  expect_error(
    ris_parse_federal(payload),
    "RIS API error \\[BrKons\\]"
  )
})
