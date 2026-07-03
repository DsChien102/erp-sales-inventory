#!/usr/bin/env bash
# Run messaging worker locally (dart) or via docker compose.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKER_DIR="${ROOT}/apps/messaging_worker"
ENV_FILE="${WORKER_ENV_FILE:-${WORKER_DIR}/.env}"
MODE="${1:-serve}"

usage() {
  cat <<'EOF'
Usage: run_messaging_worker.sh <mode>

Modes:
  serve   HTTP /health + adaptive tick loop (default)
  once    Single tick then exit
  docker  docker compose up messaging-worker (build if needed)

Prefer: melos run worker:serve | worker:once | worker:docker
EOF
}

check_supabase_reachable() {
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a

  if [[ "$SUPABASE_URL" == *127.0.0.1* || "$SUPABASE_URL" == *localhost* ]]; then
    if ! curl -sf "${SUPABASE_URL}/rest/v1/" -o /dev/null 2>/dev/null; then
      echo "ERROR: Supabase not reachable at ${SUPABASE_URL}"
      echo "       Run: supabase start && melos run env:sync"
      exit 1
    fi
  fi
}

run_dart() {
  local flag="$1"
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: Missing worker env file: ${ENV_FILE}"
    echo "       Run: melos run env:sync"
    exit 1
  fi
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
    if [[ ! -f "$ENV_FILE" ]]; then
      echo "ERROR: Missing worker env file: ${ENV_FILE}"
      echo "       Run: melos run env:sync"
      exit 1
    fi
    export WORKER_ENV_FILE="$ENV_FILE"
    cd "$ROOT"
    exec docker compose up --build messaging-worker
    ;;
  serve | once)
    check_supabase_reachable
    run_dart "--${MODE}"
    ;;
  *)
    echo "Unknown mode: ${MODE}"
    usage
    exit 64
    ;;
esac
