# Manually Managed Services

While most of our infrastructure is managed with Kubernetes, several stateful services and other components are managed separately. At current, these are managed manually, but we are considering the best tools for this, e.g. Ansible. (If you have expertise or time to contribute here, let us know in the issues or on [Slack](https://archivers-slack.herokuapp.com/)!)


## Redis Cache

We use Redis for caching and for queuing in Rails (that is, in [web-monitoring-db][-db]). Our Redis caching instance is currently hand-managed as an EC2 machine on AWS. Its current configuration (excepting the password) can be found in [`redis-cache.conf`](./redis-cache.conf). It also has an elastic IP.

The VM and other related resources (e.g. Elastic IP) are named `wm-cache-*`.

This should *probably* be a cluster (and maybe managed via AWS Elasticache?), but this has been working alright for now.


## Redis Queues

The asynchronous jobs that are part of the [web-monitoring-db][-db] codebase (for importing data, sending e-mails, and auto-analyzing versions) are based on Redis. At current, they are managed within Kubernetes, but that means they are prone to losing their state. These should be moved to AWS Elasticache or some manually managed system in the future (we may also move off Redis for our queues, too).

TBD


## Postgres via RDS

[Web-monitoring-db’s][-db] database is a PostgreSQL database managed via RDS. We have separate production and staging databases, and connect to them via a Kubernetes service.

For details, see [`rds/README.md`](./rds/README.md).


## ETL

We currently run scheduled scripts for extracting data from external services (Versionista, the Wayback Machine) and sending it to [web-monitoring-db][-db] to be imported. These are managed via `cron` on a single EC2 VM.

For details, see [`etl-server/README.md`](./etl-server/README.md).


## IA Archiver

We have an EC2 VM named `ia-archiver` that pushes lists of URLs to the Internet Archive’s “Save Page Now” feature on a regular basis. More information about this is in [`ia-archiver`](./ia-archiver). It’s mainly just an implementation of [wayback-spn-client].


[-db]: https://github.com/edgi-govdata-archiving/web-monitoring-db
[wayback-spn-client]: https://github.com/Mr0grog/wayback-spn-client

## Metrics Server

We use Elasticserach and its Kibana front-end for metrics collection and
visualization. See the metrics-server directory in this repository for
provisioning and configuration details.
