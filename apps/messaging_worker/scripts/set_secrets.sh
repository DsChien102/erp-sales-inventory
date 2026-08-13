#!/usr/bin/env bash
# Push messaging worker *secrets* to Railway for the target environment.
# Knobs (WORKER_LOG_LEVEL, batch sizes, tick intervals) are owned by
# `.railway/railway.ts` — do not set them here.
#
# Local: reads worker env file from Vet45 manifest (--env staging|production)
# CI:    pass --ci and set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, WORKER_TICK_SECRET
# Optional: RESEND_API_KEY, RESEND_FROM_DOMAIN, APP_LINK_BASE_URL (skipped if empty)
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
    ENV_FILE="${TARGET_worker_ENV_FILE:-}"
  fi
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing secrets for ${MANIFEST_ENV}. Run: vet45 sync --env ${MANIFEST_ENV} --target worker"
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

set_secret() {
  local key="$1"
  local val="$2"
  printf '%s' "$val" | railway variable set "$key" --stdin \
    --service "$SERVICE" --environment "$RAILWAY_ENV"
}

set_optional_secret() {
  local key="$1"
  local val="${!key:-}"
  if [[ -z "$val" ]]; then
    echo "skip ${key} (unset)"
    return 0
  fi
  set_secret "$key" "$val"
}

set_secret SUPABASE_URL "$SUPABASE_URL"
set_secret SUPABASE_SERVICE_ROLE_KEY "$SUPABASE_SERVICE_ROLE_KEY"
set_secret WORKER_TICK_SECRET "$WORKER_TICK_SECRET"
set_optional_secret RESEND_API_KEY
set_optional_secret RESEND_FROM_DOMAIN
set_optional_secret APP_LINK_BASE_URL

echo "Railway secrets set for ${SERVICE} (${RAILWAY_ENV})."
