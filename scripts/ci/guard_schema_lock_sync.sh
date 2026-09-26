#!/usr/bin/env bash
# Warn (slice) / fail (promote-release) when declarative sources drift from schema.lock.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

dart run tools/vet45_supabase_migrate/bin/verify_schema_lock_sync.dart "$@"
