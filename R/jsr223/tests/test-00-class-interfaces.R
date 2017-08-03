library("jsr223")
source("utility.R")
cat("Begin Test - ScriptEngine and CompiledScript Class Interfaces\n\n")

# ScriptEngine constructor parameter validation -------------------------------

cat("ScriptEngine constructor parameter validation\n")

assertMessage(
  {
    js <- ScriptEngine$new()
  }
  , 'argument "engine.name" is missing, with no default'
)

assertMessage(
  {
    js <- ScriptEngine$new(1)
  }
  , "'engine.name' must be a character vector of length 1 containing a valid engine script name."
)

assertMessage(
  {
    js <- ScriptEngine$new(c("a", "b"))
  }
  , "'engine.name' must be a character vector of length 1 containing a valid engine script name."
)

assertMessage(
  {
    js <- ScriptEngine$new("jsx")
  }
  , "java.lang.Exception: Failed to instantiate engine 'jsx'. Make sure the engine dependencies are in the class path."
)

assertMessage(
  {
    js <- ScriptEngine$new("javascript", class.path = 1)
  }
  , "'class.path' must be a character vector."
)

assertMessage(
  {
    js <- ScriptEngine$new("javascript", class.path = sprintf(" %s badfile %s b ", .Platform$path.sep, .Platform$path.sep))
  }
  , "The file 'badfile' specified in the class path does not exist."
)

js <- ScriptEngine$new("  javascript  ") # Intentionally using spaces for testing trim...
assertIdentical(TRUE, js$isInitialized())


# set / $<- / get / $ -----------------------------------------------------

cat("set / $<- / get / $\n")

# Does not allow any of the ScriptEngine method/property names to be used
# in set/get methods.
assertMessage(
  {
    js$set("set", 1)
  }
  , "The identifier 'set' is reserved."
)

assertMessage(
  {
    js$set("R", 1)
  }
  , "The identifier 'R' is reserved."
)

assertMessage(
  {
    js$get("get")
  }
  , "The identifier 'get' is reserved."
)

assertMessage(
  {
    js$get("R")
  }
  , "The identifier 'R' is reserved."
)

assertMessage(
  {
    js$set("a", function() {})
  }
  , "Values of class 'function' are not supported."
)

assertMessage(
  {
    js$set("a", array(1:16, c(2, 2, 2, 2)))
  }
  , "Arrays of three or more dimensions are not supported. Use lists of matrices, or consider using ND4J (http://nd4j.org/)."
)

# Comprehensive tests for data types are done elsewhere.
js$set("a", 1)
assertIdentical(1, js$get("a"))
js$b <- 2L
assertIdentical(2L, js$b)
js$c <- NULL
assertIdentical(NULL, js$c)
assertIdentical(NULL, js$get("doesNotExist"))
assertIdentical(NULL, js$doesNotExist)
js %~% "var a = undefined;"
assertIdentical(NULL, js$a)


# remove ------------------------------------------------------------------

cat("remove\n")

assertIdentical(FALSE, js$remove("doesNotExist"))
js$a <- 1
assertIdentical(TRUE, js$remove("a"))

assertMessage(
  {
    js$remove("R")
  }
  , "The identifier 'R' is reserved."
)

assertMessage(
  {
    js$remove("remove")
  }
  , "The identifier 'remove' is reserved."
)


# getBindings ------------------------------------------------------------

cat("getBindings\n")

js$setRowMajor(FALSE)
js$d <- list(1, 2, 3)
js$c <- mtcars
js$b <- letters
js$a <- 1
v <- js$getBindings()
# Make sure they are sorted coming back...
compare <- list(
  a = "java.lang.Double"
  , b = "[Ljava.lang.String;"
  , c = "java.util.LinkedHashMap"
  , d = "java.util.ArrayList"
  , R = "org.fgilbert.jsr223.RClient"
)
assertIdentical(compare, v)
invisible(js$remove("d"))
compare$d <- NULL
v <- js$getBindings()
assertIdentical(compare, v)
js$setRowMajor(jsr223:::DEFAULT_ROW_MAJOR)

