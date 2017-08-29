#///probably move/copy this file to jdx. dunno. "suggest" jsr223.
#///review comments everywhere.
#///make sure coerce logical and byte array stuff works for n-dimensional and collections of n-dimensional
#///add environments to testing hashed and unhashed
#///probably remove .jar files from the git repository. will bloat it.
#///add environments and n-dim arrays to lists.
#///Consider posting about jdx relative to the rJava bug for multi-dim arrays
#///also test warnings, boolean and raw, for collections and arrays.
#///test n-dimensional arrays in lists for all arrayorders. Notice that in some cases, you will get a higher-dimensional array. maybe this needs to be a setting.
#///add warning to jdx and jsr223 docs that list(matrix) will return a 3-dim array. so, use named lists instead. another example is list(factor) or list(vector)

# Introduction ------------------------------------------------------------

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Data exchange testing
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# This script tests all data exchange functionality for both jsr223 and jdx.
# These tests were designed before jdx was separated from jsr223. The data
# exchange tests remain as part of jsr223 because the tests involve scripting.
# Re-writing the tests without scripting would not be profitable. #///review

# Reference ---------------------------------------------------------------

# These are all of the data types, structures, and constants that
# are considered for testing. I put them here as a reference.

# # Data types/classes # #

# character
# numeric
# integer
# logical
# raw
# complex - not supported
# date - not supported
# POSIXt - not supported
# POSIXct - not supported
# POSIXlt - not supported

# # Basic data structures # #

# vector
# matrix
# array 1D
# array 2D (matrix)
# array nD
# data frame
# factor
# list
# environment
# formula - not supported
# expression - not supported
# function - not supported
# table - same as multidimensional array

# # Constants # #

# NULL
#
# NA
# NA_character_
# NA_real_
# NA_integer_
# NA_complex_
#
# Inf
# NaN
#
# TRUE
# FALSE


# Initialization ----------------------------------------------------------

source("utility.R")
cat("Begin Test - Data Exchange\n\n")
library("jsr223")
js <- ScriptEngine$new("javascript")

BYTE_MIN <- as.raw(0x80) # Java byte minimum is -128, but it translates bitwise to 0x80 in R.
BYTE_MAX <- as.raw(0x7f) # Java byte maximum is 127, but it translates bitwise to 0x7f in R.
# CHAR_MIN <- '\u0000'
# CHAR_MAX <- '\uFFFF'
DOUBLE_MIN <- .Machine$double.xmin
DOUBLE_MAX <- .Machine$double.xmax
FLOAT_MIN <- 1.40129846432482e-45
FLOAT_MAX <- 3.40282346638529e+38
# INTEGER_MIN <- -.Machine$integer.max # One less is the reserved value for NA_integer_
INTEGER_MIN <- NA_integer_ # The minimum integer value is a reserved value for NA in R.
INTEGER_MAX <- .Machine$integer.max
LONG_MIN <- -9223372036854775808
LONG_MAX <- 9223372036854775808
SHORT_MIN <- -32768L
SHORT_MAX <- 32767L

appendValuesAsArrays <- function(lst) {
  for (o in lst) {
    lst[[length(lst) + 1]] <- array(o)
  }
  lst
}

appendValuesAsFactors <- function(lst) {
  for (o in lst) {
    lst[[length(lst) + 1]] <- as.factor(o)
  }
  lst
}

# JS objects used in testSetAndGet function.
js %@% "
function identity(value) {
  return value;
}

var test = {identity: identity}
"

# This function tests data exchange between R and the script engine. It tests
# every method used to exchange data: eval, %~%, engine$get, engine$, engine$set,
# engine$ <-, invokeFunction, invokeMethod, R.get, R.set, and R.eval.
testSetAndGet <- function(list.set.values, list.comparison.values = NULL) {
  if (length(list.set.values) == 0)
    stop("Nothing to do.")
  if (is.null(list.comparison.values))
    list.comparison.values <- list.set.values
  for (i in 1:length(list.set.values)) {
    compare <- list.comparison.values[[i]]
    if (is.null(compare))
      compare <- list.set.values[[i]]
    if (is.array(compare) && length(dim(compare)) == 1) {
      # 1D arrays are supported, but they will come back as vectors
      compare <- as.vector(compare)
    }
    # rJava returns NULL for NA_character_
    if (identical(NA_character_, compare) && length(compare) == 1 && !js$getLengthOneVectorAsArray())
      compare <- NULL
    assign("kmk", value = list.set.values[[i]], envir = globalenv())
    on.exit(rm("kmk", envir = globalenv()))
    js$set("value", kmk)
    assertIdentical(compare, js$get("value"))
    js$value <- kmk
    assertIdentical(compare, js$value)
    assertIdentical(compare, js %~% "value;")
    assertIdentical(compare, js$invokeFunction("identity", kmk))
    assertIdentical(compare, js$invokeMethod("test", "identity", kmk))
    assertIdentical(compare, js %~% "R.get('kmk');")
    assertIdentical(compare, js %~% "R.eval('kmk');")
    js %@% "R.set('kmk', value);"
    assertIdentical(compare, kmk)
  }
}

# Used with testJavaToR function.
js %@% "var TestDataClass = Java.type('org.fgilbert.jdx.TestData');"
js %@% "var ArrayListClass = Java.type('java.util.ArrayList');"

# Test conversion of Java data to R.
testJavaToR <- function(method, compare, parameter = "", identical = TRUE, test.collection = TRUE) {

  testJavaToRInner <- function() {
    if (identical) {
      assertIdentical(compare, js$value)
      assertIdentical(compare, js %~% "value;")
    } else {
      assertAllEqual(compare, js$value, tolerance = tolerance)
      assertAllEqual(compare, js %~% "value;", tolerance = tolerance)
    }
    on.exit(rm("kmk", envir = globalenv()))
    js %@% "R.set('kmk', value);"
    if (identical) {
      assertIdentical(compare, kmk)
      assertIdentical(compare, js %~% "R.get('kmk');")
      assertIdentical(compare, js %~% "R.eval('kmk');")
    } else {
      assertAllEqual(compare, kmk, tolerance = tolerance)
      assertAllEqual(compare, js %~% "R.get('kmk');", tolerance = tolerance)
      assertAllEqual(compare, js %~% "R.eval('kmk');", tolerance = tolerance)
    }
  }

  tolerance <- sqrt(.Machine$double.eps)
  js %@% "var value = TestDataClass.@{method}(@{parameter});"
  testJavaToRInner()
  # If value is an array (1D or 2D), convert to a collection and test again.
  if (!test.collection || is.null(js$value))
    return(invisible())
  if (js %~% "var c = value.getClass(); !(c.isArray())")
    return(invisible())
  if (js %~% "value.length == 0;")
    return(invisible())
  js %@% "
    // Not sure how to use Arrays.asList(value) via JS (must cast value as Object[])
    var valueTemp = new ArrayListClass(value.length);
    for (i = 0; i < value.length; i++)
      valueTemp.add(value[i]);
    value = valueTemp;
    valueTemp = undefined;
  "
  testJavaToRInner()
}

# Unsupported Types -------------------------------------------------------

ERR_COMPLEX_1 <- "Values of class 'complex' are not supported."
ERR_COMPLEX_2 <- "java.lang.RuntimeException: Error in throwUnsupportedRtypeException(\"complex\"): Values of class 'complex' are not supported.\n"
ERR_JAVA_UTIL_RANDOM <- "java.lang.RuntimeException: Java class 'java.util.Random' cannot be converted to an R object."

assertMessage(
  {
    js$value <- 1+0i
  }
  , ERR_COMPLEX_1
)

assertMessage(
  {
    v <- 1+0i
    js %~% "R.get('v')"
  }
  , ERR_COMPLEX_2
)

assertMessage(
  {
    js$value <- matrix(1+0i)
  }
  , ERR_COMPLEX_1
)

assertMessage(
  {
    v <- matrix(1+0i)
    js %~% "R.get('v')"
  }
  , ERR_COMPLEX_2
)

assertMessage(
  {
    js$value <- data.frame(a = as.complex(1:10))
  }
  , ERR_COMPLEX_1
)

assertMessage(
  {
    v <- data.frame(a = as.complex(1:10))
    js %~% "R.get('v')"
  }
  , ERR_COMPLEX_2
)

assertMessage(
  {
    js$value <- list(as.complex(1:10))
  }
  , ERR_COMPLEX_1
)

assertMessage(
  {
    v <- list(as.complex(1:10))
    js %~% "R.get('v')"
  }
  , ERR_COMPLEX_2
)

assertMessage(
  {
    js$value <- Sys.Date()
  }
  , "Values of class 'Date' are not supported."
)

assertMessage(
  {
    js$value <- expression({1 + 1})
  }
  , "method setScriptEngineValue with signature (Ljava/lang/String;)V not found"
)

assertMessage(
  {
    js$value <- a ~ c + d
  }
  , "Values of class 'formula' are not supported."
)

assertMessage(
  {
    js$value <- function() {}
  }
  , "Values of class 'function' are not supported."
)

assertMessage(
  {
    v <- function() {}
    js %~% "R.get('v')"
  }
  , "java.lang.RuntimeException: Error in throwUnsupportedRtypeException(class(value)): Values of class 'function' are not supported.\n"
)

assertMessage(
  {
    js$value <- as.POSIXct(Sys.time(), "GMT")
  }
  , "Values of class 'POSIXct' are not supported."
)

assertMessage(
  {
    js$value <- as.POSIXlt(Sys.time(), "GMT")
  }
  , "Values of class 'POSIXlt' are not supported."
)

# Test unsupported type in evaluation
assertMessage(
  {
    js %~% "new java.util.Random(10);"
  }
  , ERR_JAVA_UTIL_RANDOM
)

# Test unsupported type in recursive evaluation
assertMessage(
  {
    script1 <- "new java.util.Random(10);"
    script2 <- "R.eval('js %~% script1')"
    js %~% "R.eval('js %~% script2')"
  }
  , ERR_JAVA_UTIL_RANDOM
  , exact.match = FALSE
)

# Test unsupported type in function call
assertMessage(
  {
    js %@% "function f() new java.util.Random(10);"
    js$invokeFunction("f")
  }
  , ERR_JAVA_UTIL_RANDOM
)

# Test unsupported type in method call
assertMessage(
  {
    js %@% "var o = {f:f};"
    js$invokeMethod("o", "f")
  }
  , ERR_JAVA_UTIL_RANDOM
)

# Test unsupported type in a Java array.
assertMessage(
  {
    js %@% "var RandomArrayClass = Java.type('java.util.Random[]');"
    js %@% "var value = new RandomArrayClass(2);"
    js %@% "value[0] = new java.util.Random(10);"
    js$value
  }
  , ERR_JAVA_UTIL_RANDOM
)

# Test unsupported type in a ScriptObjectMirror array
assertMessage(
  {
    js %@% "var value = [new java.util.Random(10)];"
    js$value
  }
  , ERR_JAVA_UTIL_RANDOM
)

# Test unsupported type in a map
assertMessage(
  {
    js$setDataFrameRowMajor(FALSE)
    js$value <- mtcars[1:3, ]
    js %@% "value.cyl = new java.util.Random(10);"
    js %~% "value;"
  }
  , ERR_JAVA_UTIL_RANDOM
)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

# Test unsupported type in a map in an ArrayList
assertMessage(
  {
    js$setDataFrameRowMajor(TRUE)
    js$value <- mtcars[1:3, ]
    js %@% "value[0].cyl = new java.util.Random(10);"
    js %~% "value;"
  }
  , ERR_JAVA_UTIL_RANDOM
)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

# Test unsupported type in a nested map.
assertMessage(
  {
    js$value <- list(list(list(a = c(1, 2), b = 2)))
    js %@% "value[0][0].b = new java.util.Random(10);"
    js %~% "value"
  }
  , ERR_JAVA_UTIL_RANDOM
)


# Warnings ----------------------------------------------------------------

assertMessage(
  {
    js$value <- c(TRUE, NA, FALSE)
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$value <- as.array(c(TRUE, NA, FALSE))
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

js$setCoerceFactors(TRUE)
assertMessage(
  {
    js$value <- as.factor(c(TRUE, NA, FALSE))
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)
js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)

assertMessage(
  {
    js$value <- list(c(TRUE, NA, FALSE))
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$value <- data.frame(a = c(TRUE, NA, FALSE))
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$value <- list(a = c(TRUE, NA, FALSE))
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$value <- matrix(c(TRUE, NA, FALSE, TRUE), 2, 2)
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js %~% "TestDataClass.getBoxedBooleanArray1dNulls()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major")
    js %~% "TestDataClass.getBoxedBooleanArray2dNulls1()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major")
    js %~% "TestDataClass.getBoxedBooleanArray2dNulls2()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major-java")
    js %~% "TestDataClass.getBoxedBooleanArray2dNulls1()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major-java")
    js %~% "TestDataClass.getBoxedBooleanArray2dNulls2()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("column-major")
    js %~% "TestDataClass.getBoxedBooleanArray2dNulls1()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("column-major")
    js %~% "TestDataClass.getBoxedBooleanArray2dNulls2()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_LOGICAL_VALUES
  , message.type = "warning"
)

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)

assertMessage(
  {
    js %~% "var a = new java.lang.Byte(1);"
    js %~% "var b = [a, a, a];"
    js %~% "b[1] = null;"
    js$b
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js %~% "var a = new java.lang.Byte(1);"
    js %~% "var b = [a, a, a];"
    js %~% "var c = [a, null, a];"
    js %~% "[b, c, b];"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js %~% "var a = new java.lang.Byte(1);"
    js %~% "var b = [a, a, a];"
    js %~% "var c = [a, null, a];"
    js %~% "[[b, c, b], [b, c, b]];"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js %~% "TestDataClass.getBoxedByteArray1dNulls()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major")
    js %~% "TestDataClass.getBoxedByteArray2dNulls1()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major")
    js %~% "TestDataClass.getBoxedByteArray2dNulls2()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major-java")
    js %~% "TestDataClass.getBoxedByteArray2dNulls1()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("row-major-java")
    js %~% "TestDataClass.getBoxedByteArray2dNulls2()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("column-major")
    js %~% "TestDataClass.getBoxedByteArray2dNulls1()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

assertMessage(
  {
    js$setArrayOrder("column-major")
    js %~% "TestDataClass.getBoxedByteArray2dNulls2()"
  }
  , jdx::jdxConstants()$MSG_WARNING_MISSING_RAW_VALUES
  , message.type = "warning"
)

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# NULL Values -------------------------------------------------------------

cat("NULL Values\n")
js$setLengthOneVectorAsArray(FALSE)
assertIdentical(NULL, js$not_defined)
js$value <- NULL
assertIdentical(NULL, js$value)
a <- list(a = NULL)
js$value <- a
assertIdentical(a, js$value)

js$setLengthOneVectorAsArray(TRUE)
assertIdentical(NULL, js$not_defined)
js$value <- NULL
assertIdentical(NULL, js$value)
a <- list(a = NULL)
js$value <- a
assertIdentical(a, js$value)

js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)

# Vectors and Arrays of Length Zero ----------------------------------------

cat("Vectors and Arrays of Length Zero\n")

l1 <- list(
  numeric()
  , integer()
  , character()
  , logical()
  , raw()
)
l1 <- appendValuesAsArrays(l1)

js$setLengthOneVectorAsArray(FALSE)
testSetAndGet(l1)

js$setLengthOneVectorAsArray(TRUE)
testSetAndGet(l1)

js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)


# Vectors and Arrays of Length One ----------------------------------------

cat("Vectors and Arrays of Length One\n")

l1 <- list(
  NA_real_
  , NA_integer_
  , NA_character_
  , NA # NA is logical and will be coerced to FALSE with a warning.
)
l1 <- appendValuesAsArrays(l1)
l2 <- list(NA_real_, NA_integer_, NA_character_, FALSE, NA_real_, NA_integer_, NA_character_, FALSE)

