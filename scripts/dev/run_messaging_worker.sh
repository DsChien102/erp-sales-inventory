#!/usr/bin/env bash
# Run messaging worker locally (dart) or via docker compose.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKER_DIR="${ROOT}/apps/messaging_worker"
ENV_FILE="${WORKER_DIR}/.env"
MODE="${1:-serve}"

usage() {
  cat <<'EOF'
Usage: run_messaging_worker.sh <mode>

Modes:
  serve   HTTP /health + adaptive tick loop (default)
  once    Single tick then exit
  docker  docker compose up messaging-worker (build if needed)

Prerequisites:
  - melos bootstrap (dart mode)
  - supabase start (when SUPABASE_URL points at local API)
  - apps/messaging_worker/.env with SUPABASE_SERVICE_ROLE_KEY (auto-filled when possible)
EOF
}

sed_inplace() {
  if [[ "$(uname -s)" == Darwin ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

read_env_value() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" || true
}

set_env_var() {
  local key="$1" value="$2"
  if grep -qE "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed_inplace "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >>"$ENV_FILE"
  fi
}

ensure_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "==> Creating ${ENV_FILE} via setup_env.sh"
    "${WORKER_DIR}/scripts/setup_env.sh"
  fi

  if command -v supabase >/dev/null 2>&1; then
    local status_env
    status_env="$(supabase status -o env 2>/dev/null || true)"
    if [[ -n "$status_env" ]]; then
      # shellcheck disable=SC2046
      eval "$(echo "$status_env" | grep -E '^(API_URL|SERVICE_ROLE_KEY)=' || true)"

      if [[ -z "$(read_env_value SUPABASE_SERVICE_ROLE_KEY)" && -n "${SERVICE_ROLE_KEY:-}" ]]; then
        echo "==> Setting SUPABASE_SERVICE_ROLE_KEY from supabase status"
        set_env_var SUPABASE_SERVICE_ROLE_KEY "$SERVICE_ROLE_KEY"
      fi

      local current_url
      current_url="$(read_env_value SUPABASE_URL)"
      if [[ (-z "$current_url" || "$current_url" == *127.0.0.1* || "$current_url" == *localhost*) && -n "${API_URL:-}" ]]; then
        echo "==> Setting SUPABASE_URL from supabase status (${API_URL})"
        set_env_var SUPABASE_URL "$API_URL"
      fi
    fi
  fi

  if [[ -z "$(read_env_value WORKER_TICK_SECRET)" ]]; then
    echo "==> Generating WORKER_TICK_SECRET"
    set_env_var WORKER_TICK_SECRET "$(openssl rand -hex 32)"
  fi

  if [[ -z "$(read_env_value SUPABASE_SERVICE_ROLE_KEY)" ]]; then
    echo "ERROR: SUPABASE_SERVICE_ROLE_KEY is empty in ${ENV_FILE}"
    echo "       Run: supabase status  (copy service_role key)"
    echo "       Or:  ./apps/messaging_worker/scripts/setup_env.sh"
    exit 1
  fi
}

check_supabase_reachable() {
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a

  if [[ "$SUPABASE_URL" == *127.0.0.1* || "$SUPABASE_URL" == *localhost* ]]; then
    if ! curl -sf "${SUPABASE_URL}/rest/v1/" -o /dev/null 2>/dev/null; then
      echo "ERROR: Supabase not reachable at ${SUPABASE_URL}"
      echo "       Run: supabase start"
      exit 1
    fi
  fi
}

run_dart() {
  local flag="$1"
  cd "$WORKER_DIR"
  set -a && source "$ENV_FILE" && set +a
  dart run bin/worker.dart "$flag"
}

case "$MODE" in
  -h | --help)
    usage
    exit 0
    ;;
  docker)
    ensure_env
    cd "$ROOT"
    exec docker compose up --build messaging-worker
    ;;
  serve | once)
    ensure_env
    check_supabase_reachable
    run_dart "--${MODE}"
    ;;
  *)
    echo "Unknown mode: ${MODE}"
    usage
    exit 64
    ;;
esac
