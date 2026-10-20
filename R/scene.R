# A scene is its JSON state (a named list) with class "ngs_scene". The
# `layers` field is a list of layer objects and the URL of the neuroglancer
# instance is kept in the "base_url" attribute.

new_scene <- function(state = list(), base_url = DEFAULT_BASE_URL) {
  check_string(base_url)
  state$layers <- state$layers %||% list()
  structure(state, base_url = base_url, class = "ngs_scene")
}

check_scene <- function(x) check_class(x, "ngs_scene", "a scene")

#' Create a scene
#'
#' A scene is a neuroglancer state: a named list with class `ngs_scene`.
#' Top-level fields (e.g. `layout`, `position`) can be read and set with `$`
#' and `[[`, and `x$layers` is the list of layers. Use [ngs_add_layers()],
#' [ngs_drop_layer()], [ngs_layer()] etc. to manage layers.
#'
#' Scenes can be combined with `+` (adds all layers of the second scene) and
#' `|` (merges layers with the same source, e.g. combines the selected
#' segments of segmentation layers, and adds the others).
#'
#' Note that JSON arrays with mixed types must be lists, e.g.
#' `dimensions = list(x = list(8e-9, "m"), ...)`.
#'
#' @param ... Layers to add and/or named top-level fields of the state
#'   (e.g. `layout = "3d"`).
#' @param base_url URL of the neuroglancer instance (host or page) used by
#'   [ngs_url()].
#' @return A scene.
#' @export
#' @examples
#' sc <- ngs_scene(
#'   ngs_image_layer("precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe"),
#'   ngs_segmentation_layer("precomputed://gs://fafb-ffn1-20200412/segmentation"),
#'   layout = "3d"
#' )
#' sc
#' sc$layout <- "xy-3d"
#' ngs_url(sc)
ngs_scene <- function(..., base_url = DEFAULT_BASE_URL) {
  args <- list(...)
  is_layer <- vapply(args, inherits, logical(1), "ngs_layer")
  state <- update_state(list(), args[!is_layer])
  ngs_add_layers(new_scene(state, base_url), args[is_layer])
}

#' Base URL of a scene
#'
#' The URL of the neuroglancer instance (e.g.
#' `"https://spelunker.cave-explorer.org/"`) that [ngs_url()] appends the
#' state to.
#'
#' @param x A scene.
#' @param value The new base URL.
#' @return For `ngs_base_url()`, the base URL.
#' @export
#' @examples
#' sc <- ngs_scene()
#' ngs_base_url(sc) <- "https://spelunker.cave-explorer.org/"
#' ngs_url(sc)
ngs_base_url <- function(x) {
  check_scene(x)
  attr(x, "base_url") %||% DEFAULT_BASE_URL
}

#' @rdname ngs_base_url
#' @export
`ngs_base_url<-` <- function(x, value) {
  check_scene(x)
  check_string(value, "value")
  attr(x, "base_url") <- value
  x
}

#' Add layers to a scene
#'
#' Layer names must be unique within a scene. If a name is already taken,
#' a suffix is added (e.g. `"segmentation-2"`).
#'
#' @param x A scene.
#' @param ... Layers to add, or lists of layers.
#' @param index Position at which to insert the layers. Default is to
#'   append.
#' @return The modified scene.
#' @export
#' @examples
#' sc <- ngs_scene()
#' sc <- ngs_add_layers(sc, ngs_segmentation_layer("precomputed://gs://x/seg"),
#'                      ngs_segmentation_layer("precomputed://gs://y/seg"))
#' ngs_layer_names(sc)
ngs_add_layers <- function(x, ..., index = NULL) {
  check_scene(x)
  layers <- list(...)
  # Allow lists of layers
  layers <- do.call(c, lapply(layers, function(l) {
    if (inherits(l, "ngs_layer")) list(l) else l
  })) %||% list()

  for (l in layers) {
    if (!inherits(l, "ngs_layer")) {
      stop("Expected a layer, got \"", class(l)[1], "\"", call. = FALSE)
    }
    taken <- ngs_layer_names(x)
    org <- as.character(l$name)
    i <- 2
    while (l$name %in% taken) {
      l$name <- paste0(org, "-", i)
      i <- i + 1
    }

    if (is.null(index)) {
      x$layers <- c(x$layers, list(l))
    } else {
      x$layers <- append(x$layers, list(l), after = index - 1)
      index <- index + 1
    }
  }
  x
}

