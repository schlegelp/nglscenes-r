# Graphene segmentation layers

Segmentation layers for graphene (CAVE chunkedgraph) sources such as
FlyWire. Constructed layers are set up for mainline neuroglancer and
Spelunker (type `"segmentation"` with a `"graphene://middleauth+"`
source). Use
[`ngs_as_flavour()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_as_flavour.md)
or
[`ngs_for_viewer()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_as_flavour.md)
to convert them for other neuroglancer flavours.

## Usage

``` r
ngs_graphene_layer(source, name = "segmentation", ...)

ngs_flywire_layer(name = "flywire_production", ...)

ngs_fanc_layer(name = "fanc", ...)
```

## Arguments

- source:

  A graphene source (`"graphene://..."`), see
  [layers](https://schlegelp.github.io/nglscenes-r/reference/layers.md).

- name:

  The layer name. Names are made unique when the layer is added to a
  scene.

- ...:

  Further fields of the layer state, e.g. `segments`, `visible = FALSE`
  or `shader`.

## Value

A graphene layer, which is also a segmentation layer.

## Details

`ngs_flywire_layer()` and `ngs_fanc_layer()` are shortcuts for the
FlyWire production and FANC segmentations.

## Examples

``` r
fw <- ngs_graphene_layer(
  "graphene://https://prod.flywire-daf.com/segmentation/1.0/flywire_public",
  segments = "720575940621039145"
)
fw$source
#> [1] "graphene://middleauth+https://prod.flywire-daf.com/segmentation/1.0/flywire_public"
```
