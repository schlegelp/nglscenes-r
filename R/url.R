# URL encoding, decoding and state-server handling

# Hosts of CAVE state servers that require authentication
CAVE_STATE_HOSTS <- c("globalv1.flywire-daf.com", "global.daf-apis.com")

SCHEME_REGEX <- "[A-Za-z][A-Za-z0-9+.-]*://"

is_url <- function(x) {
  is_string(x) && grepl(paste0("^", SCHEME_REGEX, "[^/?#]+"), x)
}

# Percent-encode like Python's `urllib.parse.quote` (keeps "/")
url_quote <- function(x) {
  gsub("%2F", "/", curl::curl_escape(x), fixed = TRUE)
}

url_decode <- function(x) {
  x <- curl::curl_unescape(x)
  Encoding(x) <- "UTF-8"
  x
}

gs_to_https <- function(url) {
  sub("^gs://", "https://storage.googleapis.com/", url)
}

# The part of the base URL the state gets appended to: any existing fragment
# is dropped and a bare host gets a trailing slash
url_base <- function(base_url) {
  base <- sub("#.*$", "", base_url)
  m <- regmatches(base, regexec(paste0("^(", SCHEME_REGEX, "[^/?#]*)([^?#]*)(.*)$"),
                                base))[[1]]
  if (!length(m)) return(base)
  if (m[3] == "") m[3] <- "/"
  paste0(m[2], m[3], m[4])
}

#' Split a neuroglancer URL into its parts
#'
#' @return A list with
#'   - `base`: the URL without the state (fragment and `json_url` query)
#'   - `state`: the JSON state encoded in the fragment, or `NULL`
#'   - `remote`: if the state lives on a state server, a list with the `url`
#'     to fetch it from, whether that needs `auth` and the `host`
#' @noRd
parse_ngl_url <- function(url) {
  # States can be several MB: split at the "#" without regexes on the whole
  # string. The query (and so `json_url`) is in the short part before it.
  hash <- regexpr("#", url, fixed = TRUE)
  base <- if (hash > 0) substr(url, 1, hash - 1) else url
  fragment <- if (hash > 0) substr(url, hash + 1, nchar(url))

  remote <- NULL
  if (grepl("[?&]json_url=", base)) {
    remote <- url_decode(sub("^.*[?&]json_url=([^&]*).*$", "\\1", base))
    base <- sub("[?&]$", "", sub("([?&])json_url=[^&]*&?", "\\1", base))
  } else if (!is.null(fragment) &&
             grepl("^!(gs://|middleauth\\+|https?://)", substr(fragment, 1, 20))) {
    remote <- sub("^!", "", fragment)
  }

  state <- if (is.null(remote) && !is.null(fragment)) {
    sub("^!", "", url_decode(fragment))
  }

  list(base = base, state = state,
       remote = if (!is.null(remote)) remote_target(remote))
}

# Where to fetch a remotely stored state from, and whether that requires
# authentication
remote_target <- function(target) {
  auth <- startsWith(target, "middleauth+")
  target <- gs_to_https(sub("^middleauth\\+", "", target))
  host <- httr2::url_parse(target)$hostname
  list(url = target, auth = auth || host %in% CAVE_STATE_HOSTS, host = host)
}

# Extract the JSON state from a URL, JSON string or list. For URLs, the base
# URL is attached as attribute.
as_state <- function(x) {
  if (is.list(x)) return(x)
  check_string(x)
  x <- trimws(x)
  if (!is_url(x)) return(parse_json_state(x))

  parts <- parse_ngl_url(x)
  if (!is.null(parts$remote)) {
    state <- fetch_state(parts$remote)
  } else if (!is.null(parts$state)) {
    state <- parse_json_state(parts$state)
  } else {
    stop("URL does not contain a neuroglancer state: ", x, call. = FALSE)
  }
  structure(state, base_url = parts$base)
}

fetch_state <- function(target) {
  token <- if (target$auth) ngs_cave_token(c(target$host, "prod.flywire-daf.com"))
  fetch_json(target$url, token = token)
}

fetch_json <- function(url, token = NULL) {
  req <- httr2::request(url)
  if (!is.null(token)) req <- httr2::req_auth_bearer_token(req, token)
  resp <- httr2::req_perform(req)
  parse_json_state(httr2::resp_body_string(resp, encoding = "UTF-8"))
}

#' Get a CAVE token
#'
#' Looks up the token used to fetch scenes from CAVE state servers (e.g. for
#' FlyWire). In order, this checks:
#'
#' 1. the `CAVE_TOKEN` and `CHUNKEDGRAPH_SECRET` environment variables
#' 2. the `cloudvolume` secrets in `~/.cloudvolume/secrets/`:
#'    `{domain}-cave-secret.json` for each `domain`, then
#'    `cave-secret.json` and `chunkedgraph-secret.json`
#'
#' This is compatible with tokens set up via Python's `cloudvolume` /
#' `caveclient` or `fafbseg::flywire_set_token()`.
#'
#' @param domain Domain(s) to look for a domain-specific secret file for.
#' @return The token (a string).
#' @export
#' @examples
#' \dontrun{
#' ngs_cave_token()
#' }
ngs_cave_token <- function(domain = "prod.flywire-daf.com") {
  for (var in c("CAVE_TOKEN", "CHUNKEDGRAPH_SECRET")) {
    token <- Sys.getenv(var)
    if (nzchar(token)) return(token)
  }

  dir <- file.path(path.expand("~"), ".cloudvolume", "secrets")
  files <- file.path(dir, c(paste0(domain, "-cave-secret.json"),
                            "cave-secret.json", "chunkedgraph-secret.json"))
  for (f in files[file.exists(files)]) {
    token <- tryCatch(jsonlite::read_json(f)$token, error = function(e) NULL)
    if (is_string(token) && nzchar(token)) return(token)
  }

  stop("No CAVE token found. Set the `CAVE_TOKEN` environment variable or ",
       "store the token in ~/.cloudvolume/secrets/cave-secret.json",
       call. = FALSE)
}
