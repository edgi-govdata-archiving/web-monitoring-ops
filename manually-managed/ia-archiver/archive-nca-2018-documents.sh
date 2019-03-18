#!/bin/bash

echo "" 1>&2
echo "[`date`] Starting archival run" 1>&2
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 10 > /dev/null
INPUT_URL_LIST=/home/ubuntu/nca-2018-documents.txt
node /home/ubuntu/wayback-spn-client/index.js $INPUT_URL_LIST

