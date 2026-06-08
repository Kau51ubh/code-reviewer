-- Rule Violation: UPDATE statement missing a WHERE clause
UPDATE ${AEDW_DB}.user_profiles
SET status = 'INACTIVE',
    updated_at = CURRENT_TIMESTAMP(); -- Rule Violation: Should be DATETIME()