#!/bin/ksh
# Syntax Error: Unclosed IF statement (missing fi)
set -e

FILE_PATH="/data/inbound/file.csv"

if [[ -f ${FILE_PATH} ]]; then
    echo "File exists, processing..."
    # Processing logic
    
echo "Done."