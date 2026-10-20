# Parse layer states into layers

Turns layer states (named lists, e.g. parsed from JSON) into layer
objects. States are taken as they are: no defaults are added and no
values changed, so they round-trip unchanged. Layers of types without a
dedicated class (e.g. neuroglancer's "new" layers) become generic layers
which are carried through verbatim.

## Usage

``` r
ngs_parse_layers(x, skip_unknown = FALSE, skip_archived = TRUE)
```

## Arguments

- x:

  A single layer state (named list) or an unnamed list thereof.

- skip_unknown:

  If `TRUE`, drop layers of unknown type instead of keeping them as
  generic layers.

- skip_archived:

  If `TRUE`, drop archived layers.

## Value

A layer, or a list of layers if `x` is a list of states.

## Examples

``` r
ngs_parse_layers(list(type = "image", source = "precomputed://gs://x/em",
                      name = "em"))
#> <image layer> "em" precomputed://gs://x/em
```
