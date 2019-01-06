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
  if (!dir_exists(location)) {
    log_fatal("Location {location} does not exist")
  }
  if (!fs::file_access(location, "write")) {
    log_fatal("You do not have write permissions for {location}")
  }
  log_info("Creating link to gathertweet at {location}/gathertweet")
  fs::link_create(
    system.file("gathertweet.R", package = "gathertweet"),
    path(location, "gathertweet")
  )
}
