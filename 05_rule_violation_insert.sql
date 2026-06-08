-- Rule Violation: Implicit column definitions and multiple INSERT statements
INSERT INTO ${AEDW_DB}.monthly_summary
VALUES (101, 500.00, '2026-06-01');

INSERT INTO ${AEDW_DB}.monthly_summary
VALUES (102, 300.00, '2026-06-01');