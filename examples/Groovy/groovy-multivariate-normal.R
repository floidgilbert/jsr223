# Demonstrate the use of Apache Commons Mathematics library.
# http://commons.apache.org/proper/commons-math/

library("jsr223")

# Include both the Groovy script engine and the Apache Commons Mathematics
# libraries in the class path. Specify the paths seperately in a character
# vector.
engine <- ScriptEngine$new(
  engine.name = "groovy"
  , class.path = c(
    "~/my-path/groovy-all.jar",
    "~/my-path/commons-math3-3.6.1.jar"
  )
)

# Define the means and covariance matrix that will be used to create the
# bivariate normal distribution.
engine$means <- c(0, 2)
engine$covariances <- diag(1, nrow = 2)

# Import the package member and instantiate a new class. Declare 'mvn'
# a global variable by excluding the type specifier.
engine %@% "
  import org.apache.commons.math3.distribution.MultivariateNormalDistribution;
  mvn = new MultivariateNormalDistribution(means, covariances);
"

# Take a sample.
engine$invokeMethod("mvn", "sample")

## [1] 0.3279374 0.8652296

# Take three samples.
replicate(3, engine$invokeMethod("mvn", "sample"))

##           [,1]      [,2]      [,3]
## [1,] 0.9924368 -1.295875 0.2025815
## [2,] 2.5145855  2.128243 1.1666272

engine$terminate()
