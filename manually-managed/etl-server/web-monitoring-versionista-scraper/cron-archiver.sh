#!/bin/bash

echo "" 1>&2
echo "[`date`] Starting archival run" 1>&2
source "$HOME/web-monitoring-versionista-scraper/.env.$1"
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 10 > /dev/null
NOW=`date +'%Y-%m-%d_%H-%M-%S'`
OUTPUT="/data/versionista-continuous/$NOW"
/home/ubuntu/web-monitoring-versionista-scraper/bin/scrape-versionista-and-upload --after $2 --output "$OUTPUT/" --scrape-pause-time 5000 --scrape-parallel 1 --scrape-pause-every 25

# Move working files into `versionista-continuous-archive` when done and clear working space
cp -ru $OUTPUT/$1/* /data/versionista-continuous-archive/$1/
rm -rf $OUTPUT

