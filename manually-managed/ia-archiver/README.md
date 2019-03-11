# IA Archiver

This machine is dedicated to pushing URLs we wish to monitor into the Internet Archive on a regular basis. It works by automating the archive’s “Save Page Now” (SPN) feature via [wayback-spn-client](https://github.com/Mr0grog/wayback-spn-client).

At current, we save URLs from two lists:

- `nca-2018-documents.txt` List of all the actual pages in NCA 2018
- `missing-from-ia.txt` List of URLs Web Monitoring analysts actively monitor (i.e. that are in our database) but that Wayback is not actively monitoring every day for us. **@Mr0grog manually updates this file frequently based on our [IA healtcheck script’s](https://github.com/edgi-govdata-archiving/web-monitoring-processing/blob/master/scripts/ia_healthcheck) output.**

This was initially an experiment to see if we could streamline the process of ensuring Wayback is archiving pages we care about, which used to be:

```
Analyst [Team Lead]
  → Slacks @Mr0grog
    → Slacks/E-mails Wayback Folks (and maybe gets a little bit of a
      runaround when this task has been handed off to someone else
      over there)
      → Someday a Wayback Engineer adds it to the config for the
        crawler doing our work.
```

…And to make ourselves less vulnerable to breakage on the machine that is doing our archiving over at the Internet Archive (which has fallen over a few times and is why we have [this health check script](https://github.com/edgi-govdata-archiving/web-monitoring-processing/blob/master/scripts/ia_healthcheck)).


## Machine

This code runs on a very simple AWS EC2 machine:

- Name: `ia-archiver`
- Image/OS: Ubuntu 18.04
- Instance Type: t2.small
- EBS Volumes: Just a the default 8GB volume


## Schedule

Scheduling is controlled by `cron`, which is configured with the contents of [`crontab`](./crontab).


## Code, Dependencies, & File Layout

The layout of this machine is *extremely* simple (probably unsafely simple). It’s an Ubuntu machine and the default user is the only user we use. It uses `cron` to trigger scripts to save pages with SPN.

It has the following file layout:

```
/home/ubuntu/
├── README.md                       Information about this machine
├── archive-missing-from-ia.sh      Script to save URLs in missing-from-ia.txt
├── archive-nca-2018-documents.sh   Script to save URLs in nca-2018-documents.txt
├── missing-from-ia.txt             List of pages we track but that Wayback is not automatically tracking for us right now
├── nca-2018-documents.txt          List of documents (pages, PDFs, excel files) in NCA 2018
├── nca-2018-resources.txt          List of all URLs (resources) in NCA 2018
└── wayback-spn-client              Git clone of https://github.com/Mr0grog/wayback-spn-client
```

It requires two major dependencies:

- The Node.js install on the system is managed by NVM (we should probably switch to Nodenv).
- Chrome is installed according to the [“installing chrome”](#installing-chrome) section below.


## Installing Chrome

Installing the dependencies of `wayback-spn-client` via `npm install` should install Chrome, but it won't necessarily grab all of Chrome's dependencies. To install Chrome via APT:

Download and install Google's signing key:

```sh
> curl 'https://dl-ssl.google.com/linux/linux_signing_key.pub' -O
> sudo apt-key add linux_signing_key.pub
```

Add Google Chrome sources to APT:

```sh
> echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
```

Install Chrome and its dependencies:

```sh
# Tack `--no-install-recommends` onto the end of this for a minimal setup
> apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst ttf-freefont
```

Export an env var to make sure `wayback-spn-client` uses this install of Chrome (not actually required now that we have all the right system dependencies):

```sh
> export $PUPPETEER_CHROMIUM_EXECUTABLE='google-chrome-unstable'
```


## To-Dos

- Develop an automated process for building/deploying this machine.
- Switch to using SPN v2 (in beta). @Mr0grog has some half-finished scripts for this.
- Build a more comprehensive list of things in `missing-from-ia.txt` rather than updating it piecemeal based on daily healthcheck results.
- Give Wayback team an updated list of all our URLs and use this less heavily? (On the other hand, maintaining the list here has taught @Mr0grog a lot about the issues with and genesis of the current list of URLs we track, and there’s a lot that can/should be cleaned out/updated. It’d lovely to do that before updating the Wayback team.)
- Log management—at a minimum, we should really have some kind of log rotation set up. Alternatively/in addition, ship them to a service.
