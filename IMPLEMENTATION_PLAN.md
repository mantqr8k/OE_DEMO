# Healthcare Data Governance Demo Implementation Plan

## Summary

This implementation will build a phase-wise Snowflake sandbox demo for the Patient 360 and Readmission Analytics platform described in `AGENTS.md`.

The demo will use Snowflake as the data warehouse platform, SQL audit tables for data quality measurement, and a small Streamlit dashboard for governance and analytics storytelling.

Primary capabilities demonstrated:

- Bronze, Silver, and Gold warehouse layers
- PHI/PII classification tagging
- Role-based dynamic masking
- SQL-based data quality audits
- Failed record capture and steward assignment
- Readmission analytics KPIs
- Data lineage and impact analysis
- Governance dashboard in Streamlit

## Guiding Decisions

- Platform: Snowflake sandbox setup owned by this demo.
- UI: Small Streamlit dashboard.
- Data quality: SQL audit tables and deterministic rule execution, not native Snowflake DMFs.
- Scope: End-to-end governed warehouse demo, not a production-grade clinical data platform.
- Demo data: Synthetic sample healthcare data with intentional quality failures.

## Phase 1: Repository and Snowflake Sandbox Foundation

### Objective

Create the project structure and Snowflake sandbox baseline needed by all later phases.

### Deliverables

- Repository folders:
  - `snowflake/`
  - `data/`
  - `streamlit/`
  - `docs/`
- Snowflake setup scripts:
  - Create warehouse
  - Create database
  - Create schemas
  - Create demo roles
  - Grant minimum privileges
- Sandbox naming convention:
  - Database: `HC_GOV_DEMO`
  - Warehouse: `HC_GOV_WH`
  - Schemas: `BRONZE`, `SILVER`, `GOLD`, `GOVERNANCE`, `ANALYTICS`
  - Roles: `HC_DEMO_ADMIN`, `HC_PHYSICIAN_ROLE`, `HC_ANALYST_ROLE`, `HC_STEWARD_ROLE`
- Role hierarchy:
  - Grant `HC_PHYSICIAN_ROLE` to `HC_DEMO_ADMIN`
  - Grant `HC_ANALYST_ROLE` to `HC_DEMO_ADMIN`
  - Grant `HC_STEWARD_ROLE` to `HC_DEMO_ADMIN`
  - Grant `HC_DEMO_ADMIN` to `SYSADMIN`
  - Keep all demo roles linked to `SYSADMIN` through this hierarchy so sandbox administration remains centralized.

### Acceptance Criteria

- A fresh Snowflake account can run the setup scripts without relying on pre-existing demo objects.
- All objects are isolated under `HC_GOV_DEMO`.
- All demo roles are granted into a hierarchy that rolls up to `SYSADMIN`.
- Teardown script can remove demo-owned objects.

## Phase 2: Synthetic Source Data and Bronze Layer

### Objective

Create realistic source-system data and load it into raw Bronze tables exactly as received.

### Deliverables

- Synthetic CSV files for:
  - Patient master
  - Patient encounter
  - Lab results
  - Pharmacy orders
  - Claims
  - Appointments
  - Providers
- Bronze tables:
  - `BRONZE.BRZ_PATIENT_MASTER`
  - `BRONZE.BRZ_PATIENT_ENCOUNTER`
  - `BRONZE.BRZ_LAB_RESULTS`
  - `BRONZE.BRZ_PHARMACY_ORDERS`
  - `BRONZE.BRZ_CLAIMS`
  - `BRONZE.BRZ_APPOINTMENT` (new)
  - `BRONZE.BRZ_PROVIDER_MASTER` (new)
- Load script using Snowflake stages and `COPY INTO`.
- Intentional data quality failures:
  - Null `patient_id`
  - Future `dob`
  - Discharge date before admission date
  - Blood glucose result outside valid range
  - Null `provider_id`
  - Expired `license_expiry_date`
  - Invalid `appointment_status` values
  - Appointment `actual_start_time` before `scheduled_time`
  - `wait_time_minutes` exceeding 240 minutes

### Acceptance Criteria

- Bronze row counts match loaded CSV files.
- Raw PHI fields are visible before masking is applied.
- Injected bad records are present and queryable for all data types including appointments and providers.

## Phase 3: Silver Standardization Layer

### Objective

Create cleansed and standardized Silver models from the Bronze layer.

### Deliverables

- Silver tables or views:
  - `SILVER.SLV_PATIENT`
  - `SILVER.SLV_ENCOUNTER`
  - `SILVER.SLV_LAB_RESULT`
  - `SILVER.SLV_MEDICATION`
  - `SILVER.SLV_CLAIM`
  - `SILVER.SLV_APPOINTMENT`
  - `SILVER.SLV_PROVIDER`
- Transformations:
  - Patient deduplication
  - Full patient name standardization
  - Age calculation
  - Encounter length-of-stay calculation
  - Lab result normalization
  - Appointment status standardization
  - Provider license status calculation
  - Surrogate key generation

### Acceptance Criteria