# getClassPath ------------------------------------------------------------

cat("getClassPath\n")

if (length(js$getClassPath()) < 3L) stop("getClassPath returned an unexpected value.")


# eval / %~% / %@% --------------------------------------------------------

cat("eval / %~% / %@%\n")

assertMessage(
  {
    js$eval(1)
  }
  , "'script' must be a character vector of length 1."
)

assertMessage(
  {
    js$eval(c("a", "b"))
  }
  , "'script' must be a character vector of length 1."
)

assertMessage(
  {
    js$eval("a", discard.return.value = "a")
  }
  , "method putEvaluationRequest with signature (Ljava/lang/String;Ljava/lang/String;)V not found"
)

assertMessage(
  {
    js$eval("a", bindings = 1)
  }
  , "'bindings' requires a named list."
)

assertMessage(
  {
    js$eval("a", bindings = list())
  }
  , "'bindings' requires a named list."
)

assertMessage(
  {
    js$eval("a", bindings = list(1))
  }
  , "'bindings' requires a named list."
)

assertMessage(
  {
    js$eval("a", bindings = list(R = 1))
  }
  , "The identifier 'R' is reserved."
)

# Comprehensive tests for data types and callbacks are done elsewhere.
assertIdentical(NULL, js$eval("var a = 1;"))
assertIdentical(1L, js$eval("a;"))
assertIdentical(1L, js %~% "a;")
assertIdentical(3.14, js %~% "R.eval('round(pi, 2)');")
assertIdentical(NULL, js %~% "R.eval('NULL');")
assertIdentical(NULL, js %~% "R.get('doesNotExist');")
assertIdentical(pi, js %~% "R.get('pi');")
assertIdentical(NULL, js %~% "")
assertIdentical(NULL, js %~% "    ")
assertIdentical(NULL, js %~% "R.set('myPiValue', Math.PI);")
assertIdentical(pi, myPiValue)

assertMessage(
  {
    js %~% "myFunction(1);"
  }
  , "javax.script.ScriptException: ReferenceError: \"myFunction\" is not defined in <eval> at line number 1"
)

assertMessage(
  {
    js %~% "R.eval('stop(\"Test error.\")');"
  }
  , "Test error."
  , exact.match = FALSE
)

assertIdentical(NULL, js$eval("Math.PI;", TRUE))
assertIdentical(NULL, js %@% "Math.PI;")
assertIdentical(NULL, js %@% "Math;") # Unsupported type, but no error because return value is discarded.
assertIdentical(NULL, js %@% "")
assertIdentical(NULL, js %@% "    ")
assertIdentical(NULL, js %@% "R.eval(1);")
# Make sure callbacks are still processed properly...
assertIdentical(NULL, js %@% "R.set('anotherValue', 1);")
assertIdentical(NULL, js %@% "R.get('anotherValue');")
assertIdentical(1L, js %~% "R.get('anotherValue');")

# Make sure errors are still processed when return value is discarded.
assertMessage(
  {
    js %@% "myFunction(1);"
  }
  , "javax.script.ScriptException: ReferenceError: \"myFunction\" is not defined in <eval> at line number 1"
)

# Test bindings
js$a <- 1
assertIdentical(1, js$eval("a"))
bindings <- list(a = 2, b = 3)
assertIdentical(2, js$eval("a", bindings = bindings))
assertIdentical(1, js$eval("a")) # Make sure original value is still available.
assertIdentical(2, js$eval("R.eval('js$eval(\"a\", bindings = bindings)')", bindings = bindings)) # Make sure RClient is still available when bindings have been set.
assertIdentical(3, js$eval("b", bindings = bindings))
assertIdentical(NULL, js$eval("b", discard.return.value = TRUE, bindings = bindings))


