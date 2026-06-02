#!/bin/ksh

set -e
set -o pipefail

TARGET_DIR="/data/stage/orders"

if [[ -n "$TARGET_DIR" ]]; then
    rm -rf "$TARGET_DIR"/*
fi

# Use enterprise wrapper function
execute_bq_wrapper "aedw_batch_123" "CALL my_proc();"
RC=$?

if [[ $RC -ne 0 ]]; then
    echo "Error executing KSH KSH."
    exit $RC
fi

echo "Process completed successfully."
exit 0
