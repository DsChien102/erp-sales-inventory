#!/usr/bin/env bash
# Warn when generated *.g.dart files are stale after codegen.
# Strict mode (GUARD_CODEGEN_STRICT=1) fails CI — enable after IAM golden module lands.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

if [[ "${GUARD_CODEGEN_STRICT:-0}" != "1" ]]; then
  echo "SKIP: guard_codegen_fresh (set GUARD_CODEGEN_STRICT=1 to enforce)"
  exit 0
fi

if [[ "${GUARD_CODEGEN_SKIP_BOOTSTRAP:-0}" != "1" ]]; then
  dart pub get >/dev/null
  (cd apps/erp && dart run build_runner build --delete-conflicting-outputs)
fi

if ! git diff --quiet -- '**/*.g.dart'; then
  echo "ERROR: generated *.g.dart files are stale — run: cd apps/erp && dart run build_runner build --delete-conflicting-outputs, then commit"
  git diff -- '**/*.g.dart' || true
  exit 1
fi

echo "OK: generated files are fresh"
