# Demonstrate the use of Apache Commons Mathematics library.
# http://commons.apache.org/proper/commons-math/

library("jsr223")

# Include the Apache Commons Mathematics library in class.path.
engine <- ScriptEngine$new(
  engine.name = "js",
  class.path = "lib/commons-math3-3.6.1.jar"
)

# Define the means and covariance matrix that will be used to create the
# bivariate normal distribution.
engine$means <- c(0, 2)
engine$covariances <- diag(1, nrow = 2)

# Import the package member and instantiate a new class.
engine %@% "
  var MultivariateNormalDistributionClass = Java.type(
    'org.apache.commons.math3.distribution.MultivariateNormalDistribution'
  );
  mvn = new MultivariateNormalDistributionClass(means, covariances);
"

# This line would throw an error. Nashorn JavaScript supports 'invokeMethod' for
# native JavaScript objects, but not for Java objects.
#
## engine$invokeMethod("mvn", "sample")

# Instead, use script...
engine %~% "mvn.sample();"

## [1] 0.3279374 0.8652296

# ...or wrap the method in a JavaScript function.
engine %@% "function sample() {return mvn.sample();}"
engine$invokeFunction("sample")

## [1] 0.2527757 1.1942332

# Take three samples.
replicate(3, engine$invokeFunction("sample"))

##           [,1]      [,2]      [,3]
## [1,] 0.9924368 -1.295875 0.2025815
## [2,] 2.5145855  2.128243 1.1666272

engine$terminate()