js$setLengthOneVectorAsArray(FALSE)
suppressWarnings(testSetAndGet(l1, l2))

js$setLengthOneVectorAsArray(TRUE)
suppressWarnings(testSetAndGet(l1, l2))

l1 <- list(
  0
  , 1
  , -1
  , Inf
  , -Inf
  , NaN
  , pi
  , .Machine$double.eps
  , .Machine$double.neg.eps
  , .Machine$double.xmax
  , .Machine$double.xmin

  , 0L
  , 1L
  , -1L
  , .Machine$integer.max

  , ""
  , "  "
  , "abc"

  , TRUE
  , FALSE

  , as.raw(0L)
  , as.raw(1L)
  , as.raw(255L)
)
l1 <- appendValuesAsArrays(l1)

js$setLengthOneVectorAsArray(FALSE)
testSetAndGet(l1)

js$setLengthOneVectorAsArray(TRUE)
testSetAndGet(l1)

js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)


# Vectors and Arrays of Length n ------------------------------------------

cat("Vectors and Arrays of Length n\n")

l1 <- list(
  c(NA, NA, NA)
  , c(NA_character_, NA_character_)
  , c(NA_integer_, NA_integer_)
  , c(NA_real_, NA_real_)
)
l1 <- appendValuesAsArrays(l1)
l2 <- c(l1, l1)
l2[[1]] <- c(FALSE, FALSE, FALSE)
l2[[5]] <- c(FALSE, FALSE, FALSE)

suppressWarnings(testSetAndGet(l1, l2))

l1 <- list(
  c(NA_real_, NaN, Inf, -Inf, pi, .Machine$double.eps, .Machine$double.neg.eps, 0, -1)

  , c(NA_integer_, 1L, 2L, 3L, 0L, -1L, .Machine$integer.max)

  , c(NA_character_, "", "", "")
  , c("  ", "  ", "")
  , LETTERS

  , c(TRUE, FALSE, TRUE)

  , as.raw(0:255)
)
l1 <- appendValuesAsArrays(l1)
testSetAndGet(l1)


# Vectors from Collections ------------------------------------------------

cat("Vectors from Collections\n")

# This section tests converting collections to vectors. We use the fact that jdx
# creates Java collections from unnamed R lists to simplify testing collections.

# If an unnamed list (or any other collection) contains only scalars, it will be
# converted to a vector.
js$setLengthOneVectorAsArray(FALSE)
v <- NA_integer_
testSetAndGet(list(as.list(v)), list(v))
v <- NA_real_
testSetAndGet(list(as.list(v)), list(v))
v <- NA_character_
testSetAndGet(list(as.list(v)), list(list(NULL)))
v <- NA
suppressWarnings(testSetAndGet(list(as.list(v)), list(FALSE)))
v <- -1.1
testSetAndGet(list(as.list(v)), list(v))
v <- -1L
testSetAndGet(list(as.list(v)), list(v))
v <- "a"
testSetAndGet(list(as.list(v)), list(v))
v <- TRUE
testSetAndGet(list(as.list(v)), list(v))
v <- as.raw(1L)
testSetAndGet(list(as.list(v)), list(v))
js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)

v <- -1.1:3.1
testSetAndGet(list(as.list(c(v, NA))), list(c(v, NA)))
v <- -1:20
testSetAndGet(list(as.list(c(v, NA))), list(c(v, NA)))
v <- c(TRUE, FALSE, TRUE)
suppressWarnings(testSetAndGet(list(as.list(c(v, NA))), list(c(v, FALSE))))
v <- letters
testSetAndGet(list(as.list(c(v, NA))), list(c(v, NA)))
v <- as.raw(0:255)
testSetAndGet(list(as.list(v)), list(v))

# A mix of raw (byte), integer (int), and numeric (double) values in a
# collection will be converted to the most general compatible vector type.
testSetAndGet(list(list(2.2, 1L, as.raw(255))), list(c(2.2, 1, -1))) # Reverts to numeric.
testSetAndGet(list(list(2.2, as.raw(255), 1L)), list(c(2.2, -1, 1))) # Reverts to numeric.
testSetAndGet(list(list(1L, 2.2, as.raw(255))), list(c(1, 2.2, -1))) # Reverts to numeric.
testSetAndGet(list(list(1L, as.raw(255), 2.2)), list(c(1, -1, 2.2))) # Reverts to numeric.
testSetAndGet(list(list(1L, 2.2)), list(c(1, 2.2))) # Reverts to numeric.
testSetAndGet(list(list(2.2, 1L)), list(c(2.2, 1))) # Reverts to numeric.
testSetAndGet(list(list(as.raw(255), 2.2)), list(c(-1, 2.2))) # Reverts to numeric.
testSetAndGet(list(list(2.2, as.raw(255))), list(c(2.2, -1))) # Reverts to numeric.
testSetAndGet(list(list(1L, as.raw(255))), list(c(1L, -1L))) # Reverts to integer.
testSetAndGet(list(list(as.raw(255), 1L)), list(c(-1L, 1L))) # Reverts to integer.

js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)

cat("Vectors from Collections - JavaScript\n")

# IMPORTANT: JavaScript arrays are collections of java.lang.Object.
# This code tests Collection to Vector coercion with more Java types.

# Prepare byte for raw testing. Other Java types will be tested elsewhere.
js %@% "
var ByteClass = Java.type('java.lang.Byte');
var b = new ByteClass(-1); // equal to R as.raw(255)
"

# All nulls will be converted to a list of NULLs.
js %@% "var value = [null, null, null]"
assertIdentical(list(NULL, NULL, NULL), js$value)

# Numeric vector
js %@% "var value = [-1.0, 0.0, 1.0, 2.0, 3.0, null]"
assertIdentical(c(-1:3, NA_real_), js$value)

# Integer vector
js %@% "var value = [-1, 0, 1, 2, 3, null]"
assertIdentical(c(-1:3, NA_integer_), js$value)
js %@% "var value = [null, -1, 0, 1, 2, 3, null]"
assertIdentical(c(NA, -1:3, NA_integer_), js$value)

# Integer vector will fail coercion on last member, will fall back to numeric.
js %@% "var value = [-1, 0, 1, 2, 3, 3.1]"
assertIdentical(c(-1:3, 3.1), js$value)

# Integer vector will fail coercion on last member, will fall back to list.
js %@% "var value = [0, 'a']"
assertIdentical(list(0L, "a"), js$value)

# Character vector
js %@% "var value = ['a', 'b', 'c']"
assertIdentical(c("a", "b", "c"), js$value)
js %@% "var value = ['a', 'b', null]"
assertIdentical(c("a", "b", NA_character_), js$value)

# Logical vector
js %@% "var value = [true, false, true]"
assertIdentical(c(TRUE, FALSE, TRUE), js$value)
js %@% "var value = [true, false, null]"
assertIdentical(c(TRUE, FALSE, FALSE), suppressWarnings(js$value))

# Raw vector of length one
js %@% "
var ByteClass = Java.type('java.lang.Byte');
var b = new ByteClass(-1); // equal to R as.raw(255)
var value = [b];
"
assertIdentical(as.raw(c(255L)), js$value)

# Raw vector
js %@% "var value = [b, b, b];"
assertIdentical(as.raw(c(255L, 255L, 255L)), js$value)
js %@% "var value = [b, null, b];"
assertIdentical(as.raw(c(255L, 0L, 255L)), suppressWarnings(js$value))

# Raw vector will fall back to integer.
js %@% "var value = [b, 2, 3];"
assertIdentical(c(-1L, 2:3), js$value)

# Raw vector will fall back to numeric.
js %@% "var value = [b, 2, 3.1];"
assertIdentical(c(-1, 2, 3.1), js$value)

# Raw vector will fall back to list.
js %@% "var value = [b, 2, 'a'];"
assertIdentical(list(as.raw(255), 2L, "a"), js$value)

# Java Character vector of length one.
js %@% "
var CharacterClass = Java.type('java.lang.Character');
var c = new CharacterClass('\\u0020');
var value = [c];
"
assertIdentical(" ", js$value)

# Character vector
js %@% "var value = [c, c, c];"
assertIdentical(c(" ", " ", " "), js$value)
js %@% "var value = [c, c, null];"
assertIdentical(c(" ", " ", NA_character_), js$value)

# Character/String vector
js %@% "var value = [c, c, c, 'abc'];"
assertIdentical(c(" ", " ", " ", 'abc'), js$value)

# Incompatible types, returns list.
js %@% "var value = [c, 'abc', true];"
assertIdentical(list(" ", "abc", TRUE), js$value)
js %@% "var value = [c, 'abc', 1.1];"
assertIdentical(list(" ", "abc", 1.1), js$value)
js %@% "var value = [c, 'abc', 1];"
assertIdentical(list(" ", "abc", 1L), js$value)
js %@% "var value = [c, 'abc', b];"
assertIdentical(list(" ", "abc", as.raw(255)), js$value)
js %@% "var value = [c, 'abc', [b, b]];" # Will convert byte collection to raw.
assertIdentical(list(" ", "abc", as.raw(c(255, 255))), js$value)

# Object[] arrays should be handled the same way as collections.
js %@% "
var ObjectArray1d = Java.type('java.lang.Object[]');
var value = new ObjectArray1d(0);
"
assertIdentical(list(), js$value)
js %@% "
var value = new ObjectArray1d(4);
value[0] = 1;
value[1] = 2;
value[2] = null;
value[3] = 4;
"
assertIdentical(c(1L, 2L, NA_integer_, 4L), js$value)

# Arrays of other objects should also be handled as collections.
js %@% "
var StringBufferArray1d = Java.type('java.lang.StringBuffer[]');
var value = new StringBufferArray1d(0);
"
assertIdentical(list(), js$value)


# Unicode -----------------------------------------------------------------

cat("Unicode\n")
v <- sapply(0:0xFFFF, intToUtf8)
js$value <- v
assertIdentical(v, js$value)


# Factors -----------------------------------------------------------------

cat("Factors\n")

js$setCoerceFactors(TRUE)

l1 <- list(factor())
l2 <- list(character())
js$setLengthOneVectorAsArray(FALSE)
testSetAndGet(l1, l2)
js$setLengthOneVectorAsArray(TRUE)
testSetAndGet(l1, l2)

l1 <- list(
  as.factor(NA_character_)
  , as.factor("a")
  , as.factor(letters)
  , as.factor(c(letters, NA, "", " "))
)
l2 <- list(
  NA_character_
  , "a"
  , letters
  , c(letters, NA, "", " ")
)
js$setLengthOneVectorAsArray(FALSE)
testSetAndGet(l1, l2)
js$setLengthOneVectorAsArray(TRUE)
testSetAndGet(l1, l2)

l1 <- list(
  as.factor(c(1.1, 2.2, Inf, -Inf))
  , as.factor(c(1, Inf))
  , as.factor(c(1.1, NA))
  , as.factor(c("1.1", "NaN"))
  , as.factor(c(round(pi, 14)))
  , as.factor(c("1.1", "A"))
  , as.factor(c("1.1", "TRUE"))
  , as.factor(c("1.1", "NA"))
  , as.factor(c("1.1", ""))
)
l2 <- list(
  c(1.1, 2.2, Inf, -Inf)
  , c(1, Inf)
  , c(1.1, NA)
  , c(1.1, NaN)
  , c(round(pi, 14))
  , c("1.1", "A")
  , c("1.1", "TRUE")
  , c("1.1", "NA")
  , c("1.1", "")
)
js$setLengthOneVectorAsArray(FALSE)
testSetAndGet(l1, l2)
js$setLengthOneVectorAsArray(TRUE)
testSetAndGet(l1, l2)

l1 <- list(
  as.factor(0L)
  , as.factor(1:20)
  , as.factor(c(1L, NA, .Machine$integer.max, -.Machine$integer.max))
  , as.factor(c("1", "A"))
  , as.factor(c("1", "TRUE"))
  , as.factor(c("1", "NA"))
  , as.factor(c("1", ""))
)
l2 <- list(
  0L
  , 1:20
  , c(1L, NA, .Machine$integer.max, -.Machine$integer.max)
  , c("1", "A")
  , c("1", "TRUE")
  , c("1", "NA")
  , c("1", "")
)
js$setLengthOneVectorAsArray(FALSE)
testSetAndGet(l1, l2)
js$setLengthOneVectorAsArray(TRUE)
testSetAndGet(l1, l2)

l1 <- list(
  as.factor(c(TRUE))
  , as.factor(c(TRUE, NA))
  , as.factor(c(FALSE))
  , as.factor(c(FALSE, NA))
  , as.factor(c("TRUE", "A"))
  , as.factor(c("TRUE", "1"))
  , as.factor(c("TRUE", "1.1"))
  , as.factor(c("TRUE", "NA"))
  , as.factor(c("TRUE", "NaN"))
  , as.factor(c("TRUE", ""))
)
l2 <- list(
  c(TRUE)
  , c(TRUE, FALSE)
  , c(FALSE)
  , c(FALSE, FALSE)
  , c("TRUE", "A")
  , c("TRUE", "1")
  , c("TRUE", "1.1")
  , c("TRUE", "NA")
  , c("TRUE", "NaN")
  , c("TRUE", "")
)
js$setLengthOneVectorAsArray(FALSE)
suppressWarnings(testSetAndGet(l1, l2))
js$setLengthOneVectorAsArray(TRUE)
suppressWarnings(testSetAndGet(l1, l2))

js$setCoerceFactors(FALSE)

l1 <- list(
  as.factor(NA_character_)
  , as.factor("a")
  , as.factor(letters)
  , as.factor(c(letters, NA, "", " "))

  , as.factor(c(1.1, 2.2, Inf, -Inf))
  , as.factor(c(1, Inf))
  , as.factor(c(1.1, NA))
  , as.factor(c(round(pi, 14)))

  , as.factor(0L)
  , as.factor(1:20)
  , as.factor(c(1L, NA, .Machine$integer.max, -.Machine$integer.max))

  , as.factor(c(TRUE))
  , as.factor(c(TRUE, NA))
  , as.factor(c(FALSE))
  , as.factor(c(FALSE, NA))
)
l2 <- list(
  NA_character_
  , "a"
  , letters
  , c(letters, NA, "", " ")

  , c("1.1", "2.2", "Inf", "-Inf")
  , c("1", "Inf")
  , c("1.1", NA)
  , c(as.character(round(pi, 14)))

  , "0"
  , as.character(1:20)
  , as.character(c(1L, NA, .Machine$integer.max, -.Machine$integer.max))

  , c("TRUE")
  , c("TRUE", NA)
  , c("FALSE")
  , c("FALSE", NA)
)

js$setLengthOneVectorAsArray(FALSE)
testSetAndGet(l1, l2)
js$setLengthOneVectorAsArray(TRUE)
testSetAndGet(l1, l2)

js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)
js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)


# Matrices of Length Zero -------------------------------------------------

cat("Matrices of Length Zero\n")
l1 <- list(
  matrix(numeric(), 0, 0)
  , matrix(integer(), 0, 0)
  , matrix(logical(), 0, 0)
  , matrix(character(), 0, 0)
  , matrix(raw(), 0, 0)
)
js$setArrayOrder("column-major")
testSetAndGet(l1)
js$setArrayOrder("row-major")
testSetAndGet(l1)
js$setArrayOrder("row-major-java")
testSetAndGet(l1)

# By default, rJava converts matrices as row-major. The default behavior for
# zero-length matrices is as follows, assuming the variable names is
# 'value'.
#
#     matrix(0, 0, 0) becomes double[][] value = {};
#     matrix(0, 0, 1) becomes double[][] value = {};
#     matrix(0, 1, 0) becomes double[][] value = {{}};
#
# jdx supports column-major matrices. It mimics the zero-length
# row-major behavior as follows.
#
#     matrix(0, 0, 0) becomes double[][] value = {};
#     matrix(0, 0, 1) becomes double[][] value = {{}};
#     matrix(0, 1, 0) becomes double[][] value = {};

