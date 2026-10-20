# Create a scene

A scene is a neuroglancer state: a named list with class `ngs_scene`.
Top-level fields (e.g. `layout`, `position`) can be read and set with
`$` and `[[`, and `x$layers` is the list of layers. Use
[`ngs_add_layers()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_add_layers.md),
[`ngs_drop_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layer-management.md),
[`ngs_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layer-management.md)
etc. to manage layers.

## Usage

``` r
ngs_scene(..., base_url = DEFAULT_BASE_URL)
```

## Arguments

- ...:

  Layers to add and/or named top-level fields of the state (e.g.
  `layout = "3d"`).

- base_url:

  URL of the neuroglancer instance (host or page) used by
  [`ngs_url()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md).

## Value

A scene.

## Details

Scenes can be combined with `+` (adds all layers of the second scene)
and `|` (merges layers with the same source, e.g. combines the selected
segments of segmentation layers, and adds the others).

Note that JSON arrays with mixed types must be lists, e.g.
`dimensions = list(x = list(8e-9, "m"), ...)`.

## Examples

``` r
sc <- ngs_scene(
  ngs_image_layer("precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe"),
  ngs_segmentation_layer("precomputed://gs://fafb-ffn1-20200412/segmentation"),
  layout = "3d"
)
sc
#> <ngs_scene> 2 layers: 1 image, 1 segmentation
#> Base URL: https://neuroglancer-demo.appspot.com/
#> 1: <image layer> "img" precomputed://gs://neurogla...ata/fafb_v14/fafb_v14_clahe
#> 2: <segmentation layer> "segmentation" precomputed:...segmentation (0 segments)
sc$layout <- "xy-3d"
ngs_url(sc)
#> [1] "https://neuroglancer-demo.appspot.com/#!%7B%22layers%22%3A%5B%7B%22blend%22%3A%22default%22%2C%22name%22%3A%22img%22%2C%22shaderControls%22%3A%7B%7D%2C%22source%22%3A%22precomputed%3A//gs%3A//neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe%22%2C%22type%22%3A%22image%22%7D%2C%7B%22name%22%3A%22segmentation%22%2C%22segments%22%3A%5B%5D%2C%22selectedAlpha%22%3A0.14%2C%22source%22%3A%22precomputed%3A//gs%3A//fafb-ffn1-20200412/segmentation%22%2C%22type%22%3A%22segmentation%22%7D%5D%2C%22layout%22%3A%22xy-3d%22%7D"
```
