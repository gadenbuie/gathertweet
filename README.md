
<!-- README.md is generated from README.Rmd. Please edit that file -->

<h1 style="font-weight: normal;">

gathe<strong>rtweet</strong>

</h1>

The goal of gathertweet is to provide a simple command line utility that
wraps key functions from [rtweet](https://rtweet.info).

The magic of **gathertweet** is that it grants you the power to
**quickly set up twitter monitoring and tweet gathering** while saving
you from the pain of **writing a bunch of boilerplate code** to

  - save new tweets without losing previously collected tweets,
  - join multiple searches,
  - update tweet stats,
  - simplify stored tweets,
  - schedule easily with [cron](https://en.wikipedia.org/wiki/Cron),
  - and more…

gathe**rtweet** is a thin wrapper around [rtweet](https://rtweet.info),
the excellent R interface to Twitter written by [Mike
Kearney](https://mikewk.com/). If you use gathertweet, please ensure
that you [cite rtweet directly](https://rtweet.info/authors.html).

``` r
> citation("rtweet")

To cite rtweet use:

  Kearney, M. W. (2018). rtweet: Collecting Twitter Data. R
  package version 0.6.7 Retrieved from
  https://cran.r-project.org/package=rtweet

A BibTeX entry for LaTeX users is

  @Manual{rtweet-package,
    title = {rtweet: Collecting Twitter Data},
    author = {Michael W. Kearney},
    year = {2018},
    note = {R package version 0.6.7},
    url = {https://cran.r-project.org/package=rtweet},
  }
```

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
need admin rights to install, try

    sudo Rscript -e "gathertweet::install_gathertweet()"

from the command line.

## Example

### Use gathertweet from the command line

Create a directory to store tweets

``` bash
mkdir rstats
cd rstats
```

Get 100 \#rstats tweets

``` bash
> gathertweet search --n 100 --quiet "#rstats"
[2019-05-04 14:52:15] [INFO] ---- gathertweet search start ----
[2019-05-04 14:52:15] [INFO] Searching for "#rstats"
[2019-05-04 14:52:16] [INFO] Gathered 100 tweets
[2019-05-04 14:52:16] [INFO] Total of 100 tweets in tweets.rds
[2019-05-04 14:52:16] [INFO] ---- gathertweet search complete ----
```

Get more tweets, automatically starting from end of the last search

``` bash
> gathertweet search --n 100 --quiet "#rstats"
[2019-05-04 14:53:17] [INFO] ---- gathertweet search start ----
[2019-05-04 14:53:17] [INFO] Searching for "#rstats"
[2019-05-04 14:53:17] [INFO] Tweets from 1124748486971359232
[2019-05-04 14:53:17] [INFO] Gathered 1 tweets
[2019-05-04 14:53:17] [INFO] Total of 100 tweets in tweets.rds
[2019-05-04 14:53:17] [INFO] ---- gathertweet search complete ----
```

Update the stored data about those \#rstats tweets

``` bash
> gathertweet update
[2019-05-04 14:53:18] [INFO] ---- gathertweet update start ----
[2019-05-04 14:53:18] [INFO] Updating tweets in tweets.rds
[2019-05-04 14:53:18] [INFO] Getting 100 tweets
[2019-05-04 14:53:19] [INFO] ---- gathertweet update complete ----
```

``` bash
> ls -lh
total 40K
-rw-rw-r-- 1 garrick garrick 39K May  4 14:53 tweets.rds
```

Gather user timelines

``` bash
> gathertweet timeline hadleywickham jennybryan dataandme
[2019-05-04 21:11:54] [INFO] ---- gathertweet timeline start ----
[2019-05-04 21:11:54] [INFO] Gathering tweets by hadleywickham, jennybryan, dataandme
[2019-05-04 21:12:23] [INFO] Gathered 7368 tweets from 3 users
[2019-05-04 21:12:23] [INFO] Total of 7368 tweets in tweets.rds
[2019-05-04 21:12:23] [INFO] ---- gathertweet timeline complete ----
```

### Schedule tweet gathering using cron

The primary use case of gathertweet is to make it easy to set up
[cron](https://en.wikipedia.org/wiki/Cron) to periodically gather
tweets. Here’s a simple example to download all tweets matching the
search term `rstats OR tidyverse` every night at midnight. The tweets
are stored, by default, in `tweets.rds` in `~/rstats-tweets`.

``` bash
crontab -e

# m h dom mon dow   command
0 0 * * * (cd ~/rstats-tweets && ~/bin/gathertweet search --polite 'rstats OR tidyverse' >>gathertweet.log)
```

## Documentation

``` bash
> gathertweet --help
```

    Gather tweets from the command line
    
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
