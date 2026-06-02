INSERT INTO DB_AEDWD2.customers (customer_id, customer_name, region, created_at, etl_batch_sk)
SELECT 
    customer_id,
    customer_name,
    'APAC' AS region,
    DATETIME(CURRENT_TIMESTAMP()) AS created_at,
    12345 AS etl_batch_sk
FROM DB_AEDWD2.stage_orders
WHERE amount > 1000.00;
