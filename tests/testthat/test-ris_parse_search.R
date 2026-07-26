test_that("ris_parse_search returns tibble with public list-columns", {
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
  expect_false("app_metadata" %in% names(out))
  expect_type(out$content_urls[[1]], "character")
  expect_length(out$content_urls[[1]], 2)
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

test_that("keywords are split into a list-column of terms", {
  make_doc <- function(id, judikatur) {
    list(
      Data = list(
        Metadaten = list(
          Technisch = list(ID = id, Applikation = "Vfgh"),
          Judikatur = judikatur
        )
      )
    )
  }
  payload <- list(
    OgdSearchResult = list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "2"),
        OgdDocumentReference = list(
          make_doc(
            "KW-1",
            list(
              Schlagworte = "Klima, Umweltschutz, EU-Recht",
              Normen = list(item = list("B-VG Art7", "StGG Art2"))
            )
          ),
          # No Schlagworte: the keywords cell must be NA, not an error.
          make_doc("KW-2", list(Normen = list(item = list("VfGG Abs1"))))
        )
      )
    )
  )

  out <- ris_parse_search(payload)

  expect_type(out$keywords, "list")
  expect_equal(out$keywords[[1]], c("Klima", "Umweltschutz", "EU-Recht"))
  expect_true(is.na(out$keywords[[2]]))

  expect_type(out$norms, "list")
  expect_equal(unlist(out$norms[[1]]), c("B-VG Art7", "StGG Art2"))
  expect_equal(unlist(out$norms[[2]]), "VfGG Abs1")
})

test_that("norms stay a list-column when every document has a single norm", {
  # When each document on a page carries exactly one norm, the API collapses
  # the item array to a bare scalar; the column must still be list-typed.
  payload <- list(
    OgdSearchResult = list(
      OgdDocumentResults = list(
        Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1"),
        OgdDocumentReference = list(
          list(
            Data = list(
              Metadaten = list(
                Technisch = list(ID = "SN-1", Applikation = "Vfgh"),
                Judikatur = list(Normen = list(item = "B-VG Art7"))
              )
            )
          )
        )
      )
    )
  )

  out <- ris_parse_search(payload)

  expect_type(out$norms, "list")
  expect_equal(out$norms[[1]], "B-VG Art7")
})
