#!/bin/ksh
#Script Handling Key point:
#load_audit_entries
#	Loads audit logs from the file into BigQuery if the log file exists and has data.
#	Removes the audit log file after loading.
#	
#etl_vm_file_move_process
#	Moves ETL_VM files to a temporary location.
#	Uses xargs -P 5 for parallel file transfers (5 processes at a time).
#	Syncs files from the temporary location to the GCS archival bucket using gsutil -m rsync.
#	Filters the rsync logs and updates audit logs based on transfer status.
#	Deletes source files post-transfer if successful.
#
#Purge Processes (ETL_VM and Composer):
#	Both purge processes (ETL_VM and Composer) move files to the purge bucket using gsutil mv.
#	Parallelism is implemented using a loop with a wait mechanism, ensure only a limited number of transfers run at the same time.
#
#composer_file_move_process:
#	Moves Composer files from the source to the staging bucket.
#	Handles file transfers similarly to ETL_VM processes, using parallelism for efficiency.
#	
#Auditing:
#	Transfer logs are captured in audit files and loaded into BigQuery.
#	Rsync logs are filtered to capture information for audit tracking.


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
# Set environment variables
# and define functions
# #######################################################################################

unset FPATH
BASEDIR=$(echo ${PROGDIR} | awk -F/ ' { print $2 } ')
ENVDIR=$(echo ${PROGDIR} | awk -F/ ' { print $3 } ')
export typeset FPATH=/${BASEDIR}/${ENVDIR}/functions
typeset -i STEP_NUMBER EXIT_STATUS
STEP_NUMBER=1
EXIT_STATUS=0

unset -f f_get_config
# Set environment variables
f_get_config "${PROGNAME}" "${PROGDIR}"

# Make copy of stdout to file desc 3 (need later to return stdout to screen)
exec 3>&1

# Redirect stdout & stderr to log
exec 1>> $MSGFILE
exec 2>&1

TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Set directories
SCRIPTDIR=${PARENTDIR}/script
TEMPDIR=${PARENTDIR}/temp
TEMPSQLDIR=${PARENTDIR}/tempsql
EXTRACTDIR=${PARENTDIR}/extract
REJECTDIR=${PARENTDIR}/reject
RESULTDIR=${PARENTDIR}/result
STGDIR=${PARENTDIR}/stg
ARCHIVEDIR=${PARENTDIR}/archive
COMMONDIR=${PARENTDIR}/common

###########################################
# Defined ETL_VM approach parameters
###########################################
ETL_VM_TEMP_FILE="/aedwload/${PROJECT_ENV}/common/temp/etl_vm_files_$TIMESTAMP.txt"

RSYNC_LOG="/aedwload/${PROJECT_ENV}/common/temp/rsync_log_$TIMESTAMP.txt"
RSYNC_TRANSFERRED_LOG="/aedwload/${PROJECT_ENV}/common/temp/rsync_transferred_files_$TIMESTAMP.txt"
PURGE_FILE_LIST="/aedwload/${PROJECT_ENV}/common/temp/purge_file_list_$TIMESTAMP.txt"
VM_TEMP_LOCATION_NM="/aedwload/VM_DATA_ARCHIVAL/TEMP1"
##GCP_DART_ARCHIVAL_BUCKET="gs://ihg-dart-edw-${PROJECT_ENV}-archive"
##GCP_DART_PURGE_BUCKET="gs://ihg-dart-edw-${PROJECT_ENV}-purge"

#Audit Files
VM_TO_ARCH_BUCKET_AUD_FILE="/aedwload/${PROJECT_ENV}/common/temp/vm_archive_bucket_aud_$TIMESTAMP.txt"
ALL_BUCKET_TO_ARCHIVE_AUD_FILE="/aedwload/${PROJECT_ENV}/common/temp/all_archive_bucket_aud_$TIMESTAMP.txt"
ARCH_TO_PURGE_AUD_FILE="/aedwload/${PROJECT_ENV}/common/temp/arc_to_purge_aud_$TIMESTAMP.txt"
PRV_WEEK_RECORD_DEL="/aedwload/${PROJECT_ENV}/common/temp/prv_week_records_del_$TIMESTAMP.txt"

# Define parameters
COMPOSER_TEMP_FILE="/aedwload/${PROJECT_ENV}/common/temp/composer_files_$TIMESTAMP.txt"
NUM_PARALLEL_TRANSFERS=20  # Number of parallel transfers

#check if bucket values are present in config

if  [ -z "${GCP_DART_ARCHIVAL_BUCKET}" ] || [ -z "${GCP_DART_PURGE_BUCKET}" ]  ; then
    echo "The variable GCP_DART_ARCHIVAL_BUCKET or GCP_DART_PURGE_BUCKET is empty or missing"
     exit 1
    
else
    echo "The variable has a value"
