#' Install gathertweet exectuable script
#'
#' Installs the `gatherwteet` executable script to the location. Should work
#' with Unix and MacOS out of the box, but I can't make any guarantees about
#' Windows.
#'
#' @param location Where to install the gathertweet executable script
#' @export
install_gathertweet <- function(
  location = "/usr/local/bin"
) {
  only_know_unix()
  if (!dir_exists(location)) {
    log_fatal("Location {location} does not exist, please create it and try again.")
  }
  if (!fs::file_access(location, "write")) {
    log_fatal("You do not have write permissions for {location}\n",
              "Try installing gathertweet to a local directory, such as $HOME/.local/bin")
  }
  log_info("Creating link to gathertweet at {location}/gathertweet")
  fs::link_create(
    system.file("gathertweet.R", package = "gathertweet"),
    path(location, "gathertweet")
  )
  instructions_run_gathertweet(location)
}

only_know_unix <- function() {
  if (.Platform$OS.type == "unix") return(invisible(TRUE))
  msg <- glue::glue(
    "I'm sorry, but I don't know how to install executable scripts on your ",
    "platform ({.Platform$OS.type}), so you'll have to do this manually. ",
    "Copy the gathertweet executable script from the location below ",
    "to a place where you can run it.\n",
    "{system.file('gathertweet.R', package='gathertweet')}"
  )
  rlang::abort(msg)
}

instructions_run_gathertweet <- function(location) {
  which_gathertweet <- tryCatch(
    system2("which", "gathertweet2", stdout = TRUE),
    error = function(e) "",
    warning = function(w) ""
  )
  if (which_gathertweet == "") {
    log_warn("gathertweet may not be installed in a location visible to your system path")
    log_warn("You may need to fully specify `{location}/gathertweet` to run gathertweet")
  } else {
    log_info("You can now call gathertweet from the command line")
  }
  log_info("In CRON jobs, use `{location}/gathertweet`")
}
