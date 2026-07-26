# Parse RIS Bundesrecht Search Responses

Parse a RIS OGD REST API `/Bundesrecht` (BrKons, consolidated federal
law) search response into a tidy tibble. Works with either an
`httr2_response` object or an already decoded response list.

## Usage

``` r
ris_parse_federal(x, requested_page = NULL, requested_per_page = NULL)
```

## Arguments

- x:

  An `httr2_response` or a decoded list.

- requested_page:

  Optional requested page number for metadata fallback.

- requested_per_page:

  Optional requested page size for metadata fallback.

## Value

A tibble parsed from one RIS Bundesrecht response payload. Includes
list-column `content_urls`. The `effective_date` and `expiry_date`
columns, when present, are parsed to `Date`.

## Examples

``` r
payload <- list(
  OgdSearchResult = list(
    OgdDocumentResults = list(
      Hits = list(pageNumber = "1", pageSize = "20", `#text` = "1"),
      OgdDocumentReference = list(
        list(
          Data = list(
            Metadaten = list(
              Technisch = list(ID = "NOR-1", Applikation = "BrKons"),
              Bundesrecht = list(
                Titel = "Allgemeines bürgerliches Gesetzbuch",
                Kurztitel = "ABGB"
              )
            ),
            Dokumentliste = list(
              ContentReference = list(
                list(
                  Urls = list(
                    ContentUrl = list(
                      list(DataType = "Html", Url = "https://example.org/1.html")
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
ris_parse_federal(payload)
#> # A tibble: 1 × 5
#>   id    application title                               short_title content_urls
#>   <chr> <chr>       <chr>                               <chr>       <list>      
#> 1 NOR-1 BrKons      Allgemeines bürgerliches Gesetzbuch ABGB        <chr [1]>   
```
