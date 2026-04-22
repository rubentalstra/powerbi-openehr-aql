# Seed data for local EHRbase

This directory holds the operational templates (`templates/`) and sample compositions (`compositions/`) used to populate a fresh local EHRbase for dev and CI.

## Sourcing templates

Drop ADL 1.4 OPT files into `templates/`. The loader uploads every `*.opt` it finds via:

```
POST /ehrbase/rest/openehr/v1/definition/template/adl1.4
Content-Type: application/xml
```

Recommended starter set (3 templates — enough for the canonical query suite):

- `vital_signs.opt` — blood pressure, pulse, body temperature.
- `laboratory_test.opt` — lab results with `DV_QUANTITY` value + units.
- `demographics.opt` — patient demographics with `DV_CODED_TEXT` gender.

Sources:

- EHRbase test fixtures — https://github.com/ehrbase/ehrbase/tree/develop/service/src/test/resources/knowledge/operational_templates
- openEHR Clinical Knowledge Manager — https://ckm.openehr.org/ckm/

The repo does not vendor OPTs directly to avoid licensing ambiguity with upstream fixtures. Run `bash scripts/fetch-templates.sh` (added in a later step) or copy files manually before first seed.

## Compositions

Drop canonical-JSON composition bodies into `compositions/`. File name convention:

```
<template_id>.<seq>.json
```

e.g. `vital_signs.001.json` ... `vital_signs.020.json`. The loader creates one EHR per unique `subject_id` found in `meta.subject_id`, then posts each composition to `/ehr/{ehr_id}/composition`.

Generation tips:

- Better Sample Generator: https://better-care.atlassian.net/wiki/spaces/SUPP/pages/1737031777/Synthetic+data
- Hand-craft one, then script variation by mutating values (magnitude, datetime) in a loop.

Target: ≥50 compositions spread across the 3 templates (matches Task 0.4 acceptance criteria).
