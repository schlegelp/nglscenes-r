test_that("segment IDs are normalised", {
  seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:3)
  expect_identical(seg$segments, c("1", "2", "3"))

  seg[["segments"]] <- 720575940621039
  expect_identical(seg$segments, "720575940621039")

  # Mixed lists of IDs aren't garbled when flattened
  seg$segments <- list("1", 720575940621039)
  expect_identical(seg$segments, c("1", "720575940621039"))

  expect_warning(seg$segments <- 720575940621039145, "precision")
  expect_error(seg$segments <- 1.5, "whole numbers")

  skip_if_not_installed("bit64")
  seg$segments <- bit64::as.integer64("720575940621039145")
  expect_identical(seg$segments, "720575940621039145")
})

test_that("required fields are checked", {
  expect_error(ngs_parse_layers(list(type = "image", name = "x")),
               "requires a \"source\"")
  expect_error(ngs_image_layer("precomputed://gs://x/em", name = "x", 1),
               "must be named")
})

test_that("layers can be managed", {
  sc <- ngs_scene(ngs_image_layer("precomputed://gs://x/em", name = "em"),
                  ngs_segmentation_layer("precomputed://gs://x/seg", name = "seg"),
                  ngs_mesh_layer("precomputed://gs://x/mesh", name = "seg"))
  expect_identical(ngs_layer_names(sc), c("em", "seg", "seg-2"))

  expect_s3_class(ngs_layer(sc, "seg"), "ngs_segmentation_layer")
  expect_s3_class(ngs_layer(sc, 3), "ngs_mesh_layer")
  expect_error(ngs_layer(sc, "foo"), "No layer named")
  expect_error(ngs_layer(sc, 4), "scene has 3 layers")

  sc <- ngs_move_layer(sc, "seg-2", 1)
  expect_identical(ngs_layer_names(sc), c("seg-2", "em", "seg"))

  sc <- ngs_add_layers(sc, ngs_image_layer("precomputed://gs://y/em", name = "em2"),
                       index = 2)
  expect_identical(ngs_layer_names(sc), c("seg-2", "em2", "em", "seg"))

  sc <- ngs_drop_layer(sc, c("em", "seg"))
  expect_identical(ngs_layer_names(sc), c("seg-2", "em2"))

  expect_error(ngs_layer(sc, 1) <- list(), "must be a layer")
  expect_error(ngs_add_layers(sc, list(name = "x")), "Expected a layer")
})

test_that("colours can be set", {
  seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:3)

  seg <- ngs_set_colors(seg, "r")
  expect_identical(unlist(seg$segmentColors),
                   c("1" = "#ff0000", "2" = "#ff0000", "3" = "#ff0000"))

  seg <- ngs_set_colors(seg, c("2" = "blue"))
  expect_identical(seg$segmentColors[["2"]], "#0000ff")
  expect_identical(seg$segmentColors[["1"]], "#ff0000")

  seg <- ngs_set_colors(seg, c(0, 1, 0))
  expect_identical(seg$segmentColors[["3"]], "#00ff00")

  seg <- ngs_set_colors(seg, c("white", "black", "#123456"))
  expect_identical(unname(unlist(seg$segmentColors)),
                   c("#ffffff", "#000000", "#123456"))

  seg <- ngs_set_colors(seg, matrix(c(1, 0, 0, 0, 1, 0, 0, 0, 1), ncol = 3,
                                    byrow = TRUE))
  expect_identical(unname(unlist(seg$segmentColors)),
                   c("#ff0000", "#00ff00", "#0000ff"))

  # RGBA matrices work too (alpha is dropped)
  seg <- ngs_set_colors(seg, cbind(diag(3), 0.5))
  expect_identical(seg$segmentColors[["2"]], "#00ff00")
  expect_error(ngs_set_colors(seg, matrix(2, 3, 3)), "0-1 range")

  expect_error(ngs_set_colors(seg, c("red", "blue")), "2 colours for 3")
  expect_error(ngs_set_colors(seg, "notacolour"), "Invalid colour")
  expect_error(ngs_set_colors(seg, c(0, 2, 0)), "0-1 range")

  # Colours are written as a JSON object
  expect_match(ngs_to_json(seg), '"segmentColors":{"1":"#ff0000"', fixed = TRUE)

  seg <- ngs_clear_colors(seg)
  expect_null(seg$segmentColors)

  seg$segmentDefaultColor <- "red"
  expect_identical(seg$segmentDefaultColor, "#ff0000")
})

