#!/usr/bin/env bash
# Build messaging-worker image and push it to the registry in WORKER_IMAGE.
# Does not deploy anything; no hosting target is configured yet.
#
# Pushes:
#   ${WORKER_IMAGE}:<pubspec version>
#   ${WORKER_IMAGE}:<staging|production>
#
# Usage:
#   ./apps/messaging_worker/scripts/publish.sh [--env staging|production] [--verify] [--ci]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

RAILWAY_ENV="${RAILWAY_ENVIRONMENT:-staging}"
IMAGE="${WORKER_IMAGE:?Set WORKER_IMAGE (e.g. ghcr.io/<owner>/messaging-worker)}"
PLATFORM="${WORKER_IMAGE_PLATFORM:-linux/amd64}"
RUN_VERIFY=false
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      RAILWAY_ENV="$2"
      shift 2
      ;;
    --verify) RUN_VERIFY=true; shift ;;
    --ci) CI_MODE=true; shift ;;
    --secrets)
      echo "ERROR: --secrets is no longer supported (no hosting target configured)"
      exit 1
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--env staging|production] [--verify] [--ci]"
      exit 1
      ;;
  esac
done

case "$RAILWAY_ENV" in
  staging|production) ;;
  *)
    echo "ERROR: --env must be staging or production (got: ${RAILWAY_ENV})"
    exit 1
    ;;
esac

read_version() {
  awk '/^version:/ { print $2; exit }' "$ROOT/apps/messaging_worker/pubspec.yaml"
}

load_local_env() {
  if [[ "$CI_MODE" == true ]]; then
    return 0
  fi
  "$ROOT/scripts/env/vet45_env.sh" sync --env "$RAILWAY_ENV" >/dev/null || true
  local resolved
  resolved="$("$ROOT/scripts/env/vet45_env.sh" resolve-shell --env "$RAILWAY_ENV")"
  local env_file=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == TARGET_worker_ENV_FILE=* ]]; then
      env_file="${line#TARGET_worker_ENV_FILE=}"
    fi
  done <<<"$resolved"
  if [[ -n "$env_file" && -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    set -a && source "$env_file" && set +a
  fi
}

if [[ "$RUN_VERIFY" == true ]]; then
  echo "==> Verifying build"
  "${SCRIPT_DIR}/verify_build.sh"

  echo "==> Verifying Supabase platform migration"
  if [[ "$CI_MODE" == true ]]; then
    "${SCRIPT_DIR}/verify_supabase.sh"
  else
    load_local_env
    "${SCRIPT_DIR}/verify_supabase.sh"
  fi
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required to build and push the worker image"
  exit 1
fi

VERSION="$(read_version)"
if [[ -z "$VERSION" ]]; then
  echo "ERROR: could not read version from apps/messaging_worker/pubspec.yaml"
  exit 1
fi

VERSION_REF="${IMAGE}:${VERSION}"
ENV_REF="${IMAGE}:${RAILWAY_ENV}"

echo "==> Building ${VERSION_REF} (${PLATFORM})"
cd "$ROOT"
docker build \
  --platform "$PLATFORM" \
  --provenance=false \
  --sbom=false \
  -f apps/messaging_worker/Dockerfile \
  -t "$VERSION_REF" \
  -t "$ENV_REF" \
  .

echo "==> Pushing ${VERSION_REF}"
docker push "$VERSION_REF"
echo "==> Pushing ${ENV_REF} (Railway environment pointer)"
docker push "$ENV_REF"

echo "Published ${VERSION_REF} -> ${ENV_REF}."
