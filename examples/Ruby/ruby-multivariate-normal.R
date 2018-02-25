# Demonstrate the use of Apache Commons Mathematics library.
# http://commons.apache.org/proper/commons-math/

library("jsr223")

# Include both the JRuby script engine and the Apache Commons Mathematics
# libraries in the class path. Specify the paths seperately in a character
# vector.
engine <- ScriptEngine$new(
  engine.name = "ruby", 
  class.path = c(
    "~/my-path/engines/jruby-complete-9.1.2.0.jar",
    "~/my-path/commons-math3-3.6.1.jar"
  )
)

# Define the means vector and covariance matrix that will be used to create the 
# bivariate normal distribution.
engine$means <- c(0, 2)
engine$covariances <- diag(1, nrow = 2)

# Import the class and create a new object from the class.
engine %@% "
java_import org.apache.commons.math3.distribution.MultivariateNormalDistribution
$mvn = MultivariateNormalDistribution.new($means, $covariances)
"

# This line would throw an error. JRuby supports 'invokeMethod' for
# native Ruby objects, but not for Java objects.
# 
## engine$invokeMethod("mvn", "sample")

# Instead, use script...
engine %~% "$mvn.sample()"

## [1] 0.3279374 0.8652296

# ...or wrap the method in a function.
engine %@% "
def sample()
  return $mvn.sample()
end
"
engine$invokeFunction("sample")

## [1] 0.2527757 1.1942332

# Take three samples.
replicate(3, engine$invokeFunction("sample"))

##           [,1]      [,2]      [,3]
## [1,] 0.9924368 -1.295875 0.2025815
## [2,] 2.5145855  2.128243 1.1666272

engine$terminate()
