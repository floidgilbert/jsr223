library("jsr223")
js <- ScriptEngine$new("js")
# debug(js$console)
js$console()

# Review console message...should begin with script language name.

# Note that the command history doesn't work in practically any console.

# Test ESC, CTRL + C, 'exit' (case sensitive) to exit console.

js$terminate()
