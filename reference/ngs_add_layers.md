# Add layers to a scene

Layer names must be unique within a scene. If a name is already taken, a
suffix is added (e.g. `"segmentation-2"`).

## Usage

``` r
ngs_add_layers(x, ..., index = NULL)
```

## Arguments

- x:

  A scene.

- ...:

  Layers to add, or lists of layers.

- index:

  Position at which to insert the layers. Default is to append.

## Value

The modified scene.

## Examples

``` r
sc <- ngs_scene()
sc <- ngs_add_layers(sc, ngs_segmentation_layer("precomputed://gs://x/seg"),
                     ngs_segmentation_layer("precomputed://gs://y/seg"))
ngs_layer_names(sc)
#> [1] "segmentation"   "segmentation-2"
```
