# 2019-02-12: Wayback Machine Import Failure

## Summary

@Mr0grog appears to have left to checkout of web-monitoring-processing that loads data in production from the Wayback Machine in a bad, merge-conflict state, so it failed immediately with Python syntax errors every time it ran. No process was set up to alert for this situation. (We normally rely on Sentry for this, but it runs in-process and if Python never actually runs our code, it doesn’t get a chance to work.)

The problem persisted for nearly two months (since about the start of the shutdown).

See also this explanation from the Dev meeting the next day: https://youtu.be/vcpmvMppM-0?t=654


## Timeline

All times in PST.

### 2019-02-12 18:30

@Mr0grog sees @gretchengehrke's [post in Slack about a page not having snapshots since December](https://edgi.slack.com/archives/CFA6LE5GX/p1549992608006900). At first, this looks unsurprising because of the shutdown, but a quick check of Wayback shows that the last snapshot we have doesn’t include the shutdown banner, which means the page should have had at least one update.

### 2019-02-12 18:40

@Mr0grog checks database for versions of page where `different=false` in case we have records that are normally hidden. No such records.

### 2019-02-12 18:50

@Mr0grog logs into `wm-scraper` machine to check logs and sees that every Wayback run has failed immediately with a syntax error since near the end of the day December 12th. Checks the actual working copy to see what's wrong; it's in a half-merged state with conflicts waiting to be resolved.

### 2019-02-12 18:55

@Mr0grog fixes all merge conflicts and realizes there is no real difference from what's on the top of the `86-import-known-db-pages-from-ia` branch (that is, the branch for [processing#174](https://github.com/edgi-govdata-archiving/web-monitoring-processing/pull/174)). He resets the branch HEAD on the scraper machine to the same as in GitHub.

### 2019-02-12 19:05

@Mr0grog starts running manual jobs to backfill data starting from December 10th (a little earlier than when things broke, just to make sure we have reliable overlap).

### 2019-02-13

Manual backfilling finishes. @Mr0grog drops all auto-analysis jobs (since we spawned a backlog of ~200,000) and re-schedules jobs for just the latest versions of every page.


## Lessons

### What Went Well

- Logs made this problem easy to understand once it was identified.


### What Went Wrong

- There were alerts for this issue and it lingered for a *loooooong* time.
- @Mr0grog is only writing this incident report 13 days later. That's much too long.


## Action Items

- Consider whether (and how) to do some alerting based on logs rather than/in addition to Sentry.
- Consider ways to lessen the auto-analysis burden of big backfills ([db#487](https://github.com/edgi-govdata-archiving/web-monitoring-db/pull/487))


## Responders

- @Mr0grog
