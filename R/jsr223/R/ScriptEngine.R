# All org.fgilbert.jsr223 methods that would otherwise return data or an object
# return a data type code in a 32-bit integer that corresponds to data type
# flags in the jdx package. This type code is used by the jdx package to quickly
# retrieve data from the JVM and construct the appropriate R object. While
# cumbersome and unintuitive, this approach improves performance considerably.

# ScriptEngine R6 Class ---------------------------------------------------

ScriptEngine <- R6::R6Class("ScriptEngine",

  private = list(

    controller = NULL # Initialized in constructor
    , controller.j2r = NULL # Initialized in constructor

    , coerce.factors = DEFAULT_COERCE_FACTORS
    , data.frame.row.major = DEFAULT_DATA_FRAME_ROW_MAJOR
    , interpolate = DEFAULT_INTERPOLATE
    , JDX_ARRAY_ORDER = NULL # Initialized in constructor
    , JDX_SC_USER_DEFINED = NULL # Initialized in constructor
    , length.one.vector.as.array = DEFAULT_LENGTH_ONE_VECTOR_AS_ARRAY
    , script.engine.information = list()
    , STANDARD_OUTPUT_CONSOLE = NULL # Initialized in constructor
    , STANDARD_OUTPUT_QUIET = NULL # Initialized in constructor
    , STANDARD_OUTPUT_BUFFER = NULL # Initialized in constructor
    , strings.as.factors = DEFAULT_STRINGS_AS_FACTORS # NULL means to use system default

    # IMPORTANT: This method throws warnings! If any warning handler is in
    # place, execution will be interrupted when a warning is propagated.
    , getDataCodeVector = function(data.code) {
      jdx::processCompositeDataCode(private$controller.j2r, data.code)
    }

    , getResponseValue = function(data.code) {
      jdx::convertToRlowLevel(j2r = private$controller.j2r, data.code = data.code, strings.as.factors = private$strings.as.factors)
    }

    , processEvaluationResponse = function() {
      repeat {
        data.code <- private$getDataCodeVector(rJava::.jcall(private$controller, "I", "waitForEvaluation"))
        if (data.code[2] != private$JDX_SC_USER_DEFINED) {
          break
        } else if (data.code[4] == CALLBACK_EVALUATION) {
          value <- rJava::.jcall(private$controller.j2r, "S", "getValueString", check = FALSE)
          tryCatch(
            {
              value <- base::eval(parse(text = value), envir = globalenv())
              private$putJavaValue(null, value, TRUE)
            }
            , error = function(e) {
              rJava::.jcall(private$controller, "V", "putCallbackResponseError", toString(e), check = FALSE)
            }
          )
        } else if (data.code[4] == CALLBACK_GET_VALUE) {
          value <- rJava::.jcall(private$controller.j2r, "S", "getValueString", check = FALSE)
          tryCatch(
            {
              value <- base::get(value, envir = globalenv())
              tryCatch(
                {
                  private$putJavaValue(null, value, TRUE)
                }
                , error = function(e) {
                  rJava::.jcall(private$controller, "V", "putCallbackResponseError", toString(e), check = FALSE)
                }
              )
            }
            , error = function(e) {
              # If the value name is not found, return Java null.
              rJava::.jcall(private$controller, "V", "putCallbackResponse", rJava::.jnull(), check = FALSE)
            }
          )
        } else if (data.code[4] == CALLBACK_SET_VALUE) {
          value <- rJava::.jcall(private$controller, "[Ljava/lang/String;", "getResponseCallbackSetValue")
          tryCatch(
            {
              # IMPORTANT: private$getDataCodeVector can throw a warning! If a
              # tryCatch handler is in place anywhere it will interrupt
              # execution and cause the Controller to get out of sync and freeze.
              base::assign(
                value[1]
                , private$getResponseValue(private$getDataCodeVector(as.integer(value[2])))
                , envir = globalenv())
              rJava::.jcall(private$controller, "V", "putCallbackResponse", rJava::.jnull(), check = FALSE)
            }
            , error = function(e) {
              rJava::.jcall(private$controller, "V", "putCallbackResponseError", toString(e), check = FALSE)
            }
          )
        } else {
          stop(sprintf("Unexpected evaluation response: (type:0x%X, structure:0x%X).", data.code[1], data.code[2]))
        }
      }
      result <- private$getResponseValue(data.code)
      if (is.null(result)) {
        return(invisible())
      } else {
        return(result)
      }
    }

    , putJavaValue = function(identifier, value, is.response.value) {
      if (is.response.value) {
        rJava::.jcall(private$controller, "V", "putCallbackResponse", jdx::convertToJava(value, scalars.as.objects = FALSE, length.one.vector.as.array = private$length.one.vector.as.array, array.order = private$array.order, data.frame.row.major = private$data.frame.row.major, coerce.factors = private$coerce.factors))
      } else {
        rJava::.jcall(private$controller, "V", "setScriptEngineValue", identifier, jdx::convertToJava(value, scalars.as.objects = FALSE, length.one.vector.as.array = private$length.one.vector.as.array, array.order = private$array.order, data.frame.row.major = private$data.frame.row.major, coerce.factors = private$coerce.factors))
      }
    }

    , readFile = function(file.name) {
      if (length(file.name) != 1L || !is.character(file.name))
        stop("'file.name' must be a character vector of length 1 containing a valid script file name.")
      file.name <- trimws(file.name)
      if (!file.exists(file.name))
        stop(sprintf("The file '%s' could not be found or does not exist.", file.name))
      file.chars <- readChar(file.name, file.info(file.name)$size)
      if (!nzchar(file.chars[1]))
        stop("The file is empty.")
      file.chars
    }

  )

  , public = list(

    # R6 class constructor
    initialize = function(engine.name, class.path = "") {
      if (length(engine.name) != 1L || !is.character(engine.name))
        stop("'engine.name' must be a character vector of length 1 containing a valid engine script name.")
      engine.name <- trimws(engine.name)
      if (!is.character(class.path))
        stop("'class.path' must be a character vector.")
      if (length(class.path) > 0L) {
        class.path <- trimws(unlist(strsplit(class.path, .Platform$path.sep, fixed = TRUE)))
        class.path <- class.path[nzchar(class.path)]
        if (length(class.path) > 0L) {
          rJava::.jaddClassPath(class.path)
          for (p in class.path) {
            if (!file.exists(p))
              stop(sprintf("The file %s specified in the class path does not exist.", shQuote(p, type = "sh")))
          }
        }
      }

      # Intialize private members. These operations cannot be done in R6Class(private = list(...)).
      private$controller <- rJava::.jnew("org/fgilbert/jsr223/Controller", engine.name)
      private$controller.j2r <- rJava::.jcall(private$controller, "Lorg/fgilbert/jdx/JavaToR;", "getResponse")
      jdx.constants <- jdx::jdxConstants()
      private$JDX_ARRAY_ORDER <- jdx.constants$ARRAY_ORDER
      private$JDX_SC_USER_DEFINED <- jdx.constants$SC_USER_DEFINED
      private$STANDARD_OUTPUT_CONSOLE <- rJava::.jfield("org.fgilbert.jsr223.Controller$StandardOutputMode", sig = NULL, "CONSOLE")
      private$STANDARD_OUTPUT_QUIET <- rJava::.jfield("org.fgilbert.jsr223.Controller$StandardOutputMode", sig = NULL, "QUIET")
      private$STANDARD_OUTPUT_BUFFER <- rJava::.jfield("org.fgilbert.jsr223.Controller$StandardOutputMode", sig = NULL, "BUFFER")

      self$setArrayOrder(DEFAULT_ARRAY_ORDER)
      self$setStandardOutputMode(DEFAULT_STANDARD_OUTPUT_MODE)

      # Populate engine information list
      m <- rJava::.jcall(private$controller, "[[Ljava/lang/String;", "getEngineInformation", evalArray = TRUE, simplify = TRUE)
      for (i in 1:(dim(m)[2])) {
        private$script.engine.information[[m[1, i]]] <- m[2, i]
      }
    }

    , finalize = function() {
      self$terminate()
    }

    # Setters/getters. Java-style get*/set* methods are used instead of active
    # bindings (i.e. object properties) to avoid confusion and coding complexity
    # with respect to the `$` and `$<-` S3 methods that we use to set values in
    # the script engine.

    , getArrayOrder = function() {
      jdx::arrayOrderToString(
        rJava::.jcall(private$controller, "Lorg/fgilbert/jdx/JavaToR$ArrayOrder;", "getArrayOrder")
      )
    }

    , setArrayOrder = function(value) {
      order <- private$JDX_ARRAY_ORDER[[value]]
      if (is.null(order))
        stop(sprintf("Valid array order values are 'column-major', 'row-major', and 'row-major-java'."))
      r <- self$getArrayOrder()
      rJava::.jcall(private$controller, "V", "setArrayOrder", order)
      invisible(r)
    }

    , getCoerceFactors = function() {
      private$coerce.factors
    }

    , setCoerceFactors = function(value) {
      if (!is.logical(value) || length(value) != 1L)
        stop("A TRUE or FALSE value is required.")
      r <- private$coerce.factors
      private$coerce.factors <- value
      invisible(r)
    }

    , getDataFrameRowMajor = function() {
      private$data.frame.row.major
    }

    , setDataFrameRowMajor = function(value) {
      if (!is.logical(value) || length(value) != 1L)
        stop("A TRUE or FALSE value is required.")
      r <- private$data.frame.row.major
      private$data.frame.row.major <- value
      invisible(r)
    }

    , getInterpolate = function() {
      private$interpolate
    }

    , setInterpolate = function(value) {
      if (!is.logical(value) || length(value) != 1L)
        stop("A TRUE or FALSE value is required.")
      r <- private$interpolate
      private$interpolate <- value
      invisible(r)
    }

    , getLengthOneVectorAsArray = function() {
      private$length.one.vector.as.array
    }

    , setLengthOneVectorAsArray = function(value) {
      if (!is.logical(value) || length(value) != 1L)
        stop("A TRUE or FALSE value is required.")
      r <- private$length.one.vector.as.array
      private$length.one.vector.as.array <- value
      invisible(r)
    }

    , getStandardOutputMode = function() {
      mode <- rJava::.jcall(private$controller, "Lorg/fgilbert/jsr223/Controller$StandardOutputMode;", "getStandardOutputMode")
      if (rJava::.jequals(mode, private$STANDARD_OUTPUT_CONSOLE))
        return("console")
      if (rJava::.jequals(mode, private$STANDARD_OUTPUT_QUIET))
        return("quiet")
      "buffer"
    }

    , setStandardOutputMode = function(value) {
      mode <- switch (value,
        console = private$STANDARD_OUTPUT_CONSOLE
        , quiet = private$STANDARD_OUTPUT_QUIET
        , buffer = private$STANDARD_OUTPUT_BUFFER
        , ... = NULL
      )
      if (is.null(mode))
        stop(sprintf("Valid standard output modes are 'console', 'quiet', or 'buffer'."))
      r <- self$getStandardOutputMode()
      rJava::.jcall(private$controller, "V", "setStandardOutputMode", mode)
      invisible(r)
    }

    , getStringsAsFactors = function() {
      private$strings.as.factors
    }

    , setStringsAsFactors = function(value) {
      if (!is.null(value) && (!is.logical(value) || is.na(value) || length(value) != 1L))
        stop("A TRUE, FALSE, or NULL value is required.")
      r <- private$strings.as.factors
      private$strings.as.factors <- value
      invisible(r)
    }

    # Public methods.

    , clearStandardOutput = function() {
      rJava::.jcall(private$controller, "V", "clearStandardOutput")
    }

    , compile = function(script) {
      CompiledScript$new(private, script)
    }

    , compileSource = function(file.name) {
      self$compile(private$readFile(file.name))
    }

    #///argument 1 (type 'list') cannot be handled by 'cat'. try something besides cat. Maybe that one thing that prints out structures...
    #///maybe bail on this all together.
    # Thanks to Jeroen Ooms and the V8 package for the idea...
    , console = function() {
      message("\n", self$getScriptEngineInformation()$language.name, " console. Press ESC, CTRL + C, or enter 'exit' to exit the console.")
      on.exit(message("Exiting console."))

      # IMPORTANT: savehistory / loadhistory does not work as expected in all consoles or on all platforms.
      tryCatch(
        {
          r.history <- "rhistory"
          jsr223.history <- "jsr223history"
          save.dir <- setwd(tempdir()) # savehistory / loadhistory does not always seem to respect full paths, so change directory...
          utils::savehistory(r.history) # According to Ooms, OSX R.app does not support savehistory
          if (!file.exists(jsr223.history)) {
            file.create(jsr223.history)
            write("", jsr223.history, append = TRUE)
          }
          utils::loadhistory(jsr223.history)
          setwd(save.dir)
          on.exit(
            {
              save.dir <- setwd(tempdir()) # savehistory / loadhistory does not always seem to respect full paths, so change directory...
              utils::savehistory(jsr223.history)
              utils::loadhistory(r.history)
              setwd(save.dir)
            }
            , add = TRUE
          )
          has.history <- TRUE
        }
        , error = function(e) {
          # According to Ooms, OSX R.app does not support savehistory.
          has.history <- FALSE
        }
      )

      # REPL
      # NOTE: Only single-line commands are supported. Because JSR223 does not
      # include a facility for validation, there is not a reliable way to
      # determine whether a command is complete.
      repeat {
        line <- readline("~ ")
        if (identical(line, "exit"))
          break
        if (has.history) {
          save.dir <- setwd(tempdir()) # savhistory / loadhistory does not always seem to respect full paths, so change directory...
          write(line, jsr223.history, append = TRUE)
          utils::loadhistory(jsr223.history)
          setwd(save.dir)
        }
        tryCatch(
          cat(self$eval(line), "\n", sep = "")
          , error = function(e) {
            message(e$message)
          }
        )
      }
    }

    # If 'discard.return.value' is TRUE, 'waitForEvaluation' will indicate NULL
    # unless there is an error or a callback.
    , eval = function(script, discard.return.value = FALSE, bindings = NULL) {
      if (length(script) != 1L || !is.character(script))
        stop("'script' must be a character vector of length 1.")
      if (private$interpolate)
        script <- strintrplt(script, envir = parent.frame(n = 2))
      if (is.null(bindings)) {
        rJava::.jcall(private$controller, "V", "putEvaluationRequest", script, discard.return.value)
      } else {
        names <- names(bindings)
        if (!is.list(bindings) || length(names) == 0)
          stop("'bindings' requires a named list.")
        if ("R" %in% names)
          stop("The identifier 'R' is reserved.")
        # It is not necessary to set scalars.as.objects for lists. It is handled automatically.
        rJava::.jcall(private$controller, "V", "putEvaluationRequest", script, discard.return.value, jdx::convertToJava(bindings, length.one.vector.as.array = private$length.one.vector.as.array, array.order = private$array.order, data.frame.row.major = private$data.frame.row.major, coerce.factors = private$coerce.factors))
      }
      private$processEvaluationResponse()
    }

    , get = function(identifier) {
      if (exists(identifier, where = self, inherits = FALSE) || identifier == "R")
        stop(sprintf("The identifier '%s' is reserved.", identifier))
      data.code <- private$getDataCodeVector(rJava::.jcall(private$controller, "I", "getScriptEngineValue", identifier))
      private$getResponseValue(data.code)
    }

    , getBindings = function() {
      data.code <- private$getDataCodeVector(rJava::.jcall(private$controller, "I", "getBindings"))
      private$getResponseValue(data.code)
    }

    , getClassPath = function() {
      rJava::.jclassPath()
    }

    , getJavaClassName = function(identifier) {
      if (exists(identifier, where = self, inherits = FALSE))
        stop(sprintf("The identifier '%s' is reserved.", identifier))
      rJava::.jcall(private$controller, "S", "getScriptEngineValueClassName", identifier)
    }

    , getScriptEngineInformation = function() {
      private$script.engine.information
    }

    , getStandardOutput = function() {
      rJava::.jcall(private$controller, "Ljava/lang/String;", "getStandardOutput")
    }

    , invokeFunction = function(function.name, ...) {
      if (length(function.name) != 1L || !is.character(function.name))
        stop("'function.name' must be a character vector of length 1.")
      arguments <- rJava::.jarray(lapply(list(...), jdx::convertToJava, scalars.as.objects = TRUE, length.one.vector.as.array = private$length.one.vector.as.array, array.order = private$array.order, data.frame.row.major = private$data.frame.row.major, coerce.factors = private$coerce.factors))
      rJava::.jcall(private$controller, "V", "putInvokeFunctionRequest", function.name, arguments)
      private$processEvaluationResponse()
    }

    , invokeMethod = function(object.name, method.name, ...) {
      if (length(object.name) != 1L || !is.character(object.name))
        stop("'object.name' must be a character vector of length 1.")
      if (length(method.name) != 1L || !is.character(method.name))
        stop("'method.name' must be a character vector of length 1.")
      arguments <- rJava::.jarray(lapply(list(...), jdx::convertToJava, scalars.as.objects = TRUE, length.one.vector.as.array = private$length.one.vector.as.array, array.order = private$array.order, data.frame.row.major = private$data.frame.row.major, coerce.factors = private$coerce.factors))
      rJava::.jcall(private$controller, "V", "putInvokeMethodRequest", object.name, method.name, arguments)
      private$processEvaluationResponse()
    }

    # Returns FALSE after 'terminate' method is called.
    , isInitialized = function() {
      rJava::.jcall(private$controller, "Z", "isInitialized")
    }

    , remove = function(identifier) {
      if (exists(identifier, where = self, inherits = FALSE) || identifier == "R")
        stop(sprintf("The identifier '%s' is reserved.", identifier))
      rJava::.jcall(private$controller, "Z", "removeScriptEngineValue", identifier)
    }

    , set = function(identifier, value) {
      if (exists(identifier, where = self, inherits = FALSE) || identifier == "R")
        stop(sprintf("The identifier '%s' is reserved.", identifier))
      private$putJavaValue(identifier, value, FALSE)
    }

    , source = function(file.name, discard.return.value = FALSE, bindings = NULL) {
      self$eval(private$readFile(file.name), discard.return.value = discard.return.value, bindings = bindings)
    }

    , terminate = function() {
      # Does not throw error if already terminated.
      rJava::.jcall(private$controller, "V", "terminate")
    }

  )

  , class = TRUE
  , cloneable = FALSE
  , lock_class = TRUE
  , lock_objects = TRUE
)

