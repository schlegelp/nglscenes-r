# JSON (de)serialisation.
#
# Neuroglancer states must round-trip unchanged, which jsonlite's defaults do
# not guarantee: they drop precision on doubles and cannot tell a length-1
# array from a scalar. We therefore parse without any simplification (arrays
# become unnamed lists, objects named lists) and write with our own small
# serialiser that follows these rules:
#
#  - named lists are objects (keys sorted, like Python's `sort_keys=True`)
#  - unnamed lists are arrays
#  - atomic vectors of length 1 are scalars unless wrapped in `I()`
#  - other atomic vectors are arrays (names are ignored)
#  - `NULL` and `NA` are `null`
#  - doubles are written with the fewest digits that round-trip exactly
#  - parsed integers with 16+ digits (e.g. 64-bit segment IDs written as
#    numbers) are kept verbatim with class "ngs_number" and written back
#    unchanged, as doubles can't represent them exactly

# Marks large integers while parsing. Control characters can't appear
# unescaped in JSON strings, so this can't clash with real strings.
BIGNUM_MARK <- "\001ngs_number:"

parse_json_state <- function(x) {
  # Quick check for 16+ digit numbers (numbers follow "[", ":" or ","), then
  # find those outside of strings and turn them into marked strings
  marked <- FALSE
  if (grepl("[\\[:,]\\s*-?\\d{16}", x, perl = TRUE)) {
    m <- gregexpr('"(?:[^"\\\\]++|\\\\.)*+"|(?<![\\d.])-?\\d{16,}(?![\\d.eE])', x,
                  perl = TRUE)
    tokens <- regmatches(x, m)[[1]]
    num <- !startsWith(tokens, "\"")
    if (any(num)) {
      # Escaped in the JSON, the parsed string starts with BIGNUM_MARK
      tokens[num] <- paste0("\"\\u0001ngs_number:", tokens[num], "\"")
      regmatches(x, m) <- list(tokens)
      marked <- TRUE
    }
  }
  state <- jsonlite::parse_json(x, simplifyVector = FALSE)
  if (marked) state <- unmark_numbers(state)
  state
}

unmark_numbers <- function(x) {
  if (is.list(x)) {
    x[] <- lapply(x, unmark_numbers)
  } else if (is_string(x) && startsWith(x, BIGNUM_MARK)) {
    x <- structure(substring(x, nchar(BIGNUM_MARK) + 1), class = "ngs_number")
  }
  x
}

to_json <- function(x, pretty = FALSE) {
  json_value(x, pretty = pretty, level = 0L)
}

# Python's json.dumps(indent=4)
JSON_INDENT <- "    "

json_value <- function(x, pretty, level) {
  if (is.null(x)) return("null")

  if (is.list(x)) {
    if (!is.null(names(x))) return(json_object(x, pretty, level))
    return(json_array(json_values(x, pretty, level + 1L), pretty, level))
  }

  if (!is.atomic(x)) {
    stop("Unable to convert object of class \"", class(x)[1], "\" to JSON",
         call. = FALSE)
  }

  items <- json_atomic(x)
  if (length(x) == 1L && !inherits(x, "AsIs")) return(items)
  json_array(items, pretty, level)
}

# Serialise the elements of a list. Lists of plain scalars of one type (e.g.
# parsed segment IDs) are converted in one vectorised go.
json_values <- function(x, pretty, level) {
  if (is_scalar_list(x)) return(json_atomic(unlist(x, use.names = FALSE)))
  if (is_array_list(x)) return(json_arrays(x, pretty, level))
  vapply(x, json_value, character(1), pretty = pretty, level = level,
         USE.NAMES = FALSE)
}

# Is `x` a list of unnamed lists of scalars, i.e. an array of arrays (e.g.
# the values of a tags property)?
is_array_list <- function(x) {
  if (!length(x) || !is.null(names(x)) ||
      !all(vapply(x, is.list, logical(1))) ||
      any(vapply(x, is.object, logical(1))) ||
      # Empty objects (`named list()`) are not arrays
      !all(vapply(lapply(x, names), is.null, logical(1)))) {
    return(FALSE)
  }
  flat <- unlist(x, recursive = FALSE)
  is.null(names(flat)) && (!length(flat) || is_scalar_list(flat))
}

