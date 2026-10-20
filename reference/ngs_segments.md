# Selected segments

`ngs_segments()` returns the selected segments, `ngs_add_segments()` and
`ngs_remove_segments()` select and deselect segments.

## Usage

``` r
ngs_segments(x, layer = NULL)

ngs_add_segments(x, segments, layer = NULL)

ngs_remove_segments(x, segments, layer = NULL)
```

## Arguments

- x:

  A segmentation layer or a scene.

- layer:

  If `x` is a scene: name or position of the segmentation layer. Can be
  omitted if the scene has only one segmentation layer.

- segments:

  Segment IDs (character, numeric or
  [`bit64::integer64`](https://bit64.r-lib.org/reference/bit64-package.html)).

## Value

`ngs_segments()` returns a character vector of segment IDs, the others
the modified layer or scene.

## Details

Neuroglancer marks segments that are selected but hidden with a leading
`!` (e.g. `"!12345"`). Adding a hidden segment makes it visible, and
removing a segment also removes it if hidden.

## Examples

``` r
seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:3)
ngs_segments(seg)
#> [1] "1" "2" "3"

sc <- ngs_scene(seg)
sc <- ngs_add_segments(sc, c(4, 5))
sc <- ngs_remove_segments(sc, 1)
ngs_segments(sc)
#> [1] "2" "3" "4" "5"
```
