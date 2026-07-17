#!/usr/bin/env bash
# Deploy messaging-worker to Railway.
#
# Usage:
#   ./apps/messaging_worker/scripts/deploy.sh [--env staging|production] [--secrets] [--verify] [--ci]
#
# Examples:
#   ./apps/messaging_worker/scripts/deploy.sh                    # redeploy staging (code only)
#   ./apps/messaging_worker/scripts/deploy.sh --env production   # redeploy production
#   ./apps/messaging_worker/scripts/deploy.sh --verify --secrets # first-time staging setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

RAILWAY_ENV="${RAILWAY_ENVIRONMENT:-staging}"
SERVICE="${RAILWAY_SERVICE:-messaging-worker}"
RUN_SECRETS=false
RUN_VERIFY=false
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      RAILWAY_ENV="$2"
      shift 2
      ;;
    --secrets) RUN_SECRETS=true; shift ;;
    --verify) RUN_VERIFY=true; shift ;;
    --ci) CI_MODE=true; shift ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--env staging|production] [--secrets] [--verify] [--ci]"
      exit 1
      ;;
  esac
done

export RAILWAY_ENVIRONMENT="$RAILWAY_ENV"
export RAILWAY_CALLER="${RAILWAY_CALLER:-skill:use-railway@1.3.0}"
export RAILWAY_AGENT_SESSION="${RAILWAY_AGENT_SESSION:-vet45-messaging-worker-deploy}"

load_local_env() {
  if [[ "$CI_MODE" == true ]]; then
    return 0
  fi
  "$ROOT/scripts/env/vet45_env.sh" sync --env "$RAILWAY_ENV" >/dev/null || true
  local resolved
  resolved="$("$ROOT/scripts/env/vet45_env.sh" resolve-shell --env "$RAILWAY_ENV")"
  local env_file=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == TARGET_worker_ENV_FILE=* ]]; then
      env_file="${line#TARGET_worker_ENV_FILE=}"
    fi
  done <<<"$resolved"
  if [[ -n "$env_file" && -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    set -a && source "$env_file" && set +a
  fi
}

if [[ "$RUN_VERIFY" == true ]]; then
  echo "==> Verifying build"
  "${SCRIPT_DIR}/verify_build.sh"

  echo "==> Verifying Supabase platform migration"
  if [[ "$CI_MODE" == true ]]; then
    "${SCRIPT_DIR}/verify_supabase.sh"
  else
    load_local_env
    "${SCRIPT_DIR}/verify_supabase.sh"
  fi
fi

if [[ "$RUN_SECRETS" == true ]]; then
  echo "==> Pushing Railway secrets"
  if [[ "$CI_MODE" == true ]]; then
    "${SCRIPT_DIR}/set_secrets.sh" --ci --env "$RAILWAY_ENV"
  else
    "${SCRIPT_DIR}/set_secrets.sh" --env "$RAILWAY_ENV"
  fi
fi

echo "==> Deploying ${SERVICE} to ${RAILWAY_ENV}"
cd "$ROOT"
railway up --service "$SERVICE" --environment "$RAILWAY_ENV" \
  --detach -m "Messaging worker deploy (${RAILWAY_ENV})"

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

echo "==> Polling deployment (up to ~8 min)"
poll_success "$SERVICE"

echo "Done. Verify /health and tick logs; see apps/messaging_worker/README.md"
