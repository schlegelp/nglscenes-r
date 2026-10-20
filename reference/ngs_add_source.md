# Add a source to a layer

Add a source to a layer

## Usage

``` r
ngs_add_source(x, source, layer = NULL)
```

## Arguments

- x:

  A layer or a scene.

- source:

  The source to add (e.g. a skeleton source).

- layer:

  If `x` is a scene: name or position of the layer. Can be omitted if
  the scene has only one layer.

## Value

The modified layer or scene.

## Examples

``` r
seg <- ngs_segmentation_layer("precomputed://gs://x/seg")
seg <- ngs_add_source(seg, "precomputed://gs://x/skeletons")
seg$source
#> [[1]]
#> [1] "precomputed://gs://x/seg"
#> 
#> [[2]]
#> [1] "precomputed://gs://x/skeletons"
#> 
```
