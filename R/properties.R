# Segment properties are the info JSON (a named list) with class
# "ngs_segment_properties". IDs and property values are kept as vectors and
# only turned into (JSON) arrays by `as.list()`.
#
# See https://github.com/google/neuroglancer/blob/master/src/datasource/precomputed/segment_properties.md

PROPERTY_TYPES <- c("label", "description", "string", "tags", "number")

check_properties <- function(x) {
  check_class(x, "ngs_segment_properties", "segment properties")
}

#' Segment properties
#'
#' Create neuroglancer segment properties, e.g. to label segments or to make
#' them searchable by tags. Start with `ngs_segment_properties()` and add
#' properties with [ngs_add_property()], or create them from a data frame
#' with `ngs_properties_from_df()`. Write them to an info file with
#' [ngs_write_info()] and convert them back with `as.data.frame()`.
#'
#' @param ids Segment IDs. Must be unique.
#' @param df A data frame with segment IDs and one column per property. See
#'   [ngs_add_property()] for how column types are interpreted.
#' @param id_col Name of the column in `df` with the segment IDs.
#' @param url URL of a segment properties info file, or of a segmentation
#'   source whose info file points to segment properties. `precomputed://`
#'   and `gs://` URLs are supported.
#' @param x An info file parsed into a list.
#' @return Segment properties.
#' @export
#' @examples
#' df <- data.frame(id = c(1, 2, 3),
#'                  name = c("DA1_lPN", "DA1_lPN", "KCg"),
#'                  size = c(10.5, 12, 3),
#'                  class = factor(c("PN", "PN", "KC")))
#' props <- ngs_properties_from_df(df)
#' props
#' as.data.frame(props)
#' cat(ngs_to_json(props, pretty = TRUE))
ngs_segment_properties <- function(ids) {
  ids <- as_segment_ids(ids)
  if (anyDuplicated(ids)) stop("Segment IDs must be unique", call. = FALSE)
  structure(list(`@type` = "neuroglancer_segment_properties",
                 inline = list(ids = ids, properties = list())),
            class = "ngs_segment_properties")
}

#' @rdname ngs_segment_properties
#' @export
ngs_properties_from_df <- function(df, id_col = "id") {
  check_class(df, "data.frame", "a data frame", "df")
  if (!id_col %in% names(df)) {
    stop("ID column \"", id_col, "\" not in data frame", call. = FALSE)
  }
  props <- ngs_segment_properties(df[[id_col]])
  for (col in setdiff(names(df), id_col)) {
    props <- ngs_add_property(props, df[[col]], name = col)
  }
  props
}

#' @rdname ngs_segment_properties
#' @export
ngs_properties_from_url <- function(url) {
  check_string(url)
  url <- sub("^precomputed://", "", url)
  url <- gs_to_https(url)
  url <- sub("/+$", "", url)
  if (!grepl("/info$", url)) url <- paste0(url, "/info")

  info <- fetch_json(url)
  if (!identical(info$`@type`, "neuroglancer_segment_properties")) {
    if (is.null(info$segment_properties)) {
      stop("No segment properties found at ", url, call. = FALSE)
    }
    base <- sub("/info$", "", url)
    return(ngs_properties_from_url(paste0(base, "/", info$segment_properties)))
  }
  ngs_properties_from_list(info)
}

#' @rdname ngs_segment_properties
#' @export
ngs_properties_from_list <- function(x) {
  if (!is.list(x) || is.null(x$inline$ids)) {
    stop("`x` must be a segment properties info with inline IDs",
         call. = FALSE)
  }
  x$inline$ids <- as_segment_ids(x$inline$ids)
  x$inline$properties <- lapply(x$inline$properties %||% list(), function(p) {
    if (identical(p$type, "tags")) {
      p$values <- if (all(lengths(p$values) == 1L)) {
        as.list(as.integer(unlist(p$values)))
      } else {
        lapply(p$values, function(v) as.integer(unlist(v)))
      }
      p$tags <- as.character(unlist(p$tags))
    } else {
      p$values <- unlist(p$values)
    }
    p
  })
  structure(x, class = "ngs_segment_properties")
}