js$setArrayOrder("column-major")
# The expression `matrix(character())` produces a matrix of zero rows, one
# column. In the column-major setting, this will produce a Java matrix with one
# element containing an array with zero elements (see the comments above).
js$value <- matrix(character())
assertIdentical(matrix(character(), 0, 1), js$value)
js$value <- matrix(character(), 1, 0)
assertIdentical(matrix(character(), 0, 0), js$value)

js$value <- matrix(numeric())
assertIdentical(matrix(numeric(), 0, 1), js$value)
js$value <- matrix(numeric(), 1, 0)
assertIdentical(matrix(numeric(), 0, 0), js$value)

js$value <- matrix(integer())
assertIdentical(matrix(integer(), 0, 1), js$value)
js$value <- matrix(integer(), 1, 0)
assertIdentical(matrix(integer(), 0, 0), js$value)

js$value <- matrix(logical())
assertIdentical(matrix(logical(), 0, 1), js$value)
js$value <- matrix(logical(), 1, 0)
assertIdentical(matrix(logical(), 0, 0), js$value)

js$value <- matrix(raw())
assertIdentical(matrix(raw(), 0, 1), js$value)
js$value <- matrix(raw(), 1, 0)
assertIdentical(matrix(raw(), 0, 0), js$value)

js$setArrayOrder("row-major")
# In the row-major setting, the results are opposite of the column-major setting.
js$value <- matrix(character())
assertIdentical(matrix(character(), 0, 0), js$value)
js$value <- matrix(character(), 1, 0)
assertIdentical(matrix(character(), 1, 0), js$value)

js$value <- matrix(numeric())
assertIdentical(matrix(numeric(), 0, 0), js$value)
js$value <- matrix(numeric(), 1, 0)
assertIdentical(matrix(numeric(), 1, 0), js$value)

js$value <- matrix(integer())
assertIdentical(matrix(integer(), 0, 0), js$value)
js$value <- matrix(integer(), 1, 0)
assertIdentical(matrix(integer(), 1, 0), js$value)

js$value <- matrix(logical())
assertIdentical(matrix(logical(), 0, 0), js$value)
js$value <- matrix(logical(), 1, 0)
assertIdentical(matrix(logical(), 1, 0), js$value)

js$value <- matrix(raw())
assertIdentical(matrix(raw(), 0, 0), js$value)
js$value <- matrix(raw(), 1, 0)
assertIdentical(matrix(raw(), 1, 0), js$value)

js$setArrayOrder("row-major-java")
js$value <- matrix(character())
assertIdentical(matrix(character(), 0, 0), js$value)
js$value <- matrix(character(), 1, 0)
assertIdentical(matrix(character(), 1, 0), js$value)

js$value <- matrix(numeric())
assertIdentical(matrix(numeric(), 0, 0), js$value)
js$value <- matrix(numeric(), 1, 0)
assertIdentical(matrix(numeric(), 1, 0), js$value)

js$value <- matrix(integer())
assertIdentical(matrix(integer(), 0, 0), js$value)
js$value <- matrix(integer(), 1, 0)
assertIdentical(matrix(integer(), 1, 0), js$value)

js$value <- matrix(logical())
assertIdentical(matrix(logical(), 0, 0), js$value)
js$value <- matrix(logical(), 1, 0)
assertIdentical(matrix(logical(), 1, 0), js$value)

js$value <- matrix(raw())
assertIdentical(matrix(raw(), 0, 0), js$value)
js$value <- matrix(raw(), 1, 0)
assertIdentical(matrix(raw(), 1, 0), js$value)

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# Matrices of Size One ----------------------------------------------------

cat("Matrices of Size One\n")

l1 <- list(
  matrix(0)
  , matrix(NaN)
  , matrix(Inf)
  , matrix(-Inf)
  , matrix(NA_real_)

  , matrix(0L)
  , matrix(NA_integer_)

  , matrix("ABC")
  , matrix(NA_character_)

  , matrix(TRUE)
  , matrix(FALSE)
  , matrix(NA)

  , matrix(as.raw(0))
  , matrix(as.raw(1))
  , matrix(as.raw(255))
)
l2 <- l1
l2[[12]] <- matrix(FALSE)
js$setArrayOrder("row-major")
suppressWarnings(testSetAndGet(l1, l2))
js$setArrayOrder("row-major-java")
suppressWarnings(testSetAndGet(l1, l2))
js$setArrayOrder("column-major")
suppressWarnings(testSetAndGet(l1, l2))

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# Matrices - One Row/Column -----------------------------------------------

cat("Matrices - One Row/Column\n")

l1 <- list(
  matrix(as.numeric(1:6), 1, 6)
  , matrix(as.numeric(1:6), 6, 1)
  , matrix(rep(NaN, times = 6), 1, 6)
  , matrix(rep(NaN, times = 6), 6, 1)
  , matrix(rep(NA_real_, times = 6), 1, 6)
  , matrix(rep(NA_real_, times = 6), 6, 1)

  , matrix(1:6, 1, 6)
  , matrix(1:6, 6, 1)
  , matrix(rep(NA_integer_, times = 6), 1, 6)
  , matrix(rep(NA_integer_, times = 6), 6, 1)

  , matrix(letters, length(letters), 1)
  , matrix(letters, 1, length(letters))
  , matrix(rep(NA_character_, times = 6), 1, 6)
  , matrix(rep(NA_character_, times = 6), 6, 1)

  , matrix(rep(c(TRUE, FALSE), times = 3), 1, 6)
  , matrix(rep(c(TRUE, FALSE), times = 3), 6, 1)
  , matrix(rep(NA, times = 6), 1, 6)
  , matrix(rep(NA, times = 6), 6, 1)

  , matrix(as.raw(250:255), 1, 6)
  , matrix(as.raw(250:255), 6, 1)
)
l2 <- l1
l2[[17]] <- matrix(rep(FALSE, times = 6), 1, 6)
l2[[18]] <- matrix(rep(FALSE, times = 6), 6, 1)
js$setArrayOrder("row-major")
suppressWarnings(testSetAndGet(l1, l2))
js$setArrayOrder("row-major-java")
suppressWarnings(testSetAndGet(l1, l2))
js$setArrayOrder("column-major")
suppressWarnings(testSetAndGet(l1, l2))

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# Matrices ----------------------------------------------------------------

cat("Matrices\n")

l1 <- list(
  matrix(as.numeric(1:26), 13, 2) # Numeric
  , matrix(c(pi, .Machine$double.xmin, .Machine$double.xmax, -1), 2, 2) # Numeric
  , matrix(c(NA, NaN, Inf, -Inf, TRUE, FALSE), 2, 3) # Special numeric values

  , matrix(c(1:26, .Machine$integer.max, 0L, -1L, NA_integer_), 15, 2)  # Integer

  , matrix(letters, 13, 2)   # Character
  , matrix(c("a", NA, "", " "), 2, 2)   # Character

  , matrix(c(TRUE, FALSE, TRUE, FALSE, NA, NA), 2, 3) # Logical

  , matrix(as.raw(0:255), 64)
)
l2 <- l1
l2[[7]] <- matrix(c(TRUE, FALSE, TRUE, FALSE, FALSE, FALSE), 2, 3)
js$setArrayOrder("row-major")
suppressWarnings(testSetAndGet(l1, l2))
js$setArrayOrder("row-major-java")
suppressWarnings(testSetAndGet(l1, l2))
js$setArrayOrder("column-major")
suppressWarnings(testSetAndGet(l1, l2))

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# Matrices from Collections -----------------------------------------------

cat("Matrices from Collections\n")

# To simplify creating collections for testing, we use the fact that jdx
# converts R unnamed lists to collections.

# If an unnamed list (or any other collection) contains same-length vectors of
# compatible types, it will be converted to a matrix. Otherwise, a list of
# objects is returned.
v <- matrix(1.1:9.1, 3, 3)
l1 <- list(as.list(v[, 1]), as.list(v[, 2]), as.list(v[, 3]))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))
l1 <- list(v[, 1], v[, 2], v[, 3])
l1[[4]] <- c(1.1, 2.2, 3.3, 4.4) # No longer a matrix-shaped collection because vectors are of differing length
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))

v <- matrix(1:9, 3, 3)
l1 <- list(as.list(v[, 1]), as.list(v[, 2]), as.list(v[, 3]))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

v <- matrix(as.raw(247:255), 3, 3)
l1 <- list(as.list(v[, 1]), as.list(v[, 2]), as.list(v[, 3]))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

v <- matrix(letters[1:9], 3, 3)
l1 <- list(as.list(v[, 1]), as.list(v[, 2]), as.list(v[, 3]))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

v <- matrix(c(TRUE, FALSE, TRUE), 3, 3)
l1 <- list(as.list(v[, 1]), as.list(v[, 2]), as.list(v[, 3]))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

# A mix of numeric, integer, and raw columns will be converted to a numeric matrix.
l1 <- list(as.raw(253:255), 1:3, 1.1:3.1)
v <- matrix(c(-3:-1, 1:3, 1.1:3.1), 3, 3)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

l1 <- list(as.raw(253:255), 1.1:3.1, 1:3)
v <- matrix(c(-3:-1, 1.1:3.1, 1:3), 3, 3)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

l1 <- list(1.1:3.1, as.raw(253:255), 1:3)
v <- matrix(c(1.1:3.1, -3:-1, 1:3), 3, 3)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

l1 <- list(1.1:3.1, 1:3, as.raw(253:255))
v <- matrix(c(1.1:3.1, 1:3, -3:-1), 3, 3)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

l1 <- list(1:3, 1.1:3.1, as.raw(253:255))
v <- matrix(c(1:3, 1.1:3.1, -3:-1), 3, 3)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

l1 <- list(1:3, as.raw(253:255), 1.1:3.1)
v <- matrix(c(1:3, -3:-1, 1.1:3.1), 3, 3)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

# A mix of integer and raw columns will be converted to an integer matrix.
l1 <- list(1:3, as.raw(253:255))
v <- matrix(c(1:3, -3:-1), 3, 2)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

l1 <- list(as.raw(253:255), 1:3)
v <- matrix(c(-3:-1, 1:3), 3, 2)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

# A mix of Java null and String/Character values will be converted to a character matrix.
# rJava converts NA_character_ to Java null.
l1 <- list(c(NA_character_, NA_character_, NA_character_), letters[1:3])
v <- matrix(c(NA_character_, NA_character_, NA_character_, letters[1:3]), 3, 2)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

# Mixed types within columns will also be converted to the most general type.
l1 <- list(
  list(as.raw(255), 1L, 1.1)
  , list(1.1, 1L, as.raw(255))
  , list(1L, as.raw(255), 1.1)
)
v <- matrix(
  c(
    -1, 1, 1.1
    , 1.1, 1, -1
    , 1, -1, 1.1
  )
  , 3
  , 3
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

l1 <- list(
  list(as.raw(255), 1L)
  , list(1L, as.raw(255))
)
v <- matrix(
  c(
    -1L, 1L
    , 1L, -1L
  )
  , 2
  , 2
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(v))
js$setArrayOrder("row-major")
testSetAndGet(list(l1), list(t(v)))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(t(v)))

# If mixed types are not compatible, a list is returned instead of a matrix.
l1 <- list(
  list(as.raw(255), "a")
  , list("a", as.raw(255))
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))

l1 <- list(
  list(as.raw(255), TRUE)
  , list(FALSE, as.raw(255))
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))

l1 <- list(
  list(1L, "a")
  , list("a", 1L)
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))

l1 <- list(
  list(1L, TRUE)
  , list(FALSE, 1L)
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))

l1 <- list(
  list(1, "a")
  , list("a", 1)
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))

l1 <- list(
  list(1, TRUE)
  , list(FALSE, 1)
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))

l1 <- list(
  list("a", TRUE)
  , list(FALSE, "a")
)
js$setArrayOrder("column-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major")
testSetAndGet(list(l1))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1))


# cat("Collections as Matrices - JavaScript\n")

# Test boxed and unboxed arrays together.
js %@% "
var doubleArrayClass = Java.type('double[]');
var DoubleArrayClass = Java.type('java.lang.Double[]');
var ArrayListClass = Java.type('java.util.ArrayList');
var al = new ArrayListClass(2);
al.add(new DoubleArrayClass(0));
al.add(new doubleArrayClass(0));
"
assertIdentical(matrix(0, 2, 0), js$al)

# Array of boxed values, array of unboxed values, and a collection of boxed
# values together. Note that the array of boxed values returns NA because each
# value is initialized as Java null.
js %@% "
var al = new ArrayListClass(3);
al.add(new DoubleArrayClass(5));
al.add(new doubleArrayClass(5));
al.add([1.1, 1.1, 1.1, 1.1, 1.1])
"
assertIdentical(matrix(c(rep(NA_real_, times = 5), rep(0, times = 5), rep(1.1, times = 5)), 3, 5, byrow = TRUE), js$al)

# Mix in an integer collection. The results will still be a numeric matrix.
js %@% "
var al = new ArrayListClass(3);
al.add(new DoubleArrayClass(5));
al.add(new doubleArrayClass(5));
al.add([1, 1, 1, 1, 1])
"
assertIdentical(matrix(c(rep(NA_real_, times = 5), rep(0, times = 5), rep(1, times = 5)), 3, 5, byrow = TRUE), js$al)

# Object[] arrays should be handled the same way as collections.
js %@% "
var ObjectArray1d = Java.type('java.lang.Object[]');
var ObjectArray2d = Java.type('java.lang.Object[][]');
var value = new ObjectArray2d(2);
var a = new ObjectArray1d(4);
a[0] = 1; a[1] = 2; a[2] = null; a[3] = 4;
value[0] = a;
value[1] = a;
"
js$setArrayOrder("column-major")
assertIdentical(matrix(c(1L, 2L, NA_integer_, 4L), 4, 2), js$value)
js$setArrayOrder("row-major")
assertIdentical(matrix(c(1L, 2L, NA_integer_, 4L), 2, 4, byrow = TRUE), js$value)
js$setArrayOrder("row-major-java")
assertIdentical(matrix(c(1L, 2L, NA_integer_, 4L), 2, 4, byrow = TRUE), js$value)

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# N-Dimensional Arrays of Length Zero -------------------------------------

# See section "Matrices of Length Zero"


# N-Dimensional Arrays - Row Major ----------------------------------------

cat("N-Dimensional Arrays - Row Major\n")

js$setArrayOrder("row-major")

# Two-dimensional
l2 <- list(
  array(integer(0), c(0, 0))
  , array(numeric(0), c(0, 0))
  , array(logical(0), c(0, 0))
  , array(character(0), c(0, 0))
  , array(raw(0), c(0, 0))
)
for (i in 0:5) {
  for (j in 0:5) {
    l1 <- list(
      array(1:(i * j), c(i, j))
      , array(as.numeric(1:(i * j)), c(i, j))
      , array(TRUE, c(i, j))
      , array(as.character(1:(i * j)), c(i, j))
      , array(as.raw(1:(i * j)), c(i, j))
    )
    if (i == 0) {
      testSetAndGet(l1, l2)
    } else {
      testSetAndGet(l1)
    }
  }
}

