#!/bin/ksh

# Determine current directory and script name
if [[ $(dirname ${0}) = . ]]; then
    CURRDIR=$PWD
    PROGNAME=${0}
    PROGDIR=${CURRDIR}
else
    CURRDIR=${0}
    PROGNAME=$(basename ${CURRDIR})
    PROGDIR=$(dirname ${CURRDIR})
fi

PROGBASE=$(basename $PROGNAME .ksh)

# Set environment variables
unset FPATH
BASEDIR=$(echo ${PROGDIR} | awk -F/ ' { print $2 } ')
ENVDIR=$(echo ${PROGDIR} | awk -F/ ' { print $3 } ')
export FPATH=/${BASEDIR}/${ENVDIR}/functions
typeset -i STEP_NUMBER EXIT_STATUS
STEP_NUMBER=1
EXIT_STATUS=0

# Load configuration
unset -f f_get_config
f_get_config "${PROGNAME}" "${PROGDIR}"

# Redirect stdout & stderr to log file
exec 3>&1
exec 1>> $MSGFILE
exec 2>&1

# Set directories
SCRIPTDIR=${PARENTDIR}/script
TEMPDIR=${PARENTDIR}/temp
TEMPSQLDIR=${PARENTDIR}/tempsql
EXTRACTDIR=${PARENTDIR}/extract
REJECTDIR=${PARENTDIR}/reject
RESULTDIR=${PARENTDIR}/result
STGDIR=${PARENTDIR}/stg
ARCHIVEDIR=${PARENTDIR}/archiveDS
COMMONDIR=${PARENTDIR}/common

START_DIR="${AEDW_BASE_ENV}"
M_INTERVAL=$1
MAX_BAD_ROWS=20

export Run_Date=$(date +"%Y-%m-%d")
check_exit_status() {
    if [ $1 -ne 0 ]; then
        echo "ERROR: Command failed with exit status $1"
        EXIT_STATUS=1  # Set the global exit status to 1 on any failure
    else
        echo "SUCCESS: Command completed successfully"
    fi
}

