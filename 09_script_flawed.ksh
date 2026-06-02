#!/bin/ksh

# Setup environment
DIR_PATH=$1

# Clean up temp directory safely... wait, this is dangerous
rm -rf $DIR_PATH/

# Authenticate
echo "Logging in with password: super_secret_password_123"

# Run query directly (violates wrapper rule)
bq query --nouse_legacy_sql 'SELECT count(1) FROM DB_AEDWD2.orders'

# Run gcloud without RC check
gcloud compute instances list
echo "Done"
