-- Phase 3: Silver standardization layer.
-- Uses regular tables and load procedures to materialize standardized models from Bronze data.
-- Run after Phase 2.

USE ROLE SYSADMIN;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;
USE SCHEMA SILVER;

DROP DYNAMIC TABLE IF EXISTS SLV_PATIENT;
DROP TABLE IF EXISTS SLV_PATIENT;
CREATE OR REPLACE TABLE SLV_PATIENT (
  patient_sk VARCHAR(64) COMMENT 'Surrogate key hashed from patient_id or medical_record_number',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier from Bronze patient master',
  medical_record_number VARCHAR(50) COMMENT 'Medical record number from Bronze patient master',
  patient_name VARCHAR(200) COMMENT 'Standardized full patient name',
  dob DATE COMMENT 'Date of birth',
  age NUMBER COMMENT 'Patient age in years as of 2026-06-11',
  gender VARCHAR(20) COMMENT 'Gender normalized to upper-case',
  city VARCHAR(100) COMMENT 'City standardized to initcap',
  state VARCHAR(50) COMMENT 'State normalized to upper-case',
  active_flag BOOLEAN COMMENT 'Active patient flag',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver patient dimension table.';

DROP DYNAMIC TABLE IF EXISTS SLV_ENCOUNTER;
DROP TABLE IF EXISTS SLV_ENCOUNTER;
CREATE OR REPLACE TABLE SLV_ENCOUNTER (
  encounter_sk VARCHAR(64) COMMENT 'Surrogate key hashed from encounter_id',
  encounter_id VARCHAR(50) COMMENT 'Source encounter identifier from Bronze patient encounter',
  patient_sk VARCHAR(64) COMMENT 'Surrogate key for patient from SLV_PATIENT',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier from Bronze patient encounter',
  admission_date DATE COMMENT 'Encounter admission date',
  discharge_date DATE COMMENT 'Encounter discharge date',
  length_of_stay NUMBER COMMENT 'Difference in days between admission and discharge',
  diagnosis_code VARCHAR(50) COMMENT 'Normalized diagnosis code',
  hospital_id VARCHAR(50) COMMENT 'Normalized hospital identifier',
  encounter_type VARCHAR(50) COMMENT 'Standardized encounter category',
  attending_physician VARCHAR(100) COMMENT 'Attending physician name from source',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver encounter fact table.';

DROP DYNAMIC TABLE IF EXISTS SLV_LAB_RESULT;
DROP TABLE IF EXISTS SLV_LAB_RESULT;
CREATE OR REPLACE TABLE SLV_LAB_RESULT (
  lab_result_sk VARCHAR(64) COMMENT 'Surrogate key hashed from lab_result_id',
  encounter_sk VARCHAR(64) COMMENT 'Surrogate key for encounter from SLV_ENCOUNTER',
  patient_sk VARCHAR(64) COMMENT 'Surrogate key for patient from SLV_PATIENT',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier from Bronze lab results',
  encounter_id VARCHAR(50) COMMENT 'Source encounter identifier from Bronze lab results',
  test_code VARCHAR(50) COMMENT 'Normalized test code',
  test_name VARCHAR(200) COMMENT 'Standardized test name',
  normalized_result NUMBER COMMENT 'Lab result value as captured from source',
  result_unit VARCHAR(50) COMMENT 'Lab result unit from source',
  result_date DATE COMMENT 'Date the lab result was recorded',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver lab result fact table.';

DROP DYNAMIC TABLE IF EXISTS SLV_MEDICATION;
DROP TABLE IF EXISTS SLV_MEDICATION;
CREATE OR REPLACE TABLE SLV_MEDICATION (
  medication_sk VARCHAR(64) COMMENT 'Surrogate key hashed from prescription_id',
  patient_sk VARCHAR(64) COMMENT 'Surrogate key for patient from SLV_PATIENT',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier from Bronze pharmacy orders',
  medication_name VARCHAR(200) COMMENT 'Standardized medication name',
  dosage VARCHAR(100) COMMENT 'Medication dosage information from source',
  prescription_date DATE COMMENT 'Date the medication was prescribed',
  prescribing_physician VARCHAR(100) COMMENT 'Physician who prescribed the medication',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver medication fact table.';

DROP DYNAMIC TABLE IF EXISTS SLV_CLAIM;
DROP TABLE IF EXISTS SLV_CLAIM;
CREATE OR REPLACE TABLE SLV_CLAIM (
  claim_sk VARCHAR(64) COMMENT 'Surrogate key hashed from claim_id',
  patient_sk VARCHAR(64) COMMENT 'Surrogate key for patient from SLV_PATIENT',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier from Bronze claims',
  insurance_id VARCHAR(50) COMMENT 'Insurance identifier from source claim',
  claim_amount NUMBER COMMENT 'Monetary amount of the claim',
  claim_status VARCHAR(50) COMMENT 'Normalized claim status',
  claim_date DATE COMMENT 'Date the claim was filed',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver claim fact table.';

CREATE OR REPLACE PROCEDURE LOAD_SLV_PATIENT()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_PATIENT;
  INSERT INTO SILVER.SLV_PATIENT (
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
  )
  WITH ranked_patients AS (
    SELECT
      patient_id,
      medical_record_number,
      patient_first_name,
      patient_last_name,
      dob,
      gender,
      city,
      state,
      ingestion_timestamp,
      ROW_NUMBER() OVER (
        PARTITION BY COALESCE(patient_id, medical_record_number)
        ORDER BY ingestion_timestamp DESC
      ) AS row_rank
    FROM BRONZE.BRZ_PATIENT_MASTER
  )
  SELECT
    SHA2(COALESCE(patient_id, medical_record_number), 256) AS patient_sk,
    patient_id,
    medical_record_number,
    INITCAP(TRIM(CONCAT_WS(' ', patient_first_name, patient_last_name))) AS patient_name,
    dob,
    IFF(
      dob IS NULL,
      NULL,
      DATEDIFF('year', dob, DATE '2026-06-11')
        - IFF(TO_CHAR(DATE '2026-06-11', 'MMDD') < TO_CHAR(dob, 'MMDD'), 1, 0)
    ) AS age,
    UPPER(TRIM(gender)) AS gender,
    INITCAP(TRIM(city)) AS city,
    UPPER(TRIM(state)) AS state,
    TRUE AS active_flag,
    ingestion_timestamp AS source_ingestion_timestamp
  FROM ranked_patients
  WHERE row_rank = 1;
  RETURN 'SLV_PATIENT loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_SLV_ENCOUNTER()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_ENCOUNTER;
  INSERT INTO SILVER.SLV_ENCOUNTER (
    encounter_sk,
    encounter_id,
    patient_sk,
    patient_id,
    admission_date,
    discharge_date,
    length_of_stay,
    diagnosis_code,
    hospital_id,
    encounter_type,
    attending_physician,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(encounter_id, 256) AS encounter_sk,
    encounter_id,
    p.patient_sk,
    e.patient_id,
    admission_date,
    discharge_date,
    DATEDIFF('day', admission_date, discharge_date) AS length_of_stay,
    UPPER(TRIM(diagnosis_code)) AS diagnosis_code,
    UPPER(TRIM(hospital_id)) AS hospital_id,
    CASE
      WHEN UPPER(TRIM(encounter_type)) IN ('INPATIENT', 'EMERGENCY', 'OUTPATIENT', 'OBSERVATION')
        THEN INITCAP(TRIM(encounter_type))
      ELSE 'Other'
    END AS encounter_type,
    attending_physician,
    e.ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_PATIENT_ENCOUNTER e
  LEFT JOIN SILVER.SLV_PATIENT p
    ON e.patient_id = p.patient_id;
  RETURN 'SLV_ENCOUNTER loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_SLV_LAB_RESULT()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_LAB_RESULT;
  INSERT INTO SILVER.SLV_LAB_RESULT (
    lab_result_sk,
    encounter_sk,
    patient_sk,
    patient_id,
    encounter_id,
    test_code,
    test_name,
    normalized_result,
    result_unit,
    result_date,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(l.lab_result_id, 256) AS lab_result_sk,
    e.encounter_sk,
    p.patient_sk,
    l.patient_id,
    l.encounter_id,
    UPPER(TRIM(l.test_code)) AS test_code,
    INITCAP(TRIM(l.test_name)) AS test_name,
    l.result_value AS normalized_result,
    TRIM(l.result_unit) AS result_unit,
    l.result_date,
    l.ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_LAB_RESULTS l
  LEFT JOIN SILVER.SLV_PATIENT p
    ON l.patient_id = p.patient_id
  LEFT JOIN SILVER.SLV_ENCOUNTER e
    ON l.encounter_id = e.encounter_id;
  RETURN 'SLV_LAB_RESULT loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_SLV_MEDICATION()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_MEDICATION;
  INSERT INTO SILVER.SLV_MEDICATION (
    medication_sk,
    patient_sk,
    patient_id,
    medication_name,
    dosage,
    prescription_date,
    prescribing_physician,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(prescription_id, 256) AS medication_sk,
    p.patient_sk,
    o.patient_id,
    INITCAP(TRIM(medication_name)) AS medication_name,
    TRIM(dosage) AS dosage,
    prescription_date,
    prescribing_physician,
    o.ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_PHARMACY_ORDERS o
  LEFT JOIN SILVER.SLV_PATIENT p
    ON o.patient_id = p.patient_id;
  RETURN 'SLV_MEDICATION loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_SLV_CLAIM()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_CLAIM;
  INSERT INTO SILVER.SLV_CLAIM (
    claim_sk,
    patient_sk,
    patient_id,
    insurance_id,
    claim_amount,
    claim_status,
    claim_date,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(claim_id, 256) AS claim_sk,
    p.patient_sk,
    c.patient_id,
    insurance_id,
    claim_amount,
    UPPER(TRIM(claim_status)) AS claim_status,
    claim_date,
    c.ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_CLAIMS c
  LEFT JOIN SILVER.SLV_PATIENT p
    ON c.patient_id = p.patient_id;
  RETURN 'SLV_CLAIM loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_ALL_SILVER()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  CALL LOAD_SLV_PATIENT();
  CALL LOAD_SLV_ENCOUNTER();
  CALL LOAD_SLV_LAB_RESULT();
  CALL LOAD_SLV_MEDICATION();
  CALL LOAD_SLV_CLAIM();
  RETURN 'All SILVER tables loaded successfully';
END;
$$;

CREATE OR REPLACE VIEW VW_SILVER_ROW_COUNTS AS
SELECT 'SLV_PATIENT' AS object_name, COUNT(*) AS row_count FROM SILVER.SLV_PATIENT
UNION ALL
SELECT 'SLV_ENCOUNTER', COUNT(*) FROM SILVER.SLV_ENCOUNTER
UNION ALL
SELECT 'SLV_LAB_RESULT', COUNT(*) FROM SILVER.SLV_LAB_RESULT
UNION ALL
SELECT 'SLV_MEDICATION', COUNT(*) FROM SILVER.SLV_MEDICATION
UNION ALL
SELECT 'SLV_CLAIM', COUNT(*) FROM SILVER.SLV_CLAIM;

-- Grant USAGE privileges on procedures to OVALEDGE_ROLE
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_PATIENT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_ENCOUNTER() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_LAB_RESULT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_MEDICATION() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_CLAIM() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_ALL_SILVER() TO ROLE OVALEDGE_ROLE;

CALL LOAD_ALL_SILVER();
