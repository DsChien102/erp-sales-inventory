#!/usr/bin/env bash
# Run `railway config` with Node 22. tsx (via railway-iac-ts) cannot resolve
# `railway/iac` on Node 24.
set -euo pipefail

RAILWAY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "${RAILWAY_DIR}/.." && pwd)"
cd "$ROOT"
export PATH="${RAILWAY_DIR}/node_modules/.bin:${PATH}"

if [[ ! -x "${RAILWAY_DIR}/node_modules/.bin/railway-iac-ts" ]]; then
  echo "Missing railway-iac-ts. From .railway: npm install"
  exit 1
fi

run_config() {
  railway config "$@"
}

node_major() {
  node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0
}

if [[ "$(node_major)" == "22" ]]; then
  run_config "$@"
  exit $?
fi

if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
  nvm exec 22 -- railway config "$@"
  exit $?
fi

echo "railway config requires Node 22 (current: $(node -v 2>/dev/null || echo none))."
echo "Install Node 22 (nvm install 22) then: nvm exec 22 -- railway config $*"
exit 1
