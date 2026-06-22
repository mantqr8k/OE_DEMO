-- Phase 4: Gold analytics layer.
-- Uses regular tables and load procedures for dimensional and fact models, plus analytics views for KPIs.
-- Run after Phase 3.

USE ROLE SYSADMIN;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;

USE SCHEMA GOLD;

DROP DYNAMIC TABLE IF EXISTS DIM_PATIENT;
DROP TABLE IF EXISTS DIM_PATIENT;
CREATE OR REPLACE TABLE DIM_PATIENT (
  patient_sk VARCHAR(64) COMMENT 'Surrogate key for patient',
  patient_id VARCHAR(50) COMMENT 'Source patient identifier',
  patient_name VARCHAR(200) COMMENT 'Standardized patient full name',
  age NUMBER COMMENT 'Patient age in years',
  gender VARCHAR(20) COMMENT 'Patient gender',
  city VARCHAR(100) COMMENT 'Patient city',
  state VARCHAR(50) COMMENT 'Patient state'
) COMMENT = 'Gold patient dimension table.';

DROP DYNAMIC TABLE IF EXISTS DIM_HOSPITAL;
DROP TABLE IF EXISTS DIM_HOSPITAL;
CREATE OR REPLACE TABLE DIM_HOSPITAL (
  hospital_sk VARCHAR(64) COMMENT 'Surrogate key for hospital',
  hospital_id VARCHAR(50) COMMENT 'Source hospital identifier',
  hospital_name VARCHAR(200) COMMENT 'Hospital name from mapping logic',
  hospital_region VARCHAR(100) COMMENT 'Hospital region from mapping logic'
) COMMENT = 'Gold hospital dimension table.';

DROP DYNAMIC TABLE IF EXISTS DIM_DIAGNOSIS;
DROP TABLE IF EXISTS DIM_DIAGNOSIS;
CREATE OR REPLACE TABLE DIM_DIAGNOSIS (
  diagnosis_sk VARCHAR(64) COMMENT 'Surrogate key for diagnosis code',
  diagnosis_code VARCHAR(50) COMMENT 'Source diagnosis code',
  diagnosis_description VARCHAR(500) COMMENT 'Diagnosis description from mapping logic'
) COMMENT = 'Gold diagnosis dimension table.';

DROP DYNAMIC TABLE IF EXISTS FACT_ENCOUNTER;
DROP TABLE IF EXISTS FACT_ENCOUNTER;
CREATE OR REPLACE TABLE FACT_ENCOUNTER (
  encounter_sk VARCHAR(64) COMMENT 'Surrogate key for encounter',
  patient_sk VARCHAR(64) COMMENT 'Foreign key to DIM_PATIENT',
  hospital_sk VARCHAR(64) COMMENT 'Foreign key to DIM_HOSPITAL',
  diagnosis_sk VARCHAR(64) COMMENT 'Foreign key to DIM_DIAGNOSIS',
  admission_date DATE COMMENT 'Encounter admission date',
  discharge_date DATE COMMENT 'Encounter discharge date',
  length_of_stay NUMBER COMMENT 'Length of stay in days'
) COMMENT = 'Gold encounter fact table.';

DROP DYNAMIC TABLE IF EXISTS FACT_READMISSION;
DROP TABLE IF EXISTS FACT_READMISSION;
CREATE OR REPLACE TABLE FACT_READMISSION (
  patient_sk VARCHAR(64) COMMENT 'Foreign key to DIM_PATIENT',
  encounter_sk VARCHAR(64) COMMENT 'Foreign key to FACT_ENCOUNTER',
  hospital_sk VARCHAR(64) COMMENT 'Foreign key to DIM_HOSPITAL',
  discharge_date DATE COMMENT 'Discharge date of current encounter',
  next_admission_date DATE COMMENT 'Next admission date for same patient',
  days_between_visits NUMBER COMMENT 'Days between discharge and next admission',
  readmission_flag NUMBER COMMENT 'Flag indicating 30-day readmission (1=yes, 0=no)'
) COMMENT = 'Gold readmission fact table.';

DROP DYNAMIC TABLE IF EXISTS FACT_CLAIMS;
DROP TABLE IF EXISTS FACT_CLAIMS;
CREATE OR REPLACE TABLE FACT_CLAIMS (
  claim_sk VARCHAR(64) COMMENT 'Surrogate key for claim',
  patient_sk VARCHAR(64) COMMENT 'Foreign key to DIM_PATIENT',
  claim_amount NUMBER COMMENT 'Claim monetary amount',
  claim_status VARCHAR(50) COMMENT 'Claim status'
) COMMENT = 'Gold claims fact table.';

