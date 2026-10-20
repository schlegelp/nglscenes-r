# Set segment colours

Set segment colours

## Usage

``` r
ngs_set_colors(x, colors, layer = NULL)
```

## Arguments

- x:

  A segmentation layer or a scene.

- colors:

  Colours to set. Colours can be names (`"red"`, also matplotlib's
  single letters like `"r"`), hex codes or RGB(A) values in the 0-1
  range. Can be:

  - a single colour for all selected segments

  - a vector (or list) of colours, one per selected segment

  - a matrix of RGB values with one row per selected segment

  - a vector (or list) of colours named by segment ID

- layer:

  If `x` is a scene: name or position of the segmentation layer. Can be
  omitted if the scene has only one segmentation layer.

## Value

The modified layer or scene. Existing colours of other segments are
kept.

## Examples

``` r
seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:3)
seg <- ngs_set_colors(seg, "red")
seg <- ngs_set_colors(seg, c("1" = "blue"))
seg <- ngs_set_colors(seg, c(0, 1, 0))
seg$segmentColors
#> $`1`
#> [1] "#00ff00"
#> 
#> $`2`
#> [1] "#00ff00"
#> 
#> $`3`
#> [1] "#00ff00"
#> 

# Scenes work too
sc <- ngs_scene(seg, ngs_segmentation_layer("precomputed://gs://y/seg",
                                            name = "other"))
sc <- ngs_set_colors(sc, "white", layer = "segmentation")
```
