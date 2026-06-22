# Healthcare Data Governance Demo Blueprint

## Patient 360 and Readmission Analytics Platform

# Objective

Demonstrate end-to-end Data Governance capabilities using a realistic healthcare analytics platform.

Governance Capabilities Demonstrated:

1. Automated PHI/PII Classification
2. Data Quality Monitoring
3. End-to-End Data Lineage
4. Impact Analysis
5. Shift-Left Governance

---

# Business Scenario

A healthcare provider network operates multiple hospitals and clinics.

Data originates from:

* Electronic Health Record (EHR)
* Laboratory Information System (LIS)
* Pharmacy System
* Claims System
* Appointment Scheduling System

The organization wants to:

* Build a trusted Patient 360 platform
* Monitor patient outcomes
* Analyze readmissions
* Protect PHI data
* Improve data quality
* Establish regulatory compliance

---

# Demo Architecture

```text
Source Systems
------------------------------------
EHR
Laboratory
Pharmacy
Claims
Scheduling
------------------------------------
             |
             v

Bronze Layer
(Raw Ingestion)

             |
             v

Silver Layer
(Standardized & Cleansed)

             |
             v

Gold Layer
(Business Metrics & Analytics)

             |
             v

Governance Services
------------------------------------
Classification
Data Quality
Lineage
Catalog
Policy Management
------------------------------------

             |
             v

Analytics Layer
------------------------------------
Patient 360 Dashboard
Clinical Quality Dashboard
Readmission Dashboard
Executive Dashboard
------------------------------------
```

---

# BRONZE LAYER

## Purpose

Store raw source data exactly as received.

No transformations.

Retain full auditability.

---

# BRZ_PATIENT_MASTER

Source: EHR

| Column                | Type      |
| --------------------- | --------- |
| patient_id            | VARCHAR   |
| medical_record_number | VARCHAR   |
| patient_first_name    | VARCHAR   |
| patient_last_name     | VARCHAR   |
| dob                   | DATE      |
| gender                | VARCHAR   |
| ssn                   | VARCHAR   |
| phone_number          | VARCHAR   |
| email_address         | VARCHAR   |
| address_line1         | VARCHAR   |
| city                  | VARCHAR   |
| state                 | VARCHAR   |
| zip_code              | VARCHAR   |
| ingestion_timestamp   | TIMESTAMP |

---

# BRZ_PATIENT_ENCOUNTER

Source: EHR

| Column              | Type      |
| ------------------- | --------- |
| encounter_id        | VARCHAR   |
| patient_id          | VARCHAR   |
| admission_date      | DATE      |
| discharge_date      | DATE      |
| encounter_type      | VARCHAR   |
| attending_physician | VARCHAR   |
| hospital_id         | VARCHAR   |
| diagnosis_code      | VARCHAR   |
| ingestion_timestamp | TIMESTAMP |

---

# BRZ_LAB_RESULTS

Source: Laboratory System

| Column              | Type      |
| ------------------- | --------- |
| lab_result_id       | VARCHAR   |
| patient_id          | VARCHAR   |
| encounter_id        | VARCHAR   |
| test_code           | VARCHAR   |
| test_name           | VARCHAR   |
| result_value        | NUMBER    |
| result_unit         | VARCHAR   |
| result_date         | DATE      |
| ingestion_timestamp | TIMESTAMP |

---

# BRZ_PHARMACY_ORDERS

Source: Pharmacy System

| Column                | Type      |
| --------------------- | --------- |
| prescription_id       | VARCHAR   |
| patient_id            | VARCHAR   |
| medication_name       | VARCHAR   |
| dosage                | VARCHAR   |
| prescription_date     | DATE      |
| prescribing_physician | VARCHAR   |
| ingestion_timestamp   | TIMESTAMP |

---

# BRZ_CLAIMS

Source: Claims System

| Column              | Type      |
| ------------------- | --------- |
| claim_id            | VARCHAR   |
| patient_id          | VARCHAR   |
| insurance_id        | VARCHAR   |
| claim_amount        | NUMBER    |
| claim_status        | VARCHAR   |
| claim_date          | DATE      |
| ingestion_timestamp | TIMESTAMP |

---

# SILVER LAYER

## Purpose

Standardize and validate data.

Apply:

