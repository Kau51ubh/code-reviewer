INSERT INTO ${AEDW_DB}.customers (customer_id, customer_name, region, created_at, etl_batch_sk)
SELECT 
    customer_id,
    customer_name,
    'APAC' AS region,
    DATETIME(CURRENT_TIMESTAMP()) AS created_at,
    ${ETL_BATCH_SK} AS etl_batch_sk
FROM ${AEDW_DB}.stage_orders
WHERE amount > 1000.00; and customer name=kaustubh
