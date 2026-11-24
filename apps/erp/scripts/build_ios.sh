#!/usr/bin/env bash
# Build ERP iOS IPA for staging or production flavor.
#
# Usage:
#   ./apps/erp/scripts/build_ios.sh --env staging|production|development|local
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV_NAME="production"
OBFUSCATE_ARGS=(--obfuscate --split-debug-info=build.artifact)

usage() {
  echo "Usage: $0 [--env staging|production|development|local]"
  exit 1
}

map_flavor() {
  case "$1" in
    development | local) echo "development" ;;
    staging) echo "staging" ;;
    production) echo "production" ;;
    *) echo "Invalid --env: $1 (expected staging|production|development|local)" >&2; exit 1 ;;
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

FLAVOR="$(map_flavor "$ENV_NAME")"

# File biến môi trường: ưu tiên apps/erp/.env.<env>, nếu không có thì dùng apps/erp/.env.
# Có thể ghi đè bằng ERP_ENV_FILE=/đường/dẫn/file.env
if [[ -n "${ERP_ENV_FILE:-}" ]]; then
  TARGET_erp_ENV_FILE="$ERP_ENV_FILE"
elif [[ -f "${APP_DIR}/.env.${ENV_NAME}" ]]; then
  TARGET_erp_ENV_FILE="${APP_DIR}/.env.${ENV_NAME}"
else
  TARGET_erp_ENV_FILE="${APP_DIR}/.env"
fi

if [[ ! -f "$TARGET_erp_ENV_FILE" ]]; then
  echo "Missing env file: ${TARGET_erp_ENV_FILE}"
  echo "Create apps/erp/.env (or .env.${ENV_NAME}) with APP_ENV, SUPABASE_CONNECTION_URL, SUPABASE_ANON_KEY"
  exit 1
fi

ERP_ENV_BASENAME="$(basename "$TARGET_erp_ENV_FILE")"
TARGET_erp_FLAVOR="$FLAVOR"

echo "==> Building iOS IPA"
echo "    flavor: ${TARGET_erp_FLAVOR}"
echo "    env file: ${TARGET_erp_ENV_FILE}"

cd "$APP_DIR"

flutter build ipa \
  --flavor "$TARGET_erp_FLAVOR" \
  --dart-define-from-file="$ERP_ENV_BASENAME" \
  "${OBFUSCATE_ARGS[@]}"

echo "==> IPA ready under ${APP_DIR}/build/ios/ipa/"
