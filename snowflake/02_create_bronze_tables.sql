-- Phase 2: Bronze table and stage setup.
-- Run after Phase 1.
-- Recommended execution role: SYSADMIN.

USE ROLE SYSADMIN;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;
USE SCHEMA BRONZE;

CREATE OR REPLACE FILE FORMAT BRONZE_CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  TRIM_SPACE = TRUE
  DATE_FORMAT = 'YYYY-MM-DD'
  TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

CREATE OR REPLACE STAGE RAW_DATA_STAGE
  FILE_FORMAT = BRONZE_CSV_FORMAT
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Internal stage for Phase 2 synthetic healthcare CSV files.';

CREATE OR REPLACE TABLE BRZ_PATIENT_MASTER (
  patient_id VARCHAR,
  medical_record_number VARCHAR,
  patient_first_name VARCHAR,
  patient_last_name VARCHAR,
  dob DATE,
  gender VARCHAR,
  ssn VARCHAR,
  phone_number VARCHAR,
  email_address VARCHAR,
  address_line1 VARCHAR,
  city VARCHAR,
  state VARCHAR,
  zip_code VARCHAR,
  ingestion_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE BRZ_PATIENT_ENCOUNTER (
  encounter_id VARCHAR,
  patient_id VARCHAR,
  admission_date DATE,
  discharge_date DATE,
  encounter_type VARCHAR,
  attending_physician VARCHAR,
  hospital_id VARCHAR,
  diagnosis_code VARCHAR,
  ingestion_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE BRZ_LAB_RESULTS (
  lab_result_id VARCHAR,
  patient_id VARCHAR,
  encounter_id VARCHAR,
  test_code VARCHAR,
  test_name VARCHAR,
  result_value NUMBER(18, 4),
  result_unit VARCHAR,
  result_date DATE,
  ingestion_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE BRZ_PHARMACY_ORDERS (
  prescription_id VARCHAR,
  patient_id VARCHAR,
  medication_name VARCHAR,
  dosage VARCHAR,
  prescription_date DATE,
  prescribing_physician VARCHAR,
  ingestion_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE BRZ_CLAIMS (
  claim_id VARCHAR,
  patient_id VARCHAR,
  insurance_id VARCHAR,
  claim_amount NUMBER(18, 2),
  claim_status VARCHAR,
  claim_date DATE,
  ingestion_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE BRZ_APPOINTMENT (
  appointment_id VARCHAR,
  patient_id VARCHAR,
  provider_id VARCHAR,
  hospital_id VARCHAR,
  appointment_date DATE,
  appointment_status VARCHAR,
  scheduled_time VARCHAR,
  actual_start_time VARCHAR,
  wait_time_minutes NUMBER(10, 0),
  cancellation_flag NUMBER(1, 0),
  no_show_flag NUMBER(1, 0),
  ingestion_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE BRZ_PROVIDER_MASTER (
  provider_id VARCHAR,
  provider_name VARCHAR,
  specialty VARCHAR,
  hospital_id VARCHAR,
  license_number VARCHAR,
  license_expiry_date DATE,
  ingestion_timestamp TIMESTAMP_NTZ
);
