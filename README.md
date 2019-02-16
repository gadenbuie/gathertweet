
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gathertweet

The goal of gathertweet is to provide a simple command line utility that
wraps key functions from [rtweet](https://rtweet.info).

The magic of **gathertweet** is that it grants you the power to
**quickly set up twitter monitoring and tweet gathering** while saving
you from the pain of **writing a bunch of boilerplate code to save new
tweets without losing previously collected tweets, join multiple
searches, update tweet stats, simplify stored tweets, and more**.

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
adjust where this link is created in `install_gathertweet()`). If you
need admin rights to install, try `sudo Rscript -e
"gathertweet::install_gathertweet()` from the command line.

## Example

Create a directory to store tweets

``` bash
mkdir rstats
cd rstats
```

Get 100 \#rstats tweets

``` bash
> gathertweet search --n 100 --quiet "#rstats"
[2019-01-29 21:54:37] [INFO] ---- gathertweet search start ----
[2019-01-29 21:54:37] [INFO] Searching for "#rstats"
[2019-01-29 21:54:37] [INFO] Gathered 100 tweets
[2019-01-29 21:54:38] [INFO] Total of 100 tweets in tweets.rds
[2019-01-29 21:54:38] [INFO] ---- gathertweet search complete ----
```

Get more tweets, automatically starting from end of the last search

``` bash
> gathertweet search --n 100 --quiet "#rstats"
[2019-01-29 21:55:39] [INFO] ---- gathertweet search start ----
[2019-01-29 21:55:39] [INFO] Searching for "#rstats"
[2019-01-29 21:55:39] [INFO] Tweets from 1090438050835038208
[2019-01-29 21:55:39] [INFO] Gathered 1 tweets
[2019-01-29 21:55:39] [INFO] Total of 100 tweets in tweets.rds
[2019-01-29 21:55:39] [INFO] ---- gathertweet search complete ----
```

Update the stored data about those \#rstats tweets

``` bash
> gathertweet update
[2019-01-29 21:55:40] [INFO] ---- gathertweet update start ----
[2019-01-29 21:55:40] [INFO] Updating tweets in tweets.rds
[2019-01-29 21:55:40] [INFO] Getting 100 tweets
[2019-01-29 21:55:41] [INFO] ---- gathertweet update complete ----
```

``` bash
> ls -lh
total 40K
-rw-rw-r-- 1 garrick garrick 40K Jan 29 21:55 tweets.rds
```

## Documentation

``` bash
> gathertweet --help
```

    Gather tweets from the command line
    
    Usage:
      gathertweet search [--file=<file>] [options] [--] <terms>...
      gathertweet update [--file=<file> --token=<token> --backup --backup-dir=<dir> --polite --debug-args]
      gathertweet simplify [--file=<file> --output=<output> --debug-args --polite] [<fields>...]
    
    Arguments
      <terms>  Search terms. Individual search terms are queried separately,
               but duplicated tweets are removed from the stored results.
               Each search term counts against the 15 minute rate limit of 180
               searches, which can be avoided by manually joining search terms
               into a single query. WARNING: Wrap queries with spaces in
               'single quotes': double quotes are allowed inside single quotes only.
    
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
    
    search:
      -n, --n <n>           Number of tweets to return [default: 18000]
      --type <type>         Type of search results: "recent", "mixed", or "popular". [default: recent]
      --include_rts         Logical indicating whether retweets should be included
      --geocode <geocode>   Geographical limiter of the template "latitude,longitude,radius"
      --max_id <max_id>     Return results with an ID less than (older than) or equal to max_id
      --since_id <since_id> Return results with an ID greather than (newer than) or equal to since_id,
                            automatically extracted from the existing tweets <file>, if it exists, and
                            ignored when <max_id> is set. "none" for all available tweets. [default: last]
      --and-simplify        Create additional simplified tweet set with default values.
                            Run `gathertweet simplify` manually for more control.
    simplify:
      --output <output>     Output file, default is input file with `_simplified` appended to name.
