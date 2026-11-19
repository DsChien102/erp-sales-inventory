#!/usr/bin/env bash
# Build ERP iOS IPA for staging or production flavor.
#
# Usage:
#   ./apps/erp/scripts/build_ios.sh --env staging|production|development|local
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

ENV_NAME="production"
OBFUSCATE_ARGS=(--obfuscate --split-debug-info=build.artifact)

usage() {
  echo "Usage: $0 [--env staging|production|development|local]"
  exit 1
}

map_manifest_env() {
  case "$1" in
    development) echo "development" ;;
    local) echo "local" ;;
    staging) echo "staging" ;;
    production) echo "production" ;;
    *) echo "$1" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV_NAME="$2"
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

MANIFEST_ENV="$(map_manifest_env "$ENV_NAME")"
"$ROOT/scripts/env/c45_env.sh" sync --env "$MANIFEST_ENV" >/dev/null

RESOLVED="$("$ROOT/scripts/env/c45_env.sh" resolve-shell --env "$MANIFEST_ENV")"
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  export "$line"
done <<<"$RESOLVED"

if [[ ! -f "${TARGET_erp_ENV_FILE:-}" ]]; then
  echo "Missing env file: ${TARGET_erp_ENV_FILE:-}"
  echo "Run: c45 sync --env ${MANIFEST_ENV} --target erp"
  exit 1
fi

ERP_ENV_BASENAME="$(basename "$TARGET_erp_ENV_FILE")"

echo "==> Building iOS IPA"
echo "    flavor: ${TARGET_erp_FLAVOR}"
echo "    env file: ${TARGET_erp_ENV_FILE}"

cd "$APP_DIR"

flutter build ipa \
  --flavor "$TARGET_erp_FLAVOR" \
  --dart-define-from-file="$ERP_ENV_BASENAME" \
  "${OBFUSCATE_ARGS[@]}"

echo "==> IPA ready under ${APP_DIR}/build/ios/ipa/"
