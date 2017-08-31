# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# JavaScript

# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##


# Initialize --------------------------------------------------------------

library("jsr223")
source("../R/jsr223/tests/utility.R")
engine <- ScriptEngine$new("js")


# Bindings ----------------------------------------------------------------

#' 1) Creating a binding and accessing it in a snippet;
#' 2) Creating a variable in a snippet and accessing it via bindings;
#' 3) Persistence of variables between snippets;
#' 4) Returning values from a snippet.
engine$c <- 2.4
assertIdentical(TRUE, engine %~% 'c === 2.4')
engine %@% 'var d = 3.8999'
assertIdentical(3.8999, engine$d)
assertIdentical(TRUE, engine %~% 'd === 3.8999')

lst <-   list(
  c = "java.lang.Double"
  , d = "java.lang.Double"
  , R = "org.fgilbert.jsr223.RClient"
)

assertIdentical(lst, engine$getBindings())
invisible(engine$remove("c"))
lst$c = NULL
assertIdentical(lst, engine$getBindings())


# Standard Output ---------------------------------------------------------

engine$setStandardOutputMode("console")
engine %@% "print('You should see this message (1).');"

engine$setStandardOutputMode("quiet")
engine %@% "print('You should not see this message (1).');"

engine$setStandardOutputMode("buffer")
engine %@% "print('You should not see this message (2).');"
assertIdentical("You should not see this message (2).", removeCarriageReturns(engine$getStandardOutput()))
engine %@% "print('You should not see this message (3).');"
engine$clearStandardOutput()
assertIdentical("", engine$getStandardOutput())

engine$setStandardOutputMode("console")
engine %@% "print('You should see this message (2).');"

engine$setStandardOutputMode(jsr223:::DEFAULT_STANDARD_OUTPUT_MODE)

# Compilable Interface ----------------------------------------------------

engine$a <- 1
cs <- engine$compile("a;")
assertIdentical(1, cs$eval())
assertIdentical(2, cs$eval(bindings = list(a = 2)))


# Invocable Interface -----------------------------------------------------

engine %~% "
function returnOne() {
  return 1;
}
"
assertIdentical(1L, engine$invokeFunction("returnOne"))

engine %~% "
function addThis(a, b, c) {
  return a + b + c;
}
"
assertIdentical(4, engine$invokeFunction("addThis", 1, 1, 2))

engine %~% "
var o = {a:1}
o.returnOne = function() {return 1;}
"
assertIdentical(1L, engine$invokeMethod("o", "returnOne"))
assertIdentical(1, engine$invokeMethod("Math", "abs", -1))


# Script Engine Types -----------------------------------------------------

cat("JS Type Testing\n")

cat("JS null...\n")

engine %@% 'var a = null'
assertIdentical(NULL, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')


cat("JS Number...\n")

engine %@% 'var a = 3.144'
assertIdentical(3.144, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')

engine %@% 'var a = 3'
assertIdentical(3L, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')

engine %@% 'var a = NaN'
assertIdentical(NaN, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'isNaN(b)')

engine %@% 'var a = Infinity'
assertIdentical(Inf, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')

engine %@% 'var a = -Infinity'
assertIdentical(-Inf, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')


cat("JS String...\n")

engine %@% 'var a = "The fox is in the barn."'
assertIdentical("The fox is in the barn.", engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')

engine %~% 'var a = ""'
assertIdentical("", engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')


cat("JS Boolean...\n")

engine %~% 'var a = true'
assertIdentical(TRUE, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')

engine %~% 'var a = false'
assertIdentical(FALSE, engine$a)
engine$b = engine$a
assertIdentical(TRUE, engine %~% 'a === b')


cat("JS Date...\n")

assertMessage(
  {
    engine %~% 'var a = new Date()'
    engine$a
  }
  , "Unsupported data type (structure:0x0 , type:0xFF)."
)


cat("JS Integer Array...\n")
engine %~% 'var a = [0, 1, 2, 3];'
assertIdentical(0:3, engine$a)
# Not Applicable: b will be a Java array.
# engine$b = engine$a
# assertIdentical(TRUE, engine %~% 'a === b')


cat("JS Double Array...\n")
engine %~% 'var a = [Math.PI, 1, 2, 3];'
assertIdentical(c(pi, 1:3), engine$a)
# Not Applicable: b will be a Java array.
# engine$b = engine$a
# assertIdentical(TRUE, engine %~% 'a === b')


cat("JS Integer Matrix...\n")
engine %~% 'var a = [[1, 2, 3], [4, 5, 6]];'
assertIdentical(matrix(1:6, 2, 3, byrow = TRUE), engine$a)


cat("JS Double Matrix...\n")
engine %~% 'var a = [[Infinity, 2, 3], [-Infinity, 5, 6]];'
assertIdentical(matrix(c(Inf, 2, 3, -Inf, 5, 6), 2, 3, byrow = TRUE), engine$a)


engine$terminate()
