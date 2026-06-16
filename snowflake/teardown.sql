-- Healthcare Governance Demo teardown.
-- This removes demo-owned Snowflake objects. Use only when you want to reset the sandbox.
-- Recommended execution roles: SYSADMIN for database/warehouse, SECURITYADMIN for roles.

USE ROLE SYSADMIN;

DROP DATABASE IF EXISTS HC_GOV_DEMO;
DROP WAREHOUSE IF EXISTS HC_GOV_WH;

USE ROLE SECURITYADMIN;

DROP ROLE IF EXISTS HC_PHYSICIAN_ROLE;
DROP ROLE IF EXISTS HC_ANALYST_ROLE;
DROP ROLE IF EXISTS HC_STEWARD_ROLE;
DROP ROLE IF EXISTS HC_DEMO_ADMIN;
