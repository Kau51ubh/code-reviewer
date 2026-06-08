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
ARCHIVEDIR=${PARENTDIR}/archive
COMMONDIR=${PARENTDIR}/common

START_DIR="${AEDW_BASE_ENV}"
M_INTERVAL=$1

ARCHIVAL_CONFIG=${SCRIPTDIR}/Archival_extensions.cfg

if [ -e ${ARCHIVAL_CONFIG} ] && [ -s ${ARCHIVAL_CONFIG} ]; then
  echo " ${ARCHIVAL_CONFIG} File exists and is not empty"
else
  echo "ERROR File ${ARCHIVAL_CONFIG} either doesn't exist or is empty"
  echo "Create ${ARCHIVAL_CONFIG} file and add extensions  to exclude files from archival process. Exiting with exit status as 1 "
  exit 1
fi

EXTENT=`head -1 ${SCRIPTDIR}/Archival_extensions.cfg`

TEMP_SQL=${TEMP_DIR}/${PROGBASE}.sql

echo "
	INSERT INTO ${SRC_DB}.ETL_SYS_FILE_ARCHV_PVS_WK_DTL SELECT * FROM ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL ;
"> ${TEMP_SQL}

f_execute_bq "$TEMP_SQL" "F"
RC=$?

echo "$BQ_OUTPUT"

if [[ $RC -ne 0 ]]
then
	echo "ERROR!!! Error in TEMP_SQL "
	echo "Exiting with exit status as 1 "
	exit 1
fi

echo "SUCCESSFULLY EXECUTED BIGQUERY COMMAND"

Run_Date=$(date +"%Y-%m-%d")
ENV=${PROJECT_ENV}

ksh ${PARENTDIR}/script/exec_btq_custom_run.ksh ${PARENTDIR}/script/Lookup_rulescheck.sql ${ENV} ${Run_Date} ${GCS_COMPOSER_BUCKET} ${EXTENT}
RC=$?
if [[ $RC -ne 0 ]]
then
	echo "ERROR!!! Error in Lookup_rulescheck"
	echo "Exiting with exit status as 1 "
	exit 1
fi
