test_that("ris_parse_search returns tibble with required list-columns", {
  payload <- list(
    OgdSearchResult = list(
      status = "ok",
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1"),
        OgdDocumentReference = list(
          list(
            Data = list(
              Metadaten = list(
                Technisch = list(
                  ID = "TEST-001",
                  Applikation = "Vwgh"
                ),
                Allgemein = list(
                  DokumentUrl = "https://example.org/meta/1",
                  Veroeffentlicht = "2024-01-15"
                ),
                Judikatur = list(
                  Vwgh = list(
                    Geschaeftszahl = "Ra 2024/01/0001"
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

  out <- ris_parse_search(payload)

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_true("content_urls" %in% names(out))
  expect_true("app_metadata" %in% names(out))
  expect_type(out$content_urls[[1]], "character")
  expect_equal(length(out$content_urls[[1]]), 2L)
  expect_type(out$app_metadata[[1]], "list")
  expect_true("id" %in% names(out))
  expect_true("document_url" %in% names(out))
  expect_equal(out$id[[1]], "TEST-001")
  # XML artifact columns should be dropped
  expect_false("technisch_import_timestamp_xsi_nil" %in% names(out))
  expect_false("technisch_import_timestamp_xmlns_xsi" %in% names(out))
})

test_that("ris_parse_search raises for RIS API errors", {
  payload <- list(
    OgdSearchResult = list(
      Error = list(
        Applikation = "Vwgh",
        Message = "Die Seitennummer ist höher als die Anzahl der verfügbaren Seiten"
      )
    )
  )

  expect_error(
    ris_parse_search(payload),
    "RIS API error \\[Vwgh\\]"
  )
})
