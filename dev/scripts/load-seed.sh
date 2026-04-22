#!/usr/bin/env bash
# Upload OPTs then compositions into a fresh EHRbase.
# Idempotent on templates (EHRbase rejects duplicates with 409; treated as OK).
# Creates one EHR per unique `subject_id` seen in composition bodies.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SEED_DIR="${DEV_DIR}/seed-data"

if [[ -f "${DEV_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  set -a && . "${DEV_DIR}/.env" && set +a
fi

PORT="${EHRBASE_PORT:-8080}"
USER="${EHRBASE_USER:-ehrbase}"
PASS="${EHRBASE_PASSWORD:-ehrbase}"
BASE="http://localhost:${PORT}/ehrbase/rest/openehr/v1"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1" >&2; exit 1; }; }
need curl
need jq

auth=(-u "${USER}:${PASS}")

echo "Loading templates from ${SEED_DIR}/templates"
shopt -s nullglob
template_count=0
for opt in "${SEED_DIR}/templates/"*.opt; do
  echo "  uploading $(basename "${opt}")"
  code=$(curl -sS -o /tmp/tpl-resp -w "%{http_code}" \
    "${auth[@]}" \
    -H "Content-Type: application/xml" \
    -H "Accept: application/json" \
    --data-binary @"${opt}" \
    -X POST "${BASE}/definition/template/adl1.4")
  if [[ "${code}" == "201" || "${code}" == "204" || "${code}" == "409" ]]; then
    template_count=$((template_count + 1))
  else
    echo "    failed: HTTP ${code}" >&2
    cat /tmp/tpl-resp >&2 || true
    exit 1
  fi
done
echo "Templates processed: ${template_count}"

echo "Loading compositions from ${SEED_DIR}/compositions"
declare -A ehr_by_subject=()

create_ehr_for() {
  local subject_id="$1" subject_namespace="$2"
  local payload
  payload=$(cat <<JSON
{
  "_type": "EHR_STATUS",
  "name": { "value": "EHR Status" },
  "archetype_node_id": "openEHR-EHR-EHR_STATUS.generic.v1",
  "subject": {
    "external_ref": {
      "id": { "_type": "GENERIC_ID", "value": "${subject_id}", "scheme": "id_scheme" },
      "namespace": "${subject_namespace}",
      "type": "PERSON"
    }
  },
  "is_queryable": true,
  "is_modifiable": true
}
JSON
)
  local resp
  resp=$(curl -sS \
    "${auth[@]}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "Prefer: return=representation" \
    -d "${payload}" \
    -X POST "${BASE}/ehr")
  echo "${resp}" | jq -r '.ehr_id.value // empty'
}

composition_count=0
for comp in "${SEED_DIR}/compositions/"*.json; do
  subject_id=$(jq -r '.meta.subject_id // "seed-subject-000"' "${comp}")
  subject_ns=$(jq -r '.meta.subject_namespace // "local-dev"' "${comp}")
  ehr_id="${ehr_by_subject[${subject_id}]:-}"
  if [[ -z "${ehr_id}" ]]; then
    ehr_id=$(create_ehr_for "${subject_id}" "${subject_ns}")
    if [[ -z "${ehr_id}" ]]; then
      echo "  could not create EHR for ${subject_id}" >&2
      exit 1
    fi
    ehr_by_subject[${subject_id}]="${ehr_id}"
    echo "  EHR ${ehr_id} for subject ${subject_id}"
  fi

  body=$(jq 'del(.meta)' "${comp}")
  code=$(curl -sS -o /tmp/cmp-resp -w "%{http_code}" \
    "${auth[@]}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "Prefer: return=minimal" \
    -d "${body}" \
    -X POST "${BASE}/ehr/${ehr_id}/composition")
  if [[ "${code}" == "201" || "${code}" == "204" ]]; then
    composition_count=$((composition_count + 1))
  else
    echo "  composition $(basename "${comp}") failed: HTTP ${code}" >&2
    cat /tmp/cmp-resp >&2 || true
    exit 1
  fi
done
echo "Compositions uploaded: ${composition_count}"
echo "Distinct EHRs created: ${#ehr_by_subject[@]}"
