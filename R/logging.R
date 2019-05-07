.onLoad <- function(libname, pkgname) {
  gathertweet_layout <- futile.logger::layout.format(
    "[~t] [~l] ~m"
  )
  futile.logger::flog.layout(gathertweet_layout, name = "gathertweet")
}

collapse <- function(..., sep = ", ") paste(..., collapse = sep)

#' @title Logging functions
#' @export
logger <- function(..., level = "info", envir = parent.frame()) {
  msg <- glue::glue(..., .envir = envir)
  futile_logger <- switch(
    tolower(level),
    "trace" = futile.logger::flog.trace,
    "debug" = futile.logger::flog.debug,
    "info"  = futile.logger::flog.info,
    "warn"  = futile.logger::flog.warn,
    "error" = futile.logger::flog.error,
    "fatal" = futile.logger::flog.fatal,
    futile.logger::flog.info
  )
  futile_logger(msg)
}

#' @rdname logger
#' @export
log_info <- function(..., envir = parent.frame()) {
  logger(..., level = "info", envir = envir)
}

#' @rdname logger
#' @export
log_debug <- function(..., envir = parent.frame()) {
  logger(..., level = "debug", envir = envir)
}

#' @rdname logger
#' @export
log_warn <- function(..., envir = parent.frame()) {
  logger(..., level = "warn", envir = envir)
}

#' @rdname logger
#' @export
log_error <- function(..., envir = parent.frame()) {
  logger(..., level = "error", envir = envir)
}

#' @rdname logger
#' @export
log_fatal <- function(..., envir = parent.frame()) {
  logger(..., level = "fatal", envir = envir)
  rlang::abort(glue::glue(..., .envir = envir))
}

#' @rdname logger
#' @export
log_pipe <- function(.data, ..., level = "info") {
  msg <- glue::glue(...)
  logger(msg, level = level)
}
