#!/bin/ksh
# SCENARIO: a shell script with a hardcoded plaintext password.
# EXPECTED: the Shift-Left security scanner detects the secret and HALTS
#           processing before any other fix or AI call. Status: SECURITY_HALT.
# (This takes priority over the 'bq query' / strict-mode fixes below.)

DB_PASSWORD="prodSecret2024"

bq query "SELECT 1"

echo "connecting..."
