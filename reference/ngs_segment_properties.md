# Segment properties

Create neuroglancer segment properties, e.g. to label segments or to
make them searchable by tags. Start with `ngs_segment_properties()` and
add properties with
[`ngs_add_property()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_add_property.md),
or create them from a data frame with `ngs_properties_from_df()`. Write
them to an info file with
[`ngs_write_info()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_write_info.md)
and convert them back with
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

## Usage

``` r
ngs_segment_properties(ids)

ngs_properties_from_df(df, id_col = "id")

ngs_properties_from_url(url)

ngs_properties_from_list(x)
```

## Arguments

- ids:

  Segment IDs. Must be unique.

- df:

  A data frame with segment IDs and one column per property. See
  [`ngs_add_property()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_add_property.md)
  for how column types are interpreted.

- id_col:

  Name of the column in `df` with the segment IDs.

- url:

  URL of a segment properties info file, or of a segmentation source
  whose info file points to segment properties. `precomputed://` and
  `gs://` URLs are supported.

- x:

  An info file parsed into a list.

## Value

Segment properties.

## Examples

``` r
df <- data.frame(id = c(1, 2, 3),
                 name = c("DA1_lPN", "DA1_lPN", "KCg"),
                 size = c(10.5, 12, 3),
                 class = factor(c("PN", "PN", "KC")))
props <- ngs_properties_from_df(df)
props
#> <ngs_segment_properties> 3 segments, 3 properties
#>   name (label)
#>   size (number)
#>   class (tags)
as.data.frame(props)
#>   id    name size class
#> 1  1 DA1_lPN 10.5    PN
#> 2  2 DA1_lPN 12.0    PN
#> 3  3     KCg  3.0    KC
cat(ngs_to_json(props, pretty = TRUE))
#> {
#>     "@type": "neuroglancer_segment_properties",
#>     "inline": {
#>         "ids": [
#>             "1",
#>             "2",
#>             "3"
#>         ],
#>         "properties": [
#>             {
#>                 "id": "name",
#>                 "type": "label",
#>                 "values": [
#>                     "DA1_lPN",
#>                     "DA1_lPN",
#>                     "KCg"
#>                 ]
#>             },
#>             {
#>                 "data_type": "float32",
#>                 "id": "size",
#>                 "type": "number",
#>                 "values": [
#>                     10.5,
#>                     12,
#>                     3
#>                 ]
#>             },
#>             {
#>                 "id": "class",
#>                 "tags": [
#>                     "KC",
#>                     "PN"
#>                 ],
#>                 "type": "tags",
#>                 "values": [
#>                     [
#>                         1
#>                     ],
#>                     [
#>                         1
#>                     ],
#>                     [
#>                         0
#>                     ]
#>                 ]
#>             }
#>         ]
#>     }
#> }
```