fi

TEMP_SQL1=${TEMP_DIR}/${PROGBASE}_1.sql
########## get last execution date , need to use the same for reporting queries
echo "SELECT COALESCE(MAX(LAST_UPDT_TS),CURRENT_DATE()) FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_AUD_CTL;"> ${TEMP_SQL1}
f_execute_bq "$TEMP_SQL1" "F"



if [[ $? -ne 0 ]]
	then 
		echo " Faile to fetch last execution date"
		exit 1
	else 
        echo "$BQ_OUTPUT"
        LAST_EXEC_DATE=`echo "$BQ_OUTPUT" |tail -n+2`
		echo "LAST_EXEC_DATE=${LAST_EXEC_DATE}"
	fi

export Run_Date=$(date +"%Y-%m-%d")
TEMP_SQL2=${TEMP_DIR}/${PROGBASE}_2.sql
 echo "SELECT COUNT(*) FROM ${SRC_DB}.ETL_FILES_ACTION_NEEDED;"> ${TEMP_SQL2}
f_execute_bq "$TEMP_SQL2" "F"

echo "$BQ_OUTPUT"
Count=`echo "$BQ_OUTPUT" |tail -n+2`
echo "Count=${Count}"

# Check if the table is empty
if [[ $Count -eq 0 ]]
 then
    echo "No data in the current week action table, so no proceeding with archive and purging logic."
    TEMP_SQL3=${EXTRACT_DIR}/Report_archival.sql
		echo " 
		CREATE OR REPLACE TABLE ${SRC_DB}.CURRENT_WEEK_ARCHIVE_REPORT AS
		SELECT ORIG_FILE_NM AS ORIGINAL_FILE_PATH,'${ENVDIR}' AS ENV,ARCHV_FILE_NM AS PURGED_FILE_PATH,REGEXP_EXTRACT(FILE_ARCHV_ACT_DSC, r'^[^,]+') AS FILE_SRC_SYS_NM,ARCHV_FILE_SIZE_VAL,ARCHV_RULE_NO,FILE_ARCHV_ACT_DT,FILE_ARCHV_ACT_STS_VAL FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_AUD_CTL  WHERE FILE_ARCHV_ACT_DSC LIKE  '%Transferred to GCS Archival bucket%' AND FILE_ARCHV_ACT_STS_VAL='Success' and DATE(LAST_UPDT_TS)=CURRENT_DATE() AND FILE_ARCHV_ACT_DT=CURRENT_DATE();
		CREATE OR REPLACE TABLE ${SRC_DB}.NEXT_WEEK_ARCHIVE_REPORT AS
		SELECT FILE_NM AS NEXT_WEEK_PLANNED_FILES,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE,FILE_ARCHV_PLN_DT AS NEXT_WEEK_ARCHIVE_PLANNED_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_ARCHV_PLN_DT BETWEEN CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE)+1  AND DATE_ADD(CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE), INTERVAL 7 DAY) AND FILE_ARCHV_PVS_WK_IND='Y';
		CREATE OR REPLACE TABLE ${SRC_DB}.CURRENT_WEEK_PURGING_REPORT AS
		SELECT ORIG_FILE_NM AS ORIGINAL_FILE_PATH,'${ENVDIR}' AS ENV,ARCHV_FILE_NM AS PURGED_FILE_PATH,REGEXP_EXTRACT(FILE_ARCHV_ACT_DSC, r'^[^,]+') AS FILE_SRC_SYS_NM,ARCHV_FILE_SIZE_VAL,ARCHV_RULE_NO,FILE_ARCHV_ACT_DT,FILE_ARCHV_ACT_STS_VAL FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_AUD_CTL  WHERE FILE_ARCHV_ACT_DSC LIKE  '%Transferred to GCS Purge bucket%' AND FILE_ARCHV_ACT_STS_VAL='Success' and DATE(LAST_UPDT_TS)=CURRENT_DATE() AND FILE_ARCHV_ACT_DT=CURRENT_DATE();
		CREATE OR REPLACE TABLE ${SRC_DB}.NEXT_WEEK_PURGING_REPORT AS
		SELECT FILE_NM AS NEXT_WEEK_PLANNED_FILES,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE,FILE_PURGE_PLN_DT as NEXT_WEEK_PURGING_PLANNED_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_PURGE_PLN_DT BETWEEN CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE)+1  AND  DATE_ADD(CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE), INTERVAL 7 DAY) AND FILE_PURGE_PVS_WK_IND='Y';
		CREATE OR REPLACE TABLE  ${SRC_DB}.NO_RULE_MATCH_REPORT  AS
		SELECT FILE_NM AS File_Name,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_SIZE_DSC='NRM';
		CREATE OR REPLACE TABLE ${SRC_DB}.ARCHIVAL_SIZE_REPORT  AS
		SELECT FILE_NM AS File_Name,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_SIZE_DSC='Y';
        CREATE OR REPLACE TABLE ${SRC_DB}.HOME_FOLDER_REPORT AS SELECT '${ENVDIR}' AS ENV,OWNERE,HOME_FOLDER_SIZE FROM (
		SELECT 
		REPLACE(home_files.OWNERE,'/','')  AS OWNERE ,
		SUM(home_files.FILE_SIZE_VAL) AS HOME_FOLDER_SIZE
		FROM 
			(
				SELECT 
				FILE_NM,
				FILE_SIZE_VAL,
				(REGEXP_EXTRACT(substr(FILE_NM,6), r'^/(?:[^/]*?/){1}')) AS OWNERE
				FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL
				WHERE FILE_NM like '/home/%') home_files
				CROSS JOIN
				(SELECT
					FILE_SIZE_VAL AS FILE_SIZE_VAL,
					ARCHV_RETN_DAYS_CNT AS ARCHV_RETN_DAYS_CNT,
					ARCHV_RULE_NO AS ARCHV_RULE_NO,
					ARCHV_IND AS ARCHV_IND
						FROM
						${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA
						WHERE 
						UPPER(FILE_FOLDER_NM) = 'HOME' ) AS home_rule 
						WHERE home_files.FILE_SIZE_VAL  >= home_rule.FILE_SIZE_VAL
						GROUP BY home_files.OWNERE);  
		">${TEMP_SQL3}
	f_execute_bq "${TEMP_SQL3}" "F" 

	
	if [[ $? -ne 0 ]]
	then 
		echo "${EXTRACT_DIR}/Report_archival.sql failed"
		exit 1
	else 
		echo "${EXTRACT_DIR}/Report_archival.sql successful"
	fi
		exit 0  
else
    echo "Proceeding with archive and purging logic..."

fi
###########################################
# Common Functions
###########################################

log_and_exit() {
  message="$1"
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: $message"
  exit 1
}

load_audit_entries() {

	AUDIT_LOG_FILE=$1
	if [[ -f "$AUDIT_LOG_FILE" && -s "$AUDIT_LOG_FILE" ]]; then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Loading audit entries into BigQuery."

		bq load -q --source_format=CSV --field_delimiter='^' "${SRC_DB}.ETL_SYS_FILE_ARCHV_AUD_CTL" "$AUDIT_LOG_FILE" \
		|| log_and_exit "Failed to load audit logs($AUDIT_LOG_FILE) into BigQuery."
	fi
	
	#rm -f "$AUDIT_LOG_FILE"
}

###############################################
##ETL_VM $ ALL Buket Archvie process functions
###############################################

etl_vm_file_move_process() {
	
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: ETL_VM file move process started."
	
	TEMP_METADATA_FILE=$(mktemp)
	> "$PRV_WEEK_RECORD_DEL"
      
	TIMESTAMP1=$(date +"%Y%m%d%H%M%S")

	while IFS=, read -r filename rule_no file_size; do
		echo "${filename}_${TIMESTAMP1},$rule_no,$file_size" >> "$TEMP_METADATA_FILE"
	done < "$ETL_VM_TEMP_FILE"
	
	echo "****************TEMP File Content****************************************"
	cat $TEMP_METADATA_FILE | head -10
	echo "*************************************************************************"
	
	cat "$ETL_VM_TEMP_FILE"| cut -d',' -f1 | xargs -P 20 -I {} bash -c '
		file="{}"
		SRC_FILE_PATH="$file"
		DEST_FILE_PATH="'$VM_TEMP_LOCATION_NM'${file}_'$TIMESTAMP1'"
        echo "destination file path is  $DEST_FILE_PATH"

		{
		if [[ ! -f "$SRC_FILE_PATH" ]]; then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Source file $SRC_FILE_PATH does not exist."
			exit 1
		fi

		mkdir -p "$(dirname "$DEST_FILE_PATH")" || { echo "Failed to create directory for $DEST_FILE_PATH"; exit 1; }

		if mv "$SRC_FILE_PATH" "$DEST_FILE_PATH"; then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Moved $SRC_FILE_PATH to $DEST_FILE_PATH"
		else
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Failed to move $SRC_FILE_PATH"
		fi
		}
	'
	
	echo "All files moved to the ${VM_TEMP_LOCATION_NM} Location"
	echo "=================================================================================================="
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Syncing files to GCS Archive bucket: ${GCP_DART_ARCHIVAL_BUCKET}.."
	
	gsutil -m rsync -r "${VM_TEMP_LOCATION_NM}" "${GCP_DART_ARCHIVAL_BUCKET}/ETL_VM" > "$RSYNC_LOG" 2>&1 \
	|| echo "Failed to sync files to GCS Archive bucket: ${GCP_DART_ARCHIVAL_BUCKET}."
    
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Sync completed. Processing audit."
	grep -v -e 'At' -e 'Building' -e 'Starting'  -e '100% Done' -e 'Operation' -e 'objects could not be copied/removed' "$RSYNC_LOG" > "${RSYNC_TRANSFERRED_LOG}"
  ##e '^/' -e '^\\' -e '^-'
	> "$VM_TO_ARCH_BUCKET_AUD_FILE" # Create the log file
	> "$PRV_WEEK_RECORD_DEL"
	
	while IFS= read -r line; do	
		
		if [[ $line == *Copying* ]]; then
				
			original_filename=$(echo "$line" |sed -n 's/^.*file:\/\/\(.*\) \[.*\].../\1/p' | sed "s/_${TIMESTAMP1}//" | sed 's|/aedwload/VM_DATA_ARCHIVAL/TEMP1||')
			file_name=$(echo "$line" |sed -n 's/^.*file:\/\/\(.*\) \[.*\].../\1/p' | sed 's|/aedwload/VM_DATA_ARCHIVAL/TEMP1||')
			archival_file_location="${GCP_DART_ARCHIVAL_BUCKET}/ETL_VM${file_name}"
			
			IFS=',' read -r rule_no file_size <<< $(grep -F "$file_name" $TEMP_METADATA_FILE | cut -d',' -f2- | tr -d '[:space:]')
			
			echo "$original_filename^$rule_no^$archival_file_location^$file_size^ETL_VM,Transferred to GCS Archival bucket^$(date +"%Y-%m-%d")^Success^$(TZ="America/New_York" date +"%Y-%m-%d %H:%M:%S")" >> "$VM_TO_ARCH_BUCKET_AUD_FILE"
			echo "$original_filename^ETL_VM^$rule_no" >> "$PRV_WEEK_RECORD_DEL"
	
			echo "deleting file $VM_TEMP_LOCATION_NM$file_name"
			rm "$VM_TEMP_LOCATION_NM$file_name" 
			
		elif [[ $line == *Permission* ]]; then
		
			original_filename=$(echo "$line" |sed -n 's/^.*file:\/\/\(.*\) \[.*\].../\1/p' | sed "s/_${TIMESTAMP1}//" | sed 's|/aedwload/VM_DATA_ARCHIVAL/TEMP1||')
			file_name=$(echo $line | sed -n 's/^.*file:\/\/\(.*\)".*/\1/p' | sed 's|/aedwload/VM_DATA_ARCHIVAL/TEMP1||')
			archival_file_location="${GCP_DART_ARCHIVAL_BUCKET}/ETL_VM${file_name}"
						
			IFS=',' read -r rule_no file_size <<< $(grep -F "$file_name" $TEMP_METADATA_FILE | cut -d',' -f2-)
			
			echo "$original_filename^$rule_no^$archival_file_location^$file_size^ETL_VM,Not Transferred to GCS Archival bucket^$(date +"%Y-%m-%d")^Failed^$(TZ="America/New_York" date +"%Y-%m-%d %H:%M:%S")" >> "$VM_TO_ARCH_BUCKET_AUD_FILE"
			
		fi
	done < "$RSYNC_TRANSFERRED_LOG"
	
	
	bq load -q --replace --source_format=CSV --field_delimiter='^' "${SRC_DB}.PRV_WEEK_RECORD_DEL" "$PRV_WEEK_RECORD_DEL" filename:STRING,filesystem:STRING,rule_no:int64 \
		|| log_and_exit "Failed to load audit logs($AUDIT_LOG_FILE) into BigQuery."
	
	bq query --use_legacy_sql=false \
	"DELETE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_PVS_WK_DTL WHERE FILE_NM IN (SELECT filename FROM ${SRC_DB}.PRV_WEEK_RECORD_DEL);"	\
	|| log_and_exit "Failed to delete the data from ETL_SYS_FILE_ARCHV_PVS_WK_DTL Table."
		
	echo "=================================================================================================="
	load_audit_entries "$VM_TO_ARCH_BUCKET_AUD_FILE"

}

composer_file_move_process() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Preparing to move files from source bucket to staging bucket."

  file_count=0
  > "$ALL_BUCKET_TO_ARCHIVE_AUD_FILE"
  > "$PRV_WEEK_RECORD_DEL"
  
  while IFS=, read -r file arch_dir rule_no file_size file_system; do
    ((file_count++))

    #BUCKET_NAME=$(echo "$file" | cut -d'/' -f3)
    #file_relative_path="${file#gs://$BUCKET_NAME/}"
	
	dest_file_path="${GCP_DART_ARCHIVAL_BUCKET}/${arch_dir}"
    {
      echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Moving $file to $dest_file_path"

      if gcloud storage -q mv "$file" "$dest_file_path"; then
        
		echo "$file^$rule_no^$dest_file_path^$file_size^$file_system,Transferred to GCS Archival bucket^$(date +"%Y-%m-%d")^Success^$(date +"%Y-%m-%d %H:%M:%S")" >> "$ALL_BUCKET_TO_ARCHIVE_AUD_FILE"
		echo "$file^$file_system^$rule_no" >> "$PRV_WEEK_RECORD_DEL"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Transfer successful and logged : $file"
		
      else
        echo "$file^$rule_no^$dest_file_path^$file_size^$file_system,Not Transferred to GCS Archival bucket^$(date +"%Y-%m-%d")^Failed^$(date +"%Y-%m-%d %H:%M:%S")" >> "$ALL_BUCKET_TO_ARCHIVE_AUD_FILE"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Transfer failed and logged : $file"
      fi
    } &

    # When reaching the limit of parallel jobs, wait for them to finish
    if [[ $((file_count % NUM_PARALLEL_TRANSFERS)) -eq 0 ]]; then
      wait
    fi
  done < "$COMPOSER_TEMP_FILE"

  wait
  
  #deleteion logic added  
	bq load -q --replace --source_format=CSV --field_delimiter='^' "${SRC_DB}.PRV_WEEK_RECORD_DEL" "$PRV_WEEK_RECORD_DEL" filename:STRING,filesystem:STRING,rule_no:int64 \
		|| log_and_exit "Failed to load audit logs($AUDIT_LOG_FILE) into BigQuery."
	
	bq query --use_legacy_sql=false \
	"DELETE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_PVS_WK_DTL WHERE FILE_NM IN (SELECT filename FROM ${SRC_DB}.PRV_WEEK_RECORD_DEL);"	\
	|| log_and_exit "Failed to delete the data from ETL_SYS_FILE_ARCHV_PVS_WK_DTL Table."
  
  load_audit_entries "$ALL_BUCKET_TO_ARCHIVE_AUD_FILE"
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: All file moves to staging completed."
}

