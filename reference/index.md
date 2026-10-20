# Package index

## Scenes

Create scenes and manage their layers.

- [`ngs_scene()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_scene.md)
  : Create a scene
- [`ngs_add_layers()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_add_layers.md)
  : Add layers to a scene
- [`ngs_layer_names()`](https://schlegelp.github.io/nglscenes-r/reference/layer-management.md)
  [`ngs_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layer-management.md)
  [`` `ngs_layer<-`() ``](https://schlegelp.github.io/nglscenes-r/reference/layer-management.md)
  [`ngs_drop_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layer-management.md)
  [`ngs_move_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layer-management.md)
  : Get, replace or remove layers
- [`ngs_base_url()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_base_url.md)
  [`` `ngs_base_url<-`() ``](https://schlegelp.github.io/nglscenes-r/reference/ngs_base_url.md)
  : Base URL of a scene

## Reading and writing scenes

- [`ngs_from_string()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)
  [`ngs_from_url()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)
  [`ngs_from_list()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)
  [`ngs_from_file()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)
  [`ngs_from_clipboard()`](https://schlegelp.github.io/nglscenes-r/reference/read-scenes.md)
  : Read scenes
- [`ngs_from_df()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_from_df.md)
  : Create a scene from a data frame of segments
- [`ngs_url()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
  [`ngs_to_json()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
  [`ngs_to_file()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
  [`ngs_to_clipboard()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
  [`ngs_open()`](https://schlegelp.github.io/nglscenes-r/reference/write-scenes.md)
  : Write scenes
- [`ngs_cave_token()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_cave_token.md)
  : Get a CAVE token

## Layers

- [`ngs_image_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layers.md)
  [`ngs_segmentation_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layers.md)
  [`ngs_annotation_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layers.md)
  [`ngs_mesh_layer()`](https://schlegelp.github.io/nglscenes-r/reference/layers.md)
  : Create layers
- [`ngs_parse_layers()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_parse_layers.md)
  : Parse layer states into layers
- [`ngs_add_source()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_add_source.md)
  : Add a source to a layer

## Segmentation layers

These helpers accept a segmentation layer or a scene. For scenes, use
`layer` to pick the layer.

- [`ngs_segments()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_segments.md)
  [`ngs_add_segments()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_segments.md)
  [`ngs_remove_segments()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_segments.md)
  : Selected segments
- [`ngs_set_colors()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_set_colors.md)
  : Set segment colours
- [`ngs_color_by()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_color_by.md)
  : Colour segments by a property
- [`ngs_clear_colors()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_clear_colors.md)
  : Clear segment colours
- [`ngs_invert()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_invert.md)
  : Invert segment selection

## Graphene (CAVE) layers

- [`ngs_graphene_layer()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_graphene_layer.md)
  [`ngs_flywire_layer()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_graphene_layer.md)
  [`ngs_fanc_layer()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_graphene_layer.md)
  : Graphene segmentation layers
- [`ngs_as_flavour()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_as_flavour.md)
  [`ngs_flavour()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_as_flavour.md)
  [`ngs_for_viewer()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_as_flavour.md)
  : Convert graphene layers between neuroglancer flavours

## Annotation layers

- [`ngs_add_points()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_add_points.md)
  : Add point annotations
- [`ngs_clear_annotations()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_clear_annotations.md)
  : Remove all annotations
- [`as.data.frame(`*`<ngs_annotation_layer>`*`)`](https://schlegelp.github.io/nglscenes-r/reference/as.data.frame.ngs_annotation_layer.md)
  : Point annotations as data frame

## Segment properties

- [`ngs_segment_properties()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_segment_properties.md)
  [`ngs_properties_from_df()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_segment_properties.md)
  [`ngs_properties_from_url()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_segment_properties.md)
  [`ngs_properties_from_list()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_segment_properties.md)
  : Segment properties
- [`ngs_add_property()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_add_property.md)
  : Add a segment property
- [`ngs_property_types()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_property_types.md)
  : Property types
- [`ngs_write_info()`](https://schlegelp.github.io/nglscenes-r/reference/ngs_write_info.md)
  : Write segment properties to an info file

## Example scenes

- [`ngs_hemibrain_scene()`](https://schlegelp.github.io/nglscenes-r/reference/example-scenes.md)
  [`ngs_manc_scene()`](https://schlegelp.github.io/nglscenes-r/reference/example-scenes.md)
  : Example scenes
