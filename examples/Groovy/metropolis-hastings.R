# This script requires 'metropolis-hastings.groovy' which can be located in the
# same folder. The required JAR files can be found in the root of the examples
# folder.
#
# The example demonstrates dynamic code behavior by extending an abstract Java
# class, MhSamplerUnivariateProposal. The class defines an abstract method,
# logPosterior, that can be implemented in script (Groovy, in this case).
#
# This example also demonstrates script compiling and dynamic bindings.
#
# The basic idea: We are performing a Bayesian analysis for a zero-inflated
# Poisson model with Beta and Gamma priors. The parameters of interest are pi
# and lambda. We wish to draw samples from the posterior using a
# high-performance, multi-threaded Java class that implements the
# Metropolis-Hasting algorithm.
#
# See comments in this script and 'metropolis-hastings.groovy' for more
# information.
#
# The Java Metropolis-Hasting sampler classes are located in
# examples/Java/org.fgilbert.jsr223.examples.

#  ------------------------------------------------------------------------
library("jsr223")

class.path <- c(
  "~/groovy-all-2.4.7.jar",
  "~/org.fgilbert.jsr223.examples-0.3.0.jar",
  "~/commons-math3-3.6.1.jar"
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
# `alpha`, `beta`, `theta`, and `kappa` are parameters for the Beta and Gamma
# priors, respectively. The are used to define the posterior function.
#
# `data` is an array of the data values. In this case, counts.
#
# `proposalVariances` are the variance parameters for the proposal distributions
# (both Gaussian).
#
# `startingValues` are the starting values for each chain.
#
# `iterations` are the number of iterations for each chain.
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
engine$threads <- parallel::detectCores()

# Compile the Groovy script to Java byte code. This approach is recommended only
# for unstructured code (i.e., code not encapsulated in methods or functions).
# Otherwise, define functions/methods and call them with engine$invokeMethod or
# engine$invokeFunction.
cs <- engine$compileSource("metropolis-hastings.groovy")

# Execute the compiled code.
r <- cs$eval()

# Review the acceptance rates for each chain.
getAcceptanceRatios <- function(r, names) {
  acc <- sapply(r, function(mcmc) mcmc[["acceptance-ratios"]])
  rownames(acc) <- names
  acc
}
getAcceptanceRatios(r, c("pi", "lambda"))

# Let's say that we find the acceptance ratios to be a little too high. We need
# to widen the variance for the proposal distributions. We simply update the
# corresponding variable and execute the compiled code again. We do not need to
# recompile the script.
engine$proposalVariances <- c(0.5^2, 1.5^2)
r <- cs$eval()

# Review the acceptance rates for each chain again.
getAcceptanceRatios(r, c("pi", "lambda"))

# Benchmark ---------------------------------------------------------------

# Display the timings for evaluation.
microbenchmark::microbenchmark(cs$eval(), times = 20L)

# Display the timings for evaluation when return value is discarded. This shows
# about how much time is required to convert the Java data strucutures to R
# objects.
microbenchmark::microbenchmark(cs$eval(discard.return.value = TRUE), times = 20L)

# Summarize MCMC Results in a table ---------------------------------------

parameter.names <- c("pi", "lambda")
parameter.count <- length(parameter.names)
chain.count <- length(r)
keep <- (bindings$iterations * 0.20 + 1):bindings$iterations

table <- matrix(0, parameter.count * chain.count, 8)
table.row <- 0
for (parm.idx in 1:parameter.count) {
  for (chain.idx in 1:chain.count) {
    s <- r[[chain.idx]]
    chain <- s$chains[keep, parm.idx]
    table.row <- table.row + 1
    table[table.row, ] <- cbind(
      chain.idx,
      t(quantile(chain, c(0.025, 0.25, 0.50, 0.75, 0.975))),
      s$`acceptance-ratios`[parm.idx],
      coda::effectiveSize(chain)
    )
  }
}

df <- data.frame(rep(parameter.names, each = chain.count), table)
colnames(df) <- c("Parameter", "Chain", "2.5%", "25%", "50%", "75%", "97.5%", "Acc. Ratio", "ESS")
df

xt <- xtable::xtable(df, label = "tab:abc", digits = 3, display = c("d", "s", "d", "f", "f", "f", "f", "f", "f", "d"))
xtable::print.xtable(xt, include.rownames = FALSE, caption.placement = "top")

engine$terminate()
