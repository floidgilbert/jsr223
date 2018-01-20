
# Public ------------------------------------------------------------------

getKotlinEngineJars <- function(directory) {
  if (length(directory) != 1)
    stop("Specify a single directory.")
  directory <- formatPath(directory, TRUE)
  if (substring(directory, nchar(directory) - 4) != paste0(.Platform$file.sep, "lib", .Platform$file.sep))
    directory <- paste0(directory, "lib", .Platform$file.sep)
  if (!dir.exists(directory))
    stop(sprintf("The directory %s does not exist.", shQuote(directory, type = "sh")))

  # The kotlin-script-util jar has a version number in the name. Find it.
  kotlin.jars <- list.files(directory, "^kotlin-script-util.*")
  kotlin.jars <- c(
    "kotlin-compiler.jar",
    "kotlin-script-runtime.jar",
    "kotlin-stdlib.jar",
    kotlin.jars
  )
  paste0(directory, kotlin.jars)
}

# getKotlinEngineJars("c:\\kotlinc")
# getKotlinEngineJars("c:\\kotlincx")
# getKotlinEngineJars("c:\\kotlinc\\")
# getKotlinEngineJars("c:\\kotlinc\\lib")
# getKotlinEngineJars("c:\\kotlinc\\lib\\")
# formatPath("c:\\kotlinc\\", TRUE)