# Serialise an array of arrays in one vectorised go: write all values, then
# split them back into one array per element
json_arrays <- function(x, pretty, level) {
  n <- lengths(x)
  out <- rep("[]", length(x))
  if (!any(n)) return(out)

  if (pretty) {
    pad <- strrep(JSON_INDENT, level + 1L)
    sep <- paste0(",\n", pad)
    open <- paste0("[\n", pad)
    close <- paste0("\n", strrep(JSON_INDENT, level), "]")
  } else {
    sep <- ","
    open <- "["
    close <- "]"
  }

  values <- json_atomic(unlist(x, use.names = FALSE))
  # "\001" can't occur in the output: control characters are escaped
  seps <- rep(sep, length(values))
  seps[cumsum(n[n > 0])] <- "\001"
  arrays <- strsplit(paste0(values, seps, collapse = ""), "\001", fixed = TRUE)[[1]]
  out[n > 0] <- paste0(open, arrays, close)
  out
}

json_object <- function(x, pretty, level) {
  if (!length(x)) return("{}")
  ord <- order(names(x), method = "radix")
  values <- json_values(x[ord], pretty, level + 1L)
  keys <- json_string(names(x)[ord])
  if (!pretty) {
    return(paste0("{", paste0(keys, ":", values, collapse = ","), "}"))
  }
  pad <- strrep(JSON_INDENT, level + 1L)
  paste0("{\n", paste0(pad, keys, ": ", values, collapse = ",\n"), "\n",
         strrep(JSON_INDENT, level), "}")
}

json_array <- function(items, pretty, level) {
  if (!length(items)) return("[]")
  if (!pretty) return(paste0("[", paste(items, collapse = ","), "]"))
  pad <- strrep(JSON_INDENT, level + 1L)
  paste0("[\n", paste0(pad, items, collapse = ",\n"), "\n",
         strrep(JSON_INDENT, level), "]")
}

json_atomic <- function(x) {
  if (is.factor(x)) x <- as.character(x)

  if (inherits(x, "integer64")) {
    out <- as.character(x)
  } else if (inherits(x, "ngs_number")) {
    # Kept verbatim from parsing
    out <- unclass(x)
  } else if (is.character(x)) {
    out <- json_string(x)
  } else if (is.logical(x)) {
    out <- ifelse(x, "true", "false")
  } else if (is.integer(x)) {
    out <- as.character(x)
  } else if (is.double(x)) {
    out <- json_number(x)
  } else {
    stop("Unable to convert values of type \"", typeof(x), "\" to JSON",
         call. = FALSE)
  }
  out[is.na(x)] <- "null"
  unname(out)
}

# Shortest representation that parses back to the same double
json_number <- function(x) {
  out <- sprintf("%.15g", x)
  redo <- is.finite(x)
  for (digits in c(16, 17)) {
    # Only re-check values that haven't round-tripped yet
    redo[redo] <- parse_numbers(out[redo]) != x[redo]
    if (!any(redo)) break
    out[redo] <- sprintf(paste0("%.", digits, "g"), x[redo])
  }
  # JSON has no Inf or NaN
  out[!is.finite(x)] <- "null"
  out
}

# R's own `as.numeric()` does not always round long decimals correctly, which
# would make us use more digits than necessary. jsonlite uses C's `strtod`.
parse_numbers <- function(x) {
  if (!length(x)) return(numeric(0))
  as.numeric(jsonlite::parse_json(paste0("[", paste(x, collapse = ","), "]"),
                                  simplifyVector = TRUE))
}

# Escapes for characters JSON doesn't allow verbatim in strings
JSON_ESCAPES <- local({
  ctrl <- 1:31
  esc <- stats::setNames(sprintf("\\u%04x", ctrl), intToUtf8(ctrl, multiple = TRUE))
  short <- c("\b" = "\\b", "\t" = "\\t", "\n" = "\\n", "\f" = "\\f",
             "\r" = "\\r")
  esc[names(short)] <- short
  # The backslash must come first so we don't escape our own escapes
  c("\\" = "\\\\", "\"" = "\\\"", esc)
})

json_string <- function(x) {
  if (!length(x)) return(character(0))
  x <- enc2utf8(as.character(x))
  # Most strings (IDs, colours, names) need no escaping
  todo <- grepl("[\"\\\\\001-\037]", x, perl = TRUE)
  if (any(todo)) {
    y <- x[todo]
    for (ch in names(JSON_ESCAPES)) {
      y <- gsub(ch, JSON_ESCAPES[[ch]], y, fixed = TRUE)
    }
    x[todo] <- y
  }
  paste0("\"", x, "\"")
}
