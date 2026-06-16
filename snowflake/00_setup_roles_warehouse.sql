-- Phase 1: Snowflake sandbox roles and warehouse setup.
-- Run this script with a role that can create roles, grant roles, and create warehouses.
-- Recommended execution role: SECURITYADMIN for role statements, SYSADMIN for warehouse statements.

USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS HC_DEMO_ADMIN
  COMMENT = 'Admin role for the Healthcare Governance Demo sandbox.';

CREATE ROLE IF NOT EXISTS HC_PHYSICIAN_ROLE
  COMMENT = 'Demo role representing clinical users who can view PHI for care workflows.';

CREATE ROLE IF NOT EXISTS HC_ANALYST_ROLE
  COMMENT = 'Demo role representing analytics users with masked PHI access.';

CREATE ROLE IF NOT EXISTS HC_STEWARD_ROLE
  COMMENT = 'Demo role representing data stewards responsible for DQ remediation.';

-- Role hierarchy. All demo roles roll up to SYSADMIN through HC_DEMO_ADMIN.
GRANT ROLE HC_PHYSICIAN_ROLE TO ROLE HC_DEMO_ADMIN;
GRANT ROLE HC_ANALYST_ROLE TO ROLE HC_DEMO_ADMIN;
GRANT ROLE HC_STEWARD_ROLE TO ROLE HC_DEMO_ADMIN;
GRANT ROLE HC_DEMO_ADMIN TO ROLE SYSADMIN;

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS HC_GOV_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Compute warehouse for the Healthcare Governance Demo sandbox.';

GRANT USAGE, OPERATE ON WAREHOUSE HC_GOV_WH TO ROLE HC_DEMO_ADMIN;
GRANT USAGE ON WAREHOUSE HC_GOV_WH TO ROLE HC_PHYSICIAN_ROLE;
GRANT USAGE ON WAREHOUSE HC_GOV_WH TO ROLE HC_ANALYST_ROLE;
GRANT USAGE ON WAREHOUSE HC_GOV_WH TO ROLE HC_STEWARD_ROLE;

