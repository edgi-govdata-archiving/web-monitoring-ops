#!/bin/bash

echo "" 1>&2
echo "[`date`] Starting team spreadsheet run"
source "$HOME/web-monitoring-versionista-scraper/.env.$1"
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 10 > /dev/null
/home/ubuntu/web-monitoring-versionista-scraper/bin/scrape-versionista-and-email --after $2 --output /data/versionista-tracking-team/ --scrape-parallel 3 --scrape-pause-time 10000

