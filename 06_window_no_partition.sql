-- SCENARIO: window function with ORDER BY but no grouping (whole-table frame).
-- EXPECTED: the OVER() triggers AI optimization; the AI should FLAG the missing
--           grouping (running total spans the entire table) and suggest grouping
--           by customer_id. Status: OPTIMIZE (AI Optimized tab populated).
SELECT
    order_id,
    customer_id,
    amount,
    SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM ${AEDW_DB}.orders
WHERE order_date >= '2024-01-01';
