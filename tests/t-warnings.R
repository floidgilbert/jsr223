library("jsr223")
source("../R/jsr223/tests/test00.R")

js <- startEngine("js")

#' Check that commands marked with '##' produces a data coercion warning.

#' IMPORTANT: This test module has been moved outside the distributed testing
#' procedures because it is not possible to do an assertWarning test similar to
#' assertError. Any warning handler will interrupt execution where the warning
#' occurs. If execution is interrupted, org.fgilbert.jsr223.Controller gets out
#' of synch and freezes occur.

# Logical/Boolean Values --------------------------------------------------

# coerceLogicalNaValues
value <- c(TRUE, NA, FALSE)
compare <- c(TRUE, TRUE, FALSE)
js$value <- value ## 1
assertIdentical(compare, js$value)
assertIdentical(compare, js %~% "value")
assertIdentical(compare, js %~% "R.get('value')") ## 1

# coerceLogicalNaValues.data.frame
value <- data.frame(a = 1:3, b = c(TRUE, NA, FALSE))
compare <- data.frame(a = 1:3, b = c(TRUE, TRUE, FALSE))
js$value <- value ## 1
assertIdentical(compare, js$value)
assertIdentical(compare, js %~% "value")
assertIdentical(compare, js %~% "R.get('value')") ## 1

# coerceLogicalNaValues.list
value <- list(1, NA, c(TRUE, NA, FALSE), "a")
compare <- list(1, TRUE, c(TRUE, TRUE, FALSE), "a")
js$value <- value ## 2
assertIdentical(compare, js$value)
assertIdentical(compare, js %~% "value")
assertIdentical(compare, js %~% "R.get('value')") ## 2

# A warning is generated on the Java side when null is encountered while coercing
# a java.lang.Boolean[] array. See unboxArray1D(Boolean[] a).

js %~% "
var BooleanArray = Java.type('java.lang.Boolean[]');
var value = new BooleanArray(5);
"
compare <- rep(TRUE, times = 5)
assertIdentical(compare, js$value) ## 1
assertIdentical(compare, js %~% "value")
js %~% "R.set('value', value);" ## 1
assertIdentical(compare, value)

# coerceCollectionToBooleanArray1D
compare <- c(TRUE, FALSE, TRUE, TRUE)
assertIdentical(compare, js %~% "[true, false, null, true];") ## 1
js %~% "R.set('value', [true, false, null, true]);" ## 1
assertIdentical(compare, value)
compare <- list(1L, 2L, list(rep(TRUE, times = 5), 3L, c(TRUE, FALSE, TRUE, TRUE)))
assertIdentical(compare, js %~% "[1, 2, [value, 3, [true, false, null, true]]];") ## 2
js %~% "R.set('value', [1, 2, [value, 3]]);" ## 1
assertIdentical(list(1L, 2L, list(rep(TRUE, times = 5), 3L)), value)

# Raw/Byte Values ---------------------------------------------------------

# A warning is generated on the Java side when null is encountered while coercing
# a java.lang.Byte[] array. See unboxArray1D(Byte[] a).
js %~% "
var ByteArray = Java.type('java.lang.Byte[]');
var value = new ByteArray(5);
"
compare <- raw(5)
assertIdentical(compare, js$value) ## 1
assertIdentical(compare, js %~% "value") ## 1
js %~% "R.set('value', value);" ## 1
assertIdentical(compare, value)

# coerceCollectionToByteArray1D
js %~% "
var ByteType = Java.type('java.lang.Byte');
var b = new ByteType(1);
"
compare <- as.raw(c(1L, 1L, 0L, 1L, 0L))
assertIdentical(compare, js %~% "[b, b, null, b, null]") ## 1
js %~% "R.set('value', [b, b, null, b, null]);" ## 1
assertIdentical(compare, value)
compare <- list(1L, 2L, list(raw(5), 3L, compare))
assertIdentical(compare, js %~% "[1, 2, [value, 3, [b, b, null, b, null]]];") ## 2
js %~% "R.set('value', [1, 2, [value, 3]]);" ## 1
assertIdentical(list(1L, 2L, list(raw(5), 3L)), value)

# Map to Data Frame
js %~% "
var LinkedHashMapClass = Java.type('java.util.LinkedHashMap');
var m = new LinkedHashMapClass(5);
m.put('a', [1, 2, 3, 4, 5])
m.put('b', new BooleanArray(5))
m.put('c', [null, false, null, true, null])
m.put('d', new ByteArray(5))
m.put('e', [null, b, null, b, null])
"

compare <- data.frame(
  a = 1:5
  , b = rep(TRUE, times = 5)
  , c = c(TRUE, FALSE, TRUE, TRUE, TRUE)
  , d = raw(5)
  , e = as.raw(c(0L, 1L, 0L, 1L, 0L))
)
assertIdentical(compare, js$m) ## 4
assertIdentical(compare, js %~% "m") ## 4
js %~% "R.set('value', m)" ## 4
assertIdentical(compare, value)

# Finished
js$terminate()
rm(js, value, compare)
