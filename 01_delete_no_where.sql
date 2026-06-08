-- SCENARIO: hardcoded dataset + a DELETE that is missing its row filter (data-loss risk).
-- EXPECTED: linter parameterizes ${AEDW_DB} -> ${AEDW_DB} and appends a mandatory
--           filter placeholder. Status: CRITICAL. Dry run bypassed (placeholder).
DELETE FROM ${AEDW_DB}.orders
WHERE <MISSING_FILTER_REQUIRED> /* TODO: Add specific condition */;