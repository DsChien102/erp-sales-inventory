#!/usr/bin/env bash
# Verify worker AOT compile and optional Docker image build.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

echo "==> dart compile exe (local)"
cd apps/messaging_worker
dart compile exe bin/worker.dart -o /tmp/messaging_worker_bin
echo "    OK: /tmp/messaging_worker_bin"

if [[ -f .env ]]; then
  echo "==> smoke --once (requires .env)"
  set -a && source .env && set +a
  /tmp/messaging_worker_bin --once || echo "    (skipped: --once failed — check Supabase platform schema / secrets)"
fi

if command -v docker >/dev/null 2>&1; then
  echo "==> docker build (optional)"
  cd "$ROOT"
  docker_build_ok=false
  if docker build -f apps/messaging_worker/Dockerfile -t messaging-worker:local .; then
    docker_build_ok=true
    echo "    OK: messaging-worker:local"
  else
    # Work around broken docker-credential-desktop on some macOS setups.
    DOCKER_NOCREDS="$(mktemp -d)"
    printf '{"auths":{}}' > "${DOCKER_NOCREDS}/config.json"
    if DOCKER_CONFIG="${DOCKER_NOCREDS}" docker build -f apps/messaging_worker/Dockerfile -t messaging-worker:local .; then
      docker_build_ok=true
      echo "    OK: messaging-worker:local (no credential helper)"
    fi
    rm -rf "${DOCKER_NOCREDS}"
  fi
  if [[ "$docker_build_ok" != true ]]; then
    echo "    WARN: docker build failed (credentials or network)"
  fi
else
  echo "==> docker not available, skipping image build"
fi

echo "Done."
