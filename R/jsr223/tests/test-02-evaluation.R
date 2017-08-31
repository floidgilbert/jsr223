library("jsr223")
source("utility.R")
cat("Begin Test - Evaluation and Recursion\n\n")

# This module tests all code evaluation scenarios including callbacks.

js <- ScriptEngine$new("javascript")

# Simple code evaluation scenarios (i.e. without callbacks) ---------------

js$setStandardOutputMode("buffer")

# Code evaluation without return value, stdout, or error.
js %~% "var a = 1 + 1;"
assertIdentical(2L, js$a)

# With return value...
assertIdentical(3, js %~% "a + 1;")

# With stdout...
js %@% "print('abc');"
assertIdentical("abc", removeCarriageReturns(js$getStandardOutput()))

# With return value and stdout...
assertIdentical(4L, js %~% "print('abc'); 4")
assertIdentical("abc", removeCarriageReturns(js$getStandardOutput()))

# With evaluation error...
assertMessage(
  {
    js %~% "throw new Error('stop execution.');"
  }
  , "javax.script.ScriptException: Error: stop execution. in <eval> at line number"
  , exact.match = FALSE
)

# With evaluation error and standard out...
e <- tryCatch(
  js %~% "print('stdout before error'); throw new Error('stop execution.');"
  , error = function(e) {return(e)}
)
assertIdentical("stdout before error", removeCarriageReturns(js$getStandardOutput()))
assertMessage(
  {
    stop(e)
  }
  , "javax.script.ScriptException: Error: stop execution. in <eval> at line number"
  , exact.match = FALSE
)

# With syntax error...
assertMessage(
  {
    js %~% "print('ab;"
  }
  , "Missing close quote"
  , exact.match = FALSE
)


# Callbacks to evaluate R code --------------------------------------------

# Evaluate simple R code without a return value.
a <- 1
assertIdentical(NULL, js %~% "R.eval('rm(a)')")
a <- 1
assertIdentical(NULL, js %@% "R.eval('rm(a)')")

# Evaluate R code with a return value.
pi.called.back <- js %~% "R.eval('round(pi, 4)')"
assertIdentical(round(pi, 4), pi.called.back)

# Evaluate R code with standard output. Note that
# js$setStandardOutput('buffer') has no effect.
s <- removeCarriageReturns(capture.output(js %~% "R.eval('cat(123)')"))
assertIdentical("123", s)

# Evaluate R code with standard output and a return value.
s <- removeCarriageReturns(capture.output(a <- js %~% "R.eval('cat(123); round(pi, 4)')"))
assertIdentical(round(pi, 4), a)
assertIdentical("123", s)

# ...with evaluation error.
assertMessage(
  {
    js %~% "R.eval('stop(\"This is an R error.\")')"
  }
  , "This is an R error."
  , exact.match = FALSE
)

# ...with evaluation error and standard output.
s <- removeCarriageReturns(
  capture.output(
    e <- tryCatch(js %~% "R.eval('cat(123); stop(\"This is an R error.\")')", error = function(e) {return(e)})
  )
)
assertMessage(
  {
    stop(e)
  }
  , "This is an R error."
  , exact.match = FALSE
)
assertIdentical("123", s)

# ...with syntax error.
assertMessage(
  {
    js %~% "R.eval('stop(\"This is an R error.\"')"
  }
  , "stop(\"This is an R error."
  , exact.match = FALSE
)

# Create and call R function.
js %~% "
var b = R.eval(
  'set.seed(10)\\n' +
  'max.rnorm <- function(n) {return(max(rnorm(n)))}\\n' +
  'max.rnorm(10)\\n'
);
"
assertIdentical(0.389794, round(js$b, 6))

# Recursive callbacks -----------------------------------------------------

# Basic recursion testing all four evaluation interfaces: eval, compile$eval, invokeFunction, invokeMethod.
assertIdentical(1L, js %~% "R.eval('js$eval(\"1;\")');")
js %~% "function returnNumber(number) {return number;}"

cs <- js$compile("Math.PI;")
assertIdentical(pi, js %~% "R.eval('cs$eval()');")
js %@% "R.set('a', R.eval('cs$eval()'));"
assertIdentical(pi, a)

js %~% "function returnNumber(number) {return number;}"
assertIdentical(1, js %~% "R.eval('js$invokeFunction(\"returnNumber\", 1)');")