# compile -----------------------------------------------------------------

cat("compile\n")

assertMessage(
  {
    js$compile(1)
  }
  , "'script' must be a character vector of length 1."
)

assertMessage(
  {
    js$compile(c("a", "b"))
  }
  , "'script' must be a character vector of length 1."
)

cs <- js$compile("var a = 1;")

assertMessage(
  {
    cs$eval(discard.return.value = "a")
  }
  , "method putEvaluationRequest with signature (Ljavax/script/CompiledScript;Ljava/lang/String;)V not found"
)

assertMessage(
  {
    cs$eval(bindings = 1)
  }
  , "'bindings' requires a named list."
)

assertMessage(
  {
    cs$eval(bindings = list())
  }
  , "'bindings' requires a named list."
)

assertMessage(
  {
    cs$eval(bindings = list(1))
  }
  , "'bindings' requires a named list."
)

assertMessage(
  {
    cs$eval(bindings = list(R = 1))
  }
  , "The identifier 'R' is reserved."
)

assertIdentical(NULL, cs$eval())
cs <- js$compile("1;")
assertIdentical(1L, cs$eval())
assertIdentical(NULL, cs$eval(TRUE))
cs <- js$compile("Math.PI;")
assertIdentical(pi, cs$eval())
cs <- js$compile("R.eval('round(pi, 2)');")
assertIdentical(3.14, cs$eval())
cs <- js$compile("R.eval('NULL');")
cs <- js$compile("R.get('doesNotExist');")
assertIdentical(NULL, cs$eval())
cs <- js$compile("")
assertIdentical(NULL, cs$eval())
cs <- js$compile("   ")
assertIdentical(NULL, cs$eval())
cs <- js$compile("R.set('myPiValue', Math.PI);")
assertIdentical(NULL, cs$eval())
assertIdentical(pi, myPiValue)

assertMessage(
  {
    cs <- js$compile("myFunction(1);")
    cs$eval()
  }
  , "javax.script.ScriptException: ReferenceError: \"myFunction\" is not defined in <eval> at line number 1"
)

assertMessage(
  {
    cs <- js$compile("myFunction(1);")
    cs$eval(TRUE)
  }
  , "javax.script.ScriptException: ReferenceError: \"myFunction\" is not defined in <eval> at line number 1"
)

assertMessage(
  {
    cs <- js$compile("R.eval('stop(\"Test error.\")');")
    cs$eval()
  }
  , "Test error."
  , exact.match = FALSE
)

# Test bindings
js$a <- 1
cs <- js$compile("a;")
assertIdentical(1, cs$eval())
bindings <- list(a = 2, b = 3)
assertIdentical(2, cs$eval(bindings = bindings))
assertIdentical(1, cs$eval()) # Make sure original value is still available.
cs <- js$compile("R.eval('js$eval(\"a\", bindings = bindings)')")
assertIdentical(2, cs$eval(bindings = bindings)) # Make sure RClient is still available when bindings have been set.
cs <- js$compile("b;")
assertIdentical(3, cs$eval(bindings = bindings))
assertIdentical(NULL, cs$eval(discard.return.value = TRUE, bindings = bindings))


# source / compileSource --------------------------------------------------

cat("source / compileSource\n")

assertMessage(
  {
    js$source(c("a", "b"))
  }
  , "'file.name' must be a character vector of length 1 containing a valid script file name."
)

assertMessage(
  {
    js$compileSource(c("a", "b"))
  }
  , "'file.name' must be a character vector of length 1 containing a valid script file name."
)

assertMessage(
  {
    js$source(1)
  }
  , "'file.name' must be a character vector of length 1 containing a valid script file name."
)

assertMessage(
  {
    js$compileSource(1)
  }
  , "'file.name' must be a character vector of length 1 containing a valid script file name."
)

assertMessage(
  {
    js$source("fileDoesNotExist")
  }
  , "The file 'fileDoesNotExist' could not be found or does not exist."
)

