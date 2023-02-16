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


## CloudFront & WAF

To protect the production instance of the API from from abuse, we point the DNS records for the API to CloudFront (AWS’s CDN) instead of directly to the API service’s load balancer. We also add some WAF (firewall) rules to the CloudFront distribution.

- CloudFront…
    - Needs a separate SSL certificate in the `us-east-1` (N. Virginia) region. It’s set up the same way certificates are set up for the rest of the Kubernetes cluster in AWS Certificate Manager.
    - Is in the NA/Europe price class.
    - The origin:
        - Uses the domain of the API service in the Kubernetes cluster (not a direct reference to the load balancer).
        - Is HTTPS-only.
        - Uses origin shield.
    - Has a default behavior that:
        - Redirects HTTP to HTTPS
        - Allows all HTTP methods
        - Caches GET, HEAD, OPTIONS
        - Forwards all headers to the origin (the `AllViewer` origin request policy)
        - Has a cache policy that:
            - Includes `Authorization` and `Accept` headers and `_webpage-versions-db_session` cookies, and all query strings in the cache key.
            - Compression support is enabled.
- There is a WAF ACL attached to the CloudFront distribution.
    - It uses the `AWS-AWSManagedRulesKnownBadInputsRuleSet` built-in rule set.
    - It uses a `per-ip-rate-limit` rule to block IP addresses requesting over a certain rate.


## 📦 Deprecated Services

⚠️ These services used to be managed manually, but have either been shut down or moved to a different, automated approach. The documentation here is for historical reference.


### ETL

**These are now all Kubernetes `CronJob` resources.** We used to run scheduled scripts for extracting data from external services (Versionista, the Wayback Machine) and sending it to [web-monitoring-db][-db] to be imported via `cron` an a single EC2 VM. For details, see [`etl-server/README.md`](./etl-server/README.md).

For details, see [`etl-server/README.md`](./etl-server/README.md).


### IA Archiver

**We no longer do this.** We have an EC2 VM named `ia-archiver` that pushes lists of URLs to the Internet Archive’s “Save Page Now” feature on a regular basis. More information about this is in [`ia-archiver`](./ia-archiver). It’s mainly just an implementation of [wayback-spn-client].


[-db]: https://github.com/edgi-govdata-archiving/web-monitoring-db
[wayback-spn-client]: https://github.com/Mr0grog/wayback-spn-client


### Metrics Server

**We no longer maintain a metrics service.** We ised to use Elasticserach and its Kibana front-end for metrics collection and visualization. See the metrics-server directory in this repository for provisioning and configuration details.
