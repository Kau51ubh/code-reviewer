-- SCENARIO: INSERT ... SELECT with no target column list, hardcoded ETL_BATCH_SK
--           aliases, plus GROUP BY and UNION ALL (optimization candidate).
-- EXPECTED: linter injects the explicit target column list extracted from the
--           SELECT, parameterizes the etl_batch_sk aliases, and (because of
--           GROUP BY / UNION) escalates to the AI for execution-plan advice.
--           Status: AUTO-FIXED + AI Optimized tab.
INSERT INTO DB_AEDWD2.customer_summary
SELECT customer_id, SUM(amount) AS total_amount, 12345 AS etl_batch_sk
FROM DB_AEDWD2.orders
GROUP BY customer_id
UNION ALL
SELECT customer_id, 0 AS total_amount, 12345 AS etl_batch_sk
FROM DB_AEDWD2.refunds
GROUP BY customer_id;
