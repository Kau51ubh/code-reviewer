SELECT 
    order_id,
    customer_id,
    amount,
    SUM(amount) OVER (ORDER BY order_date) as running_total
FROM DB_AEDWD2.orders
WHERE etl_batch_sk = 12345;
