-- SCENARIO: an implicit Cartesian product (two tables combined with no key) plus
--           a wildcard column list.
-- EXPECTED: linter warns about the wildcard and the missing join key; because the
--           query contains a join it escalates to the AI, which should FLAG the
--           accidental Cartesian product and suggest a join key (or a
--           <JOIN_CONDITION_REQUIRED> placeholder) in the AI Optimized tab.
--           Status: ISSUES.
SELECT *
FROM DB_AEDWD2.orders o
JOIN DB_AEDWD2.customers c;
