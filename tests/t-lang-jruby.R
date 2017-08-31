# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# JRuby - http://jruby.org/

# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##


# Initialize --------------------------------------------------------------

library("jsr223")
source("../R/jsr223/tests/utility.R")
engine <- ScriptEngine$new("jruby", "../engines/jruby-complete-9.1.2.0.jar")


# Bindings ----------------------------------------------------------------

#' 1) Creating a binding and accessing it in a snippet;
#' 2) Creating a variable in a snippet and accessing it via bindings;
#' 3) Persistence of variables between snippets;
#' 4) Returning values from a snippet.
engine$c <- 2.4
assertIdentical(TRUE, engine %~% '$c === 2.4')
engine %@% '$d = 3.8999'
assertIdentical(3.8999, engine$d)
assertIdentical(TRUE, engine %~% '$d === 3.8999')

lst <-   list(
  c = "java.lang.Double"
  , d = "java.lang.Double"
  , javax.script.argv = "java.util.ArrayList"
  , R = "org.fgilbert.jsr223.RClient"
)

assertIdentical(lst, engine$getBindings())
invisible(engine$remove("c"))
lst$c = NULL
assertIdentical(lst, engine$getBindings())


# Standard Output ---------------------------------------------------------

engine$setStandardOutputMode("console")
engine %@% "puts 'You should see this message (1).'"

engine$setStandardOutputMode("quiet")
engine %@% "puts 'You should not see this message (1).'"

engine$setStandardOutputMode("buffer")
engine %@% "puts 'You should not see this message (2).'"
assertIdentical("You should not see this message (2).", removeCarriageReturns(engine$getStandardOutput()))
engine %@% "puts 'You should not see this message (3).'"
engine$clearStandardOutput()
assertIdentical("", engine$getStandardOutput())

#/// doesn't work. it's broken. See what's happening...
engine$setStandardOutputMode("console")
engine %@% "puts 'You should see this message (2).'"

engine$setStandardOutputMode(jsr223:::DEFAULT_STANDARD_OUTPUT_MODE)

# Compilable Interface ----------------------------------------------------

engine$a <- 1
cs <- engine$compile("$a")
assertIdentical(1, cs$eval())
assertIdentical(2, cs$eval(bindings = list(a = 2)))


# Invocable Interface -----------------------------------------------------

#///error when using %~% because it tries to return function
engine %@% "
def returnOne()
  1
end
"
assertIdentical(1, engine$invokeFunction("returnOne"))

engine %@% "
def addThis(a, b, c)
  a + b + c;
end
"
assertIdentical(4, engine$invokeFunction("addThis", 1, 1, 2))

engine %@% "
class Abc

  def returnOne()
    1
  end

  def addThis(a, b, c)
    a + b + c;
  end

end

$o = Abc.new
"
assertIdentical(1, engine$invokeMethod("o", "returnOne"))
assertIdentical(3, engine$invokeMethod("o", "addThis", 1, 1, 1))


# Script Engine Types -----------------------------------------------------

# IMPORTANT: Do not re-use variable names with JRuby - the types remain the same.

cat("JRuby Type Testing\n")


cat("\nJRuby nil...\n")

engine %@% '$a = nil'
assertIdentical(NULL, engine$a)
engine$b <- engine$a
assertIdentical(TRUE, engine %~% '$a === $b')


cat("\nJRuby Fixnum...\n")

engine %@% '$fixA = 1'
assertIdentical(1, engine$fixA)
cat(engine %~% '$fixA.class.name', "\n")
cat(engine$getJavaClassName("fixA"), "\n")
engine$fixB <- engine$fixA
assertIdentical(TRUE, engine %~% '$fixA == $fixB')


cat("\nJRuby Bignum...\n")

engine %@% '$bigA = 12345678933 ** 2'
assertIdentical(1.5241578831672e+20, engine$bigA)
cat(engine %~% '$bigA.class.name', "\n")
cat(engine$getJavaClassName("bigA"), "\n")
engine$bigB <- engine$bigA
assertIdentical(TRUE, engine %~% '$bigA == $bigB')


cat("\nJRuby Float...\n")

engine %@% '$fltA = 1.1'
assertIdentical(1.1, engine$fltA)
cat(engine %~% '$fltA.class.name', "\n")
cat(engine$getJavaClassName("fltA"), "\n")
engine$fltB = engine$fltA
assertIdentical(TRUE, engine %~% '$fltB == $fltA')