#' Add a segment property
#'
#' @param x Segment properties.
#' @param values Property values, one per segment. Unless `type` is given,
#'   the type is inferred from the values:
#'   - numbers become `"number"` properties
#'   - the first character vector becomes the `"label"` property, subsequent
#'     ones `"string"` properties
#'   - factors and lists (e.g. `list(c("a", "b"), "c")`) become `"tags"`
#'     properties. Tags are made valid by removing leading `#` and replacing
#'     spaces with `_`.
#' @param name Name (ID) of the property.
#' @param type One of `"label"`, `"description"`, `"string"`, `"tags"` or
#'   `"number"`. Default is to infer the type from `values`.
#' @param description Optional description of the property.
#' @return The modified segment properties.
#' @export
#' @examples
#' props <- ngs_segment_properties(c("1", "2"))
#' props <- ngs_add_property(props, c("PN", "KC"), name = "type")
#' props <- ngs_add_property(props, list(c("left", "olfactory"), "right"),
#'                           name = "tags")
ngs_add_property <- function(x, values, name, type = NULL,
                             description = NULL) {
  check_properties(x)
  check_string(name)
  n <- length(x$inline$ids)
  if (length(values) != n) {
    stop("Got ", length(values), " values for ", n, " segments",
         call. = FALSE)
  }
  if (!is.list(values) && anyNA(values)) {
    stop("Property \"", name, "\" contains NAs", call. = FALSE)
  }

  if (is.null(type)) type <- infer_property_type(x, values, name)
  type <- match.arg(type, PROPERTY_TYPES)

  prop <- switch(type,
                 number = number_property(values),
                 tags = tags_property(values),
                 list(values = as.character(values)))
  prop <- c(list(id = name, type = type), prop)
  if (!is.null(description)) prop$description <- description

  x$inline$properties <- c(x$inline$properties, list(prop))
  x
}

infer_property_type <- function(x, values, name) {
  if (is.factor(values) || is.list(values)) return("tags")
  if (is.numeric(values)) return("number")
  if (is.character(values)) {
    # There can only be one "label" property
    if (!"label" %in% ngs_property_types(x)) return("label")
    message("Already have a \"label\" property: adding \"", name,
            "\" as \"string\" property.")
    return("string")
  }
  stop("Unable to infer property type for values of class \"",
       class(values)[1], "\"", call. = FALSE)
}

number_property <- function(values) {
  if (!is.numeric(values)) stop("Number properties must be numeric",
                                call. = FALSE)
  # Neuroglancer only supports 32-bit numbers
  list(data_type = if (is.integer(values)) "int32" else "float32",
       values = as.vector(values))
}

fix_tag <- function(x) gsub(" ", "_", sub("^#", "", as.character(x)))

tags_property <- function(values) {
  if (is.list(values)) {
    values <- lapply(values, function(v) fix_tag(unlist(v)))
    tags <- sort(unique(unlist(values)), method = "radix")
    return(list(tags = tags,
                values = lapply(values, function(v) match(v, tags) - 1L)))
  }
  if (is.factor(values)) {
    levels(values) <- fix_tag(levels(values))
    tags <- levels(droplevels(values))
  } else {
    tags <- unique(fix_tag(values))
  }
  # One tag per segment: match in one go
  list(tags = tags, values = as.list(match(fix_tag(values), tags) - 1L))
}

#' Property types
#'
#' @param x Segment properties.
#' @return Named character vector of property types (names are the property
#'   IDs).
#' @export
ngs_property_types <- function(x) {
  check_properties(x)
  props <- x$inline$properties
  stats::setNames(vapply(props, function(p) p$type, character(1)),
                  vapply(props, function(p) p$id, character(1)))
}

#' Write segment properties to an info file
#'
#' @param x Segment properties.
#' @param path Path of the file to write. Neuroglancer expects it to be
#'   called `info`.
#' @return `x`, invisibly.
#' @export
ngs_write_info <- function(x, path) {
  check_properties(x)
  ngs_to_file(x, path)
}

#' @export
as.list.ngs_segment_properties <- function(x, ...) {
  x <- unclass(x)
  x$inline$ids <- as.list(x$inline$ids)
  x$inline$properties <- lapply(x$inline$properties, function(p) {
    if (identical(p$type, "tags")) {
      p$values <- lapply(p$values, as.list)
      p$tags <- as.list(p$tags)
    } else {
      p$values <- as.list(p$values)
    }
    p
  })
  x
}

#' @export
as.data.frame.ngs_segment_properties <- function(x, row.names = NULL,
                                                 optional = FALSE, ...) {
  df <- data.frame(id = x$inline$ids)
  for (p in x$inline$properties) {
    if (identical(p$type, "tags")) {
      tags <- lapply(p$values, function(v) p$tags[v + 1L])
      if (all(lengths(tags) == 1L)) {
        df[[p$id]] <- factor(unlist(tags), levels = p$tags)
      } else {
        df[[p$id]] <- I(tags)
      }
    } else {
      df[[p$id]] <- p$values
    }
  }
  df
}

#' @export
print.ngs_segment_properties <- function(x, ...) {
  types <- ngs_property_types(x)
  cat("<ngs_segment_properties> ", plural(length(x$inline$ids), "segment"), ", ",
      plural(length(types), "property", "properties"), "\n", sep = "")
  if (length(types)) cat(paste0("  ", names(types), " (", types, ")"), sep = "\n")
  invisible(x)
}
