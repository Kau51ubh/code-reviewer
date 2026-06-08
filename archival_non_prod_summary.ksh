#!/usr/bin/ksh
############################################################################
# Program   : change-sudouser.ksh
# --------------------------------------------------------------------------
 
#############################################
#####                                   #####
#####  Constants and Global Variables   #####
#####                                   #####
#############################################
 
# Check for Debug mode
if [ $DEBUG ]; then set -x; fi
 
# Test if shell script is being invoked
# from directory where script resides
# or from a different directory
 
if [[ $(dirname ${0}) = . ]] then
  CURRDIR=$PWD
  PROGNAME=${0}
  PROGDIR=${CURRDIR}
else
  CURRDIR=${0}
  PROGNAME=$(basename ${CURRDIR})
  PROGDIR=$(dirname ${CURRDIR})
fi
 
# Create tempsql file w/ datetime version
# trim off extension .btq, .bteq etc
SQLBASE=$(basename $0 .ksh)
echo "Base SQL File Name: " $SQLBASE
 
# Changed PROGBASE to BTEQ base file name (parameter 1)
#PROGBASE=$(basename $PROGNAME .ksh)
PROGBASE=$SQLBASE
 
 
#########################################################
#Set environment variables
#and define functions
#########################################################
unset FPATH
BASEDIR=$(echo ${PROGDIR} | awk -F/ ' { print $2 } ')
ENVDIR=$(echo ${PROGDIR} | awk -F/ ' { print $3 } ')
export typeset FPATH=/${BASEDIR}/${ENVDIR}/functions
 
# Trap TERM, ERR, and INT signals and properly exit
# Ignore signal of 1 because this is a good return
# code from Datastage
# trap '' HUP
 
#trap 'f_term_exit $?' TERM QUIT HUP
#trap 'f_int_exit $?' INT ILL KILL BUS SEGV SYS PIPE CLD
 
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

env=`echo ${AEDW_BASE_ENV}| awk -F '/' {'print $3'}`
echo "env=$env"


sudo su - datatfruser -c 'ksh -x /aedwload/qa/common/script/exec_btq.ksh /aedwload/qa/common/script/Archival_report_non_prod.sql'

exit 0
