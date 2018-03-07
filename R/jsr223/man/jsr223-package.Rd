\name{jsr223-package}
\alias{jsr223-package}
\alias{jsr223}

\docType{package}

\title{
A Java Platform Integration for R with Programming Languages Groovy, JavaScript, JRuby (Ruby), Jython (Python), and Kotlin
}

\description{
The \CRANpkg{jsr223} package provides a high-level integration for Java that makes Java objects easy to use from within R and simplifies bi-directional data exchange for a wide variety of objects. Furthermore, \pkg{jsr223} employs the \href{http://docs.oracle.com/javase/8/docs/technotes/guides/scripting/}{Java Scripting API} to bring several scripting languages to the R software environment: JavaScript, Ruby, Python, Groovy, and Kotlin.
}

\details{
The complete documentation is in the \href{../doc/jsr223.pdf}{\pkg{jsr223} User Manual}. It includes in-depth code examples and it covers details, such as data exchange, that cannot be addressed easily in the R documentation.
}

\author{
Floid R. Gilbert \email{floid.r.gilbert@gmail.com}, David B. Dahl \email{dahl@stat.byu.edu}
}

\seealso{
\code{\link{ScriptEngine}}
}

\examples{
# Simple example embedding JavaScript.
library("jsr223")
engine <- ScriptEngine$new("javascript")
engine$radius <- 4
engine \%~\% "var area = Math.PI * Math.pow(radius, 2)"
cat ("The area of the circle is ", engine$area, ".\n", sep = "")

# Use callbacks to set values, get values, and execute R code
# in the current R session via the global R object.
# Access R from JavaScript.
engine \%@\% "R.set('a', 12);"
engine \%@\% "print(\\"The value of 'a' is \\" + R.get('a') + \\".\\");"
engine \%@\% "var randomNormal = R.eval('rnorm(5)');"
engine$randomNormal

# Use a Java object.
engine$randomNormal <- rnorm(5)
engine$randomNormal
engine \%@\% "java.util.Arrays.sort(randomNormal)"
engine$randomNormal

# Close the engine and release resources.
engine$terminate()
}

\keyword{ package }
\keyword{ programming }
\keyword{ interface }
