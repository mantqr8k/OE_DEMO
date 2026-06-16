-- Phase 5 Validation: Classification Tags and Dynamic Masking
-- Validate that governance tags are assigned and masking policies are in place

USE ROLE OVALEDGE_ROLE;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;

-- ============================================================================
-- Validation 1: Verify Governance Tags Created
-- ============================================================================

SHOW TAGS IN SCHEMA GOVERNANCE.TAGS;

-- Expected output: 6 tags (PHI, PII, SENSITIVE, RESTRICTED, CONFIDENTIAL, PUBLIC)

-- ============================================================================
-- Validation 2: Verify Tag Assignments
-- ============================================================================

SELECT
  tag_name,
  COUNT(DISTINCT object_id) AS num_objects,
  COUNT(DISTINCT object_name) AS num_columns
FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
WHERE tag_database = 'HC_GOV_DEMO'
  AND tag_schema = 'TAGS'
GROUP BY tag_name
ORDER BY tag_name;

-- Expected output: 
--   PHI: ~7 column references
--   PII: ~2 column references
--   SENSITIVE: ~2 column references
--   RESTRICTED: ~1 column reference

-- ============================================================================
-- Validation 3: Verify Masking Policies Created
-- ============================================================================

SELECT
  policy_name,
  policy_signature,
  creation_date
FROM SNOWFLAKE.INFORMATION_SCHEMA.MASKING_POLICIES
WHERE policy_schema = 'POLICIES'
ORDER BY policy_name;

-- Expected output: 7 masking policies
--   MASK_PATIENT_NAME
--   MASK_DATE
--   MASK_MRN
--   MASK_SSN
--   MASK_INSURANCE_ID
--   MASK_DIAGNOSIS

-- ============================================================================
-- Validation 4: Verify Masking Policies Applied to Columns
-- ============================================================================

SELECT
  table_schema,
  table_name,
  column_name,
  policy_name,
  policy_schema
FROM SNOWFLAKE.INFORMATION_SCHEMA.COLUMN_MASKING_POLICIES
WHERE table_schema IN ('BRONZE', 'SILVER', 'GOLD')
ORDER BY table_schema, table_name, column_name;

-- Expected output: Masking policies applied to sensitive columns in BRONZE and SILVER

-- ============================================================================
-- Validation 5: Test Masking as Different Roles (SYSADMIN - Unmasked)
-- ============================================================================

-- Physician role equivalent (inherits from OVALEDGE_ROLE - sees unmasked data)
USE ROLE OVALEDGE_ROLE;
SELECT
  patient_name,
  dob,
  medical_record_number
FROM SILVER.SLV_PATIENT
LIMIT 5;

-- Expected output: Unmasked patient names, dates, and MRNs

-- ============================================================================
-- Validation 6: Verify Governance Views Created
-- ============================================================================

SHOW VIEWS IN SCHEMA GOVERNANCE.GOVERNANCE LIKE 'VW_%';

-- Expected output: At least 3 views
--   VW_PATIENT_PHYSICIAN_VIEW
--   VW_PATIENT_ANALYST_VIEW
--   VW_TAG_COVERAGE
--   VW_CLASSIFICATION_SUMMARY

-- ============================================================================
-- Validation 7: Display Classification Summary
-- ============================================================================

SELECT * FROM GOVERNANCE.VW_CLASSIFICATION_SUMMARY;

-- ============================================================================
-- Validation 8: Display Tag Coverage for Sample Tables
-- ============================================================================

SELECT
  table_schema,
  table_name,
  column_name,
  applied_tags
FROM GOVERNANCE.VW_TAG_COVERAGE
WHERE table_schema IN ('BRONZE', 'SILVER')
  AND table_name IN ('BRZ_PATIENT_MASTER', 'SLV_PATIENT')
ORDER BY table_schema, table_name, column_name;

-- ============================================================================
-- Phase 5 Acceptance Criteria Checklist
-- ============================================================================

-- [ ] Governance tags are created in GOVERNANCE.TAGS schema
-- [ ] PHI, PII, SENSITIVE, RESTRICTED tags are assigned to appropriate columns
-- [ ] Masking policies are created in GOVERNANCE.POLICIES schema
-- [ ] Masking policies are applied to BRONZE and SILVER columns
-- [ ] OVALEDGE_ROLE sees unmasked clinical PHI
-- [ ] Analyst role masked view exists (masking applied via policy)
-- [ ] Tag coverage can be queried from governance views
-- [ ] Classification summary shows coverage by tag type
