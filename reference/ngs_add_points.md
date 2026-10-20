# Add point annotations

Add point annotations

## Usage

``` r
ngs_add_points(x, points, ids = NULL, layer = NULL)
```

## Arguments

- x:

  An annotation layer or a scene.

- points:

  The points to add. Either a data frame with `x`, `y` and `z` columns
  (and optionally an `id` column), a matrix with three columns or a
  single numeric vector of length 3.

- ids:

  Optional IDs for the points. If not given (and not in `points`), the
  points are numbered consecutively.

- layer:

  If `x` is a scene: name or position of the annotation layer. Can be
  omitted if the scene has only one annotation layer.

## Value

The modified layer or scene.

## Examples

``` r
an <- ngs_annotation_layer()
an <- ngs_add_points(an, data.frame(x = 1:3, y = 4:6, z = 7:9))
an <- ngs_add_points(an, c(10, 20, 30))
as.data.frame(an)
#>   id  x  y  z
#> 1  0  1  4  7
#> 2  1  2  5  8
#> 3  2  3  6  9
#> 4  3 10 20 30

sc <- ngs_scene(ngs_image_layer("precomputed://gs://x/em"), an)
sc <- ngs_add_points(sc, c(1, 2, 3))
```
