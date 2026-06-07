-- SCENARIO: multiple single-row INSERTs into the same table + missing column list
-- EXPECTED: linter merges them into one INSERT ... VALUES (...),(...),(...),
--           injects a placeholder target column list, parameterizes the dataset.
--           Status: AUTO-FIXED.
INSERT INTO DB_AEDWD2.dim_status VALUES (1, 'ACTIVE');
INSERT INTO DB_AEDWD2.dim_status VALUES (2, 'INACTIVE');
INSERT INTO DB_AEDWD2.dim_status VALUES (3, 'PENDING');
