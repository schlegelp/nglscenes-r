#' Read scenes
#'
#' Parse a scene from a neuroglancer URL, a JSON string, a state list, a
#' JSON file, the clipboard or a data frame of segments.
#'
#' URLs pointing to a state server are supported: `?json_url=...`,
#' `#!gs://...`, `#!https://...` and `#!middleauth+https://...` links are
#' fetched. CAVE state servers (e.g. FlyWire's) require a token, see
#' [ngs_cave_token()].
#'
#' Layers are kept exactly as written, so parsing and writing a scene
#' round-trips it unchanged. Neuroglancer also accepts `layers` as a
#' `{name: layer}` map; these are converted to a list.
#'
#' @param x A URL, a JSON string or a state (named list).
#' @param url A neuroglancer URL.
#' @param path Path to a JSON file.
#' @param skip_archived If `TRUE`, drop archived layers.
#' @param base_url URL of the neuroglancer instance used by [ngs_url()]. If
#'   not given and the input is a URL, its base is used.
#' @return A scene.
#' @name read-scenes
#' @examples
#' sc <- ngs_from_string('{"layout": "3d", "layers": [{"type": "image",
#'   "source": "precomputed://gs://x/em", "name": "em"}]}')
#' sc
#' sc2 <- ngs_from_url(ngs_url(sc))
#' \dontrun{
#' ngs_from_clipboard()
#' }
NULL

#' @rdname read-scenes
#' @export
ngs_from_string <- function(x, skip_archived = FALSE, base_url = NULL) {
  state <- as_state(x)
  if (is.null(names(state)) && length(state)) {
    stop("Expected the state to be a JSON object", call. = FALSE)
  }

  layers <- state$layers %||% list()
  # Neuroglancer also accepts a `{name: layer}` map
  if (!is.null(names(layers))) {
    layers <- unname(Map(function(l, n) {
      l$name <- n
      l
    }, layers, names(layers)))
  }
  state$layers <- NULL

  base_url <- base_url %||% attr(state, "base_url")
  attr(state, "base_url") <- NULL

  sc <- new_scene(state, base_url %||% DEFAULT_BASE_URL)
  ngs_add_layers(sc, ngs_parse_layers(layers, skip_archived = skip_archived))
}

#' @rdname read-scenes
#' @export
ngs_from_url <- function(url, skip_archived = FALSE, base_url = NULL) {
  if (!is_url(url)) stop("`url` must be a URL", call. = FALSE)
  ngs_from_string(url, skip_archived = skip_archived, base_url = base_url)
}

#' @rdname read-scenes
#' @export
ngs_from_list <- function(x, base_url = NULL) {
  if (!is.list(x)) stop("`x` must be a list", call. = FALSE)
  ngs_from_string(x, base_url = base_url)
}

#' @rdname read-scenes
#' @export
ngs_from_file <- function(path, base_url = NULL) {
  json <- paste(readLines(path, encoding = "UTF-8", warn = FALSE),
                collapse = "\n")
  ngs_from_string(json, base_url = base_url)
}

#' @rdname read-scenes
#' @export
ngs_from_clipboard <- function(base_url = NULL) {
  ngs_from_string(paste(clipr::read_clip(), collapse = "\n"),
                  base_url = base_url)
}

