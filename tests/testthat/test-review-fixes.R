# Regression tests for issues found in code review

test_that("big integers round-trip as numbers", {
  json <- paste0('{"a":"no 12345678901234567 change","b":9007199254740993,',
                 '"c":[1,-720575940621039145],',
                 '"layers":[{"name":"s","segments":[720575940621039145],',
                 '"source":"precomputed://x","type":"segmentation"}]}')
  sc <- ngs_from_string(json)
  expect_identical(ngs_to_json(sc), json)
  # Long fractions are not mistaken for big integers
  expect_type(nglscenes:::parse_json_state('{"d":0.12345678901234567}')$d, "double")
  # The IDs are still usable
  expect_identical(ngs_segments(sc), "720575940621039145")
  sc <- ngs_add_segments(sc, "1")
  expect_identical(ngs_segments(sc), c("720575940621039145", "1"))
})

test_that("dropping no layers keeps all layers", {
  sc <- ngs_scene(ngs_image_layer("precomputed://x/em"),
                  ngs_mesh_layer("precomputed://x/mesh"))
  expect_length(ngs_drop_layer(sc, character(0))$layers, 2)
})

test_that("empty objects in arrays stay objects", {
  json <- '{"x":[{},{}],"z":[[],{}]}'
  expect_identical(nglscenes:::to_json(nglscenes:::parse_json_state(json)), json)
})

test_that("local annotation layers without source can be parsed", {
  state <- state_of(list(type = "annotation", name = "a", annotations = list(),
                         tool = "annotatePoint"))
  sc <- ngs_from_list(state)
  expect_s3_class(sc$layers[[1]], "ngs_annotation_layer")
  expect_same_state(sc, state)
})

test_that("NA colours error", {
  seg <- ngs_segmentation_layer("precomputed://x/seg", segments = 1:2)
  expect_error(ngs_set_colors(seg, c("red", NA)), "must not be NA")
  expect_error(ngs_color_by(seg, c("a", NA)), "must not contain NAs")
})

test_that("default annotation IDs don't collide", {
  an <- ngs_annotation_layer()
  an <- ngs_add_points(an, c(1, 2, 3), ids = "1")
  an <- ngs_add_points(an, rbind(c(4, 5, 6), c(7, 8, 9)))
  expect_identical(as.data.frame(an)$id, c("1", "0", "2"))
})

test_that("segmentation layers with graphene sources are graphene layers", {
  for (source in c("graphene://middleauth+https://x/seg", "graphene://https://x/seg")) {
    layer <- ngs_segmentation_layer(source, segments = "1")
    expect_s3_class(layer, "ngs_graphene_layer")
    # Set up for mainline neuroglancer, like ngs_graphene_layer()
    expect_identical(layer$source, "graphene://middleauth+https://x/seg")
    expect_identical(ngs_flavour(layer), "mainline")
    expect_identical(layer$segments, "1")
  }
})

test_that("merging keeps segment colours", {
  a <- ngs_scene(ngs_segmentation_layer("precomputed://x", segments = "1",
                                        segmentColors = c("1" = "blue")))
  b <- ngs_scene(ngs_segmentation_layer("precomputed://x", segments = "2",
                                        segmentColors = c("2" = "red")))
  expect_identical(unlist((a | b)$layers[[1]]$segmentColors),
                   c("1" = "#0000ff", "2" = "#ff0000"))
})

test_that("factor sources work in ngs_from_df", {
  df <- data.frame(id = c("1", "2"),
                   source = factor(c("precomputed://x", "graphene://middleauth+https://y")))
  sc <- ngs_from_df(df)
  expect_length(sc$layers, 2)
  expect_s3_class(sc$layers[[1]], "ngs_graphene_layer")
})
