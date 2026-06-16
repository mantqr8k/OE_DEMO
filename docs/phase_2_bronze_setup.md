# Phase 2 Bronze Setup

## Purpose

Phase 2 creates synthetic source-system data and loads it into Snowflake Bronze tables exactly as received.

The seeded data includes intentional quality failures for later governance demonstrations:

- Null `patient_id`
- Future `dob`
- Discharge date before admission date
- Out-of-range blood glucose result
- Null lab result value

## Files

Synthetic source files:

- `data/patient_master.csv`
- `data/patient_encounter.csv`
- `data/lab_results.csv`
- `data/pharmacy_orders.csv`
- `data/claims.csv`

Snowflake scripts:

- `snowflake/02_create_bronze_tables.sql`
- `snowflake/03_load_sample_data.sql`
- `snowflake/99_validate_phase_2.sql`

## Execution Order

Run the Bronze object setup:

```powershell
snow sql --connection emmwcta-zj29555 --filename snowflake\02_create_bronze_tables.sql
```

Upload local CSV files to the internal Snowflake stage:

```powershell
snow stage copy data\patient_master.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\patient_encounter.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\lab_results.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\pharmacy_orders.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\claims.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite

# Or upload the 1000-row test files:

snow stage copy data\patient_master_1000.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\patient_encounter_1000.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\lab_results_1000.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\pharmacy_orders_1000.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
snow stage copy data\claims_1000.csv "@HC_GOV_DEMO.BRONZE.RAW_DATA_STAGE" --connection emmwcta-zj29555 --overwrite
```

Load staged files into Bronze tables:

```powershell
snow sql --connection emmwcta-zj29555 --filename snowflake\03_load_sample_data.sql
```

Or for the larger test dataset:

```powershell
snow sql --connection emmwcta-zj29555 --filename snowflake\03_load_sample_data_1000.sql
```

Validate Phase 2:

```powershell
snow sql --connection emmwcta-zj29555 --filename snowflake\99_validate_phase_2.sql
```

## Expected Row Counts

- `BRZ_PATIENT_MASTER`: 8
- `BRZ_PATIENT_ENCOUNTER`: 8
- `BRZ_LAB_RESULTS`: 7
- `BRZ_PHARMACY_ORDERS`: 6
- `BRZ_CLAIMS`: 7

## Expected Injected Failures

- `NULL_PATIENT_ID`: 1
- `FUTURE_DOB`: 1
- `DISCHARGE_BEFORE_ADMISSION`: 1
- `OUT_OF_RANGE_BLOOD_GLUCOSE`: 1
- `NULL_LAB_RESULT_VALUE`: 1
