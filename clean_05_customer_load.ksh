#!/bin/ksh
set -e
set -o pipefail

# CLEAN: strict mode is on, BigQuery runs through the enterprise wrapper function (no raw
# CLI invocation), the return code is checked explicitly, and nothing secret is echoed.
# No pipes / loops, so there is nothing for the AI to optimize either.
# EXPECTED: Status CLEAN (no linter fixes, no AI).

ENVIR="${1}"
LOG_DIR="/home/airflow/gcs/logs/${ENVIR}"

execute_bq_wrapper "CALL ${ENVIR}.sp_load_customers()"
RC=$?
if [[ ${RC} -ne 0 ]]; then
    echo "Customer load failed with RC=${RC}"
    exit ${RC}
fi

echo "Customer load completed successfully for ${ENVIR}"
exit 0
