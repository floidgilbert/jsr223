# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //
#
#  Stanford CoreNLP example
#
# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //

# Demonstrate the use of Stanford Natural Language Processor via JavaScript.
# 
# To run the example, download Stanford CoreNLP from
# https://stanfordnlp.github.io/CoreNLP/ Set the variable
# `stanford.installation.folder` to the path of the installation folder.
#
# Note: The Stanford Parser takes a moment to load the first time. It outputs
# a message that looks like a warning when it loads. That is normal behavior.
# 
# The first few lines here are different than the paper example only in that we 
# include code to locate the required JAR files for the class path. This is
# simpler for you to run the example, especially if the CoreNLP version changes,
# but it requires more code. We chose to keep the code in the paper focused on
# the package's functionality instead of path-parsing.

# Set this path to the Stanford CoreNLP installation folder.
stanford.installation.folder <- "~/stanford-corenlp-full-2018-01-31"

# This code will locate the appropriate dependencies.
file.patterns <- paste0(
  "protobuf\\.jar|",
  "stanford-corenlp-\\d+\\.\\d+\\.\\d+\\.jar|",
  "stanford-corenlp-\\d+\\.\\d+\\.\\d+-models\\.jar"
)
class.path <- list.files(stanford.installation.folder, file.patterns)
class.path <- file.path(stanford.installation.folder, class.path)
class.path <- normalizePath(class.path, winslash = "/")

# Now we return to the paper's example verbatim.
library("jsr223")
engine <- ScriptEngine$new("JavaScript", class.path)

# Declare JavaScript function `getPartsOfSpeech`
{
  engine %@% '
    var DocumentClass = Java.type("edu.stanford.nlp.simple.Document");

    function getPartsOfSpeech(text) {
      var doc = new DocumentClass(text);
      var list = [];
      for (i = 0; i < doc.sentences().size(); i++) {
        var sentence = doc.sentences().get(i);
        var o = {
          "words":sentence.words(),
          "pos.tag":sentence.posTags(),
          "offset.begin":sentence.characterOffsetBegin(),
          "offset.end":sentence.characterOffsetEnd()
        }
        list.push(o);
      }
      return list;
    }
  '
}

engine$invokeFunction(
  "getPartsOfSpeech",
  "The jsr223 package makes Java objects easy to use. Download it from CRAN."
)

engine$terminate()


# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //
#
#  Metropolis sampler example
#
# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //

# This script requires 'metropolis.groovy' and some JAR files which can be 
# downloaded using the following link. We would have included these files in our
# submission, but the web form would not accept the larger file (~8 MB). Please
# extract the contents, preserving folder structure, to the same folder as
# 'gilbert-dahl.R'. A folder 'lib' should be created containing the required
# files.
# 
# To run this section of the script, please set the current working directory 
# to the folder containing this script ('gilbert-dahl.R').
#
# The example demonstrates dynamic code behavior by extending an abstract Java
# class, MetropolisSamplerUnivariateProposal. The class defines an abstract
# method, logPosterior, that can be implemented in script (Groovy, in this
# case).
#
# This example also demonstrates script compiling.
#
# The basic idea: We are performing a Bayesian analysis for a zero-inflated
# Poisson model with priors pi ~ Beta and lambda ~ Gamma. We wish to draw
# samples from the posterior using a multi-threaded Java class that implements
# the Metropolis algorithm.
#
# See comments in this script and 'lib/metropolis.groovy' for more
# information.
#
# The Java sampler classes are located on Github under
# examples/Java/org.fgilbert.jsr223.examples.

#  ------------------------------------------------------------------------
library("jsr223")

class.path <- c(
  "lib/groovy-all-2.4.7.jar",
  "lib/org.fgilbert.jsr223.examples-0.3.0.jar"
)

engine <- ScriptEngine$new("Groovy", class.path)

# The sampler takes initial values for each chain. Each chain can be run on a
# separate thread. The parameters are pi (0 <= pi <= 1) and lambda (0 =>
# lambda).
starting.values <- rbind(
  c(0.999, 0.001),
  c(0.001, 0.001),
  c(0.001, 30),
  c(0.999, 30)
)

# Set global variables in the Groovy environment.
#
# `alpha`, `beta` are parameters for the pi ~ Beta `theta`, and `kappa` are
# parameters for the lambda ~ Gamma prior. The are used to define the posterior
# function.
#
# `data` is an array of the data values. In this case, counts.
#
# `proposalVariances` are the variance parameters for the proposal distributions
# (both univariate Gaussian).
#
# `startingValues` are the starting values for each random walk.
#
# `iterations` are the number of iterations for each random walk.
#
# `threads` the number of threads to use. Chains are allocated to threads. If
# there are more chains than threads, the threads will be recycled.

