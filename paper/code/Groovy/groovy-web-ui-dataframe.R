#///execute this with the source file directory.
##////change extension back to groovy.
#tell them that they must restart R if they want to re-run the whole thing. just terminating the engine won't do it.

# library("jsr223")
# engine <- startEngine("groovy", "../../../engines/groovy-all-2.4.7.jar")
# tryCatch (
#   {
#     engine$source("./groovy-web-ui-dataframe.groovy", discard.return.value = TRUE)
#     html.file <- paste0("file://localhost/", getwd(), "/groovy-web-ui-dataframe.html")
#     engine$invokeMethod("controller", "edit", "mtcars data frame", html.file, mtcars) #///this can be called as many times as you please.
#     engine$invokeFunction("exitJavaFx")
#   },
#   error = function(e) { cat(e$message, "\n", sep = "") },
#   finally = { engine$terminate(); rm(engine); gc() }
# )
# 
# 


# 123 ---------------------------------------------------------------------

library("jsr223")
engine <- startEngine("groovy", "../../../engines/groovy-all-2.4.7.jar")
engine$source("D:/Gdrive/Work/jsr223/java/org.fgilbert.jsr223/src/nodist/GroovyTemp.java", discard.return.value = TRUE)
html.file <- paste0("file://localhost/", getwd(), "/groovy-web-ui-dataframe.html")
engine$setDataFrameRowMajor(TRUE) #///explain


# abc ---------------------------------------------------------------------

d <- data.frame(name = row.names(mtcars), mtcars)
d.names <- names(d)
integer.columns <- c("cyl", "hp", "vs", "am", "gear", "carb")
for (col in d.names) {
  if (col %in% integer.columns)
    d[[col]] <- as.integer(d[[col]])
}
d.edit <- NULL
d.edit <- engine$invokeMethod(
  "controller",
  "edit",
  html.file,
  "Motor Trend Cars Data Set",
  d
)

# Handsontable returns the columns in alphabetical order. Re-order based on the
# original.
if(!is.null(d.edit))
  d.edit <- d.edit[, d.names]

invisible(d.edit)

# def ---------------------------------------------------------------------


# engine$invokeMethod("controller", "terminate")
# engine %@% "println(thread.getState());"
# engine$terminate(); rm(engine); gc()


# engine %~% "dfe.queue.clear();"
# engine %~% "dfe.queue.size();"
# engine %~% "dfe.queue.take();"
