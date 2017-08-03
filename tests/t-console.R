library("jsr223")
js <- startEngine("js")
debug(js$console)
js$console()

#/// do these things. or not. it is a terrible feature.
# Test ESC, CTRL + C, 'exit' (case sensitive) to exit console.

# Test console message...should begin with script language name.



js$terminate()
