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

SELECT
  appointment_sk,
  appointment_id,
  patient_sk,
  provider_sk,
  hospital_sk,
  appointment_date,
  appointment_status,
  wait_time_minutes,
  cancellation_flag,
  no_show_flag
FROM GOLD.FACT_APPOINTMENT
ORDER BY appointment_date, appointment_id;

SELECT
  provider_sk,
  activity_date,
  appointments_booked,
  appointments_completed,
  patients_seen,
  no_show_count,
  cancellation_count,
  utilization_rate
FROM GOLD.FACT_PROVIDER_DAILY
ORDER BY provider_sk, activity_date;

SELECT *
FROM GOLD.FACT_PROVIDER_MONTHLY
ORDER BY provider_sk, reporting_month;

SELECT *
FROM ANALYTICS.VW_READMISSION_RATE;

SELECT *
FROM ANALYTICS.VW_AVERAGE_LENGTH_OF_STAY;

SELECT *
FROM ANALYTICS.VW_CLAIM_APPROVAL_RATE;

SELECT *
FROM ANALYTICS.VW_EXECUTIVE_KPI_SUMMARY
ORDER BY kpi_name;

