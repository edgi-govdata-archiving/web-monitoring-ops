# Add URLs to our monitoring list and database
*Last updated:* 2020/04/29 

*Last run:* 2020/04/29

## Overview
Occasionally we need to add new URLs to be monitored. This usually happens when current events prompt use to track URLs that didn't exist before, we realize there are pertinent URLs we haven't been tracking, or if a third-party requests us to track URLs. See this [issue](https://github.com/edgi-govdata-archiving/web-monitoring/issues/151) for an example.

Adding new URLs involves 2 main steps:

* Add URLs Internet Archive Wayback Machine
* Add URLs to Scanner's database

## Prerequsites
- Have a clone of [web-monitoring-ops](https://github.com/edgi-govdata-archiving/web-monitoring-ops) repository

## Steps

### **Add URLs to Internet Archive Wayback Machine**
- Clone [wayback-spn-client](https://github.com/Mr0grog/wayback-spn-client)
- Create a `.txt` file with the list of new URLs to be tracked
- From `wayback-spn-client` repo: 
    - `> node index.js path/to/your/url/list.txt`
        - This process takes about 30sec per url
        - Make sure output doesn't contain errors

From `web-monitoring-ops` repo:
- Add URLs to `web-monitoring-ops/manually-managed/ia-archiver/missing-from-ia.txt`
    - Add a comment describing why the URLs were added
- Commit `missing-from-ia.txt` back to the repo.
    - In general, we don't use PRs for updating the `missing-from-ia.txt`. Commit to `master` if you're comfortable doing so.
- Copy to `ia-archiver` server from `web-monitoring-ops`
    ```
    > scp manually-managed/ia-archiver/missing-from-ia.txt ubuntu@<ipaddress>:/home/ubuntu/
    ```
- Inform Internet Archive about added URLs in the Scanner slack channel. 
    - Usually @mr0grog does this to keep our point-of-contact with the Internet Archive consistent

### **Adding URLs to Scanner's database**
* Clone [web-monitoring-processing](https://github.com/edgi-govdata-archiving/web-monitoring-processing)
* Be sure to follow all installation instructions carefully
* You will need to have write permissions and credentials to our database. Add those to `.env` file.
* For each URL:
    - `> wm import ia <URL> --tag "tag" --maintainer "maintainer"`
        - Be sure to add a `tag` and `maintainer`. You can use the [API explorer](https://api.monitoring.envirodatagov.org/) to look for examples from related, existing records

* Watch for a job import ID, so you know the import was successful. Also, can double check at [api.monitoring.envirodatagov.org](api.monitoring.envirodatagov.org)

* OPTIONAL: If URLs were not able to be imported to the Wayback Machine via SPN (Save Page Now), you will have to add the pages to the database manually instead of using `wm import`
    1. Add a page record to the DB:

        1. SSH into a live server via Kubernetes:

            ```sh
            # List available pods
            > kubectl get pods --namespace production
            # Pick an `api-` or `import-worker-` pod (basically, one of the DB pods) and log in
            > kubectl exec -it <name of pod> /bin/bash --namespace production

            # Open the Rails console once you are logged into the pod
            > rails c
            ```

        2. Create the page:

            ```rb
            > new_page = Page.create(url: 'URL OF PAGE HERE')
            # Optionally add maintainers and tags as appropriate (the `domain:` and `2l-domain`
            # tags are created automatically, so no need to add those)
            > new_page.add_tag('NAME OF TAG')
            > new_page.add_maintainer('NAME OF MAINTAINER')
            ```

    2. Make sure we are actually getting that page saved on Wayback by adding it to the [ia-archiver](https://github.com/edgi-govdata-archiving/web-monitoring-ops/tree/master/manually-managed/ia-archiver) box. 
    
        Make sure to let @Mr0grog know if you change the config on that box, since he updates it every day or two and might accidentally overwrite your changes! (See the above issue in ops again, scream at @Mr0grog about it if you need, because he could probably use a kick in the pants.)

