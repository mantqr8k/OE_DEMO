-- Phase 6 Validation: SQL Audit-Based Data Quality Framework

USE ROLE OVALEDGE_ROLE;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;

-- 1. Verify DQ schemas and tables
SHOW TABLES IN SCHEMA GOVERNANCE.DQ;

-- 2. Verify rules loaded
SELECT * FROM GOVERNANCE.DQ.DQ_RULE ORDER BY rule_id;

-- 3. Run DQ runner (example)
CALL GOVERNANCE.DQ.RUN_DQ('RUN_' || TO_VARCHAR(CURRENT_TIMESTAMP));

-- 4. Check results
SELECT * FROM GOVERNANCE.DQ.DQ_RESULT ORDER BY rule_id;

-- 5. Check failed records
SELECT * FROM GOVERNANCE.DQ.DQ_FAILED_RECORD ORDER BY captured_at DESC LIMIT 20;

-- 6. Check alerts
SELECT * FROM GOVERNANCE.DQ.DQ_ALERT ORDER BY created_at DESC LIMIT 20;

-- 7. Acceptance checklist
-- [ ] DQ tables exist
-- [ ] Rules DQ001-DQ007 present
-- [ ] Runner executes without errors
-- [ ] Failed records are captured
-- [ ] Alerts created for failing rules
