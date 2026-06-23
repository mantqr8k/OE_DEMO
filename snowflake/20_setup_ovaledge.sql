-- Setup script for OVALEDGE user, governance tags, masking policies, and tag assignments
-- Co-authored with CoCo
-- =============================================================================
-- Create user OVALEDGE and grant HC_ANALYST_ROLE for SELECT access
-- to HC_GOV_DEMO database
-- =============================================================================

USE ROLE SECURITYADMIN;
-- Step 1: Create the user
CREATE USER IF NOT EXISTS OVALEDGE
    PASSWORD = 'xx'
    DEFAULT_ROLE = 'OVALEDGE_ROLE'
    MUST_CHANGE_PASSWORD = FALSE;

-- Step 2: Create a dedicated role for OVALEDGE
CREATE ROLE IF NOT EXISTS OVALEDGE_ROLE;

-- Step 3: Grant the role to the user
GRANT ROLE OVALEDGE_ROLE TO USER OVALEDGE;

-- Step 4: Grant HC_ANALYST_ROLE to OVALEDGE_ROLE (inherits all SELECT privileges)
GRANT ROLE HC_ANALYST_ROLE TO ROLE OVALEDGE_ROLE;

-- Step 5: Create GOVERNANCE_WH warehouse using SYSADMIN
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS GOVERNANCE_WH;

-- Step 6: Grant USAGE on GOVERNANCE_WH to OVALEDGE_ROLE
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON WAREHOUSE GOVERNANCE_WH TO ROLE OVALEDGE_ROLE;

-- Step 7: Create GOVERNANCE database with TAGS and POLICIES schemas
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS GOVERNANCE;
CREATE SCHEMA IF NOT EXISTS GOVERNANCE.TAGS;
CREATE SCHEMA IF NOT EXISTS GOVERNANCE.POLICIES;

-- Step 8: Create TAG_ADMIN and MASKING_ADMIN roles using SECURITYADMIN
USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS TAG_ADMIN;
CREATE ROLE IF NOT EXISTS MASKING_ADMIN;

-- Step 9: Grant privileges to TAG_ADMIN and MASKING_ADMIN
GRANT USAGE ON DATABASE GOVERNANCE TO ROLE TAG_ADMIN;
GRANT USAGE ON SCHEMA GOVERNANCE.TAGS TO ROLE TAG_ADMIN;
GRANT CREATE TAG ON SCHEMA GOVERNANCE.TAGS TO ROLE TAG_ADMIN;
GRANT APPLY TAG ON ACCOUNT TO ROLE TAG_ADMIN;

GRANT USAGE ON DATABASE GOVERNANCE TO ROLE MASKING_ADMIN;
GRANT USAGE ON SCHEMA GOVERNANCE.POLICIES TO ROLE MASKING_ADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA GOVERNANCE.POLICIES TO ROLE MASKING_ADMIN;
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE MASKING_ADMIN;

-- Step 10: Assign TAG_ADMIN and MASKING_ADMIN to OVALEDGE_ROLE
GRANT ROLE TAG_ADMIN TO ROLE OVALEDGE_ROLE;
GRANT ROLE MASKING_ADMIN TO ROLE OVALEDGE_ROLE;


-- Phase 5: Classification Tags and Dynamic Masking
-- Demonstrates sensitive data identification and role-based protection.
-- Run after Phase 4.

USE ROLE OVALEDGE_ROLE;
USE WAREHOUSE GOVERNANCE_WH;
USE DATABASE HC_GOV_DEMO;

-- ============================================================================
-- SECTION 1: Create Governance Tags
-- ============================================================================

-- ---- Direct Identifiers (PII) ----

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_EMAIL
  ALLOWED_VALUES 'EMAIL_IDENTIFIER'
  COMMENT = 'Email addresses used for patient or provider contact'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_IP_ADDRESS
  COMMENT = 'IP addresses from system logs or web access sessions'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_NAME
  COMMENT = 'Personal names (first, last, or full) that directly identify an individual'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_PHONE_NUMBER
  COMMENT = 'Telephone numbers for patient or provider contact'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_URL
  COMMENT = 'URLs that may link to personal profiles, portals, or health records'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_US_BANK_ACCOUNT
  COMMENT = 'US bank account or routing numbers tied to financial identity'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_US_DRIVER_LICENSE
  COMMENT = 'US state-issued driver license numbers used as government ID'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_US_SSN
  COMMENT = 'US Social Security Numbers - highest sensitivity direct identifier'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII_US_STREET_ADDRESS
  COMMENT = 'Physical street addresses that pinpoint an individual residence or workplace'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- ---- Quasi-Identifiers ----

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_IDENTIFIER
  COMMENT = 'Parent category for columns that enable re-identification when combined'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_AGE
  COMMENT = 'Age values that narrow identity when combined with location or gender'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_COUNTY
  COMMENT = 'County-level geography - coarser than city but still a re-identification risk'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_DATE_OF_BIRTH
  COMMENT = 'Exact date of birth - strong quasi-identifier per HIPAA Safe Harbor'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_GENDER
  COMMENT = 'Gender or sex classification - contributes to re-identification in small populations'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_LATITUDE
  COMMENT = 'Latitude coordinate component of precise geolocation'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_LAT_LONG
  COMMENT = 'Combined latitude/longitude pair providing precise geolocation'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_LONGITUDE
  COMMENT = 'Longitude coordinate component of precise geolocation'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_OCCUPATION
  COMMENT = 'Occupation or job title - rare occupations may uniquely narrow identity'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_US_CITY
  COMMENT = 'US city name providing mid-level geographic granularity'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_US_COUNTY
  COMMENT = 'US county name - alternative geographic representation at county level'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_US_POSTAL_CODE
  COMMENT = 'ZIP/postal codes - small ZIP areas can be highly identifying per HIPAA'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_US_STATE_OR_TERRITORY
  COMMENT = 'US state or territory - broadest geographic quasi-identifier'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.QUASI_PII_YEAR_OF_BIRTH
  COMMENT = 'Year of birth - less precise than full DOB but still a quasi-identifier'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- ---- Sensitive Data ----

