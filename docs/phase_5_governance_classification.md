# Phase 5: Classification Tags and Dynamic Masking

## Overview

Phase 5 implements Snowflake's native governance features using the OvalEdge role for creating and managing governance objects. This phase establishes:

1. **Governance Tags** in `GOVERNANCE.TAGS` schema for classifying data sensitivity levels with propagation enabled
2. **Masking Policies** in `GOVERNANCE.POLICIES` schema that enforce role-based access controls
3. **Metadata Views** for measuring tag and masking coverage

## Key Capabilities Demonstrated

### Sensitive Data Classification

The demo classifies columns into six sensitivity categories:

| Tag | Purpose | Example Columns |
|-----|---------|-----------------|
| `PHI` | Protected Health Information (HIPAA-regulated) | patient_name, dob, medical_record_number, address |
| `PII` | Personally Identifiable Information | phone_number, email_address |
| `SENSITIVE` | Restricted business data | diagnosis_code, insurance_id |
| `RESTRICTED` | Highest sensitivity level | ssn |
| `CONFIDENTIAL` | Limited disclosure data | (available for future use) |
| `PUBLIC` | No sensitivity restrictions | (available for future use) |

### Role-Based Masking

Snowflake masking policies enforce different data visibility by role:

| Role | Access Level | Example Behavior |
|------|--------------|------------------|
| `OVALEDGE_ROLE` | Full governance access | Sees: `John Smith`, `1985-01-15`, `1028374` |
| `HC_DEMO_ADMIN` | Full access | Sees: `John Smith`, `1985-01-15`, `1028374` |
| `HC_PHYSICIAN_ROLE` | Clinical access (unmasked PHI) | Sees: `John Smith`, `1985-01-15`, `1028374` |
| `HC_ANALYST_ROLE` | Analytics access (masked PHI) | Sees: `J*** S****`, `NULL`, `****74` |
| Other roles | Restricted access | All sensitive data masked |

### Masking Policies

Six masking policies are created in `GOVERNANCE.POLICIES` schema to handle different data types and masking strategies:

1. **MASK_PATIENT_NAME**: Partial masking (first letter + last 4 chars) for analysts
2. **MASK_DATE**: Null masking for dates accessed by analysts
3. **MASK_MRN**: Partial masking (last 2 digits) for medical record numbers
4. **MASK_SSN**: Full masking (XXX-XX-****) for social security numbers
5. **MASK_INSURANCE_ID**: Partial masking (last 4 digits) for insurance IDs
6. **MASK_DIAGNOSIS**: Null masking for diagnosis codes for analysts

### Tag Propagation

All governance tags are created with `PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT`, ensuring that tags automatically propagate through:
- View definitions and transformations
- Data lineage paths
- Cross-schema references

## Implementation Steps

### 1. Create Governance Tags in GOVERNANCE.TAGS Schema

```sql
USE ROLE OVALEDGE_ROLE;
CREATE OR REPLACE TAG GOVERNANCE.TAGS.PHI
  COMMENT = 'Protected Health Information - Subject to HIPAA regulations'
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;
-- ... (repeat for other tags)
```

### 2. Assign Tags to Bronze Columns

Tags are assigned from the `GOVERNANCE.TAGS` schema to source system raw data columns::

```sql
ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN patient_first_name SET TAG GOVERNANCE.TAGS.PHI = 'Patient Identifier';
```

### 3. Create Masking Policies in GOVERNANCE.POLICIES Schema

Masking policies are created in a dedicated `GOVERNANCE.POLICIES` schema and define conditional visibility based on current role:

```sql
USE ROLE OVALEDGE_ROLE;
CREATE OR REPLACE MASKING POLICY GOVERNANCE.POLICIES.MASK_PATIENT_NAME AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'HC_PHYSICIAN_ROLE' THEN val
    WHEN CURRENT_ROLE() = 'HC_ANALYST_ROLE' THEN CONCAT(SUBSTRING(val, 1, 1), '*** ', SUBSTRING(val, -4))
    WHEN CURRENT_ROLE() = 'HC_DEMO_ADMIN' THEN val
    ELSE '***MASKED***'
  END;
```

### 4. Apply Masking Policies to Columns

Masking policies from `GOVERNANCE.POLICIES` are applied to both Bronze (raw) and Silver (standardized) columns:

```sql
ALTER TABLE BRONZE.BRZ_PATIENT_MASTER
  MODIFY COLUMN patient_first_name SET MASKING POLICY GOVERNANCE.POLICIES.MASK_PATIENT_NAME;
```

### 5. Create Governance Views

Metadata views enable measurement of tag coverage and classification progress:

- `VW_TAG_COVERAGE`: Shows which columns are tagged with which sensitivity levels
- `VW_CLASSIFICATION_SUMMARY`: Aggregates tagging coverage by tag type
- `VW_PATIENT_PHYSICIAN_VIEW`: Demo view of unmasked clinical data
- `VW_PATIENT_ANALYST_VIEW`: Demo view of masked data

