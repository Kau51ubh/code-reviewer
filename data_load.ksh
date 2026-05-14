#!/bin/ksh
# Load data script
FILE=/tmp/data/in.csv
cat $FILE | while read line
do
  echo "Processing $line"
  sqlplus user/pass@db @run_insert.sql $line
done
echo "Done"