DROP DYNAMIC TABLE IF EXISTS DIM_PROVIDER;
DROP TABLE IF EXISTS DIM_PROVIDER;
CREATE OR REPLACE TABLE DIM_PROVIDER (
  provider_sk VARCHAR(64) COMMENT 'Surrogate key for provider',
  provider_id VARCHAR(50) COMMENT 'Source provider identifier',
  provider_name VARCHAR(200) COMMENT 'Provider name',
  specialty VARCHAR(100) COMMENT 'Provider specialty',
  hospital_id VARCHAR(50) COMMENT 'Hospital identifier',
  hospital_name VARCHAR(200) COMMENT 'Hospital name',
  license_number VARCHAR(100) COMMENT 'Provider license number',
  license_expiry_date DATE COMMENT 'Provider license expiry date',
  license_status VARCHAR(20) COMMENT 'Provider license status',
  active_flag BOOLEAN COMMENT 'Provider active flag'
) COMMENT = 'Gold provider dimension table.';

DROP DYNAMIC TABLE IF EXISTS FACT_APPOINTMENT;
DROP TABLE IF EXISTS FACT_APPOINTMENT;
CREATE OR REPLACE TABLE FACT_APPOINTMENT (
  appointment_sk VARCHAR(64) COMMENT 'Surrogate key for appointment',
  appointment_id VARCHAR(50) COMMENT 'Source appointment identifier',
  patient_sk VARCHAR(64) COMMENT 'Foreign key to DIM_PATIENT',
  provider_sk VARCHAR(64) COMMENT 'Foreign key to DIM_PROVIDER',
  hospital_sk VARCHAR(64) COMMENT 'Foreign key to DIM_HOSPITAL',
  appointment_date DATE COMMENT 'Appointment date',
  appointment_status VARCHAR(50) COMMENT 'Appointment status',
  scheduled_time VARCHAR(20) COMMENT 'Scheduled time',
  actual_start_time VARCHAR(20) COMMENT 'Actual start time',
  appointment_duration_minutes NUMBER COMMENT 'Appointment duration in minutes',
  wait_time_minutes NUMBER COMMENT 'Wait time in minutes',
  cancellation_flag NUMBER(1,0) COMMENT 'Cancellation indicator',
  no_show_flag NUMBER(1,0) COMMENT 'No-show indicator'
) COMMENT = 'Gold appointment fact table.';

DROP DYNAMIC TABLE IF EXISTS FACT_PROVIDER_DAILY;
DROP TABLE IF EXISTS FACT_PROVIDER_DAILY;
CREATE OR REPLACE TABLE FACT_PROVIDER_DAILY (
  provider_sk VARCHAR(64) COMMENT 'Foreign key to DIM_PROVIDER',
  activity_date DATE COMMENT 'Activity date',
  appointments_booked NUMBER COMMENT 'Appointments booked',
  appointments_completed NUMBER COMMENT 'Appointments completed',
  patients_seen NUMBER COMMENT 'Patients seen',
  no_show_count NUMBER COMMENT 'No-show count',
  cancellation_count NUMBER COMMENT 'Cancellation count',
  utilization_rate NUMBER COMMENT 'Provider utilization rate'
) COMMENT = 'Gold provider daily activity fact table.';

DROP DYNAMIC TABLE IF EXISTS FACT_PROVIDER_MONTHLY;
DROP TABLE IF EXISTS FACT_PROVIDER_MONTHLY;
CREATE OR REPLACE TABLE FACT_PROVIDER_MONTHLY (
  provider_sk VARCHAR(64) COMMENT 'Foreign key to DIM_PROVIDER',
  reporting_month DATE COMMENT 'Reporting month',
  patients_seen NUMBER COMMENT 'Patients seen',
  encounters_completed NUMBER COMMENT 'Encounters completed',
  appointments_completed NUMBER COMMENT 'Appointments completed',
  no_show_rate NUMBER COMMENT 'No-show rate',
  utilization_rate NUMBER COMMENT 'Utilization rate',
  readmission_rate NUMBER COMMENT 'Readmission rate'
) COMMENT = 'Gold provider monthly activity fact table.';