###########################################
## ARchive Bucket Purge Function 
##########################################

archive_to_purge_process() {
  
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Composer purge process started."
  file_count=0
  > "$ARCH_TO_PURGE_AUD_FILE"  # Clear the audit log file at the start

  while IFS=, read -r file arch_dir rule_no file_size file_system; do
    ((file_count++))

    #file_nm=$(echo "$file" | sed -e 's|gs://[^/]*/||')	
	#src_file_path="${GCP_DART_ARCHIVAL_BUCKET}/${arch_dir}"
src_file_path="$file"
    dest_file_path="${GCP_DART_PURGE_BUCKET}/${arch_dir}"

    {
      echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Moving $src_file_path to $dest_file_path"

      if gcloud storage -q mv "$src_file_path" "$dest_file_path"; then
        echo "$file^$rule_no^$dest_file_path^$file_size^$file_system,Transferred to GCS Purge bucket^$(date +"%Y-%m-%d")^Success^$(date +"%Y-%m-%d %H:%M:%S")" >> "$ARCH_TO_PURGE_AUD_FILE"
        echo "$file^$file_system^$rule_no" >> "$PRV_WEEK_RECORD_DEL"
        
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Transfer successful and logged : $file"
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Transfer successful to Purge Bucket and logged."
		
      else
        echo "$file^$rule_no^$dest_file_path^$file_size^$file_system,Not Transferred to GCS Purge bucket^$(date +"%Y-%m-%d")^Failed^$(date +"%Y-%m-%d %H:%M:%S")" >> "$ARCH_TO_PURGE_AUD_FILE"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Transfer failed to Purge Bucket and logged."
      fi
    } &

    if [[ $((file_count % NUM_PARALLEL_TRANSFERS)) -eq 0 ]]; then
      wait
    fi
  done < "$PURGE_FILE_LIST"

  wait
  
  #deleteion logic added
	bq load -q --replace --source_format=CSV --field_delimiter='^' "${SRC_DB}.PRV_WEEK_RECORD_DEL" "$PRV_WEEK_RECORD_DEL" filename:STRING,filesystem:STRING,rule_no:int64 \
		|| log_and_exit "Failed to load audit logs($AUDIT_LOG_FILE) into BigQuery."
	
	bq query --use_legacy_sql=false \
	"DELETE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_PVS_WK_DTL WHERE FILE_NM IN (SELECT filename FROM ${SRC_DB}.PRV_WEEK_RECORD_DEL);"	\
	|| log_and_exit "Failed to delete the data from ETL_SYS_FILE_ARCHV_PVS_WK_DTL Table."
		
  load_audit_entries "$ARCH_TO_PURGE_AUD_FILE"
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: All file moves to purge completed."
}


