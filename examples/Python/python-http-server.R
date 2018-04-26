# Demonstrate serving R content with a simple Python HTTP server. Run this
# script and point your browser to
#
# http://localhost:8080
#
# or
#
# http://127.0.0.1:8080
#
# This script sources "./python-http-server.py", which starts the HTTP server
# and waits for a GET request. When it receives the request, it calls back to R
# to get an HTML table. It uses this table to generate a page.
#
# The server shuts down automatically after 'server.runtime' seconds. Or, you
# can shut down the server by interrupting R.
#
# This script requires the 'xtable' package to create an HTML table.

library("xtable")
library("jsr223")

# Format the iris data set as an HTML table. This function will be called from
# the Python web server in response to an HTTP GET request.
getHtmlTable <- function() {
  t <- xtable(iris, "Iris Data")
  html <- capture.output(print(t, type = "html", caption.placement = "top"))
  paste0(html, collapse = "\n")
}

# Start the python engine.
engine <- ScriptEngine$new(
  engine.name = "python",
  class.path = "lib/jython-standalone-2.7.0.jar"
)

# Source the Python script.
engine$source("./python-http-server.py", discard.return.value = TRUE)

runServer <- function(server.runtime = 60) {
  # Automatically shut down server and engine when this function exits.
  on.exit(
    {
      engine$invokeMethod("server", "close")
      engine$terminate()
    }
  )

  # Create an instance of Python 'MyServer' class which starts the server at the
  # specified port with the given request timeout in seconds. A timeout would
  # not be used in a production scenario.
  engine %@% "server = MyServer('localhost', 8080, 2)"

  # Handle requests for 'server.runtime' seconds before shutting down. The
  # 'handle_request' method waits for the timeout specified in the 'MyServer'
  # constructor before returning to the event loop to allow interruptions. In a
  # true web service, the R side would not be involved in monitoring requests.
  # See Python's 'SocketServer.serve_forever()' for more information.
  started <- as.numeric(Sys.time())
  while(as.numeric(Sys.time()) - started < server.runtime)
    engine$invokeMethod("server", "handle_request")
}

runServer(10)

