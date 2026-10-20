`%||%` <- function(x, y) if (is.null(x)) y else x

# Is `x` a list of plain (unclassed) scalars of a single type? Such lists can
# be `unlist()`ed without changing any values.
is_scalar_list <- function(x) {
  # Check lengths first: `unlist()` would flatten nested lists recursively
  if (!length(x) || !all(lengths(x) == 1L)) return(FALSE)
  u <- unlist(x, use.names = FALSE)
  # Re-listing gives back the same list only if no element had a different
  # type or any attributes (factor, `I()`, integer64, ...)
  is.atomic(u) && length(u) == length(x) && identical(as.list(u), unname(x))
}

DEFAULT_BASE_URL <- "https://neuroglancer-demo.appspot.com/"

# An empty list that serialises as `{}` rather than `[]`
named_list <- function() stats::setNames(list(), character(0))

plural <- function(n, word, words = paste0(word, "s")) {
  paste(n, if (n == 1) word else words)
}

is_string <- function(x) is.character(x) && length(x) == 1L && !is.na(x)

check_string <- function(x, arg = deparse(substitute(x))) {
  if (!is_string(x)) {
    stop("`", arg, "` must be a single string", call. = FALSE)
  }
  invisible(x)
}

check_class <- function(x, class, what, arg = "x") {
  if (!inherits(x, class)) stop("`", arg, "` must be ", what, call. = FALSE)
  invisible(x)
}

# "ngs_segmentation_layer" -> "segmentation"
class_label <- function(class) sub("^ngs_(.*)_layer$", "\\1", class)

# Apply named arguments (e.g. from `...`) to a state list. `NULL` values drop
# the field, matching R's usual list semantics.
update_state <- function(state, extra) {
  if (length(extra) && (is.null(names(extra)) || any(names(extra) == ""))) {
    stop("All additional arguments must be named", call. = FALSE)
  }
  for (k in names(extra)) state[[k]] <- extra[[k]]
  state
}

#' Normalise segment IDs to character
#'
#' Segment IDs are 64-bit integers, which R cannot represent natively as
#' numbers. They are therefore always stored as character. Doubles above
#' 2^53 have already lost precision, so we warn about them.
#'
#' @noRd
as_segment_ids <- function(x) {
  if (is.null(x)) return(character(0))
  if (is.list(x)) {
    if (is_scalar_list(x)) return(as_segment_ids(unlist(x, use.names = FALSE)))
    return(unlist(lapply(unname(x), as_segment_ids), use.names = FALSE) %||%
             character(0))
  }
  if (inherits(x, "integer64")) return(unname(as.character(x)))
  if (inherits(x, "ngs_number")) x <- unclass(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.double(x)) {
    if (any(x != round(x), na.rm = TRUE)) {
      stop("Segment IDs must be whole numbers", call. = FALSE)
    }
    if (any(abs(x) > 2^53, na.rm = TRUE)) {
      warning("Segment IDs above 2^53 stored as doubles have likely lost ",
              "precision. Use character or bit64::integer64 IDs instead.",
              call. = FALSE)
    }
    x <- sprintf("%.0f", x)
  }
  if (is.integer(x)) x <- as.character(x)
  if (!is.character(x)) {
    stop("Unable to interpret object of class \"", class(x)[1],
         "\" as segment IDs", call. = FALSE)
  }
  if (anyNA(x)) stop("Segment IDs must not be NA", call. = FALSE)
  unname(x)
}

#' Return the URL(s) of a layer source
#'
#' Sources can be a string, a named list (object) with a `url` or an unnamed
#' list of either.
#'
#' @noRd
source_urls <- function(source) {
  if (is.null(source)) return(character(0))
  if (is.character(source)) return(unname(source))
  if (is.list(source)) {
    if (!is.null(names(source))) {
      return(if (is.null(source$url)) character(0) else source$url)
    }
    return(unlist(lapply(source, source_urls), use.names = FALSE) %||%
             character(0))
  }
  stop("Unexpected source type \"", class(source)[1], "\"", call. = FALSE)
}

# Apply `f` to the URL(s) of a source, keeping its shape
map_source_urls <- function(source, f) {
  if (is.character(source)) return(vapply(source, f, character(1),
                                          USE.NAMES = FALSE))
  if (is.list(source)) {
    if (!is.null(names(source))) {
      if (!is.null(source$url)) source$url <- f(source$url)
      return(source)
    }
    return(lapply(source, map_source_urls, f = f))
  }
  stop("Unexpected source type \"", class(source)[1], "\"", call. = FALSE)
}

is_graphene_source <- function(source) {
  urls <- tryCatch(source_urls(source), error = function(e) character(0))
  any(startsWith(urls, "graphene://"))
}

truncate_middle <- function(x, width) {
  long <- nchar(x) > width
  half <- (width - 3) %/% 2
  x[long] <- paste0(substr(x[long], 1, half), "...",
                    substr(x[long], nchar(x[long]) - half + 1, nchar(x[long])))
  x
}
