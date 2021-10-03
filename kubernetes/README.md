# Kubernetes Configuration

This directory hosts information about and configuration files for our Kubernetes cluster. The cluster has three namespaces:

- [`production`](./production) contains all our production services.
- [`staging`](./staging) is a small mirror of production. It has less data and less compute resources, and may have its data reset at any time. It’s designed for more open, loose access so people can test new code against it. We occasionally deploy new releases to staging before production in order to test it, but usually we deploy to both and control what features are turned on with environment variables instead.
- [`kube-system`](./kube-system) contains infrastructural services that need to work across the cluster, like tools for logs and metrics.

Configuration files are stored in directories with the same name as the namespace.

See [`0-setup-guide`](./0-setup-guide) for a guide to setting up a new cluster from scratch.


## Secrets

Our deployment needs access to some sensitive data, like credentials, ARNs, etc. We keep configurations for those in a separate secure repository, but they are still Kubernetes configurations that can be deployed the same way the rest of the configurations here are. **You can find example versions of these files named `example.*.yaml` in this directory.**


## Updating the Cluster

We use the `kubectl` CLI client to update the resources in the cluster with new configurations. You’ll need to configure it on your computer with the address and keys for our cluster. Common workflows:


### Deploying a New Release

Let’s say you want to deploy release `c5a9e6de994392f23967cef3b2b916ac4d6ca87d` of web-monitoring-db:

1. Find the deployment configuration files in `production` and `staging` and update them. In this example, you’d edit:

    - [`staging/api-deployment.yaml`](./staging/api-deployment.yaml)
    - [`production/api-deployment.yaml`](./production/api-deployment.yaml)
    
    …and update the `spec.template.spec.containers.image` property to the new correct tag:
    
    ```yaml
    spec:
      containers:
      - name:  rails-server
        image: envirodgi/db-rails-server:c5a9e6de994392f23967cef3b2b916ac4d6ca87d
        imagePullPolicy: Always
    ```

2. Use `kubectl replace -f <config-file-path>` or `kubectl apply -f <config-file-path>` to deploy to the cluser:

    ```sh
    > kubectl replace -f staging/api-deployment.yaml
    > kubectl replace -f production/api-deployment.yaml
    ```

3. Keep an eye on deployment progress with `kubectl get pods`:

    ```sh
    > kubectl get pods --namespace production
    NAME                             READY   STATUS    RESTARTS   AGE
    api-74f8dcf857-j9cpc             1/1     Running   0          16d
    api-74f8dcf857-k29qh             1/1     Running   1          16d
    diffing-5b4f87c9d6-bhk25         1/1     Running   0          1d
    diffing-5b4f87c9d6-dqr4b         1/1     Running   0          1d
    import-worker-85578ccd65-c2bwr   1/1     Running   0          16d
    import-worker-85578ccd65-wvqnt   1/1     Running   3          16d
    redis-master-6c46f6cfb8-gh94g    1/1     Running   0          152d
    redis-slave-584c66c5b5-kqbtt     1/1     Running   1          187d
    redis-slave-584c66c5b5-psstd     1/1     Running   0          152d
    ui-7ff6d77fdb-rkmhr              1/1     Running   1          41d
    ui-7ff6d77fdb-s8ddp              1/1     Running   0          41d
    ```


### Restarting a Pod

Kubernetes works by keeping an eye on everything in the cluster and constantly updating it to make sure it stays in spec with the configuration. Most of the time, Kubernetes will automatically restart a pod that is stuck in a bad state.

If you need to reset a pod manually for some reason, the easiest way is just to delete it! Kubernetes will then create a new one in its place so that the right number of pods is running:

1. List the pods and find the one you want:

    ```sh
    > kubectl get pods --namespace production
    NAME                             READY   STATUS    RESTARTS   AGE
    api-74f8dcf857-j9cpc             1/1     Running   0          16d
    api-74f8dcf857-k29qh             1/1     Running   1          16d
    diffing-5b4f87c9d6-bhk25         1/1     Running   0          1d
    diffing-5b4f87c9d6-dqr4b         1/1     Running   0          1d
    import-worker-85578ccd65-c2bwr   1/1     Running   0          16d
    import-worker-85578ccd65-wvqnt   1/1     Running   3          16d
    redis-master-6c46f6cfb8-gh94g    1/1     Running   0          152d
    redis-slave-584c66c5b5-kqbtt     1/1     Running   1          187d
    redis-slave-584c66c5b5-psstd     1/1     Running   0          152d
    ui-7ff6d77fdb-rkmhr              1/1     Running   1          41d
    ui-7ff6d77fdb-s8ddp              1/1     Running   0          41d
    ```

2. Delete the pod. Sometimes this command can take a while:

    ```sh
    > kubectl delete pod --namespace production diffing-5b4f87c9d6-dqr4b
    pod "diffing-5b4f87c9d6-dqr4b" deleted
    ```

3. Keep an eye on the recreation progress with `kubectl get pods`.


### Check Jobs

Kubernetes CronJobs work by *creating* Jobs on a set schedule. You can check the CronJobs with:

```sh
> kubectl get cronjobs
```

And check the concrete jobs they’ve created with:

```sh
> kubectl get jobs
```

And you’ll also see pods created for the different jobs when you `kubectl get pods`.

**Get job run times.** `Kubectl` doesn’t give durations (oddly), so this jq snippet will do that:

```sh
> kubectl get jobs --namespace production --output json | jq '.items[] | (.status.completionTime | fromdateiso8601) as $completion | (.status.startTime | fromdateiso8601) as $start | {name: .metadata.name, date: .status.startTime, duration: ($completion - $start)}'
```


### Updating Kubernetes Itself

Kubernetes has new releases every few months, and it’s important to keep our cluster running a reasonably up-to-date version, both to alleviate security issues and to make future upgrades straightforward. We use [kOps](https://kops.sigs.k8s.io/) to manage our Kubernetes install on AWS. kOps does not always update as frequently as Kubernetes itself, but the kOps team does a pretty good job of making things reliable, so we tend to stick with Kubernetes versions that production releases of kOps supports.

First, [get yourself a copy of kOps](https://kops.sigs.k8s.io/getting_started/install/) and keep it up to date. If you’re on a Mac, *Homebrew* is the easiest way to get it:

```sh
$ brew update && brew install kop
```

Then, to update the cluster, follow the instructions at: https://kops.sigs.k8s.io/operations/updates_and_upgrades/#upgrading-kubernetes

Some things to keep in mind:

- You'll probably want to set up the `KOPS_STATE_STORE` environment variable. It points to the S3 bucket where our cluster state information is stored (contact another team member for the bucket name):

    ```sh
    $ export KOPS_STATE_STORE='s3://<name_of_s3_bucket>'
    ```

- NEVER update across multiple major releases (e.g. don’t update from Kubernetes 1.21.x to 1.23.x). Doing this in the past has frequently caused issues. If there have been multiple major relases, follow the “manual update” instructions all the way through once for each major version. Verify the cluster is in good shape and everything is running correctly (can you reach the API? can you view the UI?) between each.

- The `kops rolling-update cluster` command can take a really long time — anywhere from 10 to 40 minutes. That’s OK! To see progress in slightly more detail, you can keep an eye on EC2 instances in the AWS web console (you can see them launching and shutting down there before they might be visible to kOps).
