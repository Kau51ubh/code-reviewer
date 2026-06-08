-- Clean query using proper parameterization and explicit columns
SELECT 
    customer_id, 
    customer_name, 
    order_date 
FROM 
    ${AEDW_DB}.customer_orders 
WHERE 
    order_date >= DATETIME(2026, 1, 1)
    AND etl_batch_sk = ${ETL_BATCH_SK};