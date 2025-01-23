# Amazon RDS (Relational Database Service)

The Postgres database that backs [web-monitoring-db][] is managed through Amazon RDS, and so is manually configured instead of through Kubernetes. To provide access to Kubernetes, we use an “external” service named `rds`. See [`/examples/services.yaml`][services-example] in this repo for an example.

## Databases

`web-monitoring-db-production-b` is the production database (the `-b` is because it is the successor to an older production database). It is configured as:

- Instance: **db.t4g.medium** (This doesn’t really have as much RAM as we’d like for big queries. It’s cost-effective for our current usage, however.)
- Database: **Postgres 17.x**
- Storage: **20+ GB Standard SSD** with autoscaling
- VPC: **Same VPC as Kubernetes**
- Security Groups: **Kubernetes security group** + **custom Postgres security group** for external access.
- Custom parameter group based on the defaults. The JSON configuration for the parameter group is in [`web-monitoring-db-production-b-params.json`][web-monitoring-db-production-b-params] [(see below)](#other-notes), but with these modifications:
    - `work_mem` 16 MB (much bigger than default, which is 1 MB, but not huge)
    - `shared_buffers` 2/5 of available memory
    - `effective_cache_size` 3/4 of available memory

(We used to have a separate staging database, but the staging deployment has been turned off.)


## Upgrading

The database should be set to automatically update minor releases. However, major releases need to be done manually:

1. Create a new parameter group for the intended Postgres version. Parameter groups are specific to major database versions, so you need to make one for the version you are upgrading to before upgrading the database.

    1. In the RDS section of the AWS console, select “Parameter Groups” in the sidebar.
    2. Click the “Create Parameter Group” button.
    3. Choose the appropriate Postgres version and fill in a name and description and click “create.”
    4. Click on the new parameter group to view its details, then click “Edit parameters” in the top right to edit.
    5. Find the parameters we customize (noted above) and set them to match the values from the old parameter group. You can use the [`web-monitoring-db-production-b-params.json`](./web-monitoring-db-production-b-params.json) file in this repo to get the values or look at the old group in the AWs console.
    6. Click “save” in the top-right.

2. Modify the database.

    1. In the RDS section of the AWS console, select “Databases” in the sidebar.
    2. Click on the database you want to upgrade to change its details.
    3. Click “modify” in the top right.
    4. Choose the desired Postgres version, and further down on the page, choose the new parameter group you created in step 1.
    5. On the next screen, confirm that the major version and the parameter group are the only things that are changing.
    6. Choose whether to schedule the upgrade for you next maintenance window (recommended in most cases) or to do it right away, and save!
    7. The upgrade will probably take 5-15 minutes. You can see the database’s status in the database list view from step 2.1.


## References

These docs were helpful in getting our RDS instances set up well:

- [Tuning Your PostgreSQL Server (Postgres Wiki)](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [Server Configuration Tuning in PostgreSQL (Packt Pub)](https://hub.packtpub.com/server-configuration-tuning-postgresql/)
- [Tuning Postgres on MacOS](http://big-elephants.com/2012-12/tuning-postgres-on-macos/) (Useful for its clear descriptions, but don’t follow the advice directly, since it’s focused around a dev server with few connections and small-ish data, not a production one.)
- [Common DBA Tasks for PostgreSQL (AWS Docs)](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html)
- [Working with DB Parameter Groups (AWS Docs)](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html)
- [Configuring memory for Postgres](https://www.citusdata.com/blog/2018/06/12/configuring-work-mem-on-postgres/) offers really useful guidance on `work_mem`, which is apparently often misunderstood, and which can be thorny to optimize.
- [Is Your Postgres Query Starved for Memory?](http://patshaughnessy.net/2016/1/22/is-your-postgres-query-starved-for-memory) Even more useful details on `work_mem`.
- [Increasing work_mem and shared_buffers on Postgres 9.2 significantly slows down queries (StackExchange)](https://dba.stackexchange.com/questions/27893/increasing-work-mem-and-shared-buffers-on-postgres-9-2-significantly-slows-down)
- [Performance Tuning Queries in PostgreSQL](https://www.geekytidbits.com/performance-tuning-postgres/)

Using `pg_table_size`, `pg_relation_size`, `pg_total_relation_size`, `pg_indexes_size`, etc. was also extremely helpful in understanding the actual memory needs and tradeoffs involved in configuring memory settings and in determining instance size. [“How to Get Table, Database, Indexes, Tablespace, and Value Size in PostgreSQL”](http://www.postgresqltutorial.com/postgresql-database-indexes-table-size/) is a good reference for that.


## Other Notes

The parameter groups file can be generated with the AWS CLI app:

```sh
aws rds describe-db-parameters --db-parameter-group-name web-monitoring-db-production-b-params-17 > ./manually-managed/rds/web-monitoring-db-production-b-params.json
```

**Parameter Expressions:** AWS allows you to use expressions and variables for some settings, but they are limited and can wind up looking kind of funny. For example, `shared buffers` is:

```
{DBInstanceClassMemory*2/40960}
```

`DBInstanceClassMemory` is in bytes, but the unit for this value is 8 KB chunks, so this expression would ideally be broken down like:

```
{ DBInstanceClassMemory * (2 / 5) * (1 / (8 * 1024)) }
  ^ Available mem          ^ Ratio   ^ Convert to units of 8 KB
```



[web-monitoring-db]: https://github.com/edgi-govdata-archiving/web-monitoring-db
[web-monitoring-db-production-a-params]: ./web-monitoring-db-production-a-params.json
[services-example]: ../../examples/services.yaml
