#!/usr/bin/env bash
# Umbrella script for harness mechanical enforcement checks.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

echo "==> guard_infra_dart_only"
"$root/scripts/ci/guard_infra_dart_only.sh"

echo "==> guard_layer_imports"
"$root/scripts/ci/guard_layer_imports.sh"

echo "==> guard_docs_reference"
"$root/scripts/ci/guard_docs_reference.sh"

echo "==> guard_theme_structure"
"$root/scripts/ci/guard_theme_structure.sh"

echo "==> guard_theme_traceability"
"$root/scripts/ci/guard_theme_traceability.sh"

echo "==> guard_presentation_size"
"$root/scripts/ci/guard_presentation_size.sh"

echo "==> guard_presentation_dialogs"
GUARD_PRESENTATION_DIALOGS_LEGACY=1 "$root/scripts/ci/guard_presentation_dialogs.sh"

echo "==> guard_codegen_fresh"
"$root/scripts/ci/guard_codegen_fresh.sh"

echo "OK: all harness guards passed"
