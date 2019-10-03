#!/bin/bash

echo "" 1>&2
echo "[`date`] Starting team spreadsheet run (via DB query)"
source "$HOME/web-monitoring-versionista-scraper/.env.$1"
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 10 > /dev/null

# Only send sheets for ANY source now
# /home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/

# Don't send data with links to Versionista anymore. This was a tempororary
# measure to make transitioning easier; we shouldn't be using it anymore.
# (Keep it commented out just in case we need it back.)
# /home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/ --link-to-versionista

# Only send sheets for ANY source now
# sleep 30
# /home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/ --source-type internet_archive

# Generate sheets grouped by Versionista site
# /home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/ --source-type ANY

# Generate sheets grouped by domain
# sleep 30
# /home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/ --source-type ANY --group-by 'domain:'

# This is turned off more-or-less permanently now
# Generate sheets grouped by second-level domain
# sleep 30
# /home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/ --source-type ANY --group-by '2l-domain:'

# Generate sheets grouped by second-level domain and a custom tag
# sleep 30
/home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/ --source-type ANY --group-by '2l-domain:' --group-by 'tag2:' --group-by 'news'

# Generate sheets with only wayback data by second-level domain and custom tag
# sleep 30
# /home/ubuntu/web-monitoring-versionista-scraper/bin/query-db-and-email --after $2 --before $3 --output /data/versionista-tracking-team-db/ --source-type internet_archive --group-by '2l-domain:' --group-by 'tag2:'
