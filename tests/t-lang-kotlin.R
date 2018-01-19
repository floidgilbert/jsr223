# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# Kotlin - https://kotlinlang.org

# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# Initialize --------------------------------------------------------------

library("jsr223")

class.path <- c(
  "C:\\kotlinc\\lib\\kotlin-compiler.jar"
  , "C:\\kotlinc\\lib\\kotlin-script-runtime.jar"
  , "C:\\kotlinc\\lib\\kotlin-stdlib.jar"
  , "C:\\kotlinc\\lib\\kotlin-script-util-1.1.51.jar"
  # , "C:\\kotlinc\\lib\\kotlin-reflect.jar"
)

source("../R/jsr223/tests/utility.R")
engine <- ScriptEngine$new('kotlin', class.path)

# Bindings ----------------------------------------------------------------

#' 1) Creating a binding and accessing it in a snippet;
#' 2) Creating a variable in a snippet and accessing it via bindings;
#' 3) Persistence of variables between snippets;
#' 4) Returning values from a snippet.
engine$terminate()
engine <- ScriptEngine$new("kotlin", class.path)
engine$c <- 2.4
engine$c
engine %~% 'bindings::class.qualifiedName'
engine %~% 'bindings.size'
engine %~% 'bindings.isEmpty()'
engine %~% 'bindings.get("c")'
# engine %~% 'bindings.put("c", 100)'
engine %~% 'val bindingsx = bindings as javax.script.SimpleBindings'
engine %~% '(bindings as javax.script.SimpleBindings).put("c", 100)'
engine$c
# These work. Not sure why. List them. Tell them to just set bindingsx or something until Kotlin fixes it.
# Also, tell them about warnings that come up. Put it in issues.
# engine %~% "mt[2].invoke(bindings, \"d\" as Object, 104 as Object)"
# engine %~% "mt[3].invoke(bindings, \"d\" as Object, 104 as Object)"


# engine %~% 'val l = bindings::class.supertypes'
# engine %~% 'l::class.qualifiedName'
# engine %~% 'l[0].toString()'
# engine %~% 'l[1].toString()'

engine %~% 'val m = bindings::class.java'
engine %~% 'val mt = m.getMethods()'
# engine %~% 'mt[0].getName()'
# engine %~% 'mt[1].getName()'
# engine %~% 'mt[2].getName()'
# engine %~% 'mt[3].getName()'
# engine %~% 'mt[4].getName()'
# engine %~% 'mt[5].getName()'
# engine %~% 'mt[6].getName()'
# engine %~% 'mt[7].getName()'
# engine %~% 'mt[8].getName()'
# engine %~% 'mt[9].getName()'
# engine %~% 'mt[10].getName()'

# These work. Not sure why.
# engine %~% "mt[2].invoke(bindings, \"d\" as Object, 104 as Object)"
# engine %~% "mt[3].invoke(bindings, \"d\" as Object, 104 as Object)"
#
# engine %~% 'bindings["c"]'
# engine %~% 'bindings["j"] = 100 as Double'
# engine %~% 'bindings.get(\"c\")'
# engine %~% 'bindings.put(\"d\", 300 as Double)'


engine %~% 'mt[2].getName()'
engine %~% 'mt[2].getParameterCount()'
engine %~% 'mt[2].getParameterTypes()[0].getTypeName()'
engine %~% 'mt[2].getParameterTypes()[1].getTypeName()'

engine %~% 'mt[3].getName()'
engine %~% 'mt[3].getParameterCount()'
engine %~% 'mt[3].getParameterTypes()[0].getTypeName()'
engine %~% 'mt[3].getParameterTypes()[1].getTypeName()'


# a -----------------------------------------------------------------------



assertIdentical(TRUE, engine %~% 'bindings["c"] as Double == 2.4')
engine %~% 'bindings["c"]'
engine %~% 'bindings.getClass().getName();'
engine %~% "bindings.put('d', 100)"
engine %~% '
val f = bindings["kotlin.script.engine"] as org.jetbrains.kotlin.script.jsr223.KotlinJsr223JvmLocalScriptEngine
'
engine %~% '
val f = bindings["kotlin.script.engine"] as javax.script.ScriptEngine
'
engine %~% 'f.get("c")'
engine %~% 'f.put("d", 100)'
engine$d
engine$console()
engine %~% "bindings::class"
engine %~% "println(bindings::class::simpleName)"
engine %~% "println(bindings::class.simpleName)"
engine %~% "println(bindings::class.qualifiedName)"
engine %~% 'bindings'
engine %~% 'val b = bindings as javax.script.SimpleBindings'
engine %~% 'b.put("k", 100)'
engine %~% 'b.put("d", bindings)'
engine %~% 'b.get("k")'
engine %~% 'val s = b.get("d") as javax.script.SimpleBindings'
engine %~% 'println(s)'
engine %~% 's.put("jack", 1)'

engine %~% 'bindings.get("k")'
engine %~% 'bindings.put("s", "abc")'
engine <- ScriptEngine$new("kotlin", class.path)

engine %@% "
for (item in bindings::class.members) {
println(item)
}
"
#///next thing. enumerate all methods and print their names

engine %~% 'bindings.set("a", 100)'
engine %~% 'bindings["a"]'
engine %~% 'bindings["a"] = 3'
engine %~% 'bindings["a"]'
engine %~% 'bindings::class.supertypes.get(0)'
engine %~% 'println(bindings::class.supertypes.get(0))'
engine %~% 'println(bindings::class.supertypes.get(1))'
engine %~% 'b.put("s", "abc")'
engine$k
engine$s
# engine$getBindings()
# engine$terminate()


# abc ---------------------------------------------------------------------

# https://stackoverflow.com/questions/44781462/kotlin-jsr-223-scriptenginefactory-within-the-fat-jar-cannot-find-kotlin-compi
# https://discuss.kotlinlang.org/t/embedding-kotlin-as-scripting-language-in-java-apps/2211/9

engine %@% 'val d = 3.8999'
engine %~% 'bindings["c"] as Double'
engine %~% 'bindings["kotlin.script.state"]'
engine %~% 'bindings["kotlin.script.engine"]'
engine %~% 'val e = bindings["kotlin.script.engine"]'
engine %~% 'e.put("a", 33)'
engine %~% 'bindings["kotlin.script.engine"].put("a", 33)'

engine %~% '
val e = bindings["kotlin.script.engine"] as org.jetbrains.kotlin.script.jsr223.KotlinJsr223JvmLocalScriptEngine
'



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

engine$setStandardOutputMode("buffer")
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
# I removed support for GStringImpl. It is up to the developer to convert it to a regular string.
# assertIdentical("abc1", engine %~% "n = 1i; s = \"abc${n}\"")
# assertIdentical(rep("abc1", times = 3), engine %~% "[s, s, s]")
# assertIdentical(matrix(rep("abc1", times = 6), 2, 3), engine %~% "[[s, s, s], [s, s, s]]")
# script <- "
# \"\"\"
# ${n}
# 2
# 3
# \"\"\"
# "
# assertIdentical("\n1\n2\n3\n", engine %~% script)


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
