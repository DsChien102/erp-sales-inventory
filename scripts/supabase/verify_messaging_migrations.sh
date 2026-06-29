#!/usr/bin/env bash
# Applies Supabase migrations locally and runs messaging smoke + worker contract checks.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "ERROR: supabase CLI not found. Install: https://supabase.com/docs/guides/cli"
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql not found (required for smoke test)."
  exit 1
fi

echo "Resetting local database (applies all migrations)..."
supabase db reset --yes

echo "Running messaging smoke test..."
"$ROOT/scripts/supabase/run_messaging_smoke_test.sh"

if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "Running worker contract verify (remote/staging)..."
  "$ROOT/apps/messaging_worker/scripts/verify_supabase.sh"
else
  echo "Skipping verify_supabase.sh (set SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY for remote check)."
  echo "Local worker contract: platform.list_tenants_with_pending_messaging + messaging_backlog_stats exist after reset."
fi

echo "All local messaging migration checks passed."
