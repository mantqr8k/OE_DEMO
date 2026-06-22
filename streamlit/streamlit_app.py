# Healthcare Governance & Analytics Dashboard for Snowflake Snowsight
# Co-authored with CoCo
import pandas as pd
import streamlit as st

st.set_page_config(page_title="Healthcare Governance Dashboard", layout="wide")

conn = st.connection("snowflake")
session = conn.session()
session.sql("USE DATABASE HC_GOV_DEMO").collect()


@st.cache_data(ttl=300)
def run_query(query: str) -> pd.DataFrame:
    return session.sql(query).to_pandas()


def load_data():
    queries = {
        "executive_kpis": "SELECT * FROM HC_GOV_DEMO.ANALYTICS.VW_EXECUTIVE_KPI_SUMMARY",
        "readmission_rate": "SELECT * FROM HC_GOV_DEMO.ANALYTICS.VW_READMISSION_RATE",
        "length_of_stay": "SELECT * FROM HC_GOV_DEMO.ANALYTICS.VW_AVERAGE_LENGTH_OF_STAY",
        "claim_approval": "SELECT * FROM HC_GOV_DEMO.ANALYTICS.VW_CLAIM_APPROVAL_RATE",
        "provider_list": """
            SELECT PROVIDER_ID, PROVIDER_NAME, SPECIALTY, HOSPITAL_ID,
                   LICENSE_NUMBER, LICENSE_EXPIRY_DATE, LICENSE_STATUS, ACTIVE_FLAG
            FROM HC_GOV_DEMO.GOLD.DIM_PROVIDER ORDER BY PROVIDER_ID
        """,
        "provider_monthly": """
            SELECT REPORTING_MONTH, PROVIDER_SK, PATIENTS_SEEN, ENCOUNTERS_COMPLETED,
                   APPOINTMENTS_COMPLETED, NO_SHOW_RATE, UTILIZATION_RATE
            FROM HC_GOV_DEMO.GOLD.FACT_PROVIDER_MONTHLY ORDER BY REPORTING_MONTH
        """,
        "appointment_status": """
            SELECT APPOINTMENT_STATUS, COUNT(*) AS COUNT,
                   ROUND(AVG(WAIT_TIME_MINUTES), 2) AS AVG_WAIT_TIME
            FROM HC_GOV_DEMO.GOLD.FACT_APPOINTMENT
            GROUP BY APPOINTMENT_STATUS ORDER BY COUNT DESC
        """,
        "appointment_trend": """
            SELECT APPOINTMENT_DATE, COUNT(*) AS TOTAL_APPOINTMENTS,
                   ROUND(AVG(WAIT_TIME_MINUTES), 2) AS AVG_WAIT_TIME
            FROM HC_GOV_DEMO.GOLD.FACT_APPOINTMENT
            GROUP BY APPOINTMENT_DATE ORDER BY APPOINTMENT_DATE
        """,
        "readmission_trend": """
            SELECT DISCHARGE_DATE, SUM(READMISSION_FLAG) AS READMISSIONS,
                   COUNT(*) AS TOTAL_ENCOUNTERS
            FROM HC_GOV_DEMO.GOLD.FACT_READMISSION
            GROUP BY DISCHARGE_DATE ORDER BY DISCHARGE_DATE
        """,
        "encounter_volume": """
            SELECT HOSPITAL_SK, COUNT(*) AS ENCOUNTER_COUNT
            FROM HC_GOV_DEMO.GOLD.FACT_ENCOUNTER
            GROUP BY HOSPITAL_SK ORDER BY ENCOUNTER_COUNT DESC
        """,
    }
    results = {}
    for name, query in queries.items():
        try:
            results[name] = run_query(query)
        except Exception as e:
            st.warning(f"Query '{name}' failed: {e}")
            results[name] = pd.DataFrame()
    return results


def render_executive_summary(datasets):
    st.header("Executive Summary")
    st.markdown("Healthcare analytics KPIs from the Gold and Analytics layers.")

    kpi_df = datasets["executive_kpis"]
    if not kpi_df.empty:
        columns = kpi_df.columns.tolist()
        records = kpi_df.to_dict("records")
        if "KPI_NAME" in columns and "KPI_VALUE" in columns:
            cols = st.columns(min(len(records), 4))
            for idx, record in enumerate(records):
                cols[idx % 4].metric(record["KPI_NAME"], record["KPI_VALUE"])
        else:
            st.dataframe(kpi_df)
    else:
        st.warning("Executive KPI view returned no data.")

    st.subheader("Key analytics summaries")
    col1, col2 = st.columns(2)

    readmission_df = datasets["readmission_rate"]
    col1.metric(
        "Readmission rate",
        readmission_df["READMISSION_RATE"].iloc[0]
        if not readmission_df.empty and "READMISSION_RATE" in readmission_df.columns
        else "n/a",
    )

    los_df = datasets["length_of_stay"]
    col1.metric(
        "Average LOS",
        los_df["AVERAGE_LENGTH_OF_STAY"].iloc[0]
        if not los_df.empty and "AVERAGE_LENGTH_OF_STAY" in los_df.columns
        else "n/a",
    )

    approval_df = datasets["claim_approval"]
    col2.metric(
        "Claim approval",
        approval_df["CLAIM_APPROVAL_RATE"].iloc[0]
        if not approval_df.empty and "CLAIM_APPROVAL_RATE" in approval_df.columns
        else "n/a",
    )

    trend_df = datasets["appointment_trend"]
    col2.metric(
        "Appointment volume",
        int(trend_df["TOTAL_APPOINTMENTS"].sum()) if not trend_df.empty else 0,
    )

    with st.expander("Raw executive KPI results"):
        st.dataframe(kpi_df)

    with st.expander("Appointment trend"):
        if not trend_df.empty:
            st.line_chart(trend_df.set_index("APPOINTMENT_DATE")["TOTAL_APPOINTMENTS"])

    with st.expander("Provider monthly utilization"):
        prov_df = datasets["provider_monthly"]
        if not prov_df.empty:
            st.line_chart(prov_df.set_index("REPORTING_MONTH")["UTILIZATION_RATE"])
        else:
            st.warning("Provider monthly data not available.")


