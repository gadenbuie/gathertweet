#' @export
save_tweets <- function(
  tweets,
  file = getOption("gathertweet.file", "tweets.rds"),
  save_fun = saveRDS,
  read_fun = read_tweets,
  lck = NULL,
  key_var = "status_id"
) {
  if (nrow(tweets) < 1) return(tweets)
  fs::dir_create(fs::path_dir(file))
  if (is.null(lck)) {
    lck <- exclusive_lock(file)
    on.exit(unlock(lck))
  }
  stopifnot_locked(lck, message = "Unable to acquire lock on {file}")

  if (fs::file_exists(file)) {
    # Don't drop or lose old tweets
    tweets_prev <- read_fun(file, lck = lck)
    if (!is.null(tweets_prev)) {
      tweets_not_new <- anti_join(tweets_prev, tweets, by = key_var)
      if (nrow(tweets_not_new)) {
        tweets <- bind_rows(tweets, tweets_not_new)
      }
      if (length(setdiff(tweets_prev[[key_var]], tweets[[key_var]])) != 0) {
        log_fatal("An error occurred that would have lost stored tweets")
      }
    }
  }

  save_fun(tweets, file)
  tweets
}

#' @export
last_seen_tweet <- function(
  tweets = NULL,
  file = getOption("gathertweet.file", "tweets.rds")
  ) {
  if (is.null(tweets)) tweets <- read_tweets(file)
  if (is.null(tweets)) return(NULL)
  tweets$status_id %>%
    as.numeric() %>%
    max() %>%
    as.character()
}

#' @export
read_tweets <- function(
  file = getOption("gathertweet.file", "tweets.rds"),
  lck = NULL
) {
  if (!file_exists(file)) return(NULL)
  if (is.null(lck)) {
    lck <- shared_lock(file)
    on.exit(unlock(lck))
  }
  stopifnot_locked(lck, message = "Unable to acquire lock on {file}")

  readRDS(file)
}

#' @export
backup_tweets <- function(
  file = getOption("gathertweet.file", "tweets.rds"),
  backup_dir = "backups",
  lck = NULL
) {
  if (!file_exists(file)) return()
  if (is.null(lck)) {
    lck <- shared_lock(file)
    on.exit(unlock(lck))
  }
  stopifnot_locked(lck, message = "Unable to acquire lock on {file}")
  file_backup <- path(fs::path_dir(file), backup_dir, fs::path_file(file))
  file_backup <- path_add(file_backup)
  fs::dir_create(fs::path_dir(file_backup))
  log_info("Backing up tweet file to {file_backup}")
  fs::file_copy(file, file_backup)
}

#' @export
simplify_tweets <- function(
  tweets = NULL,
  file = getOption("gathertweet.file", "tweets.rds"),
  ...,
  .fields = NULL
) {
  if (is.null(tweets)) tweets <- read_tweets(file)
  if (is.null(tweets)) return(NULL)
  .fields <- c(list(...), .fields)
  if (length(.fields)) {
    tweets %>% dplyr::select(!!!.fields)
  } else {
    tw_cols <- names(tweets)
    keep_cols <- c(
      "created_at",
      "status_id",
      "user_id",
      "screen_name",
      "text",
      "is_quote",
      "is_retweet",
      "favorite_count",
      "retweet_count",
      "hashtags",
      "profile_url",
      "profile_image_url",
      "urls_expanded_url",
      "mentions_screen_name",
      "media_url",
      "urls_url",
      "ext_media_url",
      "status_url",
      grep("^reply_to_", tw_cols, value = TRUE),
      "quoted_status_id",
      "retweet_status_id",
      "quoted_status_id",
      grep("^mentions_", tw_cols, value = TRUE)
    )
    tweets[, intersect(tw_cols, keep_cols)]
  }
}

#' @export
update_tweets <- function(
  tweets = NULL,
  file = getOption("tweets.file", "tweets.rds"),
  ...
) {
  if (is.null(tweets)) tweets <- read_tweets(file)
  lookup_status_ratelimit(tweets$status_id, ...)
}

