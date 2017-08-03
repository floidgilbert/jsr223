# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# Groovy - http://groovy-lang.org/

# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# Initialize --------------------------------------------------------------

library("jsr223")
source("../R/jsr223/tests/test00.R")
engine <- startEngine("groovy", "../engines/groovy-all-2.3.7.jar")


# Bindings ----------------------------------------------------------------

#' 1) Creating a binding and accessing it in a snippet;
#' 2) Creating a variable in a snippet and accessing it via bindings;
#' 3) Persistence of variables between snippets;
#' 4) Returning values from a snippet.
engine$c <- 2.4
assertIdentical(TRUE, engine %~% 'c == 2.4')
engine %@% 'd = 3.8999'
assertIdentical(3.8999, engine$d)
assertIdentical(TRUE, engine %~% 'd == 3.8999')

lst <-   list(
  c = "java.lang.Double"
  , d = "java.math.BigDecimal"
  , R = "org.fgilbert.jsr223.RClient"
)

assertIdentical(lst, engine$getBindings())
invisible(engine$remove("c"))
lst$c = NULL
assertIdentical(lst, engine$getBindings())


# Standard Output ---------------------------------------------------------

engine$setStandardOutputMode("console")
engine %@% "println('You should see this message (1).');"

engine$setStandardOutputMode("quiet")
engine %@% "println('You should not see this message (1).');"

engine$setStandardOutputMode("buffered")
engine %@% "println('You should not see this message (2).');"
assertIdentical("You should not see this message (2).", removeCarriageReturns(engine$getStandardOutput()))
engine %@% "println('You should not see this message (3).');"
engine$clearStandardOutput()
assertIdentical("", engine$getStandardOutput())

engine$setStandardOutputMode("console")
engine %@% "println('You should see this message (2).');"

engine$setStandardOutputMode(jsr223:::DEFAULT_STANDARD_OUTPUT_MODE)

# Compilable Interface ----------------------------------------------------

engine$a <- 1
cs <- engine$compile("a;")
assertIdentical(1, cs$eval())
assertIdentical(2, cs$eval(bindings = list(a = 2)))


# Invocable Interface -----------------------------------------------------

engine %~% "
int returnOne() {
  return 1;
}
"
assertIdentical(1L, engine$invokeFunction("returnOne"))

engine %~% "
int addThis(int a, int b, int c) {
  return a + b + c;
}
"
assertIdentical(4L, engine$invokeFunction("addThis", 1L, 1L, 2L))

engine %@% "
class DoMath {

  int returnOne() {
    return 1;
}

  int addThese(int a, int b, int c) {
    return a + b + c;
  }

}

o = new DoMath();
"
assertIdentical(1L, engine$invokeMethod("o", "returnOne"))
assertIdentical(4L, engine$invokeMethod("o", "addThese", 1L, 2L, 1L))


# Script Engine Types -----------------------------------------------------

# IMPORTANT: This does not test all possible types because Groovy types map
# directly to Java boxed types.

cat("Groovy Type Testing\n")


cat("Groovy Strings...\n")

assertIdentical("abc", engine %~% "'abc'")
script <- "
'''
1
2
3
'''
"
assertIdentical("\n1\n2\n3\n", engine %~% script)
assertIdentical("abc", engine %~% "\"abc\"")
assertIdentical("abc1", engine %~% "n = 1i; s = \"abc${n}\"")
assertIdentical(rep("abc1", times = 3), engine %~% "[s, s, s]")
assertIdentical(matrix(rep("abc1", times = 6), 2, 3), engine %~% "[[s, s, s], [s, s, s]]")
script <- "
\"\"\"
${n}
2
3
\"\"\"
"
assertIdentical("\n1\n2\n3\n", engine %~% script)


cat("Groovy Constants...\n")

assertIdentical(NULL, engine %~% "null")
assertIdentical(FALSE, engine %~% "false")
assertIdentical(TRUE, engine %~% "true")
assertIdentical(NaN, engine %~% "Double.NaN")
assertIdentical(Inf, engine %~% "Double.class.POSITIVE_INFINITY")
assertIdentical(-Inf, engine %~% "Double.class.NEGATIVE_INFINITY")


cat("Groovy Array...\n")

assertIdentical(1:3, engine %~% "[1, 2, 3] as int[]")
assertIdentical(c(1.1, 2.1, 3.1), engine %~% "[1.1, 2.1, 3.1] as double[]")


cat("Groovy Array as Matrix...\n")

assertIdentical(matrix(1:6, 2, 3, byrow = TRUE), engine %~% "[[1, 2, 3], [4, 5, 6]] as int[][]")


cat("Groovy Map...\n")

assertIdentical(list(red = 0xFF0000L, green = 0x00FF00L, blue = 0x0000FFL), engine %~% "[red: 0xFF0000, green: 0x00FF00, blue: 0x0000FF]")

engine$terminate()
