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
  CALL LOAD_FACT_ENCOUNTER();
  CALL LOAD_FACT_READMISSION();
  CALL LOAD_FACT_CLAIMS();
  RETURN 'All GOLD tables loaded successfully';
END;
$$;

-- Grant USAGE privileges on procedures to OVALEDGE_ROLE
GRANT USAGE ON PROCEDURE GOLD.LOAD_DIM_PATIENT() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_DIM_HOSPITAL() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_DIM_DIAGNOSIS() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_ENCOUNTER() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_READMISSION() TO ROLE OVALEDGE_ROLE;
GRANT USAGE ON PROCEDURE GOLD.LOAD_FACT_CLAIMS() TO ROLE OVALEDGE_ROLE;
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

