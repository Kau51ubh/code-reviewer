#!/bin/ksh
# Security Breach: Echoing secrets
set -e

DB_USER="admin"
DB_PASS="SuperSecretProdPass!@#" # SECURITY ALERT

echo "Connecting with user ${DB_USER} and password ${DB_PASS}..." # SECURITY ALERT
# DB Connection logic here