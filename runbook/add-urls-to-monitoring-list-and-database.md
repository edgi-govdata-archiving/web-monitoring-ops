# Add URLs to our monitoring list and database
*Last updated:* 2020/04/29 

## Overview
Occasionally we need to add new URLs to be monitored. This usually happens when current events prompt us to track URLs that didn't exist before, we realize there are pertinent URLs we haven't been tracking, or if a third-party requests us to track URLs. See this [issue](https://github.com/edgi-govdata-archiving/web-monitoring/issues/151) for an example.

Adding new URLs involves 2 main steps:

* Add URLs to the Internet Archive's Wayback Machine
* Add URLs to Scanner's database

## Steps

### **Add URLs to Internet Archive's Wayback Machine**
1. First, we want to make sure that at least one snapshot is saved to IAWM via Save Page Now (SPN)
- Clone [wayback-spn-client](https://github.com/Mr0grog/wayback-spn-client)
- Create a `.txt` file with the list of new URLs to be tracked, one URL per line.
- From `wayback-spn-client` repo: 
    - `> node index.js path/to/your/url/list.txt`
        - This process takes about 30sec per url
        - Make sure output doesn't contain errors

2. Then, we want to make sure the URLs are being continually captured by [ia-archiver](https://github.com/edgi-govdata-archiving/web-monitoring-ops/tree/master/manually-managed/ia-archiver)
- Clone [web-monitoring-ops](https://github.com/edgi-govdata-archiving/web-monitoring-ops)
- Add URLs to `web-monitoring-ops/manually-managed/ia-archiver/missing-from-ia.txt`
    - Remember to add a comment describing why the URLs were added
- Commit `missing-from-ia.txt` back to the repo. 
    - In general, we don't use PRs for updating the `missing-from-ia.txt`. Commit to `master` if you're comfortable doing so.
- Copy to `ia-archiver` server from `web-monitoring-ops`
    ```
    > scp manually-managed/ia-archiver/missing-from-ia.txt ubuntu@<Public-DNS>:/home/ubuntu/
    ```
- Inform Internet Archive about added URLs in the Scanner slack channel. 
    - Usually @mr0grog does this to keep our point-of-contact with the Internet Archive consistent

### **Adding URLs to Scanner's database**
* Clone [web-monitoring-processing](https://github.com/edgi-govdata-archiving/web-monitoring-processing)
* Be sure to follow all [installation instructions](https://github.com/edgi-govdata-archiving/web-monitoring-processing/#installation-instructions) carefully
* You will need to have write permissions and credentials to our database. Add those to `.env` file.
* For each URL:
    - `> wm import ia <URL> --tag "tag1" "tag2" --maintainer "maintainer1" "maintainer2" `
        - Be sure to add a `tag` and `maintainer` It's possible to add more than one. You can use the [API explorer](https://api.monitoring.envirodatagov.org/) to look for examples from related, existing records

* Watch for a job import ID, so you know the import was successful. Also, you can check the existence of the new record at [api.monitoring.envirodatagov.org](api.monitoring.envirodatagov.org)

* IF URLS WERE NOT ABLE TO BE SAVED TO THE WAYBACK MACHINE via SPN (Save Page Now), you will have to add the pages to the database manually instead of using `wm import`.
    1. SSH into a live server via Kubernetes:

        ```sh
        # List available pods
        > kubectl get pods --namespace production
        # Pick an `api-` or `import-worker-` pod (basically, one of the DB pods) and log in
        > kubectl exec -it --namespace production <name of pod> -- /bin/bash

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
