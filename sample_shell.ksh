#!/bin/ksh
# ==============================================================================
# Script Name: bad_data_load.ksh
# Description: Example script that extracts, transforms, and loads data.
# ==============================================================================

echo "Starting Daily Data Load Job..."

# 1. Hardcoded credentials and echoing them to logs
BQ_USER="svc_acct_etl"
BQ_PASS="SuperSecretProdPass2026!"
echo "Authenticating with User: $BQ_USER and Password: $BQ_PASS"

# 2. Moving files without any Return Code (RC) checks
echo "Copying inbound file to processing area..."
cp /data/inbound/huge_daily_transactions.csv /data/processing/

# 3. Huge local Unix file processing (instead of doing this in DB)
echo "Parsing massive file locally..."
cat /data/processing/huge_daily_transactions.csv | grep "APPROVED" | awk -F',' '{print $1,$2,$5}' > /data/processing/parsed_data.csv

# 4. Direct bq query usage AND hardcoded dataset name
echo "Running BigQuery insert..."
bq query --nouse_legacy_sql "
    INSERT INTO prj-prod-data.DB_AEDWD2.TRANSACTIONS (TXN_ID, STATUS, AMOUNT)
    SELECT * FROM EXTERNAL_QUERY('connection', 'select * from source');
"

# 5. Deleting files instead of archiving them
echo "Cleaning up processing directory..."
rm /data/inbound/huge_daily_transactions.csv
rm /data/processing/parsed_data.csv

echo "Job Finished!"
exit 0