CREATE OR REPLACE PROCEDURE LOAD_DIM_PATIENT()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.DIM_PATIENT;
  INSERT INTO GOLD.DIM_PATIENT (
    patient_sk,
    patient_id,
    patient_name,
    age,
    gender,
    city,
    state
  )
  SELECT
    patient_sk,
    patient_id,
    patient_name,
    age,
    gender,
    city,
    state
  FROM SILVER.SLV_PATIENT;
  RETURN 'DIM_PATIENT loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_DIM_HOSPITAL()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.DIM_HOSPITAL;
  INSERT INTO GOLD.DIM_HOSPITAL (
    hospital_sk,
    hospital_id,
    hospital_name,
    hospital_region
  )
  SELECT
    SHA2(hospital_id, 256) AS hospital_sk,
    hospital_id,
    CASE hospital_id
      WHEN 'H001' THEN 'Central Medical Center'
      WHEN 'H002' THEN 'Lakeside Health'
      WHEN 'H003' THEN 'Bayview Hospital'
      ELSE 'Unknown Hospital'
    END AS hospital_name,
    CASE hospital_id
      WHEN 'H001' THEN 'Northeast'
      WHEN 'H002' THEN 'Midwest'
      WHEN 'H003' THEN 'West'
      ELSE 'Unknown'
    END AS hospital_region
  FROM (
    SELECT DISTINCT hospital_id
    FROM SILVER.SLV_ENCOUNTER
    WHERE hospital_id IS NOT NULL
  );
  RETURN 'DIM_HOSPITAL loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_DIM_DIAGNOSIS()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.DIM_DIAGNOSIS;
  INSERT INTO GOLD.DIM_DIAGNOSIS (
    diagnosis_sk,
    diagnosis_code,
    diagnosis_description
  )
  SELECT
    SHA2(diagnosis_code, 256) AS diagnosis_sk,
    diagnosis_code,
    CASE diagnosis_code
      WHEN 'I50.9' THEN 'Heart failure, unspecified'
      WHEN 'E11.9' THEN 'Type 2 diabetes mellitus without complications'
      WHEN 'J18.9' THEN 'Pneumonia, unspecified organism'
      WHEN 'N18.9' THEN 'Chronic kidney disease, unspecified'
      WHEN 'O80' THEN 'Encounter for full-term uncomplicated delivery'
      WHEN 'I10' THEN 'Essential hypertension'
      ELSE 'Unmapped diagnosis'
    END AS diagnosis_description
  FROM (
    SELECT DISTINCT diagnosis_code
    FROM SILVER.SLV_ENCOUNTER
    WHERE diagnosis_code IS NOT NULL
  );
  RETURN 'DIM_DIAGNOSIS loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_FACT_ENCOUNTER()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.FACT_ENCOUNTER;
  INSERT INTO GOLD.FACT_ENCOUNTER (
    encounter_sk,
    patient_sk,
    hospital_sk,
    diagnosis_sk,
    admission_date,
    discharge_date,
    length_of_stay
  )
  SELECT
    e.encounter_sk,
    e.patient_sk,
    h.hospital_sk,
    d.diagnosis_sk,
    e.admission_date,
    e.discharge_date,
    e.length_of_stay
  FROM SILVER.SLV_ENCOUNTER e
  LEFT JOIN GOLD.DIM_HOSPITAL h
    ON e.hospital_id = h.hospital_id
  LEFT JOIN GOLD.DIM_DIAGNOSIS d
    ON e.diagnosis_code = d.diagnosis_code;
  RETURN 'FACT_ENCOUNTER loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_FACT_READMISSION()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.FACT_READMISSION;
  INSERT INTO GOLD.FACT_READMISSION (
    patient_sk,
    encounter_sk,
    hospital_sk,
    discharge_date,
    next_admission_date,
    days_between_visits,
    readmission_flag
  )
  WITH encounter_sequence AS (
    SELECT
      e.patient_sk,
      e.encounter_sk,
      h.hospital_sk,
      e.discharge_date,
      LEAD(e.admission_date) OVER (
        PARTITION BY e.patient_sk
        ORDER BY e.admission_date, e.encounter_id
      ) AS next_admission_date
    FROM SILVER.SLV_ENCOUNTER e
    LEFT JOIN GOLD.DIM_HOSPITAL h
      ON e.hospital_id = h.hospital_id
    WHERE e.patient_sk IS NOT NULL
  )
  SELECT
    patient_sk,
    encounter_sk,
    hospital_sk,
    discharge_date,
    next_admission_date,
    DATEDIFF('day', discharge_date, next_admission_date) AS days_between_visits,
    CASE
      WHEN DATEDIFF('day', discharge_date, next_admission_date) BETWEEN 0 AND 30 THEN 1
      ELSE 0
    END AS readmission_flag
  FROM encounter_sequence;
  RETURN 'FACT_READMISSION loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_FACT_CLAIMS()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.FACT_CLAIMS;
  INSERT INTO GOLD.FACT_CLAIMS (
    claim_sk,
    patient_sk,
    claim_amount,
    claim_status
  )
  SELECT
    claim_sk,
    patient_sk,
    claim_amount,
    claim_status
  FROM SILVER.SLV_CLAIM;
  RETURN 'FACT_CLAIMS loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_DIM_PROVIDER()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.DIM_PROVIDER;
  INSERT INTO GOLD.DIM_PROVIDER (
    provider_sk,
    provider_id,
    provider_name,
    specialty,
    hospital_id,
    hospital_name,
    license_number,
    license_expiry_date,
    license_status,
    active_flag
  )
  SELECT
    provider_sk,
    provider_id,
    provider_name,
    specialty,
    hospital_id,
    CASE
      WHEN hospital_id = 'H001' THEN 'Central Medical Center'
      WHEN hospital_id = 'H002' THEN 'Lakeside Health'
      WHEN hospital_id = 'H003' THEN 'Bayview Hospital'
      ELSE 'Unknown Hospital'
    END AS hospital_name,
    license_number,
    license_expiry_date,
    license_status,
    active_flag
  FROM SILVER.SLV_PROVIDER;
  RETURN 'DIM_PROVIDER loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_FACT_APPOINTMENT()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.FACT_APPOINTMENT;
  INSERT INTO GOLD.FACT_APPOINTMENT (
    appointment_sk,
    appointment_id,
    patient_sk,
    provider_sk,
    hospital_sk,
    appointment_date,
    appointment_status,
    scheduled_time,
    actual_start_time,
    appointment_duration_minutes,
    wait_time_minutes,
    cancellation_flag,
    no_show_flag
  )
  SELECT
    a.appointment_sk,
    a.appointment_id,
    p.patient_sk,
    d.provider_sk,
    h.hospital_sk,
    a.appointment_date,
    a.appointment_status,
    a.scheduled_time,
    a.actual_start_time,
    a.appointment_duration_minutes,
    a.wait_time_minutes,
    a.cancellation_flag,
    a.no_show_flag
  FROM SILVER.SLV_APPOINTMENT a
  LEFT JOIN SILVER.SLV_PATIENT p ON a.patient_id = p.patient_id
  LEFT JOIN SILVER.SLV_PROVIDER d ON a.provider_id = d.provider_id
  LEFT JOIN GOLD.DIM_HOSPITAL h ON a.hospital_id = h.hospital_id;
  RETURN 'FACT_APPOINTMENT loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_FACT_PROVIDER_DAILY()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.FACT_PROVIDER_DAILY;
  INSERT INTO GOLD.FACT_PROVIDER_DAILY (
    provider_sk,
    activity_date,
    appointments_booked,
    appointments_completed,
    patients_seen,
    no_show_count,
    cancellation_count,
    utilization_rate
  )
  SELECT
    a.provider_sk,
    a.appointment_date AS activity_date,
    COUNT(*) AS appointments_booked,
    COUNT_IF(a.appointment_status = 'COMPLETED') AS appointments_completed,
    COUNT(DISTINCT a.patient_sk) AS patients_seen,
    SUM(a.no_show_flag) AS no_show_count,
    SUM(a.cancellation_flag) AS cancellation_count,
    IFF(COUNT(*) = 0, NULL, ROUND(SUM(IFF(a.appointment_status IN ('COMPLETED','NO_SHOW'), 1, 0)) / COUNT(*), 4)) AS utilization_rate
  FROM GOLD.FACT_APPOINTMENT a
  GROUP BY a.provider_sk, a.appointment_date;
  RETURN 'FACT_PROVIDER_DAILY loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_FACT_PROVIDER_MONTHLY()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  TRUNCATE TABLE GOLD.FACT_PROVIDER_MONTHLY;
  INSERT INTO GOLD.FACT_PROVIDER_MONTHLY (
    provider_sk,
    reporting_month,
    patients_seen,
    encounters_completed,
    appointments_completed,
    no_show_rate,
    utilization_rate,
    readmission_rate
  )
  SELECT
    provider_sk,
    DATE_TRUNC('month', activity_date) AS reporting_month,
    SUM(patients_seen) AS patients_seen,
    SUM(appointments_booked) AS encounters_completed,
    SUM(appointments_completed) AS appointments_completed,
    IFF(SUM(appointments_booked) = 0, NULL, ROUND(SUM(no_show_count) / SUM(appointments_booked), 4)) AS no_show_rate,
    IFF(SUM(appointments_booked) = 0, NULL, ROUND(SUM(appointments_completed) / SUM(appointments_booked), 4)) AS utilization_rate,
    NULL AS readmission_rate
  FROM GOLD.FACT_PROVIDER_DAILY
  GROUP BY provider_sk, DATE_TRUNC('month', activity_date);
  RETURN 'FACT_PROVIDER_MONTHLY loaded';
