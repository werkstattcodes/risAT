# Parse RIS Search Responses

Parse a RIS OGD REST API search response into a tidy tibble. The parser
works with either an `httr2_response` object or an already decoded
response list.

## Usage

``` r
ris_parse_search(x, requested_page = NULL, requested_per_page = NULL)
```

## Arguments

- x:

  An `httr2_response` or a decoded list.

- requested_page:

  Optional requested page number for metadata fallback.

- requested_per_page:

  Optional requested page size for metadata fallback.

## Value

A tibble parsed from one RIS response payload. Includes list-column
`content_urls`. The `decision_date` column, when present, is parsed to
`Date`.

## Examples

``` r
payload <- list(
  OgdSearchResult = list(
    status = "ok",
    OgdDocumentResults = list(
      OgdDocumentReference = list(
        list(
          Data = list(
            Metadaten = list(
              Technisch = list(ID = "DOC-1", Applikation = "Vwgh"),
              Allgemein = list(DokumentUrl = "https://example.org/meta/1")
            ),
            Dokumentliste = list(
              ContentReference = list(
                list(
                  Urls = list(
                    ContentUrl = list(
                      list(DataType = "Html", Url = "https://example.org/doc/1.html")
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
ris_parse_search(payload)
#> # A tibble: 1 × 4
#>   id    application document_url               content_urls
#>   <chr> <chr>       <chr>                      <list>      
#> 1 DOC-1 Vwgh        https://example.org/meta/1 <chr [1]>   
```
