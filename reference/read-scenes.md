# Read scenes

Parse a scene from a neuroglancer URL, a JSON string, a state list, a
JSON file, the clipboard or a data frame of segments.

## Usage

``` r
ngs_from_string(x, skip_archived = FALSE, base_url = NULL)

ngs_from_url(url, skip_archived = FALSE, base_url = NULL)

ngs_from_list(x, base_url = NULL)

ngs_from_file(path, base_url = NULL)

ngs_from_clipboard(base_url = NULL)
```

## Arguments

- x:

  A URL, a JSON string or a state (named list).

- skip_archived:

  If `TRUE`, drop archived layers.

- base_url:

  URL of the neuroglancer instance used by
  [`ngs_url()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md).
  If not given and the input is a URL, its base is used.

- url:

  A neuroglancer URL.

- path:

  Path to a JSON file.

## Value

A scene.

## Details

URLs pointing to a state server are supported: `?json_url=...`,
`#!gs://...`, `#!https://...` and `#!middleauth+https://...` links are
fetched. CAVE state servers (e.g. FlyWire's) require a token, see
[`ngs_cave_token()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_cave_token.md).

Layers are kept exactly as written, so parsing and writing a scene
round-trips it unchanged. Neuroglancer also accepts `layers` as a
`{name: layer}` map; these are converted to a list.

## Examples

``` r
sc <- ngs_from_string('{"layout": "3d", "layers": [{"type": "image",
  "source": "precomputed://gs://x/em", "name": "em"}]}')
sc
#> <ngs_scene> 1 layer: 1 image
#> Base URL: https://neuroglancer-demo.appspot.com/
#> 1: <image layer> "em" precomputed://gs://x/em
sc2 <- ngs_from_url(ngs_url(sc))
if (FALSE) { # \dontrun{
ngs_from_clipboard()
} # }
```
