#!/bin/bash

echo "" 1>&2
echo "[`date`] Starting Internet Archive Health Check" 1>&2
source "$HOME/etl-tools/.env.internetarchive"
source /opt/conda/etc/profile.d/conda.sh
conda activate web-monitoring-etl

ia_healthcheck

