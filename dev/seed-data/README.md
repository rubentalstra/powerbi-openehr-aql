# Seed data for local EHRbase

This directory holds the operational templates (`templates/`) and sample compositions (`compositions/`) used to populate a fresh local EHRbase for dev and CI.

## Sourcing templates

Drop ADL 1.4 OPT files into `templates/`. The loader uploads every `*.opt` it finds via:

```
POST /ehrbase/rest/openehr/v1/definition/template/adl1.4
Content-Type: application/xml
```

The v0.1 fixture set committed to this repo is intentionally small and
deterministic:

- `Blutdruck.opt` — blood-pressure template used by the canonical AQL suite.
- `KDS_Laborbericht.opt` — laboratory-report template reserved for follow-up
  lab-result fixtures.

Sources:

- EHRbase test fixtures — https://github.com/ehrbase/ehrbase/tree/develop/service/src/test/resources/knowledge/operational_templates
- openEHR Clinical Knowledge Manager — https://ckm.openehr.org/ckm/

Additional OPTs can be copied in manually when broadening the suite. Keep them
small, license-compatible, and deterministic.

## Compositions

Drop canonical-JSON composition bodies into `compositions/`. File name convention:

```
<template_id>.<seq>.json
```

e.g. `vital_signs.001.json` ... `vital_signs.020.json`. The loader creates one EHR per unique `subject_id` found in `meta.subject_id`, then posts each composition to `/ehr/{ehr_id}/composition`.

Generation tips:

- Better Sample Generator: https://better-care.atlassian.net/wiki/spaces/SUPP/pages/1737031777/Synthetic+data
- Hand-craft one, then script variation by mutating values (magnitude, datetime) in a loop.

The current committed dataset contains two blood-pressure compositions for one
synthetic subject. That is enough to prove Basic auth, AQL execution, RM
flattening, and connector pagination with `PageSize = 1`. Broaden this to 50+
rows before performance testing or public demo dashboards.
