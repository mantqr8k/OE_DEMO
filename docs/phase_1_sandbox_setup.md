# Phase 1 Sandbox Setup

## Purpose

Phase 1 creates the Snowflake sandbox foundation for the healthcare data governance demo.

It creates:

- Demo roles
- Role hierarchy linked to `SYSADMIN`
- Demo warehouse
- Demo database
- Bronze, Silver, Gold, Governance, and Analytics schemas
- Baseline grants for later implementation phases

## Execution Order

Run the scripts in this order:

1. `snowflake/00_setup_roles_warehouse.sql`
2. `snowflake/01_create_database_schemas.sql`
3. `snowflake/99_validate_phase_1.sql`

## Required Snowflake Privileges

Use a role that can create roles, grant roles, create warehouses, and create databases.

Recommended:

- Use `SECURITYADMIN` for role creation and role grants.
- Use `SYSADMIN` for warehouse, database, and schema creation.

The scripts include `USE ROLE` statements for these boundaries.

## Role Hierarchy

The demo roles roll up to `SYSADMIN` through `HC_DEMO_ADMIN`:

```text
SYSADMIN
  |
  +-- HC_DEMO_ADMIN
        |
        +-- HC_PHYSICIAN_ROLE
        +-- HC_ANALYST_ROLE
        +-- HC_STEWARD_ROLE
```

This keeps sandbox administration centralized while preserving separate demo personas for masking, quality stewardship, and analytics access.

## Sandbox Objects

- Database: `HC_GOV_DEMO`
- Warehouse: `HC_GOV_WH`
- Schemas:
  - `BRONZE`
  - `SILVER`
  - `GOLD`
  - `GOVERNANCE`
  - `ANALYTICS`

## Reset

To remove the sandbox, run:

```sql
snowflake/teardown.sql
```

The teardown script drops only demo-owned objects named in this plan.

