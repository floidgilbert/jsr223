source("../R/jsr223/tests/utility.R")

# Bell JS -----------------------------------------------------------------

bellUsingJs <- "
function bellUsingJs(n) {
  var sum = 0;
  function snsk(n, k) {
    if (n == 0 && k == 0)
      return 1;
    else if (n == 0 || k == 0)
      return 0;
    else
      return k * snsk(n - 1, k) + snsk(n - 1, k - 1);
  }
  for (k = 0; k <= n; k++)
    sum = sum + snsk(n, k);
  return sum;
}
"

# Run Simulation ----------------------------------------------------------

# install.packages(c("foreach", "doParallel"))
library("foreach")                   # Library for parallel for loops.
library("doParallel")                # Library providing a parallel backend
registerDoParallel(detectCores())    # Register the parallel backend with as many cores as possible.
nSimulations <- 4
nReps <- 50

simulation <- function (nReps = 2) {
  library("jsr223")
  j <- ScriptEngine$new("js")
  j %~% bellUsingJs
  m <- numeric(0)
  tryCatch(
    {
      for (i in 1:nReps) {
        m <- c(m, j %~% "bellUsingJs(16)")
      }
    }, finally = {
      j$terminate()
    }
  )
  return(m)
}

x <- foreach(k=1:nSimulations, .combine=rbind) %dopar% simulation(nReps)   # Parallel for loop.
x <- as.vector(x)
assertIdentical(rep(10480142147, times = nSimulations * nReps), x)

