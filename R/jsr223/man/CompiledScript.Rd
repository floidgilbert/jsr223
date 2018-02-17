\docType{class}
\name{CompiledScript}
\alias{CompiledScript}

\title{
CompiledScript Class
}

\description{
The \code{\link{CompiledScript}} class represents script compiled by a script engine.
}

\usage{
CompiledScript
}

\details{
CompiledScript does not have a public constructor. Create an instance of this class with the \code{\link{ScriptEngine}} methods \code{compile} and \code{compileSource}.

The complete \pkg{jsr223} documentation can be found in the \href{../doc/jsr223.pdf}{vignette}.
}

\value{
Object of \code{\link{R6Class}} that represents a compiled script.
}

\section{Methods}{
\describe{

\item{\code{eval(discard.return.value = FALSE, bindings = NULL)}}{
Executes the compiled code referenced by the object. If \code{discard.return.value = FALSE}, the method returns the result of the last expression in the script, if any, or \code{NULL} otherwise. The \code{bindings} argument accepts an R named list. The name/value pairs in the list replace the script engine's global bindings during script execution.
}

}
}

\seealso{
\code{\link{ScriptEngine}}
}
\examples{
library("jsr223")
engine <- ScriptEngine$new("javascript")

# Compile a code snippet.
cs <- engine$compile("c + d")

# This line would throw an error because 'c' and 'd' have not yet been declared.
## cs$eval()

engine$c <- 2
engine$d <- 3
cs$eval()

## 5

# Supply new bindings...
lst <- list(c = 6, d = 7)
cs$eval(bindings = lst)

## 13

# When 'bindings' is not specified, the script engine reverts to the original
# environment.
cs$eval()

## 5

# The following line executes the code but discards the return value.
cs$eval(discard.return.value = TRUE)

# Terminate the engine.
engine$terminate()
}

\keyword{ programming }
\keyword{ interface }