- Silver models preserve traceability to Bronze source records.
- Patient and encounter joins resolve through surrogate keys.
- Invalid records are not silently discarded; they remain available for DQ audit reporting.
- Appointment and provider models properly handle standardization and deduplication.

## Phase 4: Gold Analytics Layer

### Objective

Create business-ready dimensional models and KPI views.

### Deliverables

- Dimensions:
  - `GOLD.DIM_PATIENT`
  - `GOLD.DIM_HOSPITAL`
  - `GOLD.DIM_DIAGNOSIS`
  - `GOLD.DIM_PROVIDER`
- Facts:
  - `GOLD.FACT_ENCOUNTER`
  - `GOLD.FACT_READMISSION`
  - `GOLD.FACT_CLAIMS`
  - `GOLD.FACT_APPOINTMENT`
  - `GOLD.FACT_PROVIDER_DAILY`
  - `GOLD.FACT_PROVIDER_MONTHLY`
- KPI views:
  - `ANALYTICS.VW_READMISSION_RATE`
  - `ANALYTICS.VW_AVERAGE_LENGTH_OF_STAY`
  - `ANALYTICS.VW_CLAIM_APPROVAL_RATE`
  - `ANALYTICS.VW_PROVIDER_UTILIZATION_RATE`
  - `ANALYTICS.VW_APPOINTMENT_COMPLETION_RATE`
  - `ANALYTICS.VW_PROVIDER_CREDENTIAL_COMPLIANCE`

### Acceptance Criteria

- Readmission logic flags encounters where the next admission occurs within 30 days.
- Appointment completion rate properly calculated from FACT_APPOINTMENT status flags.
- Provider credential compliance properly calculates from DIM_PROVIDER license_status.
- KPI views return non-empty outputs.
- Gold objects are built from Silver objects to support Snowflake lineage inspection.

## Phase 5: Classification Tags and Dynamic Masking

### Objective

Demonstrate sensitive data identification and role-based protection.

### Deliverables

- Governance tags:
  - `PHI`
  - `PII`
  - `SENSITIVE`
  - `RESTRICTED`
  - `CONFIDENTIAL`
  - `PUBLIC`
- Tag assignments for known sensitive columns:
  - PHI: name, DOB, MRN, phone, address
  - Restricted: SSN
  - Sensitive: insurance ID, diagnosis code
- Masking policies for:
  - Patient name
  - DOB
  - MRN
  - SSN
  - Phone
  - Address
  - Insurance ID
- Demo queries for:
  - Physician view
  - Analyst view

### Acceptance Criteria

- Physician role can see unmasked clinical PHI needed for care workflows.
- Analyst role sees masked PHI.
- Tag coverage can be measured from metadata views.

## Phase 6: SQL Audit-Based Data Quality Framework

### Objective

Implement deterministic SQL audit tables for data quality measurement, failed record capture, alerts, and steward assignment.

### Deliverables

- Governance audit tables:
  - `GOVERNANCE.DQ_RULE`
  - `GOVERNANCE.DQ_RUN`
  - `GOVERNANCE.DQ_RESULT`
  - `GOVERNANCE.DQ_FAILED_RECORD`
  - `GOVERNANCE.DQ_ALERT`
  - `GOVERNANCE.STEWARD_ASSIGNMENT`
- Rules:
  - `DQ001`: Patient ID cannot be null
  - `DQ002`: DOB cannot be future dated
  - `DQ003`: Age must be between 0 and 120
  - `DQ004`: Discharge date must be greater than or equal to admission date
  - `DQ005`: Length of stay must be greater than or equal to 0
  - `DQ006`: Lab result value cannot be null
  - `DQ007`: Blood glucose normalized result must be between 40 and 600
  - `DQ008`: Provider ID cannot be null
  - `DQ009`: License expiry date required
  - `DQ010`: License must not be expired (HIGH severity)
  - `DQ011`: Appointment ID required
  - `DQ012`: Appointment status validation (enumeration check)
  - `DQ013`: Actual start time must be after scheduled time
  - `DQ014`: Wait time less than 240 minutes
- SQL procedure or repeatable script to:
  - Start a DQ run
  - Execute each rule
  - Store pass/fail counts
  - Capture failed record identifiers and failure details
  - Create alerts for failed rules
  - Assign steward ownership

### Acceptance Criteria

- All injected errors are detected.
- Failed records are captured with rule ID, source object, key fields, and failure reason.
- DQ score is calculated as passed checks divided by total checks.
- Alerts and steward assignments are visible through governance views.

## Phase 7: Lineage and Impact Analysis

### Objective

Demonstrate traceability from executive KPI back to source and simulate impact analysis for a source schema change.

### Deliverables

- Lineage-friendly object creation using views and `CREATE TABLE AS SELECT` patterns.
- Demo lineage path:
  - Executive dashboard
  - Readmission KPI
  - `GOLD.FACT_READMISSION`
  - `SILVER.SLV_ENCOUNTER`
  - `BRONZE.BRZ_PATIENT_ENCOUNTER`
  - EHR source
