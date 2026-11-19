#!/usr/bin/env bash
# Thin Unix shim — prefer AOT binary, else dart run.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="$ROOT/.c45/bin/c45"
if [[ -x "$BIN" ]]; then
  exec "$BIN" "$@"
fi
echo "tip: run \`melos run env:build\` once for a faster AOT binary (falling back to dart run)" >&2
exec dart run "$ROOT/tools/c45_env/bin/c45_env.dart" "$@"
