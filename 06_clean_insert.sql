-- Clean: Explicit columns, single INSERT with multiple VALUES
INSERT INTO ${AEDW_DB}.monthly_summary (account_id, balance, summary_date, etl_batch_sk)
VALUES 
    (101, 500.00, DATETIME('2026-06-01'), ${ETL_BATCH_SK}),
    (102, 300.00, DATETIME('2026-06-01'), ${ETL_BATCH_SK});