assertMessage(
  {
    js$compileSource("fileDoesNotExist")
  }
  , "The file 'fileDoesNotExist' could not be found or does not exist."
)

temp.file <- tempfile(fileext = ".js")
cat("", file = temp.file, sep = "")

assertMessage(
  {
    js$source(temp.file)
  }
  , "The file is empty."
)

assertMessage(
  {
    js$compileSource(temp.file)
  }
  , "The file is empty."
)

cat("a + b", file = temp.file, sep = "")
js$a <- 1; js$b <- 2
assertIdentical(3, js$source(temp.file))
assertIdentical(9, js$source(temp.file, bindings = list(a = 4, b = 5)))
assertIdentical(NULL, js$source(temp.file, discard.return.value = TRUE))
cs <- js$compileSource(temp.file)
assertIdentical(3, cs$eval())
assertIdentical(9, cs$eval(bindings = list(a = 4, b = 5)))
assertIdentical(NULL, cs$eval(discard.return.value = TRUE))

invisible(file.remove(temp.file))


# invokeFunction / invokeMethod -------------------------------------------

cat("invokeFunction / invokeMethod\n")

assertMessage(
  {
    js$invokeFunction(1)
  }
  , "'function.name' must be a character vector of length 1."
)

assertMessage(
  {
    js$invokeFunction(c("a", "b"))
  }
  , "'function.name' must be a character vector of length 1."
)

assertMessage(
  {
    js$invokeFunction("doesNotExist", 1, 1)
  }
  , "java.lang.NoSuchMethodException: No such function doesNotExist"
)

js %~% "
function returnOne() {
  return 1;
}
"
assertIdentical(1L, js$invokeFunction("returnOne"))

js %~% "
function addThis(a, b, c) {
  return a + b + c;
}
"
assertIdentical(4, js$invokeFunction("addThis", 1, 1, 2))


assertMessage(
  {
    js$invokeMethod(1)
  }
  , "'object.name' must be a character vector of length 1."
)

assertMessage(
  {
    js$invokeMethod(letters)
  }
  , "'object.name' must be a character vector of length 1."
)

assertMessage(
  {
    js$invokeMethod("Math", 1)
  }
  , "'method.name' must be a character vector of length 1."
)

assertMessage(
  {
    js$invokeMethod("Math", letters)
  }
  , "'method.name' must be a character vector of length 1."
)

assertMessage(
  {
    js$invokeMethod("objectDoesNotExist", "methodDoesNotExist", 1)
  }
  , "java.lang.RuntimeException: An object with identifier 'objectDoesNotExist' could not be found."
)

assertMessage(
  {
    js$invokeMethod("Math", "methodDoesNotExist", 1)
  }
  , "java.lang.NoSuchMethodException: No such function methodDoesNotExist"
)

js %~% "
var o = {a:1}
o.returnOne = function() {return 1;}
"
assertIdentical(1L, js$invokeMethod("o", "returnOne"))
assertIdentical(1, js$invokeMethod("Math", "abs", -1))

# getEngineInformation ----------------------------------------------------

cat("getEngineInformation\n")

info <- js$getScriptEngineInformation()
assertIdentical("Oracle Nashorn", info$name)
assertIdentical("ECMAScript", info$language.name)


# getInterpolate / setInterpolate -----------------------------------------

cat("getInterpolate / setInterpolate\n")

assertIdentical(jsr223:::DEFAULT_INTERPOLATE, js$getInterpolate())
js$setInterpolate(!jsr223:::DEFAULT_INTERPOLATE)
assertIdentical(!jsr223:::DEFAULT_INTERPOLATE, js$getInterpolate())
assertMessage(
  {
    js$setInterpolate(1)
  }
  , "A TRUE or FALSE value is required."
)
previous.value <- js$setInterpolate(TRUE)
assertIdentical(!jsr223:::DEFAULT_INTERPOLATE, previous.value)
js$eval("var a = '@{round(pi, 3)}';")
assertIdentical("3.142", js$a)
previous.value <- js$setInterpolate(FALSE)
assertIdentical(TRUE, previous.value)
js$eval("var a = '@{round(pi, 3)}';")
assertIdentical("@{round(pi, 3)}", js$a)
js$setInterpolate(jsr223:::DEFAULT_INTERPOLATE)