#' Create a scene from a data frame of segments
#'
#' @param df A data frame with an `id` (or `segment_id`) column with segment
#'   IDs and a `source` column with the segmentation sources. Each source gets
#'   its own layer.
#' @param layer_col Optional name of a column to further split segments into
#'   layers by. Layers are named by its values.
#' @param color_col Optional name of a column with colours for the segments.
#' @param ... Passed to [ngs_scene()], e.g. other layers or `base_url`.
#' @return A scene.
#' @export
#' @examples
#' df <- data.frame(id = c("1", "2", "3"),
#'                  source = "precomputed://gs://x/seg",
#'                  type = c("A", "B", "A"),
#'                  color = c("red", "blue", "red"))
#' ngs_from_df(df, layer_col = "type", color_col = "color")
ngs_from_df <- function(df, layer_col = NULL, color_col = NULL, ...) {
  check_class(df, "data.frame", "a data frame", "df")
  if (!"id" %in% names(df)) {
    if (!"segment_id" %in% names(df)) {
      stop("Data frame must contain an \"id\" or \"segment_id\" column",
           call. = FALSE)
    }
    df$id <- df$segment_id
  }
  if (!"source" %in% names(df)) {
    stop("Data frame must contain a \"source\" column", call. = FALSE)
  }
  df$source <- as.character(df$source)
  for (col in c(layer_col, color_col)) {
    if (!col %in% names(df)) {
      stop("Column \"", col, "\" not in data frame", call. = FALSE)
    }
  }

  make <- function(source, rows, name) {
    ids <- as_segment_ids(rows$id)
    f <- if (is_graphene_source(source)) ngs_graphene_layer else
      ngs_segmentation_layer
    layer <- f(source, name = name, segments = ids)
    if (!is.null(color_col)) {
      layer <- ngs_set_colors(layer, stats::setNames(as.character(rows[[color_col]]), ids))
    }
    layer
  }

  # One layer per source (and value of `layer_col`), sorted by both
  groups <- split(df, df[c("source", layer_col)], drop = TRUE, lex.order = TRUE)
  layers <- lapply(unname(groups), function(rows) {
    name <- if (is.null(layer_col)) "segmentation" else
      as.character(rows[[layer_col]][1])
    make(rows$source[1], rows, name)
  })

  ngs_add_layers(ngs_scene(...), layers)
}

#' Write scenes
#'
#' `ngs_url()` generates a neuroglancer URL with the state encoded in it,
#' `ngs_to_json()` the JSON string. `ngs_to_file()` and `ngs_to_clipboard()`
#' write those to a file or the clipboard, and `ngs_open()` opens the scene
#' in the browser. Use `as.list()` to get the state as a plain list.
#'
#' @param x A scene. `ngs_to_json()` also accepts layers and segment
#'   properties.
#' @param pretty If `TRUE`, indent the JSON.
#' @param path Path of the file to write.
#' @param json If `TRUE`, copy the JSON state instead of the URL.
#' @return `ngs_url()` and `ngs_to_json()` return a string, the others
#'   return `x` invisibly.
#' @name write-scenes
#' @examples
#' sc <- ngs_scene(ngs_image_layer("precomputed://gs://x/em"), layout = "3d")
#' ngs_url(sc)
#' cat(ngs_to_json(sc, pretty = TRUE))
#' \dontrun{
#' ngs_open(sc)
#' }
NULL

#' @rdname write-scenes
#' @export
ngs_url <- function(x) {
  check_scene(x)
  # The state is a fragment: replace any existing fragment of the base
  paste0(url_base(ngs_base_url(x)), "#!", url_quote(ngs_to_json(x)))
}

#' @rdname write-scenes
#' @export
ngs_to_json <- function(x, pretty = FALSE) {
  to_json(as.list(x), pretty = pretty)
}

#' @rdname write-scenes
#' @export
ngs_to_file <- function(x, path) {
  writeLines(enc2utf8(ngs_to_json(x, pretty = TRUE)), path, useBytes = TRUE)
  invisible(x)
}

#' @rdname write-scenes
#' @export
ngs_to_clipboard <- function(x, json = FALSE) {
  if (json) {
    clipr::write_clip(ngs_to_json(x, pretty = TRUE))
    message("Scene copied to clipboard.")
  } else {
    clipr::write_clip(ngs_url(x))
    message("URL copied to clipboard.")
  }
  invisible(x)
}

#' @rdname write-scenes
#' @export
ngs_open <- function(x) {
  utils::browseURL(ngs_url(x))
  invisible(x)
}
