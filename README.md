[![Code of Conduct](https://img.shields.io/badge/%E2%9D%A4-code%20of%20conduct-blue.svg?style=flat)](https://github.com/edgi-govdata-archiving/overview/blob/master/CONDUCT.md) &nbsp;[![Project Status Board](https://img.shields.io/badge/✔-Project%20Status%20Board-green.svg?style=flat)](https://github.com/orgs/edgi-govdata-archiving/projects/4)

# EDGI Web Monitoring Ops & Deployment

This repository contains instructions and configuration files for EDGI’s deployment of the [Web Monitoring project](https://github.com/edgi-govdata-archiving/web-monitoring/). Unlike most other software repos, this one contains deployment configurations that are specific to EDGI’s setup. If you’d like to deploy your own copy of the Web Monitoring project, you can use the content of this repo as a general guide or fork and edit it.

We currently run all our services in AWS:

- *Services* are managed by [Kubernetes](https://kubernetes.io/). See the [`kubernetes`](./kubernetes) directory for details.
- *Scheduled jobs* are currently run on manually configured EC2 instances. See the [`manually-managed`](./manually-managed) directory for details.
- We use a handful of AWS services like S3 and RDS. See the [`manually-managed`](./manually-managed) directory for details.

**A note about secrets and private data:** While EDGI strives to work as much in the open as possible, a production deployment of software necessarily involves some secret data like account credentials. We maintain secret data in a private Git repo stored on Keybase, and layer that data on top of what’s in this repo. Get in touch with a project maintainer on Slack if you need access to it.


## Releasing/Publishing New Versions

Most of our code repos automatically publish new releases (Docker images to https://hub.docker.com/u/envirodgi and packages to the relevant package managers) when code is pushed to the `release` branch. We usually create *merge commits* on the `release` branch that note the PRs included in the release or any other relevant notes (e.g. [`Release #503, #504`](https://github.com/edgi-govdata-archiving/web-monitoring-db/commit/67e4510d1f2a8c7f01542cc86a6361539ef77fa5)). Since most of our code is not widely distributed, we don’t currently include release notes that describe the changes in more detail.

Docker images are tagged with the SHA-1 of the git commit they were built from. For example, the image `envirodgi/db-rails-server:ddc246819a039465e7711a1abd61f67c14b7a320` was built from [commit `ddc246819a039465e7711a1abd61f67c14b7a320`](https://github.com/edgi-govdata-archiving/web-monitoring-db/commit/ddc246819a039465e7711a1abd61f67c14b7a320) in web-monitoring-db.


## Deploying Releases to Servers

Services running in Kubernetes always use the Docker images we release as above. Inside our Kubernetes cluster, we manage **two namespaces**: `staging` and `production`. The staging namespace has fewer instances of most services and operates against a smaller database that we might reset from time to time. It’s good for testing things. We typically deploy new code to both at the same time, but occasionally send new code only to staging or use a configuration variable to only turn the new code on in staging if it needs more rigorous testing. To update Kubernetes:

1. When we are ready to deploy code, trigger a release as described above.

2. Update the Kubernetes configuration files in this repo to point to the new images. Adjust secrets and environment variables as appropriate for the new release.

3. Use the `kubectl` command-line tool to update our Kubernetes cluster with the new configuration files.

Manually managed servers (for our scheduled jobs) tend to each have their own process. Check the [`manually-managed`](./manually-managed) directory for details on each one.

Manually managed AWS services like RDS or S3 are also described in [`manually-managed`](./manually-managed).


## Code of Conduct

This repository falls under EDGI's [Code of Conduct](https://github.com/edgi-govdata-archiving/overview/blob/master/CONDUCT.md).


## Contributing

This is an open-source project, and works because of contributors like you! See our [contributing guidelines](./CONTRIBUTING.md) to find out how you can help.


## License & Copyright

Copyright (C) 2017-2019 Environmental Data and Governance Initiative (EDGI)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.0.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the [`LICENSE`](https://github.com/edgi-govdata-archiving/webpage-versions-processing/blob/master/LICENSE) file for details.