CREATE OR REPLACE TAG GOVERNANCE.TAGS.SENSITIVE
  COMMENT = 'Parent category for sensitive non-PII data requiring access controls'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.SENSITIVE_CREDIT_CARD_NUMBER
  COMMENT = 'Credit/payment card numbers subject to PCI-DSS compliance'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.SENSITIVE_INCOME
  COMMENT = 'Income or salary data protected under financial privacy regulations'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.SENSITIVE_USER_ID
  COMMENT = 'Internal user or system identifiers not intended for public exposure'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

CREATE OR REPLACE TAG GOVERNANCE.TAGS.SECURE_OBJECT
  COMMENT = 'Composite classification spanning IDENTIFIER, QUASI_IDENTIFIER, and SENSITIVE categories'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- ============================================================================
-- SECTION 2: Assign Tags to Bronze Layer Columns
-- ============================================================================

-- BRZ_PATIENT_MASTER - PHI columns
ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN patient_first_name SET TAG GOVERNANCE.TAGS.PHI = 'Patient Identifier';

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN patient_last_name SET TAG GOVERNANCE.TAGS.PHI = 'Patient Identifier';

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN dob SET TAG GOVERNANCE.TAGS.PHI = 'Demographic';

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN medical_record_number SET TAG GOVERNANCE.TAGS.PHI = 'Medical Record Identifier';

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN phone_number SET TAG GOVERNANCE.TAGS.PII = 'Contact Information';

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN email_address SET TAG GOVERNANCE.TAGS.PII = 'Contact Information';

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN address_line1 SET TAG GOVERNANCE.TAGS.PHI = 'Location';

-- BRZ_PATIENT_MASTER - RESTRICTED columns
ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN ssn SET TAG GOVERNANCE.TAGS.RESTRICTED = 'Social Security Number';

-- BRZ_PATIENT_ENCOUNTER - SENSITIVE columns
ALTER TABLE BRONZE.BRZ_PATIENT_ENCOUNTER
  MODIFY COLUMN diagnosis_code SET TAG GOVERNANCE.TAGS.SENSITIVE = 'Clinical';

-- BRZ_CLAIMS - SENSITIVE columns
ALTER TABLE BRONZE.BRZ_CLAIMS
  MODIFY COLUMN insurance_id SET TAG GOVERNANCE.TAGS.SENSITIVE = 'Insurance Identifier';

-- ============================================================================
-- SECTION 3: Assign Tags to Silver Layer Columns
-- ============================================================================

-- SLV_PATIENT
ALTER TABLE SILVER.SLV_PATIENT
  MODIFY COLUMN patient_name SET TAG GOVERNANCE.TAGS.PHI = 'Patient Identifier';

ALTER TABLE SILVER.SLV_PATIENT
  MODIFY COLUMN dob SET TAG GOVERNANCE.TAGS.PHI = 'Demographic';

-- SLV_ENCOUNTER
ALTER TABLE SILVER.SLV_ENCOUNTER
  MODIFY COLUMN diagnosis_code SET TAG GOVERNANCE.TAGS.SENSITIVE = 'Clinical';

-- SLV_CLAIM
ALTER TABLE SILVER.SLV_CLAIM
  MODIFY COLUMN insurance_id SET TAG GOVERNANCE.TAGS.SENSITIVE = 'Insurance Identifier';

-- ============================================================================
-- SECTION 4: Create Masking Policies
-- ============================================================================

-- Masking policy for patient names
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_NAME AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'HC_PHYSICIAN_ROLE' THEN val
    WHEN CURRENT_ROLE() = 'HC_ANALYST_ROLE' THEN CONCAT(SUBSTRING(val, 1, 1), '*** ', SUBSTRING(val, -4))
    WHEN CURRENT_ROLE() = 'HC_DEMO_ADMIN' THEN val
    ELSE '***MASKED***'
  END;