# Three-dimensional
for (i in 0:5) {
  for (j in 0:5) {
    for (k in 0:5) {
      l1 <- list(
        array(1:(i * j), c(i, j, k))
        , array(as.numeric(1:(i * j)), c(i, j, k))
        , array(TRUE, c(i, j, k))
        , array(as.character(1:(i * j * k)), c(i, j, k))
        , array(as.raw(1:(i * j * k)), c(i, j, k))
      )
      if (i == 0) {
        dimensions <- c(0, 0, 0)
        l2 <- list(
          array(integer(0), dimensions)
          , array(numeric(0), dimensions)
          , array(logical(0), dimensions)
          , array(character(0), dimensions)
          , array(raw(0), dimensions)
        )
        testSetAndGet(l1, l2)
      } else if (i > 0 & j == 0) {
        dimensions <- c(i, 0, 0)
        l2 <- list(
          array(integer(0), dimensions)
          , array(numeric(0), dimensions)
          , array(logical(0), dimensions)
          , array(character(0), dimensions)
          , array(raw(0), dimensions)
        )
        testSetAndGet(l1, l2)
      } else {
        testSetAndGet(l1)
      }
    }
  }
}

# Higher dimensions are tested sufficiently in jdx.

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)

# N-Dimensional Arrays - Column Major -------------------------------------

cat("N-Dimensional Arrays - Column Major\n")

js$setArrayOrder("column-major")

# Two-dimensional
l2 <- list(
  array(integer(0), c(0, 0))
  , array(numeric(0), c(0, 0))
  , array(logical(0), c(0, 0))
  , array(character(0), c(0, 0))
  , array(raw(0), c(0, 0))
)
for (i in 0:5) {
  for (j in 0:5) {
    l1 <- list(
      array(1:(i * j), c(i, j))
      , array(as.numeric(1:(i * j)), c(i, j))
      , array(TRUE, c(i, j))
      , array(as.character(1:(i * j)), c(i, j))
      , array(as.raw(1:(i * j)), c(i, j))
    )
    if (j == 0) {
      testSetAndGet(l1, l2)
    } else {
      testSetAndGet(l1)
    }
  }
}

# Three-dimensional
for (i in 0:5) {
  for (j in 0:5) {
    for (k in 0:5) {
      l1 <- list(
        array(1:(i * j), c(i, j, k))
        , array(as.numeric(1:(i * j)), c(i, j, k))
        , array(TRUE, c(i, j, k))
        , array(as.character(1:(i * j * k)), c(i, j, k))
        , array(as.raw(1:(i * j * k)), c(i, j, k))
      )
      if (k == 0) {
        dimensions <- c(0, 0, 0)
        l2 <- list(
          array(integer(0), dimensions)
          , array(numeric(0), dimensions)
          , array(logical(0), dimensions)
          , array(character(0), dimensions)
          , array(raw(0), dimensions)
        )
        testSetAndGet(l1, l2)
      } else if (k > 0 & j == 0) {
        dimensions <- c(0, 0, k)
        l2 <- list(
          array(integer(0), dimensions)
          , array(numeric(0), dimensions)
          , array(logical(0), dimensions)
          , array(character(0), dimensions)
          , array(raw(0), dimensions)
        )
        testSetAndGet(l1, l2)
      } else {
        testSetAndGet(l1)
      }
    }
  }
}

# Higher dimensions are tested sufficiently in jdx.

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# N-Dimensional Arrays - Row Major Java -----------------------------------

cat("N-Dimensional Arrays - Row Major Java\n")

js$setArrayOrder("row-major-java")

# Two-dimensional
l2 <- list(
  array(integer(0), c(0, 0))
  , array(numeric(0), c(0, 0))
  , array(logical(0), c(0, 0))
  , array(character(0), c(0, 0))
  , array(raw(0), c(0, 0))
)
for (i in 0:5) {
  for (j in 0:5) {
    l1 <- list(
      array(1:(i * j), c(i, j))
      , array(as.numeric(1:(i * j)), c(i, j))
      , array(TRUE, c(i, j))
      , array(as.character(1:(i * j)), c(i, j))
      , array(as.raw(1:(i * j)), c(i, j))
    )
    if (i == 0) {
      testSetAndGet(l1, l2)
    } else {
      testSetAndGet(l1)
    }
  }
}

# Three-dimensional
for (i in 0:5) {
  for (j in 0:5) {
    for (k in 0:5) {
      l1 <- list(
        array(1:(i * j), c(i, j, k))
        , array(as.numeric(1:(i * j)), c(i, j, k))
        , array(TRUE, c(i, j, k))
        , array(as.character(1:(i * j * k)), c(i, j, k))
        , array(as.raw(1:(i * j * k)), c(i, j, k))
      )
      if (k == 0) {
        dimensions <- c(0, 0, 0)
        l2 <- list(
          array(integer(0), dimensions)
          , array(numeric(0), dimensions)
          , array(logical(0), dimensions)
          , array(character(0), dimensions)
          , array(raw(0), dimensions)
        )
        testSetAndGet(l1, l2)
      } else if (k > 0 & i == 0) {
        dimensions <- c(0, 0, k)
        l2 <- list(
          array(integer(0), dimensions)
          , array(numeric(0), dimensions)
          , array(logical(0), dimensions)
          , array(character(0), dimensions)
          , array(raw(0), dimensions)
        )
        testSetAndGet(l1, l2)
      } else {
        testSetAndGet(l1)
      }
    }
  }
}

# Higher dimensions are tested sufficiently in jdx.

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)


# N-Dimensional Arrays from Collections -----------------------------------

# Higher dimensions are tested sufficiently in jdx with the exception of mixed types.

range <- 0:255
numeric.matrix <- array(as.numeric(range), c(256, 1))
integer.matrix <- array(range, c(256, 1))
logical.matrix <- array(rep(c(TRUE, FALSE), times = 128), c(256, 1))
character.matrix <- array(as.numeric(range), c(256, 1))
raw.matrix <- array(as.raw(range), c(256, 1))

# Mixed types using column-major and row-major-java

l1 <- list(numeric.matrix, integer.matrix, raw.matrix)
a <- array(as.numeric(c(range, range, 0:127, -128:-1)), c(256, 1, 3))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

l1 <- list(numeric.matrix, raw.matrix, integer.matrix)
a <- array(as.numeric(c(range, 0:127, -128:-1, range)), c(256, 1, 3))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

l1 <- list(integer.matrix, raw.matrix, numeric.matrix)
a <- array(as.numeric(c(range, 0:127, -128:-1, range)), c(256, 1, 3))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

l1 <- list(integer.matrix, numeric.matrix, raw.matrix)
a <- array(as.numeric(c(range, range, 0:127, -128:-1)), c(256, 1, 3))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

l1 <- list(raw.matrix, numeric.matrix, integer.matrix)
a <- array(as.numeric(c(0:127, -128:-1, range, range)), c(256, 1, 3))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

l1 <- list(raw.matrix, integer.matrix, numeric.matrix)
a <- array(as.numeric(c(0:127, -128:-1, range, range)), c(256, 1, 3))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

l1 <- list(integer.matrix, raw.matrix)
a <- array(as.integer(c(range, 0:127, -128:-1)), c(256, 1, 2))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

l1 <- list(raw.matrix, integer.matrix)
a <- array(as.integer(c(0:127, -128:-1, range)), c(256, 1, 2))
js$setArrayOrder("column-major")
testSetAndGet(list(l1), list(a))
js$setArrayOrder("row-major-java")
testSetAndGet(list(l1), list(a))

# Mixed types using row-major

js$setArrayOrder("row-major")

a <- array(as.numeric(1:18), c(3, 3, 2))
# js$value <- a
# js %~% "java.util.Arrays.deepToString(value);"

js %@% "var ByteClass = Java.type('java.lang.Byte');"
js %@% "function b(value) {return new ByteClass(value);}"

js %@% "var value = [[[1, 10], [4, 13], [7, 16]], [[2.0, 11.0], [5.0, 14.0], [8.0, 17.0]], [[b(3), b(12)], [b(6), b(15)], [b(9), b(18)]]];"
assertIdentical(a, js$value)

js %@% "var value = [[[1, 10], [4, 13], [7, 16]], [[b(2), b(11)], [b(5), b(14)], [b(8), b(17)]], [[3.0, 12.0], [6.0, 15.0], [9.0, 18.0]]];"
assertIdentical(a, js$value)

js %@% "var value = [[[1.0, 10.0], [4.0, 13.0], [7.0, 16.0]], [[2, 11], [5, 14], [8, 17]], [[b(3), b(12)], [b(6), b(15)], [b(9), b(18)]]];"
assertIdentical(a, js$value)

js %@% "var value = [[[1, 10], [4, 13], [7, 16]], [[b(2), b(11)], [b(5), b(14)], [b(8), b(17)]], [[3.0, 12.0], [6.0, 15.0], [9.0, 18.0]]];"
assertIdentical(a, js$value)

js %@% "var value = [[[b(1), b(10)], [b(4), b(13)], [b(7), b(16)]], [[2, 11], [5, 14], [8, 17]], [[3.0, 12.0], [6.0, 15.0], [9.0, 18.0]]];"
assertIdentical(a, js$value)

js %@% "var value = [[[b(1), b(10)], [b(4), b(13)], [b(7), b(16)]], [[2.0, 11.0], [5.0, 14.0], [8.0, 17.0]], [[3, 12], [6, 15], [9, 18]]];"
assertIdentical(a, js$value)

a <- array(1:12, c(2, 3, 2))
# js$value <- a
# js %~% "java.util.Arrays.deepToString(value);"

js %@% "var value = [[[1, 7], [3, 9], [5, 11]], [[b(2), b(8)], [b(4), b(10)], [b(6), b(12)]]];"
assertIdentical(a, js$value)

js %@% "var value = [[[b(1), b(7)], [b(3), b(9)], [b(5), b(11)]], [[2, 8], [4, 10], [6, 12]]];"
assertIdentical(a, js$value)

js$setArrayOrder(jsr223:::DEFAULT_ARRAY_ORDER)

# Data Frames - Errors ----------------------------------------------------

cat("Data Frames - Errors\n")

assertMessage(
  {
    df <- data.frame(a = 1L)
    names(df) <- NULL
    testSetAndGet(list(df))
  }
  , "Data frames and named lists are required to have unique names for each column or member."
)

assertMessage(
  {
    df <- data.frame(1L, 1.1)
    names(df) <- c("a", "a")
    testSetAndGet(list(df))
  }
  , "Data frames and named lists are required to have unique names for each column or member."
)

assertMessage(
  {
    js %@% "var m = new java.util.LinkedHashMap(2, 1);"
    js %@% "m.put('a', 1);"
    js %@% "m.put(2, 1);"
    js$m
  }
  , "java.lang.RuntimeException: Map keys must be string types."
)

assertMessage(
  {
    js$value <- data.frame(a = 1+2i)
  }
  , "Values of class 'complex' are not supported."
)


# Data Frames - Empty and Empty Values - Column Major ---------------------

cat("Data Frames - Empty and Empty Values - Column Major\n")

js$setDataFrameRowMajor(FALSE)
js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)

# Empty and one-column data frames come back as lists.
testSetAndGet(list(data.frame()), list(list()))
testSetAndGet(list(data.frame(a = integer())), list(list(a = integer())))
testSetAndGet(list(data.frame(a = character())), list(list(a = character())))
df <- data.frame(
  integer()
  , fix.empty.names = FALSE
  , check.names = FALSE
)
testSetAndGet(list(df), list(as.list(df)))

df <- data.frame(
  a = integer()
  , b = numeric()
  , c = logical()
  , d = character()
  , e = raw()
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df))

df$c <- as.factor(df$c) # Convert the logical vector to a factor.
df2 <- df
df2$c <- character() # When js$setCoerceFactors(FALSE), jdx converts factors to character vectors. When js$setStringsAsFactors(FALSE), the data frame is created without converting character vectors to factors.
testSetAndGet(list(df), list(df2))

js$setStringsAsFactors(TRUE)
df2$c <- as.factor(df2$c) # Now that js$setStringsAsFactors(TRUE), both character vectors will come back as factors.
df2$d <- as.factor(df2$d)
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(TRUE) # Because the vectors are empty, this should have no effect (i.e. the data frame factors will be converted to character vectors)
testSetAndGet(list(df), list(df2))

js %@% "
value.clear();
"
assertIdentical(list(), js$value)

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)


# Data Frames - Empty and Empty Values - Row Major ------------------------

cat("Data Frames - Empty and Empty Values - Row Major\n")

js$setDataFrameRowMajor(TRUE)
js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)

# Empty and one-column data frames come back as lists. When
# js$setDataFrameRowMajor(TRUE), the object is always an empty list.
testSetAndGet(list(data.frame()), list(list()))
testSetAndGet(list(data.frame(a = integer())), list(list()))
testSetAndGet(list(data.frame(a = character())), list(list()))
df <- data.frame(
  integer()
  , fix.empty.names = FALSE
  , check.names = FALSE
)
testSetAndGet(list(df), list(list()))

df <- data.frame(
  a = integer()
  , b = numeric()
  , c = logical()
  , d = character()
  , e = raw()
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df), list(list()))

js %@% "
value.clear();
"
assertIdentical(js$value, list())

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)


# Data Frames - One Row - Column Major ------------------------------------

cat("Data Frames - One Row - Column Major\n")

js$setDataFrameRowMajor(FALSE)
js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)

# For column-major, data frames with one column are returned as a list with a
# single member. For row-major, a data frame is returned.
df <- data.frame(a = 1L)
testSetAndGet(list(df), list(as.list(df)))
names(df) <- ""
testSetAndGet(list(df), list(as.list(df)))

df <- data.frame(
  a = NA_integer_
  , b = NA_real_
  , c = NA
  , d = NA_character_
  , stringsAsFactors = FALSE
)
df2 <- df
df2$c <- FALSE
suppressWarnings(testSetAndGet(list(df), list(df2)))

df$c <- as.factor(df$c) # Convert the logical vector to a factor.
df2 <- df
df2$c <- NA_character_ # When js$setCoerceFactors(FALSE), jdx converts factors to character vectors. When js$setStringsAsFactors(FALSE), the data frame is created without converting character vectors to factors.
testSetAndGet(list(df), list(df2))

js$setStringsAsFactors(TRUE)
df2$c <- as.factor(df2$c) # Now that js$setStringsAsFactors(TRUE), both character vectors will come back as factors.
df2$d <- as.factor(df2$d)
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(TRUE) # Because the vectors are NA, this should have no effect (i.e. the data frame factors will be converted to character vectors)
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)
df <- data.frame(
  a = .Machine$integer.max
  , b = pi
  , c = TRUE
  , d = ""
  , e = as.raw(0L)
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df))

df$c <- as.factor(df$c) # Convert the logical vector to a factor.
df2 <- df
df2$c <- "TRUE" # When js$setCoerceFactors(FALSE), jdx converts factors to character vectors. When js$setStringsAsFactors(FALSE), the data frame is created without converting character vectors to factors.
testSetAndGet(list(df), list(df2))

js$setStringsAsFactors(TRUE)
df2$c <- as.factor(df2$c) # Now that js$setStringsAsFactors(TRUE), both character vectors will come back as factors.
df2$d <- as.factor(df2$d)
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(TRUE)
df2$c <- TRUE
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)


# Data Frames - One Row - Row Major ---------------------------------------

cat("Data Frames - One Row - Row Major\n")

js$setDataFrameRowMajor(TRUE)
js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)

# For column-major, data frames with one column are returned as a list with a
# single member. For row-major, a data frame is returned.
df <- data.frame(a = 1L)
testSetAndGet(list(df))
names(df) <- ""
testSetAndGet(list(df))

df <- data.frame(
  a = NA_integer_
  , b = NA_real_
  , c = NA
  , d = NA_character_
  , stringsAsFactors = FALSE
)
df2 <- df
df2$c <- FALSE
suppressWarnings(testSetAndGet(list(df), list(df2)))

df$c <- as.factor(df$c) # Convert the logical vector to a factor.
df2 <- df
df2$c <- NA_character_ # When js$setCoerceFactors(FALSE), jdx converts factors to character vectors. When js$setStringsAsFactors(FALSE), the data frame is created without converting character vectors to factors.
testSetAndGet(list(df), list(df2))