#GCS BUCKET DATA PULL (composer/inbound/outbound/staging/archive)
# Parallelize gsutil commands using background jobs (&) 
{
	gcloud storage ls -l -R ${GCS_COMPOSER_BUCKET}/dags/* > ${PARENTDIR}/temp/bucket_info_composer.txt
	sed -i '$d' ${PARENTDIR}/temp/bucket_info_composer.txt
	gcloud storage ls -l -R ${GCS_COMPOSER_BUCKET}/data/* >> ${PARENTDIR}/temp/bucket_info_composer.txt  
} &
PID1=$! # Capture the process ID
 
{
    gcloud storage ls -l -R gs://ihg-dart-edw-${PROJECT_ENV}-outbound-common > ${PARENTDIR}/temp/bucket_info_outbound.txt

} &
PID2=$!
 
{
    gcloud storage ls -l -R gs://ihg-dart-edw-${PROJECT_ENV}-inbound-common > ${PARENTDIR}/temp/bucket_info_inbound.txt 
} &
PID3=$!
 
{
    gcloud storage ls -l -R gs://ihg-dart-edw-${PROJECT_ENV}-staging | grep -v -e "VM_ARCHIVAL/" -e "VM_DATA_ARCHIVAL/" > ${PARENTDIR}/temp/bucket_info_staging.txt
} &
PID4=$!

{
    gsutil ls -l -R gs://ihg-dart-edw-${PROJECT_ENV}-archive/ETL_VM gs://ihg-dart-edw-${PROJECT_ENV}-archive/STAGING gs://ihg-dart-edw-${PROJECT_ENV}-archive/INBOUND gs://ihg-dart-edw-${PROJECT_ENV}-archive/OUTBOUND gs://ihg-dart-edw-${PROJECT_ENV}-archive/COMPOSER > ${PARENTDIR}/temp/bucket_info_archive.txt
} &
PID5=$! 
  
# Wait for all background jobs to complete and check their status
# Check if the first process failed
#$PID1
wait $PID1 $PID2 $PID3 $PID4 $PID5
 
if [ $EXIT_STATUS -ne 0 ]; then
    echo "One or more processes failed. Exiting with status $EXIT_STATUS."
    exit $EXIT_STATUS
else
    echo "All processes completed successfully."
fi

END_TIME=$(date +%s)
TIME_TAKEN=$((END_TIME - START_TIME))
echo "Total time taken: ${TIME_TAKEN} seconds"
#${PARENTDIR}/temp/bucket_info_composer.txt
cat  ${PARENTDIR}/temp/bucket_info_composer.txt ${PARENTDIR}/temp/bucket_info_outbound.txt ${PARENTDIR}/temp/bucket_info_inbound.txt ${PARENTDIR}/temp/bucket_info_staging.txt ${PARENTDIR}/temp/bucket_info_archive.txt > ${PARENTDIR}/temp/bucket_info.txt 
grep -v '/:' ${PARENTDIR}/temp/bucket_info.txt   > ${PARENTDIR}/temp/GCS_bucket_info.txt
sed -i '/^$/d;s/^[ \t]*//;s/  /^/1;s/  /^/1;$d' ${PARENTDIR}/temp/GCS_bucket_info.txt   

sed -i '/^$/d;/^TOTAL/d' ${PARENTDIR}/temp/GCS_bucket_info.txt
sed 's/[[:space:]]*$//' ${PARENTDIR}/temp/GCS_bucket_info.txt | cut -d'^' -f1-3 > ${PARENTDIR}/temp/Clean_GCS_bucket_info.txt

TEMP_SQL=${EXTRACT_DIR}/CLEANUP_BKT.sql
echo " 
CREATE OR REPLACE TABLE ${SRC_DB}.GCS_CLEANUP_DATA
(
  FILE_SIZE STRING,
  CR_DT STRING,
  FILE_NAME STRING
);

">${TEMP_SQL}
f_execute_bq "${TEMP_SQL}" "F" 

if [[ $? -ne 0 ]]
then 
	echo "${EXTRACT_DIR}/CLEANUP_BKT.sql failed"
	exit 1
else 
	echo "${EXTRACT_DIR}/CLEANUP_BKT.sql successful"
fi

bq load  --max_bad_records=${MAX_BAD_ROWS} --source_format=CSV --field_delimiter="^" --project_id=${GCPPROJ}  ${SRC_DB}.GCS_CLEANUP_DATA ${PARENTDIR}/temp/Clean_GCS_bucket_info.txt

if [[ $? -ne 0 ]]
 then
    echo "Clean_GCS_bucket_info loading encountered an error. Exiting."
    exit 1
	else
	echo "Clean_GCS_bucket_info loaded sucessfully"
fi
 

echo "Run_Date='$Run_Date'"

TEMP_SQL1=${EXTRACT_DIR}/GCS_BUCKET_DATA.sql
echo " 
DELETE FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_DTL WHERE DATE(LAST_UPDT_TS)='$Run_Date';
INSERT INTO ${SRC_DB}.ETL_SYS_FILE_ARCHV_DTL
SELECT  FILE_NAME AS FILE_NM,
 CASE
   WHEN REGEXP_CONTAINS(FILE_NAME, r'gs://us-east4-composer2') THEN 'composer'
   WHEN REGEXP_CONTAINS(FILE_NAME, r'(?i)ihg-dart-edw') and REGEXP_CONTAINS(FILE_NAME, r'(?i)archive/COMPOSER/') THEN 'composer'
   WHEN REGEXP_CONTAINS(FILE_NAME, r'(?i)ETL_VM') THEN 'ETL_VM'
   WHEN REGEXP_CONTAINS(FILE_NAME, r'(?i)STAGING') THEN 'staging'
   WHEN REGEXP_CONTAINS(FILE_NAME, r'(?i)INBOUND') THEN 'inbound'
   WHEN REGEXP_CONTAINS(FILE_NAME, r'(?i)OUTBOUND') THEN 'outbound'
   ELSE 'NA'
 END AS FILE_SRC_SYS_NM,
 ARRAY_REVERSE(SPLIT(FILE_NAME, '/'))[SAFE_OFFSET(1)] AS FILE_FOLDER_NM,
 'NA' AS FILE_OWN_NM,
  CAST(CAST(FILE_SIZE AS INT64) / (1024*1024) AS NUMERIC) AS FILE_SIZE_VAL,
 DATE(TIMESTAMP(CR_DT)) AS FILE_LAST_UPDATE_DT,
 DATETIME('$Run_Date') AS LAST_UPDT_TS FROM  ${SRC_DB}.GCS_CLEANUP_DATA;
">${TEMP_SQL1}
f_execute_bq "${TEMP_SQL1}" "F" 

if [[ $? -ne 0 ]]
then 
	echo "${EXTRACT_DIR}/GCS_BUCKET_DATA.sql failed"
	exit 1
else 
	echo "${EXTRACT_DIR}/GCS_BUCKET_DATA.sql successful"
fi
 
#ETL_VM
find /aedwload/ /home/ -type f -printf '%p;%u;%s;%TY-%Tm-%Td;%TH:%TM:%TS\n' 2>/dev/null | awk -F';' -v current_date="$(date '+%Y-%m-%d %H:%M:%S')" '{
    n = split($1, path_parts, "/");
    folder = path_parts[n-1];
    FILE_SYSTEM = "ETL_VM";
    printf "%s^%s^%s^%s^%.2f^%s^%s\n", $1,FILE_SYSTEM,folder,$2, $3/1048576, $4, current_date
}' > ${PARENTDIR}/temp/ETL_VM_file_data.csv

