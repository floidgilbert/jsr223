# Demonstrate the use of Apache Commons Mathematics library.
# http://commons.apache.org/proper/commons-math/

library("jsr223")

# Change this path to the installation directory of the Kotlin compiler.
kotlin.directory <- Sys.getenv("KOTLIN_HOME")

# Include both the Kotlin script engine jars and the Apache Commons Mathematics
# libraries in the class path. Specify the paths seperately in a character
# vector.
engine <- ScriptEngine$new(
  engine.name = "kotlin"
  , class.path = c(
    getKotlinScriptEngineJars(kotlin.directory),
    "../commons-math3-3.6.1.jar"
  )
)

# Define the means and covariance matrix that will be used to create the
# bivariate normal distribution.
engine$means <- c(0, 2)
engine$covariances <- diag(1, nrow = 2)

# Import the package member and instantiate a new class.
engine %@% '
import org.apache.commons.math3.distribution.MultivariateNormalDistribution
val mvn = MultivariateNormalDistribution(
  jsr223Bindings["means"] as DoubleArray,
  jsr223Bindings["covariances"] as Array<DoubleArray>
)
'

# This line is a workaround for a Kotlin bug.
# https://github.com/floidgilbert/jsr223/issues/1
engine %@% 'jsr223Bindings["mvn"] = mvn'

# Take a multivariate sample.
engine$invokeMethod("mvn", "sample")

# Take three samples.
replicate(3, engine$invokeMethod("mvn", "sample"))

##           [,1]      [,2]      [,3]
## [1,] 0.9924368 -1.295875 0.2025815
## [2,] 2.5145855  2.128243 1.1666272

# Terminate the script engine.
engine$terminate()

