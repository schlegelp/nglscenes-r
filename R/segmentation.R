# Helpers for segmentation layers. They all accept either a segmentation
# layer or a scene. For scenes, `layer` picks the layer to act on (by name or
# position); if not given, the scene must have exactly one segmentation
# layer.

#' Selected segments
#'
#' `ngs_segments()` returns the selected segments, `ngs_add_segments()` and
#' `ngs_remove_segments()` select and deselect segments.
#'
#' Neuroglancer marks segments that are selected but hidden with a leading
#' `!` (e.g. `"!12345"`). Adding a hidden segment makes it visible, and
#' removing a segment also removes it if hidden.
#'
#' @param x A segmentation layer or a scene.
#' @param segments Segment IDs (character, numeric or `bit64::integer64`).
#' @param layer If `x` is a scene: name or position of the segmentation
#'   layer. Can be omitted if the scene has only one segmentation layer.
#' @return `ngs_segments()` returns a character vector of segment IDs, the
#'   others the modified layer or scene.
#' @export
#' @examples
#' seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:3)
#' ngs_segments(seg)
#'
#' sc <- ngs_scene(seg)
#' sc <- ngs_add_segments(sc, c(4, 5))
#' sc <- ngs_remove_segments(sc, 1)
#' ngs_segments(sc)
ngs_segments <- function(x, layer = NULL) {
  as_segment_ids(resolve_layer(x, layer, "ngs_segmentation_layer")$segments)
}

#' @rdname ngs_segments
#' @export
ngs_add_segments <- function(x, segments, layer = NULL) {
  with_layer(x, layer, "ngs_segmentation_layer", function(x) {
    segments <- as_segment_ids(segments)
    current <- setdiff(ngs_segments(x), paste0("!", segments))
    x$segments <- union(current, segments)
    x
  })
}

#' @rdname ngs_segments
#' @export
ngs_remove_segments <- function(x, segments, layer = NULL) {
  with_layer(x, layer, "ngs_segmentation_layer", function(x) {
    segments <- as_segment_ids(segments)
    x$segments <- setdiff(ngs_segments(x), c(segments, paste0("!", segments)))
    x
  })
}

#' Set segment colours
#'
#' @inheritParams ngs_segments
#' @param colors Colours to set. Colours can be names (`"red"`, also
#'   matplotlib's single letters like `"r"`), hex codes or RGB(A) values in the
#'   0-1 range. Can be:
#'   - a single colour for all selected segments
#'   - a vector (or list) of colours, one per selected segment
#'   - a matrix of RGB values with one row per selected segment
#'   - a vector (or list) of colours named by segment ID
#' @return The modified layer or scene. Existing colours of other segments are
#'   kept.
#' @export
#' @examples
#' seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:3)
#' seg <- ngs_set_colors(seg, "red")
#' seg <- ngs_set_colors(seg, c("1" = "blue"))
#' seg <- ngs_set_colors(seg, c(0, 1, 0))
#' seg$segmentColors
#'
#' # Scenes work too
#' sc <- ngs_scene(seg, ngs_segmentation_layer("precomputed://gs://y/seg",
#'                                             name = "other"))
#' sc <- ngs_set_colors(sc, "white", layer = "segmentation")
ngs_set_colors <- function(x, colors, layer = NULL) {
  with_layer(x, layer, "ngs_segmentation_layer", function(x) {
    segs <- ngs_segments(x)

    if (is.matrix(colors)) colors <- rgb_to_hex(colors)

    if (!is.null(names(colors))) {
      map <- colors
    } else if (is.numeric(colors) || length(colors) == 1L) {
      # A single colour: convert once
      map <- stats::setNames(rep(to_hex(colors), length(segs)), segs)
    } else {
      if (length(colors) != length(segs)) {
        stop("Got ", length(colors), " colours for ", length(segs), " segments",
             call. = FALSE)
      }
      map <- stats::setNames(colors, segs)
    }

    # Setting `segmentColors` converts the colours to hex codes
    current <- x$segmentColors %||% named_list()
    current[names(map)] <- as.list(map)
    x$segmentColors <- current
    x
  })
}

