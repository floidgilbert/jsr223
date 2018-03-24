# Initialize --------------------------------------------------------------

library("shiny")
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
  # c(0.001, 30),
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
engine$proposalVariances <- c(0.5^2, 1.7^2)
engine$startingValues <- starting.values
engine$iterations <- 20000L
engine$discard <- as.integer(engine$iterations * 0.10)
engine$threads <- parallel::detectCores()

# Set the array order to get the results in the form we like. See the
# documentation for more information on array order settings.
engine$setArrayOrder("column-minor")

# Compile the Groovy script to Java byte code. This approach is recommended only
# for unstructured code (i.e., code not encapsulated in methods or functions).
# Otherwise, define functions/methods and call them with engine$invokeMethod or
# engine$invokeFunction.
cs <- engine$compileSource("metropolis.groovy")

# Shiny -------------------------------------------------------------------

ani <- animationOptions(300, TRUE)

ui <- fluidPage(
  titlePanel("Sensitivity Analysis"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput(
        "betaShape1",
        "pi prior - Beta shape 1:",
        min = 0.001,
        max = 5,
        value = 1,
        step = 0.1,
        animate = ani
      ),
      sliderInput(
        "betaShape2",
        "pi prior - Beta shape 2:",
        min = 0.001,
        max = 5,
        value = 1,
        step = 0.1,
        animate = ani
      ),
      sliderInput(
        "gammaShape",
        "lambda prior - Gamma shape:",
        min = 0.001,
        max = 10,
        value = 2,
        step = 0.1,
        animate = ani
      ),
      sliderInput(
        "gammaRate",
        "lambda prior - Gamma rate:",
        min = 0.001,
        max = 10,
        value = 1,
        step = 0.1,
        animate = ani
      )
    ),
      
    mainPanel(
      plotOutput("plot", height = "800px"),
      div(tableOutput("table"), style = "font-size:200%")
    )
  )
)

server <- function(input, output) {
  output$plot <- renderPlot(
    {
      engine$alpha <- input$betaShape1
      engine$beta <- input$betaShape2
      engine$theta <- input$gammaShape
      engine$kappa <- input$gammaRate
      r <- cs$eval()
      pi <- as.vector(r$chains[(-1):(-engine$iterations * 0.10), 1, ])
      lambda <- as.vector(r$chains[(-1):(-engine$iterations * 0.10), 2, ])
      par(mfrow = c(4, 1))
      curve(dbeta(x,  input$betaShape1, input$betaShape2), 0, 1, ylab = "", xlab = "", main = "Beta", col = "darkorange3", lwd = 2)
      curve(dgamma(x, input$gammaShape, rate = input$gammaRate), 0, 15, ylab = "", xlab = "", main = "Gamma", col = "firebrick", lwd = 2)
      q <- c(0.025, 0.5, 0.975)
      qtable <- rbind(pi = quantile(pi, q), lambda = quantile(lambda, q))
      qtable <- cbind(qtable, Width = qtable[, 3] - qtable[, 1])
      output$table <- renderTable(qtable, rownames = TRUE, digits = 2)
      hist(pi, breaks = 50, freq = FALSE, main = "pi", xlab = "", xlim = c(0, 1), col = "orange")
      abline(v = qtable[1, 1:3], lwd = 2)
      hist(lambda, breaks = 50, freq = FALSE, main = "lambda", xlab = "", xlim = c(0, 4), col = "darkolivegreen1")
      abline(v = qtable[2, 1:3], lwd = 2)
      par(mfrow = c(1, 1))
    }
  )
}

# Run the application 
shinyApp(ui = ui, server = server)
