# Private -----------------------------------------------------------------

# Default engine property values.
DEFAULT_ARRAY_ORDER <- "row-major"
DEFAULT_COERCE_FACTORS <- TRUE
DEFAULT_DATA_FRAME_ROW_MAJOR <- TRUE
DEFAULT_INTERPOLATE <- TRUE
DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY <- FALSE
DEFAULT_STANDARD_OUTPUT_MODE <- "console"
DEFAULT_STRINGS_AS_FACTORS <- NULL

# User-defined type codes for use with jdx.
CALLBACK_EVALUATION <- 0x01000000
CALLBACK_GET_VALUE <- 0x02000000
CALLBACK_SET_VALUE <- 0x03000000

# Taken directly from rscala package written by David B. Dahl.
strintrplt <- function (snippet, envir = parent.frame()) {
  if (!is.character(snippet))
    stop("Character vector expected.")
  if (length(snippet) != 1)
    stop("Length of vector must be exactly one.")
  m <- regexpr("@\\{([^\\}]+)\\}", snippet)
  if (m != -1) {
    s1 <- substr(snippet, 1, m - 1)
    s2 <- substr(snippet, m + 2, m + attr(m, "match.length") - 2)
    s3 <- substr(snippet, m + attr(m, "match.length"), nchar(snippet))
    strintrplt(paste(s1, paste(toString(eval(parse(text = s2),
      envir = envir)), collapse = " ", sep = ""), s3, sep = ""),
      envir)
  }
  else snippet
}

tempFile <- function(file.name) {
  paste0(formatPath(tempdir(), TRUE), file.name)
}

formatPath <- function(path, terminate.with.separator = FALSE) {
  path <- gsub("\\", .Platform$file.sep, path, fixed = TRUE)
  if (!terminate.with.separator)
    return(path)
  if (substring(path, nchar(path)) == .Platform$file.sep)
    return(path)
  paste0(path, .Platform$file.sep)
}
