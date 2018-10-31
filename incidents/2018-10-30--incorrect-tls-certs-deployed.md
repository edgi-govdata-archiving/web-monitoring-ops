# 2018-10-30: Incorrect TLS Certificates deployed to staging and production.

## Summary

During the initial deployment of the production namespace to the Kubernetes cluster, @jsnshrmn made configuration changes to the load balancers outside of kubectl, and did not update the certificates specified in the Kubernetes service templates afterwards.

After reorganizing the services templates weeks later, @jsnshrmn redeployed all services, to verify that no substantive changes were made. @jsnshrmn had added a security exception in his browser (accidentally making it permanent) for the incorrect certs on deployment day so that he could check the content being returned on that day. Because of this, he did not notice the incorrect certificates during his spot checks of staging and then production end points.



## Timeline

All times in CDT.

### 2018-10-08 ~18:10

During the initial deployment of the production namespace to the Kubernetes cluster, we (@danielballan, @jsnshrmn, @Mr0grog) hit a snag with getting appropriate TLS certificates provisioned, due to our DNS configuration. @jsnshrmn carelessly adds a *permanent* exception to allow the invalid certificate in his browser while troubleshooting the issue.

### 2018-10-08 ~18:40

We realized that @danielballan had manually obtained the appropriate certificates in advance. @jsnshrmn manually applies those certificates to the load balancers in the AWS console, and does not update the certificates specified in the Kubernetes service templates. Services are operational, but the conditions for failure have been set for the next deployment of services.

### 2018-10-30 09:10

Weeks later, @jsnshrmn deploys reorganized service configuration to staging (and the incorrect certs along with it), and performs a sanity check by visiting the staging ui and api endpoints in his browser. This looks fine on the surface, because his browser had a *permanent* exception to allow the invalid certificate and isn't looking very closely at the security status for the endpoints.

### 2018-10-30 12:15

@jsnshrmn deploys reorganized service configuration to production (and the incorrect certs along with it), and performs a sanity check by visiting the staging ui and api endpoints in his browser. This looks fine on the surface, because his browser had a *permanent* exception to allow the invalid certificate and isn't looking very closely at the security status for the endpoints.


### 2018-10-30 19:00

Sentry began sending alerts because versionista-scraper was encountering ssl errors while connecting to the production api endpoint.

### 2018-10-30 19:12

@jsnshrmn reports the issue on slack and begins investigating, feeling suspicious that it was related to the service template changes, but confused by the apparent functional status of the endpoints in his browser. Upon performing `curl` against the end points, he discovers the source of the false negative of his earlier checks. He removes the certificate exceptions from his browser.

### 2018-10-30 19:30

@jsnshrmn manually updates the certificates specified for the staging and production load balancers for staging and production to the correct values. Services are restored.

### 2018-10-30 19:40

@jsnshrmn corrects the certificates specified in the staging service template and redeploys. He verifies that they are *truly* correct after deployment.

### 2018-10-30 19:46

@jsnshrmn corrects the certificates specified in the production service template and redeploys. He verifies that they are *truly* correct after deployment. He copies amended service configurations back to keybase and reports in on slack.

Incident resolved.


## Lessons

### What Went Well

All infrastructure operated as documented.

### What Went Wrong

@jsnshrmn did not use a reasonable operational procedure during the initial deployment of the production namespace, nor did he adequately test the success of changes to the service configuration templates. Additionally, there were no automated post-deployment tests nor endpoint monitoring to alert anyone of the issue until the versionista-scraper ran and failed later that evening. If any of these factors were not in play, this error would have:

- never happened, or
- been identified immediately after the staging deployment, or
- been identified immediately after the production deployment, instead of many hours later


## Action Items

- @jsnshrmn will identify and implement a basic service deployment test procedure
- @jsnshrmn will identify and implement a basic service monitoring and alerting process for our staging and production endpoints


## Responders

- @jsnshrmn
