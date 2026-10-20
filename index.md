# nglscenes

Generate and manipulate
[neuroglancer](https://github.com/google/neuroglancer) scenes from R.
This is an R port of the core of the Python package
[nglscenes](https://github.com/schlegelp/nglscenes).

## Features

- read scenes from URLs (including state servers such as CAVE’s), JSON
  strings, files or the clipboard
- construct and manipulate layers, segments, colours and annotations
- combine and merge scenes
- convert graphene (CAVE) layers between neuroglancer flavours (mainline
  / Spelunker vs. Seung-lab)
- write scenes to URLs, JSON, files or the clipboard
- create segment properties

Scenes round-trip unchanged: parsing a scene and writing it back gives
the same state (and the same JSON as the Python package).

## Install

``` r

# install.packages("remotes")
remotes::install_github("schlegelp/nglscenes-r")
```

## Usage

Scenes and layers are plain R lists (the JSON state) with a class
attached. All functions return modified copies, so they work well with
pipes.

### Construct a scene

``` r

library(nglscenes)

sc <- ngs_scene(
  ngs_image_layer("precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe"),
  ngs_segmentation_layer("precomputed://gs://fafb-ffn1-20200412/segmentation",
                         segments = c("710435991", "720575940621039145")),
  ngs_annotation_layer("precomputed://gs://neuroglancer-20191211_fafbv14_buhmann2019_li20190805"),
  layout = "3d"
)
sc
#> <ngs_scene> 3 layers: 1 image, 1 segmentation, 1 annotation
#> Base URL: https://neuroglancer-demo.appspot.com/
#> 1: <image layer> "img" precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe
#> 2: <segmentation layer> "segmentation" precomputed://gs://fafb-ffn1-20200412/segmentation (2 segments)
#> 3: <annotation layer> "annotations" precomputed://gs://neuroglancer-20191211_fafbv14_buhmann2019_li20190805

ngs_url(sc)     # URL with the state encoded
ngs_open(sc)    # open in the browser
ngs_to_clipboard(sc)
```

### Manipulate a scene

``` r

sc <- ngs_from_clipboard()   # or ngs_from_url(url), ngs_from_file(path), ...

# Top-level fields
sc$layout <- "xy-3d"
sc$position <- c(109357, 41309, 5417)

# Layers by name or (1-based) position
ngs_layer_names(sc)
ngs_layer(sc, 1)$visible <- FALSE

sc <- sc |>
  ngs_drop_layer("annotations") |>
  ngs_move_layer("segmentation", 1)

# Helpers work on layers and on scenes: with a scene, `layer` picks the
# layer (or is omitted if there is only one layer of the right type)
sc <- sc |>
  ngs_add_segments(c("12345", "67890"), layer = "segmentation") |>
  ngs_color_by(c("A", "B", "A", "B"), palette = "Okabe-Ito",
               layer = "segmentation")
```

Segment IDs are 64-bit integers, which R can’t represent as numbers.
They are always stored as character: numbers (or
[`bit64::integer64`](https://bit64.r-lib.org/reference/bit64-package.html))
are converted when set.

### Combine scenes

``` r

# `+` adds all layers of the second scene
comb <- sc1 + sc2

# `|` merges layers with the same source (e.g. combines selected segments)
merged <- sc1 | sc2
```

### Graphene (CAVE) layers

``` r

fw <- ngs_scene(ngs_flywire_layer(segments = "720575940621039145"),
                base_url = "https://spelunker.cave-explorer.org/")

# Convert for the Seung-lab flavour of neuroglancer (e.g. ngl.flywire.ai)
fw2 <- ngs_for_viewer(fw, "seunglab")
ngs_base_url(fw2) <- "https://ngl.flywire.ai/"
```

Scenes stored on CAVE state servers need a token, see
[`?ngs_cave_token`](https://schlegelp.github.io/nglscenes-r/reference/ngs_cave_token.md).

### Segment properties

``` r

df <- data.frame(id = c(1, 2, 3),
                 name = c("DA1_lPN", "DA1_lPN", "KCg"),
                 size = c(10.5, 12, 3),
                 class = factor(c("PN", "PN", "KC")))
props <- ngs_properties_from_df(df)
ngs_write_info(props, "segment_properties/info")
```

## Differences to the Python package

- Copy-on-modify instead of in-place modification:
  `sc <- ngs_add_layers(sc, layer)`.
- Layers are indexed from 1. Use names or positions; negative indices
  are not supported.
- `LocalScene` (live sync with a local neuroglancer server) and the
  local data server are not ported.