########################################################################################
############################# Script execution starts here##############################
########################################################################################

echo "=================================================================================================="
echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Fetching files from ETL_FILES_ACTION_NEEDED table where FILE_SRC_SYS_NM='ETL_VM' AND STATUS='Action Required' and ARCHIVE_IND='Y' AND FILE_ARCHV_PLN_DT <='$Run_Date'"

# bq -q query --nouse_legacy_sql --format=csv --max_rows=99999 \
# "SELECT distinct PRV_FILENAME,ARCHV_RULE_NO,FILE_SIZE_VAL FROM ${SRC_DB}.ETL_FILES_ACTION_NEEDED WHERE FILE_SRC_SYS_NM='ETL_VM' AND STATUS='Action Required' and ARCHIVE_IND='Y' AND FILE_ARCHV_PLN_DT <='$Run_Date'" | tail -n +2 > "$ETL_VM_TEMP_FILE" \
# || log_and_exit "Failed to fetch ETL_VM files."


TEMP_SQL5=${TEMP_DIR}/ETL_VM_FILES_2_${TIMESTAMP}.sql

echo "
CREATE OR REPLACE TABLE ${SRC_DB}.ETL_VM_FILES as
SELECT 
 distinct PRV_FILENAME,
ARCHV_RULE_NO,
FILE_SIZE_VAL 
FROM ${SRC_DB}.ETL_FILES_ACTION_NEEDED 
WHERE 
FILE_SRC_SYS_NM='ETL_VM' 
AND STATUS='Action Required'
 and ARCHIVE_IND='Y' 