-- Masking policy for dates (DOB, admission date, etc.)
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_DATE AS (val DATE) RETURNS DATE ->
  CASE
    WHEN CURRENT_ROLE() = 'HC_PHYSICIAN_ROLE' THEN val
    WHEN CURRENT_ROLE() = 'HC_ANALYST_ROLE' THEN NULL
    WHEN CURRENT_ROLE() = 'HC_DEMO_ADMIN' THEN val
    ELSE NULL
  END;

-- Masking policy for medical record numbers
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_MRN AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'HC_PHYSICIAN_ROLE' THEN val
    WHEN CURRENT_ROLE() = 'HC_ANALYST_ROLE' THEN CONCAT('****', SUBSTRING(val, -2))
    WHEN CURRENT_ROLE() = 'HC_DEMO_ADMIN' THEN val
    ELSE '***MASKED***'
  END;

-- Masking policy for SSN
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_SSN AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'HC_PHYSICIAN_ROLE' THEN val
    WHEN CURRENT_ROLE() = 'HC_ANALYST_ROLE' THEN 'XXX-XX-****'
    WHEN CURRENT_ROLE() = 'HC_DEMO_ADMIN' THEN val
    ELSE 'XXX-XX-****'
  END;

-- Masking policy for insurance IDs
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_INSURANCE_ID AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'HC_PHYSICIAN_ROLE' THEN val
    WHEN CURRENT_ROLE() = 'HC_ANALYST_ROLE' THEN CONCAT('****', SUBSTRING(val, -4))
    WHEN CURRENT_ROLE() = 'HC_DEMO_ADMIN' THEN val
    ELSE '***MASKED***'
  END;

-- Masking policy for diagnosis codes
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_DIAGNOSIS AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'HC_PHYSICIAN_ROLE' THEN val
    WHEN CURRENT_ROLE() = 'HC_ANALYST_ROLE' THEN NULL
    WHEN CURRENT_ROLE() = 'HC_DEMO_ADMIN' THEN val
    ELSE NULL
  END;

-- ============================================================================
-- SECTION 5: Apply Masking Policies to tags
-- ============================================================================

ALTER TAG GOVERNANCE.TAGS.PII_NAME SET MASKING POLICY GOVERNANCE.POLICIES.MASK_NAME;
ALTER TAG GOVERNANCE.TAGS.PII_US_SSN SET MASKING POLICY GOVERNANCE.POLICIES.MASK_SSN;



-- ============================================================================
-- SECTION 7: Create Governance Views for Demo Queries
-- ============================================================================

-- View to show physician role data (unmasked clinical PHI)
CREATE OR REPLACE VIEW GOVERNANCE.VW_PATIENT_PHYSICIAN_VIEW AS
SELECT
  patient_sk,
  patient_id,
  medical_record_number,
  patient_name,
  dob,
  age,
  gender,
  city,
  state,
  active_flag,
  source_ingestion_timestamp
FROM SILVER.SLV_PATIENT;

-- View to show analyst role data (masked PHI)
CREATE OR REPLACE VIEW GOVERNANCE.VW_PATIENT_ANALYST_VIEW AS
SELECT
  patient_sk,
  patient_id,
  medical_record_number,
  patient_name,
  dob,
  age,
  gender,
  city,
  state,
  active_flag,
  source_ingestion_timestamp
FROM SILVER.SLV_PATIENT;

-- Tag coverage metadata view
CREATE OR REPLACE VIEW GOVERNANCE.VW_TAG_COVERAGE AS
SELECT
  table_catalog,
  table_schema,
  table_name,
  column_name,
  data_type,
  LISTAGG(DISTINCT tag_name, ', ') WITHIN GROUP (ORDER BY tag_name) AS applied_tags
FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
WHERE tag_database = 'HC_GOV_DEMO'
  AND tag_schema = 'TAGS'
GROUP BY table_catalog, table_schema, table_name, column_name, data_type
ORDER BY table_schema, table_name, column_name;

-- Summary of tagged columns
CREATE OR REPLACE VIEW GOVERNANCE.VW_CLASSIFICATION_SUMMARY AS
SELECT
  tag_name,
  COUNT(DISTINCT object_id) AS num_objects,
  COUNT(DISTINCT object_name) AS num_unique_objects,
  LISTAGG(DISTINCT object_name, ', ') WITHIN GROUP (ORDER BY object_name) AS object_names
FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
WHERE tag_database = 'HC_GOV_DEMO'
  AND tag_schema = 'TAGS'
GROUP BY tag_name
ORDER BY tag_name;

-- ============================================================================
-- SECTION 8: Demo Query Scripts
-- ============================================================================

-- Query to demonstrate unmasked data access (run as SYSADMIN)
-- Note: Physician role inherits SYSADMIN privileges in this demo
-- SELECT 
--   patient_name, 
--   dob, 
--   medical_record_number,
--   ssn
-- FROM SILVER.SLV_PATIENT
-- LIMIT 10;

-- Query to demonstrate masked data access (would run as HC_ANALYST_ROLE)
-- SELECT 
--   patient_name, 
--   dob, 
--   medical_record_number,
--   ssn
-- FROM SILVER.SLV_PATIENT
-- LIMIT 10;