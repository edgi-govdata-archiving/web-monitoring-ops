# ETL Server

This machine runs ETL (Extract, Transform, and Load) scripts to pull page & version data out of other services (like the Internet Archive or Versionista) and import it into a [web-monitoring-db][] instance. The core code for most of that lives in other web-monitoring-* repositories; this server just uses cron and some very simple bash scripts to execute them and save logs.

Specifically, this server currently performs four tasks:

1. Import data from the Internet Archive. [(IA import script in web-monitoring-processing)][ia-import-script]
2. Healthcheck for Internet Archive scrapers. Our scraper at the Internet Archive has occasionally had issues, so we run this script to check whether our URLs are being actively scraped. [(Healthcheck script in web-monitoring-processing)][ia-healthcheck-script]
3. ~Import data from Versionista~ (No longer used.) [(Versionista import script in web-monitoring-versionista-scraper)][versionista-import-script]
4. Generate weekly analyst task spreadsheets. [(Analyst spreadsheet script in web-monitoring-versionista-scraper)][analyst-sheet-script]

Each of these script is started from a short shell script (which manages environment variables, arguments, and logs) that is triggered on a schedule by `cron`.

The repos where the underlying scripts live are simple `git` checkouts. (See below for details.)


## Machine

This code runs on a very simple AWS EC2 machine:

- Name: `wm-scraper`
- Image/OS: Ubuntu 16.04
- Instance Type: t2.medium
- EBS Volumes:
    - Standard 8 GB root volume
    - 64 GB gp2 volume mounted at `/data` ([mounting instructions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html))


## Schedule

Scheduling is controlled by `cron`, which is configured with the contents of [`crontab`](./crontab).


## Code, Dependencies, & File Layout

The layout of this machine is fairly simple (probably unsafely simple). It’s an Ubuntu machine and the default user is the only user we use. It uses `cron` to trigger scripts.

It has the following file layout:

```
/home/ubuntu/
├─┬ etl-tools                           Scripts and environment info for ETL jobs
│ ├── .env.internetarchive              Environment variables for Internet Archive scripts
│ ├── cron-ia-healthcheck.sh            Runs the healthcheck script
│ └── cron-ia-import.sh                 Runs the Internet Archive import script
├── web-monitoring-processing           A git checkout of web-monitoring processing
└─┬ web-monitoring-versionista-scraper  A git checkout of web-monitoring-versionista-scraper, with some extra files
  ├── .env.versionista1                 Environment variables for importing from the first Versionista account
  ├── .env.versionista2                 Environment variables for importing from the second Versionista account
  ├── cron-archiver.sh                  Runs the Versionista import script
  ├── cron-tracking-team-db.sh          Runs the analyst task sheet generation script
  └── cron-tracking-team.sh             (DEPRECATED) Runs an older analyst task sheet generation script that works directly from Versionista instead of our database
```

It requires a few major dependencies:

- `git` to check out and update clones of web-monitoring-processing and web-monitoring-versionista-scraper.
- Conda to manage Python versions and environments. We have an environment named `web-monitoring-etl` that is activated on login in `.bashrc`. (At some point, we might change this to Pyenv.)
    - Python 3.7 for web-monitoring-processing
    - A conda environment named `web-monitoring-etl` for all Python scripts to run in. It also gets activated automatically on login via the `.bashrc` lines:

        ```sh
        . /opt/conda/etc/profile.d/conda.sh
        conda activate web-monitoring-etl
        ```
- The Node.js install on the system is managed by NVM (we should probably switch to Nodenv).


## To-Dos

- Develop an automated process for building/deploying this machine.
- Switch to Pyenv for Python management.
- Move extra files in scraper checkout into the `etl-tools` directory.
- Move analyst sheet generation out of versionista-scraper repo.
- Remove deprecated scripts and tools.
- Log management—at a minimum, we should really have some kind of log rotation set up. Alternatively/in addition, ship them to a service.


[web-monitoring-db]: https://github.com/edgi-govdata-archiving/web-monitoring-db
[ia-import-script]: https://github.com/edgi-govdata-archiving/web-monitoring-processing/blob/master/web_monitoring/cli.py
[ia-healthcheck-script]: https://github.com/edgi-govdata-archiving/web-monitoring-processing/blob/master/scripts/ia_healthcheck
[versionista-import-script]: https://github.com/edgi-govdata-archiving/web-monitoring-versionista-scraper/blob/master/bin/scrape-versionista-and-upload
[analyst-sheet-script]: https://github.com/edgi-govdata-archiving/web-monitoring-versionista-scraper/blob/master/bin/query-db-and-email