END;
$$;

CREATE OR REPLACE PROCEDURE LOAD_ALL_GOLD()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  CALL LOAD_DIM_PATIENT();
  CALL LOAD_DIM_HOSPITAL();
  CALL LOAD_DIM_DIAGNOSIS();
  CALL LOAD_DIM_PROVIDER();
  CALL LOAD_FACT_ENCOUNTER();
  CALL LOAD_FACT_READMISSION();
  CALL LOAD_FACT_CLAIMS();
  CALL LOAD_FACT_APPOINTMENT();
  CALL LOAD_FACT_PROVIDER_DAILY();
  CALL LOAD_FACT_PROVIDER_MONTHLY();
  RETURN 'All GOLD tables loaded successfully';
END;
$$;

-- Grant USAGE privileges on procedures to OVALEDGE_ROLE
GRANT USAGE ON PROCEDURE GOLD.LOAD_DIM_PATIENT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_DIM_HOSPITAL() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_DIM_DIAGNOSIS() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_DIM_PROVIDER() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_ENCOUNTER() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_READMISSION() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_CLAIMS() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_APPOINTMENT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_PROVIDER_DAILY() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_PROVIDER_MONTHLY() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_ALL_GOLD() TO ROLE OVALEDGE_ROLE;

CREATE OR REPLACE VIEW VW_GOLD_ROW_COUNTS AS
SELECT 'DIM_PATIENT' AS object_name, COUNT(*) AS row_count FROM GOLD.DIM_PATIENT
UNION ALL
SELECT 'DIM_HOSPITAL', COUNT(*) FROM GOLD.DIM_HOSPITAL
UNION ALL
SELECT 'DIM_DIAGNOSIS', COUNT(*) FROM GOLD.DIM_DIAGNOSIS
UNION ALL
SELECT 'FACT_ENCOUNTER', COUNT(*) FROM GOLD.FACT_ENCOUNTER
UNION ALL
SELECT 'FACT_READMISSION', COUNT(*) FROM GOLD.FACT_READMISSION
UNION ALL
SELECT 'FACT_CLAIMS', COUNT(*) FROM GOLD.FACT_CLAIMS;

