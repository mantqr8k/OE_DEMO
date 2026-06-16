-- Phase 5: Classification Tags and Dynamic Masking
-- Demonstrates sensitive data identification and role-based protection.
-- Run after Phase 4.

USE ROLE OVALEDGE_ROLE;
USE WAREHOUSE GOVERNANCE_WH;
USE DATABASE HC_GOV_DEMO;

-- ============================================================================
-- SECTION 1: Create Governance Tags
-- ============================================================================

-- Create tag for PHI (Protected Health Information)
CREATE OR REPLACE TAG GOVERNANCE.TAGS.PHI
  COMMENT = 'Protected Health Information - Subject to HIPAA regulations'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- Create tag for PII (Personally Identifiable Information)
CREATE OR REPLACE TAG GOVERNANCE.TAGS.PII
  COMMENT = 'Personally Identifiable Information - Requires privacy controls'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- Create tag for Sensitive data
CREATE OR REPLACE TAG GOVERNANCE.TAGS.SENSITIVE
  COMMENT = 'Sensitive business data - Restricted access required'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- Create tag for Restricted data
CREATE OR REPLACE TAG GOVERNANCE.TAGS.RESTRICTED
  COMMENT = 'Restricted data - Highest sensitivity level'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- Create tag for Confidential data
CREATE OR REPLACE TAG GOVERNANCE.TAGS.CONFIDENTIAL
  COMMENT = 'Confidential data - Limited disclosure'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;

-- Create tag for Public data
CREATE OR REPLACE TAG GOVERNANCE.TAGS.PUBLIC
  COMMENT = 'Public data - No sensitivity restrictions'
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
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_PATIENT_NAME AS (val VARCHAR) RETURNS VARCHAR ->
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
-- SECTION 5: Apply Masking Policies to Bronze Layer
-- ============================================================================

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN patient_first_name SET MASKING POLICY GOVERNANCE.POLICIES.MASK_PATIENT_NAME;

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN patient_last_name SET MASKING POLICY GOVERNANCE.POLICIES.MASK_PATIENT_NAME;

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN dob SET MASKING POLICY GOVERNANCE.POLICIES.MASK_DATE;

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN medical_record_number SET MASKING POLICY GOVERNANCE.POLICIES.MASK_MRN;

ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN ssn SET MASKING POLICY GOVERNANCE.POLICIES.MASK_SSN;

ALTER TABLE BRONZE.BRZ_PATIENT_ENCOUNTER
  MODIFY COLUMN diagnosis_code SET MASKING POLICY GOVERNANCE.POLICIES.MASK_DIAGNOSIS;

ALTER TABLE BRONZE.BRZ_CLAIMS
  MODIFY COLUMN insurance_id SET MASKING POLICY GOVERNANCE.POLICIES.MASK_INSURANCE_ID;

-- ============================================================================
-- SECTION 6: Apply Masking Policies to Silver Layer
-- ============================================================================

ALTER TABLE SILVER.SLV_PATIENT
  MODIFY COLUMN patient_name SET MASKING POLICY GOVERNANCE.POLICIES.MASK_PATIENT_NAME;

ALTER TABLE SILVER.SLV_PATIENT
  MODIFY COLUMN dob SET MASKING POLICY GOVERNANCE.POLICIES.MASK_DATE;

ALTER TABLE SILVER.SLV_ENCOUNTER
  MODIFY COLUMN diagnosis_code SET MASKING POLICY GOVERNANCE.POLICIES.MASK_DIAGNOSIS;

ALTER TABLE SILVER.SLV_CLAIM
  MODIFY COLUMN insurance_id SET MASKING POLICY GOVERNANCE.POLICIES.MASK_INSURANCE_ID;

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
