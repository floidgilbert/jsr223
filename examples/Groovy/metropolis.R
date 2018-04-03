# This script requires 'metropolis.groovy' which can be located in the
# same folder. The required JAR files can be found in the root of the examples
# folder.
#
# The example demonstrates dynamic code behavior by extending an abstract Java
# class, MetropolisSamplerUnivariateProposal. The class defines an abstract
# method, logPosterior, that can be implemented in script (Groovy, in this
# case).
#
# This example also demonstrates script compiling and dynamic bindings.
#
# The basic idea: We are performing a Bayesian analysis for a zero-inflated
# Poisson model with Beta and Gamma priors. The parameters of interest are pi
# and lambda. We wish to draw samples from the posterior using a
# high-performance, multi-threaded Java class that implements the
# Metropolis and Metropolis-Hastings algorithms.
#
# See comments in this script and 'metropolis.groovy' for more
# information.
#
# The Java sampler classes are located in
# examples/Java/org.fgilbert.jsr223.examples.

#  ------------------------------------------------------------------------
library("jsr223")

class.path <- c(
  "lib/groovy-all-2.4.7.jar",
  "lib/org.fgilbert.jsr223.examples-0.3.0.jar",
  "lib/commons-math3-3.6.1.jar"
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
# for unstructured code (i.e., code not encapsulated in methods or functions).
# Otherwise, define functions/methods and call them with engine$invokeMethod or
# engine$invokeFunction.
cs <- engine$compileSource("metropolis.groovy")

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

doBenchmarks <- function(cs) {
  benchmark.iterations <- 20L
  benchmark.warmup <- 4L
  benchmark.control <- list(warmup = benchmark.warmup)
  mcmc.iterations <- c(10000L, 100000L, 1000000L)

  f1 <- function(iterations, discard.return.value) {
    engine$iterations <- iterations
    engine$discard <- 0L
    micro <- microbenchmark::microbenchmark(cs$eval(discard.return.value), times = benchmark.iterations, control = benchmark.control)
    median(micro$time) / 1000000
  }

  median.time.with.return.values <- sapply(mcmc.iterations, f1, FALSE)

  median.time.without.return.values <- sapply(mcmc.iterations, f1, TRUE)

  m <- cbind(
    mcmc.iterations,
    median.time.with.return.values,
    median.time.without.return.values,
    median.time.with.return.values - median.time.without.return.values
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

