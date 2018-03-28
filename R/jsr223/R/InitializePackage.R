.onLoad <- function(libname, pkgname) {
  # Load jdx package without using Depends in DESCRIPTION file. I need to load
  # jdx so the related Java libraries are in the class path. Without this line
  # we will have the error
  # "java.lang.NoClassDefFoundError: org/fgilbert/jdx/JavaToR"
  o <- jdx::convertToJava(NULL)

  # Required rJava initialization routine.
  rJava::.jpackage(pkgname, lib.loc = libname)

  # Check Java version.
  # See https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Writing-portable-packages
  v <- rJava::.jcall("java/lang/System", "S", "getProperty", "java.runtime.version")
  if(substr(v, 1L, 2L) == "1.") {
    v <- as.numeric(paste0(strsplit(v, "[.]")[[1L]][1:2], collapse = "."))
    if(v < 1.8) stop("Java 8 or above is required for this package.")
  }
}
