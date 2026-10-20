to_json <- nglscenes:::to_json
parse <- nglscenes:::parse_json_state

test_that("JSON round-trips unchanged", {
  json <- paste0('{"a":{},"b":[],"c":null,"d":[1],"e":[[1]],"f":"x",',
                 '"g":true,"h":[null,1.5],"i":"720575940621039145"}')
  expect_identical(to_json(parse(json)), json)
})

test_that("keys are sorted", {
  expect_identical(to_json(list(b = 1L, a = list(d = 1L, c = 2L))),
                   '{"a":{"c":2,"d":1},"b":1}')
})

test_that("vectors are scalars or arrays", {
  expect_identical(to_json(list(a = "x", b = c(1, 2), c = I("x"),
                                d = character(0), e = nglscenes:::named_list())),
                   '{"a":"x","b":[1,2],"c":["x"],"d":[],"e":{}}')
})

test_that("doubles use the shortest representation that round-trips", {
  # R's parser doesn't always round long literals correctly, so we go via
  # jsonlite to get the exact doubles
  x <- c(0.1 + 0.2, 1 / 3, 2, 4e-9,
         nglscenes:::parse_numbers(c("-0.9964525699615479", "201443.95380397898")))
  out <- nglscenes:::json_number(x)
  expect_identical(out, c("0.30000000000000004", "0.3333333333333333", "2",
                          "4e-09", "-0.9964525699615479", "201443.95380397898"))
  expect_identical(nglscenes:::json_number(c(NA, Inf, NaN)),
                   rep("null", 3))
})

test_that("big integers keep their precision", {
  x <- parse('{"id":720575940621039145}')
  expect_s3_class(x$id, "ngs_number")
  expect_identical(unclass(x$id), "720575940621039145")
  expect_identical(to_json(x), '{"id":720575940621039145}')
})

test_that("strings are escaped", {
  s <- "a\"b\\c\nd\te\001f/é"
  json <- to_json(list(s = s))
  expect_identical(json, '{"s":"a\\"b\\\\c\\nd\\te\\u0001f/é"}')
  expect_identical(parse(json)$s, s)
})

test_that("pretty printing matches Python's json.dumps(indent=4)", {
  expect_identical(to_json(list(a = list(1L, 2L), b = nglscenes:::named_list()),
                           pretty = TRUE),
                   '{\n    "a": [\n        1,\n        2\n    ],\n    "b": {}\n}')
})

test_that("output matches Python nglscenes", {
  py <- readLines(fixture("fafb_python.json"), warn = FALSE)
  expect_identical(ngs_to_json(ngs_from_url(TEST_URL)), py)
})

test_that("arrays of arrays are written like nested lists", {
  x <- list(list(1L, 2L), list(), list(3L), list(4L, 5L))
  expect_true(nglscenes:::is_array_list(x))
  expect_identical(to_json(x), '[[1,2],[],[3],[4,5]]')
  expect_identical(to_json(list(a = x[1:3]), pretty = TRUE),
                   paste0('{\n    "a": [\n        [\n            1,\n            2\n',
                          '        ],\n        [],\n        [\n            3\n',
                          '        ]\n    ]\n}'))
  # Mixed or nested contents fall back to the general path
  expect_identical(to_json(list(list(1L, "a"), list(list(1L)))),
                   '[[1,"a"],[[1]]]')
})
