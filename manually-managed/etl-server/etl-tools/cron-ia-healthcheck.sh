#!/bin/bash

echo "" 1>&2
echo "[`date`] Starting Internet Archive Health Check" 1>&2
source "$HOME/etl-tools/.env.internetarchive"

# Initialize Pyenv and enter the relevant virtualenv
export PATH="/home/ubuntu/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
pyenv activate web-monitoring-etl

ia_healthcheck
