-- Missing explicit columns, dangerous bypass, hardcoded DB
DELETE FROM ${AEDW_DB}.orders 
WHERE <MISSING_FILTER_REQUIRED> /* TODO: Replace global bypass with condition */;