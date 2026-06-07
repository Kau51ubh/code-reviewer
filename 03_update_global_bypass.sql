-- SCENARIO: UPDATE that targets every row via a global bypass, plus a hardcoded
--           ETL_BATCH_SK and a TIMESTAMP() call.
-- EXPECTED: linter converts TIMESTAMP()->DATETIME(), parameterizes the batch SK,
--           replaces the global bypass with a safe filter placeholder, and
--           parameterizes the dataset. Status: CRITICAL.
UPDATE DB_AEDWD2.orders
SET status = 'CLOSED',
    etl_batch_sk = 99999,
    updated_at = TIMESTAMP(CURRENT_TIMESTAMP())
WHERE 1=1;
