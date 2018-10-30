# Components

In the section, you will install and configure all the components necessary to
connect to and modify EDGI's Kubernetes cluster.

## This Repository

This repository contains templates that specify the configuration of the
cluster. You will need a local copy.

```sh
git clone https://github.com/edgi-govdata-archiving/web-monitoring-kube
cd web-monitoring-kube
```

## The Kubernetes Client, ``kubectl``

To operate on the cluster, we use ``kubectl``, a commandline program that runs
on your local machine, connects to the cluster, and issues commands to the
cluster.

The cluster is running version 1.10.3. Install a compatible version of the
client (>= 1.10.2, <= 1.10.4).

[Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Keybase

To share secret files containing authentication keys and other sensitive
configuration, the development team uses Keybase.

[Install Keybase](https://keybase.io/download)

If you do not have an account, you will be prompted to create one when you start
to use keybase. Ask a member of the development team to invite you to the
``edgi_wm_kube`` team.

## Kubernetes configuration

To connect to the cluster, you will need a configuration file that includes the
address of the cluster and secret authentication information. Because this file
contains secrets, it is not stored in this repository but rather shared via
Keybase.

If you are not using Kubernetes to manage any other clusters, you can simply
copy the file from Keybase:

```sh
mkdir ~/.kube
cp /keybase/team/edgi_wm_kube/kube_config.yaml ~/.kube/config
```

If you have other clusters to manage, you will have to manually merge the
contents of that file with your existing ``~/.kube/config``.

Set the context and verify that it worked:

```sh
kubectl config set-context kube.monitoring.envirodatagov.org
kubectl config current-context
```

The output should be ``kube.monitoring.envirodatagov.org``.

## Try communicating with the cluster

```sh
kubectl get nodes
```

The output should something look like:

```
NAME                                          STATUS    ROLES     AGE       VERSION
ip-172-20-63-114.us-west-2.compute.internal   Ready     node      32d       v1.10.3
ip-172-20-63-2.us-west-2.compute.internal     Ready     master    32d       v1.10.3
ip-172-20-81-52.us-west-2.compute.internal    Ready     node      32d       v1.10.3
```

## Secrets

Templates containing secret configuration parameters are stored in Keybase as
well. Copy them into your checkout of ``web-monitoring-kube`` like so:

```sh
cp /keybase/team/edgi_wm_kube/secrets.production.yaml templates/production
cp /keybase/team/edgi_wm_kube/secrets.staging.yaml templates/staging
cp /keybase/team/edgi_wm_kube/ui-secrets.production.yaml templates/production
cp /keybase/team/edgi_wm_kube/ui-secrets.staging.yaml templates/staging
```

## Services

Services provide the network endpoints to access running pods. While most services contain no sensitive information (and are therefore in version control) a few web-monitoring services require sensitive information. Templates containing our local service configuration parameters are stored in Keybase as well. Copy them into your checkout of ``web-monitoring-kube`` like so:

```sh
cp /keybase/team/edgi_wm_kube/services.production.yaml templates/production
cp /keybase/team/edgi_wm_kube/services.staging.yaml templates/staging
```

## Getting Oriented

In ``templates/``, there are separate directories corresponding to the
*namespaces* in the Kubernetes cluster.

* ``kube-system`` -- cluter-wide objects related to capturing logs
* ``production`` -- objects deployed to the production namespace
* ``staging`` -- objects deployed to the staging namespace

The contents of the templates in ``production/`` and ``staging/`` differ only by
their ``namespace: ...`` parameter and the values of the secrets.
