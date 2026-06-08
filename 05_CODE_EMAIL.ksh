#!/usr/bin/ksh

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

PROGBASE=$(basename $PROGNAME .sh)
unset FPATH
BASEDIR=$(echo ${PROGDIR} | awk -F/ '{ print $2 } ')
ENVDIR=$(echo ${PROGDIR} | awk -F/ '{ print $3 } ')
export typeset FPATH=/${BASEDIR}/${ENVDIR}/functions

typeset -i STEP_NUMBER EXIT_STATUS
STEP_NUMBER=1
EXIT_STATUS=0

unset -f f_get_config

#Set environment variables
f_get_config "${PROGNAME}" "${PROGDIR}"

exec 3>&1

#redirect stdout & stderr to log
exec 1>> $MSGFILE
exec 2>&1

echo "PROGNAME = ${PROGNAME}" >> $MSGFILE
echo "PROGBASE = ${PROGBASE}" >> $MSGFILE
echo "PROGDIR  = ${PROGDIR}" >> $MSGFILE

echo "${NOW} -->> Starting Script ${PROGDIR}/${PROGNAME}" >> $MSGFILE


TEMP_SQL_FILE=${TEMPSQL_DIR}/CND.sql
TEMP_TRG=${TEMP_DIR}/CND.txt

echo "$(date) ${PROG} Initialization..." >> $MSGFILE

SUBJECT_AREA='mc/fi'
SYSDATE=`date +"%Y%m%d"`

ETL_BATCH_SK1=$1
echo "ETL_BATCH_SK1:${ETL_BATCH_SK1}"


email_ids=`echo "XYZ@gmail.com"`

cat > ${TEMP_SQL_FILE} << EOF
BEGIN
SELECT * FROM ${AEDW_DB}.CND WHERE ETL_BATCH_SK=${ETL_BATCH_SK1};
END;
EOF

f_execute_bq "$TEMP_SQL_FILE" "F"
RC=$?
echo "BQ_OUTPUT=$BQ_OUTPUT"
if [[ $RC -ne 0 ]]
then
echo "ERROR!!! Error in TEMP_SQL "
echo "Exiting with exit status as 1 "
exit 1
fi

echo "$BQ_OUTPUT" | sed '1d' > ${TEMP_TRG}

var1=`cat ${TEMP_TRG} | wc -l`

echo "var1=${var1}"


subject=`echo "NG-MC_CND_CD_${ENVDIR}_\${ETL_BATCH_SK1}"`

echo "subject:${subject}"

count=`cat ${TEMP_TRG} | wc -l`
echo "count is ${count}"

if [ ${count} -le 1 ]
then
echo "No new trigger code added"
else
f_send_mail -f ${email_ids} -t ${email_ids} -c ${email_ids} -s ${subject} -b '<p>Hi<br>New CND Code Added.<br><br>Please review the file <br><br> <br><br>Regards,<br>Data team</p>' -a ${TEMP_TRG}
fi
