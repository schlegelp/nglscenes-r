# Colour segments by a property

Colour segments by a property

## Usage

``` r
ngs_color_by(x, by, palette = "tab10", layer = NULL)
```

## Arguments

- x:

  A segmentation layer or a scene.

- by:

  Values to colour by. Must have one value per selected segment.

- palette:

  Either the name of a palette (anything in
  [`grDevices::palette.pals()`](https://rdrr.io/r/grDevices/palette.html)
  or
  [`grDevices::hcl.pals()`](https://rdrr.io/r/grDevices/palettes.html),
  case-insensitive; `"tab10"` is an alias for `"Tableau 10"`), a
  function returning `n` colours, or a vector (or list) of colours named
  by the values in `by`.

- layer:

  If `x` is a scene: name or position of the segmentation layer. Can be
  omitted if the scene has only one segmentation layer.

## Value

The modified layer or scene. Replaces any existing segment colours.

## Examples

``` r
seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:4)
seg <- ngs_color_by(seg, c("A", "B", "A", "C"))
seg <- ngs_color_by(seg, c("A", "B", "A", "C"), palette = "viridis")
seg <- ngs_color_by(seg, c("A", "B", "A", "B"),
                    palette = c(A = "red", B = "blue"))
```
