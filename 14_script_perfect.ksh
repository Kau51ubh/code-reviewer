#!/bin/ksh
set -e
set -o pipefail

# SCENARIO: a clean shell script (control / happy path) — strict mode on, uses
#           the wrapper, checks the return code, no dangerous deletes/secrets.
# EXPECTED: no linter fixes. Status: CLEAN.

execute_bq_wrapper "SELECT COUNT(*) FROM \${AEDW_DB}.orders WHERE etl_batch_sk = \${ETL_BATCH_SK}"
RC=$?

if [[ ${RC} -ne 0 ]]; then
  echo "Query failed with code ${RC}"
  exit 1
fi

echo "Load completed successfully"
