# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# Jython - http://jython.org/

# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# Initialize --------------------------------------------------------------

library("jsr223")
source("../R/jsr223/tests/test00.R")
engine <- startEngine("jython", "../engines/jython-standalone-2.7.0.jar")


# Bindings ----------------------------------------------------------------

#' 1) Creating a binding and accessing it in a snippet;
#' 2) Creating a variable in a snippet and accessing it via bindings;
#' 3) Persistence of variables between snippets;
#' 4) Returning values from a snippet.
engine$c <- 2.4
assertIdentical(TRUE, engine %~% "c == 2.4")
engine %@% "d = 3.8999"
assertIdentical(3.8999, engine$d)
assertIdentical(TRUE, engine %~% "d == 3.8999")

lst <-   list(
  `__builtins__` = "org.python.core.PyStringMap"
  , c = "java.lang.Double"
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

engine$setStandardOutputMode("buffered")
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
cs <- engine$compile("a")
assertIdentical(1, cs$eval())
assertIdentical(2, cs$eval(bindings = list(a = 2)))


# Invocable Interface -----------------------------------------------------

#///error when using %~% because it tries to return function
engine %@% "
def returnOne():
  return 1
"
assertIdentical(1L, engine$invokeFunction("returnOne"))

engine %@% "
def addThis(a, b, c):
  return a + b + c;
"
assertIdentical(4, engine$invokeFunction("addThis", 1, 1, 2))

engine %@% "
class Abc:

  def returnOne(self):
    return 1

  def addThis(self, a, b, c):
    return a + b + c;

o = Abc()
"
assertIdentical(1L, engine$invokeMethod("o", "returnOne"))
assertIdentical(3, engine$invokeMethod("o", "addThis", 1, 1, 1))


# Script Engine Types -----------------------------------------------------

cat("Jython Type Testing\n")


cat("\nJython None...\n")

engine %@% 'a = None'
assertIdentical(NULL, engine$a)
engine$b <- engine$a
assertIdentical(TRUE, engine %~% 'a == b')


cat("\nJython bool...\n")
engine %~% 'boolA = True'
assertIdentical(TRUE, engine$boolA)
cat(engine %~% 'type(boolA).__name__', "\n")
cat(engine$getJavaClassName("boolA"), "\n")
engine$boolB = engine$boolA
assertIdentical(TRUE, engine %~% 'boolB == boolA')

engine %~% 'boolA = False'
assertIdentical(FALSE, engine$boolA)
engine$boolB = engine$boolA
assertIdentical(TRUE, engine %~% 'boolB == boolA')


cat("\nJython int...\n")
engine %~% 'intA = int(1)'
assertIdentical(1L, engine$intA)
cat(engine %~% 'type(intA).__name__', "\n")
cat(engine$getJavaClassName("intA"), "\n")
engine$intB = engine$intA
assertIdentical(TRUE, engine %~% 'intB == intA')


cat("\nJython long...\n")
engine %~% 'longA = long(1)'
assertIdentical(1, engine$longA)
cat(engine %~% 'type(longA).__name__', "\n")
cat(engine$getJavaClassName("longA"), "\n")
engine$longB = engine$longA
assertIdentical(TRUE, engine %~% 'longB == longA')


cat("\nJython float...\n")
engine %~% 'floatA = float(1.2)'
assertIdentical(1.2, engine$floatA)
cat(engine %~% 'type(floatA).__name__', "\n")
cat(engine$getJavaClassName("floatA"), "\n")
engine$floatB = engine$floatA
assertIdentical(TRUE, engine %~% 'floatB == floatA')


# Not supported...
# cat("\nJython complex...\n")
# engine %~% 'complexA = complex(1, 2)'
# cat(engine %~% 'type(complexA).__name__', "\n")
# cat(engine$getJavaClassName("complexA"), "\n")
# engine$complexB = engine$complexA
# assertIdentical(TRUE, engine %~% 'complexB == complexA')


# Appears to be no difference between raw, unicode, and ascii. All return "Unicode" as type.
cat("\nJython str...\n")
engine %~% 'strA = "abcd"'
assertIdentical("abcd", engine$strA)
cat(engine %~% 'type(strA).__name__', "\n")
cat(engine$getJavaClassName("strA"), "\n")
engine$strB = engine$strA
assertIdentical(TRUE, engine %~% 'strB == strA')


# Handled internally as a collection.
cat("\nJython list...\n")
engine %~% 'listA = [1, 2, 3]'
assertIdentical(1:3, engine$listA)
cat(engine %~% 'type(listA).__name__', "\n")
cat(engine$getJavaClassName("listA"), "\n")
# jsr223 will create an ArrayList, not a PyList.
# engine$listB = engine$listA
# assertIdentical(TRUE, engine %~% 'listB == listA')


# Handled internally as a collection.
cat("\nJython list as matrix...\n")
engine %~% 'listA = [[1, 2, 3], [4, 5, 6]]'
assertIdentical(matrix(1:6, 2, 3, byrow = TRUE), engine$listA)
cat(engine %~% 'type(listA).__name__', "\n")
cat(engine$getJavaClassName("listA"), "\n")
# jsr223 will create an ArrayList, not a PyList.
# engine$listB = engine$listA
# assertIdentical(TRUE, engine %~% 'listB == listA')


# Handled internally as a collection.
cat("\nJython tuple...\n")
engine %~% 'tupleA = (1, 2, 3)'
assertIdentical(1:3, engine$tupleA)
cat(engine %~% 'type(tupleA).__name__', "\n")
cat(engine$getJavaClassName("tupleA"), "\n")
# jsr223 will create an ArrayList, not a PyList.
# engine$tupleB = engine$tupleA
# assertIdentical(TRUE, engine %~% 'tupleB == tupleA')


# Not supported.
# cat("\nJython bytearray...\n")
# engine %~% 'bytearrayA = bytearray("abc")'
# cat(engine %~% 'type(bytearrayA).__name__')
# cat(engine$getJavaClassName("bytearrayA"), "\n")
# engine$bytearrayB = engine$bytearrayA
# assertIdentical(TRUE, engine %~% 'bytearrayB == bytearrayA')


# Not supported.
# cat("\nJython xrange...\n")
# engine %~% 'xrangeA = xrange(1, 2)'
# cat(engine %~% 'type(xrangeA).__name__', "\n")
# cat(engine$getJavaClassName("xrangeA"), "\n")
# engine$xrangeB = engine$xrangeA
# assertIdentical(TRUE, engine %~% 'xrangeB == xrangeA')


cat("\nJython set...\n")
engine %~% 'setA = set([1, 2, 3])'
assertIdentical(1:3, engine$setA)
cat(engine %~% 'type(setA).__name__', "\n")
cat(engine$getJavaClassName("setA"), "\n")
# jsr223 will create an ArrayList, not a PySet.
# engine$setB = engine$setA
# assertIdentical(TRUE, engine %~% 'setB == setA')


cat("\nJython frozenset...\n")
engine %~% 'setA = frozenset([1, 2, 3])'
assertIdentical(1:3, engine$setA)
cat(engine %~% 'type(setA).__name__', "\n")
cat(engine$getJavaClassName("setA"), "\n")
# jsr223 will create an ArrayList, not a PyFrozenSet.
# engine$setB = engine$setA
# assertIdentical(TRUE, engine %~% 'setB == setA')


cat("\nJython dict...\n")
engine %~% 'dictA = {"first": 1, "second": 2}'
assertIdentical(list(one = 2L, two = 3L), engine$dictA)
cat(engine %~% 'type(dictA).__name__', "\n")
cat(engine$getJavaClassName("dictA"), "\n")
engine$dictB = engine$dictA
assertIdentical(TRUE, engine %~% 'dictB == dictA')


engine$terminate()


