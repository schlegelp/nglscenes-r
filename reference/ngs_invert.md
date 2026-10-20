# Invert segment selection

Selects the segments matching the layer's segment query (`segmentQuery`)
that are currently not selected, and deselects all others.

## Usage

``` r
ngs_invert(x, layer = NULL)
```

## Arguments

- x:

  A segmentation layer or a scene.

- layer:

  If `x` is a scene: name or position of the segmentation layer. Can be
  omitted if the scene has only one segmentation layer.

## Value

The modified layer or scene.
