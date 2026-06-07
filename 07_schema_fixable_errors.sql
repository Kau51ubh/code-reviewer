-- SCENARIO: small errors that the LIVE SCHEMA can resolve deterministically:
--   1) a stray semicolon that splits the WHERE clause
--   2) a column identifier written with a space ("customer name")
--   3) an unquoted string literal compared to a STRING column (= kaustubh)
-- EXPECTED: the schema-aware linter fixes all three WITHOUT calling the AI
--           (no tokens): merges the clause, -> customer_name, -> 'kaustubh'.
--           Status: AUTO-FIXED. (If the table/schema is unavailable, the BQ dry
--           run fails and the AI is asked to fix the syntax error instead.)
SELECT order_id, customer_id, amount
FROM DB_AEDWD2.orders
WHERE amount > 1000.00;
 and customer name = kaustubh
