#' @title gathertweet actions
#' @export
gathertweet_search <- function(
  terms,
  file             = "tweets.rds",
  n                = 18000,
  max_id           = NULL,
  since_id         = "last",
  type             = "recent",
  include_rts      = FALSE,
  geocode          = NULL,
  `no-parse`       = FALSE,
  token            = NULL,
  retryonratelimit = FALSE,
  quiet            = FALSE,
  ...
) {
  log_info("Searching for \"{paste0(terms, collapse = '\", \"')}\"")

  since_id <- if (is.null(max_id)) {
    if (since_id == "last") {
      last_seen_tweet(file = file)
    } else if (since_id == "none") {
      NULL
    } else since_id
  }
  if (!is.null(since_id)) log_info("Tweets from {since_id}")
  if (!is.null(max_id)) log_info("Tweets up to {max_id}")

  tweets <- lapply(
    terms,
    function(term) rtweet::search_tweets(
      q                = term,
      n                = as.integer(n),
      type             = type,
      include_rts      = include_rts,
      geocode          = geocode,
      max_id           = max_id,
      parse            = isFALSE(`no-parse`),
      token            = token,
      retryonratelimit = retryonratelimit,
      verbose          = isFALSE(quiet),
      since_id         = since_id
    )
  )



  if (isTRUE(`no-parse`)) {
    log_info("Saving un-parsed tweets in {file}")
    saveRDS(tweets, file)
  } else {
    tweets <- dplyr::bind_rows(tweets)

    if (nrow(tweets) == 0) {
      log_info("No new tweets.")
      exit()
    }

    tweets <- tweets[!duplicated(tweets$status_id), ]
    tweets <- tweets[order(tweets$status_id), ]

    log_info("Gathered {nrow(tweets)} tweets")
    tweets <- save_tweets(tweets, file)

    log_info("Total of {nrow(tweets)} tweets in {file}")
  }

  tweets
}

#' @export
gathertweet_update <- function(file = "tweets.rds", `no-parse` = FALSE, token = NULL, ...) {
  logger("Updating tweets in {file}")
  if (!file.exists(file)) {
    log_fatal("`{file}` does not exist")
  }
  tweets <- update_tweets(
    file = file,
    # passed to rtweet::lookup_statuses()
    parse = isFALSE(`no-parse`),
    token = token
  )
  log_debug("Status lookup returned {nrow(tweets)} tweets")
  tweets <- save_tweets(tweets, file)
  log_debug("Total of {nrow(tweets)} tweets in {file}")
  tweets
}

#' @export
gathertweet_timeline <- function(
  users,
  file        = "tweets.rds",
  n           = 3200,
  max_id      = NULL,
  home        = TRUE,
  `no-parse`  = FALSE,
  token       = NULL,
  include_rts = FALSE,
  ...
) {
  log_info("Gathering tweets by {collapse(users)}")

  n <- as.integer(n)
  if (n > 3200) {
    log_warn("Twitter API for timelines returns a maximum of 3200 tweets per user")
  }

  tweets <- rtweet::get_timeline(
    user        = users,
    n           = n,
    max_id      = max_id,
    home        = isTRUE(home),
    parse       = isFALSE(`no-parse`),
    check       = TRUE,
    token       = token,
    include_rts = isTRUE(include_rts)
  )

  tweets <- tweets[!duplicated(tweets$status_id), ]
  tweets <- tweets[order(tweets$status_id), ]

  log_info("Gathered {nrow(tweets)} tweets from {length(users)} users")
  tweets <- save_tweets(tweets, file)

  log_info("Total of {nrow(tweets)} tweets in {file}")
  tweets
}

#' @export
gathertweet_simplify <- function(
  file = "tweets.rds",
  fields = NULL,
  output = NULL,
  ...
) {
  logger("Simplifying tweets in {file}")
  if (!file.exists(file)) {
    log_fatal("`{file}` does not exist")
  }
  tweets_simplified <- simplify_tweets(
    tweets = NULL,
    file = file,
    .fields = fields
  )
  log_debug("Simplified {nrow(tweets_simplified)} tweets")
  if (is.null(output)) {
    output <- gathertweet:::path_add(file, append = "_simplified")
  }
  log_info("Saving simplified tweets to {output}")
  save_tweets(tweets_simplified, output)
}
