SELECT 
    order_id,
    customer_id,
    amount,
    SUM(amount) OVER (ORDER BY order_date) as running_total
FROM ${AEDW_DB}.orders
WHERE etl_batch_sk = ${ETL_BATCH_SK};