- Additional lineage paths:
  - Provider Utilization KPI → `FACT_PROVIDER_MONTHLY` → `FACT_PROVIDER_DAILY` → `FACT_APPOINTMENT` → `SLV_APPOINTMENT` → `BRZ_APPOINTMENT` → Scheduling System
  - Appointment No-Show Rate → `FACT_APPOINTMENT` → `SLV_APPOINTMENT` → `BRZ_APPOINTMENT` → Scheduling System
- Column-level lineage documentation for:
  - `readmission_flag` (derived from admission_date, discharge_date, patient_id)
  - `wait_time_minutes` (derived from scheduled_time, actual_start_time)
  - `license_status` (derived from license_expiry_date, CURRENT_DATE)
- Impact analysis scenarios:
  - Scenario 1: Rename `admission_date` to `admit_dt` → impacts SLV_ENCOUNTER, FACT_ENCOUNTER, FACT_READMISSION, Readmission Dashboard, Executive KPI Dashboard
  - Scenario 2: Rename `appointment_status` to `appointment_state` → impacts SLV_APPOINTMENT, FACT_APPOINTMENT, FACT_PROVIDER_DAILY, Appointment Dashboard, Executive Operations Dashboard
  - Scenario 3: Change `license_expiry_date` datatype → impacts SLV_PROVIDER, DIM_PROVIDER, Credential Compliance KPI, Provider Governance Dashboard

### Acceptance Criteria

- Snowflake/Snowsight lineage can show upstream and downstream relationships for key objects.
- Impact analysis report lists the expected dependent assets.
- Demo documentation explains how to navigate lineage in Snowsight.

## Phase 8: Streamlit Governance Dashboard

### Objective

Build a small Streamlit dashboard for presenting the demo outcomes.

### Deliverables

- Streamlit app under `streamlit/`.
- Dashboard pages or tabs:
  - Governance overview
  - Classification coverage
  - Data quality scorecard
  - Failed records and alerts
  - Patient 360 sample view
  - Readmission analytics
  - Provider governance dashboard
  - Appointment operations dashboard
  - Lineage and impact analysis
- Provider governance dashboard displays:
  - Total providers, active providers, expired licenses
  - Credential compliance percentage
  - Provider data quality score
  - Charts for providers by specialty, utilization trend, license expiry trend
- Appointment operations dashboard displays:
  - Total appointments, completion rate, no-show rate, cancellation rate
  - Average wait time
  - Charts for appointment status distribution, wait time trend, utilization trend
- Snowflake connection configuration documentation.
- Read-only dashboard queries against `ANALYTICS` and `GOVERNANCE` views.

### Acceptance Criteria

- Dashboard connects to Snowflake sandbox.
- Dashboard shows classification coverage, DQ score, lineage completeness, and policy compliance.
- Dashboard supports role-aware masking demonstration through Snowflake role/session behavior or separate physician/analyst demo queries.
- Dashboard does not duplicate transformation logic already implemented in Snowflake SQL.

## Phase 9: Demo Runbook and Final Validation

### Objective

Create a clear script for running the demo phase by phase.

### Deliverables

- `README.md` with setup instructions.
- `docs/demo_script.md` with presenter flow:
  - Ingest Bronze data (patient, encounter, lab, pharmacy, claims, appointment, provider)
  - Run classification and masking
  - Promote to Silver
  - Execute DQ audits including new appointment and provider rules
  - Build Gold KPIs including provider utilization and appointment analytics
  - Open Streamlit dashboard
  - Demo Scenario 1: PHI Classification
  - Demo Scenario 2: Data Quality Failure (including appointment and provider failures)
  - Demo Scenario 3: Readmission KPI Lineage
  - Demo Scenario 4: Impact Analysis (admission_date rename)
  - Demo Scenario 5: Audit Investigation
  - Demo Scenario 6: Provider Credential Compliance
  - Demo Scenario 7: Appointment No-Show Analytics
  - Demo Scenario 8: Provider Utilization Analysis
  - Show lineage and run impact analysis
- Validation checklist.
- Troubleshooting notes.

### Acceptance Criteria

- A presenter can execute the demo from a fresh sandbox.
- Each phase has clear start and end validation queries.
- Known Snowflake prerequisites and privileges are documented.

## Implementation Order

1. Phase 1: Sandbox foundation
2. Phase 2: Data and Bronze
3. Phase 3: Silver
4. Phase 4: Gold
5. Phase 6: SQL audit DQ framework
6. Phase 5: Classification and masking
7. Phase 7: Lineage and impact
8. Phase 8: Streamlit dashboard
9. Phase 9: Runbook and validation

Data quality is intentionally implemented before the dashboard so the Streamlit app can remain a thin presentation layer over governed Snowflake objects.

## Assumptions

- The demo will run in a Snowflake sandbox where creating a database, schemas, roles, and warehouse is acceptable.
- Native Snowflake Data Quality Monitoring DMFs are not required for the first implementation.
- Snowflake Enterprise-only governance features may be used where available, but SQL audit tables provide the deterministic fallback for the demo.
- Streamlit will be a lightweight dashboard and not the system of record for governance logic.
- All patient data will be synthetic.
