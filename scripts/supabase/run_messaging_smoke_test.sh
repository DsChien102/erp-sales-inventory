#!/usr/bin/env bash
# Runs messaging smoke test against local Supabase Postgres.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54422/postgres}"

echo "Running messaging smoke test against ${DB_URL}..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$ROOT/scripts/supabase/messaging_smoke_test.sql"
echo "Smoke test passed."
