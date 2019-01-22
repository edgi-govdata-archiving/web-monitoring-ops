# 2019-01-18: Versionista Scaper Failure.

## Summary

A change in Versionista's behavior caused [Versionista Scraper](https://github.com/edgi-govdata-archiving/web-monitoring-versionista-scraper) to fail.

## Timeline

All times in EST.

### 2019-01-18 18:02

Sentry begins reporting that Versionista was returning invalid URIs for raw versions requested by the scraper.

### 2019-01-18 ~ 22:00

@Mr0grog notices the Sentry reports and begins to investigate. He invites @jsnshrmn (who is actually in the same room) to join in and observe.

### 2019-01-18 ~ 22:10

@Mr0grog identifies the change impacting `lib/versionista.js` and verifies the fix by running the scraper locally over a very small period of time and printing test values to STDOUT.

### 2019-01-18 22:18

@Mr0grog merges [versionista-scraper#186](https://github.com/edgi-govdata-archiving/web-monitoring-versionista-scraper/pull/186), opens an SSH session on the production Versionista Scraper VM and executes `git pull` to deploy the update. In a screen session, he then executes `scrape-versionista` with the `--after 5` argument to capture all of the version scrapes that failed since the change to Versionista. He takes the time to talk @jsnshrmn through what he is doing and makes a note on slack.

Incident resolved.


## Lessons

### What Went Well

- Sentry alerts worked correctly
- @Mr0grog was able to resolve the issue quickly upon noticing the Sentry alerts.
- @jsnshrmn was able to learn more about Versionista Scraper.

### What Went Wrong

- Versionista has no APIs and no process for communicating that changes are coming, so Versionista Scraper breaks anytime Versionista makes a change to something it uses.


## Action Items

- N/A


## Responders

- @Mr0grog
- @jsnshrmn (observing)
