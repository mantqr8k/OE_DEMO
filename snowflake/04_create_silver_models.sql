-- Phase 3: Silver standardization layer.
-- Uses regular tables and load procedures to materialize standardized models from Bronze data.
-- Run after Phase 2.

USE ROLE SYSADMIN;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;
USE SCHEMA SILVER;

-- DROP DYNAMIC TABLE IF EXISTS SLV_PATIENT;
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

-- DROP DYNAMIC TABLE IF EXISTS SLV_ENCOUNTER;
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

-- DROP DYNAMIC TABLE IF EXISTS SLV_LAB_RESULT;
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

-- DROP DYNAMIC TABLE IF EXISTS SLV_MEDICATION;
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

-- DROP DYNAMIC TABLE IF EXISTS SLV_CLAIM;
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

-- DROP DYNAMIC TABLE IF EXISTS SLV_APPOINTMENT;
DROP TABLE IF EXISTS SLV_APPOINTMENT;
CREATE OR REPLACE TABLE SLV_APPOINTMENT (
  appointment_sk VARCHAR(64) COMMENT 'Surrogate key hashed from appointment_id',
  appointment_id VARCHAR(50) COMMENT 'Source appointment identifier from Bronze appointment table',
  patient_sk VARCHAR(64) COMMENT 'Surrogate key for patient from SLV_PATIENT',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier from Bronze appointment',
  provider_id VARCHAR(50) COMMENT 'Source provider identifier from Bronze appointment',
  hospital_id VARCHAR(50) COMMENT 'Hospital identifier from source appointment',
  appointment_date DATE COMMENT 'Appointment date',
  appointment_status VARCHAR(50) COMMENT 'Normalized appointment status',
  scheduled_time VARCHAR(20) COMMENT 'Scheduled appointment time',
  actual_start_time VARCHAR(20) COMMENT 'Actual appointment start time',
  appointment_duration_minutes NUMBER COMMENT 'Appointment duration in minutes',
  wait_time_minutes NUMBER COMMENT 'Wait time in minutes',
  cancellation_flag NUMBER(1,0) COMMENT 'Indicator for cancellation',
  no_show_flag NUMBER(1,0) COMMENT 'Indicator for no-show',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver appointment fact table.';

-- DROP DYNAMIC TABLE IF EXISTS SLV_PROVIDER;
DROP TABLE IF EXISTS SLV_PROVIDER;
CREATE OR REPLACE TABLE SLV_PROVIDER (
  provider_sk VARCHAR(64) COMMENT 'Surrogate key hashed from provider_id',
  provider_id VARCHAR(50) COMMENT 'Source provider identifier',
  provider_name VARCHAR(200) COMMENT 'Provider full name',
  specialty VARCHAR(100) COMMENT 'Provider specialty',
  hospital_id VARCHAR(50) COMMENT 'Hospital identifier',
  license_number VARCHAR(100) COMMENT 'Provider license number',
  license_expiry_date DATE COMMENT 'Provider license expiry date',
  license_status VARCHAR(20) COMMENT 'Calculated license status',
  active_flag BOOLEAN COMMENT 'Provider active indicator',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver provider master table.';

-- DROP DYNAMIC TABLE IF EXISTS SLV_APPOINTMENT;
DROP TABLE IF EXISTS SLV_APPOINTMENT;
CREATE OR REPLACE TABLE SLV_APPOINTMENT (
  appointment_sk VARCHAR(64) COMMENT 'Surrogate key hashed from appointment_id',
  appointment_id VARCHAR(50) COMMENT 'Source appointment identifier from Bronze appointment table',
  patient_sk VARCHAR(64) COMMENT 'Surrogate key for patient from SLV_PATIENT',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier from Bronze appointment',
  provider_id VARCHAR(50) COMMENT 'Source provider identifier from Bronze appointment',
  hospital_id VARCHAR(50) COMMENT 'Hospital identifier from source appointment',
  appointment_date DATE COMMENT 'Appointment date',
  appointment_status VARCHAR(50) COMMENT 'Normalized appointment status',
  scheduled_time VARCHAR(20) COMMENT 'Scheduled appointment time',
  actual_start_time VARCHAR(20) COMMENT 'Actual appointment start time',
  appointment_duration_minutes NUMBER COMMENT 'Appointment duration in minutes',
  wait_time_minutes NUMBER COMMENT 'Wait time in minutes',
  cancellation_flag NUMBER(1,0) COMMENT 'Indicator for cancellation',
  no_show_flag NUMBER(1,0) COMMENT 'Indicator for no-show',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver appointment fact table.';

-- DROP DYNAMIC TABLE IF EXISTS SLV_PROVIDER;
DROP TABLE IF EXISTS SLV_PROVIDER;
CREATE OR REPLACE TABLE SLV_PROVIDER (
  provider_sk VARCHAR(64) COMMENT 'Surrogate key hashed from provider_id',
  provider_id VARCHAR(50) COMMENT 'Source provider identifier',
  provider_name VARCHAR(200) COMMENT 'Provider full name',
  specialty VARCHAR(100) COMMENT 'Provider specialty',
  hospital_id VARCHAR(50) COMMENT 'Hospital identifier',
  license_number VARCHAR(100) COMMENT 'Provider license number',
  license_expiry_date DATE COMMENT 'Provider license expiry date',
  license_status VARCHAR(20) COMMENT 'Calculated license status',
  active_flag BOOLEAN COMMENT 'Provider active indicator',
  source_ingestion_timestamp TIMESTAMP_NTZ COMMENT 'Ingestion timestamp from source record'
) COMMENT = 'Silver provider master table.';

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

CREATE OR REPLACE PROCEDURE LOAD_SLV_APPOINTMENT()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_APPOINTMENT;
  INSERT INTO SILVER.SLV_APPOINTMENT (
    appointment_sk,
    appointment_id,
    patient_sk,
    patient_id,
    provider_id,
    hospital_id,
    appointment_date,
    appointment_status,
    scheduled_time,
    actual_start_time,
    appointment_duration_minutes,
    wait_time_minutes,
    cancellation_flag,
    no_show_flag,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(appointment_id, 256) AS appointment_sk,
    appointment_id,
    p.patient_sk,
    a.patient_id,
    a.provider_id,
    UPPER(TRIM(a.hospital_id)) AS hospital_id,
    appointment_date,
    UPPER(TRIM(appointment_status)) AS appointment_status,
    scheduled_time,
    actual_start_time,
    IFF(
      actual_start_time IS NOT NULL AND scheduled_time IS NOT NULL,
      DATEDIFF('minute',
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', scheduled_time), 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', actual_start_time), 'YYYY-MM-DD HH24:MI:SS')
      ),
      NULL
    ) AS appointment_duration_minutes,
    IFF(
      actual_start_time IS NOT NULL AND scheduled_time IS NOT NULL,
      DATEDIFF('minute',
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', scheduled_time), 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', actual_start_time), 'YYYY-MM-DD HH24:MI:SS')
      ),
      NULL
    ) AS wait_time_minutes,
    IFF(UPPER(TRIM(appointment_status)) = 'CANCELLED', 1, 0) AS cancellation_flag,
    IFF(UPPER(TRIM(appointment_status)) = 'NO_SHOW', 1, 0) AS no_show_flag,
    a.ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_APPOINTMENT a
  LEFT JOIN SILVER.SLV_PATIENT p
    ON a.patient_id = p.patient_id;
  RETURN 'SLV_APPOINTMENT loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_SLV_PROVIDER()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_PROVIDER;
  INSERT INTO SILVER.SLV_PROVIDER (
    provider_sk,
    provider_id,
    provider_name,
    specialty,
    hospital_id,
    license_number,
    license_expiry_date,
    license_status,
    active_flag,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(provider_id, 256) AS provider_sk,
    provider_id,
    provider_name,
    specialty,
    hospital_id,
    license_number,
    license_expiry_date,
    IFF(license_expiry_date IS NOT NULL AND license_expiry_date < CURRENT_DATE, 'EXPIRED', 'ACTIVE') AS license_status,
    IFF(license_expiry_date IS NOT NULL AND license_expiry_date >= CURRENT_DATE, TRUE, FALSE) AS active_flag,
    ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_PROVIDER_MASTER;
  RETURN 'SLV_PROVIDER loaded';
END;
$$;


CREATE OR REPLACE PROCEDURE LOAD_SLV_APPOINTMENT()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_APPOINTMENT;
  INSERT INTO SILVER.SLV_APPOINTMENT (
    appointment_sk,
    appointment_id,
    patient_sk,
    patient_id,
    provider_id,
    hospital_id,
    appointment_date,
    appointment_status,
    scheduled_time,
    actual_start_time,
    appointment_duration_minutes,
    wait_time_minutes,
    cancellation_flag,
    no_show_flag,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(appointment_id, 256) AS appointment_sk,
    appointment_id,
    p.patient_sk,
    a.patient_id,
    a.provider_id,
    UPPER(TRIM(a.hospital_id)) AS hospital_id,
    appointment_date,
    UPPER(TRIM(appointment_status)) AS appointment_status,
    scheduled_time,
    actual_start_time,
    IFF(
      actual_start_time IS NOT NULL AND scheduled_time IS NOT NULL,
      DATEDIFF('minute',
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', scheduled_time), 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', actual_start_time), 'YYYY-MM-DD HH24:MI:SS')
      ),
      NULL
    ) AS appointment_duration_minutes,
    IFF(
      actual_start_time IS NOT NULL AND scheduled_time IS NOT NULL,
      DATEDIFF('minute',
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', scheduled_time), 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP_NTZ(CONCAT(TO_CHAR(appointment_date, 'YYYY-MM-DD'), ' ', actual_start_time), 'YYYY-MM-DD HH24:MI:SS')
      ),
      NULL
    ) AS wait_time_minutes,
    IFF(UPPER(TRIM(appointment_status)) = 'CANCELLED', 1, 0) AS cancellation_flag,
    IFF(UPPER(TRIM(appointment_status)) = 'NO_SHOW', 1, 0) AS no_show_flag,
    a.ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_APPOINTMENT a
  LEFT JOIN SILVER.SLV_PATIENT p
    ON a.patient_id = p.patient_id;
  RETURN 'SLV_APPOINTMENT loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_SLV_PROVIDER()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE SILVER.SLV_PROVIDER;
  INSERT INTO SILVER.SLV_PROVIDER (
    provider_sk,
    provider_id,
    provider_name,
    specialty,
    hospital_id,
    license_number,
    license_expiry_date,
    license_status,
    active_flag,
    source_ingestion_timestamp
  )
  SELECT
    SHA2(provider_id, 256) AS provider_sk,
    provider_id,
    provider_name,
    specialty,
    hospital_id,
    license_number,
    license_expiry_date,
    IFF(license_expiry_date IS NOT NULL AND license_expiry_date < CURRENT_DATE, 'EXPIRED', 'ACTIVE') AS license_status,
    IFF(license_expiry_date IS NOT NULL AND license_expiry_date >= CURRENT_DATE, TRUE, FALSE) AS active_flag,
    ingestion_timestamp AS source_ingestion_timestamp
  FROM BRONZE.BRZ_PROVIDER_MASTER;
  RETURN 'SLV_PROVIDER loaded';
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
  CALL LOAD_SLV_APPOINTMENT();
  CALL LOAD_SLV_PROVIDER();
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
SELECT 'SLV_CLAIM', COUNT(*) FROM SILVER.SLV_CLAIM
UNION ALL
SELECT 'SLV_APPOINTMENT', COUNT(*) FROM SILVER.SLV_APPOINTMENT
UNION ALL
SELECT 'SLV_PROVIDER', COUNT(*) FROM SILVER.SLV_PROVIDER;

-- Grant USAGE privileges on procedures to OVALEDGE_ROLE
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_PATIENT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_ENCOUNTER() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_LAB_RESULT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_MEDICATION() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_CLAIM() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_APPOINTMENT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_SLV_PROVIDER() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE SILVER.LOAD_ALL_SILVER() TO ROLE OVALEDGE_ROLE;

CALL LOAD_ALL_SILVER();