# Should work, but there are bugs.
# cat("\nJRuby BigDecimal...\n")
#
# engine %@% 'require "bigdecimal"; $bigdA = BigDecimal.new("0.0001")'
# assertIdentical(0.0001, engine$bigdA)
# cat(engine %~% '$bigdA.class.name', "\n")
# cat(engine$getJavaClassName("bigdA"), "\n")
# engine$bigdB <- engine$bigdA
# assertIdentical(TRUE, engine %~% '$bigdA == $bigdB')


cat("\nJRuby String...\n")

engine %@% '$strA = "abc"'
assertIdentical("abc", engine$strA)
cat(engine %~% '$strA.class.name', "\n")
cat(engine$getJavaClassName("strA"), "\n")
engine$strB = engine$strA
assertIdentical(TRUE, engine %~% '$strA == $strB')

engine %@% '$strA = ""'
engine$strB = engine$strA
assertIdentical(TRUE, engine %~% '$strA == $strB')


#///Removed support for symbol
# cat("\nJRuby Symbol...\n")
#
# assertIdentical("abc123", engine %~% ":'abc123'")
# cat(engine %~% ":'abc123'.class.name", "\n")
# Identifier does not make sense in this context.
# cat(engine$getJavaClassName(":'abc123'"), "\n")


cat("\nJRuby Boolean...\n")

engine %@% '$boolA = true'
assertIdentical(TRUE, engine$boolA)
cat(engine %~% '$boolA.class.name', "\n")
cat(engine$getJavaClassName("boolA"), "\n")
engine$boolB = engine$boolA
assertIdentical(TRUE, engine %~% '$boolA == $boolB')

engine %@% '$boolA = false'
assertIdentical(FALSE, engine$boolA)
engine$boolB = engine$boolA
assertIdentical(TRUE, engine %~% '$boolA == $boolB')


# Intentionally not supported.
# cat("JRuby Complex...\n")
# engine %@% '$cxA = Complex(2, 3)'
# cat(engine %~% '$cxA.class.name', "\n")
# cat(engine$getJavaClassName("cxA"), "\n")
# engine$cxB = engine$cxA
# assertIdentical(TRUE, engine %~% '$cxA == $cxB')


#///removed support for Ruby Rational.
cat("\nJRuby Rational...\n")

# engine %@% '$rtA = Rational(2, 3)'
# assertIdentical(2 / 3, engine$rtA)
# cat(engine %~% '$rtA.class.name', "\n")
# cat(engine$getJavaClassName('rtA'), "\n")
# engine$rtB = engine$rtA
# assertIdentical(TRUE, engine %~% '$rtA == $rtB')

cat("\nJRuby Array...\n")

engine %@% '$arrayA = [1, 2, 3, 4]'
assertIdentical(as.numeric(1:4), engine$arrayA)
cat(engine %~% '$arrayA.class.name', "\n")
cat(engine$getJavaClassName('arrayA'), "\n")
engine$arrayB = engine$arrayA
assertIdentical(TRUE, engine %~% '$arrayA == $arrayB')


cat("\nJRuby Matrix...\n")

engine %@% '$matrixA = [[1, 2, 3], [4, 5, 6]]'
assertIdentical(matrix(as.numeric(1:6), 2, 3, byrow = TRUE), engine$matrixA)
cat(engine %~% '$matrixA.class.name', "\n")
cat(engine$getJavaClassName('matrixA'), "\n")
engine$matrixB = engine$matrixA
# matrixA and matrixB are different data strucures at this point.
# assertIdentical(TRUE, engine %~% '$matrixA == $matrixB')


cat("\nJRuby Hash...\n")

engine %@% '$hashA = { "red" => 0xf00, "green" => 0x0f0, "blue" => 0x00f }'
assertIdentical(list(red = 0xf00, green = 0x0f0, blue = 0x00f), engine$hashA)
cat(engine %~% '$hashA.class.name', "\n")
cat(engine$getJavaClassName('hashA'), "\n")
# hashA and hashB are not comparable. They are different data structures at this point.
# engine$hashB = engine$hashA
# assertIdentical(TRUE, engine %~% '$hashA == $hashB')


# Intentionally not supported. Not used enough as a valid data structure to justify supporting it.
#
# cat("\nJRuby Range...\n")
#
# engine %@% '$rangeA = 0..5'
# assertIdentical(as.numeric(0:5), engine$rangeA)
# cat(engine %~% '$rangeA.class.name', "\n")
# cat(engine$getJavaClassName('rangeA'), "\n")
# engine$rangeB = engine$rangeA
# # rangeA and rangeB are different data strucures at this point.
# # assertIdentical(TRUE, engine %~% '$rangeA == $rangeB')

engine$terminate()