engine$alpha <- 1
engine$beta <- 1
engine$theta <- 2
engine$kappa <- 1
engine$data <- as.integer(c(rep(0, 25), rep(1, 6), rep(2, 4), rep(3, 3), 5))
engine$proposalVariances <- c(0.3^2, 1.2^2)
engine$startingValues <- starting.values
engine$iterations <- 10000L
engine$discard <- as.integer(engine$iterations * 0.20)
engine$threads <- parallel::detectCores()

# Set the array order to get the results in the form we like. See the
# documentation for more information on array order settings.
engine$setArrayOrder("column-minor")

# Compile the Groovy script to Java byte code. This approach is recommended only
# for unstructured code: not methods or functions. For the latter, call them
# directly from R using engine$invokeMethod or engine$invokeFunction.
cs <- engine$compileSource("lib/metropolis.groovy")

# Execute the compiled code.
r <- cs$eval()

# View dimensions of the chains - iteration, parameter, walk
dim(r$chains)

# Show the head of the first random walk
parameter.names <- c("pi", "lambda")
dimnames(r$chains) <- list(NULL, parameter.names, NULL)
head(r$chains[, , 1])

# Review the acceptance rates for each chain.
colnames(r$acceptance_rates) <- parameter.names
r$acceptance_rates

# Let's say that we find the acceptance rates to be a little too high. We need
# to widen the variance for the proposal distributions. We simply update the
# corresponding variable and execute the compiled code again. We do not need to
# recompile the script.
engine$proposalVariances <- c(0.5^2, 1.7^2)
r <- cs$eval()

# Review the acceptance rates for each chain again.
colnames(r$acceptance_rates) <- parameter.names
r$acceptance_rates

# Summarize MCMC Results in a table ---------------------------------------

parameter.count <- length(parameter.names)
chain.count <- dim(r$chains)[3]

table <- matrix(0, parameter.count * chain.count, 8)
table.row <- 0
for (parm.idx in 1:parameter.count) {
  for (chain.idx in 1:chain.count) {
    chain <- r$chains[ , parm.idx, chain.idx]
    table.row <- table.row + 1
    table[table.row, ] <- cbind(
      chain.idx,
      t(quantile(chain, c(0.025, 0.25, 0.50, 0.75, 0.975))),
      r$acceptance_rates[chain.idx, parm.idx],
      coda::effectiveSize(chain)
    )
  }
}

df <- data.frame(rep(parameter.names, each = chain.count), table)
colnames(df) <- c("Parameter", "Chain", "2.5%", "25%", "50%", "75%", "97.5%", "Acc. Rate", "ESS")
df

xt <- xtable::xtable(df, label = "tab:abc", digits = 3, display = c("d", "s", "d", "f", "f", "f", "f", "f", "f", "d"))
xtable::print.xtable(xt, include.rownames = FALSE, caption.placement = "top")

# Benchmarks --------------------------------------------------------------

# IMPORTANT: This section will take several minutes to run. Reduce
# `benchmark.iterations` to reduce run time.

doBenchmarks <- function(cs) {
  benchmark.iterations <- 40L
  benchmark.warmup <- 2L
  benchmark.control <- list(warmup = benchmark.warmup)
  mcmc.iterations <- c(10000L, 100000L, 1000000L)

  f1 <- function(iterations, discard.return.value) {
    engine$iterations <- iterations
    engine$discard <- 0L
    m <- microbenchmark::microbenchmark(cs$eval(discard.return.value), times = benchmark.iterations, control = benchmark.control)
    mean(m$time) / 1000000
  }

  mean.time.with.return.values <- sapply(mcmc.iterations, f1, FALSE)

  mean.time.without.return.values <- sapply(mcmc.iterations, f1, TRUE)

  m <- cbind(
    mcmc.iterations,
    mean.time.with.return.values,
    mean.time.without.return.values,
    mean.time.with.return.values - mean.time.without.return.values
  )
  colnames(m) <- c("Iterations", "Run time 1", "Run time 2", "Difference")

  xt <- xtable::xtable(m, label = "tab:abc", digits = 3, display = c("d", "d", "f", "f", "f"))
  xtable::print.xtable(xt, include.rownames = FALSE, caption.placement = "top")

  m
}

(b1 <- doBenchmarks(cs))