js$setStringsAsFactors(TRUE)
df2$c <- as.factor(df2$c) # Now that js$setStringsAsFactors(TRUE), both character vectors will come back as factors.
df2$d <- as.factor(df2$d)
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(TRUE) # Because the vectors are NA, this should have no effect (i.e. the data frame factors will be converted to character vectors)
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)
df <- data.frame(
  a = .Machine$integer.max
  , b = pi
  , c = TRUE
  , d = ""
  , e = as.raw(0L)
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df))

df$c <- as.factor(df$c) # Convert the logical vector to a factor.
df2 <- df
df2$c <- "TRUE" # When js$setCoerceFactors(FALSE), jdx converts factors to character vectors. When js$setStringsAsFactors(FALSE), the data frame is created without converting character vectors to factors.
testSetAndGet(list(df), list(df2))

js$setStringsAsFactors(TRUE)
df2$c <- as.factor(df2$c) # Now that js$setStringsAsFactors(TRUE), both character vectors will come back as factors.
df2$d <- as.factor(df2$d)
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(TRUE)
df2$c <- TRUE
testSetAndGet(list(df), list(df2))

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)


# Data Frames - n Rows - Column Major -------------------------------------

cat("Data Frames - n Rows - Column Major\n")

js$setDataFrameRowMajor(FALSE)
js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)

df <- data.frame(names = row.names(mtcars), mtcars, stringsAsFactors = FALSE)
row.names(df) <- NULL
testSetAndGet(list(df))

# Data frame with all supported data types and constants. Each column has 20 elements
df <- data.frame(
  a = c(as.numeric(-1:15), .Machine$double.xmin, .Machine$double.xmax, pi)
  , b = rep(c(NA, NaN, Inf, -Inf), times = 5)
  , c = c(-1:16, .Machine$integer.max, NA)
  , d = c(letters[1:17], "", " ", NA)
  , e = c(rep(c(TRUE, FALSE), times = 9), NA, NA)
  , f = as.raw(236:255)
  , stringsAsFactors = FALSE
)
df2 <- df
df2$e <- c(rep(c(TRUE, FALSE), times = 9), FALSE, FALSE)
suppressWarnings(testSetAndGet(list(df), list(df2)))

assertIdentical("java.util.LinkedHashMap", js$getJavaClassName("value"))
js %@% "var a = value.a;"
assertIdentical("[D", js$getJavaClassName("a"))

df$g <- as.factor(df$b)
df$h <- as.factor(df$c)
df$i <- as.factor(df$e)
df2$g <- as.character(df$b)
df2$h <- as.character(df$c)
df2$i <- as.character(df$e)
suppressWarnings(testSetAndGet(list(df), list(df2)))
js$setCoerceFactors(TRUE)
df2$g <- df2$b
df2$h <- df2$c
df2$i <- df2$e
suppressWarnings(testSetAndGet(list(df), list(df2)))
js$setStringsAsFactors(TRUE)
df2$d <- as.factor(df2$d)
suppressWarnings(testSetAndGet(list(df), list(df2)))
js$setCoerceFactors(FALSE)
df2$g <- as.factor(df$b)
df2$h <- as.factor(as.character(df$c))
df2$i <- as.factor(df$e)
suppressWarnings(testSetAndGet(list(df), list(df2)))

# If one or more of the arrays are not the same length, a list should be
# returned instead of a data frame.
js$setStringsAsFactors(FALSE); js$setCoerceFactors(FALSE)
df <- as.data.frame(names = row.names(mtcars), mtcars, stringsAsFactors = FALSE)
row.names(df) <- NULL
js$value <- df
js %@% "
  var integerArrayClass = Java.type('int[]');
  var myArray = new integerArrayClass(5);
  for (i = 0; i < myArray.length; i++) {
    myArray[i] = i;
  }
  value.put('x', myArray);
"
assertIdentical("list", class(js$value))

js %@% "
  var myArray = new integerArrayClass(value.values().toArray()[0].length);
  for (i = 0; i < myArray.length; i++) {
    myArray[i] = i;
  }
  value.put('x', myArray);
"
assertIdentical("data.frame", class(js$value))
df[["x"]] <- 0:(length(df[[1]]) - 1)
assertIdentical(js$value, df)

# A mix of numeric, integer, and raw in the same column is allowed. The most
# general type will be used. This named list of unnamed lists will be converted
# to a Java Map containing collections. On the way back to R, this structure
# is converted to a data frame.
js$setStringsAsFactors(FALSE); js$setCoerceFactors(FALSE)
l1 <- list(
  a = list(1.1, 1L, as.raw(255))
  , b = list(1.1, as.raw(255), 1L)
  , c = list(1L, 1.1, as.raw(255))
  , d = list(1L, as.raw(255), 1.1)
  , e = list(as.raw(255), 1.1, 1L)
  , f = list(as.raw(255), 1L, 1.1)
)
df <- data.frame(
  a = c(1.1, 1, -1)
  , b = c(1.1, -1, 1)
  , c = c(1, 1.1, -1)
  , d = c(1, -1, 1.1)
  , e = c(-1, 1.1, 1)
  , f = c(-1, 1, 1.1)
)
testSetAndGet(list(l1), list(df))
l1 <- list(
  a = list(1L, as.raw(255))
  , b = list(as.raw(255), 1L)
)
df <- data.frame(
  a = c(1L, -1L)
  , b = c(-1L, 1L)
)
testSetAndGet(list(l1), list(df))

# Create a column-major data frame from a JS object.
js %@% "var value = {'a':[1, 2, 3], 'b':['a', 'b', 'c']};"
assertIdentical(js$value, data.frame(a = 1:3, b = c("a", "b", "c"), stringsAsFactors = FALSE))

# Test large data structure.
js$setStringsAsFactors(FALSE); js$setCoerceFactors(FALSE)
k <- as.data.frame(names = row.names(mtcars), mtcars, stringsAsFactors = FALSE)
row.names(k) <- NULL
while (nrow(k) < 1000000) {
  k <- rbind(k, k)
}
js$value <- k
assertIdentical(k, js$value)

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)

# Data Frames - n Rows - Row Major ----------------------------------------

cat("Data Frames - n Rows - Row Major\n")

js$setDataFrameRowMajor(TRUE)
js$setCoerceFactors(FALSE); js$setStringsAsFactors(FALSE)

df <- data.frame(names = row.names(mtcars), mtcars, stringsAsFactors = FALSE)
row.names(df) <- NULL
testSetAndGet(list(df))

# Data frame with all supported data types and constants. Each column has 20 elements
df <- data.frame(
  a = c(as.numeric(-1:15), .Machine$double.xmin, .Machine$double.xmax, pi)
  , b = rep(c(NA, NaN, Inf, -Inf), times = 5)
  , c = c(-1:16, .Machine$integer.max, NA)
  , d = c(letters[1:17], "", " ", NA)
  , e = c(rep(c(TRUE, FALSE), times = 9), NA, NA)
  , f = as.raw(236:255)
  , stringsAsFactors = FALSE
)
df2 <- df
df2$e <- c(rep(c(TRUE, FALSE), times = 9), FALSE, FALSE)
suppressWarnings(testSetAndGet(list(df), list(df2)))

assertIdentical("java.util.ArrayList", js$getJavaClassName("value"))
js %@% "var a = value[0];"
assertIdentical("java.util.LinkedHashMap", js$getJavaClassName("a"))

df$g <- as.factor(df$b)
df$h <- as.factor(df$c)
df$i <- as.factor(df$e)
df2$g <- as.character(df$b)
df2$h <- as.character(df$c)
df2$i <- as.character(df$e)
suppressWarnings(testSetAndGet(list(df), list(df2)))
js$setCoerceFactors(TRUE)
df2$g <- df2$b
df2$h <- df2$c
df2$i <- df2$e
suppressWarnings(testSetAndGet(list(df), list(df2)))
js$setStringsAsFactors(TRUE)
df2$d <- as.factor(df2$d)
suppressWarnings(testSetAndGet(list(df), list(df2)))
js$setCoerceFactors(FALSE)
df2$g <- as.factor(df$b)
df2$h <- as.factor(as.character(df$c))
df2$i <- as.factor(df$e)
suppressWarnings(testSetAndGet(list(df), list(df2)))

# If one or more of the row objects are not the same length, a list should be
# returned instead of a data frame.
js$setStringsAsFactors(FALSE); js$setCoerceFactors(FALSE)
df <- as.data.frame(names = row.names(mtcars), mtcars, stringsAsFactors = FALSE)
row.names(df) <- NULL
js$value <- df
js %~% "value[3].remove('carb');"
assertIdentical("list", class(js$value))

# rJava converts NA_character_ to Java null. This presents challenges in the
# row-major setting because null has no type/class in Java. Each row's values
# are scalars, not arrays. The best we can do is convert all null values to
# NA_character_. These tests are designed explicitly for correctly converting
# null values to character columns for data frames in the row-major setting.
df <- data.frame(
  a = c(NA_character_, NA_character_)
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df))
df <- data.frame(
  a = c("a", NA_character_)
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df))
df <- data.frame(
  a = c(NA_character_, "a")
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df))
df <- data.frame(
  a = c(NA_character_, NA_character_)
  , b = c("a", NA_character_)
  , c = c(NA_character_, "a")
  , stringsAsFactors = FALSE
)
testSetAndGet(list(df))

# Test mixture of types in the same row-major columns.
#
# In this case, all columns should be converted to numeric.
l1 <- list(
  list(a = 1.1, b = 1.1, c = 1L, d = 1L, e = as.raw(255), f = as.raw(255))
  , list(a = 1L, b = as.raw(255), c = 1.1, d = as.raw(255), e = 1.1, f = 1L)
  , list(a = as.raw(255), b = 1L, c = as.raw(255), d = 1.1, e = 1L, f = 1.1)
)
df <- data.frame(
  a = c(1.1, 1, -1)
  , b = c(1.1, -1, 1)
  , c = c(1, 1.1, -1)
  , d = c(1, -1, 1.1)
  , e = c(-1, 1.1, 1)
  , f = c(-1, 1, 1.1)
)
testSetAndGet(list(l1), list(df))

# In this case, all columns should be converted to integer.
l1 <- list(
  list(a = 1L, b = as.raw(255))
  , list(a = as.raw(255), b = 1L)
)
df <- data.frame(
  a = c(1L, -1L)
  , b = c(-1L, 1L)
)
testSetAndGet(list(l1), list(df))

# Create a row-major data frame from a JS object.
js$setStringsAsFactors(FALSE); js$setCoerceFactors(FALSE)
js %@% "
  var row = {'a':1, 'b':'string', 'c':Math.PI};
  var value = [row, row, row]; // your boat...
"
assertIdentical(js$value, data.frame(a = rep(1L, 3), b = rep("string", 3), c = rep(pi, 3), stringsAsFactors = FALSE))
js %@% "
  var ObjectArray1D = Java.type('java.lang.Object[]');
  var value = new ObjectArray1D(3);
  value[0] = row;
  value[1] = row;
  value[2] = row;
"
assertIdentical(js$value, data.frame(a = rep(1L, 3), b = rep("string", 3), c = rep(pi, 3), stringsAsFactors = FALSE))

# Test large data structure. Use fewer rows than in column-major test because
# row-major is much slower. #///note this in documentation
js$setStringsAsFactors(FALSE); js$setCoerceFactors(FALSE)
k <- as.data.frame(names = row.names(mtcars), mtcars, stringsAsFactors = FALSE)
row.names(k) <- NULL
while (nrow(k) < 100000) {
  k <- rbind(k, k)
}
js$value <- k
assertIdentical(k, js$value)

js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)


# Lists - Empty and Empty Values ------------------------------------------

cat("Lists - Empty and Empty Values\n")
testSetAndGet(list(new.env()), list(list()))
testSetAndGet(list(list()))
testSetAndGet(list(list(integer())), list(array(0L, c(1, 0))))
testSetAndGet(list(list(a = integer())))

l1 <- list(
  numeric()
  , integer()
  , logical()
  , character()
  , raw()
)
testSetAndGet(list(l1))

# Named lists of same-sized vectors will be returned as data frames.
l1 <- list(
  a = numeric()
  , b = integer()
  , c = logical()
  , d = character()
  , e = raw()
)
js$setStringsAsFactors(FALSE)
testSetAndGet(list(l1), list(as.data.frame(l1, stringsAsFactors = FALSE)))
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)

# Lists of lists and data frames
l1 <- list(
  list(
    list()
  )
)
testSetAndGet(list(l1))

l1 <- list(
  list(
    list(
      list()
    )
  )
)
testSetAndGet(list(l1))

l1 <- list(
  a = list()
)
testSetAndGet(list(l1))

l1 <- list(
  a = list(
    list()
  )
)
testSetAndGet(list(l1))

l1 <- list(
  a = list(
    list(
      list(
        a = list()
      )
    )
  )
)
testSetAndGet(list(l1))

l1 <- list(
  a = list(
    a = list(
      a = list(
        a = list()
      )
    )
  )
)
testSetAndGet(list(l1))

l1 <- list(
  a = list(
    list(
      list(a = list(a = list(list(list()))))
    )
  )
)
testSetAndGet(list(l1))

l1 <- list(
  a = data.frame()
)
js$setDataFrameRowMajor(FALSE)
testSetAndGet(list(l1), list(list(a = list())))
js$setDataFrameRowMajor(TRUE)
testSetAndGet(list(l1), list(list(a = list())))
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

# An empty Java Map object is converted to an empty list.
js %@% "var value = new java.util.LinkedHashMap();"
assertIdentical(list(), js$value)

# Lists -------------------------------------------------------------------

cat("Lists\n")

l1 <- list(
  list(NULL)
  , list(NULL, NULL, NULL)
)
testSetAndGet(l1)

l1 <- list(a = 1L)
testSetAndGet(list(l1))
names(l1) <- ""
testSetAndGet(list(l1))

l1 <- list(a = 1L, a = 1.1)
assertMessage(
  {
    testSetAndGet(list(l1))
  }
  , "Data frames and named lists are required to have unique names for each column or member."
)

l1 <- list(
  a = NA_integer_
  , b = NA_real_
  , c = NA
  , d = NA_character_
)
l2 <- l1
l2$c <- FALSE
js$setLengthOneVectorAsArray(TRUE)
js$setStringsAsFactors(FALSE)
df <- as.data.frame(l2, stringsAsFactors = FALSE)
suppressWarnings(testSetAndGet(list(l1), list(df)))
suppressWarnings(testSetAndGet(list(list(l1)), list(list(as.data.frame(l2, stringsAsFactors = FALSE)))))
js$setLengthOneVectorAsArray(FALSE)
# We expect a NULL entry for 'd' on return. However, setting a list member to
# NULL removes it, by default. This code is a workaround.
l2$d <- NULL # Removes entry
l2[[5]] <- 1 # Will create l2[[4]] as a NULL value
l2[[5]] <- NULL # Removes temporary entry.
names(l2) <- names(l1)
suppressWarnings(testSetAndGet(list(l1), list(l2)))
l2$d <- NA_character_
suppressWarnings(testSetAndGet(list(list(l1)), list(as.data.frame(l2, stringsAsFactors = FALSE))))
js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)

# A named list with same-length vectors will come back as a data frame.
l1 <- list(
  a = c(1:20)
  , b = as.numeric(1:20)
  , c = rep(c(TRUE, FALSE), times = 10)
  , d = rep(c(NA, NaN, Inf, -Inf), times = 5)
  , e = letters[1:20]
  , f = as.raw(1:20)
)
js$setStringsAsFactors(FALSE)
testSetAndGet(list(l1), list(as.data.frame(l1, stringsAsFactors = FALSE)))
js$setStringsAsFactors(TRUE)
testSetAndGet(list(l1), list(as.data.frame(l1, stringsAsFactors = TRUE)))
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)

