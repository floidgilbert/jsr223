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

terminateString <- function(x, t) {
  if (typeof(x) != "character" || typeof(t) != "character")
    stop("The argumentx 'x' and 't' require character vectors.")
  length.x <- length(x)
  length.t <- length(t)
  if (length.x == 0 || length.t == 0)
    return(x)

  # Make recycling work as expected.
  if (length.x == 1 && length.t > 1) {
    x <- rep(x, times = length.t)
  } else if (length.x > 1 && length.t == 1) {
    t <- rep(t, times = length.x)
  }

  nchar.x <- nchar(x)
  nchar.t <- nchar(t)
  b <- substring(x, nchar.x - nchar.t + 1, nchar.x) != t
  x[b] <- paste0(x[b], t[b])
  x
}

# terminateString(c(1), c("b")) # Throws error.
# terminateString(c("a"), c(1)) # Throws error.
# terminateString(character(), c("b"))
# terminateString(c("a"), character())
# terminateString(c("a"), c("b"))
# terminateString(c(""), c("b"))
# terminateString(c("a"), c(""))
# terminateString(c("a"), c("a"))
# terminateString(c("a"), c("a", "b"))
# terminateString(c("a"), c("a", "a"))
# terminateString(c("a"), c("a", "b", "a"))
# terminateString(c("a", "b"), c("a"))
# terminateString(c("a", "b"), c("a", "b"))
# terminateString(c("a", "b"), c("d", "e"))
# terminateString(c("a", "b"), c("d", "e", "f")) # Throws error
# terminateString(c("abc"), c("def"))
# terminateString(c("abc", "def"), c("def"))
# terminateString(c("abc", "def"), c("def", "hij"))
# terminateString(c("abcdef", "hijklm"), c("def"))
