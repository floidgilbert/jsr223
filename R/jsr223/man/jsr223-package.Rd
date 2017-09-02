\name{jsr223-package}
\alias{jsr223-package}
\alias{jsr223}

\docType{package}

\title{
A Simple Interface Between R, Java, and Java-Based Scripting Languages JavaScript, Jython (Python), JRuby (Ruby), and Groovy
}

\description{
The R package \CRANpkg{jsr223} is a high-level integration for Java that makes Java objects easy to use from within R and simplifies bi-directional data exchange for a wide variety of objects. Furthermore, \pkg{jsr223} employs the \href{http://docs.oracle.com/javase/8/docs/technotes/guides/scripting/}{Java Scripting API} to bring four scripting languages and, by extension, countless libraries to the R software environment. \pkg{jsr223} uses intuitive syntax to blend JavaScript, Ruby, Python, and Groovy (a Java-like scripting language) with R script.
}

\details{
\pkg{jsr223} requires the Java Runtime Environment (JRE) version 8. Both 64-bit and 32-bit editions are supported. See the vignette///.

\pkg{jsr223} is built on \CRANpkg{rJava}, the low-level R to Java interface. The design of \pkg{jsr223} follows cues from \pkg{rJava}, \CRANpkg{rscala}, and \CRANpkg{V8}.
}

\author{
Floid R. Gilbert \email{floid.r.gilbert@gmail.com}, David B. Dahl \email{dahl@stat.byu.edu}
}

\seealso{
\code{\link{ScriptEngine}}
}
\examples{
# Simple example for embedding JavaScript.
engine <- ScriptEngine$new("javascript")
engine$radius <- 4
engine \%~\% "var area = Math.PI * Math.pow(radius, 2);"
cat ("The area of the circle is ", engine$area, ".\n", sep = "")
engine$terminate()

#///include example of using a Java object. Proabably just do a better example in general that shows the features including lists, data frames, etc.
}

\keyword{ package }
\keyword{ programming }
\keyword{ interface }
