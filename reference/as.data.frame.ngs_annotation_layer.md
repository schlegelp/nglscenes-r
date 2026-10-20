# Point annotations as data frame

Point annotations as data frame

## Usage

``` r
# S3 method for class 'ngs_annotation_layer'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  An annotation layer.

- row.names, optional, ...:

  Ignored.

## Value

A data frame with `id`, `x`, `y` and `z` columns. Annotations that are
not points are dropped with a warning.
