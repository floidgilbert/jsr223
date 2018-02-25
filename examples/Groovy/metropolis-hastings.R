#  ------------------------------------------------------------------------
library("jsr223")
library("xtable")

class.path <- c(
  "D:\\Offline\\Work\\jsr223\\engines\\groovy-all-2.4.7.jar",
  "D:\\Offline\\Work\\jsr223\\examples\\org.fgilbert.jsr223.examples-0.3.0.jar",
  "D:\\Offline\\Work\\jsr223\\examples\\commons-math3-3.6.1.jar"
)

engine <- ScriptEngine$new("Groovy", class.path)

# Initial values for four seperate chains
starting.values <- rbind(
  c(0.999, 0.001)
  , c(0.001, 0.001)
  , c(0.001, 30)
  , c(0.999, 30)
)

bindings <- list(
  alpha = 1,
  beta = 1,
  theta = 2,
  kappa = 1,
  data = as.integer(c(rep(0, 25), rep(1, 6), rep(2, 4), rep(3, 3), 5)),
  proposalVariances = c(0.5^2, 1.2^2),
  startingValues = starting.values,
  iterations = 10000L,
  threads = parallel::detectCores()
)
cs <- engine$compileSource("metropolis-hastings.groovy")
r <- cs$eval(bindings = bindings)


# Benchmark ---------------------------------------------------------------
microbenchmark::microbenchmark(cs$eval(bindings = bindings), times = 50L)


# Summarize MCMC Results --------------------------------------------------
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

xt <- xtable(df, label = "tab:abc", digits = 3, display = c("d", "s", "d", "f", "f", "f", "f", "f", "f", "d"))
print(xt, include.rownames = FALSE, caption.placement = "top")