{
  script <- "
  import org.fgilbert.jsr223.examples.MetropolisSamplerZeroInflatedPoisson;
  import org.fgilbert.jsr223.examples.ProposalDistributionUnivariateNormal;

  ProposalDistributionUnivariateNormal[] pd =
  new ProposalDistributionUnivariateNormal[proposalVariances.length];
  for (int i = 0; i < proposalVariances.length; i++)
  pd[i]	= new ProposalDistributionUnivariateNormal(proposalVariances[i]);

  MetropolisSamplerZeroInflatedPoisson sampler = new MetropolisSamplerZeroInflatedPoisson(alpha, beta, theta, kappa, data);
  sampler.sample(startingValues, pd, iterations, discard, threads);
  "
}

(b2 <- doBenchmarks(engine$compile(script)))

# Done --------------------------------------------------------------------

engine$terminate()


# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //
#
#  JavaScript Voca example
#
# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //

engine <- ScriptEngine$new("JavaScript")
engine$source(
  "https://raw.githubusercontent.com/panzerdp/voca/master/dist/voca.min.js",
  discard.return.value = TRUE
)
engine$invokeMethod(
  "v",
  "wordWrap",
  "A long sentence to wrap using Voca methods.",
  list(width = 20)
)
engine$terminate()


# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //
#
#  rJava software review
#
# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //

# rJava demonstration taken from http://www.rforge.net/rJava --------------

# Note: the GUI window may appear in the background.
library("rJava")
.jinit()
f <- .jnew("java/awt/Frame", "Hello")
b <- .jnew("java/awt/Button", "OK")
.jcall(f, "Ljava/awt/Component;", "add", .jcast(b, "java/awt/Component"))
.jcall(f, , "pack")
# Show the window.
.jcall(f, , "setVisible", TRUE)
# Close the window.
.jcall(f, , "dispose")


# rJava demonstration reproduced in JavaScript and jsr223 -----------------

library(jsr223)
engine <- ScriptEngine$new("JavaScript")

# Execute code inline to create and show the window.
engine %@% "
  var f = new java.awt.Frame('Hello');
  f.add(new java.awt.Button('OK'));
  f.pack();
  f.setVisible(true);
"

# Close the window
engine %@% "f.dispose();"


# rJava data exchange -----------------------------------------------------

a <- matrix(rnorm(10), 5, 2)
# Copy matrix to a Java object with rJava
o <- .jarray(a, dispatch = TRUE)
# Convert it back to an R matrix.
b <- .jevalArray(o, simplify = TRUE)
identical(a, b)


# jsr223 data exchange ----------------------------------------------------

a <- matrix(rnorm(10), 5, 2)
# Copy an R object to Java using jsr223.
engine$a <- a
# Retrieve the object.
engine$a
identical(a, engine$a)
engine$terminate()


# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //
#
#  rGroovy software review
#
# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //

# Typical rGroovy approach ------------------------------------------------

# Class paths must set in the global option GROOVY_JARS before
# loading the rGroovy package.
class.path <- normalizePath("lib/groovy-all-2.4.7.jar", winslash = "/")
options(GROOVY_JARS = list(class.path))
library("rGroovy")

# rGroovy uses rJava API by default. A bindings object must be created for the
# bindings available to the Groovy script engine.
bindings <- rJava::.jnew("groovy/lang/Binding")
Initialize(bindings)
myValue <- rJava::.jarray(1:3)
myValue <- rJava::.jcast(myValue, "java/lang/Object")
rJava::.jcall(bindings, "V", method = "setVariable", "myValue", myValue)

# Finally, Groovy code can be executed using the Evaluate method; it returns the
# value of the last statement, if any. In this example, we modify the last
# element of our myValue array, and return the contents of the array.
Evaluate(groovyScript = "myValue[2] = 5; myValue;")


# Foregoing code reproduced by jsr223 -------------------------------------

library("jsr223")
engine <- ScriptEngine$new("Groovy", "lib/groovy-all-2.4.7.jar")
engine$myValue <- 1:3
engine %~% "myValue[2] = 5; myValue"


# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //
#
#  JavaScript integrations software review
#
# /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// //

# Demonstrate that JSON data exchange loses precision ---------------------

# jsonlite is used by V8 as well as many other packages.
library("jsonlite")
# `digits = NA` requests maximum precision.
identical(pi, fromJSON(toJSON(pi, digits = NA)))


# Demonstrate that jsr223 data exchange preserves precision ---------------

library("jsr223")
engine <- ScriptEngine$new("JavaScript")
engine$pi <- pi
identical(engine$pi, pi)

