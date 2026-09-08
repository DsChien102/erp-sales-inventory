#!/usr/bin/env bash
# Pull already-published images. Does not build or set secrets.
#
# Usage:
#   ./.railway/scripts/rollout.sh [--env staging|production]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RAILWAY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT="$(cd "${RAILWAY_DIR}/.." && pwd)"
SERVICES_FILE="${RAILWAY_DIR}/services.txt"

RAILWAY_ENV="${RAILWAY_ENVIRONMENT:-staging}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      RAILWAY_ENV="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--env staging|production]"
      exit 1
      ;;
  esac
done

case "$RAILWAY_ENV" in
  staging|production) ;;
  *)
    echo "ERROR: --env must be staging or production (got: ${RAILWAY_ENV})"
    exit 1
    ;;
esac

export RAILWAY_ENVIRONMENT="$RAILWAY_ENV"
export RAILWAY_CALLER="${RAILWAY_CALLER:-skill:use-railway@1.3.0}"
export RAILWAY_AGENT_SESSION="${RAILWAY_AGENT_SESSION:-vet45-railway-rollout}"

if [[ ! -f "$SERVICES_FILE" ]]; then
  echo "ERROR: missing ${SERVICES_FILE}"
  exit 1
fi

cd "$ROOT"

services=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | xargs)"
  [[ -z "$line" ]] && continue
  services+=("$line")
done <"$SERVICES_FILE"

if [[ ${#services[@]} -eq 0 ]]; then
  echo "ERROR: no services in ${SERVICES_FILE}"
  exit 1
fi

for service in "${services[@]}"; do
  echo "==> Redeploying ${service} on ${RAILWAY_ENV} (pull image)"
  railway redeploy --service "$service" --environment "$RAILWAY_ENV" --from-source --yes
done

poll_success() {
  local service="$1"
  for _ in $(seq 1 32); do
    local dep_status
    dep_status=$(railway deployment list --service "$service" --environment "$RAILWAY_ENV" --limit 1 --json \
      | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['status'])")
    echo "  ${service}: ${dep_status}"
    if [[ "$dep_status" == "SUCCESS" ]]; then return 0; fi
    if [[ "$dep_status" == "FAILED" || "$dep_status" == "CRASHED" ]]; then return 1; fi
    sleep 15
  done
  return 1
}

echo "==> Polling deployment (up to ~8 min each)"
for service in "${services[@]}"; do
  poll_success "$service"
done

echo "Rollout done (${RAILWAY_ENV})."
