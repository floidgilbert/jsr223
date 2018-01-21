
# Public ------------------------------------------------------------------

# Searches the folder recursively for required kotlin*.jar files.
#
# directory - The Kotlin directory.
# minimum - List only the minimum JAR files required for the script engine. If FALSE,
#     all JAR files in the folder will be returned.
getKotlinScriptEngineJars <- function(directory, minimum = TRUE) {
  if (length(directory) != 1)
    stop("Specify a single directory.")
  directory <- formatPath(directory)
  kotlin.jars <- list.files(
    directory,
    ifelse(
      minimum,
      "^kotlin-compiler\\.jar$|^kotlin-script-runtime\\.jar$|^kotlin-stdlib\\.jar$|^kotlin-script-util.*\\.jar$", # kotlin-script-util.jar may have a version number, hence the .*\\.jar pattern
      "^kotlin.*\\.jar$"
    ),
    full.names = TRUE,
    all.files = TRUE,
    recursive = TRUE
  )
  if (
    length(grep("kotlin-compiler\\.jar$", kotlin.jars)) &&
      length(grep("kotlin-script-runtime\\.jar$", kotlin.jars)) &&
    #  length(grep("kotlin-stdlib\\.jar$", kotlin.jars)) &&
      length(grep("kotlin-script-util.*\\.jar$", kotlin.jars))
  )
    return(kotlin.jars)
  stop("The following files are required: 'kotlin-compiler.jar', 'kotlin-script-runtime.jar', 'kotlin-script-util.jar', and 'kotlin-stdlib.jar'.")
}