# If one or more of the arrays are not the same length, a list should be
# returned instead of a data frame.
js %@% "
var integerArrayClass = Java.type('int[]');
var myArray = new integerArrayClass(5);
for (i = 0; i < myArray.length; i++) {
  myArray[i] = i;
}
value.put('g', myArray);
"
l1$g <- 0:4
assertIdentical(l1, js$value)

l1$g <- 1+2i
assertMessage(
  {
    testSetAndGet(l1)
  }
  , "Values of class 'complex' are not supported."
)

# Factors in lists...
js$setCoerceFactors(TRUE)
f <- factor(letters)
testSetAndGet(list(list(f)), list(list(as.character(f))))
f <- factor(1:26)
testSetAndGet(list(list(f)), list(list(as.integer(f))))
f <- factor(c(1.2, Inf, -Inf))
testSetAndGet(list(list(f)), list(list(c(1.2, Inf, -Inf))))
js$setCoerceFactors(FALSE)
f <- factor(letters)
testSetAndGet(list(list(f)), list(list(as.character(f))))
f <- factor(1:26)
testSetAndGet(list(list(f)), list(list(as.character(f))))
f <- factor(c(1.2, Inf, -Inf))
testSetAndGet(list(list(f)), list(list(as.character(c(1.2, Inf, -Inf)))))
js$setCoerceFactors(FALSE)

# All supported R types/structures in a single list object
l1 <- list(
  factor(letters)

  , as.array(letters)

  , 2.1
  , 1L
  , "a"
  , TRUE
  , as.raw(255L)

  , c(-1.2, 0, 2.3)
  , -1:2
  , letters
  , c(TRUE, FALSE, TRUE)
  , as.raw(0:255)

  , matrix(-1.1:7.1, 3, 3)
  , matrix(-1:7, 3, 3)
  , matrix(letters[1:9], 3, 3)
  , matrix(c(TRUE, FALSE, TRUE), 3, 3)
  , matrix(integer(), 0, 0)
  , matrix(as.raw(0:255), 32, 8)

  , eval({v <- mtcars; row.names(v) <- NULL; v})

  , list()
  , list(a = list(), b = 2.1, c = TRUE, d = "a", e = list(letters, 1:10), f = as.raw(0:9))
  , list(1, 2.1, TRUE, "a", list(letters, 1:10))
)
l2 <- l1
l2[[1]] <- letters
l2[[2]] <- letters
js$setCoerceFactors(FALSE)
# Critical to test row-major/column-major setting in list context.
js$setDataFrameRowMajor(TRUE)
testSetAndGet(list(l1), list(l2))
js$setDataFrameRowMajor(FALSE)
testSetAndGet(list(l1), list(l2))
# Convert to named list and test again.
names(l1) <- letters[1:length(l1)]
names(l2) <- letters[1:length(l1)]
js$setDataFrameRowMajor(TRUE)
testSetAndGet(list(l1), list(l2))
js$setDataFrameRowMajor(FALSE)
testSetAndGet(list(l1), list(l2))
testSetAndGet(list(l1), list(l2))
js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

# Critical to test StringsAsFactors setting in list context.
l1 <- list({v <- mtcars; row.names(v) <- NULL; data.frame(names = row.names(mtcars), v, stringsAsFactors = FALSE)})
js$setStringsAsFactors(FALSE)
testSetAndGet(l1)
l1 <- list(a = l1)
testSetAndGet(l1)
l1 <- list({v <- mtcars; row.names(v) <- NULL; data.frame(names = row.names(mtcars), v, stringsAsFactors = TRUE)})
js$setStringsAsFactors(TRUE)
testSetAndGet(l1)
l1 <- list(a = l1)
testSetAndGet(l1)

# Mix of named and unnamed lists.
l1 <- list(list(list()))
testSetAndGet(list(l1))
l1 <- list(a = list(list(list(a = list()))))
testSetAndGet(list(l1))
# Remember that list(list(a = 1, b = 2)) will come back as a data frame,
# so use list(list(a = c(1, 2), b = 2)) to test instead.
l1 <- list(list(a = list(list(list(a = c(1, 2), b = 1), list()))))
testSetAndGet(list(l1))
l1 <- list(list(a = list(list(a = list(a = c(1, 2), b = 1), b = list()))))
testSetAndGet(list(l1))


# Lists from Collections --------------------------------------------------

cat("Lists from Collections\n")

js %@% "var value = []"
assertIdentical(list(), js$value)

js %@% "var value = [[]]"
assertIdentical(list(list()), js$value)

js %@% "var value = [[], []]"
assertIdentical(list(list(), list()), js$value)

js %@% "var value = [[[]], []]"
assertIdentical(list(list(list()), list()), js$value)

js %@% "
var value = [
  1
  , [1, 2]
  , ['a', true, []]
  , [[1, 3], [2, 4]]
]
"
v <- list(1L, c(1L, 2L), list("a", TRUE, list()), matrix(1:4, 2, 2))
assertIdentical(v, js$value)

js %@% "var value = [1, [1, 2], ['a', 'b', []]]"
v <- list(1L, c(1L, 2L), list("a", "b", list()))
assertIdentical(v, js$value)

js %@% "var value = [NaN, Infinity, -Infinity, true, false, null, undefined]"
assertIdentical(list(NaN, Inf, -Inf, TRUE, FALSE, NULL, NULL), js$value)

# Named, nested list from JavaScript object.
js %@% "var value = {'a':1, 'b':{'c':'abc', 'd':null}}"
assertIdentical(js$value, list(a = 1L, b = list(c = "abc", d = NULL)))


# Java Types --------------------------------------------------------------

cat("Java Types\n")
js$setCoerceFactors(jsr223:::DEFAULT_COERCE_FACTORS)
js$setLengthOneVectorAsArray(jsr223:::DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY)
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)
js$setStringsAsFactors(jsr223:::DEFAULT_STRINGS_AS_FACTORS)

cat("Java Errors\n")
assertMessage(
  {
    js %~% "new java.math.BigDecimal(java.lang.Double.longBitsToDouble(0x7ff00000000007a2));"
  }
  , "java.lang.NumberFormatException: Infinite or NaN"
)

cat("Java Types - Constants\n")
testJavaToR("getInfinityNegative", -Inf)
testJavaToR("getInfinityPositive", Inf)
testJavaToR("getNaN", NaN)
testJavaToR("getNull", NULL)
testJavaToR("getBooleanMin", FALSE)
testJavaToR("getBooleanMax", TRUE)

cat("Java Types - Scalars\n")
testJavaToR("getByteMin", BYTE_MIN)
testJavaToR("getByteMax", BYTE_MAX)
testJavaToR("getCharacterLow", "\u20", parameter = 0x20L)
# testJavaToR("getCharacterHigh", "\u00", parameter = 0x20L)
# testJavaToR("getCharacterMin", "\u0000")
# testJavaToR("getCharacterMax", "\uFFFF")
testJavaToR("getDoubleMin", DOUBLE_MIN)
testJavaToR("getDoubleMax", DOUBLE_MAX)
testJavaToR("getFloatMin", FLOAT_MIN, identical = FALSE)
testJavaToR("getFloatMax", FLOAT_MAX, identical = FALSE)
testJavaToR("getIntMin", INTEGER_MIN)
testJavaToR("getIntMax", INTEGER_MAX)
testJavaToR("getLongMin", LONG_MIN)
testJavaToR("getLongMax", LONG_MAX)
testJavaToR("getShortMin", SHORT_MIN)
testJavaToR("getShortMax", SHORT_MAX)

cat("Java Types - Boxed Scalars\n")
testJavaToR("getBigDecimalLarge", Inf)
testJavaToR("getBigDecimalSmall", -Inf)
testJavaToR("getBigDecimalTen", 10)
testJavaToR("getBigDecimalZero", 0)
testJavaToR("getBigIntegerLarge", Inf)
testJavaToR("getBigIntegerSmall", -Inf)
testJavaToR("getBigIntegerTen", 10)
testJavaToR("getBigIntegerZero", 0)
testJavaToR("getBoxedBooleanMin", FALSE)
testJavaToR("getBoxedBooleanMax", TRUE)
testJavaToR("getBoxedByteMin", BYTE_MIN)
testJavaToR("getBoxedByteMax", BYTE_MAX)
testJavaToR("getBoxedCharacterLow", "\u20", parameter = 0x20L)
# testJavaToR("getBoxedCharacterHigh", "\u00", parameter = 0x20L)
# testJavaToR("getBoxedCharacterMin", "\u0000")
# testJavaToR("getBoxedCharacterMax", "\uFFFF")
testJavaToR("getBoxedDoubleMin", DOUBLE_MIN)
testJavaToR("getBoxedDoubleMax", DOUBLE_MAX)
testJavaToR("getBoxedFloatMin", FLOAT_MIN, identical = FALSE)
testJavaToR("getBoxedFloatMax", FLOAT_MAX, identical = FALSE)
testJavaToR("getBoxedIntegerMin", INTEGER_MIN)
testJavaToR("getBoxedIntegerMax", INTEGER_MAX)
testJavaToR("getBoxedLongMin", LONG_MIN)
testJavaToR("getBoxedLongMax", LONG_MAX)
testJavaToR("getBoxedShortMin", SHORT_MIN)
testJavaToR("getBoxedShortMax", SHORT_MAX)
testJavaToR("getStringAlphabetLower", "abcdefghijklmnopqrstuvwxyz")
testJavaToR("getStringEmpty", "")

cat("Java Types - Primitive 1D Arrays\n")
testJavaToR("getBooleanArray1d0x0", logical())
testJavaToR("getBooleanArray1d1x1", TRUE)
testJavaToR("getBooleanArray1d1x2", c(FALSE, TRUE))
testJavaToR("getByteArray1d0x0", raw())
testJavaToR("getByteArray1d1x1", as.raw(0x80L))
testJavaToR("getByteArray1dLowZeroHigh", as.raw(c(0x80L, 0x00L, 0x7FL)))
testJavaToR("getCharacterArray1d0x0", character())
testJavaToR("getCharacterArray1d1x1", "1")
testJavaToR("getCharacterArray1d1x3", c("1", "2", "3"))
testJavaToR("getDoubleArray1d0x0", numeric())
testJavaToR("getDoubleArray1d1x1", DOUBLE_MIN)
testJavaToR("getDoubleArray1dLowZeroHigh", c(DOUBLE_MIN, 0, DOUBLE_MAX))
testJavaToR("getFloatArray1d0x0", numeric())
testJavaToR("getFloatArray1d1x1", FLOAT_MIN, identical = FALSE)
testJavaToR("getFloatArray1dLowZeroHigh", c(FLOAT_MIN, 0, FLOAT_MAX), identical = FALSE)
testJavaToR("getIntArray1d0x0", integer())
testJavaToR("getIntArray1d1x1", INTEGER_MIN)
testJavaToR("getIntArray1dLowZeroHigh", c(INTEGER_MIN, 0L, INTEGER_MAX))
testJavaToR("getLongArray1d0x0", numeric())
testJavaToR("getLongArray1d1x1", LONG_MIN)
testJavaToR("getLongArray1dLowZeroHigh", c(LONG_MIN, 0, LONG_MAX))
testJavaToR("getShortArray1d0x0", integer())
testJavaToR("getShortArray1d1x1", SHORT_MIN)
testJavaToR("getShortArray1dLowZeroHigh", c(SHORT_MIN, 0L, SHORT_MAX))

cat("Java Types - Boxed 1D Arrays\n")
testJavaToR("getBigDecimalArray1d0x0", numeric())
testJavaToR("getBigDecimalArray1d1x1", 1)
testJavaToR("getBigDecimalArray1d1x2", c(DOUBLE_MIN, DOUBLE_MAX))
testJavaToR("getBigDecimalArray1dNulls", c(NA_real_, -1, NA_real_, 1, NA_real_))
testJavaToR("getBigIntegerArray1d0x0", numeric())
testJavaToR("getBigIntegerArray1d1x1", 1)
testJavaToR("getBigIntegerArray1d1x2", c(LONG_MIN, LONG_MAX))
testJavaToR("getBigIntegerArray1dNulls", c(NA_real_, -1, NA_real_, 1, NA_real_))
testJavaToR("getBoxedBooleanArray1d0x0", logical())
testJavaToR("getBoxedBooleanArray1d1x1", TRUE)
testJavaToR("getBoxedBooleanArray1d1x2", c(FALSE, TRUE))
suppressWarnings(
  testJavaToR("getBoxedBooleanArray1dNulls", c(TRUE, FALSE, TRUE, TRUE, TRUE))
)
testJavaToR("getBoxedByteArray1d0x0", raw())
testJavaToR("getBoxedByteArray1d1x1", as.raw(0x80L))
testJavaToR("getBoxedByteArray1dLowZeroHigh", as.raw(c(0x80L, 0x00L, 0x7FL)))
suppressWarnings(
  testJavaToR("getBoxedByteArray1dNulls", as.raw(c(0x00L, 0x80L, 0x00L, 0x7FL, 0x00L)))
)
testJavaToR("getBoxedCharacterArray1d0x0", character())
testJavaToR("getBoxedCharacterArray1d1x1", "1")
testJavaToR("getBoxedCharacterArray1d1x3", c("1", "2", "3"))
testJavaToR("getBoxedCharacterArray1dNulls", c(NA_character_, "1", NA_character_, "3", NA_character_))
testJavaToR("getBoxedDoubleArray1d0x0", numeric())
testJavaToR("getBoxedDoubleArray1d1x1", DOUBLE_MIN)
testJavaToR("getBoxedDoubleArray1dLowZeroHigh", c(DOUBLE_MIN, 0, DOUBLE_MAX))
testJavaToR("getBoxedDoubleArray1dNulls", c(NA_real_, DOUBLE_MIN, NA_real_, DOUBLE_MAX, NA_real_))
testJavaToR("getBoxedFloatArray1d0x0", numeric())
testJavaToR("getBoxedFloatArray1d1x1", FLOAT_MIN, identical = FALSE)
testJavaToR("getBoxedFloatArray1dLowZeroHigh", c(FLOAT_MIN, 0, FLOAT_MAX), identical = FALSE)
testJavaToR("getBoxedFloatArray1dNulls", c(NA_real_, FLOAT_MIN, NA_real_, FLOAT_MAX, NA_real_), identical = FALSE)
testJavaToR("getBoxedIntegerArray1d0x0", integer())
testJavaToR("getBoxedIntegerArray1d1x1", INTEGER_MIN)
testJavaToR("getBoxedIntegerArray1dLowZeroHigh", c(INTEGER_MIN, 0L, INTEGER_MAX))
testJavaToR("getBoxedIntegerArray1dNulls", c(NA_integer_, INTEGER_MIN, NA_integer_, INTEGER_MAX, NA_integer_))
testJavaToR("getBoxedLongArray1d0x0", numeric())
testJavaToR("getBoxedLongArray1d1x1", LONG_MIN)
testJavaToR("getBoxedLongArray1dLowZeroHigh", c(LONG_MIN, 0, LONG_MAX))
testJavaToR("getBoxedLongArray1dNulls", c(NA_real_, LONG_MIN, NA_real_, LONG_MAX, NA_real_))
testJavaToR("getBoxedShortArray1d0x0", integer())
testJavaToR("getBoxedShortArray1d1x1", SHORT_MIN)
testJavaToR("getBoxedShortArray1dLowZeroHigh", c(SHORT_MIN, 0L, SHORT_MAX))
testJavaToR("getBoxedShortArray1dNulls", c(NA_integer_, SHORT_MIN, NA_integer_, SHORT_MAX, NA_integer_))
testJavaToR("getStringArray1d0x0", character())
testJavaToR("getStringArray1d1x1", "A")
testJavaToR("getStringArray1dAlphabetLower", letters)
testJavaToR("getStringArray1dNulls", c(NA_character_, "b", NA_character_, "d", NA_character_))

