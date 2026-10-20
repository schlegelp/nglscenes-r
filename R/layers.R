# Layers are the layer's JSON state (a named list) with a class attached:
# `c("ngs_<type>_layer", "ngs_layer")`. Fields can be read and set with `$`
# and `[[` as usual. Setting some fields normalises their values, e.g. a
# segmentation layer's `segments` are always stored as character.

# Neuroglancer layer type -> R class
LAYER_CLASSES <- list(
  image = "ngs_image_layer",
  segmentation = "ngs_segmentation_layer",
  annotation = "ngs_annotation_layer",
  mesh = "ngs_mesh_layer",
  segmentation_with_graph = c("ngs_graphene_layer", "ngs_segmentation_layer")
)

new_layer <- function(state, class) {
  layer <- structure(state, class = c(class, "ngs_layer"))
  validate_layer(layer)
}

# Like the constructors but used for user input: normalises values
make_layer <- function(state, extra, class) {
  state <- update_state(state, extra)
  for (k in names(state)) state[[k]] <- normalise_field(class, k, state[[k]])
  new_layer(state, class)
}

validate_layer <- function(x) {
  # Local annotation layers can come without a source
  required <- if (inherits(x, "ngs_generic_layer")) c("name", "type") else
    if (inherits(x, "ngs_annotation_layer")) "name" else c("name", "source")
  missing <- setdiff(required, names(x))
  if (length(missing)) {
    stop(class_label(class(x)[1]), " layer requires a \"", missing[1], "\" field",
         call. = FALSE)
  }
  x
}

# Normalise values when setting fields of layers of the given class
normalise_field <- function(class, name, value) {
  if (is.null(value) || !"ngs_segmentation_layer" %in% class) return(value)
  switch(name,
         segments = as_segment_ids(value),
         segmentColors = as_color_map(value),
         segmentDefaultColor = to_hex(value),
         value)
}

as_color_map <- function(x) {
  if (!length(x)) return(named_list())
  if (is.null(names(x)) || any(names(x) == "")) {
    stop("`segmentColors` must be named by segment ID", call. = FALSE)
  }
  as.list(to_hex_all(x))
}

#' @export
`[[<-.ngs_layer` <- function(x, i, value) {
  cls <- oldClass(x)
  if (is_string(i)) value <- normalise_field(cls, i, value)
  x <- unclass(x)
  x[[i]] <- value
  structure(x, class = cls)
}

#' @export
`$<-.ngs_layer` <- function(x, name, value) {
  x[[name]] <- value
  x
}

#' Create layers
#'
#' Constructors for the different types of neuroglancer layers. Each layer is
#' its JSON state (a named list) with a class attached, so fields can be read
#' and set with `$` and `[[`, e.g. `layer$visible <- FALSE`. Setting the
#' `segments`, `segmentColors` or `segmentDefaultColor` fields of a
#' segmentation layer normalises their values: segment IDs are stored as
#' character and colours as hex codes.
#'
#' Constructed layers get a few default fields (e.g. `selectedAlpha` for
#' segmentation layers). `ngs_segmentation_layer()` with a graphene source
#' returns a graphene layer (see [ngs_graphene_layer()]). Layers parsed from an existing scene are kept exactly
#' as written.
#'
#' Note that, as with any list in R, setting a field to `NULL` removes it.
#' Use `NA` to write an explicit JSON `null`.
#'
#' @param source The data source: a URL string (e.g.
#'   `"precomputed://gs://bucket/path"`), a list with a `url` field and further
#'   options (e.g. `subsources`), or an unnamed list of either.
#' @param name The layer name. Names are made unique when the layer is added
#'   to a scene.
#' @param ... Further fields of the layer state, e.g. `segments`,
#'   `visible = FALSE` or `shader`.
#' @return A layer object.
#' @name layers
#' @examples
#' img <- ngs_image_layer("precomputed://gs://neuroglancer-fafb-data/fafb_v14/fafb_v14_clahe")
#' seg <- ngs_segmentation_layer("precomputed://gs://fafb-ffn1-20200412/segmentation",
#'                               segments = c(710435991, 710435992))
#' seg$segments
#' seg$segments <- c(seg$segments, "123456")
#' an <- ngs_annotation_layer()
NULL

#' @rdname layers
#' @export
ngs_image_layer <- function(source, name = "img", ...) {
  state <- list(source = source, type = "image", blend = "default",
                shaderControls = named_list(), name = name)
  make_layer(state, list(...), LAYER_CLASSES$image)
}

#' @rdname layers
#' @export
ngs_segmentation_layer <- function(source, name = "segmentation", ...) {
  # Graphene sources get a graphene layer, like parsed layers do
  if (is_graphene_source(source)) {
    return(ngs_graphene_layer(source, name = name, ...))
  }
  make_layer(segmentation_state(source, name), list(...),
             LAYER_CLASSES$segmentation)
}

segmentation_state <- function(source, name) {
  list(source = source, type = "segmentation", selectedAlpha = 0.14,
       segments = character(0), name = name)
}

