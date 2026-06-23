# Healthcare Governance Power BI Dashboard

Power BI equivalent of `streamlit/streamlit_app.py`. Connects to the same `HC_GOV_DEMO` Snowflake objects and reproduces all four dashboard pages.

## Quick start

1. Install [Power BI Desktop](https://powerbi.microsoft.com/desktop/) (June 2024 or later recommended for PBIP support).
2. Enable **Power BI Project (.pbip)** and **TMDL** preview features:
   - **File → Options → Preview features**
   - Turn on **Power BI Project (.pbip) save option**
   - Turn on **Store semantic model in TMDL format**
3. Open `powerbi/HealthcareGovernance.pbip` in Power BI Desktop.
4. When prompted, set the three Snowflake connection parameters:
   - `SnowflakeHost` — e.g. `xy12345.us-east-1.snowflakecomputing.com`
   - `SnowflakeWarehouse` — e.g. `COMPUTE_WH` or `HC_GOV_WH`
   - `SnowflakeRole` — optional; leave blank or use `HC_ANALYST_ROLE`
5. Sign in with your Snowflake credentials when Power Query loads data.
6. **Refresh** the model (**Home → Refresh**).
7. Add visuals to the four pre-created report pages using **`REPORT_PAGES.md`** (field-by-field mapping from Streamlit).

## Project structure

```text
powerbi/
├── HealthcareGovernance.pbip
├── HealthcareGovernance.SemanticModel/   # TMDL data model + DAX measures
├── HealthcareGovernance.Report/          # Four report pages (PBIR)
├── dax/measures.dax                      # Standalone measure definitions
├── power_query/                          # M scripts (reference / Tabular Editor)
├── REPORT_PAGES.md                       # Visual build guide (Streamlit → Power BI)
└── README.md
```

## Page mapping (Streamlit → Power BI)

| Streamlit page | Power BI page | Key visuals |
| --- | --- | --- |
| Executive Summary | Executive Summary | KPI cards, appointment trend line, utilization trend |
| Provider Governance | Provider Governance | Provider counts, detail table, specialty bar, utilization line |
| Appointment Operations | Appointment Operations | Status table + bar, volume line, wait-time line |
| Readmission Analytics | Readmission Analytics | Readmissions line, encounters by hospital bar, detail table |

## Data sources

Same queries as the Streamlit app:

| Table / view | Snowflake object |
| --- | --- |
| VW_EXECUTIVE_KPI_SUMMARY | `HC_GOV_DEMO.ANALYTICS.VW_EXECUTIVE_KPI_SUMMARY` |
| VW_READMISSION_RATE | `HC_GOV_DEMO.ANALYTICS.VW_READMISSION_RATE` |
| VW_AVERAGE_LENGTH_OF_STAY | `HC_GOV_DEMO.ANALYTICS.VW_AVERAGE_LENGTH_OF_STAY` |
| VW_CLAIM_APPROVAL_RATE | `HC_GOV_DEMO.ANALYTICS.VW_CLAIM_APPROVAL_RATE` |
| DIM_PROVIDER | `HC_GOV_DEMO.GOLD.DIM_PROVIDER` |
| FACT_PROVIDER_MONTHLY | `HC_GOV_DEMO.GOLD.FACT_PROVIDER_MONTHLY` |
| FACT_APPOINTMENT | `HC_GOV_DEMO.GOLD.FACT_APPOINTMENT` |
| FACT_READMISSION | `HC_GOV_DEMO.GOLD.FACT_READMISSION` |
| FACT_ENCOUNTER | `HC_GOV_DEMO.GOLD.FACT_ENCOUNTER` |
| DIM_HOSPITAL | `HC_GOV_DEMO.GOLD.DIM_HOSPITAL` |

Relationships:

- `FACT_PROVIDER_MONTHLY[PROVIDER_SK]` → `DIM_PROVIDER[PROVIDER_SK]`
- `FACT_ENCOUNTER[HOSPITAL_SK]` → `DIM_HOSPITAL[HOSPITAL_SK]`

## DAX measures

Core measures mirror Streamlit metrics and analytics views. See `dax/measures.dax` for the full list. Examples:

- **Readmission Rate** — 30-day readmission rate from `FACT_READMISSION`
- **Average LOS** — average length of stay (non-negative encounters only)
- **Claim Approval Rate** — approved claims / total claims
- **Total Providers**, **Active Providers**, **Expired Licenses**
- **Appointment Volume**, **Average Wait Time**

## DirectQuery alternative

The project uses **Import** mode for simpler demo refresh. To switch a table to DirectQuery:

1. Open **Transform data** → select the query → **Advanced options**.
2. Or recreate the connection with **DirectQuery** when using **Get Data → Snowflake**.

## Publish to Fabric / Power BI Service

1. **Publish** from Power BI Desktop to your workspace.
2. Configure the Snowflake data source credentials in the service (**Settings → Semantic model → Data source credentials**).
3. Schedule refresh if using Import mode.

## Troubleshooting

| Issue | Fix |
| --- | --- |
| Snowflake connector missing | Install from **Get Data** or Microsoft Store Snowflake connector |
| Empty KPI cards | Run Gold load procedures in Snowflake (`CALL GOLD.LOAD_ALL_GOLD();`) |
| Role / warehouse errors | Set `SnowflakeWarehouse` and `SnowflakeRole` parameters |
| PBIP won't open | Enable PBIP + TMDL preview features in Power BI Desktop |

## Related docs

- Streamlit app: `streamlit/streamlit_app.py`
- Gold layer: `docs/phase_4_gold_setup.md`
- Demo blueprint: `AGENTS.md`
