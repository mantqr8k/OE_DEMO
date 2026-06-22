# Provider & Appointment Analytics Extension

## Objective

Extend the Patient 360 platform to include provider productivity, appointment operations, and access-to-care analytics.

This enables demonstration of:

- Provider master data governance
- Appointment data quality
- Operational analytics lineage
- Healthcare workforce optimization
- Access-to-care metrics

---

# Gold Layer Enhancements

## DIM_PROVIDER

Provider dimension.

| Column |
|----------|
| provider_sk |
| provider_id |
| provider_name |
| specialty |
| hospital_id |
| hospital_name |
| license_number |
| license_expiry_date |
| license_status |
| active_flag |

Derived Columns:

### license_status

```sql
CASE
    WHEN license_expiry_date < CURRENT_DATE
    THEN 'EXPIRED'
    ELSE 'ACTIVE'
END
```

---

## FACT_APPOINTMENT

Grain:

One appointment per row.

| Column |
|----------|
| appointment_sk |
| appointment_id |
| patient_sk |
| provider_sk |
| hospital_sk |
| appointment_date |
| appointment_status |
| scheduled_time |
| actual_start_time |
| appointment_duration_minutes |
| wait_time_minutes |
| cancellation_flag |
| no_show_flag |

Derived Columns:

### wait_time_minutes

```sql
DATEDIFF(
    minute,
    scheduled_time,
    actual_start_time
)
```

---

## FACT_PROVIDER_DAILY

Grain:

One provider per day.

| Column |
|----------|
| provider_sk |
| activity_date |
| appointments_booked |
| appointments_completed |
| patients_seen |
| no_show_count |
| cancellation_count |
| utilization_rate |

Purpose:

Provider productivity reporting.

---

## FACT_PROVIDER_MONTHLY

Grain:

One provider per month.

| Column |
|----------|
| provider_sk |
| reporting_month |
| patients_seen |
| encounters_completed |
| appointments_completed |
| no_show_rate |
| utilization_rate |
| readmission_rate |

Purpose:

Executive provider performance dashboard.

---

# Additional Source Data Requirements

## Appointment Data

Required fields:

| Column |
|----------|
| appointment_id |
| patient_id |
| provider_id |
| hospital_id |
| appointment_date |
| scheduled_time |
| actual_start_time |
| appointment_status |

Allowed Status Values:

```text
SCHEDULED
COMPLETED
NO_SHOW
CANCELLED
RESCHEDULED
```

---

## Provider Data

Required fields:

| Column |
|----------|
| provider_id |
| provider_name |
| specialty |
| hospital_id |
| license_number |
| license_expiry_date |

Specialties:

```text
Cardiology
Neurology
Orthopedics
Internal Medicine
Pediatrics
Emergency Medicine
Oncology
Pulmonology
```

---

# Provider Analytics KPIs

## KPI-04

Provider Utilization Rate

Definition:

Percentage of available appointment slots utilized.

Formula:

```text
Booked Appointment Hours
/
Available Appointment Hours
```

Target:

> 75%

---

## KPI-05

Patients Seen per Provider

Definition:

Unique patients treated by provider.

Formula:

```text
Distinct Patients
/
Provider
```

Dimensions:

- Hospital
- Specialty
- Month

---

## KPI-06

Average Encounters per Provider

Formula:

```text
Total Encounters
/
Total Providers
```

---

## KPI-07

Provider Readmission Rate

Definition:

Readmission rate attributed to attending provider.

Formula:

```text
Readmitted Patients
/
Total Discharged Patients
```

Dimensions:

- Provider
- Specialty
- Hospital

Governance Value:

Excellent lineage demonstration.

---

## KPI-08

Provider Credential Compliance Rate

Formula:

```text
Providers With Active Licenses
/
Total Providers
```

Governance Value:

Master Data Governance
Data Quality
Regulatory Compliance

---

## KPI-09

Average Patient Load

Formula:

```text
Active Patients
/
Provider
```

---

# Appointment Analytics KPIs