CALL LOAD_ALL_GOLD();

USE SCHEMA ANALYTICS;

CREATE OR REPLACE VIEW VW_READMISSION_RATE AS
SELECT
  COUNT_IF(readmission_flag = 1) AS readmitted_encounters,
  COUNT(*) AS total_discharged_encounters,
  ROUND(COUNT_IF(readmission_flag = 1) / NULLIF(COUNT(*), 0), 4) AS readmission_rate
FROM GOLD.FACT_READMISSION
WHERE discharge_date IS NOT NULL;

CREATE OR REPLACE VIEW VW_AVERAGE_LENGTH_OF_STAY AS
SELECT
  SUM(length_of_stay) AS total_length_of_stay,
  COUNT(*) AS total_encounters,
  ROUND(AVG(length_of_stay), 2) AS average_length_of_stay
FROM GOLD.FACT_ENCOUNTER
WHERE length_of_stay >= 0;

CREATE OR REPLACE VIEW VW_CLAIM_APPROVAL_RATE AS
SELECT
  COUNT_IF(claim_status = 'APPROVED') AS approved_claims,
  COUNT(*) AS total_claims,
  ROUND(COUNT_IF(claim_status = 'APPROVED') / NULLIF(COUNT(*), 0), 4) AS claim_approval_rate
FROM GOLD.FACT_CLAIMS;

CREATE OR REPLACE VIEW VW_EXECUTIVE_KPI_SUMMARY AS
SELECT
  '30-Day Readmission Rate' AS kpi_name,
  readmission_rate AS kpi_value,
  readmitted_encounters AS numerator,
  total_discharged_encounters AS denominator
FROM ANALYTICS.VW_READMISSION_RATE
UNION ALL
SELECT
  'Average Length of Stay',
  average_length_of_stay,
  total_length_of_stay,
  total_encounters
FROM ANALYTICS.VW_AVERAGE_LENGTH_OF_STAY
UNION ALL
SELECT
  'Claim Approval Rate',
  claim_approval_rate,
  approved_claims,
  total_claims
FROM ANALYTICS.VW_CLAIM_APPROVAL_RATE;

