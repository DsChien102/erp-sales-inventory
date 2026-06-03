#!/usr/bin/env bash
# Build ERP iOS IPA for staging or production flavor.
#
# Usage:
#   ./apps/erp/scripts/build_ios.sh --env staging|production|development
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV_NAME="production"
OBFUSCATE_ARGS=(--obfuscate --split-debug-info=build.artifact)

usage() {
  echo "Usage: $0 [--env staging|production|development]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

case "$ENV_NAME" in
  development|staging|production) ;;
  *)
    echo "Invalid --env: $ENV_NAME (expected development, staging, or production)"
    exit 1
    ;;
esac

ENV_FILE="${APP_DIR}/.env.${ENV_NAME}"
if [[ "$ENV_NAME" == "development" ]]; then
  ENV_FILE="${APP_DIR}/.env"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: ${ENV_FILE}"
  echo "Copy from ${ENV_FILE}.example if available."
  exit 1
fi

echo "==> Building iOS IPA"
echo "    flavor: ${ENV_NAME}"
echo "    env file: ${ENV_FILE}"

cd "$APP_DIR"

flutter build ipa \
  --flavor "$ENV_NAME" \
  --dart-define-from-file="$ENV_FILE" \
  "${OBFUSCATE_ARGS[@]}"

echo "==> IPA ready under ${APP_DIR}/build/ios/ipa/"
