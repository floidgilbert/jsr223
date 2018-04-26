\name{getKotlinScriptEngineJars}
\alias{getKotlinScriptEngineJars}

\title{
Search for Required Kotlin JAR Files
}

\description{
The \code{\link{getKotlinScriptEngineJars}} function searches a directory recursively for \file{kotlin*.jar} files required to create an instance of the Kotlin script engine. Because Kotlin does not provide a standalone script engine JAR file, we include this convenience function to simplify adding JAR files to the class path.
}

\usage{
getKotlinScriptEngineJars(
  directory,
  minimum = TRUE
)
}

\arguments{
  \item{directory}{
A character vector of length one specifying a path that contains Kotlin script engine JAR files.
}
  \item{minimum}{
A logical vector of length one. When \code{TRUE} (the default), the function returns only the minimum required JAR files to instantiate a script engine. If \code{FALSE}, all JAR files of the pattern \file{kotlin*.jar} will be returned.
}
}

\details{
The function searches the given directory recursively. If one or more of the required JAR files are not found, the function throws an error with a message listing the required files.

As of this writing, a standalone Kotlin compiler installation does not contain all of the required files to create a script engine instance. See section ``Script engine installation and instantiation'' in the \href{../doc/jsr223.pdf}{User Manual} for more information.
}

\value{
A character vector containing paths to the JAR files.
}

\seealso{
\code{\link{ScriptEngine}}
}

\examples{
\dontrun{
library("jsr223")
jars <- getKotlinScriptEngineJars("~/my-path/kotlin")
engine <- ScriptEngine$new("kotlin", jars)
engine \%~\% "1 + 1"
engine$terminate()
}
}

\keyword{ interface }