assertIdentical(1, js %~% "R.eval('js$invokeMethod(\"Math\", \"abs\", -1)');")

# R recursive function
recursive.countdown <- function(start.value, throw.error = FALSE) {
  cat("T minus ", start.value, "\n", sep = "")
  if (start.value > 0)
    return(js %~% "R.eval('recursive.countdown(@{start.value - 1}, @{throw.error})');")
  if (throw.error)
    stop("Recursion testing error.")
  return(0L)
}

# Basic recursion including return value and standard output
a <- NULL; s <- NULL
s <- removeCarriageReturns(capture.output(a <- recursive.countdown(2)))
assertIdentical(0L, a)
assertAllEqual(c("T minus 2", "T minus 1", "T minus 0"), s)

a <- NULL; s <- NULL
s <- removeCarriageReturns(capture.output(a <- js %~% "R.eval('recursive.countdown(2)');"))
assertIdentical(0L, a)
assertAllEqual(c("T minus 2", "T minus 1", "T minus 0"), s)

# Recursion with evaluation error on R side.
a <- NULL; s <- NULL
s <- removeCarriageReturns(
  capture.output(
    e <- tryCatch(
      recursive.countdown(2, TRUE)
      , error = function(e) {e}
    )
  )
)
assertAllEqual(c("T minus 2", "T minus 1", "T minus 0"), s)
assertMessage(
  {
    stop(e)
  }
  ,
  "Error in recursive.countdown(0, TRUE): Recursion testing error."
  , exact.match = FALSE
)

# R recursive function using compiled interface.
cs <- js$compile("R.eval('recursive.countdown(' + startValue + ', ' + throwError + ')');")
recursive.countdown <- function(start.value, throw.error = FALSE) {
  cat("T minus ", start.value, "\n", sep = "")
  if (start.value > 0) {
    bindings = list(
      startValue = as.character(start.value - 1)
      , throwError = as.character(throw.error)
    )
    return(cs$eval(bindings = bindings))
  }
  if (throw.error)
    stop("Recursion testing error.")
  return(0L)
}

a <- NULL; s <- NULL
s <- removeCarriageReturns(capture.output(a <- recursive.countdown(2)))
assertIdentical(0L, a)
assertAllEqual(c("T minus 2", "T minus 1", "T minus 0"), s)

a <- NULL; s <- NULL
s <- removeCarriageReturns(capture.output(a <- js %~% "R.eval('recursive.countdown(2)');"))
assertIdentical(0L, a)
assertAllEqual(c("T minus 2", "T minus 1", "T minus 0"), s)

# Recursion with evaluation error on R side.
a <- NULL; s <- NULL
s <- removeCarriageReturns(
  capture.output(
    e <- tryCatch(
      recursive.countdown(2, TRUE)
      , error = function(e) {e}
    )
  )
)
assertAllEqual(c("T minus 2", "T minus 1", "T minus 0"), s)
assertMessage(
  {
    stop(e)
  }
  ,
  "Error in recursive.countdown(0, TRUE): Recursion testing error."
  , exact.match = FALSE
)

# JavaScript recursive function.
js %@% "
function recursiveCountdown(startValue, throwError) {
  print('T minus ' + startValue);
  if (startValue > 0)
    return(R.eval('js %~% \"recursiveCountdown(' + (startValue - 1).toString() + ', ' + throwError.toString() + ')\"'));
  if (throwError)
    throw new Error('Recursion testing error.');
  return(0);
}
"

# Basic recursion including return value and standard output
a <- NULL
a <- js$invokeFunction("recursiveCountdown", 2, FALSE)
assertIdentical(0L, a)
assertAllEqual("T minus 2T minus 1T minus 0", removeCarriageReturns(js$getStandardOutput()))

# Recursion with evaluation error on JVM side.
a <- NULL
e <- tryCatch(
  js$invokeFunction("recursiveCountdown", 2, TRUE)
  , error = function(e) {return(e)}
)
assertAllEqual("T minus 2T minus 1T minus 0", removeCarriageReturns(js$getStandardOutput()))
assertMessage(
  {
    stop(e)
  }
  ,
  "Error: Recursion testing error."
  , exact.match = FALSE
)

js$terminate()

cat("End Test\n\n")
