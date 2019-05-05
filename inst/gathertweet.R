#! /usr/bin/env Rscript

# Usage -------------------------------------------------------------------
'Gather tweets from the command line

Usage:
  gathertweet search [--file=<file>] [options] [--] <terms>...
  gathertweet timeline [options] [--] <users>...
  gathertweet update [--file=<file> --token=<token> --backup --backup-dir=<dir> --polite --debug-args]
  gathertweet simplify [--file=<file> --output=<output> --debug-args --polite] [<fields>...]

Arguments
  <terms>  Search terms. Individual search terms are queried separately,
           but duplicated tweets are removed from the stored results.
           Each search term counts against the 15 minute rate limit of 180
           searches, which can be avoided by manually joining search terms
           into a single query. WARNING: Wrap queries with spaces in
           \'single quotes\': double quotes are allowed inside single quotes only.

  <fields>  Tweet fields that should be included. Default value will include
            `status_id`, `created_at`, `user_id`, `screen_name`, `text`,
            `favorite_count`, `retweet_count`, `is_quote`, `hashtags`,
            `mentions_screen_name`, `profile_url`, `profile_image_url`,
            `media_url`, `urls_url`, `urls_expanded_url`.

Options:
  -h --help             Show this screen.
  --file <file>         Name of RDS file where tweets are stored [default: tweets.rds]
  --no-parse            Disable parsing of the results
  --token <token>       See {rtweet} for more information
  --retryonratelimit    Wait and retry when rate limited (only relevant when n exceeds 18000 tweets)
  --quiet               Disable printing of {rtweet} processing/retrieval messages
  --polite              Only allow one process (search|update) to run at a time
  --backup              Create a backup of existing tweet file before writing any new files
  --backup-dir <dir>    Location for backups, use "" for current directory. [default: backups]
  --debug-args          Print values of the arguments only
  --and-simplify        Create additional simplified tweet set with default values.
                        Run `gathertweet simplify` manually for more control.

search and timeline:
  -n, --n <n>           Number of tweets to return [default: 18000]
  --include_rts         Logical indicating whether retweets should be included
  --max_id <max_id>     Return results with an ID less than (older than) or equal to max_id

search:
  --type <type>         Type of search results: "recent", "mixed", or "popular". [default: recent]
  --geocode <geocode>   Geographical limiter of the template "latitude,longitude,radius"
  --since_id <since_id> Return results with an ID greather than (newer than) or equal to since_id,
                        automatically extracted from the existing tweets <file>, if it exists, and
                        ignored when <max_id> is set. Use "none" for all available tweets,
                        or "last" for the maximum seen status_id in existing tweets. [default: last]

timeline:
  --home                If included, returns home-timeline instead of user-timeline.

simplify:
  --output <output>     Output file, default is input file with `_simplified` appended to name.
' -> doc

library(docopt)
args <- docopt(doc, version = paste('gathertweet version', packageVersion("gathertweet")))
exit <- function(value = 0) q(save = "no", value)

if (args$`--debug-args`) {
  str(args)
  saveRDS(args, "args.rds")
  exit()
}

library(gathertweet)
collapse <- function(..., sep = ", ") paste(..., collapse = sep)

# Which action was called?
valid_actions <- c("search", "update", "simplify", "timeline")
action <- names(Filter(isTRUE, args[valid_actions]))
if (!length(action)) {
  log_fatal("Please specify a valid action: {collapse(valid_actions)}")
}

if (args$polite) {
  lockfile <- paste0(".gathertweet_",
                     digest::digest(args[c("file", "search", "update", "simplify")]),
                     ".lock")
  lck <- filelock::lock(lockfile, exclusive = TRUE, timeout = 0)
  gathertweet:::stopifnot_locked(lck, "Another gathertweet {action} process is currently running for {args$file}")
}

log_info("---- gathertweet {action} start ----")