#' Get, replace or remove layers
#'
#' Layers can be referred to by their (1-based) position or by name.
#'
#' `ngs_layer()` and its replacement form also make it easy to modify a
#' layer in place, e.g. `ngs_layer(sc, "segmentation")$segments <- ids`.
#'
#' @param x A scene.
#' @param which Position (integer) or name (string) of the layer. For
#'   `ngs_drop_layer()`, can also be a vector of positions or names.
#' @param value A layer.
#' @param index The new position of the layer.
#' @return `ngs_layer()` returns a layer, `ngs_layer_names()` a character
#'   vector and the others the modified scene.
#' @name layer-management
#' @examples
#' sc <- ngs_scene(
#'   ngs_image_layer("precomputed://gs://x/em", name = "em"),
#'   ngs_segmentation_layer("precomputed://gs://x/seg", name = "seg")
#' )
#' ngs_layer(sc, "seg")
#' ngs_layer(sc, "seg")$segments <- c("1", "2")
#' sc <- ngs_move_layer(sc, "seg", 1)
#' ngs_layer_names(sc)
#' sc <- ngs_drop_layer(sc, "em")
NULL

#' @rdname layer-management
#' @export
ngs_layer_names <- function(x) {
  check_scene(x)
  vapply(x$layers, function(l) as.character(l$name %||% NA), character(1))
}

#' @rdname layer-management
#' @export
ngs_layer <- function(x, which) {
  check_scene(x)
  x$layers[[layer_index(x, which)]]
}

#' @rdname layer-management
#' @export
`ngs_layer<-` <- function(x, which, value) {
  check_scene(x)
  check_class(value, "ngs_layer", "a layer", "value")
  x$layers[[layer_index(x, which)]] <- value
  x
}

#' @rdname layer-management
#' @export
ngs_drop_layer <- function(x, which) {
  check_scene(x)
  ix <- vapply(as.list(which), layer_index, integer(1), x = x)
  # `x[-integer(0)]` would drop everything
  if (length(ix)) x$layers <- x$layers[-ix]
  x
}

#' @rdname layer-management
#' @export
ngs_move_layer <- function(x, which, index) {
  check_scene(x)
  ix <- layer_index(x, which)
  if (!is.numeric(index) || length(index) != 1 || index < 1 ||
      index > length(x$layers)) {
    stop("`index` must be between 1 and ", length(x$layers), call. = FALSE)
  }
  layer <- x$layers[[ix]]
  x$layers <- append(x$layers[-ix], list(layer), after = index - 1)
  x
}

# Helpers that take a layer or a scene: `with_layer()` applies `f` to the
# layer (for scenes, the one picked by `pick_layer()`) and returns `x` with the
# modified layer, `resolve_layer()` just returns the layer
with_layer <- function(x, layer, class, f) {
  if (!inherits(x, "ngs_scene")) return(f(check_layer(x, layer, class)))
  ix <- pick_layer(x, layer, class)
  x$layers[[ix]] <- f(x$layers[[ix]])
  x
}

resolve_layer <- function(x, layer, class) {
  if (!inherits(x, "ngs_scene")) return(check_layer(x, layer, class))
  x$layers[[pick_layer(x, layer, class)]]
}

