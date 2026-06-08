#!/bin/ksh
###############################################################################
# Script Name: archival_process_wrapper_script.ksh
# Description: Wrapper script to manage execution of archival file processes with auditing,
#              exception handling, and rerun capabilities.
# Author: Vamshi
# Date: 06-12-2024
###############################################################################

if [[ $(dirname ${0}) = . ]]
then
        CURRDIR=$PWD
        PROGNAME=${0}
        PROGDIR=${CURRDIR}
else
        CURRDIR=${0}
        PROGNAME=$(basename ${CURRDIR})
        PROGDIR=$(dirname ${CURRDIR})
fi

PROGBASE=$(basename $PROGNAME .ksh)

# #######################################################################################
#Set environment variables
#and define functions
# #######################################################################################
#source ${PROGDIR}/report_generate.sh
unset FPATH
BASEDIR=$(echo ${PROGDIR} | awk -F/ ' { print $2 } ')
ENVDIR=$(echo ${PROGDIR} | awk -F/ ' { print $3 } ')
export typeset FPATH=/${BASEDIR}/${ENVDIR}/functions
typeset -i STEP_NUMBER EXIT_STATUS
STEP_NUMBER=1
EXIT_STATUS=0

unset -f f_get_config
#Set environment variables
f_get_config "${PROGNAME}" "${PROGDIR}"

#make copy of stdout to file desc 3 (need later to return stdout to screen)
exec 3>&1

#redirect stdout & stderr to log
exec 1>> $MSGFILE
exec 2>&1



# Debugging to verify environment
echo "Environment detected: ${PROJECT_ENV}"

# Redirect stdout & stderr to MSGFILE
exec 1>>"${MSGFILE}"
exec 2>&1

# ---------------------------------------------------------------------

# Variables
DATE=$(date '+%Y%m%d')  # Date without time
AUDIT_FILE="${PARENTDIR}/stg/Archival_process_audit_${DATE}.txt"
STATUS_SUCCESS="SUCCESS"
STATUS_FAILED="FAILED"
STATUS_NOT_RUN="NOT_RUN"

# Process scripts
PROCESS_SCRIPTS=("Archival_Data_extraction.ksh" "Archival_Data_transformation.ksh" "Archival_purge_process.ksh")

# Determine the appropriate YAML file for reporting based on the environment
CONFIG_FILE=""
if [[ "${PROJECT_ENV}" = "qa" ]]; then
    CONFIG_FILE="${PARENTDIR}/stg/archival_report_non_prod.yaml"
elif [[ "${PROJECT_ENV}" = "prod" ]]; then
    CONFIG_FILE="${PARENTDIR}/stg/archival_report_prod.yaml"
else
    CONFIG_FILE=""
    echo "WARNING: Reporting will be skipped as environment is neither 'qa' nor 'prod'."
fi

# Function to initialize the audit file
initialize_audit_file() {
    echo "Initializing audit file: ${AUDIT_FILE}"
    for process in "${PROCESS_SCRIPTS[@]}"; do
        echo "${process}|${STATUS_NOT_RUN}|Process not yet executed|$(date '+%Y-%m-%d %H:%M:%S')" >> "${AUDIT_FILE}"
    done
}

# Function to load statuses from the audit file
read_status_from_audit_file() {
    idx=0  
    echo "Reading status from audit file: ${AUDIT_FILE}"
    while IFS='|' read -r process_name status message timestamp; do
        PROCESSES[idx]="${process_name}"
        STATUSES[idx]="${status}"
        idx=$((idx + 1))
    done < "${AUDIT_FILE}"
}

# Function to update the audit file after each process execution
update_audit_file() {
    > "${AUDIT_FILE}"  # Clear and rewrite the audit file
    for idx in "${!PROCESSES[@]}"; do
        process_name="${PROCESSES[idx]}"
        status="${STATUSES[idx]}"
        message="${1:-Status updated}"
        echo "${process_name}|${status}|${message}|$(date '+%Y-%m-%d %H:%M:%S')" >> "${AUDIT_FILE}"
    done
}

# Function to execute a process script
execute_process() {
    process_name="$1"
    process_script="${PROGDIR}/${process_name}"  # Full path to the script

    if [[ ! -x "${process_script}" ]]; then
        echo "ERROR: Script ${process_script} does not exist."
		update_status "${process_name}" "${STATUS_FAILED}" ${process_script} "script not found"
        return 1
    fi

    echo "Executing ${process_name} ......."
    if ! ksh "${process_script}"; then  
        echo "ERROR: Execution failed for ${process_name}."
        update_status "${process_name}" "${STATUS_FAILED}" "Execution Error"
        exit 1
        return 1
    else
        echo "${process_name} executed successfully."
        update_status "${process_name}" "${STATUS_SUCCESS}" "Execution Completed"
        return 0
    fi
}

