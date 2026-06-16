# Phase 6: SQL Audit-Based Data Quality Framework

## Overview

Phase 6 implements deterministic SQL-based data quality checks and a lightweight audit framework using Snowflake objects. It provides:

- Rule registry (`GOVERNANCE.DQ.DQ_RULE`)
- Run history (`GOVERNANCE.DQ.DQ_RUN`)
- Aggregated results (`GOVERNANCE.DQ.DQ_RESULT`)
- Failed-record capture (`GOVERNANCE.DQ.DQ_FAILED_RECORD`)
- Alert table (`GOVERNANCE.DQ.DQ_ALERT`)
- Runner stored procedure `GOVERNANCE.DQ.RUN_DQ(run_id)`

## How it works

- Rules are SQL boolean expressions stored in `DQ_RULE`.
- The runner iterates rules, counts passing and failing rows, stores results, captures failed records (JSON), and inserts alerts.
- Failed record capture is limited to 1000 rows per rule per run by default.

## Sample rules
- `DQ001`: Patient ID cannot be null (BRONZE.BRZ_PATIENT_MASTER)
- `DQ002`: DOB cannot be future dated (BRONZE.BRZ_PATIENT_MASTER)
- `DQ003`: Age must be between 0 and 120 (SILVER.SLV_PATIENT)
- `DQ004`: Discharge date >= Admission date (BRONZE.BRZ_PATIENT_ENCOUNTER)
- `DQ005`: Length of stay >= 0 (SILVER.SLV_ENCOUNTER)
- `DQ006`: Lab result value cannot be null (BRONZE.BRZ_LAB_RESULTS)
- `DQ007`: Blood glucose normalized result between 40 and 600 (SILVER.SLV_LAB_RESULT)

## Running DQ

Example:

```sql
-- create a new run id and execute
CALL GOVERNANCE.DQ.RUN_DQ('RUN_20260611_01');

-- view aggregated results
SELECT * FROM GOVERNANCE.DQ.DQ_RESULT;

-- inspect failed records
SELECT * FROM GOVERNANCE.DQ.DQ_FAILED_RECORD ORDER BY captured_at DESC;
```

## Limitations and Notes
- The runner executes dynamic SQL using string concatenation; ensure rule expressions are valid and safe.
- Failed-record capture stores a JSON representation of the entire row. For production, capture key columns instead.
- To reduce load, schedule rule executions or split heavy rules into incremental checks.

## Next steps
- Add automated steward assignment based on rule metadata
- Integrate alerts with messaging (Slack/email) via external functions
- Add DQ scoring and historical trend views
