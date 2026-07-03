#!/usr/bin/env bash
# Push messaging worker secrets to Railway for the target environment.
# Local: reads worker env file from Vet45 manifest (--env staging|production)
# CI:    pass --ci and set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, WORKER_TICK_SECRET
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SERVICE="${RAILWAY_SERVICE:-messaging-worker}"
RAILWAY_ENV="${RAILWAY_ENVIRONMENT:-staging}"
CI_MODE=false
MANIFEST_ENV="staging"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ci) CI_MODE=true; shift ;;
    --env)
      RAILWAY_ENV="$2"
      MANIFEST_ENV="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

export RAILWAY_ENVIRONMENT="$RAILWAY_ENV"

if [[ "$CI_MODE" != true ]]; then
  "$ROOT/scripts/env/vet45_env.sh" sync --env "$MANIFEST_ENV" >/dev/null
  RESOLVED="$("$ROOT/scripts/env/vet45_env.sh" resolve-shell --env "$MANIFEST_ENV")"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    export "$line"
  done <<<"$RESOLVED"

  ENV_FILE="${SECRETS_FILE:-}"
  if [[ ! -f "$ENV_FILE" ]]; then
    ENV_FILE="${WORKER_ENV_FILE}"
  fi
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing secrets for ${MANIFEST_ENV}. Run melos run env:sync -- --env ${MANIFEST_ENV}"
    exit 1
  fi
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a
fi

for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY WORKER_TICK_SECRET; do
  val="${!key:-}"
  if [[ -z "$val" ]]; then
    echo "ERROR: ${key} must be set"
    exit 1
  fi
done

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
railway variable set "WORKER_LOG_LEVEL=${WORKER_LOG_LEVEL:-WARNING}" \
  --service "$SERVICE" --environment "$RAILWAY_ENV"

echo "Railway variables set for ${SERVICE} (${RAILWAY_ENV})."