# ScriptEngine S3 Interface -----------------------------------------------

names.ScriptEngine <- function(x, ...){
  ls(x, ...)
}

print.ScriptEngine <- function(x, ...) {
  cat("ScriptEngine\n")
  invisible(x)
}

toString.ScriptEngine <- function(x, ...) {
  "ScriptEngine"
}

# Retrieve a value in the script engine.
`$.ScriptEngine` <- function(engine, identifier) {
  if (exists(identifier, where = engine, inherits = FALSE))
    return(base::get(identifier, envir = engine, inherits = FALSE))
  # If the identifier is not part of the environment, query the script engine for a binding.
  base::get("get", envir = engine, inherits = FALSE)(identifier)
}

# Set a value in the script engine.
`$<-.ScriptEngine` <- function(engine, identifier, value) {
  base::get("set", envir = engine, inherits = FALSE)(identifier, value)
  invisible(engine) # Prevents engine from being modified during assignment operation (i.e. engine$identifier <- value).
}

# Override the default environment behavior of engine[["identifier"]] and engine["identifier"].
`[[.ScriptEngine` <- `$.ScriptEngine`
`[.ScriptEngine` <- `$.ScriptEngine`
`[[<-.ScriptEngine` <- `$<-.ScriptEngine`
`[<-.ScriptEngine` <- `$<-.ScriptEngine`

# Evaluate a script contained in a character vector of length one.
`%~%` <- function(engine, script) UseMethod("%~%")

`%~%.ScriptEngine` <- function(engine, script) {
  base::get("eval", envir = engine, inherits = FALSE)(script)
}

# Evaluate a script contained in a character vector of length one and discard the result.
`%@%` <- function(engine, script) UseMethod("%@%")

`%@%.ScriptEngine` <- function(engine, script) {
  base::get("eval", envir = engine, inherits = FALSE)(script, TRUE)
}