# Index of the layer a scene-level helper should act on: `layer` if given,
# otherwise the scene's only layer of the given class
pick_layer <- function(x, layer, class) {
  what <- layer_kind(class)

  if (is.null(layer)) {
    ix <- which(vapply(x$layers, inherits, logical(1), class))
    if (!length(ix)) stop("Scene has no ", what, "layer", call. = FALSE)
    if (length(ix) > 1) {
      stop("Scene has multiple ", what, "layers (",
           paste0("\"", ngs_layer_names(x)[ix], "\"", collapse = ", "),
           "): use `layer` to pick one", call. = FALSE)
    }
    return(ix)
  }

  ix <- layer_index(x, layer)
  if (!inherits(x$layers[[ix]], class)) {
    stop("Layer \"", ngs_layer_names(x)[ix], "\" is not a ", what, "layer",
         call. = FALSE)
  }
  ix
}

# "segmentation " for messages like "no segmentation layer"
layer_kind <- function(class) {
  if (class == "ngs_layer") "" else paste0(class_label(class), " ")
}

# For helpers that take a layer or a scene, if `x` isn't a scene: check that
# it's a layer of the right class (`layer` only makes sense for scenes)
check_layer <- function(x, layer, class) {
  if (!is.null(layer)) {
    stop("`layer` can only be used when `x` is a scene", call. = FALSE)
  }
  what <- layer_kind(class)
  if (!inherits(x, class)) {
    stop("`x` must be a", if (grepl("^[aeiou]", what)) "n", " ", what,
         "layer or a scene", call. = FALSE)
  }
  invisible(x)
}

layer_index <- function(x, which) {
  n <- length(x$layers)
  if (is_string(which)) {
    ix <- which(ngs_layer_names(x) == which)
    if (!length(ix)) stop("No layer named \"", which, "\"", call. = FALSE)
    if (length(ix) > 1) {
      stop("Multiple layers named \"", which, "\"", call. = FALSE)
    }
    return(ix)
  }
  if (is.numeric(which) && length(which) == 1 && !is.na(which)) {
    if (which < 1 || which > n || which != round(which)) {
      stop("Unable to get layer ", which, ": scene has ", plural(n, "layer"),
           call. = FALSE)
    }
    return(as.integer(which))
  }
  stop("Layers must be referred to by a single position or name",
       call. = FALSE)
}

#' @export
Ops.ngs_scene <- function(e1, e2) {
  if (!.Generic %in% c("+", "|")) {
    stop("Operator `", .Generic, "` is not supported for scenes",
         call. = FALSE)
  }
  if (!inherits(e1, "ngs_scene") || !inherits(e2, "ngs_scene")) {
    stop("Unable to combine a scene with something that isn't a scene",
         call. = FALSE)
  }
  switch(.Generic,
         "+" = ngs_add_layers(e1, e2$layers),
         "|" = merge_scenes(e1, e2))
}

merge_scenes <- function(x, y) {
  for (l in y$layers) {
    merged <- FALSE
    # Merge into the first layer that accepts it
    for (i in seq_along(x$layers)) {
      m <- merge_layers(x$layers[[i]], l)
      if (!is.null(m)) {
        x$layers[[i]] <- m
        merged <- TRUE
        break
      }
    }
    if (!merged) x <- ngs_add_layers(x, l)
  }
  x
}

#' @export
as.list.ngs_scene <- function(x, ...) {
  layers <- lapply(x$layers, as.list)
  x <- unclass(x)
  attr(x, "base_url") <- NULL
  x$layers <- layers
  x
}

#' @export
print.ngs_scene <- function(x, ...) {
  n <- length(x$layers)
  types <- vapply(x$layers, function(l) as.character(l$type %||% "?"),
                  character(1))
  counts <- table(factor(types, levels = unique(types)))
  summary <- if (n) paste0(": ", paste(counts, names(counts), collapse = ", "))
  cat("<ngs_scene> ", plural(n, "layer"), summary, "\n", sep = "")
  cat("Base URL: ", ngs_base_url(x), "\n", sep = "")

  if (n) {
    width <- getOption("width", 80) - nchar(n) - 2
    lines <- vapply(x$layers, format, character(1), width = width)
    cat(paste0(format(seq_len(n), width = nchar(n)), ": ", lines), sep = "\n")
  }
  invisible(x)
}
