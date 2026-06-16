-- Phase 3 validation queries.
-- Confirms Silver dynamic tables, standardized values, and preservation of invalid records for DQ audits.

USE ROLE SYSADMIN;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;

SHOW DYNAMIC TABLES IN SCHEMA SILVER;

SELECT object_name, row_count
FROM SILVER.VW_SILVER_ROW_COUNTS
ORDER BY object_name;

SELECT
  patient_id,
  medical_record_number,
  patient_name,
  dob,
  age,
  gender,
  city,
  state,
  active_flag
FROM SILVER.SLV_PATIENT
ORDER BY patient_id NULLS LAST, medical_record_number;

SELECT
  encounter_id,
  patient_id,
  admission_date,
  discharge_date,
  length_of_stay,
  encounter_type,
  hospital_id,
  diagnosis_code
FROM SILVER.SLV_ENCOUNTER
ORDER BY encounter_id;

SELECT 'DEDUPED_PATIENT_P1001' AS check_name, COUNT(*) AS observed_count
FROM SILVER.SLV_PATIENT
WHERE patient_id = 'P1001'
UNION ALL
SELECT 'NULL_PATIENT_ID_PRESERVED', COUNT(*)
FROM SILVER.SLV_PATIENT
WHERE patient_id IS NULL
UNION ALL
SELECT 'FUTURE_DOB_PRESERVED', COUNT(*)
FROM SILVER.SLV_PATIENT
WHERE dob > CURRENT_DATE()
UNION ALL
SELECT 'NEGATIVE_LOS_PRESERVED', COUNT(*)
FROM SILVER.SLV_ENCOUNTER
WHERE length_of_stay < 0
UNION ALL
SELECT 'OUT_OF_RANGE_GLUCOSE_PRESERVED', COUNT(*)
FROM SILVER.SLV_LAB_RESULT
WHERE test_code = 'GLU'
  AND normalized_result NOT BETWEEN 40 AND 600
UNION ALL
SELECT 'NULL_LAB_RESULT_PRESERVED', COUNT(*)
FROM SILVER.SLV_LAB_RESULT
WHERE normalized_result IS NULL
ORDER BY check_name;

