-- CLEAN: an idempotent single-partition reload — a DELETE WITH a real WHERE (not a
-- global bypass), then one INSERT with explicit columns. Parameterized datasets and
-- ${ETL_BATCH_SK}, date-based filters (no string-equality), CURRENT_DATETIME().
-- EXPECTED: Status CLEAN (run ddl_setup.sql first so the dry-run validates).
DELETE FROM ${AEDW_DB}.daily_revenue WHERE revenue_dt = CURRENT_DATE();

INSERT INTO ${AEDW_DB}.daily_revenue (revenue_dt, gross_amount, etl_batch_sk, load_ts)
SELECT
    o.order_date AS revenue_dt,
    SUM(o.amount) AS gross_amount,
    ${ETL_BATCH_SK} AS etl_batch_sk,
    CURRENT_DATETIME() AS load_ts
FROM ${AEDW_DB}.orders AS o
WHERE o.order_date = CURRENT_DATE()
GROUP BY o.order_date;
