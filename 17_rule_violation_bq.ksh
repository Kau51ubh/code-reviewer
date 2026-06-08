#!/bin/ksh
# Rule Violation: Direct use of bq query instead of wrapper function
set -e

QUERY="SELECT COUNT(*) FROM DB_AEDWD2.customers"

echo "Running direct BQ command"
bq query --use_legacy_sql=false "${QUERY}"
RC=$?

if [[ ${RC} -ne 0 ]]; then
    exit ${RC}
fi