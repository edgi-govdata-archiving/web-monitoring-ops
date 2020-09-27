#!/bin/bash

echo "" 1>&2
echo "[`date`] Starting Internet Archive Import" 1>&2
source "$HOME/etl-tools/.env.internetarchive"

# Initialize Pyenv and enter the relevant virtualenv
export PATH="/home/ubuntu/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
pyenv activate web-monitoring-etl

export LOG_LEVEL=INFO
UNPLAYBACKABLE_CACHE="$HOME/etl-tools/unplaybackable.json"
# --from is in hours:
#  72 = 3 days
# 120 = 5 days
# 192 = 8 days
# We typically keep this at 3-5 days to accomodate for any slow indexing
# on Wayback's part.
# They're experiencing major issues right now, so it's set higher.
wm import ia-known-pages --from 192 --parallel 10 --unplaybackable "$UNPLAYBACKABLE_CACHE" 1>&2
echo "Internet Archive import completed at `date`" 1>&2
