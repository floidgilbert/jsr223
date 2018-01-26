# Demonstrate the issues, and workarounds, related to the global bindings in the
# Kotlin script engine environment.

library("jsr223")

# Change this path to the installation directory of the Kotlin compiler.
kotlin.directory <- Sys.getenv("KOTLIN_HOME")

engine <- ScriptEngine$new(
  engine.name = "kotlin",
  class.path = getKotlinScriptEngineJars(kotlin.directory)
)

# Establish a binding named `a`
engine$a <- 1
engine$a

# Access bindings via the global `bindings` object in the Kotlin script engine
# environment. Be sure to use double quotes as the string delimiter within the
# Kotlin script. The following two expressions are equivalent.
engine %~% 'bindings["a"]'
engine %~% 'bindings.get("a")'

# The `bindings` object appears to be of javax.script.SimpleBindings.
engine %~% 'bindings::class.qualifiedName'

# However, the object does not support updates. The following line would throw
# an error. See https://youtrack.jetbrains.com/issue/KT-18917
# engine %~% 'bindings.put("a", 2.1);'

# This is a known bug. The workarounds are to cast `bindings` as
# javax.script.Bindings or to use `jsr223Bindings`.
engine %@% 'jsr223Bindings["a"] = 3.1'
engine$a
engine %@% 'jsr223Bindings.put("a", 4.1)'
engine$a

engine %@% 'val b = bindings as javax.script.Bindings'
engine %@% 'b["a"] = 3.1'
engine$a
engine %@% 'b.put("a", 4.1)'
engine$a

# The RClient object, R, is not easy to use from the `bindings` object because
# it must be cast to an explicit type as follows.
engine %~% '(bindings["R"] as org.fgilbert.jsr223.RClient).set("c", 3)'

# To work around this, jsr223 automatically creates a variable R in the
# global scope of the Kotlin environment to facilitate callbacks.
engine %~% 'R.set("c", 4)'

# Terminate the script engine.
engine$terminate()

engine %@% 'jsr223Bindings["myValue"] = 3.1'
engine %~% 'jsr223Bindings["myValue"]'
