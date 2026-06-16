-- Phase 6: SQL Audit-Based Data Quality Framework
-- Creates DQ metadata tables, rules, runner procedure, failed-record capture, and alerting

USE ROLE OVALEDGE_ROLE;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;

-- Create GOVERNANCE schema objects for DQ if not present
CREATE SCHEMA IF NOT EXISTS GOVERNANCE.DQ;

-- DQ_RULE stores rule definitions
CREATE OR REPLACE TABLE GOVERNANCE.DQ.DQ_RULE (
  rule_id VARCHAR PRIMARY KEY,
  description VARCHAR,
  object_schema VARCHAR,
  object_name VARCHAR,
  expression VARCHAR,
  severity VARCHAR,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DQ_RUN stores runs
CREATE OR REPLACE TABLE GOVERNANCE.DQ.DQ_RUN (
  run_id VARCHAR PRIMARY KEY,
  started_at TIMESTAMP,
  finished_at TIMESTAMP,
  status VARCHAR,
  run_by VARCHAR
);

-- DQ_RESULT stores aggregated results per rule per run
CREATE OR REPLACE TABLE GOVERNANCE.DQ.DQ_RESULT (
  run_id VARCHAR,
  rule_id VARCHAR,
  passed_count NUMBER,
  failed_count NUMBER,
  PRIMARY KEY (run_id, rule_id)
);

-- DQ_FAILED_RECORD stores failed record details
CREATE OR REPLACE TABLE GOVERNANCE.DQ.DQ_FAILED_RECORD (
  run_id VARCHAR,
  rule_id VARCHAR,
  object_schema VARCHAR,
  object_name VARCHAR,
  record_key VARCHAR,
  failure_message VARCHAR,
  captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DQ_ALERT stores alerts
CREATE OR REPLACE TABLE GOVERNANCE.DQ.DQ_ALERT (
  alert_id VARCHAR PRIMARY KEY,
  run_id VARCHAR,
  rule_id VARCHAR,
  severity VARCHAR,
  message VARCHAR,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample rules DQ001-DQ007
INSERT INTO GOVERNANCE.DQ.DQ_RULE (rule_id, description, object_schema, object_name, expression, severity)
VALUES
('DQ001','Patient ID cannot be null','BRONZE','BRZ_PATIENT_MASTER','patient_id IS NOT NULL','HIGH'),
('DQ002','DOB cannot be future dated','BRONZE','BRZ_PATIENT_MASTER','dob <= CURRENT_DATE','HIGH'),
('DQ003','Age must be between 0 and 120','SILVER','SLV_PATIENT','age BETWEEN 0 AND 120','MEDIUM'),
('DQ004','Discharge date >= Admission date','BRONZE','BRZ_PATIENT_ENCOUNTER','discharge_date >= admission_date','HIGH'),
('DQ005','Length of stay >= 0','SILVER','SLV_ENCOUNTER','length_of_stay >= 0','MEDIUM'),
('DQ006','Lab result value cannot be null','BRONZE','BRZ_LAB_RESULTS','result_value IS NOT NULL','HIGH'),
('DQ007','Blood glucose normalized result between 40 and 600','SILVER','SLV_LAB_RESULT','normalized_result BETWEEN 40 AND 600','HIGH');

-- Stored procedure to run DQ rules. It will iterate rules, execute counts, store results, and capture failed record keys.
CREATE OR REPLACE PROCEDURE GOVERNANCE.DQ.RUN_DQ(run_id VARCHAR)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS
$$
var runId = run_id;
var start = new Date();
var ctx = snowflake.createStatement({sqlText: `INSERT INTO GOVERNANCE.DQ.DQ_RUN(run_id, started_at, status, run_by) VALUES(?, CURRENT_TIMESTAMP, 'RUNNING', CURRENT_ROLE())` , binds:[runId]}).execute();

// fetch rules
var rs = snowflake.createStatement({sqlText: `SELECT rule_id, object_schema, object_name, expression FROM GOVERNANCE.DQ.DQ_RULE ORDER BY rule_id`}).execute();
while(rs.next()){
  var rule_id = rs.getColumnValue(1);
  var obj_schema = rs.getColumnValue(2);
  var obj_name = rs.getColumnValue(3);
  var expr = rs.getColumnValue(4);
  
  // build count queries
  var pass_q = `SELECT COUNT(*) FROM ${obj_schema}.${obj_name} WHERE ${expr}`;
  var total_q = `SELECT COUNT(*) FROM ${obj_schema}.${obj_name}`;
  var fail_q = `SELECT COUNT(*) FROM ${obj_schema}.${obj_name} WHERE NOT (${expr})`;

  var pass_rs = snowflake.createStatement({sqlText: pass_q}).execute();
  pass_rs.next();
  var passed = pass_rs.getColumnValue(1);

  var fail_rs = snowflake.createStatement({sqlText: fail_q}).execute();
  fail_rs.next();
  var failed = fail_rs.getColumnValue(1);

  // insert into DQ_RESULT
  snowflake.createStatement({sqlText: `MERGE INTO GOVERNANCE.DQ.DQ_RESULT tgt USING (SELECT ? AS run_id, ? AS rule_id, ? AS passed_count, ? AS failed_count) src ON tgt.run_id = src.run_id AND tgt.rule_id = src.rule_id WHEN MATCHED THEN UPDATE SET passed_count = src.passed_count, failed_count = src.failed_count WHEN NOT MATCHED THEN INSERT (run_id, rule_id, passed_count, failed_count) VALUES(src.run_id, src.rule_id, src.passed_count, src.failed_count)`, binds:[runId, rule_id, passed, failed]}).execute();

  // capture failed records keys (simple approach: capture JSON of key columns)
  if(failed > 0){
    var capture_sql = `SELECT OBJECT_CONSTRUCT(*)::STRING AS rec FROM ${obj_schema}.${obj_name} WHERE NOT (${expr}) LIMIT 1000`;
    var cap_rs = snowflake.createStatement({sqlText: capture_sql}).execute();
    while(cap_rs.next()){
      var rec = cap_rs.getColumnValue(1);
      snowflake.createStatement({sqlText: `INSERT INTO GOVERNANCE.DQ.DQ_FAILED_RECORD(run_id, rule_id, object_schema, object_name, record_key, failure_message) VALUES(?, ?, ?, ?, ?, ?)`, binds:[runId, rule_id, obj_schema, obj_name, rec, 'Rule failed']}).execute();
    }

    // create alert
    snowflake.createStatement({sqlText: `INSERT INTO GOVERNANCE.DQ.DQ_ALERT(alert_id, run_id, rule_id, severity, message) VALUES(?, ?, ?, ?, ?)`, binds:[runId + '_' + rule_id, runId, rule_id, 'HIGH', 'Rule failed with ' + failed + ' records']}).execute();
  }
}

// finalize run
snowflake.createStatement({sqlText: `UPDATE GOVERNANCE.DQ.DQ_RUN SET finished_at = CURRENT_TIMESTAMP, status = 'COMPLETED' WHERE run_id = ?`, binds:[runId]}).execute();

return 'COMPLETED';
$$;

-- NOTE: The procedure captures up to 1000 failed records per rule per run; adjust as needed.
