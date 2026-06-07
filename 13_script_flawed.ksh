#!/bin/ksh
# SCENARIO: raw 'bq query' invocation, a dangerous recursive delete of a variable
#           path, and no strict error handling.
# EXPECTED: linter injects 'set -e' and 'set -o pipefail' after the shebang,
#           refactors 'bq query' into the enterprise wrapper, and wraps the
#           'rm -rf $VAR' in an existence safety check. Status: AUTO-FIXED.

TARGET_DIR=$1

bq query --nouse_legacy_sql "SELECT COUNT(*) FROM orders WHERE dt = CURRENT_DATE()"

rm -rf $TARGET_DIR
