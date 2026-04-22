#!/usr/bin/env bash
# Run the canonical AQL suite against the given CDR base URL.
# Usage: run-canonical.sh <cdrBaseUrl>
# Example: run-canonical.sh http://localhost:8080/ehrbase/rest/openehr/v1
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <cdrBaseUrl>" >&2
  exit 2
fi

CDR_URL="${1%/}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES="${REPO_ROOT}/tests/fixtures/canonical-queries.json"
USER="${EHRBASE_USER:-ehrbase}"
PASS="${EHRBASE_PASSWORD:-ehrbase}"

if ! command -v jq >/dev/null 2>&1; then
  echo "missing: jq" >&2
  exit 2
fi

pass=0
fail=0
declare -a failures=()

count=$(jq -r '.queries | length' "${FIXTURES}")
echo "Running ${count} canonical queries against ${CDR_URL}"

for i in $(seq 0 $((count - 1))); do
  id=$(jq -r ".queries[$i].id" "${FIXTURES}")
  description=$(jq -r ".queries[$i].description" "${FIXTURES}")
  aql=$(jq -r ".queries[$i].aql" "${FIXTURES}")
  qp=$(jq -c ".queries[$i].queryParameters // null" "${FIXTURES}")
  assert_cols=$(jq -c ".queries[$i].assertColumns" "${FIXTURES}")
  assert_min=$(jq -r ".queries[$i].assertMinRows" "${FIXTURES}")
  allow_empty=$(jq -r ".queries[$i].allowEmpty" "${FIXTURES}")

  body=$(jq -nc --arg q "${aql}" --argjson qp "${qp}" \
    'if $qp == null then {q: $q} else {q: $q, query_parameters: $qp} end')

  echo
  echo "[${id}] ${description}"

  resp=$(curl -sS -u "${USER}:${PASS}" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -d "${body}" \
    -X POST "${CDR_URL}/query/aql" || true)

  if [[ -z "${resp}" ]]; then
    echo "  FAIL: empty response"
    fail=$((fail + 1))
    failures+=("${id}: empty response")
    continue
  fi

  is_err=$(echo "${resp}" | jq -r 'has("message") or has("error")')
  if [[ "${is_err}" == "true" ]]; then
    msg=$(echo "${resp}" | jq -r '.message // .error')
    echo "  FAIL: ${msg}"
    fail=$((fail + 1))
    failures+=("${id}: ${msg}")
    continue
  fi

  got_cols=$(echo "${resp}" | jq -c '[.columns[]?.name // .columns[]?.path]')
  row_count=$(echo "${resp}" | jq -r '.rows | length')

  missing=$(jq -nc --argjson want "${assert_cols}" --argjson got "${got_cols}" \
    '$want - $got')
  if [[ "${missing}" != "[]" ]]; then
    echo "  FAIL: missing columns: ${missing} (got ${got_cols})"
    fail=$((fail + 1))
    failures+=("${id}: missing ${missing}")
    continue
  fi

  if [[ "${row_count}" -lt "${assert_min}" && "${allow_empty}" != "true" ]]; then
    echo "  FAIL: expected ≥${assert_min} rows, got ${row_count}"
    fail=$((fail + 1))
    failures+=("${id}: rows=${row_count}")
    continue
  fi

  echo "  PASS (rows=${row_count})"
  pass=$((pass + 1))
done

echo
echo "Canonical suite: ${pass} passed, ${fail} failed"
if [[ ${fail} -gt 0 ]]; then
  printf '  - %s\n' "${failures[@]}"
  exit 1
fi