## KPI-10

Appointment Completion Rate

Formula:

```text
Completed Appointments
/
Total Appointments
```

---

## KPI-11

Appointment No-Show Rate

Formula:

```text
No Show Appointments
/
Total Scheduled Appointments
```

Governance Value:

Demonstrates quality validation on appointment status values.

---

## KPI-12

Appointment Cancellation Rate

Formula:

```text
Cancelled Appointments
/
Total Appointments
```

---

## KPI-13

Average Wait Time

Formula:

```text
Actual Start Time
-
Scheduled Time
```

Unit:

Minutes

---

## KPI-14

Schedule Utilization Rate

Formula:

```text
Booked Slots
/
Available Slots
```

---

## KPI-15

Days to Next Available Appointment

Formula:

```text
Next Available Appointment Date
-
Current Date
```

Governance Value:

Access-to-care metric.

Executive stakeholders frequently monitor this KPI.

---

# Additional Data Quality Rules

## Provider Rules

### DQ008

Provider ID cannot be null

```sql
provider_id IS NOT NULL
```

---

### DQ009

License expiry date required

```sql
license_expiry_date IS NOT NULL
```

---

### DQ010

License must not be expired

```sql
license_expiry_date >= CURRENT_DATE
```

Severity:

HIGH

---

## Appointment Rules

### DQ011

Appointment ID required

```sql
appointment_id IS NOT NULL
```

---

### DQ012

Appointment status validation

```sql
appointment_status IN (
'SCHEDULED',
'COMPLETED',
'NO_SHOW',
'CANCELLED',
'RESCHEDULED'
)
```

---

### DQ013

Actual start time must be after scheduled time

```sql
actual_start_time >= scheduled_time
```

---

### DQ014

Wait time less than 240 minutes

```sql
wait_time_minutes <= 240
```

---

# Governance Dashboard Enhancements

## Provider Governance Dashboard

KPIs:

- Total Providers
- Active Providers
- Expired Licenses
- Credential Compliance %
- Provider Data Quality Score

Charts:

- Providers by Specialty
- Provider Utilization Trend
- License Expiry Trend

---

## Appointment Governance Dashboard

KPIs:

- Total Appointments
- Completion Rate
- No Show Rate
- Cancellation Rate
- Average Wait Time

Charts:

- Appointment Status Distribution
- Wait Time Trend
- Utilization Trend

---

# Lineage Demonstration Additions

## Provider Utilization KPI Lineage

```text
Provider Utilization Dashboard
        |
Provider Utilization KPI
        |
FACT_PROVIDER_MONTHLY
        |
FACT_PROVIDER_DAILY
        |
FACT_APPOINTMENT
        |
SLV_APPOINTMENT
        |
BRZ_APPOINTMENT
        |
Scheduling System
```

---

## No-Show Rate KPI Lineage

```text
Executive Operations Dashboard
        |
No Show Rate KPI
        |
FACT_APPOINTMENT
        |
SLV_APPOINTMENT
        |
BRZ_APPOINTMENT
        |
Scheduling System
```

---

# Impact Analysis Demonstration

Scenario 1

```text
appointment_status renamed to appointment_state
```

Impacted Assets:

- SLV_APPOINTMENT
- FACT_APPOINTMENT
- FACT_PROVIDER_DAILY
- Appointment Dashboard
- Executive Operations Dashboard

---

Scenario 2

```text
license_expiry_date datatype changed
```

Impacted Assets:

- SLV_PROVIDER
- DIM_PROVIDER
- Credential Compliance KPI
- Provider Governance Dashboard

---

# Demo Scenarios

## Scenario 6

Provider Credential Compliance

Demonstrate:

- Expired licenses
- Quality rule violations
- Governance alerts

---

## Scenario 7

Appointment No-Show Analytics

Demonstrate:

- Appointment quality validation
- KPI calculation
- Operational dashboard

---

## Scenario 8

Provider Utilization Analysis

Demonstrate:

- Lineage tracing
- Impact analysis
- Executive reporting
