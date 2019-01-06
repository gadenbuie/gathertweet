#! /usr/bin/env Rscript

# Usage -------------------------------------------------------------------
'Gather tweets from the command line

Usage:
  gathertweet search [--file=<file>] [options] [--] <terms>...
  gathertweet update [--file=<file> --backup --polite --token --debug-args]

Arguments
  <terms>  Search terms. Individual search terms are queried separately,
           but duplicated tweets are removed from the stored results.

Options:
  -h --help             Show this screen.
  --file=<file>         Name of RDS file where tweets are stored [default: tweets.rds]
  -n, --n <n>           Number of tweets to return [default: 18000]
  --type <type>         Type of search results: "recent", "mixed", or "popular". [default: recent]
  --include_rts         Logical indicating whether retweets should be included
  --geocode <geocode>   Geographical limiter of the template "latitude,longitude,radius"
  --max_id <max_id>     Return results with an ID less than (older than) or equal to max_id
  --since_id <since_id> Return results with an ID greather than (newer than) or equal to since_id,
                        automatically extracted from the existing tweets <file>, if it exists, and
                        ignored when <max_id> is set. [default: last]
  --no-parse            Disable parsing of the results
  --token <token>       See {rtweet} for more information
  --retryonratelimit    Wait and retry when rate limited (only relevant when n exceeds 18000 tweets)
  --quiet               Disable printing of {rtweet} processing/retrieval messages
  --polite              Only allow one process (search|update) to run at a time
  --backup              Create a backup of existing tweet file before writing any new files
  --debug-args          Print values of the arguments only
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

if (args$polite) {
  lockfile <- paste0(".gathertweet_",
                     digest::digest(args[c("file", "search", "update")]),
                     ".lock")
  lck <- filelock::lock(lockfile, exclusive = TRUE, timeout = 0)
  action <- names(Filter(isTRUE, args[c("search", "update")]))
  gathertweet:::stopifnot_locked(lck, "Another gathertweet {action} process is currently running for {args$file}")
}

# Search ------------------------------------------------------------------
if (isTRUE(args$search)) {

  log_info("Searching for \"{paste0(args$terms, collapse = '\", \"')}\"")

  max_id <- args[["max_id"]]
  since_id <- args[["since_id"]]
  since_id <- if (is.null(max_id)) {
    if (since_id == "last") {
      last_seen_tweet(file = args$file)
    } else since_id
  }
  if (!is.null(since_id)) log_info("Tweets from {since_id}")
  if (!is.null(max_id)) log_info("Tweets up to {max_id}")

  tweets <- rtweet::search_tweets2(
    q = args$terms,
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

  if (nrow(tweets) == 0) {
    log_info("No new tweets.")
    exit()
  }

  tweets <- tweets[order(tweets$status_id), ]
  tweets <- tweets[!duplicated(tweets$status_id), ]

  log_info("Gathered {nrow(tweets)} tweets")
  if (args$backup) backup_tweets(args$file)
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
  if (args$backup) backup_tweets(args$file)
  tweets <- save_tweets(tweets, args$file)
  log_debug("Total of {nrow(tweets)} tweets in {args$file}")
  log_info("Tweet update complete")

}

if (args$polite) {
  filelock::unlock(lck)
  unlink(lockfile)
}