# Function to update the status of a specific process in the arrays
update_status() {
    process_name="$1"  # Removed 'local'
    status="$2"
    message="$3"
    for idx in "${!PROCESSES[@]}"; do
        if [[ "${PROCESSES[idx]}" = "${process_name}" ]]; then
            STATUSES[idx]="${status}"
            break
        fi
    done
    update_audit_file "${message}"
}

# Function to execute BigQuery to GCS export
export_bq_to_gcs() {
    echo "Starting BigQuery export for table NO_RULE_MATCH_REPORT from dataset ${SRC_DB} to GCS bucket ${TEMP_GCS_BKT}..."
    bq extract --destination_format=CSV \
        "${SRC_DB}.NO_RULE_MATCH_REPORT" \
        "${TEMP_GCS_BKT}/NO_RULE_MATCH_REPORT_${DATE}.csv"
    if [[ $? -eq 0 ]]; then
        echo "BigQuery export completed successfully."        
    else
        echo "ERROR: BigQuery export failed."
        exit 1
    fi
}
# Function to execute report.py
execute_report() {
    # Additional condition: Execute change_sudouser.ksh if PROJECT_ENV is qa
    if [[ "${PROJECT_ENV}" = "qa" ]]; then
        echo "PROJECT_ENV is qa. change the user to datatfr and  Get consolidated non-prod archival summary  ..."
        if ! ksh "${PROGDIR}/archival_non_prod_summary.ksh"; then
            echo "ERROR: Failed to execute archival_non_prod_summary. Aborting reporting."
            exit 1
        fi
    fi
    if [[ "${PROJECT_ENV}" = "qa" ]]; then
        echo "uploading all non-prod archival no rule match data to GCS  ..."
        bq extract --destination_format=CSV \
        "${SRC_DB}.NO_RULE_MATCH_REPORT_NON_PROD" \
        "${TEMP_GCS_BKT}/NO_RULE_MATCH_REPORT_NON_PROD_${DATE}.csv"
        if [[ $? -eq 0 ]]; then
			echo "BigQuery export completed successfully."        
		else
			echo "ERROR: BigQuery export failed."
			exit 1
		fi

    fi
    
    # Execute report.py
    REPORT_SCRIPT="${PROGDIR}/report.py"
    if [[ ! -f "${REPORT_SCRIPT}" ]]; then
        echo "ERROR: report.py script not found at ${REPORT_SCRIPT}"
        exit 1
    fi

    echo "All processes completed successfully. Executing report.py with config: ${CONFIG_FILE}..."
    if ! python3 "${REPORT_SCRIPT}" "${CONFIG_FILE}"; then
        echo "ERROR: Execution failed for report.py."
        exit 1
    else
        echo "report.py executed successfully with config: ${CONFIG_FILE}"
    fi
}

# Main script logic
if [[ ! -f "${AUDIT_FILE}" ]]; then
    echo "Audit file not found. Initializing a new audit file..."
    initialize_audit_file
    echo "Loading statuses after initializing the audit file..."
    read_status_from_audit_file
else
    echo "Audit file found. Loading statuses from the audit file..."
    read_status_from_audit_file
fi

# Execute processes based on statuses
ALL_SUCCESS=1
STOP_EXECUTION=0

for idx in "${!PROCESSES[@]}"; do
    process_name="${PROCESSES[idx]}"
    status="${STATUSES[idx]}"

    if [[ "${STOP_EXECUTION}" -eq 1 ]]; then
        echo "Skipping ${process_name} due to failure in a prior process."
        continue
    fi

    if [[ "${status}" != "${STATUS_SUCCESS}" ]]; then
        if ! execute_process "${process_name}"; then
            ALL_SUCCESS=0
            STOP_EXECUTION=1  # Set STOP_EXECUTION to proceed further processes
        fi
    else
        echo "${process_name} already succeeded. Skipping."
    fi
done

# Call the BigQuery export function to upload no rule match data to GCS Bucket
export_bq_to_gcs

# Determine whether to execute the report
if [[ -z "${CONFIG_FILE}" ]]; then
    echo "WARNING: Reporting skipped because the environment is neither 'qa' nor 'prod'."
elif [[ "${ALL_SUCCESS}" -ne 1 ]]; then
    echo "ERROR: Reporting skipped due to one or more process failures."
else
    execute_report
fi




