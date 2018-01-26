# Demonstrate using a Ruby gem. This example examines stocks using Ty Rauber's
# stock_quote gem.

library("jsr223")
library("jsonlite")
library("ggplot2")

# In addition to the script engine JAR, include all of the required gem paths in
# the class path. In this case, we use 'jruby.jar' from the full installation 
# instead of the standalone script engine JAR file.
# 
# The gem paths were obtained by running the JRuby REPL 'jirb' in the terminal
# and executing the following two commands:
# 
# require 'stock_quote'
# puts $LOAD_PATH

class.path <- "
C:/jruby-9.1.5.0/lib/jruby.jar
C:/jruby-9.1.5.0/lib/ruby/gems/shared/gems/unf-0.1.4-java/lib
C:/jruby-9.1.5.0/lib/ruby/gems/shared/gems/domain_name-0.5.20160826/lib
C:/jruby-9.1.5.0/lib/ruby/gems/shared/gems/http-cookie-1.0.3/lib
C:/jruby-9.1.5.0/lib/ruby/gems/shared/gems/mime-types-2.99.3/lib
C:/jruby-9.1.5.0/lib/ruby/gems/shared/gems/netrc-0.11.0/lib
C:/jruby-9.1.5.0/lib/ruby/gems/shared/gems/rest-client-1.8.0/lib
C:/jruby-9.1.5.0/lib/ruby/gems/shared/gems/stock_quote-1.2.3/lib
C:/jruby-9.1.5.0/lib/ruby/stdlib
"
class.path <- unlist(strsplit(class.path, "\n", fixed = TRUE))

engine <- startEngine(
  engine.name = "jruby",
  class.path = class.path
)

# Import the required Ruby libraries.
engine %@% "
require 'date'
require 'stock_quote'
"

# Print some real-time stock data to the console.
engine %@% "
$stock = StockQuote::Stock.quote('AEPGX')
puts $stock.name, $stock.change
"

# Ruby function to retrieve a year of closing stock prices for a given symbol in
# JSON format.
engine %@% "
def getStockYear(symbol)
  end_date = Date.today
  start_date = end_date.prev_year
  h = StockQuote::Stock.history(
    symbol,
    start_date = start_date,
    end_date = end_date,
    select = 'Close, Date',
    format = 'json'
  )
  return JSON.generate(h.fetch('quote'))
end
"

# R function wrapper to convert the Ruby JSON result to a data frame.
getStockYear <- function(symbol) {
  json <- engine$invokeFunction("getStockYear", symbol)
  df <- jsonlite::fromJSON(json)
  df$Close <- as.numeric(df$Close)
  df$Date <- as.POSIXct(df$Date)
  df
}

# Get closing values as data frames for two stocks.
aepgx <- getStockYear("AEPGX")
agthx <- getStockYear("AGTHX")

# Graph the closing values via 'ggplot2'.
ggplot() +
  geom_line(data = aepgx, aes(x = Date, y = Close, color = "AEPGX")) +
  geom_line(data = agthx, aes(x = Date, y = Close, color = "AGTHX")) +
  ggtitle("Closing Stock Prices: AEPGX, AGTHX") +
  theme(legend.position = c(0.1, 0.9), legend.title = element_blank()) +
  labs(x = "Date", y = "Closing Price")

engine$terminate()
