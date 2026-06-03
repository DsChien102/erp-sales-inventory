#!/usr/bin/env bash
# Push messaging worker secrets to Railway for the target environment.
# Local: reads apps/messaging_worker/.env
# CI:    pass --ci and set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, WORKER_TICK_SECRET
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
ENV_FILE="${ROOT}/apps/messaging_worker/.env"
SERVICE="${RAILWAY_SERVICE:-messaging-worker}"
RAILWAY_ENV="${RAILWAY_ENVIRONMENT:-staging}"
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ci) CI_MODE=true; shift ;;
    --env)
      RAILWAY_ENV="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

export RAILWAY_ENVIRONMENT="$RAILWAY_ENV"

if [[ "$CI_MODE" == true ]]; then
  for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY WORKER_TICK_SECRET; do
    if [[ -z "${!key:-}" ]]; then
      echo "ERROR: ${key} must be set in CI environment"
      exit 1
    fi
  done
else
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing ${ENV_FILE}. Run ./apps/messaging_worker/scripts/setup_env.sh first."
    exit 1
  fi
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a

  for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY WORKER_TICK_SECRET; do
    val="${!key:-}"
    if [[ -z "$val" ]]; then
      echo "ERROR: ${key} is empty in ${ENV_FILE}"
      exit 1
    fi
  done
fi

export RAILWAY_CALLER="${RAILWAY_CALLER:-skill:use-railway@1.3.0}"
export RAILWAY_AGENT_SESSION="${RAILWAY_AGENT_SESSION:-vet45-messaging-worker-deploy}"

cd "$ROOT"

printf '%s' "$SUPABASE_URL" | railway variable set SUPABASE_URL --stdin \
  --service "$SERVICE" --environment "$RAILWAY_ENV"
printf '%s' "$SUPABASE_SERVICE_ROLE_KEY" | railway variable set SUPABASE_SERVICE_ROLE_KEY --stdin \
  --service "$SERVICE" --environment "$RAILWAY_ENV"
printf '%s' "$WORKER_TICK_SECRET" | railway variable set WORKER_TICK_SECRET --stdin \
  --service "$SERVICE" --environment "$RAILWAY_ENV"

railway variable set "WORKER_TENANT_BATCH_SIZE=${WORKER_TENANT_BATCH_SIZE:-20}" \
  --service "$SERVICE" --environment "$RAILWAY_ENV"
railway variable set "WORKER_MODULE_BATCH_SIZE=${WORKER_MODULE_BATCH_SIZE:-10}" \
  --service "$SERVICE" --environment "$RAILWAY_ENV"
railway variable set "WORKER_MAX_ROUNDS_PER_TICK=${WORKER_MAX_ROUNDS_PER_TICK:-5}" \
  --service "$SERVICE" --environment "$RAILWAY_ENV"
railway variable set "WORKER_TICK_ACTIVE_SECONDS=${WORKER_TICK_ACTIVE_SECONDS:-3}" \
  --service "$SERVICE" --environment "$RAILWAY_ENV"
railway variable set "WORKER_TICK_IDLE_SECONDS=${WORKER_TICK_IDLE_SECONDS:-15}" \
  --service "$SERVICE" --environment "$RAILWAY_ENV"
railway variable set "WORKER_TICK_MAX_IDLE_SECONDS=${WORKER_TICK_MAX_IDLE_SECONDS:-30}" \
  --service "$SERVICE" --environment "$RAILWAY_ENV"

echo "Railway variables set for ${SERVICE} (${RAILWAY_ENV})."
