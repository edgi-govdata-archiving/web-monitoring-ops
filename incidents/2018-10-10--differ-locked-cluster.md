# 2018-10-10: Diff Service Locked Up the Whole Cluster

## Summary

The diffing service consumed all resources in all cluster nodes, locking up not only itself but also all our other services (API, Import Worker, UI, Redis). This appears to have happened as a result of the new automated analysis job (see https://github.com/edgi-govdata-archiving/web-monitoring-db/pull/406) requesting a source code diff of a PDF and an HTML page, specifically the change:

```
0c2f9d24-df8e-48b4-919b-7d1eca02d3c4..7c9904f4-c090-4f0d-8c3f-ba3dc4fade25
```


## Timeline

All times in PDT.

### 2018-10-10 15:30

@Mr0grog pushed the new analysis code to production (https://github.com/danielballan/web-monitoring-kube/commit/22450e3120f80b53d753b46988e6085f88ed707d) and queued a day’s worth of analysis jobs. He watched the first ~350 work successfully, then headed to a meeting.

### 2018-10-10 16:45

@Mr0grog checked in on the analysis progress between meetings (Web Monitoring Analyst meeting was at 17:00) only to find that the cluster had spun up about 9 pods for each type of deployment, with each being listed as unknown status.

@Mr0grog posted the situation in Slack and proceeded to try and delete some pods and to look at the flood of errors starting on Sentry. Errors make it clear that the analysis job is hitting problems, so it appears this is another instance of the diff service running amok.

### 2018-10-10 17:12

@jsnshrmn signs on to help. Now that we have an idea of cause and two people, @jsnshrmn works on addressing Kubernetes, @Mr0grog works on patching code to avoid triggering the problem.

### 2018-10-10 17:28

@jsnshrmn clears out testing resources of all types (`kubectl --namespace=testing delete all --all`) since they are of only ocassional value, but were still consuming some resources. The remaining resources were forcibly removed (`kubectl --namespace=staging delete pods --all --force --grace-period=0` because they were stuck in an "Unknown" state.

@jsnshrmn clears out the cluster’s production resources by deleting each deployment (`kubectl delete deployment.apps/<appname>`) which should have deleted all pods. This tooks several minutes per deployment because many pods were in an "Unknown" state, and could not be gracefully evicted, eventually timing out. @jsnshrmn tries to gracefully shut down the remain pods which were all in an "Unknown" state (`kubectl --namespace=production delete pods --all`) and (`kubectl --namespace=production delete pod/<podname>`), but without success. 

@jsnshrmn forcefully deleted all remaining pods (`kubectl --namespace=staging delete pods --all --force --grace-period=0`). This quiets things down. We think it is safe to start services again since we won’t have saved the state of any queues, so no more analysis jobs will be queued.

### 2018-10-10 17:34

@Mr0grog finishes writing a hotfix (https://github.com/edgi-govdata-archiving/web-monitoring-db/commit/6ea87de05d52d823f989e531dc1a600e25edab25) that basically causes the analysis job to check the URL for any file extensions that might indicate non-HTML content.

### 2018-10-10 17:42

@jsnshrmn also clears out all staging resources (we noticed that staging was still stuck, probably because everything is sharing just a couple nodes).

### 2018-10-10 17:45

Hotfix image is published.

### 2018-10-10 17:50

All services and deployments are recreated in staging and production (with the hotfix).

### 2018-10-10 17:55

Kubectl reports that all pods are stuck in a pending state.

### 2018-10-10 18:02

@jsnshrmn hard restarts one of the cluster nodes from the AWS console. That seems to give Kubernetes a nice kick in the pants and the pods start coming up.

### 2018-10-10 18:15

All nodes have been restarted, all pods in staging and production appear to be up and operational. Incident appears to be resolved.

### 2018-10-10 22:40

Issue recurs. @Mr0grog writes another hotfix that simply stops the problematic behavior (optimistically trying a diff if we aren’t sure that it won’t work): https://github.com/edgi-govdata-archiving/web-monitoring-db/commit/0a46db02b78d8332f974b86eafff067a09eb3ac2

### 2018-10-10 22:50

Pods still seem stuck. @Mr0grog attempts to stop one of the nodes; instead the node winds up terminated (not actually sure what happened here; it seems like Kubernetes did this itself when stopping ocurred; it looks like we should have been more careful to delete all services and pods first) and Kubernetes auto-created a new node.

### 2018-10-10 22:58

New node comes online and services are accessible, but clearly not stable. Sentry reports lots of odd connectivity errors and `kubectl` still reports lots of unknown status pods. @Mr0grog decides to give it a break for 30 minutes until imports complete before doing anything more damaging.

### 2018-10-10 23:35

Sentry errors seem to have stopped, all the parts of the cluster can communicate, and bad pods are no longer reported. It probably just took some time for everything to settle out after Kubernetes terminated and recreated a whole node.

@Mr0grog starts long Versionista archive job to recover data lost from 15:00 through now.

### 2018-10-10 23:55

Versionista jobs complete without major problems. Incident appears to be over.

### 2018-10-11 07:26

@jsnshrmn determines that implementing resource limits in a verifiable way requires core metrics, a set of services that are deployed by default in Kubernetes, but not in our KOPS deployment. Builtin diagnostic tools like `kubectl top <pods|nodes>` aren't working. @jsnshrmn notices that a previously deployed metrics gathering framework based on Prometheus and Grafana is broken.

### 2018-10-11 08:01

@jsnshrmn gets verification from @dallan that the old metrics framework can be deleted and does so (`kubectl --namespace=monitoring delete all --all; kubectl delete namespaces monitoring`).

### 2018-10-11 08:28

While checking the `kube-system` namespace (where core metrics would be deployed), @jsnshrmn discovered that pods related to proxy and logging are not functioning correctly. 

### 2018-10-11 08:40

@jsnshrmn Performs `kubectl --namespace=kube-system inspect|logs` on pod, deployments, and consistently show various communication errors in various layers of the stack.

### 2018-10-11 09:07

@jsnshrmn notices that one of the errors shown in the proxy logs on this node is related to the dns pod that should be providing services for the node. @jsnshrmn deletes the dns node, and performs `kubectl --namespace=kube-system logs pods/<dnspodname>` and finds `Error response from daemon: grpc: the connection is unavailable`, yet another network error, this time from a pod that reported it was working before deletion. @jsnshrmn stops/starts the node via the EC2 console.

### 2018-10-11 11:35

Basic troubleshooting tools now work. Incident resolved.


## Lessons

### What Went Well

Since we didn't configure the Kubernetes master node as a cluster node too, it stayed up; meaning that the cluster could be communicated with via kubectl. Our data, which is stored in an external database and AWS S3 buckets, was not lost. The Kubernetes scheduler behaved as documented.

### What Went Wrong

There is no magic in the Kubernetes scheduler. If it hasn't been given any specifications regarding the resources that may normally be consumed by a container, it assumes the container will consume *no resources at all* and may attempt to deploy infinite containers to a node. Additionally, if no resource limits are set, a single container is allowed to consume more than 100% of the resources on a node, potentially knocking it offline. We supplied the scheduler with no information about how many containers should be running simultanously on a single node nor resource limits for any of our containers. Because of this, the problematic diffing containers overwhelmed one node (which they were all deployed to) causing it to become unavailable. The scheduler dilligently noted that the specified number of container replicas were no longer available, and redeployed to the remaining cluster node to come into compliance with the replica count specified. Once the diffing pod was operational again, it then knocked the only remaining cluster node offline, leaving us with an outage.


## Action Items

- Look into ways to set resource limits or node affinity ([processing#154](https://github.com/edgi-govdata-archiving/web-monitoring-processing/issues/154))
- Clean up the ugly hotfix code ([db#411](https://github.com/edgi-govdata-archiving/web-monitoring-db/issues/411))
- Protect `html_text_dmp` and `html_source_dmp` with content-type checking and sniffing ([processing#287](https://github.com/edgi-govdata-archiving/web-monitoring-processing/issues/287))


## Responders

- @Mr0grog
- @jsnshrmn
