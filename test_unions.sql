-- Filename: test_unions.sql
-- Description: Testing UNION threshold parsing

SELECT transaction_id, user_id, amount, 'ACTIVE' as stage 
FROM archive_transactions_jan
WHERE amount > 5000

UNION

SELECT transaction_id, user_id, amount, 'PENDING' as stage
FROM pending_transactions_feb
WHERE amount > 5000;
