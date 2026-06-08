#!/bin/ksh
# Clean: set -e, uses wrappers, dataset parameterization
set -e

DATASET=${AEDW_DB}
TARGET_TABLE="daily_metrics"

echo "Executing BigQuery Wrapper..."
run_bq_wrapper_func -d ${DATASET} -t ${TARGET_TABLE} -f sql/process.sql
RC=$?

if [[ ${RC} -ne 0 ]]; then
    echo "Error executing wrapper. Exiting."
    exit ${RC}
fi