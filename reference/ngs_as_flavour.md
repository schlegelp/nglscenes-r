# Convert graphene layers between neuroglancer flavours

The neuroglancer families spell CAVE chunkedgraph layers differently and
each refuses the other's spelling:

## Usage

``` r
ngs_as_flavour(x, flavour)

ngs_flavour(x)

ngs_for_viewer(x, flavour)
```

## Arguments

- x:

  A graphene layer (for `ngs_as_flavour()`, `ngs_flavour()`) or a scene
  (for `ngs_for_viewer()`).

- flavour:

  One of `"mainline"`, `"spelunker"` or `"seunglab"`.

## Value

The converted layer or scene.

## Details

- `"mainline"` and `"spelunker"` (e.g. ngl.cave-explorer.org) use type
  `"segmentation"` with a `"graphene://middleauth+"` source

- `"seunglab"` (e.g. ngl.flywire.ai) uses type
  `"segmentation_with_graph"` with a bare `"graphene://"` source

`ngs_as_flavour()` converts a single graphene layer, `ngs_for_viewer()`
converts all graphene layers in a scene and leaves other layers
untouched. `ngs_flavour()` returns the flavour a graphene layer is
written for.

## Examples

``` r
sc <- ngs_scene(ngs_flywire_layer())
sc2 <- ngs_for_viewer(sc, "seunglab")
sc2$layers[[1]]$type
#> [1] "segmentation_with_graph"
```