* Data quality rules
* Conformed dimensions
* Standardized business definitions

---

# SLV_PATIENT

Master Patient Entity

| Column                |
| --------------------- |
| patient_sk            |
| patient_id            |
| medical_record_number |
| patient_name          |
| dob                   |
| age                   |
| gender                |
| city                  |
| state                 |
| active_flag           |

Transformations:

* Deduplicate patient records
* Standardize names
* Calculate age
* Resolve duplicates

---

# SLV_ENCOUNTER

| Column         |
| -------------- |
| encounter_sk   |
| encounter_id   |
| patient_sk     |
| admission_date |
| discharge_date |
| length_of_stay |
| diagnosis_code |
| hospital_id    |
| encounter_type |

Transformations:

* Calculate LOS
* Standardize encounter categories

---

# SLV_LAB_RESULT

| Column            |
| ----------------- |
| lab_result_sk     |
| encounter_sk      |
| patient_sk        |
| test_code         |
| test_name         |
| normalized_result |
| result_unit       |
| result_date       |

Transformations:

* Standardize units
* Normalize values

---

# SLV_MEDICATION

| Column            |
| ----------------- |
| medication_sk     |
| patient_sk        |
| medication_name   |
| dosage            |
| prescription_date |

---

# SLV_CLAIM

| Column       |
| ------------ |
| claim_sk     |
| patient_sk   |
| insurance_id |
| claim_amount |
| claim_status |
| claim_date   |

---

# SILVER DATA QUALITY RULES

## Patient Rules

### DQ001

Patient ID cannot be null

```sql
patient_id IS NOT NULL
```

### DQ002

DOB cannot be future dated

```sql
dob <= CURRENT_DATE
```

### DQ003

Age must be between 0 and 120

```sql
age BETWEEN 0 AND 120
```

---

## Encounter Rules

### DQ004

Discharge date >= Admission date

```sql
discharge_date >= admission_date
```

### DQ005

Length of stay >= 0

```sql
length_of_stay >= 0
```

---

## Lab Rules

### DQ006

Result value cannot be null

```sql
result_value IS NOT NULL
```

### DQ007

Blood glucose value range

```sql
normalized_result BETWEEN 40 AND 600
```

---

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

# GOLD LAYER

## Purpose

Business-ready analytics models.

---

# DIM_PATIENT

Patient Dimension

| Column       |
| ------------ |
| patient_sk   |
| patient_id   |
| patient_name |
| age          |
| gender       |
| city         |
| state        |

---

# DIM_HOSPITAL

| Column          |
| --------------- |
| hospital_sk     |
| hospital_id     |
| hospital_name   |
| hospital_region |

---

# DIM_DIAGNOSIS

| Column                |
| --------------------- |
| diagnosis_sk          |
| diagnosis_code        |
| diagnosis_description |

---

# DIM_PROVIDER

Provider Dimension

| Column              |
| ------------------- |
| provider_sk         |
| provider_id         |
| provider_name       |
| specialty           |
| hospital_id         |
| hospital_name       |
| license_number      |
| license_expiry_date |
| license_status      |
| active_flag         |

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

# FACT_ENCOUNTER

| Column         |
| -------------- |
| encounter_sk   |
| patient_sk     |
| hospital_sk    |
| diagnosis_sk   |
| admission_date |
| discharge_date |
| length_of_stay |

Grain:

One encounter per row.

---

# FACT_READMISSION

| Column              |
| ------------------- |
| patient_sk          |
| encounter_sk        |
| hospital_sk         |
| discharge_date      |
| next_admission_date |
| days_between_visits |
| readmission_flag    |

Business Logic:

```sql
CASE
WHEN days_between_visits <= 30
THEN 1
ELSE 0
END
```

---

# FACT_CLAIMS

| Column       |
| ------------ |
| claim_sk     |
| patient_sk   |
| claim_amount |
| claim_status |

---

# FACT_APPOINTMENT

Grain:

One appointment per row.

| Column                      |
| --------------------------- |
| appointment_sk              |
| appointment_id              |
| patient_sk                  |
| provider_sk                 |
| hospital_sk                 |
| appointment_date            |
| appointment_status          |
| scheduled_time              |
| actual_start_time           |
| appointment_duration_minutes |
| wait_time_minutes           |
| cancellation_flag           |
| no_show_flag                |

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

