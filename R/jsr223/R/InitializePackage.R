.onLoad <- function(libname, pkgname) {
  # Load jdx package without using Depends in DESCRIPTION file. I need to load
  # jdx so the related Java libraries are in the class path. Without this line
  # we will have the error
  # "java.lang.NoClassDefFoundError: org/fgilbert/jdx/JavaToR"
  o <- jdx::convertToJava(NULL)

  # Required rJava initialization routine.
  rJava::.jpackage(pkgname, lib.loc = libname)
}