sed -i 's/\r//g' ${PARENTDIR}/temp/ETL_VM_file_data.csv

################# OUTBOUND ##############################

TEMP_SQL2=${EXTRACT_DIR}/ETL_VM_file_data.sql
echo " 
CREATE OR REPLACE TABLE ${SRC_DB}.ETL_VM_file_data
(FILE_NAME STRING,
  FILE_SYSTEM STRING,
  FOLDER STRING,
  OWNER STRING ,
  SIZE_IN_MB STRING,
  LMD DATE,
  LAST_UPDT_TS DATETIME
);

">${TEMP_SQL2}
f_execute_bq "${TEMP_SQL2}" "F" 

if [[ $? -ne 0 ]]
then 
	echo "${EXTRACT_DIR}/ETL_VM_file_data.sql failed"
	exit 1
else 
	echo "${EXTRACT_DIR}/ETL_VM_file_data.sql successful"
fi

bq load --max_bad_records=${MAX_BAD_ROWS} --source_format=CSV --skip_leading_rows=1  --field_delimiter="^" --project_id=${GCPPROJ}  ${SRC_DB}.ETL_VM_file_data ${PARENTDIR}/temp/ETL_VM_file_data.csv
if [[ $? -ne 0 ]]
 then
    echo "ETL_VM_file_data loading encountered an error. Exiting."
    exit 1
	else
	echo "ETL_VM_file_data loaded sucessfully"
fi

 
TEMP_SQL3=${EXTRACT_DIR}/ETL_VM_file_Scan.sql
echo " INSERT INTO ${SRC_DB}.ETL_SYS_FILE_ARCHV_DTL 
SELECT IFNULL(FILE_NAME,'NA') AS FILE_NM,
IFNULL(FILE_SYSTEM,'NA') AS FILE_SRC_SYS_NM,
CASE WHEN FILE_NAME LIKE '/home/%' THEN 'HOME' ELSE IFNULL(FOLDER,'NA') END AS FILE_FOLDER_NM,
IFNULL(OWNER,'NA') AS FILE_OWN_NM,
CAST (SIZE_IN_MB AS NUMERIC) AS FILE_SIZE_VAL,
LMD AS FILE_LAST_UPDATE_DT,
DATETIME('$Run_Date') AS LAST_UPDT_TS  FROM  ${SRC_DB}.ETL_VM_file_data
">${TEMP_SQL3}
f_execute_bq "${TEMP_SQL3}" "F" 


if [[ $? -ne 0 ]]
 then
    echo "ETL_VM_file_data loading encountered an error. Exiting."
    exit 1
	else
	echo "ETL_VM_file_data loaded sucessfully in table"
fi
 
echo "Script completed successfully."	

