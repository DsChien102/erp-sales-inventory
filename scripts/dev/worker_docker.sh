#!/usr/bin/env bash
# Run messaging-worker via Docker Compose.
# Image is env-agnostic; runtime config comes from WORKER_ENV_FILE.
# When WORKER_SUPABASE_URL is set (vet45 env `local`), load the host-gateway overlay.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [[ -z "${WORKER_ENV_FILE:-}" ]]; then
  echo "ERROR: WORKER_ENV_FILE is required"
  echo "       Prefer: melos run worker:docker"
  exit 1
fi
if [[ ! -f "$WORKER_ENV_FILE" ]]; then
  echo "ERROR: Missing worker env file: ${WORKER_ENV_FILE}"
  echo "       Run: vet45 sync --target worker"
  exit 1
fi

files=(-f docker-compose.yml)
if [[ -n "${WORKER_SUPABASE_URL:-}" ]]; then
  files+=(-f docker-compose.local.yml)
fi

exec docker compose "${files[@]}" up --build messaging-worker