lookup_status_ratelimit <- function(status_id, ...) {
  tweets <- NULL
  rate_limit <- rtweet::rate_limits(query = "statuses/lookup")
  fetch_count <- 0
  n_status <- length(status_id)
  n_status_large <- n_status > 90000
  for (idx_group in seq(1, ceiling(n_status/90000))) {
    # Rate limit ----
    # Track rate limit and wait it out if needed
    if (Sys.time() > rate_limit$reset_at) {
      log_debug("Updating out-of-date rate limit")
      rate_limit <- rtweet::rate_limits(query = "statuses/lookup")
    }
    if (rate_limit$remaining - fetch_count < 1) {
      # wait until rate limit resets
      wait_s <- difftime(Sys.time(), rate_limit$reset_at, units = "sec")
      log_info("Waiting for rate limit to reset at {rate_limit$reset_at}")
      Sys.sleep(ceiling(as.numeric(wait_s)))
    }
    if (fetch_count > 0 && fetch_count %% 50 == 0) {
      rate_limit <- rtweet::rate_limits(query = "statuses/lookup")
    }

    # Get Statuses ----
    if (n_status_large) {
      idx_start <- (idx_group - 1) * 90000 + 1
      idx_end   <- min(idx_group * 90000, n_status)
      log_info("Getting tweets {idx_start} to {idx_end} of {n_status}")
    } else {
      idx_start <- 1
      idx_end <- n_status
      log_info("Getting {n_status} tweets")
    }
    tweets <- bind_rows(
      tweets,
      rtweet::lookup_statuses(status_id[idx_start:idx_end], ...)
    )
  }

  tweets
}

path_lock <- function(file) {
  path(path_add(file, NULL, prepend = "."), ext = "lock")
}

path_add <- function(file, append = strftime(Sys.time(), "_%F_%H%M%S"), prepend = NULL) {
  if (is.null(append)) append <- ""
  if (is.null(prepend)) prepend <- ""
  file_base <- fs::path_ext_remove(fs::path_file(file))
  file_ext <- fs::path_ext(file)
  file_dir <- fs::path_dir(file)
  path(file_dir,
       glue::glue("{prepend}{file_base}{append}"),
       ext = file_ext)
}

stopifnot_locked <- function(lck = NULL, message = "Unable to aquire lock") {
  if (!is.null(lck)) return(invisible(TRUE))
  log_error(message, envir = sys.frame(1))
}

shared_lock <- function(file, timeout = 1 * 60 * 1000) {
  lock(path_lock(file), exclusive = FALSE, timeout = timeout)
}

exclusive_lock <- function(file, timeout = 1 * 60 * 1000) {
  lock(path_lock(file), exclusive = TRUE, timeout = timeout)
}

#' @title Get user info
#' @param file The file where tweets are located. The text `_users` is
#'   automatically appended to this file name.
#' @export
get_user_info <- function(
  tweets = NULL,
  file = getOption("gathertweet.file", "tweets.rds"),
  dir_profile_images = NULL
) {
  if (is.null(tweets)) read_tweets(file)
  user_file <- path_add(file, append = "_users")
  users <- tweets %>%
    rtweet::users_data() %>%
    dplyr::distinct()

  users <- save_tweets(users, user_file, key_var = "user_id")

  if (!is.null(dir_profile_images)) {
    rs <- lapply(users$profile_image_url, download_profile_images, output_dir = dir_profile_images)
  }

  return(users)
}

download_profile_images <- function(profile_image_url, ..., output_dir = "data") {
  output_file <- sub("^.+?profile", "profile", profile_image_url)
  output_file <- fs::path(output_dir, output_file)
  fs::dir_create(fs::path_dir(output_file), recursive = TRUE)
  download_file(profile_image_url, output_file)
}

download_file <- function(url, dest) {
  if (fs::file_exists(dest)) return(dest)
  x <- list(result = NULL, error = NULL)
  x$result <- tryCatch({
    download.file(url, dest)
    dest
  }, error = function(e) x$error <<- e$message)

  if (!is.null(x$error)) {
    log_warn("Error downloading {dest}: {x$error}")
  } else x$result
}
