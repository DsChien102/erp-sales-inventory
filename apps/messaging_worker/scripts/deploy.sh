#!/usr/bin/env bash
# Compatibility wrapper. Publish only — does not redeploy or set secrets.
#
#   ./apps/messaging_worker/scripts/publish.sh
#   vet45 run railway rollout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> deploy.sh now publishes the image only (no Railway redeploy)."
"${SCRIPT_DIR}/publish.sh" "$@"
echo "Railway pull is separate: vet45 run railway rollout"
