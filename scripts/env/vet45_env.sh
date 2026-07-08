#!/usr/bin/env bash
# Thin Unix shim — delegates to cross-platform Dart CLI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec dart run "$ROOT/tools/vet45_env/bin/vet45_env.dart" "$@"
