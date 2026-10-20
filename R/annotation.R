#' Add point annotations
#'
#' @param x An annotation layer or a scene.
#' @param points The points to add. Either a data frame with `x`, `y` and `z`
#'   columns (and optionally an `id` column), a matrix with three columns or
#'   a single numeric vector of length 3.
#' @param ids Optional IDs for the points. If not given (and not in
#'   `points`), the points are numbered consecutively.
#' @param layer If `x` is a scene: name or position of the annotation layer.
#'   Can be omitted if the scene has only one annotation layer.
#' @return The modified layer or scene.
#' @export
#' @examples
#' an <- ngs_annotation_layer()
#' an <- ngs_add_points(an, data.frame(x = 1:3, y = 4:6, z = 7:9))
#' an <- ngs_add_points(an, c(10, 20, 30))
#' as.data.frame(an)
#'
#' sc <- ngs_scene(ngs_image_layer("precomputed://gs://x/em"), an)
#' sc <- ngs_add_points(sc, c(1, 2, 3))
ngs_add_points <- function(x, points, ids = NULL, layer = NULL) {
  with_layer(x, layer, "ngs_annotation_layer", function(x) {

    if (is.data.frame(points)) {
      if (!all(c("x", "y", "z") %in% names(points))) {
        stop("Data frame must contain \"x\", \"y\" and \"z\" columns",
             call. = FALSE)
      }
      if (is.null(ids) && "id" %in% names(points)) ids <- points$id
      points <- as.matrix(points[, c("x", "y", "z")])
    } else if (is.numeric(points) && is.null(dim(points))) {
      points <- matrix(points, nrow = 1)
    }
    if (!is.matrix(points) || ncol(points) != 3 || !is.numeric(points)) {
      stop("Expected a data frame, a numeric (N, 3) matrix or a vector of ",
           "length 3", call. = FALSE)
    }

    current <- x$annotations %||% list()
    if (is.null(ids)) {
      # Number consecutively, skipping IDs already in use
      used <- vapply(current, function(a) as.character(a$id %||% NA), character(1))
      free <- setdiff(as.character(seq_len(nrow(points) + length(current)) - 1),
                      used)
      ids <- free[seq_len(nrow(points))]
    }
    if (length(ids) != nrow(points)) {
      stop("Got ", length(ids), " IDs for ", nrow(points), " points",
           call. = FALSE)
    }
    ids <- as_segment_ids(ids)

    new <- lapply(seq_len(nrow(points)), function(i) {
      list(id = ids[i], type = "point", point = as.numeric(points[i, ]))
    })
    x$annotations <- c(current, new)
    x
  })
}

#' Remove all annotations
#'
#' @inheritParams ngs_add_points
#' @return The modified layer or scene.
#' @export
ngs_clear_annotations <- function(x, layer = NULL) {
  with_layer(x, layer, "ngs_annotation_layer", function(x) {
    x$annotations <- list()
    x
  })
}

#' Point annotations as data frame
#'
#' @param x An annotation layer.
#' @param row.names,optional,... Ignored.
#' @return A data frame with `id`, `x`, `y` and `z` columns. Annotations
#'   that are not points are dropped with a warning.
#' @export
as.data.frame.ngs_annotation_layer <- function(x, row.names = NULL,
                                               optional = FALSE, ...) {
  annotations <- x$annotations %||% list()
  is_point <- vapply(annotations, function(a) identical(a$type, "point"),
                     logical(1))
  if (any(!is_point)) {
    warning("Dropped ", sum(!is_point), " annotations that are not points",
            call. = FALSE)
  }
  points <- annotations[is_point]
  coords <- vapply(points, function(a) as.numeric(unlist(a$point))[1:3],
                   numeric(3))
  coords <- matrix(coords, ncol = 3, byrow = TRUE)
  data.frame(id = vapply(points, function(a) as.character(a$id %||% NA),
                         character(1)),
             x = coords[, 1], y = coords[, 2], z = coords[, 3])
}
