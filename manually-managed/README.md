# Manually Managed Services

While most of our infrastructure is managed with Kubernetes, several stateful services and other components are managed separately. At current, these are managed manually, but we are considering the best tools for this, e.g. Ansible. (If you have expertise or time to contribute here, let us know in the issues or on [Slack](https://archivers-slack.herokuapp.com/)!)


## Redis Cache

We use Redis for caching in Rails (that is, in [web-monitoring-db][-db]). Our Redis caching instance is currently hand-managed as an EC2 machine on AWS. Its current configuration (excepting the password) can be found in [`redis-cache.conf`](./redis-cache.conf). It also has an elastic IP.

The VM and other related resources (e.g. Elastic IP) are named `wm-cache-*`.

This should *probably* be a cluster (and maybe managed via AWS Elasticache?), but this has been working alright for now.


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


## IAM Access Key Expiration

*This is not specific to Web Monitoring, but is a security concern for the AWS account it runs in.*

We have some tools and scripts that use IAM access keys to get stuff done with AWS APIs (e.g. uploading to S3), but access keys unfortunately do not expire. That creates a big risk! (AWS has some nice solutions for OIDC and short-lived keys, but we have plenty of code that is not (yet?) compatible with that.)

The CloudFormation template in [`expire-old-access-keys.yaml`](./expire-old-access-keys.yaml) creates a set of roles, policies, and configurations in AWS that will automatically expire old access keys and send warnings to an SNS topic about keys that are near expiration. To set it up:

1. Ensure you have an SNS (Simple Notification Service) topic for admins to subscribe to and be notified about expiring access keys.

    If you don’t already have one, you can create a topic in the AWS console at: https://us-west-2.console.aws.amazon.com/sns/v3/home. Name the topic anything you like, and then add the appropriate e-mail addresses or phone numbers for people who should be alerted about expiring keys (e.g. yourself). SNS topics are basically message queues that can be subscribed to via e-mail, SMS, or mobile push messages.

    Note the ARN for your SNS topic.

2. In [CloudFormation](https://us-west-2.console.aws.amazon.com/cloudformation/home)…
    1. click the “create stack” button (a stack is a set of resources in AWS that are controlled together by a template). Then upload the [`expire-old-access-keys.yaml`](./expire-old-access-keys.yaml) file as the template to use.
    2. On the next screen, give it an understandable name and fill in the parameters as appropriate: when you want keys to expire, when you want warnings about near-expiration keys, and the ARN for your SNS topic from step 1.
    3. Follow the rest of the steps to instantiate the template.
    4. You should be done and good to go!


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
