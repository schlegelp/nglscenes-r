# The neuroglancer families spell a CAVE chunkedgraph layer differently:
#  - mainline neuroglancer / Spelunker: type "segmentation" with a
#    "graphene://middleauth+https://..." source
#  - the Seung-lab fork (e.g. ngl.flywire.ai): type "segmentation_with_graph"
#    with a bare "graphene://https://..." source

needs_middleauth <- function(url) {
  startsWith(url, "graphene://") & !startsWith(url, "graphene://middleauth+")
}

add_middleauth <- function(url) {
  if (needs_middleauth(url)) {
    url <- sub("graphene://", "graphene://middleauth+", url, fixed = TRUE)
  }
  url
}

remove_middleauth <- function(url) {
  sub("^graphene://middleauth\\+", "graphene://", url)
}

FLAVOURS <- list(
  mainline = list(type = "segmentation", f = add_middleauth),
  spelunker = list(type = "segmentation", f = add_middleauth),
  seunglab = list(type = "segmentation_with_graph", f = remove_middleauth)
)

check_flavour <- function(flavour) {
  if (!is_string(flavour) || is.null(FLAVOURS[[flavour]])) {
    stop("Unknown flavour \"", flavour, "\". Expected one of: ",
         paste(names(FLAVOURS), collapse = ", "), call. = FALSE)
  }
  invisible(flavour)
}


#' Graphene segmentation layers
#'
#' Segmentation layers for graphene (CAVE chunkedgraph) sources such as
#' FlyWire. Constructed layers are set up for mainline neuroglancer and
#' Spelunker (type `"segmentation"` with a `"graphene://middleauth+"` source).
#' Use [ngs_as_flavour()] or [ngs_for_viewer()] to convert them for other
#' neuroglancer flavours.
#'
#' `ngs_flywire_layer()` and `ngs_fanc_layer()` are shortcuts for the FlyWire
#' production and FANC segmentations.
#'
#' @param source A graphene source (`"graphene://..."`), see [layers].
#' @inheritParams layers
#' @return A graphene layer, which is also a segmentation layer.
#' @export
#' @examples
#' fw <- ngs_graphene_layer(
#'   "graphene://https://prod.flywire-daf.com/segmentation/1.0/flywire_public",
#'   segments = "720575940621039145"
#' )
#' fw$source
ngs_graphene_layer <- function(source, name = "segmentation", ...) {
  if (!is_graphene_source(source)) {
    stop("Expected `source` to start with the \"graphene://\" protocol",
         call. = FALSE)
  }
  layer <- make_layer(segmentation_state(source, name), list(...),
                      LAYER_CLASSES$segmentation_with_graph)
  ngs_as_flavour(layer, "mainline")
}

#' @rdname ngs_graphene_layer
#' @export
ngs_flywire_layer <- function(name = "flywire_production", ...) {
  ngs_graphene_layer(
    "graphene://middleauth+https://prod.flywire-daf.com/segmentation/1.0/fly_v31",
    name = name, ...
  )
}

#' @rdname ngs_graphene_layer
#' @export
ngs_fanc_layer <- function(name = "fanc", ...) {
  ngs_graphene_layer(
    "graphene://https://cave.fanc-fly.com/segmentation/table/mar2021_prod",
    name = name, ...
  )
}

#' Convert graphene layers between neuroglancer flavours
#'
#' The neuroglancer families spell CAVE chunkedgraph layers differently and
#' each refuses the other's spelling:
#'
#' - `"mainline"` and `"spelunker"` (e.g. ngl.cave-explorer.org) use type
#'   `"segmentation"` with a `"graphene://middleauth+"` source
#' - `"seunglab"` (e.g. ngl.flywire.ai) uses type `"segmentation_with_graph"`
#'   with a bare `"graphene://"` source
#'
#' `ngs_as_flavour()` converts a single graphene layer, `ngs_for_viewer()`
#' converts all graphene layers in a scene and leaves other layers untouched.
#' `ngs_flavour()` returns the flavour a graphene layer is written for.
#'
#' @param x A graphene layer (for `ngs_as_flavour()`, `ngs_flavour()`) or a
#'   scene (for `ngs_for_viewer()`).
#' @param flavour One of `"mainline"`, `"spelunker"` or `"seunglab"`.
#' @return The converted layer or scene.
#' @export
#' @examples
#' sc <- ngs_scene(ngs_flywire_layer())
#' sc2 <- ngs_for_viewer(sc, "seunglab")
#' sc2$layers[[1]]$type
ngs_as_flavour <- function(x, flavour) {
  check_class(x, "ngs_graphene_layer", "a graphene layer")
  check_flavour(flavour)
  x$type <- FLAVOURS[[flavour]]$type
  x$source <- map_source_urls(x$source, FLAVOURS[[flavour]]$f)
  x
}

#' @rdname ngs_as_flavour
#' @export
ngs_flavour <- function(x) {
  check_class(x, "ngs_graphene_layer", "a graphene layer")
  if (identical(x$type, FLAVOURS$seunglab$type)) "seunglab" else "mainline"
}

#' @rdname ngs_as_flavour
#' @export
ngs_for_viewer <- function(x, flavour) {
  check_scene(x)
  check_flavour(flavour)
  x$layers <- lapply(x$layers, function(l) {
    if (inherits(l, "ngs_graphene_layer")) ngs_as_flavour(l, flavour) else l
  })
  x
}