# FACT_PROVIDER_DAILY

Grain:

One provider per day.

| Column                 |
| ---------------------- |
| provider_sk            |
| activity_date          |
| appointments_booked    |
| appointments_completed |
| patients_seen          |
| no_show_count          |
| cancellation_count     |
| utilization_rate       |

Purpose:

Provider productivity reporting.

---

# FACT_PROVIDER_MONTHLY

Grain:

One provider per month.

| Column                |
| --------------------- |
| provider_sk           |
| reporting_month       |
| patients_seen         |
| encounters_completed  |
| appointments_completed |
| no_show_rate          |
| utilization_rate      |
| readmission_rate      |

Purpose:

Executive provider performance dashboard.

---

# BUSINESS KPIs

## KPI 1

30-Day Readmission Rate

Formula:

```text
Readmitted Patients /
Total Discharged Patients
```

---

## KPI 2

Average Length of Stay

Formula:

```text
Total LOS /
Total Encounters
```

---

## KPI 3

Claim Approval Rate

Formula:

```text
Approved Claims /
Total Claims
```

---

## KPI 4

Provider Utilization Rate

Definition:

Percentage of available appointment slots utilized.

Formula:

```text
Booked Appointment Hours /
Available Appointment Hours
```

Target:

> 75%

---

## KPI 5

Patients Seen per Provider

Definition:

Unique patients treated by provider.

Formula:

```text
Distinct Patients /
Provider
```

Dimensions:

* Hospital
* Specialty
* Month

---

## KPI 6

Average Encounters per Provider

Formula:

```text
Total Encounters /
Total Providers
```

---

## KPI 7

Provider Readmission Rate

Definition:

Readmission rate attributed to attending provider.

Formula:

```text
Readmitted Patients /
Total Discharged Patients
```

Dimensions:

* Provider
* Specialty
* Hospital

Governance Value:

Excellent lineage demonstration.

---

## KPI 8

Provider Credential Compliance Rate

Formula:

```text
Providers With Active Licenses /
Total Providers
```

Governance Value:

Master Data Governance, Data Quality, Regulatory Compliance

---

## KPI 9

Average Patient Load

Formula:

```text
Active Patients /
Provider
```

---

## KPI 10

Appointment Completion Rate

Formula:

```text
Completed Appointments /
Total Appointments
```

---

## KPI 11

Appointment No-Show Rate

Formula:

```text
No Show Appointments /
Total Scheduled Appointments
```

Governance Value:

Demonstrates quality validation on appointment status values.

---

## KPI 12

Appointment Cancellation Rate

Formula:

```text
Cancelled Appointments /
Total Appointments
```

---

## KPI 13

Average Wait Time

Formula:

```text
Actual Start Time -
Scheduled Time
```

Unit:

Minutes

---

## KPI 14

Schedule Utilization Rate

Formula:

```text
Booked Slots /
Available Slots
```

---

## KPI 15

Days to Next Available Appointment

Formula:

```text
Next Available Appointment Date -
Current Date
```

Governance Value:

Access-to-care metric. Executive stakeholders frequently monitor this KPI.

---

# DATA CLASSIFICATION DEMO

## Classification Scan Targets

### PHI

Columns:

* patient_first_name
* patient_last_name
* patient_name
* dob
* medical_record_number
* phone_number
* address_line1

---

### Restricted

Columns:

* ssn

---

### Sensitive

Columns:

* insurance_id
* diagnosis_code

---

# Tag Taxonomy

```text
PHI
PII
SENSITIVE
RESTRICTED
CONFIDENTIAL
PUBLIC
```

---

# Dynamic Masking Demonstration

## Physician Role

Visible:

```text
John Smith
DOB: 1985-01-15
MRN: 1028374
```

---

## Analyst Role

Masked:

```text
J*** S****
DOB: ******
MRN: ******74
```

---

# DATA QUALITY DEMO

Inject Sample Errors

## Error 1

```text
patient_id = NULL
```

## Error 2

```text
dob = 2035-01-01
```

## Error 3

```text
admission_date = 2026-01-15
discharge_date = 2026-01-10
```

## Error 4

```text
blood_glucose = 9999
```

---

