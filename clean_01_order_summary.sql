-- CLEAN: parameterized datasets, explicit target columns, single JOIN WITH an ON
-- condition, a date (non-string) WHERE filter, parameterized ${ETL_BATCH_SK}, and the
-- DATETIME-family current function. Nothing for the linter to fix, no AI red flag.
-- EXPECTED: Status CLEAN (run ddl_setup.sql first so the dry-run validates).
INSERT INTO ${AEDW_DB}.order_summary (customer_id, customer_name, order_count, total_amount, etl_batch_sk, load_dt)
SELECT
    o.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.amount) AS total_amount,
    ${ETL_BATCH_SK} AS etl_batch_sk,
    CURRENT_DATETIME() AS load_dt
FROM ${AEDW_DB}.orders AS o
JOIN ${AEDW_DB}.customers AS c ON c.customer_id = o.customer_id
WHERE o.order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY o.customer_id, c.customer_name;