cat("Java Types - Primitive 2D Arrays - Column Major\n")
js$setDataFrameRowMajor(FALSE)
testJavaToR("getBooleanArray2d0x0", matrix(TRUE, 0, 0))
testJavaToR("getBooleanArray2d2x0", matrix(TRUE, 0, 2))
testJavaToR("getBooleanArray2d2x1", matrix(c(FALSE, TRUE), 1, 2))
testJavaToR("getBooleanArray2d2x2", matrix(c(FALSE, TRUE, TRUE, FALSE), 2, 2, byrow = TRUE))
testJavaToR("getBooleanArray2dRagged1", list(logical(), c(TRUE, FALSE), logical(), FALSE, TRUE, logical()))
testJavaToR("getBooleanArray2dRagged2", list(c(TRUE, FALSE), logical(), FALSE, TRUE))
testJavaToR("getByteArray2d0x0", matrix(as.raw(0), 0, 0))
testJavaToR("getByteArray2d2x0", matrix(as.raw(0), 0, 2))
testJavaToR("getByteArray2d2x1", matrix(c(BYTE_MIN, BYTE_MAX), 1, 2))
testJavaToR("getByteArray2d2x2", matrix(as.raw(c(BYTE_MIN, 0xff, 0, BYTE_MAX)), 2, 2, byrow = FALSE))
testJavaToR("getByteArray2dRagged1", list(raw(), as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL)), raw()))
testJavaToR("getByteArray2dRagged2", list(as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL))))
testJavaToR("getCharacterArray2d0x0", matrix("", 0, 0))
testJavaToR("getCharacterArray2d2x0", matrix("", 0, 2))
testJavaToR("getCharacterArray2d2x1", matrix(c("1", "2"), 1, 2))
testJavaToR("getCharacterArray2d2x2", matrix(c("1", "2", "3", "4"), 2, 2, byrow = FALSE))
testJavaToR("getCharacterArray2dRagged1", list(character(), "1", character(), c("2", "3"), character()))
testJavaToR("getCharacterArray2dRagged2", list("1", character(), c("2", "3")))
testJavaToR("getDoubleArray2d0x0", matrix(0, 0, 0))
testJavaToR("getDoubleArray2d2x0", matrix(0, 0, 2))
testJavaToR("getDoubleArray2d2x1", matrix(c(DOUBLE_MIN, DOUBLE_MAX), 1, 2))
testJavaToR("getDoubleArray2d2x2", matrix(c(DOUBLE_MIN, -1, 0, DOUBLE_MAX), 2, 2, byrow = FALSE))
testJavaToR("getDoubleArray2dRagged1", list(numeric(), DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX), numeric()))
testJavaToR("getDoubleArray2dRagged2", list(DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX)))
testJavaToR("getFloatArray2d0x0", matrix(0, 0, 0))
testJavaToR("getFloatArray2d2x0", matrix(0, 0, 2))
testJavaToR("getFloatArray2d2x1", matrix(c(FLOAT_MIN, FLOAT_MAX), 1, 2), identical = FALSE)
testJavaToR("getFloatArray2d2x2", matrix(c(FLOAT_MIN, -1, 0, FLOAT_MAX), 2, 2, byrow = FALSE), identical = FALSE)
testJavaToR("getFloatArray2dRagged1", list(numeric(), FLOAT_MIN, numeric(), c(0, FLOAT_MAX), numeric()), identical = FALSE)
testJavaToR("getFloatArray2dRagged2", list(FLOAT_MIN, numeric(), c(0, FLOAT_MAX)), identical = FALSE)
testJavaToR("getIntArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getIntArray2d2x0", matrix(0L, 0, 2))
testJavaToR("getIntArray2d2x1", matrix(c(INTEGER_MIN, INTEGER_MAX), 1, 2))
testJavaToR("getIntArray2d2x2", matrix(c(INTEGER_MIN, -1L, 0L, INTEGER_MAX), 2, 2, byrow = FALSE))
testJavaToR("getIntArray2dRagged1", list(integer(), INTEGER_MIN, integer(), c(0L, INTEGER_MAX), integer()))
testJavaToR("getIntArray2dRagged2", list(INTEGER_MIN, integer(), c(0L, INTEGER_MAX)))
testJavaToR("getLongArray2d0x0", matrix(0, 0, 0))
testJavaToR("getLongArray2d2x0", matrix(0, 0, 2))
testJavaToR("getLongArray2d2x1", matrix(c(LONG_MIN, LONG_MAX), 1, 2))
testJavaToR("getLongArray2d2x2", matrix(c(LONG_MIN, -1, 0, LONG_MAX), 2, 2, byrow = FALSE))
testJavaToR("getLongArray2dRagged1", list(numeric(), LONG_MIN, numeric(), c(0, LONG_MAX), numeric()))
testJavaToR("getLongArray2dRagged2", list(LONG_MIN, numeric(), c(0, LONG_MAX)))
testJavaToR("getShortArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getShortArray2d2x0", matrix(0L, 0, 2))
testJavaToR("getShortArray2d2x1", matrix(c(SHORT_MIN, SHORT_MAX), 1, 2))
testJavaToR("getShortArray2d2x2", matrix(c(SHORT_MIN, -1L, 0L, SHORT_MAX), 2, 2, byrow = FALSE))
testJavaToR("getShortArray2dRagged1", list(integer(), SHORT_MIN, integer(), c(0L, SHORT_MAX), integer()))
testJavaToR("getShortArray2dRagged2", list(SHORT_MIN, integer(), c(0L, SHORT_MAX)))
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

cat("Java Types - Boxed 2D Arrays - Column Major\n")
js$setDataFrameRowMajor(FALSE)
testJavaToR("getBigDecimalArray2d0x0", matrix(numeric(), 0, 0))
testJavaToR("getBigDecimalArray2d2x0", matrix(numeric(), 0, 2))
testJavaToR("getBigDecimalArray2d2x1", matrix(c(DOUBLE_MIN, DOUBLE_MAX), 1, 2))
testJavaToR("getBigDecimalArray2d2x2", matrix(c(0, 10, DOUBLE_MIN, DOUBLE_MAX), 2, 2, byrow = FALSE))
testJavaToR("getBigDecimalArray2dNulls", matrix(c(NA_real_, 0, NA_real_, 1, NA_real_, 10), 3, 2))
testJavaToR("getBigDecimalArray2dRagged1", list(numeric(), c(0, 1), numeric(), 10, 1, numeric()))
testJavaToR("getBigDecimalArray2dRagged2", list(c(0, 1), numeric(), 10, 0))
testJavaToR("getBigIntegerArray2d0x0", matrix(numeric(), 0, 0))
testJavaToR("getBigIntegerArray2d2x0", matrix(numeric(), 0, 2))
testJavaToR("getBigIntegerArray2d2x1", matrix(c(LONG_MIN, LONG_MAX), 1, 2))
testJavaToR("getBigIntegerArray2d2x2", matrix(c(0, 10, LONG_MIN, LONG_MAX), 2, 2, byrow = FALSE))
testJavaToR("getBigIntegerArray2dNulls", matrix(c(NA_real_, 0, NA_real_, 1, NA_real_, 10), 3, 2))
testJavaToR("getBigIntegerArray2dRagged1", list(numeric(), c(0, 1), numeric(), 10, 1, numeric()))
testJavaToR("getBigIntegerArray2dRagged2", list(c(0, 1), numeric(), 10, 0))
testJavaToR("getBoxedBooleanArray2d0x0", matrix(TRUE, 0, 0))
testJavaToR("getBoxedBooleanArray2d2x0", matrix(TRUE, 0, 2))
testJavaToR("getBoxedBooleanArray2d2x1", matrix(c(FALSE, TRUE),1, 2))
testJavaToR("getBoxedBooleanArray2d2x2", matrix(c(FALSE, TRUE, TRUE, FALSE), 2, 2, byrow = FALSE))
suppressWarnings(
  testJavaToR("getBoxedBooleanArray2dNulls", matrix(c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE), 3, 2))
)
testJavaToR("getBoxedBooleanArray2dRagged1", list(logical(), c(TRUE, FALSE), logical(), FALSE, TRUE, logical()))
testJavaToR("getBoxedBooleanArray2dRagged2", list(c(TRUE, FALSE), logical(), FALSE, TRUE))
testJavaToR("getBoxedByteArray2d0x0", matrix(as.raw(0), 0, 0))
testJavaToR("getBoxedByteArray2d2x0", matrix(as.raw(0), 0, 2))
testJavaToR("getBoxedByteArray2d2x1", matrix(c(BYTE_MIN, BYTE_MAX), 1, 2))
testJavaToR("getBoxedByteArray2d2x2", matrix(as.raw(c(BYTE_MIN, 0xff, 0, BYTE_MAX)), 2, 2, byrow = FALSE))
suppressWarnings(
  testJavaToR("getBoxedByteArray2dNulls", matrix(as.raw(c(0, BYTE_MIN, 0, BYTE_MIN, 0, BYTE_MAX)), 3, 2))
)
testJavaToR("getBoxedByteArray2dRagged1", list(raw(), as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL)), raw()))
testJavaToR("getBoxedByteArray2dRagged2", list(as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL))))
testJavaToR("getBoxedCharacterArray2d0x0", matrix("", 0, 0))
testJavaToR("getBoxedCharacterArray2d2x0", matrix("", 0, 2))
testJavaToR("getBoxedCharacterArray2d2x1", matrix(c("1", "2"), 1, 2))
testJavaToR("getBoxedCharacterArray2d2x2", matrix(c("1", "2", "3", "4"), 2, 2, byrow = FALSE))
testJavaToR("getBoxedCharacterArray2dNulls", matrix(c(NA_character_, "1", NA_character_, "2", NA_character_, "3"), 3, 2))
testJavaToR("getBoxedCharacterArray2dRagged1", list(character(), "1", character(), c("2", "3"), character()))
testJavaToR("getBoxedCharacterArray2dRagged2", list("1", character(), c("2", "3")))
testJavaToR("getBoxedDoubleArray2d0x0", matrix(0, 0, 0))
testJavaToR("getBoxedDoubleArray2d2x0", matrix(0, 0, 2))
testJavaToR("getBoxedDoubleArray2d2x1", matrix(c(DOUBLE_MIN, DOUBLE_MAX), 1, 2))
testJavaToR("getBoxedDoubleArray2d2x2", matrix(c(DOUBLE_MIN, -1, 0, DOUBLE_MAX), 2, 2, byrow = FALSE))
testJavaToR("getBoxedDoubleArray2dNulls", matrix(c(NA_real_, DOUBLE_MIN, NA_real_, DOUBLE_MIN, NA_real_, DOUBLE_MAX), 3, 2))
testJavaToR("getBoxedDoubleArray2dRagged1", list(numeric(), DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX), numeric()))
testJavaToR("getBoxedDoubleArray2dRagged2", list(DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX)))
testJavaToR("getBoxedFloatArray2d0x0", matrix(0, 0, 0))
testJavaToR("getBoxedFloatArray2d2x0", matrix(0, 0, 2))
testJavaToR("getBoxedFloatArray2d2x1", matrix(c(FLOAT_MIN, FLOAT_MAX), 1, 2), identical = FALSE)
testJavaToR("getBoxedFloatArray2d2x2", matrix(c(FLOAT_MIN, -1, 0, FLOAT_MAX), 2, 2, byrow = FALSE), identical = FALSE)
testJavaToR("getBoxedFloatArray2dNulls", matrix(c(NA_real_, FLOAT_MIN, NA_real_, FLOAT_MIN, NA_real_, FLOAT_MAX), 3, 2), identical = FALSE)
testJavaToR("getBoxedFloatArray2dRagged1", list(numeric(), FLOAT_MIN, numeric(), c(0, FLOAT_MAX), numeric()), identical = FALSE)
testJavaToR("getBoxedFloatArray2dRagged2", list(FLOAT_MIN, numeric(), c(0, FLOAT_MAX)), identical = FALSE)
testJavaToR("getBoxedIntegerArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getBoxedIntegerArray2d2x0", matrix(0L, 0, 2))
testJavaToR("getBoxedIntegerArray2d2x1", matrix(c(INTEGER_MIN, INTEGER_MAX), 1, 2))
testJavaToR("getBoxedIntegerArray2d2x2", matrix(c(INTEGER_MIN, -1L, 0L, INTEGER_MAX), 2, 2, byrow = FALSE))
testJavaToR("getBoxedIntegerArray2dNulls", matrix(c(NA_integer_, INTEGER_MIN, NA_integer_, INTEGER_MIN, NA_integer_, INTEGER_MAX), 3, 2))
testJavaToR("getBoxedIntegerArray2dRagged1", list(integer(), INTEGER_MIN, integer(), c(0L, INTEGER_MAX), integer()))
testJavaToR("getBoxedIntegerArray2dRagged2", list(INTEGER_MIN, integer(), c(0L, INTEGER_MAX)))
testJavaToR("getBoxedLongArray2d0x0", matrix(0, 0, 0))
testJavaToR("getBoxedLongArray2d2x0", matrix(0, 0, 2))
testJavaToR("getBoxedLongArray2d2x1", matrix(c(LONG_MIN, LONG_MAX), 1, 2))
testJavaToR("getBoxedLongArray2d2x2", matrix(c(LONG_MIN, -1, 0, LONG_MAX), 2, 2, byrow = FALSE))
testJavaToR("getBoxedLongArray2dNulls", matrix(c(NA_real_, LONG_MIN, NA_real_, LONG_MIN, NA_real_, LONG_MAX), 3, 2))
testJavaToR("getBoxedLongArray2dRagged1", list(numeric(), LONG_MIN, numeric(), c(0, LONG_MAX), numeric()))
testJavaToR("getBoxedLongArray2dRagged2", list(LONG_MIN, numeric(), c(0, LONG_MAX)))
testJavaToR("getBoxedShortArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getBoxedShortArray2d2x0", matrix(0L, 0, 2))
testJavaToR("getBoxedShortArray2d2x1", matrix(c(SHORT_MIN, SHORT_MAX), 1, 2))
testJavaToR("getBoxedShortArray2d2x2", matrix(c(SHORT_MIN, -1L, 0L, SHORT_MAX), 2, 2, byrow = FALSE))
testJavaToR("getBoxedShortArray2dNulls", matrix(c(NA_integer_, SHORT_MIN, NA_integer_, SHORT_MIN, NA_integer_, SHORT_MAX), 3, 2))
testJavaToR("getBoxedShortArray2dRagged1", list(integer(), SHORT_MIN, integer(), c(0L, SHORT_MAX), integer()))
testJavaToR("getBoxedShortArray2dRagged2", list(SHORT_MIN, integer(), c(0L, SHORT_MAX)))
testJavaToR("getStringArray2d0x0", matrix("", 0, 0))
testJavaToR("getStringArray2d2x0", matrix("", 0, 2))
testJavaToR("getStringArray2d2x1", matrix(c("", ""), 1, 2))
testJavaToR("getStringArray2d2x2", matrix(c("", " ", "a", "Z"), 2, 2, byrow = FALSE))
testJavaToR("getStringArray2dNulls", matrix(c(NA_character_, "", NA_character_, "a", NA_character_, "Z"), 3, 2))
testJavaToR("getStringArray2dRagged1", list(character(), "", character(), c("a", "Z"), character()))
testJavaToR("getStringArray2dRagged2", list("", character(), c("a", "Z")))
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

