test_that("properties can be created from a data frame", {
  df <- data.frame(id = c(1, 2, 3),
                   name = c("DA1_lPN", "DA1_lPN", "KCg"),
                   notes = c("a", "b", "c"),
                   size = c(10.5, 12, 3),
                   n = 1:3,
                   class = factor(c("P N", "P N", "#KC")))
  expect_message(props <- ngs_properties_from_df(df), "string")
  expect_identical(ngs_property_types(props),
                   c(name = "label", notes = "string", size = "number",
                     n = "number", class = "tags"))

  info <- as.list(props)
  expect_identical(info$inline$ids, list("1", "2", "3"))
  tags <- info$inline$properties[[5]]
  expect_identical(tags$tags, list("KC", "P_N"))
  expect_identical(tags$values, list(list(1L), list(1L), list(0L)))
  expect_identical(info$inline$properties[[4]]$data_type, "int32")
  expect_identical(info$inline$properties[[3]]$data_type, "float32")

  back <- as.data.frame(props)
  expect_identical(back$id, c("1", "2", "3"))
  expect_identical(back$name, df$name)
  expect_identical(back$size, df$size)
  expect_identical(as.character(back$class), c("P_N", "P_N", "KC"))
})

test_that("tags can be lists", {
  props <- ngs_segment_properties(c("1", "2"))
  props <- ngs_add_property(props, list(c("b", "a"), "c"), name = "tags",
                            description = "Some tags")
  p <- as.list(props)$inline$properties[[1]]
  expect_identical(p$tags, list("a", "b", "c"))
  expect_identical(p$values, list(list(1L, 0L), list(2L)))
  expect_identical(p$description, "Some tags")
  expect_identical(as.data.frame(props)$tags[[1]], c("b", "a"))
})

test_that("properties round-trip through JSON", {
  props <- ngs_properties_from_df(data.frame(id = 1, label = "x", v = 2.5))
  path <- withr::local_tempfile()
  ngs_write_info(props, path)
  info <- jsonlite::read_json(path)
  back <- ngs_properties_from_list(info)
  expect_identical(ngs_to_json(back), ngs_to_json(props))
  # A single segment is still an array
  expect_match(ngs_to_json(props), '"ids":["1"]', fixed = TRUE)
})

test_that("invalid input errors", {
  expect_error(ngs_segment_properties(c(1, 1)), "unique")
  props <- ngs_segment_properties(1:2)
  expect_error(ngs_add_property(props, 1:3, "x"), "3 values for 2")
  expect_error(ngs_add_property(props, c(1, NA), "x"), "NAs")
  expect_error(ngs_add_property(props, c(TRUE, FALSE), "x"), "infer")
})

test_that("properties are fetched from URLs", {
  urls <- character()
  local_mocked_bindings(fetch_json = function(url, token = NULL) {
    urls <<- c(urls, url)
    if (grepl("props", url)) {
      list(`@type` = "neuroglancer_segment_properties",
           inline = list(ids = list("1"), properties = list()))
    } else {
      list(segment_properties = "props")
    }
  })
  props <- ngs_properties_from_url("precomputed://gs://bucket/seg")
  expect_identical(urls, c("https://storage.googleapis.com/bucket/seg/info",
                           "https://storage.googleapis.com/bucket/seg/props/info"))
  expect_s3_class(props, "ngs_segment_properties")
})