#' Colour segments by a property
#'
#' @inheritParams ngs_segments
#' @param by Values to colour by. Must have one value per selected segment.
#' @param palette Either the name of a palette (anything in
#'   [grDevices::palette.pals()] or [grDevices::hcl.pals()], case-insensitive;
#'   `"tab10"` is an alias for `"Tableau 10"`), a function returning `n`
#'   colours, or a vector (or list) of colours named by the values in `by`.
#' @return The modified layer or scene. Replaces any existing segment colours.
#' @export
#' @examples
#' seg <- ngs_segmentation_layer("precomputed://gs://x/seg", segments = 1:4)
#' seg <- ngs_color_by(seg, c("A", "B", "A", "C"))
#' seg <- ngs_color_by(seg, c("A", "B", "A", "C"), palette = "viridis")
#' seg <- ngs_color_by(seg, c("A", "B", "A", "B"),
#'                     palette = c(A = "red", B = "blue"))
ngs_color_by <- function(x, by, palette = "tab10", layer = NULL) {
  with_layer(x, layer, "ngs_segmentation_layer", function(x) {
    segs <- ngs_segments(x)
    if (anyNA(by)) stop("`by` must not contain NAs", call. = FALSE)
    if (length(by) != length(segs)) {
      stop("Got ", length(by), " values for ", length(segs), " segments",
           call. = FALSE)
    }

    values <- if (is.factor(by)) levels(droplevels(by)) else sort(unique(by))
    values <- as.character(values)
    by <- as.character(by)

    if ((is.character(palette) || is.list(palette)) && !is.null(names(palette))) {
      missing <- setdiff(values, names(palette))
      if (length(missing)) {
        stop("Palette has no colour for: ", paste(missing, collapse = ", "),
             call. = FALSE)
      }
      colors <- palette[values]
    } else {
      colors <- palette_colors(palette, length(values))
    }

    # Setting `segmentColors` converts the colours to hex codes
    colors <- unname(colors)[match(by, values)]
    x$segmentColors <- stats::setNames(as.list(colors), segs)
    x
  })
}

#' Clear segment colours
#'
#' @inheritParams ngs_segments
#' @return The modified layer or scene.
#' @export
ngs_clear_colors <- function(x, layer = NULL) {
  with_layer(x, layer, "ngs_segmentation_layer", function(x) {
    x$segmentColors <- NULL
    x
  })
}

#' Invert segment selection
#'
#' Selects the segments matching the layer's segment query (`segmentQuery`)
#' that are currently not selected, and deselects all others.
#'
#' @inheritParams ngs_segments
#' @return The modified layer or scene.
#' @export
ngs_invert <- function(x, layer = NULL) {
  with_layer(x, layer, "ngs_segmentation_layer", function(x) {
    query <- trimws(strsplit(x$segmentQuery %||% "", ",", fixed = TRUE)[[1]])
    query <- query[nzchar(query)]
    x$segments <- setdiff(query, ngs_segments(x))
    x
  })
}

#' Add a source to a layer
#'
#' @param x A layer or a scene.
#' @param source The source to add (e.g. a skeleton source).
#' @param layer If `x` is a scene: name or position of the layer. Can be
#'   omitted if the scene has only one layer.
#' @return The modified layer or scene.
#' @export
#' @examples
#' seg <- ngs_segmentation_layer("precomputed://gs://x/seg")
#' seg <- ngs_add_source(seg, "precomputed://gs://x/skeletons")
#' seg$source
ngs_add_source <- function(x, source, layer = NULL) {
  with_layer(x, layer, "ngs_layer", function(x) {
    current <- x$source
    if (is.character(current) || (is.list(current) && !is.null(names(current)))) {
      x$source <- list(current, source)
    } else if (is.list(current)) {
      x$source <- c(current, list(source))
    } else {
      x$source <- source
    }
    x
  })
}
