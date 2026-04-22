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
EHRBASE_ADMIN_USER="${EHRBASE_ADMIN_USER:-ehrbase_admin}"
EHRBASE_ADMIN_PASSWORD="${EHRBASE_ADMIN_PASSWORD:-ehrbase_admin}"
BASE="http://localhost:${EHRBASE_PORT}/ehrbase"

# probe <label> <method> <path> [body] [creds]
# creds: "user:pass" — defaults to regular auth. Use admin creds for /management/*.
probe() {
  local label="$1" method="$2" path="$3" body="${4:-}" creds="${5:-${EHRBASE_USER}:${EHRBASE_PASSWORD}}"
  local url="${BASE}${path}"
  local args=(-sS -o /dev/null -w "%{http_code}" -u "${creds}" -X "${method}")
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
# /management/* is admin-only in EHRbase 2.x — use admin credentials for it.
probe "management/health"   GET  "/management/health" "" "${EHRBASE_ADMIN_USER}:${EHRBASE_ADMIN_PASSWORD}"
probe "definition/template" GET  "/rest/openehr/v1/definition/template/adl1.4"
probe "query/aql"           POST "/rest/openehr/v1/query/aql" \
  '{"q":"SELECT e/ehr_id/value FROM EHR e LIMIT 1"}'

echo "All probes OK."
