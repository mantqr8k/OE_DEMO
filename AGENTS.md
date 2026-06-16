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

## Business KPI

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

# Column-Level Lineage

readmission_flag

Derived From:

```text
admission_date
discharge_date
patient_id
```

---

# IMPACT ANALYSIS DEMO

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

# DEMO SCRIPT

## Step 1

Ingest patient data into Bronze.

## Step 2

Run classification scan.

Show PHI tags.

## Step 3

Promote data to Silver.

Execute quality checks.

Inject failures.

## Step 4

Create Gold metrics.

Generate Readmission KPI.

## Step 5

Open lineage visualization.

Trace KPI back to source.

## Step 6

Rename source field.

Execute impact analysis.

## Step 7

Show governance dashboard.

Display:

* Classification Coverage
* Data Quality Score
* Lineage Completeness
* Policy Compliance

---

# Expected Governance Outcomes

1. PHI automatically identified.
2. Sensitive data protected.
3. Data quality issues detected early.
4. KPI lineage fully traceable.
5. Change impact known before deployment.
6. Governance embedded into onboarding lifecycle.
