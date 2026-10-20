# Port of nglscenes' tests/test_parsing.py

# Issue 1
test_that("scenes round-trip unchanged", {
  expect_same_state(ngs_from_list(PUBLISHED), PUBLISHED)
})

test_that("constructed layers get defaults", {
  layer <- ngs_segmentation_layer("precomputed://gs://x/seg")
  expect_true("selectedAlpha" %in% names(layer))
  expect_identical(layer$segments, character(0))
})

test_that("edits are still normalised", {
  sc <- ngs_from_list(PUBLISHED)
  ngs_layer(sc, "segmentation")$segments <- list("10001", "!10002", 10003)
  expect_identical(ngs_layer(sc, "segmentation")$segments,
                   c("10001", "!10002", "10003"))
})

# Issue 2
test_that("URLs use the base as given", {
  cases <- c(
    "https://ngl.cave-explorer.org" = "https://ngl.cave-explorer.org/#!",
    "https://spelunker.cave-explorer.org/" = "https://spelunker.cave-explorer.org/#!",
    "https://coda.science/neuroglancer.html" = "https://coda.science/neuroglancer.html#!",
    "https://x.org?foo=1" = "https://x.org/?foo=1#!",
    "https://x.org/neuroglancer.html?foo=1" = "https://x.org/neuroglancer.html?foo=1#!",
    "https://ngl.cave-explorer.org/#!%7B%22layout%22%3A%224panel%22%7D" = "https://ngl.cave-explorer.org/#!"
  )
  for (base in names(cases)) {
    sc <- ngs_scene(layout = "3d", base_url = base)
    url <- ngs_url(sc)
    expect_true(startsWith(url, cases[[base]]))
    expect_identical(lengths(regmatches(url, gregexpr("#!", url, fixed = TRUE))), 1L)
    expect_same_state(url_state(url), sc)
  }
})

# Issue 3
test_that("base URL can be set", {
  base <- "https://ngl.cave-explorer.org/"
  sc <- ngs_from_list(PUBLISHED, base_url = base)
  expect_identical(ngs_base_url(sc), base)
  expect_true(startsWith(ngs_url(sc), paste0(base, "#!")))

  ngs_base_url(sc) <- "https://coda.science/neuroglancer.html"
  expect_true(startsWith(ngs_url(sc), "https://coda.science/neuroglancer.html#!"))

  # Explicit base wins over the URL's own
  url <- ngs_url(ngs_from_list(PUBLISHED))
  expect_true(startsWith(ngs_url(ngs_from_string(url, base_url = base)),
                         paste0(base, "#!")))
  expect_identical(ngs_base_url(ngs_from_string(url)),
                   "https://neuroglancer-demo.appspot.com/")
})

# Issue 4
test_that("graphene layers are kept as written", {
  for (layer in list(SEUNGLAB_LAYER, SPELUNKER_LAYER)) {
    sc <- ngs_from_list(state_of(layer))
    expect_same_state(as.list(sc)$layers, list(layer))
    expect_s3_class(sc$layers[[1]], "ngs_graphene_layer")
  }
})

test_that("constructed graphene layers are mainline", {
  layer <- ngs_graphene_layer(SEUNGLAB_LAYER$source,
                              type = "segmentation_with_graph")
  expect_identical(layer$type, "segmentation")
  expect_true(startsWith(layer$source, "graphene://middleauth+https://"))
})

