# 2019-07-21: Differ Broken

## Summary

One of the diffing service pods started failing and returning a variety of errors, causing downstream errors in the DB’s auto-analysis job. @Mr0grog was offline at a camp and was unable to address it for a full day.

The problem appears to have been caused by a broken executor.


## Timeline

All times in PDT.

### 2019-07-20 20:30

The diffing service starts raising a few more errors than usual.

### 2019-07-20 21:00

Sentry begins sending rollup error alerts with multiple errors because of the error frequency.

### 2019-07-21 11:30

Rob sees huge number of errors while checking in on the internet at DWeb Camp. Internet is limited, and the errors are mostly about about fetch timeouts in the differ while fetching snapshots from S3, but S3 is not reporting any issues, so it’s unclear what exactly is going wrong and hard to fix at the time.

### 2019-07-21 21:00

Rob gets home and starts looking into the issue in more detail. Sentry is mainly sending two error types:

- Timed out while fetching a snapshot from S3
- “Cannot send error response after headers written”

The second error indicates things are in a weird state, and checking the actual logs, it looks like there are issues being emitted from the process pool that actually runs the diff. Based on that, it looks like the process pool is just broken, and the only real remediation is to restart the differ pods.

### 2019-07-21 21:53

Rob restarts all the differ pods one by one using:

```sh
> kubectl delete pod <diffing_service_pod_name>
```

### 2019-07-21 22:30

After monitoring Sentry for half an hour, all errors seem to have stopped and the incident is resolved.

Plan to look into the cause and possible code fixes in more detail tomorrow.


## Lessons

### What Went Well

- Logs provided useful information about the issue.
- Resolving the incident and restarting was reasonably straightforward.


### What Went Wrong

- @Mr0grog was unavailable and largely offline for the weekend and nobody else addressed the issue.
- Most of errors Sentry was reporting were side-effects of the actual issue (broken process pool). The process pool issue was not at all immediately obvious.


## Action Items

- Look deeper into the actual cause and determine whether we could change anything to:
    - Automatically resolve similar issues.
    - Make similar issues more apparent when they occur (e.g. stop and warn about the process pool rather than warning about so many side-effects)


## Responders

- @Mr0grog
