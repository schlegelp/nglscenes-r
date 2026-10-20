# Get, replace or remove layers

Layers can be referred to by their (1-based) position or by name.

## Usage

``` r
ngs_layer_names(x)

ngs_layer(x, which)

ngs_layer(x, which) <- value

ngs_drop_layer(x, which)

ngs_move_layer(x, which, index)
```

## Arguments

- x:

  A scene.

- which:

  Position (integer) or name (string) of the layer. For
  `ngs_drop_layer()`, can also be a vector of positions or names.

- value:

  A layer.

- index:

  The new position of the layer.

## Value

`ngs_layer()` returns a layer, `ngs_layer_names()` a character vector
and the others the modified scene.

## Details

`ngs_layer()` and its replacement form also make it easy to modify a
layer in place, e.g. `ngs_layer(sc, "segmentation")$segments <- ids`.

## Examples

``` r
sc <- ngs_scene(
  ngs_image_layer("precomputed://gs://x/em", name = "em"),
  ngs_segmentation_layer("precomputed://gs://x/seg", name = "seg")
)
ngs_layer(sc, "seg")
#> <segmentation layer> "seg" precomputed://gs://x/seg (0 segments)
ngs_layer(sc, "seg")$segments <- c("1", "2")
sc <- ngs_move_layer(sc, "seg", 1)
ngs_layer_names(sc)
#> [1] "seg" "em" 
sc <- ngs_drop_layer(sc, "em")
```
