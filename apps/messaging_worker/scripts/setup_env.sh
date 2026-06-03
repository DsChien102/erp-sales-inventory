#!/usr/bin/env bash
# Bootstrap apps/messaging_worker/.env from ERP Supabase URL + generated tick secret.
# Add SUPABASE_SERVICE_ROLE_KEY manually from Supabase Dashboard → Settings → API.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ERP_ENV="${ROOT}/apps/erp/.env"
WORKER_ENV="${ROOT}/apps/messaging_worker/.env"

if [[ ! -f "$ERP_ENV" ]]; then
  echo "Missing ${ERP_ENV}"
  exit 1
fi

read_env_value() {
  local file="$1" key="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" || true
}

url="$(read_env_value "$ERP_ENV" SUPABASE_URL)"
if [[ -z "$url" ]]; then
  url="$(read_env_value "$ERP_ENV" SUPABASE_CONNECTION_URL)"
fi
if [[ -z "$url" ]]; then
  echo "No SUPABASE_URL or SUPABASE_CONNECTION_URL in ${ERP_ENV}"
  exit 1
fi

tick_secret=""
if [[ -f "$WORKER_ENV" ]]; then
  tick_secret="$(read_env_value "$WORKER_ENV" WORKER_TICK_SECRET)"
fi
if [[ -z "$tick_secret" ]]; then
  tick_secret=$(openssl rand -hex 32)
fi

existing_service_role=""
if [[ -f "$WORKER_ENV" ]]; then
  existing_service_role="$(read_env_value "$WORKER_ENV" SUPABASE_SERVICE_ROLE_KEY)"
fi

cat > "$WORKER_ENV" <<EOF
SUPABASE_URL=${url}
SUPABASE_SERVICE_ROLE_KEY=${existing_service_role}
WORKER_TICK_SECRET=${tick_secret}

# Optional tuning (defaults shown)
WORKER_TENANT_BATCH_SIZE=20
WORKER_MODULE_BATCH_SIZE=10
WORKER_MAX_ROUNDS_PER_TICK=5

# Adaptive self-loop tick intervals (seconds)
WORKER_TICK_ACTIVE_SECONDS=3
WORKER_TICK_IDLE_SECONDS=15
WORKER_TICK_MAX_IDLE_SECONDS=30

# HTTP port when running --serve locally (Railway sets PORT automatically)
PORT=8080
EOF

if [[ -z "$existing_service_role" ]]; then
  echo "Wrote ${WORKER_ENV}. Set SUPABASE_SERVICE_ROLE_KEY, then run:"
  echo "  ./apps/messaging_worker/scripts/deploy.sh --env staging --secrets"
else
  echo "Wrote ${WORKER_ENV} (preserved existing service role)."
fi