AND FILE_ARCHV_PLN_DT <='$Run_Date';"> ${TEMP_SQL5}

f_execute_bq "$TEMP_SQL5" "F"

if [[ $? -ne 0 ]]
	then 
		echo "${ETL_VM_TEMP_FILE} creation failed"
		exit 1
	else 
		echo " ${ETL_VM_TEMP_FILE} creation"
        f_bq_extract_csv_without_header "${SRC_DB}" "ETL_VM_FILES" "${TEMPDIR}/" "ETL_VM_FILES_EXTRACT_TEMP_$TIMESTAMP" "txt"
		mv "${TEMPDIR}/ETL_VM_FILES_EXTRACT_TEMP_$TIMESTAMP.txt" ${ETL_VM_TEMP_FILE}
        
        echo " ${ETL_VM_TEMP_FILE} created"
	fi



if [ -s "$ETL_VM_TEMP_FILE" ]; then
	
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: ETL_VM files found, proceeding with ETL_VM file move process..."
	etl_vm_file_move_process
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: ETL_VM file move process to Archive bucket completed."
	echo "=================================================================================================="
  
else
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: No ETL_VM files found. Skipping ETL_VM Archive process."
fi

echo "=================================================================================================="
echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Fetching files from ETL_FILES_ACTION_NEEDED table where LOWER(FILE_SRC_SYS_NM) IN (lower('inbound'), lower('outbound'), lower('staging'),lower('composer'))  AND STATUS='Action Required' and ARCHIVE_IND='Y' AND FILE_ARCHV_PLN_DT <='$Run_Date'"