# Make sure interpolation uses the correct scope.
js$setInterpolate(TRUE)
a <- 1L
assertIdentical(2L, js %~% "1 + @{a};")
cs <- js$compile("1 + @{a};")
assertIdentical(2L, cs$eval())
testScope <- function(a) {
  js %~% "1 + @{a};"
}
assertIdentical(3L, testScope(2L))
testScope <- function(a) {
  cs <- js$compile("1 + @{a};")
  cs$eval()
}
assertIdentical(3L, testScope(2L))

js$setInterpolate(jsr223:::DEFAULT_INTERPOLATE)


# getJavaClassName --------------------------------------------------------

cat("getJavaClassName\n")

assertIdentical(NULL, js$getJavaClassName("doesNotExist"))
js$eval("var a = 1;")
assertIdentical("java.lang.Integer", js$getJavaClassName("a"))


# getLengthOneVectorAsArray / setLengthOneVectorAsArray -------------------

cat("getLengthOneVectorAsArray / setLengthOneVectorAsArray\n")

assertIdentical(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY, js$getLengthOneVectorAsArray())
js$setLengthOneVectorAsArray(!jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)
assertIdentical(!jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY, js$getLengthOneVectorAsArray())
assertMessage(
  {
    js$setLengthOneVectorAsArray(1)
  }
  , "A TRUE or FALSE value is required."
)

previous.value <- js$setLengthOneVectorAsArray(TRUE)
assertIdentical(!jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY, previous.value)
js$a <- 1
assertIdentical(1, js %~% "a[0];")
js$a <- as.array(2)
assertIdentical(2, js %~% "a[0];")
js$setCoerceFactors(FALSE)
js$a <- as.factor("abc")
assertIdentical("abc", js %~% "a[0];")
js$setCoerceFactors(TRUE)
js$a <- as.factor("abc")
assertIdentical("abc", js %~% "a[0];")
js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
a <- 1
assertIdentical(1, js %~% "R.eval('a')[0];")
assertIdentical(1, js %~% "R.get('a')[0];")

previous.value <- js$setLengthOneVectorAsArray(FALSE)
assertIdentical(TRUE, previous.value)
js$a <- 1
assertIdentical(NULL, js %~% "a[0];")
assertIdentical(1, js %~% "a;")
js$a <- as.array(2)
assertIdentical(NULL, js %~% "a[0];")
assertIdentical(2, js %~% "a;")
js$setCoerceFactors(FALSE)
js$a <- as.factor(c("abc"))
assertIdentical("a", js %~% "a[0];") # Strings are like arrays in JS.
assertIdentical("abc", js %~% "a;")
js$setCoerceFactors(TRUE)
js$a <- as.factor(c("abc"))
assertIdentical("a", js %~% "a[0];")
assertIdentical("abc", js %~% "a;")
js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
a <- 1
assertIdentical(NULL, js %~% "R.eval('a')[0];")
assertIdentical(1, js %~% "R.eval('a');")
assertIdentical(1, js %~% "R.get('a');")
js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)


# AsIs Class - I() --------------------------------------------------------

cat("AsIs Class - I()\n")

js$setLengthOneVectorAsArray(FALSE)
js$a <- 1
assertIdentical(1, js %~% "a;")
js$a <- I(1)
assertIdentical(1, js %~% "a[0];")

js$a <- "abc"
assertIdentical("abc", js %~% "a;")
js$a <- I("abc")
assertIdentical("abc", js %~% "a[0];")

