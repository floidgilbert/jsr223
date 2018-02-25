library("jsr223")
engine <- ScriptEngine$new("groovy", "~/my-path/groovy-all.jar")
tryCatch (
  engine$source(commandArgs(TRUE)[1], discard.return.value = TRUE),
  error = function(e) { cat(e$message, "\n", sep = "") },
  finally = { engine$terminate() }
)
