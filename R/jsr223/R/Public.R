
# Public ------------------------------------------------------------------

# Searches a folder recursively for required kotlin*.jar files.
#
# directory - The Kotlin directory.
# minimum - List only the minimum JAR files required for the script engine. If FALSE,
#     all JAR files in the folder will be returned.
getKotlinScriptEngineJars <- function(directory, minimum = TRUE) {
  if (length(directory) != 1)
    stop("Specify a single directory.")
  directory <- formatPath(directory)
  required.files <- c('kotlin-compiler.jar', 'kotlin-script-runtime.jar', 'kotlin-script-util.jar', 'kotlin-stdlib.jar')
  pattern <- paste0("^", paste0(required.files, collapse = "$|^"), "$")
  pattern <- gsub(".", "\\.", pattern, fixed = TRUE)
  kotlin.jars <- list.files(
    directory,
    ifelse(
      minimum,
      pattern,
      "^kotlin.*\\.jar$"
    ),
    full.names = TRUE,
    all.files = TRUE,
    recursive = TRUE
  )
  for (f in required.files) {
    if (length(grep(gsub(".", "\\.", f, fixed = TRUE), kotlin.jars)) == 0)
      stop(sprintf("One or more required files were not found. The required files are %s.", paste0(sQuote(required.files), collapse = ", ")))
  }
  kotlin.jars
}

