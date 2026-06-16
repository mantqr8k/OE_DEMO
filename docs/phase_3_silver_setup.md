# Phase 3 Silver Setup

## Purpose

Phase 3 creates the standardized Silver layer from Bronze data using Snowflake dynamic tables.

Dynamic tables are used so Snowflake can track dependencies and refresh transformed outputs declaratively. For this demo, Silver dynamic tables use `REFRESH_MODE = FULL` and `TARGET_LAG = '1 hour'` because the dataset is intentionally small and the transformations favor clarity over incremental refresh complexity.

## Files

- `snowflake/04_create_silver_models.sql`
- `snowflake/99_validate_phase_3.sql`

## Silver Objects

- `SILVER.SLV_PATIENT`
- `SILVER.SLV_ENCOUNTER`
- `SILVER.SLV_LAB_RESULT`
- `SILVER.SLV_MEDICATION`
- `SILVER.SLV_CLAIM`
- `SILVER.VW_SILVER_ROW_COUNTS`

## Transformations

- Deduplicate patients by `COALESCE(patient_id, medical_record_number)` using latest `ingestion_timestamp`.
- Standardize patient names with `INITCAP` and trimmed first/last name composition.
- Calculate age as of demo date `2026-06-11`.
- Standardize gender, city, state, diagnosis code, hospital ID, encounter type, and claim status.
- Generate deterministic surrogate keys with `SHA2`.
- Calculate encounter length of stay using `DATEDIFF`.
- Preserve invalid records so Phase 6 SQL DQ audits can capture failures.

## Execution

```powershell
snow sql --connection emmwcta-zj29555 --filename snowflake\04_create_silver_models.sql
snow sql --connection emmwcta-zj29555 --filename snowflake\99_validate_phase_3.sql
```

## Expected Row Counts

- `SLV_PATIENT`: 7
- `SLV_ENCOUNTER`: 8
- `SLV_LAB_RESULT`: 7
- `SLV_MEDICATION`: 6
- `SLV_CLAIM`: 7

`SLV_PATIENT` has 7 rows because the duplicate `P1001` Bronze patient record is deduplicated.

## Expected Preservation Checks

- `DEDUPED_PATIENT_P1001`: 1
- `NULL_PATIENT_ID_PRESERVED`: 1
- `FUTURE_DOB_PRESERVED`: 1
- `NEGATIVE_LOS_PRESERVED`: 1
- `OUT_OF_RANGE_GLUCOSE_PRESERVED`: 1
- `NULL_LAB_RESULT_PRESERVED`: 1

