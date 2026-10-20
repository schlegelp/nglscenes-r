# Colour handling

# Matplotlib's single-letter colour codes (also accepted by Python nglscenes)
SHORT_COLORS <- c(b = "#0000ff", g = "#008000", r = "#ff0000", c = "#00bfbf",
                  m = "#bf00bf", y = "#bfbf00", k = "#000000", w = "#ffffff")

# Convert a single colour (name, hex code or RGB(A) values in 0-1) to
# "#rrggbb". Any alpha channel is dropped.
to_hex <- function(x) {
  if (is.numeric(x)) return(rgb_to_hex(matrix(x, nrow = 1)))
  if (is_string(x) || is.factor(x) && length(x) == 1L) {
    return(col_to_hex(as.character(x)))
  }
  stop("Unable to interpret object of class \"", class(x)[1], "\" as colour",
       call. = FALSE)
}

# Convert a matrix with one RGB(A) colour (0-1) per row
rgb_to_hex <- function(m) {
  if (!is.numeric(m) || !ncol(m) %in% 3:4) {
    stop("Numeric colours must be RGB(A) values of length 3 or 4",
         call. = FALSE)
  }
  if (any(is.na(m) | m < 0 | m > 1)) {
    stop("RGB values must be in the 0-1 range", call. = FALSE)
  }
  tolower(grDevices::rgb(m[, 1], m[, 2], m[, 3]))
}

# Vectorised conversion of colour names/hex codes
col_to_hex <- function(x) {
  x <- as.character(x)
  # col2rgb() would silently turn NA into white
  if (anyNA(x)) stop("Colours must not be NA", call. = FALSE)
  # Already normalised, e.g. when setting a map we converted before
  todo <- !grepl("^#[0-9a-f]{6}$", x, perl = TRUE)
  if (!any(todo)) return(x)
  y <- x[todo]
  short <- y %in% names(SHORT_COLORS)
  y[short] <- SHORT_COLORS[y[short]]
  m <- tryCatch(grDevices::col2rgb(y),
                error = function(e) stop("Invalid colour(s): ", conditionMessage(e),
                                         call. = FALSE))
  x[todo] <- tolower(grDevices::rgb(m[1, ], m[2, ], m[3, ], maxColorValue = 255))
  x
}

# Convert a list or vector of colours to hex codes, keeping names. Colour
# strings are converted in one go, only RGB values one by one.
to_hex_all <- function(x) {
  if (!is.list(x)) return(stats::setNames(col_to_hex(x), names(x)))
  # Usually all colour strings
  u <- unlist(x, use.names = FALSE)
  if (is.character(u) && length(u) == length(x)) {
    return(stats::setNames(col_to_hex(u), names(x)))
  }
  out <- character(length(x))
  is_chr <- vapply(x, is_string, logical(1))
  out[is_chr] <- col_to_hex(unlist(x[is_chr], use.names = FALSE))
  out[!is_chr] <- vapply(x[!is_chr], to_hex, character(1))
  stats::setNames(out, names(x))
}

# Matplotlib palette names that differ from R's beyond case and punctuation
PALETTE_ALIASES <- c(tab10 = "Tableau 10")

# Generate `n` colours from a palette name or function
palette_colors <- function(palette, n) {
  if (is.function(palette)) return(palette(n))
  check_string(palette)
  # Ignore case and punctuation, e.g. "viridis" for "Viridis" or "Set1" for
  # "Set 1"
  key <- function(x) gsub("[^a-z0-9]", "", tolower(x))
  name <- key(palette)
  if (name %in% names(PALETTE_ALIASES)) name <- key(PALETTE_ALIASES[[name]])

  pals <- grDevices::palette.pals()
  ix <- match(name, key(pals))
  if (!is.na(ix)) {
    return(rep_len(unname(grDevices::palette.colors(NULL, pals[ix])), n))
  }
  pals <- grDevices::hcl.pals()
  ix <- match(name, key(pals))
  if (!is.na(ix)) {
    return(grDevices::hcl.colors(n, pals[ix]))
  }
  stop("Unknown palette \"", palette, "\". See grDevices::palette.pals() and ",
       "grDevices::hcl.pals() for available palettes.", call. = FALSE)
}
