# Amazon RDS (Relational Database Service)

The Postgres database that backs [web-monitoring-db][] is managed through Amazon RDS, and so is manually configured instead of through Kubernetes. To provide access to Kubernetes, we use an “external” service named `rds`. See [`/examples/services.yaml`][services-example] in this repo for an example.

## Databases

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
              ^ Available mem          ^ Ratio   ^ Convert to units of 8 KB
            ```

2. `web-monitoring-db-staging-aws-west2a` is the staging database. It is configured as:
    - Instance: **db.t2.small**
    - Database: **Postgres 9.x**
    - Storage: **20 GB Standard SSD**
    - VPC: **Default VPC**
    - Security Groups: **Default**
    - Parameters: **Default**


## References

These docs were helpful in getting our RDS instances set up well:

- [Tuning Your PostgreSQL Server (Postgres Wiki)](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [Server Configuration Tuning in PostgreSQL (Packt Pub)](https://hub.packtpub.com/server-configuration-tuning-postgresql/)
- [Tuning Postgres on MacOS](http://big-elephants.com/2012-12/tuning-postgres-on-macos/) (Useful for its clear descriptions, but don’t follow the advice directly, since it’s focused around a dev server with few connections and small-ish data, not a production one.)
- [Configuring memory for Postgres](https://www.citusdata.com/blog/2018/06/12/configuring-work-mem-on-postgres/) offers really useful guidance on `work_mem`, which is apparently often misunderstood, and which can be thorny to optimize.
- [Is Your Postgres Query Starved for Memory?](http://patshaughnessy.net/2016/1/22/is-your-postgres-query-starved-for-memory) Even more useful details on `work_mem`.
- [Increasing work_mem and shared_buffers on Postgres 9.2 significantly slows down queries (StackExchange)](https://dba.stackexchange.com/questions/27893/increasing-work-mem-and-shared-buffers-on-postgres-9-2-significantly-slows-down)
- [Performance Tuning Queries in PostgreSQL](https://www.geekytidbits.com/performance-tuning-postgres/)

Using `pg_table_size`, `pg_relation_size`, `pg_total_relation_size`, `pg_indexes_size`, etc. was also extremely helpful in understanding the actual memory needs and tradeoffs involved in configuring memory settings and in determining instance size. [“How to Get Table, Database, Indexes, Tablespace, and Value Size in PostgreSQL”](http://www.postgresqltutorial.com/postgresql-database-indexes-table-size/) is a good reference for that.



[web-monitoring-db]: https://github.com/edgi-govdata-archiving/web-monitoring-db
[web-monitoring-db-production-a-params]: ./web-monitoring-db-production-a-params.json
[services-example]: ../../examples/services.yaml
