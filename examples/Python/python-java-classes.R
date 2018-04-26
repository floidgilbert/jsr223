# Demonstrate creating Java classes and arrays in Jython (Python).
# See the Jython Users Guide for more details.
#   https://wiki.python.org/jython/NewUsersGuide

library("jsr223")
engine <- ScriptEngine$new(
  engine.name = "python",
  class.path = "lib/jython-standalone-2.7.0.jar"
)

# Create an object from the java.util.Random class.
engine %~% "
from java.util import Random
r = Random(10)
"

# Jython supports invoking Java methods.
engine$invokeMethod("r", "nextDouble")

## [1] 0.7304303

# Use 'jarray.array' to copy a sequence to a Java array of the requested type.
engine %~% "
from jarray import *
myArray = array([3, 2, 1], 'i')
"
engine$myArray

## [1] 3 2 1

# Alternatively, use zeros to initialize an array with zeros or null. This
# example allocates an array and udpates the values with a loop.
engine %~% "
myArray = zeros(5, 'i')
for i in range(myArray.__len__()):
  myArray[i] = i
"
engine$myArray

## [1] 0 1 2 3 4

engine$terminate()