## Expected Outcomes

### Tag Coverage

| Tag | Objects Tagged | Coverage |
|-----|----------------|----------|
| PHI | 7 columns | patient_first_name, patient_last_name, dob, medical_record_number, address_line1, patient_name, diagnosis_code |
| PII | 2 columns | phone_number, email_address |
| SENSITIVE | 2 columns | diagnosis_code, insurance_id |
| RESTRICTED | 1 column | ssn |

### Masking Policy Coverage

All sensitive columns in Bronze and Silver layers have masking policies applied. When queried as `HC_ANALYST_ROLE`, sensitive data is masked or nullified.

## Demo Workflow

### Query 1: Unmasked Clinical Data (Physician View)

```sql
USE ROLE HC_DEMO_ADMIN;
USE WAREHOUSE HC_GOV_WH;
USE DATABASE HC_GOV_DEMO;

SELECT
  patient_name,
  dob,
  medical_record_number,
  ssn
FROM SILVER.SLV_PATIENT
LIMIT 10;
```

**Expected Output:**
```
patient_name | dob | medical_record_number | ssn
John Smith | 1985-01-15 | 1028374 | 123-45-6789
Jane Doe | 1990-06-20 | 1028375 | 234-56-7890
```

### Query 2: Masked Analytics Data (Analyst View)

To test masking as a different role, you would:

1. Create a session with HC_ANALYST_ROLE (or execute a query with EXECUTE AS HC_ANALYST_ROLE)
2. Run the same query
3. Observe masked output

**Expected Output:**
```
patient_name | dob | medical_record_number | ssn
J*** S**** | NULL | ****74 | XXX-XX-6789
J*** D** | NULL | ****75 | XXX-XX-7890
```

### Query 3: Review Classification Coverage

```sql
SELECT * FROM GOVERNANCE.VW_CLASSIFICATION_SUMMARY;
```

**Expected Output:**
A summary table showing counts of objects tagged with each sensitivity level.

## Validation

Run the Phase 5 validation script (`99_validate_phase_5.sql`) to verify:

- [ ] All governance tags are created
- [ ] Tags are assigned to sensitive columns
- [ ] Masking policies are created and applied
- [ ] Unmasked data is visible to SYSADMIN/Physician role
- [ ] Governance views return results
- [ ] Tag coverage metrics are available

## Prerequisites

- Phase 1-4 completed (Bronze, Silver, Gold layers established)
- Roles created (HC_DEMO_ADMIN, HC_PHYSICIAN_ROLE, HC_ANALYST_ROLE, OVALEDGE_ROLE)
- OVALEDGE_ROLE has privileges to create tags and masking policies in GOVERNANCE schema
- GOVERNANCE.TAGS and GOVERNANCE.POLICIES schemas created
- Sufficient Snowflake account edition (Enterprise or higher recommended for full masking policy support)

## Next Steps

After Phase 5 validation:

1. **Phase 6**: SQL Audit-Based Data Quality Framework
   - Implement deterministic DQ rules
   - Capture failed records
   - Create alerts and steward assignments

2. **Phase 7**: Lineage and Impact Analysis
   - Document data lineage from source to KPI
   - Simulate impact analysis for schema changes

3. **Phase 8**: Streamlit Governance Dashboard
   - Build dashboard for visualizing classification, DQ, and lineage

## Troubleshooting

### Issue: Masking Policy Not Applied

**Symptom**: Data still appears unmasked when queried as restricted role

**Solution**: 
1. Verify masking policy is applied to column: `SHOW COLUMNS IN TABLE schema.table;`
2. Check that CURRENT_ROLE() matches policy conditions
3. Ensure Snowflake account supports masking policies (Enterprise+ required)

### Issue: Tag Not Visible in Governance Views

**Symptom**: `VW_TAG_COVERAGE` returns no results

**Solution**:
1. Verify tag was created: `SHOW TAGS IN SCHEMA GOVERNANCE.GOVERNANCE;`
2. Verify tag was applied to column: `SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES WHERE tag_name = 'PHI';`
3. Account usage views may have slight delay; wait a few minutes and retry

### Issue: Role Hierarchy Not Working for Masking

**Symptom**: Policy doesn't respect role grants

**Solution**: Ensure CURRENT_ROLE() is checked correctly. In Snowflake, CURRENT_ROLE() returns the role currently active in the session, not parent roles. Use a test query to verify:

```sql
SELECT CURRENT_ROLE(), CURRENT_USER();
```

## References

- [Snowflake Governance Tags Documentation](https://docs.snowflake.com/en/user-guide/governance-tagging)
- [Snowflake Masking Policies Documentation](https://docs.snowflake.com/en/user-guide/security-column-masking-policies)
- [HIPAA and Healthcare Compliance](https://docs.snowflake.com/en/user-guide/security-compliance)
