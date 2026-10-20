# Port of nglscenes' tests/test_base.py

constructors <- list(ngs_image_layer, ngs_segmentation_layer, ngs_mesh_layer,
                     ngs_annotation_layer)

test_that("layers can be constructed", {
  for (f in constructors) {
    layer <- f(source = "precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe",
               name = "fafb_v14_clahe")
    expect_s3_class(layer, "ngs_layer")
    expect_type(format(layer), "character")
    expect_type(as.list(layer), "list")
    expect_null(oldClass(as.list(layer)))
    expect_identical(layer$name, "fafb_v14_clahe")
  }
})

test_that("empty scene", {
  sc <- ngs_scene()
  expect_type(ngs_url(sc), "character")
  expect_output(print(sc), "0 layers")
  expect_identical(ngs_to_json(sc), '{"layers":[]}')
})

test_that("full scene", {
  sc <- ngs_scene()
  sc <- ngs_add_layers(sc, ngs_image_layer(
    "precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe",
    name = "fafb_v14_clahe"
  ))
  sc <- ngs_add_layers(sc, ngs_segmentation_layer(
    list(url = "precomputed://gs://fafb-ffn1-20200412/segmentation",
         subsources = list(default = TRUE, bounds = TRUE, mesh = TRUE,
                           skeletons = TRUE),
         enableDefaultSubsources = FALSE),
    name = "fafb-ffn1-20200412",
    segments = "710435991"
  ))
  sc <- ngs_add_layers(sc, ngs_segmentation_layer(
    "precomputed://gs://neuroglancer-20191211_fafbv14_buhmann2019_li20190805",
    linkedSegmentationLayer = list(pre_segment = "fafb-ffn1-20200412",
                                   post_segment = "fafb-ffn1-20200412"),
    filterBySegmentation = c("post_segment", "pre_segment"),
    name = "synapses_buhmann2019"
  ))
  expect_length(sc$layers, 3)

  sc <- ngs_drop_layer(sc, "synapses_buhmann2019")
  expect_length(sc$layers, 2)

  # A single segment is still written as an array
  expect_match(ngs_to_json(sc), '"segments":["710435991"]', fixed = TRUE)
  expect_output(print(sc), "2 layers")
})

test_that("scene parsing", {
  sc <- ngs_from_string(TEST_URL)
  expect_length(sc$layers, 8)
  expect_identical(ngs_base_url(sc),
                   "https://fafb-dot-neuroglancer-demo.appspot.com/")
  expect_same_state(sc, url_state(TEST_URL))
  expect_same_state(ngs_from_url(ngs_url(sc)), sc)
})

test_that("scene combining", {
  sc1 <- ngs_from_string(TEST_URL)
  sc2 <- ngs_from_string(TEST_URL)

  sc3 <- sc1 + sc2
  expect_length(sc3$layers, 16)
  # Names are made unique
  expect_false(anyDuplicated(ngs_layer_names(sc3)) > 0)

  sc3 <- sc1 | sc2
  types <- vapply(sc1$layers, function(l) class(l)[1], character(1))
  not_comb <- !types %in% c("ngs_image_layer", "ngs_segmentation_layer")
  expect_length(sc3$layers, length(sc1$layers) + sum(not_comb))
})

test_that("merging combines segments", {
  src <- "precomputed://gs://x/seg"
  sc1 <- ngs_scene(ngs_segmentation_layer(src, segments = c("1", "2")))
  sc2 <- ngs_scene(ngs_segmentation_layer(src, segments = c("2", "3")),
                   ngs_segmentation_layer("precomputed://gs://y/seg"))
  merged <- sc1 | sc2
  expect_length(merged$layers, 2)
  expect_identical(ngs_segments(merged$layers[[1]]), c("1", "2", "3"))

  # Hidden segments are made visible rather than duplicated
  sc1 <- ngs_scene(ngs_segmentation_layer(src, segments = c("1", "!2")))
  expect_identical(ngs_segments((sc1 | sc2)$layers[[1]]), c("1", "2", "3"))
})

test_that("unsupported operators error", {
  expect_error(ngs_scene() - ngs_scene(), "not supported")
  expect_error(ngs_scene() + 1, "isn't a scene")
})
