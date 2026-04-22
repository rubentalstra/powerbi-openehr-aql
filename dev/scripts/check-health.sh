#!/usr/bin/env bash
# Probe the three endpoints the connector relies on.
# Exits non-zero if any probe fails — safe to chain with `&&`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../.env" ]]; then
  # shellcheck disable=SC1091
  set -a && . "${SCRIPT_DIR}/../.env" && set +a
fi

EHRBASE_PORT="${EHRBASE_PORT:-8080}"
EHRBASE_USER="${EHRBASE_USER:-ehrbase}"
EHRBASE_PASSWORD="${EHRBASE_PASSWORD:-ehrbase}"
BASE="http://localhost:${EHRBASE_PORT}/ehrbase"

probe() {
  local label="$1" method="$2" path="$3" body="${4:-}"
  local url="${BASE}${path}"
  local args=(-sS -o /dev/null -w "%{http_code}" -u "${EHRBASE_USER}:${EHRBASE_PASSWORD}" -X "${method}")
  if [[ -n "${body}" ]]; then
    args+=(-H "Content-Type: application/json" -d "${body}")
  fi
  local code
  code=$(curl "${args[@]}" "${url}" || true)
  if [[ "${code}" =~ ^2|^4 ]]; then
    printf '  %-32s %s %s\n' "${label}" "${code}" "${url}"
  else
    printf '  %-32s %s %s\n' "${label}" "${code:-ERR}" "${url}" >&2
    return 1
  fi
}

echo "Checking EHRbase at ${BASE}"
probe "management/health"   GET  "/management/health"
probe "definition/template" GET  "/rest/openehr/v1/definition/template/adl1.4"
probe "query/aql"           POST "/rest/openehr/v1/query/aql" \
  '{"q":"SELECT e/ehr_id/value FROM EHR e LIMIT 1"}'

echo "All probes OK."
