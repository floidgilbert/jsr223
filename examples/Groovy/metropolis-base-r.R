# This script is an R-only implementation of a generic Metropolis sampler that
# is comparable to the one referenced in the `metropolis.R` script. This R
# script was used for a performance comparison against the Groovy and Java
# examples.

#  ------------------------------------------------------------------------

metropolisSamplerUnivariateProposal <- function(log.posterior, starting.values, proposal.functions, iterations, discard, cores) {

  # Validate
  parameter.count <- length(proposal.functions)
  if (!is.function(log.posterior))
    stop("The argument 'log.posterior' must be a function.")
  if (parameter.count == 0)
    stop("Invalid number of proposal distributions. There is a one-to-one relationship between the number of parameters and proposal distributions.")
  if (dim(starting.values)[2] != parameter.count)
    stop("This statement must be true 'dim(starting.values)[2] == length(proposal.functions)'. That is, there must be a proposal distribution for each parameter.")
  if (iterations < 1)
    stop("The value 'iterations' must be greater than zero.")
  if (discard < 0 || discard >= iterations)
    stop("The value 'discard' must be zero or greater and less than 'iterations'.")
  if (cores < 1)
    stop("The value 'cores' must be greater than zero.")
  chain.count <- dim(starting.values)[1]

  mcmc <- function(starting.values) {
    chains = array(0, c(iterations - discard, parameter.count))
    proposals.accepted = integer(parameter.count)
    state <- starting.values
    proposal <- starting.values
    probability.ratio <- 0
    log.posterior.state <- log.posterior(starting.values)
    log.posterior.proposal <- 0

    if (discard == 0)
      chains[1, ] <- starting.values
    for (i in 2:iterations) {
      for (j in 1:parameter.count) {
        proposal[j] <- proposal.functions[[j]](state[j])
        log.posterior.proposal <- log.posterior(proposal)
        probability.ratio <- log.posterior.proposal - log.posterior.state
        if (is.nan(probability.ratio))
          probability.ratio <- -Inf
        if (probability.ratio >= log(runif(1))) {
          state[j] <- proposal[j]
          log.posterior.state <- log.posterior.proposal
          proposals.accepted[j] <- proposals.accepted[j] + 1
        } else {
          proposal[j] <- state[j]
        }
      }
      if (i > discard)
        chains[i - discard, ] <- state
    }
    list(
      acceptance_rates = proposals.accepted / iterations
      , chains = chains
    )
  }

  cluster <- parallel::makeCluster(cores)
  tryCatch (
    r <- parallel::parApply(cluster, starting.values, 1, mcmc)
    , finally = parallel::stopCluster(cluster)
  )
  chains <- sapply(1:chain.count, function(i) r[[i]]$chains)
  chains <- array(chains, c(iterations - discard, parameter.count, chain.count))
  list(
    acceptance_rates = sapply(1:chain.count, function(i) r[[i]]$acceptance_rates)
    , chains = chains
  )
}

makePosterior <- function(alpha, beta, theta, kappa, data) {

  data.length <- length(data)
  data.zero.count <- length(data[data == 0])
  data.positive.count <- data.length - data.zero.count
  data.sum <- sum(data)

  function(values) {
    pi <- values[1]
    lambda <- values[2]
    if (pi <= 0 || pi >= 1 || lambda < 0)
      return(-Inf)
    (alpha - 1) * log(pi) + (beta - 1) * log(1 - pi) +
      (theta - 1) * log(lambda) - kappa * lambda +
      data.zero.count * log(pi + (1 - pi) * exp(-lambda)) +
      data.positive.count * log((1 - pi) * exp(-lambda)) +
      data.sum * log(lambda)
  }

}

logPosterior <- makePosterior(1, 1, 2, 1, as.integer(c(rep(0, 25), rep(1, 6), rep(2, 4), rep(3, 3), 5)))

starting.values <- rbind(
  c(0.999, 0.001),
  c(0.001, 0.001),
  c(0.001, 30),
  c(0.999, 30)
)

proposal.functions <- list(
  function(x) {rnorm(1, x, sqrt(0.5^2))}
  , function(x) {rnorm(1, x, sqrt(1.7^2))}
)

iterations <- 10000L
discard <- as.integer(iterations * 0.20)
cores <- parallel::detectCores()

r <- metropolisSamplerUnivariateProposal(logPosterior, starting.values, proposal.functions, iterations, discard, cores)

# View dimensions of the chains - iteration, parameter, walk
dim(r$chains)

# Show the head of the first random walk
parameter.names <- c("pi", "lambda")
dimnames(r$chains) <- list(NULL, parameter.names, NULL)
head(r$chains[, , 1])

# Review the acceptance rates for each chain.
r$acceptance_rates <- t(r$acceptance_rates)
colnames(r$acceptance_rates) <- parameter.names
r$acceptance_rates

# Benchmarks --------------------------------------------------------------

doBenchmarks <- function() {
  benchmark.iterations <- 40L
  benchmark.warmup <- 2L
  benchmark.control <- list(warmup = benchmark.warmup)
  mcmc.iterations <- c(10000L, 100000L, 1000000L)

  f1 <- function(iterations, discard.return.value) {
    discard <- 0L
    micro <- microbenchmark::microbenchmark(
      r <- metropolisSamplerUnivariateProposal(logPosterior, starting.values, proposal.functions, iterations, discard, cores),
      times = benchmark.iterations,
      control = benchmark.control
    )
    mean(micro$time) / 1000000
  }

  mean.time.with.return.values <- sapply(mcmc.iterations, f1, FALSE)

  m <- cbind(
    mcmc.iterations,
    mean.time.with.return.values
  )
  colnames(m) <- c("Iterations", "Run time 1")

  xt <- xtable::xtable(m, label = "tab:abc", digits = 3, display = c("d", "d", "f"))
  xtable::print.xtable(xt, include.rownames = FALSE, caption.placement = "top")

  m
}

(b1 <- doBenchmarks())