# bq -q query --nouse_legacy_sql --format=csv --max_rows=99999 \
# "SELECT distinct PRV_FILENAME,ARCHIVED_DIRECTORY,ARCHV_RULE_NO,FILE_SIZE_VAL,FILE_SRC_SYS_NM FROM ${SRC_DB}.ETL_FILES_ACTION_NEEDED WHERE LOWER(FILE_SRC_SYS_NM) IN (lower('inbound'), lower('outbound'), lower('staging'),lower('composer')) AND STATUS='Action Required' and ARCHIVE_IND='Y' AND FILE_ARCHV_PLN_DT <= '$Run_Date'" | tail -n +2 > "$COMPOSER_TEMP_FILE" \
# || log_and_exit "Failed to fetch Composer files."

TEMP_SQL6=${TEMP_DIR}/COMPOSER_TEMP_FILES_${TIMESTAMP}.sql

echo "
CREATE OR REPLACE TABLE ${SRC_DB}.COMPOSER_TEMP_FILES as
SELECT 
distinct PRV_FILENAME,
ARCHIVED_DIRECTORY,
ARCHV_RULE_NO,
FILE_SIZE_VAL,
FILE_SRC_SYS_NM 
FROM ${SRC_DB}.ETL_FILES_ACTION_NEEDED 
WHERE LOWER(FILE_SRC_SYS_NM) IN (lower('inbound'), lower('outbound'), lower('staging'),lower('composer')) 
AND STATUS='Action Required' 
and ARCHIVE_IND='Y' 
AND FILE_ARCHV_PLN_DT <= '$Run_Date';"> ${TEMP_SQL6}

f_execute_bq "$TEMP_SQL6" "F"

