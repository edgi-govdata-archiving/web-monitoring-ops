# Manually Managed Services

While most of our infrastructure is managed with Kubernetes, several stateful services and other components are managed separately. At current, these are managed manually, but we are considering the best tools for this, e.g. Ansible. (If you have expertise or time to contribute here, let us know in the issues or on Slack!)


## Redis Cache

We use Redis for caching and for queuing in Rails (that is, in `web-monitoring-db`). Our Redis caching instance is currently hand-managed as an EC2 machine on AWS. Its current configuration (excepting the password) can be found in [`redis-cache.conf`](./redis-cache.conf).

This Redis instance has an Elastic IP.

This should *probably* be a cluster (and maybe managed via AWS Elasticache?), but this has been working alright for now.


## Redis Queues

The asynchronous jobs that are part of the `web-monitoring-db` codebase (for importing data, sending e-mails, and auto-analyzing versions) are based on Redis. At current, they are managed within Kubernetes, but that means they are prone to losing their state. These should be moved to AWS Elasticache or some manually managed system in the future (we may also move off Redis for our queues, too).

TBD


## Postgres via RDS

Web-monitoring-db’s database is a PostgreSQL database managed via RDS.

TBD


## ETL

We currently run scheduled scripts for extracting data from external services (Versionista, the Wayback Machine) and sending it to web-monitoring-db to be imported. These are managed via `cron` on a single EC2 VM.

TBD
