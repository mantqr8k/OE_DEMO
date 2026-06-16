# Phase 4 Gold Setup

## Purpose

Phase 4 creates the business-ready analytics layer from Silver dynamic tables.

Gold dimensions and facts are implemented as Snowflake dynamic tables. KPI outputs are implemented as standard views in the `ANALYTICS` schema so dashboard and demo consumers query stable business-facing objects.

## Files

- `snowflake/05_create_gold_models.sql`
- `snowflake/99_validate_phase_4.sql`

## Gold Objects

Dynamic tables:

- `GOLD.DIM_PATIENT`
- `GOLD.DIM_HOSPITAL`
- `GOLD.DIM_DIAGNOSIS`
- `GOLD.FACT_ENCOUNTER`
- `GOLD.FACT_READMISSION`
- `GOLD.FACT_CLAIMS`

Views:

- `GOLD.VW_GOLD_ROW_COUNTS`
- `ANALYTICS.VW_READMISSION_RATE`
- `ANALYTICS.VW_AVERAGE_LENGTH_OF_STAY`
- `ANALYTICS.VW_CLAIM_APPROVAL_RATE`
- `ANALYTICS.VW_EXECUTIVE_KPI_SUMMARY`

## Transformation Design

- `DIM_PATIENT` projects patient attributes from `SILVER.SLV_PATIENT`.
- `DIM_HOSPITAL` derives hospital records from distinct Silver encounter hospital IDs and enriches them with demo names and regions.
- `DIM_DIAGNOSIS` derives diagnosis records from distinct Silver diagnosis codes and enriches them with demo descriptions.
- `FACT_ENCOUNTER` joins Silver encounters to hospital and diagnosis dimensions.
- `FACT_READMISSION` sequences encounters by patient with `LEAD(admission_date)` and flags readmissions where the next admission is 0 to 30 days after discharge.
- `FACT_CLAIMS` projects standardized claims from `SILVER.SLV_CLAIM`.

## KPI Rules

- 30-day readmission rate: readmitted encounters divided by discharged encounters.
- Average length of stay: average non-negative `length_of_stay`; negative LOS remains preserved for DQ reporting but excluded from this KPI.
- Claim approval rate: approved claims divided by total claims.

## Execution

Do not run this phase until Phase 3 has completed successfully.

```powershell
snow sql --connection emmwcta-zj29555 --filename snowflake\05_create_gold_models.sql
snow sql --connection emmwcta-zj29555 --filename snowflake\99_validate_phase_4.sql
```

## Expected Row Counts

- `DIM_PATIENT`: 7
- `DIM_HOSPITAL`: 3
- `DIM_DIAGNOSIS`: 6
- `FACT_ENCOUNTER`: 8
- `FACT_READMISSION`: 8
- `FACT_CLAIMS`: 7

## Expected KPI Shape

- `VW_READMISSION_RATE` returns one summary row.
- `VW_AVERAGE_LENGTH_OF_STAY` returns one summary row and excludes negative LOS.
- `VW_CLAIM_APPROVAL_RATE` returns one summary row.
- `VW_EXECUTIVE_KPI_SUMMARY` returns three KPI rows.

