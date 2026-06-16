-- Phase 1 validation queries.
-- These queries should return the sandbox objects and grants created by Phase 1.

SHOW ROLES LIKE 'HC_%';

SHOW GRANTS TO ROLE HC_DEMO_ADMIN;
SHOW GRANTS TO ROLE SYSADMIN;

SHOW WAREHOUSES LIKE 'HC_GOV_WH';

SHOW DATABASES LIKE 'HC_GOV_DEMO';
SHOW SCHEMAS IN DATABASE HC_GOV_DEMO;

