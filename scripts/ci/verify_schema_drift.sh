#!/usr/bin/env bash
# After supabase db reset, fail if declarative SQL sources drift from the DB.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

if ! command -v supabase >/dev/null 2>&1; then
  echo "error: supabase CLI is required for schema drift verify" >&2
  exit 1
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "error: dart SDK is required for schema drift verify" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required for supabase start / db reset" >&2
  exit 1
fi

echo "==> supabase start"
supabase start

echo "==> supabase db reset"
supabase db reset --yes

echo "==> resolve local database URL"
status_env="$(supabase status -o env 2>/dev/null || true)"
db_url="$(printf '%s\n' "$status_env" | sed -n 's/^DB_URL=//p' | tr -d '"' | head -1)"
if [[ -z "${db_url}" ]]; then
  db_url="$(printf '%s\n' "$status_env" | sed -n 's/^DATABASE_URL=//p' | tr -d '"' | head -1)"
fi
if [[ -z "${db_url}" ]]; then
  echo "error: could not read DB_URL from supabase status" >&2
  supabase status >&2 || true
  exit 1
fi

echo "==> schema:verify-drift"
dart run tools/vet45_supabase_migrate/bin/verify_schema_drift.dart \
  --database-url "$db_url"