if [[ $? -ne 0 ]]
	then 
		echo "${COMPOSER_TEMP_FILE} creation failed"
		exit 1
	else 
		echo " ${COMPOSER_TEMP_FILE} creation"
        f_bq_extract_csv_without_header "${SRC_DB}" "COMPOSER_TEMP_FILES" "${TEMPDIR}/" "COMPOSER_TEMP_FILE_TEMP_$TIMESTAMP" "txt"
		mv "${TEMPDIR}/COMPOSER_TEMP_FILE_TEMP_$TIMESTAMP.txt" ${COMPOSER_TEMP_FILE}
        
        echo " ${COMPOSER_TEMP_FILE} created"
fi


if [ -s "$COMPOSER_TEMP_FILE" ]; then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Composer files found, proceeding with move to Archive Bucket..."
  
	composer_file_move_process
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Composer file move process to Archive bucket completed."
	echo "=================================================================================================="
  
else
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: No Composer files found. Skipping Composer Archive process."
  echo "=================================================================================================="
fi 

echo "=================================================================================================="
echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Fetching files from ETL_FILES_ACTION_NEEDED tableWHERE LOWER(FILE_SRC_SYS_NM) IN (lower('inbound'), lower('outbound'), lower('staging'),lower('composer'),lower('etl_vm')) AND STATUS='Action Required' and PURGE_IND='Y' and FILE_PURGE_PLN_DT <='$Run_Date'"

# bq -q query --nouse_legacy_sql --format=csv --max_rows=99999 \
# "SELECT distinct PRV_FILENAME,ARCHIVED_DIRECTORY,ARCHV_RULE_NO,FILE_SIZE_VAL,FILE_SRC_SYS_NM FROM ${SRC_DB}.ETL_FILES_ACTION_NEEDED WHERE LOWER(FILE_SRC_SYS_NM) IN (lower('inbound'), lower('outbound'), lower('staging'),lower('composer'),lower('etl_vm')) AND STATUS='Action Required' and PURGE_IND='Y' and FILE_PURGE_PLN_DT <='$Run_Date'" | tail -n +2 > "$PURGE_FILE_LIST" \
# || log_and_exit "Failed to fetch Composer files."

TEMP_SQL7=${TEMP_DIR}/PURGE_FILE_LIST_${TIMESTAMP}.sql
echo "
CREATE OR REPLACE TABLE ${SRC_DB}.PURGE_FILE_LIST as
SELECT 
distinct 
PRV_FILENAME,
ARCHIVED_DIRECTORY,
ARCHV_RULE_NO,
FILE_SIZE_VAL,
FILE_SRC_SYS_NM 
FROM ${SRC_DB}.ETL_FILES_ACTION_NEEDED 
WHERE LOWER(FILE_SRC_SYS_NM) IN (lower('inbound'), lower('outbound'), lower('staging'),lower('composer'),lower('etl_vm')) 
AND STATUS='Action Required' and PURGE_IND='Y' and FILE_PURGE_PLN_DT <='$Run_Date';"> ${TEMP_SQL7}

f_execute_bq "$TEMP_SQL7" "F"

if [[ $? -ne 0 ]]
	then 
		echo "${PURGE_FILE_LIST} creation failed"
		exit 1
	else 
		echo " ${PURGE_FILE_LIST} creation"
                f_bq_extract_csv_without_header "${SRC_DB}" "PURGE_FILE_LIST" "${TEMPDIR}/" "$PURGE_FILE_LIST_TEMP_$TIMESTAMP" "txt"
		mv "${TEMPDIR}/$PURGE_FILE_LIST_TEMP_$TIMESTAMP.txt" ${PURGE_FILE_LIST}
        
        echo " ${PURGE_FILE_LIST} created"
fi



if [ -s "$PURGE_FILE_LIST" ]; then

	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: files found, proceeding with move to Purge Bucket..."
	archive_to_purge_process
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: All file move process to Purge bucket completed."
	echo "=================================================================================================="
 
else
 echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: No All files found. Skipping All Purge process."
 echo "=================================================================================================="
fi


