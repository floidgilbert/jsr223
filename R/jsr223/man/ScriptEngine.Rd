\name{ScriptEngine}
\alias{ScriptEngine}
\alias{$<-.ScriptEngine}
\alias{$.ScriptEngine}
\alias{[<-.ScriptEngine}
\alias{[.ScriptEngine}
\alias{[[<-.ScriptEngine}
\alias{[[.ScriptEngine}
\alias{\%~\%}
\alias{\%~\%.ScriptEngine}
\alias{\%@\%}
\alias{\%@\%.ScriptEngine}
%///see if these aliases work

\title{
Create an Instance of a Java-based Scripting Language Engine
}

\description{
The \code{\link{ScriptEngine}} class represents a Java-based script engine. A \code{\link{ScriptEngine}} instance is used to execute arbitrary code and pass data back and forth between the script engine environment and R. The script engine environment contains a global object named \code{R} that facilitates callbacks into the R environment. Complete documentation is found in the vignette///.
}

\usage{
ScriptEngine$new(engine.name, class.path = "")
}

\arguments{
  \item{engine.name}{
A character vector of length one that specifies the type of script engine to create. Valid engine names are \samp{js} or \samp{javascript} for JavaScript, \samp{ruby}, \samp{python}, and \samp{groovy}. The engine name is case sensitive.
}
  \item{class.path}{
A character vector of paths to any JAR files that are required for the scripting engine and any script dependencies. A \var{class.path} value is required for all engines except JavaScript. Scripting engine JAR files can be obtained from the language-specific web sites referenced in the section \strong{Script Engines}. Note that class paths accumulate between script engine instances started in the same R session because they all use the same Java Virtual Machine. This is a limitation of \CRANpkg{rJava}, the package that \pkg{jsr223} builds on.
}
}

\details{
///see vignette. other details. data exchange is not discussed here and it's a big deal.

///callbacks.

///script engines. other sections here.

The bridge between R and the script engine is not thread-safe. Multiple R threads should not simultaneously access the same engine.
}

\value{
An \CRANpkg{R6} class named \code{ScriptEngine} that represents an instance of a Java-based script engine. See the \strong{Script Engine Settings} and \strong{Methods} sections below.
}

\author{
Floid R. Gilbert \email{floid.r.gilbert@gmail.com}, David B. Dahl \email{dahl@stat.byu.edu}
}

\section{Script Engine Settings}{
Several script engine settings are exposed using Java-style getter/setter methods. Other methods are addressed in the \strong{Methods} section.

\describe{
\item{\code{getArrayOrder()}}{
Returns a length-one character vector containing the current array order scheme. See \code{setArrayOrder} for more information.
}

\item{\code{setArrayOrder(value)}}{
Sets the current array ordering scheme used for all n-dimensional arrays (such as matrices) converted to and from the script engine. Valid values are \code{'row-major'} (the default), \code{'column-major'}, and \code{'row-major-java'}. These indexing schemes are described in the ///vig.
}

\item{\code{getCoerceFactors()}}{
Returns a length-one logical vector indicating whether the \var{coerce factors} setting is enabled. See \code{setCoerceFactors} for more information.
}

\item{\code{setCoerceFactors(value)}}{
Enables or disables the \var{coerce factors} setting. Valid values are \code{TRUE} (the default) and \code{FALSE}. When enabled, an attempt is made to coerce R factors to integer, numeric, or logical vectors before converting them to a Java array. If the attempt fails, or if the setting is disabled, the factor is converted to a Java string array. This setting applies to standalone factors as well as factors in data frames.
}

\item{\code{getDataFrameRowMajor()}}{
Returns a length-one logical vector indicating whether the \var{data frame row major} setting is enabled. See \code{setDataFrameRowMajor} for more information.
}

\item{\code{setDataFrameRowMajor(value)}}{
Enables or disables the \var{data frame row major} setting. Valid values are \code{TRUE} (the default) and \code{FALSE}. When enabled, data frames are converted to Java objects in row-major fashion. When disabled, column-major ordering is used. See the vignette for details///.
}

\item{\code{getInterpolate()}}{
Returns a length-one logical vector indicating whether the \var{string interpolation} setting is enabled. See \code{setInterpolate} for more information.
}

\item{\code{setInterpolate(value)}}{
Enables or disables the \var{string interpolation} setting. Valid values are \code{TRUE} (the default) and \code{FALSE}. When enabled, R code placed between \code{@\{} and \code{\}} in a script is evaluated and replaced by the a string representation of the return value. A script may contain multiple \code{@\{...\}} expressions.
}

\item{\code{getLengthOneVectorAsArray()}}{
Returns a length-one logical vector indicating whether the \var{length one vector as array} setting is enabled. See \code{setLengthOneVectorAsArray} for more information.
}

\item{\code{setLengthOneVectorAsArray(value)}}{
Enables or disables the \var{length one vector as array} setting. Valid values are \code{TRUE} and \code{FALSE} (the default). When disabled, length-one R vectors and factors are converted to Java scalars. When enabled, length-one R vectors and factors are converted to Java arrays. This latter effect can also be produced by wrapping the vector in the \dQuote{as-is} function before passing it to the script engine (e.g. \code{engine$myValue <- I(variable)}).
}

\item{\code{getStandardOutputMode()}}{
Returns a length-one character vector containing the current standard output mode. See \code{setStandardOutputMode} for more information.
}

\item{\code{setStandardOutputMode(value)}}{
Controls how text written to standard output is handled. The default value, \code{'console'}, indicates that standard output will be printed in the R console. This output cannot be captured using standard R methods. The \code{'buffer'} setting indicates that standard output will be saved in an internal buffer. This buffered output can be retrieved and cleared using the \code{getStandardOutput} method, or cleared using the \code{clearStandardOutput} method. Finally, the \code{'quiet'} setting indicates that standard output will be discarded.
}

\item{\code{getStringsAsFactors()}}{
Returns a length-one logical vector, or \code{NULL}, indicating whether the \var{strings as factors} setting is enabled. See \code{setStringsAsFactors} for more information.
}

\item{\code{setStringsAsFactors(value)}}{
When converting a Java object to a data frame, the \var{strings as factors} setting controls whether character vectors are converted to factors. The default value of \code{NULL} indicates that the R system setting \code{stringsAsFactors} should be used (see \code{getOption("stringsAsFactors")}). A value of \code{TRUE} ensures that character vectors are converted to factors. A setting of \code{FALSE} disables conversion to factors.
}

}
}

\section{Methods}{

This section includes \code{ScriptEngine} class methods that do not get/set script engine options. See \strong{Script Engine Settings} for information on script engine options.

\describe{

\item{\code{$identifier}}{
Retrieves the global variable named \code{identifier} from the script engine environment. For example, if \code{engine} is a script engine instance, retrieve the value of a variabled named \code{myValue} using \code{engine$myValue}. Quote names that are not valid variable names in R (e.g. engine$`a-3`). This method is equivalent to \code{get(identifier)}.
}

\item{\code{$identifier <- value}}{
Assigns \code{value} to the global variable named \code{identifier} in the script engine environment. The R object contained in \code{value} is converted to a Java object. For example, if \code{engine} is a script engine instance, set the value of a variabled named \code{myValue} using \code{engine$myValue <- 1}. Quote names that are not valid variable names in R (e.g. engine$`a-3` <- 1). This method is equivalent to \code{set(identifier, value)}.
}

\item{\code{\%@\% script}}{
Evaluates code contained in the \code{script} character vector and returns \code{NULL} invisibly. This method is equivalent to using \code{eval(script, discard.return.value = TRUE)}.
}

\item{\code{\%~\% script}}{
Evaluates code contained in the \code{script} character vector and returns the result of the last expression in the script, if any, or \code{NULL} otherwise. This method is equivalent to using \code{eval(script, discard.return.value = FALSE)}.
}

\item{\code{clearStandardOutput()}}{
Empties the script engine's standard output buffer. This method is only useful when the standard output mode has been set to \code{'buffer'}. See the methods \code{getStandardOutputMode} and \code{setStandardOutputMode} in \strong{Script Engine Settings} for more information.
}

\item{\code{compile(script)}}{
Compiles code contained in the \code{script} character vector. Returns a \code{\link{CompiledScript}} object.
}

\item{\code{compileSource(file.name)}}{
Compiles code contained in the file specified by \code{file.name}. Returns a \code{\link{CompiledScript}} object.
}

\item{\code{console()}}{
Starts a simple REPL in the current script language. The REPL is useful for quickly setting and inspecting variables in the script engine. Returned values are printed to the console using \code{base::dput}. Only single-line commands are supported: no line continuations or carriage returns are allowed. Enter \samp{exit} to return to the R prompt.
}

\item{\code{eval(script, discard.return.value = FALSE, bindings = NULL)}}{
Evaluates code contained in the \code{script} character vector. If \code{discard.return.value = FALSE}, the method returns the result of the last expression in the script, if any, or \code{NULL} otherwise. The \code{bindings} argument accepts an R named list. The name/value pairs in the list replace the script engine's global bindings during script execution.///examples here or refer to vig?
}

\item{\code{finalize()}}{
This method is called before the object is garbage-collected to release resources. Do not call this method directly. Use the \code{terminate} method instead.
}

\item{\code{get(identifier)}}{
Retrieves the value of a global variable in the script engine environment. The name of the variable is specified in the length-one character vector \code{identifier}. For example, if \code{engine} is a script engine instance, retrieve the value of a variabled named \code{myValue} using \code{engine$get("myValue")}. This method is equivalent to \code{$identifier}.
}

\item{\code{getBindings()}}{
Lists all of the global variables in the script engine environment. This method returns a named list where the names are the variable names and the values are the respective Java class names.
}

\item{\code{getClassPath()}}{
Returns the class path as a character vector. The class path is set in the \code{ScriptEngine} constructor method. Note that class paths accumulate between script engine instances started in the same R session because they all use the same Java Virtual Machine. This is a limitation of \pkg{rJava}, the package that \pkg{jsr223} builds on.
}

\item{\code{getJavaClassName(identifier)}}{
Retrieves the Java class name of the global variable named \code{identifier} from the script engine environment. This method is equivalent to using \code{$identifier}.
}

\item{\code{getScriptEngineInformation()}}{
Returns a named list containing information about the script engine including the name, language, and version.
}

\item{\code{getStandardOutput()}}{
Returns a character vector of length one containing the contents of the script engine's standard output buffer. The standard output buffer is emptied. This method is only useful when the standard output mode has been set to \code{'buffer'}. See \code{setStandardOutputMode} in \strong{Script Engine Settings} for more information.
}

\item{\code{initialize()}}{
The constructor for this class. Do not call this method directly. Use \code{ScriptEngine$new()} instead.
}

\item{\code{invokeFunction(function.name, ...)}}{
Invoke a function in the script engine environment. The argument \code{function.name} is a character vector containing the name of the function to be called. The \code{...} indicates any number of arguments to be passed to the script function. The return value is the result of the function converted to an R object.
}

\item{\code{invokeMethod(object.name, method.name, ...)}}{
Invoke a method of an object in the script engine environment. The arguments \code{object.name} and \code{method.name} are character vectors containing the names of the object and method, respectively. The \code{...} indicates any number of arguments to be passed to the method. The return value is the result of the method converted to an R object. The Groovy and Python engines can use \code{invokeMethod} to call methods of Java objects. The JavaScript and Ruby engines only support calling methods of native scripting objects.
}

\item{\code{isInitialized()}}{
Returns \code{TRUE} or \code{FALSE} indicating whether the script engine instance is active (i.e., it has not been explicitly terminated).
}

\item{\code{remove(identifier)}}{
Removes a variable from the script engine environment. The name of the variable is specified in the length-one character vector \code{identifier}. For example, if \code{engine} is a script engine instance, remove the variabled named \code{myValue} using \code{engine$remove("myValue")}.
}

\item{\code{set(identifier, value)}}{
Assigns \code{value} to a global variable in the script engine environment. The name of the variable is specified in the length-one character vector \code{identifier}. The R object \code{value} is converted to a Java object. For example, if \code{engine} is a script engine instance, set the value of a variabled named \code{myValue} using \code{engine$set("myValue", 1)}. This method is equivalent to \code{$identifier <- value)}.
}

\item{\code{source(file.name, discard.return.value = FALSE, bindings = NULL)}}{
Evaluates code contained in the file specified by the length-one character vector \code{file.name}. If \code{discard.return.value = FALSE}, the method returns the result of the last expression in the script, if any, or \code{NULL} otherwise. The \code{bindings} argument accepts an R named list. The name/value pairs in the list replace the script engine's global bindings during script execution.///examples here or refer to vig?
}

\item{\code{terminate()}}{
Terminates the script engine instance and releases associated resources. Call this method when the script engine is no longer needed.
}

}
}

\section{Callbacks}{
Embedded scripts can access the R environment using the \pkg{jsr223} callback interface. When a script engine is started, \pkg{jsr223} creates a global object named \code{R} in the script engine's environment. This object is used to execute R code and set/get variables in the R session's global environment. Infinite recursive calls between R and the script engine are supported. The only limitation is available stack space.

To set a variable in the R global environment, use

\code{engine \%@\% "R.set('a', [1, 2, 3])"}

To retrieve a variable from the R global environment, use

\code{engine \%~\% "R.get('a')"}

Finally, to evaluate R code, use

\code{engine \%~\% "R.eval('rnorm(1)')"}

\strong{Note:} Changing any of the data exchange settings will affect the behavior of the callback interface. For example, using \code{engine$setLengthOneVectorAsArray(TRUE)} will cause \code{R.get("pi")} to return an array with a single element instead of a scalar value.
}

\section{Script Engines}{
The \pkg{jsr223} package supports the following Java-based languages. Follow a link below to visit the language's supporting web site and to download script engine JAR files. Detailed instructions can be found ///vig.

\href{http://groovy-lang.org}{Groovy} -- A Java-like language enhanced with modern dynamic programming features.

\href{https://docs.oracle.com/javase/8/docs/technotes/guides/scripting/nashorn/}{JavaScript (Nashorn)} -- Nashorn is the JavaScript dialect included in Java 8 and above. No download or \var{class.path} parameter is required to use JavaScript with \pkg{jsr223}.

\href{http://jruby.org}{JRuby} -- A Java-based implementation of the Ruby programming language.

\href{http://jython.org}{Jython} -- A Java-based implementation of the Python programming language.
}

\seealso{
\code{\link{CompiledScript}}
}
\examples{
library("jsr223")

# Create an instance of a JavaScript engine. Note that the
# script engine's JAR file is not required for the class.path
# parameter because JavaScript is included with JRE 8.
engine <- ScriptEngine$new(engine.name = "javascript")

# Evaluate arbitrary code. Multiline code is allowed.
engine \%~\% "var a = Math.PI;"

# Retrieve the value of a global JavaScript variable.
cat("The value of 'a' is ", engine$a, ".", sep = "")

# Set the value of a global variable. If the variable does
# not exist in the engine environment, it will be created.
engine$a <- 10
cat("The value of 'a' is now ", engine$a, ".", sep = "")

# Use callbacks to set values, get values, and execute R code
# in the current R session via the global R object.
engine \%@\% "R.set('a', 12);"
cat("The value of 'a' is now ", engine \%~\% "R.get('a');", ".", sep = "")
engine \%@\% "var randomNormal = R.eval('rnorm(5)');"
engine$randomNormal

# Use a Java object.
engine \%@\% "java.util.Arrays.sort(randomNormal)"
engine$randomNormal

# Enable property to convert length one vectors to arrays
# instead of scalar values.
engine$setLengthOneVectorAsArray(TRUE)
engine$c <- 1
engine \%~\% "c[0]" # Returns 1
engine$setLengthOneVectorAsArray(FALSE)

# Suppress console output.
engine$setStandardOutputMode("quiet")
engine \%~\% "print('Hello (1)');"

# Re-enable console output
engine$setStandardOutputMode("console")
engine \%~\% "print('Hello (2)');"

# Terminate the engine.
engine$terminate()

\dontrun{
# Create a JRuby engine by specifying the engine name and
# the class path for the engine JAR. The JAR file path
# will be different on your system.
engine <- ScriptEngine$new(
  engine.name = "jruby"
  , class.path = "../engines/jruby-complete.jar"
)

# Assign a value to a variable. This will create a global
# variable in the Ruby environment.
engine$c <- pi

# Reference the previous value in a code snippet. Note that
# Ruby requires a "$" designator for global variables.
engine \%~\% "3 * $c"

# Evaluate a script file.
engine$source("./my_script.rb")

# Terminate the engine.
engine$terminate()
}
}

\keyword{ programming }
\keyword{ interface }
