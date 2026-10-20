# Get started with nglscenes

[Neuroglancer](https://github.com/google/neuroglancer) keeps everything
it shows (layers, selected segments, camera position, layout and so on)
in a JSON *state*, usually encoded in the URL. nglscenes reads, builds
and edits these states from R.

``` r

library(nglscenes)
```

## Scenes and layers are lists

A scene is the neuroglancer state as a named list with class
`ngs_scene`, and each layer is the layer’s state with a class such as
`ngs_segmentation_layer`. You can read and set fields with `$` and `[[`
like with any other list:

``` r

sc <- ngs_scene(
  ngs_image_layer("precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe",
                  name = "em"),
  ngs_segmentation_layer("precomputed://gs://fafb-ffn1-20200412/segmentation",
                         name = "ffn1", segments = c(710435991, 2803641208)),
  layout = "3d"
)
sc
#> <ngs_scene> 2 layers: 1 image, 1 segmentation
#> Base URL: https://neuroglancer-demo.appspot.com/
#> 1: <image layer> "em" precomputed://gs://neurogla...ata/fafb_v14/fafb_v14_clahe
#> 2: <segmentation layer> "ffn1" precomputed://gs...412/segmentation (2 segments)

sc$layout
#> [1] "3d"
sc$layout <- "xy-3d"
sc$position <- c(109357, 41309, 5417)
```

All functions return a modified copy rather than changing the scene in
place, so they work well with pipes.

## Writing scenes

[`ngs_url()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
encodes the state in a URL for the scene’s neuroglancer instance:

``` r

url <- ngs_url(sc)
substr(url, 1, 120)
#> [1] "https://neuroglancer-demo.appspot.com/#!%7B%22layers%22%3A%5B%7B%22blend%22%3A%22default%22%2C%22name%22%3A%22em%22%2C%2"
```

[`ngs_open()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
opens that URL in the browser,
[`ngs_to_clipboard()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
copies it, and
[`ngs_to_json()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
/
[`ngs_to_file()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
give you the JSON instead.

To use a different neuroglancer instance, change the base URL:

``` r

ngs_base_url(sc) <- "https://spelunker.cave-explorer.org/"
substr(ngs_url(sc), 1, 60)
#> [1] "https://spelunker.cave-explorer.org/#!%7B%22layers%22%3A%5B%"
```

## Reading scenes

Scenes can be read from URLs
([`ngs_from_url()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)),
JSON strings or state lists
([`ngs_from_string()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md),
[`ngs_from_list()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)),
files
([`ngs_from_file()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md))
and the clipboard
([`ngs_from_clipboard()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)).
URLs that point to a state server (`?json_url=...`, `#!gs://...`,
`#!middleauth+https://...`) are fetched automatically.

``` r

sc2 <- ngs_from_url(url)
sc2
#> <ngs_scene> 2 layers: 1 image, 1 segmentation
#> Base URL: https://neuroglancer-demo.appspot.com/
#> 1: <image layer> "em" precomputed://gs://neurogla...ata/fafb_v14/fafb_v14_clahe
#> 2: <segmentation layer> "ffn1" precomputed://gs...412/segmentation (2 segments)
```

Parsed scenes round-trip unchanged: writing a scene you have read gives
the same state back, including fields nglscenes doesn’t know about.

``` r

identical(ngs_to_json(sc2), ngs_to_json(ngs_from_url(ngs_url(sc2))))
#> [1] TRUE
```

## Managing layers

Layers are referred to by name or by (1-based) position:

``` r

ngs_layer_names(sc)
#> [1] "em"   "ffn1"

sc <- sc |>
  ngs_add_layers(ngs_annotation_layer(name = "points")) |>
  ngs_move_layer("points", 1)
ngs_layer_names(sc)
#> [1] "points" "em"     "ffn1"

ngs_layer(sc, "em")$visible <- FALSE
sc <- ngs_drop_layer(sc, "points")
```

Layer names must be unique within a scene: adding a layer whose name is
taken adds a suffix (e.g. `"ffn1-2"`).

## Segments and colours

Segment IDs are 64-bit integers, which R can’t represent exactly as
numbers. nglscenes therefore always stores them as character, and
converts numbers (or
[`bit64::integer64`](https://bit64.r-lib.org/reference/bit64-package.html)
values) when they are set:

``` r

ngs_segments(sc)
#> [1] "710435991"  "2803641208"
```

The helpers for segmentation layers accept a layer or a scene. With a
scene, `layer` picks the layer, or can be left out if there is only one
segmentation layer:

``` r

sc <- sc |>
  ngs_add_segments(c("2803641209", "2803641210")) |>
  ngs_color_by(c("KC", "PN", "PN", "KC"), palette = "Okabe-Ito")

unlist(ngs_layer(sc, "ffn1")$segmentColors)
#>  710435991 2803641208 2803641209 2803641210 
#>  "#000000"  "#e69f00"  "#e69f00"  "#000000"
```

[`ngs_set_colors()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_set_colors.md)
sets colours directly, from a single colour, one colour per segment or
colours named by segment ID:

``` r

sc <- ngs_set_colors(sc, c("710435991" = "red"), layer = "ffn1")
```

## Annotations

``` r

an <- ngs_annotation_layer(name = "somata") |>
  ngs_add_points(data.frame(id = c("a", "b"),
                            x = c(1000, 2000), y = c(500, 600), z = c(10, 20)))
as.data.frame(an)
#>   id    x   y  z
#> 1  a 1000 500 10
#> 2  b 2000 600 20
```

## Combining scenes

`+` adds all layers of the second scene to the first, and `|` merges
layers that share a source (e.g. combines the segments of two
segmentation layers) and adds the rest:

``` r

a <- ngs_scene(ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:2))
b <- ngs_scene(ngs_segmentation_layer("precomputed://gs://x/seg", segments = 2:3))

length((a + b)$layers)
#> [1] 2
ngs_segments(a | b)
#> [1] "1" "2" "3"
```

## Graphene (CAVE) layers

Mainline neuroglancer and Spelunker spell CAVE chunkedgraph layers
differently from the Seung-lab fork (e.g. ngl.flywire.ai), and each
refuses the other’s spelling.
[`ngs_for_viewer()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_as_flavour.md)
converts all graphene layers in a scene:

``` r

fw <- ngs_scene(ngs_flywire_layer(segments = "720575940621039145"))
fw$layers[[1]]$type
#> [1] "segmentation"

fw2 <- ngs_for_viewer(fw, "seunglab")
fw2$layers[[1]]$type
#> [1] "segmentation_with_graph"
fw2$layers[[1]]$source
#> [1] "graphene://https://prod.flywire-daf.com/segmentation/1.0/fly_v31"
```

Fetching scenes from CAVE state servers requires a token, see
[`?ngs_cave_token`](https://schlegelp.github.io/nglscenes-r/reference/ngs_cave_token.md).

## Segment properties

Segment properties add labels and searchable tags to segments. Create
them from a data frame and write them to an `info` file next to your
segmentation:

``` r

props <- ngs_properties_from_df(data.frame(
  id = c(1, 2, 3),
  name = c("DA1_lPN", "DA1_lPN", "KCg-m"),
  class = factor(c("PN", "PN", "KC")),
  size = c(10.5, 12, 3)
))
props
#> <ngs_segment_properties> 3 segments, 3 properties
#>   name (label)
#>   class (tags)
#>   size (number)
```

``` r

ngs_write_info(props, "segment_properties/info")
```
