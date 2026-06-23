# Report page build guide

Step-by-step instructions to replicate each Streamlit page in Power BI Desktop after opening `HealthcareGovernance.pbip` and refreshing data.

Enable **View → Page view → Fit to page** and use a **16:9** canvas.

---

## Page 1: Executive Summary

**Streamlit equivalent:** `render_executive_summary()`

### KPI cards (top row)

| Visual | Field | Notes |
| --- | --- | --- |
| Card | `VW_EXECUTIVE_KPI_SUMMARY[KPI_VALUE]` with filter `KPI_NAME = "30-Day Readmission Rate"` | Or use `VW_READMISSION_RATE[READMISSION_RATE]` |
| Card | `VW_AVERAGE_LENGTH_OF_STAY[AVERAGE_LENGTH_OF_STAY]` | Average LOS |
| Card | `VW_CLAIM_APPROVAL_RATE[CLAIM_APPROVAL_RATE]` | Claim approval |
| Card | `_Metrics[Appointment Volume]` | Total appointments |

### Executive KPI matrix (optional)

- **Visual:** Matrix
- **Rows:** `VW_EXECUTIVE_KPI_SUMMARY[KPI_NAME]`
- **Values:** `VW_EXECUTIVE_KPI_SUMMARY[KPI_VALUE]`, `NUMERATOR`, `DENOMINATOR`

### Charts

| Visual | Axis | Values |
| --- | --- | --- |
| Line chart | `FACT_APPOINTMENT[APPOINTMENT_DATE]` | `COUNT` of rows (or `_Metrics[Appointment Volume]` by date) |
| Line chart | `FACT_PROVIDER_MONTHLY[REPORTING_MONTH]` | `AVERAGE` of `UTILIZATION_RATE` (or `_Metrics[Avg Monthly Utilization]`) |

---

## Page 2: Provider Governance

**Streamlit equivalent:** `render_provider_governance()`

### KPI cards

| Visual | Field |
| --- | --- |
| Card | `_Metrics[Total Providers]` |
| Card | `_Metrics[Active Providers]` |
| Card | `_Metrics[Expired Licenses]` |

### Table

- **Visual:** Table
- **Columns:** `DIM_PROVIDER` — PROVIDER_ID, PROVIDER_NAME, SPECIALTY, HOSPITAL_ID, LICENSE_NUMBER, LICENSE_EXPIRY_DATE, LICENSE_STATUS, ACTIVE_FLAG

### Charts

| Visual | Axis | Values |
| --- | --- | --- |
| Line chart | `FACT_PROVIDER_MONTHLY[REPORTING_MONTH]` | Average `UTILIZATION_RATE` |
| Clustered bar | `DIM_PROVIDER[SPECIALTY]` | `COUNT` of PROVIDER_ID |

---

## Page 3: Appointment Operations

**Streamlit equivalent:** `render_appointment_operations()`

### Status breakdown

- **Table:** `APPOINTMENT_STATUS`, Count of appointments, Average `WAIT_TIME_MINUTES`
- **Clustered bar:** Axis = `FACT_APPOINTMENT[APPOINTMENT_STATUS]`, Values = Count

### Trends

| Visual | Axis | Values |
| --- | --- | --- |
| Line chart | `FACT_APPOINTMENT[APPOINTMENT_DATE]` | Count of appointments |
| Line chart | `FACT_APPOINTMENT[APPOINTMENT_DATE]` | Average `WAIT_TIME_MINUTES` |

---

## Page 4: Readmission Analytics

**Streamlit equivalent:** `render_readmission_analytics()`

### Charts

| Visual | Axis | Values |
| --- | --- | --- |
| Line chart | `FACT_READMISSION[DISCHARGE_DATE]` | Sum `READMISSION_FLAG` (or `_Metrics[Total Readmissions]`) |
| Clustered bar | `DIM_HOSPITAL[HOSPITAL_NAME]` | Count from `FACT_ENCOUNTER` (use relationship) |

### Detail table

- **Table:** `FACT_READMISSION` — DISCHARGE_DATE, READMISSION_FLAG, and add calculated column or show SUM by discharge date in a matrix

---

## Navigation

Add a **Page navigator** visual on each page, or use the default page tabs. Streamlit used a sidebar `selectbox`; in Power BI, page tabs or a bookmark navigator provide the same UX.

---

## Theme suggestion

Use a healthcare-friendly theme (teal/blue) via **View → Themes → Customize current theme** to differentiate from default Streamlit styling.
