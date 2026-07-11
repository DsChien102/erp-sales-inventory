#!/usr/bin/env bash
# Thin Unix shim — prefer AOT binary, else dart run.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="$ROOT/.vet45/bin/vet45"
if [[ -x "$BIN" ]]; then
  exec "$BIN" "$@"
fi
echo "tip: run \`melos run env:build\` once for a faster AOT binary (falling back to dart run)" >&2
exec dart run "$ROOT/tools/vet45_env/bin/vet45_env.dart" "$@"
