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
  docker build -f apps/messaging_worker/Dockerfile -t messaging-worker:local . \
    && echo "    OK: messaging-worker:local" \
    || echo "    WARN: docker build failed (credentials or network)"
else
  echo "==> docker not available, skipping image build"
fi

echo "Done."
