#!/bin/ksh
set -e
set -o pipefail

# CLEAN: strict mode, parameterized paths, BQ through the wrapper, explicit RC check,
# no echoed secrets, no dangerous deletes, no pipes / loops.
# EXPECTED: Status CLEAN (no linter fixes, no AI).

ENVIR="${1}"
ARCHIVE_DIR="/home/airflow/gcs/archive/${ENVIR}"

execute_bq_wrapper "CALL ${ENVIR}.sp_archive_orders()"
RC=$?
if [[ ${RC} -ne 0 ]]; then
    echo "Order archive failed with RC=${RC}"
    exit ${RC}
fi

echo "Order archive completed for ${ENVIR}"
exit 0
