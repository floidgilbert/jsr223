# This example demonstrates a static method call of a Java class to sort a
# vector/array.

library("jsr223")
engine <- ScriptEngine$new("js")

# The method recommended by Nashorn: create a reference to a Java class using
# the built-in Java.type() method. Conceptually, this is similar to importing
# the class.

engine %~% "
var Arrays = Java.type('java.util.Arrays');
var random = R.eval('sample(5)');
Arrays.sort(random);
random;
"

## [1] 1 2 3 4 5

# An alternative method is to use the a fully qualified class name, but it
# requires more overhead per call.

engine %~% "
var random = R.eval('sample(5)');
java.util.Arrays.sort(random);
random;
"

## [1] 1 2 3 4 5

engine$terminate()
