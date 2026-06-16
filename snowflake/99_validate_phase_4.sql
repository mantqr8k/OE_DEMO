-- Phase 4 validation queries.
-- Confirms Gold dimensional/fact models and Analytics KPI views.

USE ROLE SYSADMIN;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;

SHOW DYNAMIC TABLES IN SCHEMA GOLD;

SELECT object_name, row_count
FROM GOLD.VW_GOLD_ROW_COUNTS
ORDER BY object_name;

SELECT
  hospital_id,
  hospital_name,
  hospital_region
FROM GOLD.DIM_HOSPITAL
ORDER BY hospital_id;

SELECT
  diagnosis_code,
  diagnosis_description
FROM GOLD.DIM_DIAGNOSIS
ORDER BY diagnosis_code;

SELECT
  patient_sk,
  encounter_sk,
  discharge_date,
  next_admission_date,
  days_between_visits,
  readmission_flag
FROM GOLD.FACT_READMISSION
ORDER BY patient_sk, discharge_date;

SELECT *
FROM ANALYTICS.VW_READMISSION_RATE;

SELECT *
FROM ANALYTICS.VW_AVERAGE_LENGTH_OF_STAY;

SELECT *
FROM ANALYTICS.VW_CLAIM_APPROVAL_RATE;

SELECT *
FROM ANALYTICS.VW_EXECUTIVE_KPI_SUMMARY
ORDER BY kpi_name;

