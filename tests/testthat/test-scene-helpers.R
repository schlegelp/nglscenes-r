two_seg <- function() {
  ngs_scene(ngs_image_layer("precomputed://gs://x/em", name = "em"),
            ngs_segmentation_layer("precomputed://gs://x/seg", name = "a",
                                   segments = c("1", "2")),
            ngs_segmentation_layer("precomputed://gs://y/seg", name = "b"))
}

test_that("helpers pick the only layer of the right type", {
  sc <- ngs_scene(ngs_image_layer("precomputed://gs://x/em"),
                  ngs_segmentation_layer("precomputed://gs://x/seg"),
                  ngs_annotation_layer())
  sc <- sc |>
    ngs_add_segments(c(1, 2, 3)) |>
    ngs_set_colors("red") |>
    ngs_add_points(c(1, 2, 3))
  expect_identical(ngs_segments(sc), c("1", "2", "3"))
  expect_identical(ngs_layer(sc, 2)$segmentColors[["3"]], "#ff0000")
  expect_length(ngs_layer(sc, 3)$annotations, 1)

  sc <- sc |> ngs_clear_colors() |> ngs_clear_annotations()
  expect_null(ngs_layer(sc, 2)$segmentColors)
  expect_length(ngs_layer(sc, 3)$annotations, 0)
})

test_that("`layer` picks the layer by name or position", {
  sc <- two_seg()
  expect_identical(ngs_segments(sc, "a"), c("1", "2"))

  sc <- ngs_color_by(sc, c("x", "y"), palette = c(x = "red", y = "blue"),
                     layer = "a")
  expect_identical(unname(unlist(ngs_layer(sc, "a")$segmentColors)),
                   c("#ff0000", "#0000ff"))

  sc <- ngs_add_segments(sc, "10", layer = 3)
  expect_identical(ngs_segments(sc, "b"), "10")
  # Other layers untouched
  expect_identical(ngs_segments(sc, "a"), c("1", "2"))

  sc <- ngs_add_source(sc, "precomputed://gs://x/skel", layer = "em")
  expect_length(ngs_layer(sc, "em")$source, 2)
})

test_that("ambiguous or wrong layers error", {
  sc <- two_seg()
  expect_error(ngs_segments(sc), "multiple segmentation layers \\(\"a\", \"b\"\\)")
  expect_error(ngs_set_colors(sc, "red", layer = "em"),
               "\"em\" is not a segmentation layer")
  expect_error(ngs_add_points(sc, c(1, 2, 3)), "no annotation layer")
  expect_error(ngs_add_source(sc, "x://y"), "multiple layers")
  expect_error(ngs_segments(sc, "nope"), "No layer named")

  # `layer` only applies to scenes
  expect_error(ngs_segments(ngs_layer(sc, "a"), layer = "a"),
               "only be used when `x` is a scene")
  expect_error(ngs_segments(ngs_layer(sc, "em")), "segmentation layer or a scene")
})

test_that("segments can be added and removed", {
  seg <- ngs_segmentation_layer("precomputed://gs://x/seg",
                                segments = c("1", "!2", "3"))
  # Adding a hidden segment makes it visible
  seg <- ngs_add_segments(seg, c(2, 4, 1))
  expect_identical(ngs_segments(seg), c("1", "3", "2", "4"))

  seg$segments <- c("1", "!2")
  seg <- ngs_remove_segments(seg, c("1", "2"))
  expect_identical(ngs_segments(seg), character(0))
  expect_match(ngs_to_json(seg), '"segments":[]', fixed = TRUE)
})
