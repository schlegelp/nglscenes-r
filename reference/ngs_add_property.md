# Add a segment property

Add a segment property

## Usage

``` r
ngs_add_property(x, values, name, type = NULL, description = NULL)
```

## Arguments

- x:

  Segment properties.

- values:

  Property values, one per segment. Unless `type` is given, the type is
  inferred from the values:

  - numbers become `"number"` properties

  - the first character vector becomes the `"label"` property,
    subsequent ones `"string"` properties

  - factors and lists (e.g. `list(c("a", "b"), "c")`) become `"tags"`
    properties. Tags are made valid by removing leading `#` and
    replacing spaces with `_`.

- name:

  Name (ID) of the property.

- type:

  One of `"label"`, `"description"`, `"string"`, `"tags"` or `"number"`.
  Default is to infer the type from `values`.

- description:

  Optional description of the property.

## Value

The modified segment properties.

## Examples

``` r
props <- ngs_segment_properties(c("1", "2"))
props <- ngs_add_property(props, c("PN", "KC"), name = "type")
props <- ngs_add_property(props, list(c("left", "olfactory"), "right"),
                          name = "tags")
```
