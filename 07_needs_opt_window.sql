-- Optimization needed: Window function applied before filtering (inefficient partition scale)
WITH ranked_sales AS (
    SELECT 
        store_id,
        sale_amount,
        ROW_NUMBER() OVER(PARTITION BY store_id ORDER BY sale_amount DESC) as rnk
    FROM ${AEDW_DB}.store_sales
)
SELECT store_id, sale_amount
FROM ranked_sales
WHERE store_id = 55; -- Filter applied too late