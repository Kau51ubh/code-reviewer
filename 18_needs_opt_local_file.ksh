#!/bin/ksh
# Optimization needed: Huge local file processing via bash loops instead of BigQuery load
set -e

FILE="/data/massive_export_10GB.csv"

echo "Processing line by line locally..."
while IFS=, read -r col1 col2 col3; do
    # Terrible performance for 10GB file
    echo "${col1} - ${col2}" >> /data/parsed_output.txt
done < "${FILE}"