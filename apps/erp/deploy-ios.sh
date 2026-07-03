#!/usr/bin/env bash
# Upload ERP iOS IPA to TestFlight via App Store Connect API.
#
# Usage:
#   ./apps/erp/deploy-ios.sh [--env staging|production]
#
# Requires APP_STORE_CONNECT_* in synced ERP env file (melos run env:sync).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="${SCRIPT_DIR}"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_NAME="production"

usage() {
  echo "Usage: $0 [--env staging|production]"
  exit 1
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

case "$ENV_NAME" in
  staging | production) ;;
  *)
    echo "Invalid --env: $ENV_NAME (expected staging or production)"
    exit 1
    ;;
esac

expected_bundle_id() {
  case "$1" in
    staging) echo "com.agapi.vet45.staging" ;;
    production) echo "com.agapi.vet45" ;;
  esac
}

"$ROOT/scripts/env/vet45_env.sh" sync --env "$ENV_NAME" >/dev/null
RESOLVED="$("$ROOT/scripts/env/vet45_env.sh" resolve-shell --env "$ENV_NAME")"
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  export "$line"
done <<<"$RESOLVED"

if [[ ! -f "${ERP_ENV_FILE:-}" ]]; then
  echo "Missing env file: ${ERP_ENV_FILE:-}"
  echo "Run: melos run env:sync -- --env ${ENV_NAME}"
  exit 1
fi

# shellcheck disable=SC1090
set -a && source "$ERP_ENV_FILE" && set +a

: "${APP_STORE_CONNECT_KEY_IDENTIFIER:?Set APP_STORE_CONNECT_KEY_IDENTIFIER in config/secrets and re-run env:sync}"
: "${APP_STORE_CONNECT_ISSUER_ID:?Set APP_STORE_CONNECT_ISSUER_ID in config/secrets and re-run env:sync}"

IPA_GLOB="${APP_DIR}/build/ios/ipa/*.ipa"
shopt -s nullglob
IPAS=($IPA_GLOB)
shopt -u nullglob

if [[ ${#IPAS[@]} -eq 0 ]]; then
  echo "No IPA found at ${IPA_GLOB}"
  echo "Run: melos run build:ios  (or ./apps/erp/scripts/build_ios.sh --env ${ENV_NAME})"
  exit 1
fi

IPA_PATH="${IPAS[0]}"
EXPECTED_ID="$(expected_bundle_id "$ENV_NAME")"

echo "==> Uploading ${IPA_PATH}"
echo "    target ASC env: ${ENV_NAME}"
echo "    expected bundle id: ${EXPECTED_ID}"
echo "    env file: ${ERP_ENV_FILE}"

xcrun altool --upload-app --type ios -f "$IPA_PATH" \
  --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

echo "==> Upload complete for ${ENV_NAME}"