test_that("segments can be coloured by a property", {
  seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:4)
  seg <- ngs_color_by(seg, c("A", "B", "A", "C"))
  cols <- unlist(seg$segmentColors)
  expect_identical(cols[["1"]], cols[["3"]])
  expect_length(unique(cols), 3)

  seg <- ngs_color_by(seg, c("A", "B", "A", "B"), palette = c(A = "red", B = "blue"))
  expect_identical(unname(unlist(seg$segmentColors)),
                   c("#ff0000", "#0000ff", "#ff0000", "#0000ff"))

  seg <- ngs_color_by(seg, 1:4, palette = "viridis")
  expect_length(unique(unlist(seg$segmentColors)), 4)

  # Palette names ignore case and punctuation
  seg <- ngs_color_by(seg, c("A", "B", "A", "B"), palette = "Set1")
  expect_identical(unname(unlist(seg$segmentColors))[1:2], c("#e41a1c", "#377eb8"))

  expect_error(ngs_color_by(seg, 1:2), "2 values for 4")
  expect_error(ngs_color_by(seg, 1:4, palette = c("1" = "red")), "no colour")
  expect_error(ngs_color_by(seg, 1:4, palette = "nope"), "Unknown palette")
})

test_that("selection can be inverted", {
  seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = c("1", "2"),
                                segmentQuery = "1, 2, 3,4")
  expect_identical(ngs_invert(seg)$segments, c("3", "4"))
})

test_that("sources can be added", {
  seg <- ngs_segmentation_layer("precomputed://gs://x/seg")
  seg <- ngs_add_source(seg, "precomputed://gs://x/skel")
  expect_identical(seg$source, list("precomputed://gs://x/seg",
                                    "precomputed://gs://x/skel"))
  seg <- ngs_add_source(seg, "precomputed://gs://x/more")
  expect_length(seg$source, 3)
})

test_that("annotations can be added", {
  an <- ngs_annotation_layer()
  an <- ngs_add_points(an, data.frame(x = 1:2, y = 3:4, z = 5:6))
  an <- ngs_add_points(an, c(7, 8, 9))
  an <- ngs_add_points(an, data.frame(id = "foo", x = 1, y = 1, z = 1))

  df <- as.data.frame(an)
  expect_identical(df$id, c("0", "1", "2", "foo"))
  expect_identical(df$x, c(1, 2, 7, 1))
  expect_match(ngs_to_json(an), '"point":[1,3,5]', fixed = TRUE)

  expect_length(ngs_clear_annotations(an)$annotations, 0)
  expect_error(ngs_add_points(an, matrix(1:4, ncol = 2)), "Expected")

  an$annotations <- c(an$annotations, list(list(type = "line", id = "l")))
  expect_warning(as.data.frame(an), "not points")
})

test_that("data frames become scenes", {
  df <- data.frame(id = c(1, 2, 3, 4),
                   source = c("precomputed://gs://x/seg", "precomputed://gs://x/seg",
                              "precomputed://gs://x/seg", "precomputed://gs://y/seg"),
                   type = c("A", "B", "A", "A"),
                   color = c("red", "blue", "red", "green"))
  sc <- ngs_from_df(df)
  expect_length(sc$layers, 2)
  expect_identical(ngs_segments(sc$layers[[1]]), c("1", "2", "3"))

  sc <- ngs_from_df(df, layer_col = "type", color_col = "color")
  expect_identical(ngs_layer_names(sc), c("A", "B", "A-2"))
  expect_identical(ngs_layer(sc, "A")$segmentColors[["3"]], "#ff0000")

  expect_error(ngs_from_df(df[, -2]), "source")
  expect_error(ngs_from_df(df, layer_col = "foo"), "foo")
})

test_that("example scenes", {
  sc <- ngs_hemibrain_scene()
  expect_length(sc$layers, 3)
  expect_same_state(ngs_from_url(ngs_url(sc)), sc)
})
