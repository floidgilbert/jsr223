
# CompiledScript R6 Class -------------------------------------------------

CompiledScript <- R6::R6Class("CompiledScript",

  private = list(
    compiled.script = NULL
    , engine.private = NULL
  )

  , public = list(

    # R6 class constructor
    initialize = function(engine.private, script) {
      if (length(script) != 1L || !is.character(script))
        stop("'script' must be a character vector of length 1.")
      if (engine.private$interpolate)
        script <- strintrplt(script, envir = parent.frame(n = 3))
      private$compiled.script <- rJava::.jcall(engine.private$controller, "Ljavax/script/CompiledScript;", "compileScript", script)
      private$engine.private <- engine.private
    }

    , eval = function(discard.return.value = FALSE, bindings = NULL) {
      engine.private <- private$engine.private
      if (is.null(bindings)) {
        rJava::.jcall(engine.private$controller, "V", "putEvaluationRequest", private$compiled.script, discard.return.value)
      } else {
        names <- names(bindings)
        if (!is.list(bindings) || length(names) == 0)
          stop("'bindings' requires a named list.")
        if ("R" %in% names)
          stop("The identifier 'R' is reserved.")
        # It is not necessary to set scalars.as.objects for lists. It is handled automatically.
        rJava::.jcall(engine.private$controller, "V", "putEvaluationRequest", private$compiled.script, discard.return.value, jdx::convertToJava(bindings, length.one.vector.as.array = engine.private$length.one.vector.as.array, coerce.factors = engine.private$coerce.factors, row.major = engine.private$row.major))
      }
      engine.private$processEvaluationResponse()
    }
  )

  , active = NULL
  , class = TRUE
  , cloneable = FALSE
  , lock_class = TRUE
  , lock_objects = TRUE
)

# CompiledScript S3 Interface ---------------------------------------

names.CompiledScript <- function(x, ...){
  ls(x, ...)
}

print.CompiledScript <- function(x, ...) {
  cat("CompiledScript\n")
  invisible(x)
}

toString.CompiledScript <- function(x, ...) {
  "CompiledScript"
}

