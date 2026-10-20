# Create a scene from a data frame of segments

Create a scene from a data frame of segments

## Usage

``` r
ngs_from_df(df, layer_col = NULL, color_col = NULL, ...)
```

## Arguments

- df:

  A data frame with an `id` (or `segment_id`) column with segment IDs
  and a `source` column with the segmentation sources. Each source gets
  its own layer.

- layer_col:

  Optional name of a column to further split segments into layers by.
  Layers are named by its values.

- color_col:

  Optional name of a column with colours for the segments.

- ...:

  Passed to
  [`ngs_scene()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_scene.md),
  e.g. other layers or `base_url`.

## Value

A scene.

## Examples

``` r
df <- data.frame(id = c("1", "2", "3"),
                 source = "precomputed://gs://x/seg",
                 type = c("A", "B", "A"),
                 color = c("red", "blue", "red"))
ngs_from_df(df, layer_col = "type", color_col = "color")
#> <ngs_scene> 2 layers: 2 segmentation
#> Base URL: https://neuroglancer-demo.appspot.com/
#> 1: <segmentation layer> "A" precomputed://gs://x/seg (2 segments)
#> 2: <segmentation layer> "B" precomputed://gs://x/seg (1 segment)
```
