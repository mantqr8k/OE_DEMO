// Snowflake connection parameters (set when opening PBIP in Power BI Desktop)
// SnowflakeHost = "YOUR_ACCOUNT.snowflakecomputing.com"
// SnowflakeWarehouse = "COMPUTE_WH"
// SnowflakeRole = null  // optional, e.g. HC_ANALYST_ROLE

// Shared connection
let
    Snowflake_HC_GOV = Snowflake.Databases(SnowflakeHost, "HC_GOV_DEMO", [Role=SnowflakeRole, Warehouse=SnowflakeWarehouse])
in
    Snowflake_HC_GOV

// Example: DIM_PROVIDER
let
    Source = Value.NativeQuery(
        Snowflake_HC_GOV,
        "SELECT PROVIDER_ID, PROVIDER_NAME, SPECIALTY, HOSPITAL_ID, LICENSE_NUMBER, LICENSE_EXPIRY_DATE, LICENSE_STATUS, ACTIVE_FLAG, PROVIDER_SK FROM HC_GOV_DEMO.GOLD.DIM_PROVIDER ORDER BY PROVIDER_ID",
        null,
        [EnableFolding=true]
    )
in
    Source

// Example: Appointment status aggregation (Streamlit GROUP BY query)
let
    Source = Value.NativeQuery(
        Snowflake_HC_GOV,
        "SELECT APPOINTMENT_STATUS, COUNT(*) AS COUNT, ROUND(AVG(WAIT_TIME_MINUTES), 2) AS AVG_WAIT_TIME FROM HC_GOV_DEMO.GOLD.FACT_APPOINTMENT GROUP BY APPOINTMENT_STATUS ORDER BY COUNT DESC",
        null,
        [EnableFolding=true]
    )
in
    Source
