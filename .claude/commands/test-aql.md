---
description: Run an AQL query against the local EHRbase and pretty-print the response.
argument-hint: "<AQL string, quoted>"
---

## Context

Quick smoke-test against `http://localhost:8080/ehrbase` using the dev credentials from `dev/.env`. Assumes `docker compose up -d` is already running and seed data is loaded.

## Instructions

Use Bash. Source credentials from `dev/.env` (fall back to `ehrbase:ehrbase`). Post the AQL body to `/rest/openehr/v1/query/aql`. Pretty-print with `jq`.

```bash
set -a && . dev/.env && set +a
curl -sS -u "${EHRBASE_USER:-ehrbase}:${EHRBASE_PASSWORD:-ehrbase}" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$(jq -nc --arg q "$ARGUMENTS" '{q: $q}')" \
  "http://localhost:${EHRBASE_PORT:-8080}/ehrbase/rest/openehr/v1/query/aql" \
  | jq .
```

Summarize: row count, column names, any error category.
