-- SCENARIO: hardcoded dataset + a DELETE that is missing its row filter (data-loss risk).
-- EXPECTED: linter parameterizes DB_AEDWD2 -> ${AEDW_DB} and appends a mandatory
--           filter placeholder. Status: CRITICAL. Dry run bypassed (placeholder).
DELETE FROM DB_AEDWD2.orders;
