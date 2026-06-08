-- Optimization needed: SELECT * and an unindexed CROSS JOIN
SELECT * FROM ${AEDW_DB}.transactions t
CROSS JOIN ${AEDW_DB}.date_dim d
WHERE t.transaction_date = d.full_date;