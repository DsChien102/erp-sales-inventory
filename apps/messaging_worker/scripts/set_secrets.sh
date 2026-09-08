#!/usr/bin/env bash
# Wrapper. Secret push lives in .railway/scripts/sync-env.sh
# (shared keys + messaging-worker secrets). Knobs stay in railway.ts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "==> set_secrets.sh delegates to railway sync-env"
exec "$ROOT/.railway/scripts/sync-env.sh" "$@"