js$a <- as.array(2)
assertIdentical(2, js %~% "a;")
js$a <- I(as.array(2))
assertIdentical(2, js %~% "a[0];")

js$a <- as.table(2)
assertIdentical(2, js %~% "a;")
js$a <- I(as.table(2))
assertIdentical(2, js %~% "a[0];")

js$setCoerceFactors(FALSE)
js$a <- as.factor(1)
assertIdentical("1", js %~% "a;")
js$a <- I(as.factor(1))
assertIdentical("1", js %~% "a[0];")
js$a <- as.factor("abc")
assertIdentical("abc", js %~% "a;")
js$a <- I(as.factor("abc"))
assertIdentical("abc", js %~% "a[0];")

js$setCoerceFactors(TRUE)
js$a <- as.factor(1)
assertIdentical(1L, js %~% "a;")
js$a <- I(as.factor(1))
assertIdentical(1L, js %~% "a[0];")
js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)

a <- 1
assertIdentical(1, js %~% "R.eval('a');")
a <- I(1)
assertIdentical(1, js %~% "R.eval('a')[0];")

js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)


# *StandardOutput* methods ------------------------------------------------

cat("*StandardOutput* methods\n")

js$setStandardOutputMode("console")
assertIdentical("console", js$getStandardOutputMode())
js %@% "print('You should see this message (1).');"

previous.value <- js$setStandardOutputMode("quiet")
assertIdentical("console", previous.value)
assertIdentical("quiet", js$getStandardOutputMode())
js %@% "print('You should not see this message (1).');"

previous.value <- js$setStandardOutputMode("buffer")
assertIdentical("quiet", previous.value)
assertIdentical("buffer", js$getStandardOutputMode())
js %@% "print('You should not see this message (2).');"
assertIdentical("You should not see this message (2).", removeCarriageReturns(js$getStandardOutput()))
js %@% "print('You should not see this message (3).');"
js$clearStandardOutput()
assertIdentical("", js$getStandardOutput())

previous.value <- js$setStandardOutputMode("console")
assertIdentical("buffer", previous.value)
js %@% "print('You should see this message (2).');"

assertMessage(
  {
    js$setStandardOutputMode("none")
  }
  , "Valid standard output modes are 'console', 'quiet', or 'buffer'."
)

js$setStandardOutputMode(jsr223:::DEFAULT_STANDARD_OUTPUT_MODE)


# getArrayOrder / setArrayOrder -------------------------------------------

cat("getArrayOrder / setArrayOrder\n")
#///left off

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)

previous.value <- js$setArrayOrder("row-major")
assertIdentical(jsr223:::DEFAULT_ARRAY_ORDER, previous.value)
assertIdentical("row-major", js$getArrayOrder())

#///testit

previous.value <- js$setArrayOrder("row-major-java")
assertIdentical("row-major", previous.value)
assertIdentical("row-major-java", js$getArrayOrder())

#///testit

previous.value <- js$setArrayOrder("column-major")
assertIdentical("row-major-java", previous.value)
assertIdentical("column-major", js$getArrayOrder())

#///testit

assertMessage(
  {
    js$setArrayOrder("invalid")
  }
  , "Valid array order values are 'column-major', 'row-major', or 'row-major-java'."
)

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# getCoerceFactors / setCoerceFactors -------------------------------------

cat("getCoerceFactors / setCoerceFactors\n")

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)

previous.value <- js$setCoerceFactors(TRUE)
assertIdentical(jsr223:::DEFAULT_COERCE_FACTORS, previous.value)
assertIdentical(TRUE, js$getCoerceFactors())
js$a <- as.factor(1:10)
assertIdentical(1:10, js$a)
js$setRowMajor(FALSE)
js$a <- data.frame(a = as.factor(1:10), b = 0)
assertIdentical(1:10, js %~% "a.a")
js$setRowMajor(TRUE)
js$a <- data.frame(a = as.factor(1:10), b = 0)
assertIdentical(1L, js %~% "a[0].a")

