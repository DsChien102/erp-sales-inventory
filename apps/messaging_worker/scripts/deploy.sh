#!/usr/bin/env bash
# Compatibility wrapper. Publish only — does not redeploy or set secrets.
#
#   ./apps/messaging_worker/scripts/publish.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> deploy.sh publishes the image only (no hosting target configured)."
"${SCRIPT_DIR}/publish.sh" "$@"