# Search ------------------------------------------------------------------
if (isTRUE(args$search)) {
  if (args[["--and-simplify"]]) args$simplify <- TRUE

  log_info("Searching for \"{paste0(args$terms, collapse = '\", \"')}\"")

  max_id <- args[["max_id"]]
  since_id <- args[["since_id"]]
  since_id <- if (is.null(max_id)) {
    if (since_id == "last") {
      last_seen_tweet(file = args$file)
    } else if (since_id == "none") {
      NULL
    } else since_id
  }
  if (!is.null(since_id)) log_info("Tweets from {since_id}")
  if (!is.null(max_id)) log_info("Tweets up to {max_id}")

  tweets <- lapply(
    args$term,
    function(term) rtweet::search_tweets(
      q = term,
      n = as.integer(args$n),
      type = args$type,
      include_rts = args$include_rts,
      geocode = args$geocode,
      max_id = max_id,
      parse = !args[["no-parse"]],
      token = args$token,
      retryonratelimit = args$retryonratelimit,
      verbose = !args$quiet,
      since_id = since_id
    )
  )

  tweets <- dplyr::bind_rows(tweets)

  if (nrow(tweets) == 0) {
    log_info("No new tweets.")
    exit()
  }

  tweets <- tweets[!duplicated(tweets$status_id), ]
  tweets <- tweets[order(tweets$status_id), ]

  log_info("Gathered {nrow(tweets)} tweets")
  if (args$backup) backup_tweets(args$file, backup_dir = args[["backup-dir"]])
  tweets <- save_tweets(tweets, args$file)

  log_info("Total of {nrow(tweets)} tweets in {args$file}")

# Update ------------------------------------------------------------------
} else if (isTRUE(args$update)) {
  logger("Updating tweets in {args$file}")
  tweets <- update_tweets(
    file = args$file,
    # passed to rtweet::lookup_statuses()
    parse = !args[["no-parse"]],
    token = args$token
  )
  log_debug("Status lookup returned {nrow(tweets)} tweets")
  if (args$backup) backup_tweets(args$file, backup_dir = args[["backup-dir"]])
  tweets <- save_tweets(tweets, args$file)
  log_debug("Total of {nrow(tweets)} tweets in {args$file}")

} else if (isTRUE(args$timeline)) {
  if (!length(args$users)) {
    stop("Please provide a list of users as user names, user IDs, or a mixture of both.")
  }

  log_info("Gathering tweets by {collapse(args$users)}")
  if (args[["--and-simplify"]]) args$simplify <- TRUE

  tweets <- rtweet::get_timeline(
    user = args[["users"]],
    n = min(as.integer(args[["n"]]), 3200),
    max_id = args[["max_id"]],
    home = isTRUE(args[["home"]]),
    parse = isFALSE(args[["no-parse"]]),
    check = TRUE,
    token = args$token,
    include_rts = isTRUE(args[["include-rts"]])
  )

  tweets <- tweets[!duplicated(tweets$status_id), ]
  tweets <- tweets[order(tweets$status_id), ]

  log_info("Gathered {nrow(tweets)} tweets from {length(args$users)} users")
  if (args$backup) backup_tweets(args$file, backup_dir = args[["backup-dir"]])
  tweets <- save_tweets(tweets, args$file)

  log_info("Total of {nrow(tweets)} tweets in {args$file}")
}


# Simplify ----------------------------------------------------------------
if (isTRUE(args$simplify)) {
  logger("Simplifying tweets in {args$file}")
  tweets_simplified <- simplify_tweets(
    tweets = NULL,
    file = args$file,
    .fields = args$fields
  )
  log_debug("Simplified {nrow(tweets_simplified)} tweets")
  if (is.null(args$output)) {
    args$output <- gathertweet:::path_add(args$file, append = "_simplified")
  }
  log_info("Saving simplified tweets to {args$output}")
  tweets_simplfied <- save_tweets(tweets_simplified, args$output)
}

if (args$polite) {
  filelock::unlock(lck)
  unlink(lockfile)
}

log_info("---- gathertweet {action} complete ----")
