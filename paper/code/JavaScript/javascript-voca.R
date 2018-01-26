# Demonstrate the use of voca.js, "The ultimate JavaScript string library".
# https://vocajs.com/
#
# These examples were adapted from the Voca documentation.

library("jsr223")
engine <- ScriptEngine$new("js")

# Source the Voca library. This creates a utility object named 'v'.
# engine$source("./voca.min.js", discard.return.value = TRUE)
engine$source("https://raw.githubusercontent.com/panzerdp/voca/1.3.0/dist/voca.min.js", discard.return.value = TRUE)

# 'prune' truncates string, without break words, ensuring the given length, including
# a trailing "..."
engine %~% "v.prune('A long string to prune.', 12);"

## [1] "A long..."

# Provide a different suffix to 'prune'.
engine %~% "v.prune('A long string to prune.', 16, ' (more)');"

## [1] "A long (more)"

# Voca supports method chaining.
engine %~% "
v('Voca chaining example')
  .lowerCase()
  .words()
"

## [1] "voca"     "chaining" "example"

# Split graphemes.
engine %~% "v.graphemes('cafe\u0301');"

## [1] "c" "a" "f" "é"

# Word wrapping.
engine %~% "v.wordWrap('A long string to wrap', {width: 10});"

## [1] "A long\nstring to\nwrap"

# Word wrapping with custom delimiters.
engine %~% "
v.wordWrap(
  'A long string to wrap',
  {
    width: 10,
    newLine: '<br/>',
    indent: '__'
  }
);
"

## [1] "__A long<br/>__string to<br/>__wrap"

engine$terminate()
