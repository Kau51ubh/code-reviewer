-- Syntax error: Missing comma between columns and invalid keyword
SELECT 
    order_id
    total_amount
    FROMM ${AEDW_DB}.sales
WHERE status = 'CLOSED'