#' @rdname layers
#' @export
ngs_annotation_layer <- function(source = "local://annotations",
                                 name = "annotations", ...) {
  state <- list(source = source, type = "annotation", name = name,
                annotations = list())
  make_layer(state, list(...), LAYER_CLASSES$annotation)
}

#' @rdname layers
#' @export
ngs_mesh_layer <- function(source, name = "meshes", ...) {
  state <- list(source = source, type = "mesh", name = name)
  make_layer(state, list(...), LAYER_CLASSES$mesh)
}

#' Parse layer states into layers
#'
#' Turns layer states (named lists, e.g. parsed from JSON) into layer
#' objects. States are taken as they are: no defaults are added and no values
#' changed, so they round-trip unchanged. Layers of types without a dedicated
#' class (e.g. neuroglancer's "new" layers) become generic layers which are
#' carried through verbatim.
#'
#' @param x A single layer state (named list) or an unnamed list thereof.
#' @param skip_unknown If `TRUE`, drop layers of unknown type instead of
#'   keeping them as generic layers.
#' @param skip_archived If `TRUE`, drop archived layers.
#' @return A layer, or a list of layers if `x` is a list of states.
#' @export
#' @examples
#' ngs_parse_layers(list(type = "image", source = "precomputed://gs://x/em",
#'                       name = "em"))
ngs_parse_layers <- function(x, skip_unknown = FALSE, skip_archived = TRUE) {
  if (inherits(x, "ngs_layer")) return(x)
  if (!is.list(x)) {
    stop("Expected a layer state (named list) or a list thereof, got \"",
         class(x)[1], "\"", call. = FALSE)
  }
  if (is.null(names(x))) {
    res <- lapply(x, ngs_parse_layers, skip_unknown = skip_unknown,
                  skip_archived = skip_archived)
    return(Filter(Negate(is.null), res))
  }

  if (isTRUE(x$archived) && skip_archived) return(NULL)

  ty <- x$type
  if (!is_string(ty) || is.null(LAYER_CLASSES[[ty]])) {
    if (skip_unknown) return(NULL)
    if (is.null(ty)) {
      stop("Layer \"", x$name %||% "", "\" has no type", call. = FALSE)
    }
    return(new_layer(x, "ngs_generic_layer"))
  }

  class <- LAYER_CLASSES[[ty]]
  # Mainline neuroglancer writes graphene layers as plain segmentation layers
  if (ty == "segmentation" && is_graphene_source(x$source)) {
    class <- LAYER_CLASSES$segmentation_with_graph
  }

  # Segment IDs are kept as character vectors. This doesn't change the JSON.
  segs <- x$segments
  if (is.list(segs) && (!length(segs) || is_scalar_list(segs) && is.character(segs[[1]]))) {
    x$segments <- as.character(unlist(segs))
  }

  new_layer(x, class)
}

#' @export
as.list.ngs_layer <- function(x, ...) {
  x <- unclass(x)
  # Arrays must stay arrays, even with a single element
  if (is.character(x$segments)) x$segments <- as.list(x$segments)
  x
}

#' @export
format.ngs_layer <- function(x, width = getOption("width", 80), ...) {
  src <- source_urls(x$source)
  info <- if (inherits(x, "ngs_generic_layer")) {
    paste0("type: ", x$type)
  } else if (length(src)) {
    src[1]
  } else {
    "no source"
  }
  suffix <- ""
  if (inherits(x, "ngs_segmentation_layer")) {
    n <- length(x$segments)
    suffix <- paste0(" (", plural(n, "segment"), ")")
  } else if (inherits(x, "ngs_annotation_layer") && length(x$annotations)) {
    n <- length(x$annotations)
    suffix <- paste0(" (", plural(n, "annotation"), ")")
  }
  prefix <- paste0("<", class_label(class(x)[1]), " layer> \"", x$name, "\" ")
  # Shorten the source rather than the name
  info <- truncate_middle(info, max(20, width - nchar(prefix) - nchar(suffix)))
  paste0(prefix, info, suffix)
}

#' @export
print.ngs_layer <- function(x, ...) {
  cat(format(x), "\n", sep = "")
  invisible(x)
}

# Merge two layers (used by `scene | scene`). Returns `NULL` if the layers
# can't be merged.
merge_layers <- function(x, y) UseMethod("merge_layers")

#' @export
merge_layers.default <- function(x, y) NULL

#' @export
merge_layers.ngs_image_layer <- function(x, y) {
  if (!same_kind(x, y)) return(NULL)
  # Fields of `y` take precedence but `x` keeps its name
  update_state(x, unclass(y)[setdiff(names(y), "name")])
}

#' @export
merge_layers.ngs_segmentation_layer <- function(x, y) {
  if (!same_kind(x, y)) return(NULL)
  x <- ngs_add_segments(x, ngs_segments(y))
  if (length(y$segmentColors)) {
    colors <- x$segmentColors %||% named_list()
    colors[names(y$segmentColors)] <- y$segmentColors
    x$segmentColors <- colors
  }
  x
}

same_kind <- function(x, y) {
  identical(class(x), class(y)) && identical(x$source, y$source)
}
