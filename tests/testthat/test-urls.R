target <- function(url) nglscenes:::parse_ngl_url(url)$remote

test_that("state URLs are recognised", {
  is_state <- function(url) !is.null(target(url))
  expect_true(is_state("https://ngl.flywire.ai/?json_url=https://globalv1.flywire-daf.com/nglstate/123"))
  expect_true(is_state("https://neuroglancer-demo.appspot.com/#!gs://bucket/state.json"))
  expect_true(is_state("https://spelunker.cave-explorer.org/#!middleauth+https://global.daf-apis.com/nglstate/api/v1/123"))
  expect_true(is_state("https://neuroglancer-demo.appspot.com/#!https://x.org/state.json"))
  expect_false(is_state(TEST_URL))
})

test_that("state URLs resolve to the right target", {
  x <- target("https://ngl.flywire.ai/?json_url=https://globalv1.flywire-daf.com/nglstate/123")
  expect_identical(x$url, "https://globalv1.flywire-daf.com/nglstate/123")
  expect_true(x$auth)

  x <- target("https://neuroglancer-demo.appspot.com/#!gs://bucket/short/state.json")
  expect_identical(x$url, "https://storage.googleapis.com/bucket/short/state.json")
  expect_false(x$auth)

  x <- target("https://spelunker.cave-explorer.org/#!middleauth+https://global.daf-apis.com/nglstate/api/v1/123")
  expect_identical(x$url, "https://global.daf-apis.com/nglstate/api/v1/123")
  expect_true(x$auth)
  expect_identical(x$host, "global.daf-apis.com")

  x <- target("https://x.org/?a=1&json_url=https%3A%2F%2Fy.org%2Fs.json")
  expect_identical(x$url, "https://y.org/s.json")
})

test_that("large states are parsed in full", {
  ids <- sprintf("7205759400%08d", 1:50000)
  sc <- ngs_scene(ngs_segmentation_layer("precomputed://gs://x/seg", segments = ids))
  url <- ngs_url(sc)
  expect_gt(nchar(url), 1e6)
  expect_identical(ngs_segments(ngs_from_url(url)), ids)
})

test_that("the state is stripped from base URLs", {
  strip <- function(url) nglscenes:::parse_ngl_url(url)$base
  expect_identical(strip("https://ngl.flywire.ai/?json_url=https://x.org/1"),
                   "https://ngl.flywire.ai/")
  expect_identical(strip("https://x.org/?a=1&json_url=https://x.org/1&b=2"),
                   "https://x.org/?a=1&b=2")
  expect_identical(strip("https://x.org/#!{}"), "https://x.org/")
})

test_that("state servers are fetched", {
  state <- '{"layout":"3d","layers":[]}'
  local_mocked_bindings(fetch_json = function(url, token = NULL) {
    expect_identical(url, "https://storage.googleapis.com/bucket/state.json")
    expect_null(token)
    nglscenes:::parse_json_state(state)
  })
  sc <- ngs_from_url("https://neuroglancer-demo.appspot.com/#!gs://bucket/state.json")
  expect_identical(sc$layout, "3d")
  expect_identical(ngs_base_url(sc), "https://neuroglancer-demo.appspot.com/")
})

test_that("CAVE tokens are found", {
  withr::with_envvar(c(CAVE_TOKEN = "abc"),
                     expect_identical(ngs_cave_token(), "abc"))

  home <- withr::local_tempdir()
  dir.create(file.path(home, ".cloudvolume", "secrets"), recursive = TRUE)
  jsonlite::write_json(list(token = "def"),
                       file.path(home, ".cloudvolume", "secrets", "cave-secret.json"),
                       auto_unbox = TRUE)
  withr::with_envvar(c(CAVE_TOKEN = "", CHUNKEDGRAPH_SECRET = "", HOME = home),
                     expect_identical(ngs_cave_token(), "def"))
})
