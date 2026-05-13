# Windows validation checklist

Use this checklist before tagging a public `v0.1.0` tester release.

## Prerequisites

- Windows 10 or 11.
- Power BI Desktop Win32 installer build.
- A running local EHRbase seeded from this repo:

```bash
cp dev/.env.example dev/.env
docker compose -f dev/docker-compose.yml up -d ehrbase-postgres ehrbase
bash dev/scripts/load-seed.sh
```

## Install the signed connector

Download `OpenEHR.pqx`, `dev-cert.cer`, and `install-powerbi-connector.ps1` from the release candidate.

Run PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install-powerbi-connector.ps1
```

## Desktop smoke test

1. Restart Power BI Desktop.
2. Confirm **Get Data → Other → openEHR (Beta)** is visible.
3. Connect to `http://localhost:8080/ehrbase/rest/openehr/v1`.
4. Choose **Username and password**.
5. Enter `ehrbase` / `ehrbase` for the local dev CDR.
6. Confirm the Navigator opens.

## Query smoke test

In a blank query, run:

```m
OpenEHR.Aql(
    "http://localhost:8080/ehrbase/rest/openehr/v1",
    "SELECT
        e/ehr_id/value AS EhrId,
        o/data[at0001]/events[at0006]/data[at0003]/items[at0004]/value/magnitude AS Systolic,
        o/data[at0001]/events[at0006]/data[at0003]/items[at0005]/value/magnitude AS Diastolic,
        o/data[at0001]/events[at0006]/time/value AS Taken
     FROM EHR e CONTAINS COMPOSITION c CONTAINS OBSERVATION o
        [openEHR-EHR-OBSERVATION.blood_pressure.v2]
     ORDER BY o/data[at0001]/events[at0006]/time/value DESC",
    [ PageSize = 1 ]
)
```

Acceptance:

- At least two seeded rows are returned.
- `Systolic` and `Diastolic` are numeric.
- Refresh works after saving, closing, and reopening the `.pbix`.
- The M query contains only the CDR URL and AQL; credentials are not function arguments.

## Notes

Record the exact Power BI Desktop version, connector artifact SHA, and any failure text in `dev/sample-pbix/README.md` or the release candidate notes.

[← Back to Home](../index.md)