TEMP_SQL3=${EXTRACT_DIR}/Report_archival.sql
	 echo " 
			CREATE OR REPLACE TABLE ${SRC_DB}.CURRENT_WEEK_ARCHIVE_REPORT AS
		SELECT ORIG_FILE_NM AS ORIGINAL_FILE_PATH,'${ENVDIR}' AS ENV,ARCHV_FILE_NM AS PURGED_FILE_PATH,REGEXP_EXTRACT(FILE_ARCHV_ACT_DSC, r'^[^,]+') AS FILE_SRC_SYS_NM,ARCHV_FILE_SIZE_VAL,ARCHV_RULE_NO,FILE_ARCHV_ACT_DT,FILE_ARCHV_ACT_STS_VAL FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_AUD_CTL  WHERE FILE_ARCHV_ACT_DSC LIKE  '%Transferred to GCS Archival bucket%' AND FILE_ARCHV_ACT_STS_VAL='Success' and DATE(LAST_UPDT_TS)=CURRENT_DATE() AND FILE_ARCHV_ACT_DT=CURRENT_DATE();
		CREATE OR REPLACE TABLE ${SRC_DB}.NEXT_WEEK_ARCHIVE_REPORT AS
		SELECT FILE_NM AS NEXT_WEEK_PLANNED_FILES,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE,FILE_ARCHV_PLN_DT AS NEXT_WEEK_ARCHIVE_PLANNED_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_ARCHV_PLN_DT BETWEEN CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE)+1  AND DATE_ADD(CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE), INTERVAL 7 DAY) AND FILE_ARCHV_PVS_WK_IND='Y';
		CREATE OR REPLACE TABLE ${SRC_DB}.CURRENT_WEEK_PURGING_REPORT AS
		SELECT ORIG_FILE_NM AS ORIGINAL_FILE_PATH,'${ENVDIR}' AS ENV,ARCHV_FILE_NM AS PURGED_FILE_PATH,REGEXP_EXTRACT(FILE_ARCHV_ACT_DSC, r'^[^,]+') AS FILE_SRC_SYS_NM,ARCHV_FILE_SIZE_VAL,ARCHV_RULE_NO,FILE_ARCHV_ACT_DT,FILE_ARCHV_ACT_STS_VAL FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_AUD_CTL  WHERE FILE_ARCHV_ACT_DSC LIKE  '%Transferred to GCS Purge bucket%' AND FILE_ARCHV_ACT_STS_VAL='Success' and DATE(LAST_UPDT_TS)=CURRENT_DATE() AND FILE_ARCHV_ACT_DT=CURRENT_DATE();
		CREATE OR REPLACE TABLE ${SRC_DB}.NEXT_WEEK_PURGING_REPORT AS
		SELECT FILE_NM AS NEXT_WEEK_PLANNED_FILES,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE,FILE_PURGE_PLN_DT as NEXT_WEEK_PURGING_PLANNED_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_PURGE_PLN_DT BETWEEN CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE)+1  AND  DATE_ADD(CAST(SUBSTR('${LAST_EXEC_DATE}',1,10) AS DATE), INTERVAL 7 DAY) AND FILE_PURGE_PVS_WK_IND='Y';
		CREATE OR REPLACE TABLE  ${SRC_DB}.NO_RULE_MATCH_REPORT  AS
		SELECT FILE_NM AS File_Name,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_SIZE_DSC='NRM';
		CREATE OR REPLACE TABLE ${SRC_DB}.ARCHIVAL_SIZE_REPORT  AS
		SELECT FILE_NM AS File_Name,'${ENVDIR}' AS ENV,FILE_SRC_SYS_NM,FILE_SIZE_VAL AS FILE_SIZE_IN_MB,ARCHV_RULE_NO,FILE_LAST_UPDATE_DT AS FILE_LAST_UPDATE_DATE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL WHERE FILE_SIZE_DSC='Y';
        CREATE OR REPLACE TABLE ${SRC_DB}.HOME_FOLDER_REPORT AS SELECT '${ENVDIR}' AS ENV,OWNERE,HOME_FOLDER_SIZE FROM (
		SELECT 
		REPLACE(home_files.OWNERE,'/','')  AS OWNERE ,
		SUM(home_files.FILE_SIZE_VAL) AS HOME_FOLDER_SIZE
		FROM 
			(
				SELECT 
				FILE_NM,
				FILE_SIZE_VAL,
				(REGEXP_EXTRACT(substr(FILE_NM,6), r'^/(?:[^/]*?/){1}')) AS OWNERE
				FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL
				WHERE FILE_NM like '/home/%') home_files
				CROSS JOIN
				(SELECT
					FILE_SIZE_VAL AS FILE_SIZE_VAL,
					ARCHV_RETN_DAYS_CNT AS ARCHV_RETN_DAYS_CNT,
					ARCHV_RULE_NO AS ARCHV_RULE_NO,
					ARCHV_IND AS ARCHV_IND
						FROM
						${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA
						WHERE 
						UPPER(FILE_FOLDER_NM) = 'HOME' ) AS home_rule 
						WHERE home_files.FILE_SIZE_VAL  >= home_rule.FILE_SIZE_VAL
						GROUP BY home_files.OWNERE);  
		 ">${TEMP_SQL3}
	 f_execute_bq "${TEMP_SQL3}" "F" 
	
	if [[ $? -ne 0 ]]
	then 
		echo "${EXTRACT_DIR}/Report_archival.sql failed"
		exit 1
	else 
		echo "${EXTRACT_DIR}/Report_archival.sql successful"
	fi
