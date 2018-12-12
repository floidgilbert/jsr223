# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Testing functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

assertAllEqual <- function(expected.value, value, tolerance = 0) {
  if (!isTRUE(all.equal(value, expected.value, tolerance = tolerance, check.names = TRUE))) stop(sprintf("Expected value '%s' but received '%s'.", toString(expected.value), toString(value)))
}

assertMessage <- function(f, message, exact.match = TRUE, message.type = "error") {
  result <- tryCatch(
    eval(f)
    , error = function(e) {e}
    , warning = function(w) {w}
    , message = function(m) {m}
  )
  if (inherits(result, message.type)) {
    if (exact.match) {
      if (result$message != message) stop(sprintf("Expecting %s\n\n%s\n\nbut received\n\n%s", message.type, message, result$message))
    } else {
      if (!grepl(message, result$message, fixed = TRUE)) stop(sprintf("Partial match for %s\n\n%s\n\nwas not found in\n\n%s", message.type, message, result$message))
    }
  } else {
    stop(sprintf("Expecting %s\n\n%s\n\nbut it was not thrown.", message.type, message))
  }
}

assertIdentical <- function(expected.value, value) {
  if (!identical(value, expected.value)) stop(sprintf("Expected value '%s' but received '%s'.", toString(expected.value), toString(value)))
}

captureResult <- function(expression) {
  value <- tryCatch(
    eval(expression, envir = parent.frame())
    , error = function(e) {e}
  )
  value
}

removeCarriageReturns <- function(x) {
  gsub("\r|\n", "", x)
}
