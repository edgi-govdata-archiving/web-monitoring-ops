# ETL Server

This machine runs ETL (Extract, Transform, and Load) scripts to pull page & version data out of other services (like the Internet Archive or Versionista) and import it into a [web-monitoring-db][] instance. The core code for most of that lives in other web-monitoring-* repositories; this server just uses cron and some very simple bash scripts to execute them and save logs.

Specifically, this server currently performs two tasks:

1. Import data from the Internet Archive. [(IA import script in web-monitoring-processing)][ia-import-script]

2. Healthcheck for Internet Archive scrapers. Our scraper at the Internet Archive has occasionally had issues, so we run this script to check whether our URLs are being actively scraped. [(Healthcheck script in web-monitoring-processing)][ia-healthcheck-script]

Each of these scripts is started from a short shell script (which manages environment variables, arguments, and logs) that is triggered on a schedule by `cron`.

The repos where the underlying scripts live are simple `git` checkouts. (See below for details.)


## Machine

This code runs on a very simple AWS EC2 machine:

- Name: `wm-etl`
- Image/OS: Ubuntu 20.04
- Instance Type: t3.medium
- EBS Volumes:
    - 16 GB gp2 (SSD) root volume

See the [“Setup Guide for a New Server” section](#setup-guide-for-a-new-server) for instructions on how to configure it.


## Schedule

Scheduling is controlled by `cron`, which is configured with the contents of [`crontab`](./crontab).


## Code, Dependencies, & File Layout

The layout of this machine is fairly simple (probably unsafely simple). It’s an Ubuntu machine and the default user is the only user we use. It uses `cron` to trigger scripts.

It has the following file layout:

```
/home/ubuntu/
├─┬ etl-tools/                      Scripts and environment info for ETL jobs
│ ├── .env.internetarchive          Environment variables for Internet Archive scripts
│ ├── cron-ia-healthcheck.sh        Runs the healthcheck script
│ └── cron-ia-import.sh             Runs the Internet Archive import script
├── web-monitoring-processing/      A git checkout of web-monitoring processing
└── crontab                         A schedule for automated scripts in cron format
```

It requires a few major dependencies:

- `git` to check out and update clones of web-monitoring-processing.
- Pyenv to manage Python versions and environments.
    - Python 3.8 for web-monitoring-processing
    - A virtual environment named `web-monitoring-etl` where everything is
        installed.


## To-Dos

- Develop an automated process for building/deploying/updating this machine. Basically, put everything in the setup guide into a script.
- Log management—at a minimum, we should really have some kind of log rotation set up. Alternatively/in addition, ship them to a service.
- Look into using AWS Batch or Kubernetes jobs for this instead.


## Setup Guide for a New Server

1. Set up and launch the machine on EC2. See the description in the [“Machine” section](#machine) for what you basically want to create.

2. Copy the contents of this directory to the new server:

    ```sh
    $ scp -r ./* ubuntu@<IP or DNS address of server>:/home/ubuntu/
    ```

    (Depending on your security settings for the new machine, you might need to install the keys needed to log in with `ssh-add <path_to_key_file>`.)

3. Now log into the server via SSH for the rest of the setup:

    ```sh
    $ ssh ubuntu@<IP or DNS address of server>:/home/ubuntu/
    ```

4. Update system packages:

    ```sh
    $ sudo apt-get update
    $ sudo apt-get upgrade
    ```

5. Install prerequisites for Pyenv:

    ```sh
    $ sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
    # And additional prerequisites for web-monitoring-processing
    $ sudo apt-get install -y gcc g++ pkg-config libxml2-dev libxslt-dev \
        openssl libcurl4-openssl-dev
    ```

    (Taken from https://github.com/pyenv/pyenv/wiki/Common-build-problems)

6. Install Pyenv:

    ```sh
    $ curl https://pyenv.run | bash
    ```

    That’ll output a lot of stuff. If successful, the last bit will be:

    ```
    WARNING: seems you still have not added 'pyenv' to the load path.

    # Load pyenv automatically by adding
    # the following to ~/.bashrc:

    export PATH="/home/ubuntu/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    ```

    So add that to `.bashrc`.

7. Install the correct Python and set it as the default version.

    ```sh
    $ pyenv install `cat .python-version`
    $ pyenv global `cat .python-version`
    ```

8. Create a virtualenv for ETL scripts and activate it. The rest of the commands should be run inside the virtualenv:

    ```sh
    $ pyenv virtualenv web-monitoring-etl
    $ pyenv activate web-monitoring-etl
    ```

9. Clone the [web-monitoring-processing][] project and install it:

    ```sh
    $ git clone https://github.com/edgi-govdata-archiving/web-monitoring-processing.git
    $ cd web-monitoring-processing
    $ pip install --upgrade pip
    $ pip install -r requirements.txt
    $ python setup.py install
    ```

10. Fill in the `.env` files in the `etl-tools` directory with correct usernames, passwords, etc.

    - `etl-tools/.env.internetarchive`

11. Ensure there is a directory for logs:

    ```sh
    $ sudo mkdir -p /var/log/cron-ia-import
    $ sudo chown ubuntu:ubuntu /var/log/cron-ia-import
    $ chmod 766 /var/log/cron-ia-import
    ```

12. Install the cron schedule so scripts start running automatically:

    ```sh
    # Remove any existing crontab.
    $ crontab -r || true
    # Install from the crontab file.
    $ crontab ./crontab
    ```


[web-monitoring-db]: https://github.com/edgi-govdata-archiving/web-monitoring-db
[web-monitoring-processing]: https://github.com/edgi-govdata-archiving/web-monitoring-processing
[ia-import-script]: https://github.com/edgi-govdata-archiving/web-monitoring-processing/blob/master/web_monitoring/cli.py
[ia-healthcheck-script]: https://github.com/edgi-govdata-archiving/web-monitoring-processing/blob/master/scripts/ia_healthcheck
