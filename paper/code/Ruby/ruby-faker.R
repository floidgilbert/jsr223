# Demonstrate integration with a Ruby gem. This example uses Benjamin Curtis's
# faker gem to generate "real-looking" test data. https://github.com/stympy/faker

library("jsr223")

# Install the faker gem using
#   gem install faker
# 
# In addition to the JRuby script engine JAR, include all of the required gem
# paths in the class path. In this case, we use 'jruby.jar' from the full
# installation instead of the standalone script engine JAR file.
# 
# The gem paths are obtained by running the JRuby REPL 'jirb' in the terminal
# and executing the following two commands:
# 
# require 'faker'
# puts $LOAD_PATH
# 
# IMPORTANT: If a folder such as "site_ruby" does not exist, it will prevent the
# engine from starting. Simply remove any such folders from the class path list.

class.path <- "
C:/jruby-9.1.12.0/lib/jruby.jar
C:/jruby-9.1.12.0/lib/ruby/gems/shared/gems/i18n-0.8.6/lib
C:/jruby-9.1.12.0/lib/ruby/gems/shared/gems/faker-1.8.4/lib
C:/jruby-9.1.12.0/lib/ruby/stdlib
"
class.path <- unlist(strsplit(class.path, "\n", fixed = TRUE))

engine <- ScriptEngine$new(
  engine.name = "jruby",
  class.path = class.path
)

# Import the required Ruby libraries.
engine %@% "require 'faker'"

# To create data deterministically, set a seed.
engine %@% "Faker::Config.random = Random.new(10)"

# Demonstrate unique, fake name.
engine %~% "Faker::Name.unique.name"

# Define a Ruby function to return a given number of fake profiles.
engine %@% "
def random_profile(n = 1)
  fname = Array.new(n)
  lname = Array.new(n)
  title = Array.new(n)
  for i in 0..(n - 1)
    fname[i] = Faker::Name.unique.first_name
    lname[i] = Faker::Name.unique.last_name
    title[i] = Faker::Name.unique.title
  end
  return {'fname' => fname, 'lname' => lname, 'title' => title}
end
"

# Retrieve 10 fake profiles. The Ruby hash of same-length arrays will be
# automatically converted to a dataframe.
engine$invokeFunction("random_profile", 5)

engine$terminate()