test_that("scenes can be converted for viewers", {
  seung <- ngs_from_list(state_of(SEUNGLAB_LAYER, PUBLISHED$layers[[1]]))
  spel <- ngs_from_list(state_of(SPELUNKER_LAYER, PUBLISHED$layers[[1]]))

  x <- ngs_for_viewer(seung, "spelunker")
  expect_identical(x$layers[[1]]$type, "segmentation")
  expect_identical(x$layers[[1]]$source,
                   sub("graphene://", "graphene://middleauth+",
                       SEUNGLAB_LAYER$source, fixed = TRUE))
  # Original untouched; non-graphene layers untouched
  expect_same_state(as.list(seung)$layers[[1]], SEUNGLAB_LAYER)
  expect_same_state(as.list(x)$layers[[2]], PUBLISHED$layers[[1]])

  # Object source keeps its shape and subsources (issue 5)
  y <- ngs_for_viewer(spel, "seunglab")
  expect_identical(y$layers[[1]]$type, "segmentation_with_graph")
  expect_identical(y$layers[[1]]$source,
                   list(url = SEUNGLAB_LAYER$source,
                        subsources = list(bounds = FALSE)))

  # Idempotent and reversible
  expect_same_state(ngs_for_viewer(x, "spelunker"), x)
  expect_same_state(ngs_for_viewer(y, "seunglab"), y)
  expect_same_state(ngs_for_viewer(y, "spelunker"), spel)

  expect_error(ngs_for_viewer(seung, "foo"), "Unknown flavour")
})

test_that("layers can be converted between flavours", {
  layer <- ngs_from_list(state_of(SEUNGLAB_LAYER))$layers[[1]]
  expect_identical(ngs_flavour(layer), "seunglab")
  expect_identical(ngs_flavour(ngs_as_flavour(layer, "mainline")), "mainline")
  expect_identical(ngs_flavour(layer), "seunglab")
})

# Issue 5
test_that("graphene object sources keep their shape", {
  sources <- list(SPELUNKER_LAYER$source,
                  list(SPELUNKER_LAYER$source, "precomputed://gs://x/skeletons"))
  for (source in sources) {
    layer <- ngs_graphene_layer(source)
    urls <- nglscenes:::source_urls(layer$source)
    expect_true(startsWith(urls[1], "graphene://middleauth+"))
    expect_identical(is.null(names(layer$source)), is.null(names(source)))

    state <- state_of(modifyList(SEUNGLAB_LAYER, list(source = source)))
    expect_identical(as.list(ngs_from_list(state))$layers[[1]]$source, source)
  }
})

# Issue 6
test_that("unknown layer types are kept", {
  draft <- list(type = "new", name = "draft")
  future <- list(type = "some_future_type", name = "future", source = "x://y")
  s <- state_of(PUBLISHED$layers[[1]], draft, future)
  sc <- ngs_from_list(s)
  expect_length(sc$layers, 3)
  expect_s3_class(ngs_layer(sc, "draft"), "ngs_generic_layer")
  expect_same_state(sc, s)
  expect_output(print(sc), "3 layers")

  expect_error(ngs_parse_layers(list(name = "no type", source = "x://y")),
               "has no type")
  expect_identical(ngs_parse_layers(list(future), skip_unknown = TRUE), list())
})

# Issue 7
test_that("layer maps are converted to lists", {
  s <- list(layers = list(em = list(type = "image",
                                    source = "precomputed://gs://x/em")))
  sc <- ngs_from_list(s)
  expect_length(sc$layers, 1)
  expect_identical(sc$layers[[1]]$name, "em")
  expect_same_state(as.list(sc)$layers,
                    list(list(type = "image", source = "precomputed://gs://x/em",
                              name = "em")))
})

# Issue 8
test_that("URL JSON is compact", {
  sc <- ngs_from_list(PUBLISHED)
  url <- ngs_url(sc)
  expect_false(grepl("%20", url, fixed = TRUE))
  expect_same_state(url_state(url), PUBLISHED)
  expect_match(ngs_to_json(sc, pretty = TRUE), ": ", fixed = TRUE)
})

test_that("archived layers can be skipped", {
  s <- state_of(PUBLISHED$layers[[1]],
                modifyList(PUBLISHED$layers[[3]], list(archived = TRUE)))
  expect_length(ngs_from_list(s)$layers, 2)
  expect_length(ngs_from_string(s, skip_archived = TRUE)$layers, 1)
})
