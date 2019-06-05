#! /usr/bin/env Rscript

# Usage -----------------------------------------------------------------------
'Gather tweets from the command line

Usage:
  gathertweet search [--file=<file>] [options] [--] <terms>...
  gathertweet update [--file=<file> --and-simplify --polite --debug-args --token=<token> --backup --backup-dir=<dir>]
  gathertweet timeline [options] [--] <users>...
  gathertweet favorites [options] [--] <users>...
  gathertweet simplify [--file=<file> --output=<output> --debug-args --polite] [<fields>...]

Options:
  -h --help             Show this screen.
  --file <file>         Name of RDS file where tweets are stored
                        [default: tweets.rds]
  --no-parse            Disable parsing of the results
  --token <token>       See {rtweet} for more information
  --retryonratelimit    Wait and retry when rate limited (only relevant when n
                        exceeds 18000 tweets)
  --quiet               Disable printing of {rtweet} processing messages
  --polite              Only allow one process (search|update) to run at a time
  --backup              Create a backup of existing tweet file
  --backup-dir <dir>    Location for backups [default: backups]
  --debug-args          Debug input arguments
  --and-simplify        Create additional simplified tweet set.
                        Run `gathertweet simplify` manually for more control.
search:
  <terms>  Search terms. Individual search terms are queried separately,
           but duplicated tweets are removed from the stored results.
           Each search term counts against the 15 minute rate limit of 180
           searches, which can be avoided by manually joining search terms
           into a single query. NOTE: Wrap queries with spaces in
           \'single quotes\': only use double quotes within single quotes.
  --type <type>         Type of search results: "recent", "mixed", or "popular"
                        [default: recent]
  --geocode <geocode>   Geographical limiter of the template
                        "latitude,longitude,radius"
  --since_id <since_id> Return results with an ID greather than (newer than) or
                        equal to since_id, automatically extracted from the
                        existing tweets <file>, if it exists, and ignored when
                        <max_id> is set. Use "none" for all available tweets,
                        or "last" for the maximum seen status_id in existing
                        tweets. [default: last]

search and timeline:
  -n, --n <n>        Number of tweets to return [default: 18000]
  --include_rts      Logical indicating whether retweets should be included
                     (default is to exclude RTs)
  --max_id <max_id>  Return tweets with an ID less (older) than or equal to

timeline and favorites:
  <users>  A list of users as user names, IDs, or a mixture of both,
           separated by spaces.

timeline:
  --home   If included, returns home-timeline instead of user-timeline.

simplify:
  <fields>  Tweet fields that should be included. By default includes:
            `status_id`, `created_at`, `user_id`, `screen_name`, `text`,
            `favorite_count`, `retweet_count`, `is_quote`, `hashtags`,
            `mentions_screen_name`, `profile_url`, `profile_image_url`,
            `media_url`, `urls_url`, `urls_expanded_url`.
  --output <output>  Output file, default is input file with `_simplified`
                     appended to name.
' -> doc

library(docopt)
args <- docopt(doc, version = paste('gathertweet version', packageVersion("gathertweet")))
exit <- function(value = 0) q(save = "no", value)

if (args$`--debug-args`) {
  str(args)
  saveRDS(args, "args.rds")
  exit()
}

do_gathertweet <- function() {
  library(gathertweet)
  collapse <- function(..., sep = ", ") paste(..., collapse = sep)

  # Which action was called?
  valid_actions <- c("search", "update", "simplify", "timeline", "favorites")
  action <- names(Filter(isTRUE, args[valid_actions]))
  if (!length(action)) {
    log_fatal("Please specify a valid action: {collapse(valid_actions)}")
  }

  if (args$polite) {
    lockfile <- paste0(
      ".gathertweet_",
      digest::digest(args[c("file", "search", "update", "simplify")]),
      ".lock"
    )
    lck <- filelock::lock(lockfile, exclusive = TRUE, timeout = 0)
    gathertweet:::stopifnot_locked(
      lck,
      "Another gathertweet {action} process is currently running for {args$file}"
    )
    on.exit({
      filelock::unlock(lck)
      unlink(lockfile)
    })
  }

  log_info("---- gathertweet {action} start ----")

  if (isTRUE(args$backup)) {
    backup_tweets(args$file, backup_dir = args[["backup-dir"]])
  }

  # Also simplify if --and-simplify flag is called
  if (args[["--and-simplify"]]) args$simplify <- TRUE

  tweets <-
    # Search ----
  if (isTRUE(args$search)) {

    do.call("gathertweet_search", args)

    # Update ----
  } else if (isTRUE(args$update)) {

    do.call("gathertweet_update", args)

    # Timeline ----
  } else if (isTRUE(args$timeline)) {
    if (!length(args$users)) {
      stop("Please provide a list of users as user names, user IDs, ",
           "or a mixture of both.")
    }

    do.call("gathertweet_timeline", args)

    # Favorites ----
  } else if (isTRUE(args$favorites)) {
    if (!length(args$users)) {
      stop("Please provide a list of users as user names, user IDs, ",
           "or a mixture of both.")
    }

    do.call("gathertweet_favorites", args)
  }


  # Simplify ----------------------------------------------------------------
  if (isTRUE(args$simplify)) {
    do.call("gathertweet_simplify", args)
  }

  if (args$polite) {
    filelock::unlock(lck)
    unlink(lockfile)
  }

  log_info("---- gathertweet {action} complete ----")
}

do_gathertweet()