cat("Java Types - Primitive 2D Arrays - Row Major\n")
js$setDataFrameRowMajor(TRUE)
testJavaToR("getBooleanArray2d0x0", matrix(TRUE, 0, 0))
testJavaToR("getBooleanArray2d2x0", matrix(TRUE, 2, 0))
testJavaToR("getBooleanArray2d2x1", matrix(c(FALSE, TRUE)))
testJavaToR("getBooleanArray2d2x2", matrix(c(FALSE, TRUE, TRUE, FALSE), 2, 2, byrow = TRUE))
testJavaToR("getBooleanArray2dRagged1", list(logical(), c(TRUE, FALSE), logical(), FALSE, TRUE, logical()))
testJavaToR("getBooleanArray2dRagged2", list(c(TRUE, FALSE), logical(), FALSE, TRUE))
testJavaToR("getByteArray2d0x0", matrix(as.raw(0), 0, 0))
testJavaToR("getByteArray2d2x0", matrix(as.raw(0), 2, 0))
testJavaToR("getByteArray2d2x1", matrix(c(BYTE_MIN, BYTE_MAX)))
testJavaToR("getByteArray2d2x2", matrix(as.raw(c(BYTE_MIN, 0xff, 0, BYTE_MAX)), 2, 2, byrow = TRUE))
testJavaToR("getByteArray2dRagged1", list(raw(), as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL)), raw()))
testJavaToR("getByteArray2dRagged2", list(as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL))))
testJavaToR("getCharacterArray2d0x0", matrix("", 0, 0))
testJavaToR("getCharacterArray2d2x0", matrix("", 2, 0))
testJavaToR("getCharacterArray2d2x1", matrix(c("1", "2")))
testJavaToR("getCharacterArray2d2x2", matrix(c("1", "2", "3", "4"), 2, 2, byrow = TRUE))
testJavaToR("getCharacterArray2dRagged1", list(character(), "1", character(), c("2", "3"), character()))
testJavaToR("getCharacterArray2dRagged2", list("1", character(), c("2", "3")))
testJavaToR("getDoubleArray2d0x0", matrix(0, 0, 0))
testJavaToR("getDoubleArray2d2x0", matrix(0, 2, 0))
testJavaToR("getDoubleArray2d2x1", matrix(c(DOUBLE_MIN, DOUBLE_MAX)))
testJavaToR("getDoubleArray2d2x2", matrix(c(DOUBLE_MIN, -1, 0, DOUBLE_MAX), 2, 2, byrow = TRUE))
testJavaToR("getDoubleArray2dRagged1", list(numeric(), DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX), numeric()))
testJavaToR("getDoubleArray2dRagged2", list(DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX)))
testJavaToR("getFloatArray2d0x0", matrix(0, 0, 0))
testJavaToR("getFloatArray2d2x0", matrix(0, 2, 0))
testJavaToR("getFloatArray2d2x1", matrix(c(FLOAT_MIN, FLOAT_MAX)), identical = FALSE)
testJavaToR("getFloatArray2d2x2", matrix(c(FLOAT_MIN, -1, 0, FLOAT_MAX), 2, 2, byrow = TRUE), identical = FALSE)
testJavaToR("getFloatArray2dRagged1", list(numeric(), FLOAT_MIN, numeric(), c(0, FLOAT_MAX), numeric()), identical = FALSE)
testJavaToR("getFloatArray2dRagged2", list(FLOAT_MIN, numeric(), c(0, FLOAT_MAX)), identical = FALSE)
testJavaToR("getIntArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getIntArray2d2x0", matrix(0L, 2, 0))
testJavaToR("getIntArray2d2x1", matrix(c(INTEGER_MIN, INTEGER_MAX)))
testJavaToR("getIntArray2d2x2", matrix(c(INTEGER_MIN, -1L, 0L, INTEGER_MAX), 2, 2, byrow = TRUE))
testJavaToR("getIntArray2dRagged1", list(integer(), INTEGER_MIN, integer(), c(0L, INTEGER_MAX), integer()))
testJavaToR("getIntArray2dRagged2", list(INTEGER_MIN, integer(), c(0L, INTEGER_MAX)))
testJavaToR("getLongArray2d0x0", matrix(0, 0, 0))
testJavaToR("getLongArray2d2x0", matrix(0, 2, 0))
testJavaToR("getLongArray2d2x1", matrix(c(LONG_MIN, LONG_MAX)))
testJavaToR("getLongArray2d2x2", matrix(c(LONG_MIN, -1, 0, LONG_MAX), 2, 2, byrow = TRUE))
testJavaToR("getLongArray2dRagged1", list(numeric(), LONG_MIN, numeric(), c(0, LONG_MAX), numeric()))
testJavaToR("getLongArray2dRagged2", list(LONG_MIN, numeric(), c(0, LONG_MAX)))
testJavaToR("getShortArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getShortArray2d2x0", matrix(0L, 2, 0))
testJavaToR("getShortArray2d2x1", matrix(c(SHORT_MIN, SHORT_MAX)))
testJavaToR("getShortArray2d2x2", matrix(c(SHORT_MIN, -1L, 0L, SHORT_MAX), 2, 2, byrow = TRUE))
testJavaToR("getShortArray2dRagged1", list(integer(), SHORT_MIN, integer(), c(0L, SHORT_MAX), integer()))
testJavaToR("getShortArray2dRagged2", list(SHORT_MIN, integer(), c(0L, SHORT_MAX)))
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

cat("Java Types - Boxed 2D Arrays - Row Major\n")
js$setDataFrameRowMajor(TRUE)
testJavaToR("getBigDecimalArray2d0x0", matrix(numeric(), 0, 0))
testJavaToR("getBigDecimalArray2d2x0", matrix(numeric(), 2, 0))
testJavaToR("getBigDecimalArray2d2x1", matrix(c(DOUBLE_MIN, DOUBLE_MAX)))
testJavaToR("getBigDecimalArray2d2x2", matrix(c(0, 10, DOUBLE_MIN, DOUBLE_MAX), 2, 2, byrow = TRUE))
testJavaToR("getBigDecimalArray2dNulls", matrix(c(NA_real_, 0, NA_real_, 1, NA_real_, 10), 2, 3, byrow = TRUE))
testJavaToR("getBigDecimalArray2dRagged1", list(numeric(), c(0, 1), numeric(), 10, 1, numeric()))
testJavaToR("getBigDecimalArray2dRagged2", list(c(0, 1), numeric(), 10, 0))
testJavaToR("getBigIntegerArray2d0x0", matrix(numeric(), 0, 0))
testJavaToR("getBigIntegerArray2d2x0", matrix(numeric(), 2, 0))
testJavaToR("getBigIntegerArray2d2x1", matrix(c(LONG_MIN, LONG_MAX)))
testJavaToR("getBigIntegerArray2d2x2", matrix(c(0, 10, LONG_MIN, LONG_MAX), 2, 2, byrow = TRUE))
testJavaToR("getBigIntegerArray2dNulls", matrix(c(NA_real_, 0, NA_real_, 1, NA_real_, 10), 2, 3, byrow = TRUE))
testJavaToR("getBigIntegerArray2dRagged1", list(numeric(), c(0, 1), numeric(), 10, 1, numeric()))
testJavaToR("getBigIntegerArray2dRagged2", list(c(0, 1), numeric(), 10, 0))
testJavaToR("getBoxedBooleanArray2d0x0", matrix(TRUE, 0, 0))
testJavaToR("getBoxedBooleanArray2d2x0", matrix(TRUE, 2, 0))
testJavaToR("getBoxedBooleanArray2d2x1", matrix(c(FALSE, TRUE)))
testJavaToR("getBoxedBooleanArray2d2x2", matrix(c(FALSE, TRUE, TRUE, FALSE), 2, 2, byrow = TRUE))
suppressWarnings(
  testJavaToR("getBoxedBooleanArray2dNulls", matrix(c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE), 2, 3, byrow = TRUE))
)
testJavaToR("getBoxedBooleanArray2dRagged1", list(logical(), c(TRUE, FALSE), logical(), FALSE, TRUE, logical()))
testJavaToR("getBoxedBooleanArray2dRagged2", list(c(TRUE, FALSE), logical(), FALSE, TRUE))
testJavaToR("getBoxedByteArray2d0x0", matrix(as.raw(0), 0, 0))
testJavaToR("getBoxedByteArray2d2x0", matrix(as.raw(0), 2, 0))
testJavaToR("getBoxedByteArray2d2x1", matrix(c(BYTE_MIN, BYTE_MAX)))
testJavaToR("getBoxedByteArray2d2x2", matrix(as.raw(c(BYTE_MIN, 0xff, 0, BYTE_MAX)), 2, 2, byrow = TRUE))
suppressWarnings(
  testJavaToR("getBoxedByteArray2dNulls", matrix(as.raw(c(0, BYTE_MIN, 0, BYTE_MIN, 0, BYTE_MAX)), 2, 3, byrow = TRUE))
)
testJavaToR("getBoxedByteArray2dRagged1", list(raw(), as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL)), raw()))
testJavaToR("getBoxedByteArray2dRagged2", list(as.raw(0x80L), raw(), as.raw(c(0x00L, 0x7FL))))
testJavaToR("getBoxedCharacterArray2d0x0", matrix("", 0, 0))
testJavaToR("getBoxedCharacterArray2d2x0", matrix("", 2, 0))
testJavaToR("getBoxedCharacterArray2d2x1", matrix(c("1", "2")))
testJavaToR("getBoxedCharacterArray2d2x2", matrix(c("1", "2", "3", "4"), 2, 2, byrow = TRUE))
testJavaToR("getBoxedCharacterArray2dNulls", matrix(c(NA_character_, "1", NA_character_, "2", NA_character_, "3"), 2, 3, byrow = TRUE))
testJavaToR("getBoxedCharacterArray2dRagged1", list(character(), "1", character(), c("2", "3"), character()))
testJavaToR("getBoxedCharacterArray2dRagged2", list("1", character(), c("2", "3")))
testJavaToR("getBoxedDoubleArray2d0x0", matrix(0, 0, 0))
testJavaToR("getBoxedDoubleArray2d2x0", matrix(0, 2, 0))
testJavaToR("getBoxedDoubleArray2d2x1", matrix(c(DOUBLE_MIN, DOUBLE_MAX)))
testJavaToR("getBoxedDoubleArray2d2x2", matrix(c(DOUBLE_MIN, -1, 0, DOUBLE_MAX), 2, 2, byrow = TRUE))
testJavaToR("getBoxedDoubleArray2dNulls", matrix(c(NA_real_, DOUBLE_MIN, NA_real_, DOUBLE_MIN, NA_real_, DOUBLE_MAX), 2, 3, byrow = TRUE))
testJavaToR("getBoxedDoubleArray2dRagged1", list(numeric(), DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX), numeric()))
testJavaToR("getBoxedDoubleArray2dRagged2", list(DOUBLE_MIN, numeric(), c(0, DOUBLE_MAX)))
testJavaToR("getBoxedFloatArray2d0x0", matrix(0, 0, 0))
testJavaToR("getBoxedFloatArray2d2x0", matrix(0, 2, 0))
testJavaToR("getBoxedFloatArray2d2x1", matrix(c(FLOAT_MIN, FLOAT_MAX)), identical = FALSE)
testJavaToR("getBoxedFloatArray2d2x2", matrix(c(FLOAT_MIN, -1, 0, FLOAT_MAX), 2, 2, byrow = TRUE), identical = FALSE)
testJavaToR("getBoxedFloatArray2dNulls", matrix(c(NA_real_, FLOAT_MIN, NA_real_, FLOAT_MIN, NA_real_, FLOAT_MAX), 2, 3, byrow = TRUE), identical = FALSE)
testJavaToR("getBoxedFloatArray2dRagged1", list(numeric(), FLOAT_MIN, numeric(), c(0, FLOAT_MAX), numeric()), identical = FALSE)
testJavaToR("getBoxedFloatArray2dRagged2", list(FLOAT_MIN, numeric(), c(0, FLOAT_MAX)), identical = FALSE)
testJavaToR("getBoxedIntegerArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getBoxedIntegerArray2d2x0", matrix(0L, 2, 0))
testJavaToR("getBoxedIntegerArray2d2x1", matrix(c(INTEGER_MIN, INTEGER_MAX)))
testJavaToR("getBoxedIntegerArray2d2x2", matrix(c(INTEGER_MIN, -1L, 0L, INTEGER_MAX), 2, 2, byrow = TRUE))
testJavaToR("getBoxedIntegerArray2dNulls", matrix(c(NA_integer_, INTEGER_MIN, NA_integer_, INTEGER_MIN, NA_integer_, INTEGER_MAX), 2, 3, byrow = TRUE))
testJavaToR("getBoxedIntegerArray2dRagged1", list(integer(), INTEGER_MIN, integer(), c(0L, INTEGER_MAX), integer()))
testJavaToR("getBoxedIntegerArray2dRagged2", list(INTEGER_MIN, integer(), c(0L, INTEGER_MAX)))
testJavaToR("getBoxedLongArray2d0x0", matrix(0, 0, 0))
testJavaToR("getBoxedLongArray2d2x0", matrix(0, 2, 0))
testJavaToR("getBoxedLongArray2d2x1", matrix(c(LONG_MIN, LONG_MAX)))
testJavaToR("getBoxedLongArray2d2x2", matrix(c(LONG_MIN, -1, 0, LONG_MAX), 2, 2, byrow = TRUE))
testJavaToR("getBoxedLongArray2dNulls", matrix(c(NA_real_, LONG_MIN, NA_real_, LONG_MIN, NA_real_, LONG_MAX), 2, 3, byrow = TRUE))
testJavaToR("getBoxedLongArray2dRagged1", list(numeric(), LONG_MIN, numeric(), c(0, LONG_MAX), numeric()))
testJavaToR("getBoxedLongArray2dRagged2", list(LONG_MIN, numeric(), c(0, LONG_MAX)))
testJavaToR("getBoxedShortArray2d0x0", matrix(0L, 0, 0))
testJavaToR("getBoxedShortArray2d2x0", matrix(0L, 2, 0))
testJavaToR("getBoxedShortArray2d2x1", matrix(c(SHORT_MIN, SHORT_MAX)))
testJavaToR("getBoxedShortArray2d2x2", matrix(c(SHORT_MIN, -1L, 0L, SHORT_MAX), 2, 2, byrow = TRUE))
testJavaToR("getBoxedShortArray2dNulls", matrix(c(NA_integer_, SHORT_MIN, NA_integer_, SHORT_MIN, NA_integer_, SHORT_MAX), 2, 3, byrow = TRUE))
testJavaToR("getBoxedShortArray2dRagged1", list(integer(), SHORT_MIN, integer(), c(0L, SHORT_MAX), integer()))
testJavaToR("getBoxedShortArray2dRagged2", list(SHORT_MIN, integer(), c(0L, SHORT_MAX)))
testJavaToR("getStringArray2d0x0", matrix("", 0, 0))
testJavaToR("getStringArray2d2x0", matrix("", 2, 0))
testJavaToR("getStringArray2d2x1", matrix(c("", ""), 2, 1))
testJavaToR("getStringArray2d2x2", matrix(c("", " ", "a", "Z"), 2, 2, byrow = TRUE))
testJavaToR("getStringArray2dNulls", matrix(c(NA_character_, "", NA_character_, "a", NA_character_, "Z"), 2, 3, byrow = TRUE))
testJavaToR("getStringArray2dRagged1", list(character(), "", character(), c("a", "Z"), character()))
testJavaToR("getStringArray2dRagged2", list("", character(), c("a", "Z")))
js$setDataFrameRowMajor(jsr223:::DEFAULT_DATA_FRAME_ROW_MAJOR)

# Miscellaneous -----------------------------------------------------------

# Because the last expression of a script is returned, a script containing a
# function will return a function. I could raise an error, but this is annoying
# and unexpected. Return R NULL instead.

js %@% "var a = function(x) x"
assertIdentical(NULL, js %~% "a")
assertIdentical(NULL, js$a)

# Finished ----------------------------------------------------------------

js$terminate()

cat("End Test\n\n")
