# Sample `.pbix` dashboards — PENDING

`.pbix` files require Power BI Desktop (Windows). This repo's maintainer develops on macOS, so the three planned sample reports are captured here as AQL queries for a future contributor with Windows access to build and commit.

## Dashboard 1 — Vital signs overview

- **AQL:** `SELECT e/ehr_id/value AS EhrId, o/data[at0001]/events[at0006]/data[at0003]/items[at0004]/value/magnitude AS Systolic, o/data[at0001]/events[at0006]/data[at0003]/items[at0005]/value/magnitude AS Diastolic, o/data[at0001]/events[at0006]/time/value AS Taken FROM EHR e CONTAINS COMPOSITION c CONTAINS OBSERVATION o [openEHR-EHR-OBSERVATION.blood_pressure.v2]`
- Visuals: line chart (systolic + diastolic over time, per patient), distribution (histogram of latest systolic), data table.

## Dashboard 2 — Lab results trend

- **AQL:** `SELECT e/ehr_id/value AS EhrId, o/data[at0001]/events[at0002]/data[at0003]/items[at0005]/name/value AS Analyte, o/data[at0001]/events[at0002]/data[at0003]/items[at0005]/value/magnitude AS Value, o/data[at0001]/events[at0002]/data[at0003]/items[at0005]/value/units AS Units, o/data[at0001]/events[at0002]/time/value AS Taken FROM EHR e CONTAINS COMPOSITION c CONTAINS OBSERVATION o [openEHR-EHR-OBSERVATION.laboratory_test_result.v1]`
- Visuals: small-multiples line chart per analyte, slicer by patient + date, rolling-mean overlay.

## Dashboard 3 — Demographics + population

- **AQL:** `SELECT e/ehr_status/subject/external_ref/id/value AS SubjectId, e/ehr_id/value AS EhrId FROM EHR e`
- Visuals: card totals, donut by gender, table of EHRs with last-updated timestamp.

## Submission checklist

When building these in Power BI Desktop:

1. Use the locally-installed `OpenEHR.pqx` from the self-signed release flow.
2. Target `http://localhost:8080/ehrbase/rest/openehr/v1` against the seeded dev EHRbase.
3. Save `.pbix` to `dev/sample-pbix/<slug>.pbix`; include a `.png` screenshot alongside.
4. Redact all PHI before committing — use only the seed data.

Open a PR; reviewers will run the `.pbix` against their own seeded EHRbase.
