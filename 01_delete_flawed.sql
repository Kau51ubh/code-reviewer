-- Missing explicit columns, dangerous bypass, hardcoded DB
DELETE FROM ${AEDW_DB}.orders 
WHERE order_id = 1;