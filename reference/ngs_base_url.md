# Base URL of a scene

The URL of the neuroglancer instance (e.g.
`"https://spelunker.cave-explorer.org/"`) that
[`ngs_url()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
appends the state to.

## Usage

``` r
ngs_base_url(x)

ngs_base_url(x) <- value
```

## Arguments

- x:

  A scene.

- value:

  The new base URL.

## Value

For `ngs_base_url()`, the base URL.

## Examples

``` r
sc <- ngs_scene()
ngs_base_url(sc) <- "https://spelunker.cave-explorer.org/"
ngs_url(sc)
#> [1] "https://spelunker.cave-explorer.org/#!%7B%22layers%22%3A%5B%5D%7D"
```
