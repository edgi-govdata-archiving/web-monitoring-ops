# Amazon RDS (Relational Database Service)

The Postgres database that backs [web-monitoring-db][] is managed through Amazon RDS, and so is manually configured instead of through Kubernetes. To provide access to Kubernetes, we use an “external” service named `rds`. See [`/examples/services.yaml`][services-example] in this repo for an example.

We have two databases:

1. `web-monitoring-db-production-a` is the production database (the `-a` is because it is the successor to an older produciton database). It is configured as:

    - Instance: **db.t3.medium** (This doesn’t really have as much RAM as we’d like for big queries, and we expect that if we make the system public access, this will definitely have to be upgraded. It’s cost-effective for our current usage, however.)
    - Database: **Postgres 11.x**
    - Storage: **20+ GB Standard SSD** with autoscaling
    - VPC: **Same VPC as Kubernetes**
    - Security Groups: **Kubernetes security group** + **custom Postgres security group** for external access.
    - Custom parameter group based on the defaults. The JSON configuration for the parameter group is in [`web-monitoring-db-production-a-params.json`][web-monitoring-db-production-a-params], but with these modifications:
        - `work_mem` 16 MB (much bigger than default, which is 1 MB, but not huge)
        - `shared_buffers` 2/5 of available memory
        - `effective_cache_size` 3/4 of available memory
        - A note about the above: AWS allows you to use expressions for things like the above that involve available memory, but they are limited and can wind up looking kind of funny. For example, `shared buffers` is:

            ```
            {DBInstanceClassMemory*2/40960}
            ```

            `DBInstanceClassMemory` is in bytes, but the unit for this value is 8 KB chunks, so this expression would ideally be broken down like:

            ```
            { DBInstanceClassMemory * (2 / 5) * (1 / (8 * 1024)) }
            ```

2. `web-monitoring-db-staging-aws-west2a` is the staging database. It is configured as:
    - Instance: **db.t2.small**
    - Database: **Postgres 9.x**
    - Storage: **20 GB Standard SSD**
    - VPC: **Default VPC**
    - Security Groups: **Default**
    - Parameters: **Default**


[web-monitoring-db]: https://github.com/edgi-govdata-archiving/web-monitoring-db
[web-monitoring-db-production-a-params]: ./web-monitoring-db-production-a-params.json
[services-example]: ../examples/services.yaml
