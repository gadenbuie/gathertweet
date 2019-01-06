
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gathertweet

The goal of gathertweet is to provide a simple command line utility that
wraps key functions from \[rtweet\].

**gathertweet** removes the boilerplate code required to run periodic
Twitter searches and plays well with cron.

## Installation

This is a work in progress and may not work well for you yet. But you
are welcome to install **gathertweet** and try it out.

``` r
# install.packages("remotes")
remotes::install_github("gadenbuie/gathertweet")
```

Once you’ve installed the package, you need to run

``` r
gathertweet::install_gathertweet()
```

which adds `gathertweet` to `/usr/local/bin` as a symlink (you can
adjust were this link is created).

## Example

``` bash
# Get 100 #rstats tweets
gathertweet search --n 100 --quiet "#rtats"

# Get more tweets, automatically starting from end of the last search
gathertweet search --n 100 --quiet "#rstats"

# Update the stored data about those #rstats tweets
gathertweet update
```

## Documentation

``` bash
> gathertweet --help
Gather tweets from the command line

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
```
