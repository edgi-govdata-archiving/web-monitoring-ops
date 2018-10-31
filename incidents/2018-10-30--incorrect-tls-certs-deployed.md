# 2018-10-30: Incorrect TLS Certificates deployed to staging and production.

## Summary

When we originally deployed the Kubernetes cluster, we hit a snag with getting appropriate TLS certificates provisioned, due to our DNS configuration. We realized that @danielballan had manually obtained the appropriate certificates in advance. At that time, @jsnshrmn manually applied those certificates to the load balancers in the AWS console, but did not update the certificates specified in the Kubernetes service templates.

After reorganizing the services templates, @jsnshrmn redeployed all services, to verify that no substantive changes were made. @jsnshrmn had added a security exception in his browser (accidentally making it permanent) for the incorrect certs on deployment day so that he could check the content being returned on that day. Because of this, he did not notice the incorrect certificates during his spot checks of staging and then production end points.



## Timeline

All times in PDT.

...


## Lessons

### What Went Well

...

### What Went Wrong

...


## Action Items

...


## Responders

- @jsnshrmn
