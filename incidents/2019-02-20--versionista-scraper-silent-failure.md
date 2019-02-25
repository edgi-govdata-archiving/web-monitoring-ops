# 2019-02-20: Versionista Scraper Silent Failure

## Summary

Versionista removed all version content from the HTML in the initial page load and started populating the list of versions of a page via a dynamic, JavaScript-based request asynchronously after the initial page load. The HTML that now came over the wire looked the same to our code as a page that listed no captured versions (rare, but can happen if you have no protected versions of a page and your account runs over with too many captures). We logged a warning, but
failed to see that warning as an error case and so did not fire alerts on Sentry.

The problem persisted for a week before it was caught.

On the up-side, we now have a structured API (even if we’re not sure how reliable it is) for getting lists of versions in a page. (There is no corresponding API to get lists of pages or lists of sites.)

NOTE: the PR to fix this ([scraper#196](https://github.com/edgi-govdata-archiving/web-monitoring-versionista-scraper/pull/196)) is unmerged and still awaiting review, but is running in production.


## Timeline

All times in PST.

### 2019-02-20 14:01

@jjudish posts [an issue on the versionista-scraper project](https://github.com/edgi-govdata-archiving/web-monitoring-versionista-scraper/issues/195) describing unusual error messages they haven’t seen before. (“No versions found for {URL}”)

### 2019-02-20 17:47

@Mr0grog responds with some possibilities and thoughts for debugging from his phone.

### 2019-02-20 19:00

@Mr0grog gets home and checks logs to see if we are having similar issues — we are. The issues started on Feb 12th at 3pm PST (`2019-02-12T23:00:00Z`). Checking the page in browsers demonstrates the issue immediately: the data is no longer being delivered in the HTML body of the page.

### 2019-02-20 21:20

@Mr0grog creates hotfix code to:

1. Throw exceptions in this situation instead of treating it the same as a page with no versions.
2. Throw exceptions in a similar situation for lists of pages in a site and list of sites in an account, since it seem only natural that they will change in the same way soon.
3. Use the same API call the content of the page is making to extract the data.

He switches production to the branch with the hotfix after testing with a smaller timeframe locally and tests with a larger timeframe matching the first failing request from a week ago.

### 2019-02-20 23:20

@Mr0grog creates PR from the hotfix code after it seems to be working successfully and asks for @jjudish’s review. He then starts incrementally backfilling data from the `versionista1` account.

### 2019-02-21 01:40

The backfilling process finishes for `versionista1`. @Mr0grog starts a much larger single backfill process (instead of incremental) for `versionista2`.

### 2019-02-21 01:50

The backfilling process throws a few errors and @Mr0grog adjusts the PR to account for them.

### 2019-02-21 02:30

The backfilling process for `versionista2` appears to be going smoothly and @Mr0grog and goes to sleep. (Sites in the `versionista2` account tend to change with greater frequency, so the same operation usually takes 1.5x - 2x the time for `versionista2`, so @Mr0grog expected this to go for a while.)

### 2019-02-21 21:00

Backfilling process for `versionista2` finishes.


## Lessons

### What Went Well

- The issue filed by @jjudish was super useful.
- Logs provided URLs and obvious spots to investigate.


### What Went Wrong

- This didn’t register as an actual error and we had no alerts about it for a week.
- Other people saw the issue before @Mr0grog but did not respond or investigate or flag it for someone who could.


## Action Items

- Review and merge PR for the fix.
- There was an old discussion about having a process that looks for new records from Versionista in our DB every so often as a general “is it working and not failing silently?” measure. We should discuss whether we should revive that.


## Responders

- @Mr0grog
