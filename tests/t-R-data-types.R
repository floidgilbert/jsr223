#///finish this
library("jsr223")
source("../R/jsr223/tests/test00.R")

testTypes <- function(j) {

  # All of these data tests come from test03.R distributed with jsr223. Keep in
  # synch with that file. Remove the JavaScript-specific items.

  # Null and undefined values
  assert.identical(NULL, j$not_defined)

  j$null_value <- NULL
  assert.identical(NULL, j$null_value)

  # Missing values - NA. jsonlite handles NA differently depending on whether the
  # vector is character or numeric. If numeric, the string "NA" is used. If
  # character, JSON type null is used. See the jsonlite paper for more
  # information.
  j$a <- c(1, 2, NA)
  assert.identical(TRUE, is.na(j$a[3]))

  j$a <- c("a", "b", NA)
  assert.identical(TRUE, is.na(j$a[3]))

  # Other special R constants.
  j$a <- c(1, NaN, -Inf, Inf, 2)
  assert.all.equal(j$a, c(1, NaN, -Inf, Inf, 2))

  # IMPORTANT: The expression j$a <- list(1, NaN, -Inf, Inf, 2) will come back as
  # a matrix. This is a jsonlite limitation. When using lists, specify labels.
  j$a <- list(a = 1, b = NaN, c = -Inf, d = Inf, e = 2)
  assert.all.equal(j$a, list(a = 1, b = NaN, c = -Inf, d = Inf, e = 2))

  j$a <- matrix(c(1, NaN, -Inf, Inf, 2))
  assert.all.equal(j$a, matrix(c(1, NaN, -Inf, Inf, 2)))

  # UTF-8 Unicode test. From the UTF-8 specification: "The definition of UTF-8
  # prohibits encoding character numbers between U+D800 and U+DFFF, which are
  # reserved for use with the UTF-16 encoding form (as surrogate pairs) and do not
  # directly represent characters" (Page 5 at
  # https://tools.ietf.org/html/rfc3629#page-5). Furthermore, characters
  # 0x0000:0x001F are control characters which are not escaped by jsonlite at the
  # time of this writing. So, they are not included in the test.
  utf8.out <- intToUtf8(c(0x0020:0xD7FF, 0xE000:0x10FFFF))
  j$a <- utf8.out
  utf8.in <- j$a
  assert.identical(TRUE, identical(utf8.out, utf8.in))
  rm(utf8.out, utf8.in)

  setGet <- function(input, tolerance = 0, allow.numeric.to.integer = FALSE) {
    if (class(input) == "data.frame") {
      for (i in 1:ncol(input)) setGet(input[, i], allow.numeric.to.integer = allow.numeric.to.integer)
      return(invisible(NULL))
    }
    j$a <- input
    output <- j$a
    j$a <- NULL
    if (!isTRUE(all.equal(input, output, tolerance = tolerance, check.attributes = FALSE, check.names = TRUE))) stop(paste("Input/output values are not equal:\n\n" , paste(input, collapse=","), "\n\n", paste(output, collapse=","), "\n"))
    q <- c(class(input), class(output))
    if (q[1] != q[2] &&  !(allow.numeric.to.integer && q == c("numeric", "integer"))) stop(sprintf("Input class is '%s' but class of output is '%s'.\n", class(input), class(output)))
    q <- c(mode(input), mode(output))
    if (q[1] != q[2] &&  !(allow.numeric.to.integer && q == c("numeric", "integer"))) stop(sprintf("Input mode is '%s' but mode of output is '%s'.\n", mode(input), mode(output)))
  }

  j$length.one.vector.as.array <- FALSE
  setGet(4L)
  setGet(5, allow.numeric.to.integer = TRUE)
  setGet(TRUE)
  setGet(FALSE)
  setGet("David")

  j$length.one.vector.as.array <- TRUE
  setGet(4L)
  setGet(5, allow.numeric.to.integer = TRUE)
  setGet(TRUE)
  setGet(FALSE)
  setGet("David")

  j$length.one.vector.as.array <- jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY
  setGet(c(4L, 3L))
  setGet(c(5, 6), allow.numeric.to.integer = TRUE)
  setGet(c(TRUE, FALSE))
  setGet(c("David", "Dahl"))

  setGet(matrix(c(1L, 2L, 3L, 4L, 5L, 6L), nrow=1))
  setGet(matrix(c(1, 2, 3, 4, 5, 6, 7, 8), nrow=1))
  setGet(matrix(c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE), nrow=1))
  setGet(matrix(c("1", "2", "3", "4", "5", "6", "7", "8"), nrow=1))

  setGet(matrix(c(1L, 2L, 3L, 4L, 5L, 6L), nrow=2))
  setGet(matrix(c(1, 2, 3, 4, 5, 6, 7, 8), nrow=2))
  setGet(matrix(c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE), nrow=2))
  setGet(matrix(c("1", "2", "3", "4", "5", "6", "7", "8"), nrow=2))

  setGet(mtcars, allow.numeric.to.integer = TRUE)
  setGet(euro.cross, tolerance = .Machine$double.eps ^ 0.5)
  setGet(as.data.frame(EuStockMarkets))

  # Large/small numbers
  setGet(.Machine$integer.max)
  setGet(.Machine$double.xmin, tolerance = .Machine$double.eps ^ 0.5)
  # setGet(.Machine$double.xmax) // This fails because Nashorn JS returns the word "Infinity" while jsonlite expects "Inf". Either way, it's wrong.

  # jsonlite supports these types by converting to strings. Just check for type errors.
  j$a <- complex(3, 4, 5, 32)
  j$a <- date()
  j$a <- as.POSIXlt(Sys.time(), "GMT")
}

runTest <- function(engine, class.path = "") {
  j <- startEngine(engine, class.path = class.path)
  cat(j$engine.name, "\n")
  tryCatch(
    {testTypes(j)}
    , finally = {close(j); rm(j)}
  )
}

runTest("javascript")
runTest("jruby", class.path = "../engines/jruby-complete-9.0.0.0.jar")
runTest("jython", class.path = "../engines/jython-2.5.3.jar")
runTest("groovy", class.path = "../engines/groovy-all-2.3.7.jar")

# For Scala, class.path is handled automatically by jsr223::startEngine.
# This test assumes Scala is installed.
# NOTE: As of this writing, quiet mode has no effect in Scala because
# the JSR-223 implementation does not support redirecting output.
runTest("scala")

# Beanshell works, but we aren't going to actively support it. It's a dead language.
# runTest("bsh", class.path = "../engines/bsh-2.1.8.jar")

# class.path <- c(
#   "../engines/jruby-complete-9.0.0.0.jar"
#   ,"../engines/jython-2.5.3.jar"
#   ,"../engines/groovy-all-2.3.7.jar"
#   ,"../engines/bsh-2.1.8.jar"
# )
#
# d <- jsr223::getEngineInfo(class.path = class.path)
