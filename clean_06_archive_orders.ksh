#!/bin/bash

# ==============================================================================
# DESCRIPTION: Orchestrates SQL Server -> GCS -> BigQuery pipeline with checks.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# --- 1. CONFIGURATION VARIABLES ---
# GCP Project & Region
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"

# SQL Server / JDBC Connection Details
export JDBC_CONNECTION_URL="jdbc:sqlserver://<SQL_SERVER_IP>:1433;databaseName=<DB_NAME>"
export JDBC_DRIVER_CLASS="com.microsoft.sqlserver.jdbc.SQLServerDriver"
export JDBC_DRIVER_GCS_PATH="gs://your-bucket/drivers/mssql-jdbc.jar"

# Query to pull data
export SQL_QUERY="SELECT * FROM your_table WHERE update_ts >= '2026-01-01'"

# GCS Staging & Output
export BUCKET_NAME="your-gcs-bucket"
export OUTPUT_GCS_DIR="gs://${BUCKET_NAME}/extracted_data/"
export DATAFLOW_STAGING_DIR="gs://${BUCKET_NAME}/dataflow_staging/"

# BigQuery Target
export BQ_DATASET="your_dataset"
export BQ_TABLE="your_target_table"
export BQ_SCHEMA="id:INTEGER,name:STRING,update_ts:TIMESTAMP" # Or auto-detect

# --- 2. INITIALIZATION & AUTH ---
echo "INFO: Initializing environment..."
gcloud config set project ${PROJECT_ID}

# Fetch password securely from GCP Secret Manager
echo "INFO: Fetching database credentials..."
DB_PASSWORD=$(gcloud secrets versions access latest --secret="${DB_PASSWORD_SECRET_NAME}")

# --- 3. RUN DATAFLOW JOB (SQL Server to GCS) ---
JOB_NAME="sql-server-to-gcs-$(date +%Y%m%d-%H%M%S)"
echo "INFO: Triggering Dataflow Job: ${JOB_NAME}..."

gcloud dataflow jobs run ${JOB_NAME} \
    --gcs-location="gs://dataflow-templates-${REGION}/latest/Jdbc_to_GCS" \
    --region=${REGION} \
    --parameters \
driverClassName="${JDBC_DRIVER_CLASS}",\
driverJars="${JDBC_DRIVER_GCS_PATH}",\
connectionUrl="${JDBC_CONNECTION_URL}",\
username="${DB_USER}",\
password="${DB_PASSWORD}",\
query="${SQL_QUERY}",\
outputFile="${OUTPUT_GCS_DIR}data_output_"

echo "INFO: Waiting for Dataflow job to complete successfully..."
# This block waits dynamically for the Dataflow job to finish
while true; do
    JOB_STATE=$(gcloud dataflow jobs list --filter="name=${JOB_NAME}" --format="value(STATE)" --limit=1)
    echo "Current Job State: ${JOB_STATE}"
    if [ "${JOB_STATE}" == "Done" ]; then
        echo "SUCCESS: Dataflow job finished successfully."
        break
    elif [ "${JOB_STATE}" == "Failed" ] || [ "${JOB_STATE}" == "Cancelled" ]; then
        echo "ERROR: Dataflow job failed or was cancelled."
        exit 1
    fi
    sleep 30
done

# --- 4. LOAD DATA FROM GCS TO BIGQUERY ---
echo "INFO: Loading data from GCS (${OUTPUT_GCS_DIR}) into BigQuery table ${BQ_DATASET}.${BQ_TABLE}..."

# Adjust source_format based on your Dataflow template output (CSV or JSON)
bq load \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --autodetect \
    "${BQ_DATASET}.${BQ_TABLE}" \
    "${OUTPUT_GCS_DIR}data_output_*"

echo "SUCCESS: Data loaded into BigQuery successfully."

# --- 5. POST-LOAD VALIDATION CHECKS ---
echo "INFO: Running data validation checks..."

# Check 1: Record Count Check (Ensure we actually loaded rows)
ROW_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(1) FROM \`${PROJECT_ID}.${BQ_DATASET}.${BQ_TABLE}\`" | tail -n 1)

echo "INFO: Total rows in BigQuery destination: ${ROW_COUNT}"
if [ "${ROW_COUNT}" -eq 0 ]; then
    echo "ERROR: Validation failed! Destination table is empty."
    exit 1
fi

# Check 2: Custom Data Integrity Check (Example: Null Check on primary keys)
# Returns 1 if any rows have null keys
NULL_KEYS=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(1) FROM \`${PROJECT_ID}.${BQ_DATASET}.${BQ_TABLE}\` WHERE id IS NULL" | tail -n 1)

if [ "${NULL_KEYS}" -gt 0 ]; then
    echo "WARNING: ${NULL_KEYS} records found with NULL IDs!"
    # Handle error or notify alerting system here
else
    echo "SUCCESS: No NULL IDs detected."
fi

echo "=== PIPELINE EXECUTED SUCCESSFULLY ==="
