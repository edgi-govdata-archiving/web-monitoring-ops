# 2018-10-09: API & Import Worker Infinitely Rebooting on Staging

## Summary

After updating the `api` and `import-worker` deployments, Kubernetes was stuck in a loop infinitely rebooting them. It turns out that this was caused by a badly base64-encoded secret. Specifically `cache-date-differ` ended with a newline character.

Updating the secrets to have a correct value and then replacing `api-deployment.yaml` and `import-worker-deployment.yaml` (by updating the `INCREMENTAL_UPDATE` env var) resolved the issue. It appears this happened because we pushed new secrets to staging *after* all the other deployment configs, so the issue didn’t crop up until the the next deployment change that used those secrets.


## Timeline

All times in PDT.

### 2018-10-09 17:15

@Mr0grog pushed new deploy configurations to the cluster for both staging and production. Staging immediately started rebooting repeatedly; production was fine.

### 2018-10-09 17:20

@Mr0grog tried deleting the rebooting pods (rookie move, me!), which just made more rebooting pods.

### 2018-10-09 17:25

@Mr0grog checking the logs reveals only one log line, which is cryptic:

```
starting container process caused "process_linux.go:295: setting oom score for ready process caused write /proc/3002/oom_score_adj: invalid argument
```

Luckily, stackoverflow [gave us a good lead](https://stackoverflow.com/questions/49296359/kubernetes-secret-in-google-container-engine-fails-setting-oom-score-for-read) that the problem might be in decoding secrets. We checked all the secrets and noted that `cache-date-differ`, when decoded, ended with a newline, which seemed wrong. Re-encoding the correct value, replacing the secrets in the cluster, then replacing the deployment configs immediately resolved the issue.

### 2018-10-09 17:30

Incident resolved.


## Lessons

### What Went Well

Kubernetes did its job swimmingly — although we were having problems, the staging environment was up and available the whole time (it never replaced one of the pods because the others were still restarting). At first, @Mr0grog was freaking out, but he quickly realized the staging service was still available the whole time. This was a huge relief.

### What Went Wrong

That is one cryptic and unhelpful error message. It’s also still unclear what the *real* issue was. The secrets value in question decoded fine; it just ended with a newline. Was Kubernetes choking on the newline? Or was the server crashing when it booted and tried to parse the string as a date, but Kubernetes swallowed what would have been a useful error log line and threw out the confusing error instead?


## Action Items


- We should only use the binary Data field where it is useful to have base64-encoded values. Examples could include actual binary data, or string data that would require some of its characters to be escaped. @jsnshrmn will stringify our secrets where convenient so that we can avoid the error-prone process of manually base64-encoding every secret.
- Determine if additional measures, such as a script or system for validating our secrets files, are necessary.


## Responders

- @Mr0grog