def render_provider_governance(datasets):
    st.header("Provider Governance")
    st.markdown(
        "Provider quality and compliance metrics derived from the Gold provider dimension "
        "and monthly activity fact table."
    )

    provider_df = datasets["provider_list"]
    if provider_df.empty:
        st.warning("No provider data available.")
        return

    total_providers = provider_df.shape[0]
    active_count = (
        int(provider_df[provider_df["ACTIVE_FLAG"] == True].shape[0])
        if "ACTIVE_FLAG" in provider_df.columns
        else "n/a"
    )
    expired_count = (
        int(provider_df[provider_df["LICENSE_STATUS"] == "EXPIRED"].shape[0])
        if "LICENSE_STATUS" in provider_df.columns
        else "n/a"
    )

    m1, m2, m3 = st.columns(3)
    m1.metric("Total Providers", total_providers)
    m2.metric("Active Providers", active_count)
    m3.metric("Expired Licenses", expired_count)

    st.subheader("Provider details")
    st.dataframe(provider_df, use_container_width=True)

    prov_monthly = datasets["provider_monthly"]
    if not prov_monthly.empty:
        st.subheader("Monthly Utilization Trend")
        provider_util = (
            prov_monthly.groupby("REPORTING_MONTH")["UTILIZATION_RATE"]
            .mean()
            .reset_index()
        )
        st.line_chart(provider_util.set_index("REPORTING_MONTH")["UTILIZATION_RATE"])

    if not provider_df.empty and "SPECIALTY" in provider_df.columns:
        st.subheader("Providers by Specialty")
        specialty_counts = provider_df["SPECIALTY"].value_counts().reset_index()
        specialty_counts.columns = ["SPECIALTY", "COUNT"]
        st.bar_chart(specialty_counts.set_index("SPECIALTY"))


def render_appointment_operations(datasets):
    st.header("Appointment Operations")
    st.markdown("Appointment-side operations metrics from the Gold appointment fact table.")

    status_df = datasets["appointment_status"]
    if not status_df.empty:
        st.subheader("Appointment status breakdown")
        st.dataframe(status_df, use_container_width=True)
        st.bar_chart(status_df.set_index("APPOINTMENT_STATUS")["COUNT"])
    else:
        st.warning("No appointment status data available.")

    trend_df = datasets["appointment_trend"]
    if not trend_df.empty:
        st.subheader("Daily appointment volume")
        st.line_chart(trend_df.set_index("APPOINTMENT_DATE")["TOTAL_APPOINTMENTS"])
        st.subheader("Average wait time trend")
        st.line_chart(trend_df.set_index("APPOINTMENT_DATE")["AVG_WAIT_TIME"])
    else:
        st.warning("No appointment trend data available.")


def render_readmission_analytics(datasets):
    st.header("Readmission Analytics")
    st.markdown("Analytics for readmission and encounter volume from the Gold layer.")

    readmission_df = datasets["readmission_trend"]
    if not readmission_df.empty:
        st.subheader("Readmissions over time")
        st.line_chart(readmission_df.set_index("DISCHARGE_DATE")["READMISSIONS"])

        encounter_df = datasets["encounter_volume"]
        if not encounter_df.empty:
            st.subheader("Encounter volume by hospital")
            st.bar_chart(encounter_df.set_index("HOSPITAL_SK")["ENCOUNTER_COUNT"])

        st.subheader("Readmission rate details")
        st.dataframe(readmission_df, use_container_width=True)
    else:
        st.warning("No readmission trend data available.")


def main():
    st.title("Healthcare Governance & Analytics Dashboard")
    st.markdown(
        "A Streamlit presentation layer for Snowflake Gold analytics and governance metrics."
    )

    page = st.sidebar.selectbox(
        "Select dashboard page",
        [
            "Executive Summary",
            "Provider Governance",
            "Appointment Operations",
            "Readmission Analytics",
        ],
    )

    with st.spinner("Loading data from Snowflake..."):
        datasets = load_data()

    if page == "Executive Summary":
        render_executive_summary(datasets)
    elif page == "Provider Governance":
        render_provider_governance(datasets)
    elif page == "Appointment Operations":
        render_appointment_operations(datasets)
    elif page == "Readmission Analytics":
        render_readmission_analytics(datasets)

    st.sidebar.markdown("---")
    st.sidebar.markdown(
        "Built on `HC_GOV_DEMO` Gold objects: `GOLD.FACT_APPOINTMENT`, "
        "`GOLD.FACT_PROVIDER_MONTHLY`, `GOLD.FACT_READMISSION`, "
        "`GOLD.DIM_PROVIDER`, and analytics views in `ANALYTICS`."
    )


if __name__ == "__main__":
    main()
