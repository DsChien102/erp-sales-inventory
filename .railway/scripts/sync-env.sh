#!/usr/bin/env bash
# Push profile secrets to Railway for one environment.
# Shared keys (all services): SUPABASE_URL, APP_LINK_BASE_URL
# Service secrets: messaging-worker only
# Knobs stay in railway.ts. Do not set WORKER_* here.
#
# Usage:
#   ./.railway/scripts/sync-env.sh [--env staging|production] [--ci]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RAILWAY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT="$(cd "${RAILWAY_DIR}/.." && pwd)"

RAILWAY_ENV="${RAILWAY_ENVIRONMENT:-staging}"
SERVICE="${RAILWAY_SERVICE:-messaging-worker}"
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
      echo "Usage: $0 [--env staging|production] [--ci]"
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
export RAILWAY_AGENT_SESSION="${RAILWAY_AGENT_SESSION:-vet45-railway-sync-env}"

if [[ "$CI_MODE" != true ]]; then
  "$ROOT/scripts/env/vet45_env.sh" sync --env "$RAILWAY_ENV" >/dev/null
  RESOLVED="$("$ROOT/scripts/env/vet45_env.sh" resolve-shell --env "$RAILWAY_ENV")"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    export "$line"
  done <<<"$RESOLVED"

  ENV_FILE="${SECRETS_FILE:-}"
  if [[ ! -f "$ENV_FILE" ]]; then
    ENV_FILE="${TARGET_worker_ENV_FILE:-}"
  fi
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing secrets for ${RAILWAY_ENV}. Run: vet45 sync --env ${RAILWAY_ENV} --target worker"
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

cd "$ROOT"

echo "==> Shared variables (${RAILWAY_ENV})"
python3 - "$RAILWAY_ENV" <<'PY'
import json, os, subprocess, sys

env = sys.argv[1]
shared = {"SUPABASE_URL": os.environ["SUPABASE_URL"]}
app_link = os.environ.get("APP_LINK_BASE_URL", "")
if app_link:
    shared["APP_LINK_BASE_URL"] = app_link
else:
    print("skip APP_LINK_BASE_URL (unset)")

payload = {"sharedVariables": {k: {"value": v} for k, v in shared.items()}}
subprocess.run(
    [
        "railway",
        "environment",
        "edit",
        "--environment",
        env,
        "--message",
        f"sync shared env ({env})",
        "--json",
    ],
    input=json.dumps(payload),
    text=True,
    check=True,
)
print("shared set:", ", ".join(shared))
PY

set_service_secret() {
  local key="$1"
  local val="$2"
  printf '%s' "$val" | railway variable set "$key" --stdin \
    --service "$SERVICE" --environment "$RAILWAY_ENV" --skip-deploys
}

set_optional_service_secret() {
  local key="$1"
  local val="${!key:-}"
  if [[ -z "$val" ]]; then
    echo "skip ${key} (unset)"
    return 0
  fi
  set_service_secret "$key" "$val"
}

echo "==> Service secrets (${SERVICE})"
set_service_secret SUPABASE_SERVICE_ROLE_KEY "$SUPABASE_SERVICE_ROLE_KEY"
set_service_secret WORKER_TICK_SECRET "$WORKER_TICK_SECRET"
set_optional_service_secret RESEND_API_KEY
set_optional_service_secret RESEND_FROM_DOMAIN

echo "Railway env synced for ${RAILWAY_ENV} (shared + ${SERVICE})."
echo "Next: vet45 run railway rollout"
