# Create layers

Constructors for the different types of neuroglancer layers. Each layer
is its JSON state (a named list) with a class attached, so fields can be
read and set with `$` and `[[`, e.g. `layer$visible <- FALSE`. Setting
the `segments`, `segmentColors` or `segmentDefaultColor` fields of a
segmentation layer normalises their values: segment IDs are stored as
character and colours as hex codes.

## Usage

``` r
ngs_image_layer(source, name = "img", ...)

ngs_segmentation_layer(source, name = "segmentation", ...)

ngs_annotation_layer(source = "local://annotations", name = "annotations", ...)

ngs_mesh_layer(source, name = "meshes", ...)
```

## Arguments

- source:

  The data source: a URL string (e.g.
  `"precomputed://gs://bucket/path"`), a list with a `url` field and
  further options (e.g. `subsources`), or an unnamed list of either.

- name:

  The layer name. Names are made unique when the layer is added to a
  scene.

- ...:

  Further fields of the layer state, e.g. `segments`, `visible = FALSE`
  or `shader`.

## Value

A layer object.

## Details

Constructed layers get a few default fields (e.g. `selectedAlpha` for
segmentation layers). `ngs_segmentation_layer()` with a graphene source
returns a graphene layer (see
[`ngs_graphene_layer()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_graphene_layer.md)).
Layers parsed from an existing scene are kept exactly as written.

Note that, as with any list in R, setting a field to `NULL` removes it.
Use `NA` to write an explicit JSON `null`.

## Examples

``` r
img <- ngs_image_layer("precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe")
seg <- ngs_segmentation_layer("precomputed://gs://fafb-ffn1-20200412/segmentation",
                              segments = c(710435991, 710435992))
seg$segments
#> [1] "710435991" "710435992"
seg$segments <- c(seg$segments, "123456")
an <- ngs_annotation_layer()
```
