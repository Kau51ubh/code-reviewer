-- SCENARIO: a well-formed, already-parameterized query (control / happy path).
-- EXPECTED: no linter fixes, no AI needed, dry run validates. Status: CLEAN.
SELECT
    order_id,
    customer_id,
    amount
FROM ${AEDW_DB}.orders
WHERE order_date >= '2024-01-01'
  AND status = 'COMPLETE';