previous.value <- js$setCoerceFactors(FALSE)
assertIdentical(previous.value, TRUE)
assertIdentical(FALSE, js$getCoerceFactors())
js$a <- as.factor(1:10)
assertIdentical(as.character(1:10), js$a)
js$setRowMajor(FALSE)
js$a <- data.frame(a = as.factor(1:10), b = 0)
assertIdentical(as.character(1:10), js %~% "a.a")
js$setRowMajor(TRUE)
js$a <- data.frame(a = as.factor(1:10), b = 0)
assertIdentical("1", js %~% "a[0].a")

assertMessage(
  {
    js$setCoerceFactors(1)
  }
  , "A TRUE or FALSE value is required."
)

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setRowMajor(jsr223:::DEFAULT_ROW_MAJOR)




# getDataFrameRowMajor / setDataFrameRowMajor -----------------------------

cat("getDataFrameRowMajor / setDataFrameRowMajor\n")

js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

previous.value <- js$setDataFrameRowMajor(TRUE)
assertIdentical(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR, previous.value)
assertIdentical(TRUE, js$getDataFrameRowMajor())
js$a <- mtcars
assertIdentical(as.list(mtcars[5, ]), js %~% "a[4]")

previous.value <- js$setDataFrameRowMajor(FALSE)
assertIdentical(previous.value, TRUE)
assertIdentical(FALSE, js$getDataFrameRowMajor())
js$a <- mtcars
assertIdentical(mtcars[, "cyl"], js %~% "a.cyl")

assertMessage(
  {
    js$setDataFrameRowMajor(1)
  }
  , "A TRUE or FALSE value is required."
)

js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)


# getStringsAsFactors / setStringsAsFactors -------------------------------

cat("getStringsAsFactors / setStringsAsFactors\n")

js$setStringsAsFactors(NULL)
assertIdentical(NULL, js$getStringsAsFactors())
save.strings.as.factors <- getOption("stringsAsFactors")
options(stringsAsFactors = TRUE)
js$a <- data.frame(
  a = letters
  , b = 0L
  , stringsAsFactors = FALSE
)
assertIdentical(TRUE, is.factor(js$a[, 1]))

options(stringsAsFactors = FALSE)
assertIdentical(FALSE, is.factor(js$a[, 1]))

options(stringsAsFactors = save.strings.as.factors)

previous.value <- js$setStringsAsFactors(TRUE)
assertIdentical(NULL, previous.value)
assertIdentical(TRUE, js$getStringsAsFactors())
assertIdentical(TRUE, is.factor(js$a[, 1]))

previous.value <- js$setStringsAsFactors(FALSE)
assertIdentical(TRUE, previous.value)
assertIdentical(FALSE, js$getStringsAsFactors())
assertIdentical(FALSE, is.factor(js$a[, 1]))

assertMessage(
  {
    js$setStringsAsFactors(1)
  }
  , "A TRUE, FALSE, or NULL value is required."
)

assertMessage(
  {
    js$setStringsAsFactors(NA)
  }
  , "A TRUE, FALSE, or NULL value is required."
)

js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)


# names -------------------------------------------------------------------

cat("names\n")

assertIdentical(TRUE, "set" %in% names(js))
cs <- js$compile("1;")
assertIdentical(TRUE, "eval" %in% names(cs))


# print -------------------------------------------------------------------

cat("print\n")

assertIdentical("ScriptEngine", capture.output(print(js)))
cs <- js$compile("1;")
assertIdentical("CompiledScript", capture.output(print(cs)))


# toString ----------------------------------------------------------------

cat("toString\n")

assertIdentical("ScriptEngine", toString(js))
cs <- js$compile("1;")
assertIdentical("CompiledScript", toString(cs))


# terminate / finalize ----------------------------------------------------

cat("terminate / finalize\n")

js$terminate()
assertIdentical(FALSE, js$isInitialized())

cat("End Test\n\n")