# Demonstrate

1. Rule violation detection
2. Failed record capture
3. Data quality score
4. Alert creation
5. Steward assignment

---

# LINEAGE DEMO

## Business KPI 1

30-Day Readmission Rate

Lineage Flow

```text
Executive Dashboard
        |
Readmission KPI
        |
FACT_READMISSION
        |
SLV_ENCOUNTER
        |
BRZ_PATIENT_ENCOUNTER
        |
EHR System
```

---

## Business KPI 2

Provider Utilization Rate

Lineage Flow

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

## Business KPI 3

No-Show Rate

Lineage Flow

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

# Column-Level Lineage

readmission_flag

Derived From:

```text
admission_date
discharge_date
patient_id
```

---

wait_time_minutes

Derived From:

```text
scheduled_time
actual_start_time
```

---

license_status

Derived From:

```text
license_expiry_date
CURRENT_DATE
```

---

# IMPACT ANALYSIS DEMO

## Scenario 1

Simulate Change

```text
admission_date renamed to admit_dt
```

Show Impacted Assets

* SLV_ENCOUNTER
* FACT_ENCOUNTER
* FACT_READMISSION
* Readmission Dashboard
* Executive KPI Dashboard

---

## Scenario 2

Simulate Change

```text
appointment_status renamed to appointment_state
```

Show Impacted Assets

* SLV_APPOINTMENT
* FACT_APPOINTMENT
* FACT_PROVIDER_DAILY
* Appointment Dashboard
* Executive Operations Dashboard

---

## Scenario 3

Simulate Change

```text
license_expiry_date datatype changed
```

Show Impacted Assets

* SLV_PROVIDER
* DIM_PROVIDER
* Credential Compliance KPI
* Provider Governance Dashboard

---

# SHIFT-LEFT GOVERNANCE DEMO

Workflow

```text
New Dataset Arrives
        |
Schema Registration
        |
PHI Classification
        |
Quality Rule Generation
        |
Lineage Capture
        |
Governance Review
        |
Production Release
```

---

# DEMO SCENARIOS

## Scenario 1

PHI Classification

Demonstrate:

* Automatic classification
* Tag creation
* Masking

---

## Scenario 2

Data Quality Failure

Inject:

```text
patient_id = NULL

dob = 2035-01-01

blood_glucose = 9999
```

Demonstrate:

* Rule violations
* Quality score reduction
* Stewardship workflow

---

## Scenario 3

Readmission KPI Lineage

Trace:

```text
Readmission Dashboard
 ->
FACT_READMISSION
 ->
SLV_ENCOUNTER
 ->
BRZ_PATIENT_ENCOUNTER
 ->
EHR
```

---

## Scenario 4

Impact Analysis

Rename:

```text
admission_date
```

Demonstrate affected assets.

---

## Scenario 5

Audit Investigation

Show:

* Analyst accesses PHI
* Audit log generated
* Policy evaluation triggered

---

## Scenario 6

Provider Credential Compliance

Demonstrate:

* Expired licenses
* Quality rule violations
* Governance alerts

---

## Scenario 7

Appointment No-Show Analytics

Demonstrate:

* Appointment quality validation
* KPI calculation
* Operational dashboard

---

## Scenario 8

Provider Utilization Analysis

Demonstrate:

* Lineage tracing
* Impact analysis
* Executive reporting

---

# SEED DATA REQUIREMENTS

Generate:

## Patients

5000 records

---

## Encounters

25000 records

---

## Lab Results

100000 records

---

## Claims

50000 records

---

## Appointments

30000 records

---

## Providers

500 records

---

Inject:

* Duplicate patients
* Missing IDs
* Invalid dates
* Outlier lab values
* Expired provider licenses
* Invalid appointment statuses
* Wait times exceeding thresholds

to support governance demonstrations.

---

# ADDITIONAL SOURCE DATA REQUIREMENTS

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

# Success Criteria

The final platform should demonstrate:

1. Automatic classification of sensitive healthcare data.
2. End-to-end lineage from source systems to executive KPIs.
3. Proactive data quality monitoring.
4. Stewardship workflows.
5. Operational governance visibility.
6. Security and audit transparency.
7. Impact analysis before deployment.
8. A single Governance Command Center for healthcare analytics.
