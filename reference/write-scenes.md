# Write scenes

`ngs_url()` generates a neuroglancer URL with the state encoded in it,
`ngs_to_json()` the JSON string. `ngs_to_file()` and
`ngs_to_clipboard()` write those to a file or the clipboard, and
`ngs_open()` opens the scene in the browser. Use
[`as.list()`](https://rdrr.io/r/base/list.html) to get the state as a
plain list.

## Usage

``` r
ngs_url(x)

ngs_to_json(x, pretty = FALSE)

ngs_to_file(x, path)

ngs_to_clipboard(x, json = FALSE)

ngs_open(x)
```

## Arguments

- x:

  A scene. `ngs_to_json()` also accepts layers and segment properties.

- pretty:

  If `TRUE`, indent the JSON.

- path:

  Path of the file to write.

- json:

  If `TRUE`, copy the JSON state instead of the URL.

## Value

`ngs_url()` and `ngs_to_json()` return a string, the others return `x`
invisibly.

## Examples

``` r
sc <- ngs_scene(ngs_image_layer("precomputed://gs://x/em"), layout = "3d")
ngs_url(sc)
#> [1] "https://neuroglancer-demo.appspot.com/#!%7B%22layers%22%3A%5B%7B%22blend%22%3A%22default%22%2C%22name%22%3A%22img%22%2C%22shaderControls%22%3A%7B%7D%2C%22source%22%3A%22precomputed%3A//gs%3A//x/em%22%2C%22type%22%3A%22image%22%7D%5D%2C%22layout%22%3A%223d%22%7D"
cat(ngs_to_json(sc, pretty = TRUE))
#> {
#>     "layers": [
#>         {
#>             "blend": "default",
#>             "name": "img",
#>             "shaderControls": {},
#>             "source": "precomputed://gs://x/em",
#>             "type": "image"
#>         }
#>     ],
#>     "layout": "3d"
#> }
if (FALSE) { # \dontrun{
ngs_open(sc)
} # }
```
