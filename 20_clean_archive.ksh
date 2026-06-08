#!/bin/ksh
# Clean: Incorporates retention/archival steps
set -e

SOURCE_DIR="/data/${env}/inbound"
ARCHIVE_DIR="/data/${env}/archive"
FILE_NAME="daily_feed.dat"

echo "Moving file to archive..."
mv ${SOURCE_DIR}/${FILE_NAME} ${ARCHIVE_DIR}/${FILE_NAME}_$(date +%Y%m%d)
RC=$?

if [[ ${RC} -ne 0 ]]; then
    echo "Archival failed."
    exit ${RC}
fi

echo "Archival complete."