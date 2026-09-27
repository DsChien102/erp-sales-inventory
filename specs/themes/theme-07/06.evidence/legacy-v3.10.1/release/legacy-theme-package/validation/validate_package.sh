#!/usr/bin/env bash
set -euo pipefail
PACKAGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$PACKAGE_ROOT/validation/validate-package.py"
python3 "$PACKAGE_ROOT/design-readiness/validate-design-readiness.py"
node "$PACKAGE_ROOT/prototype/scripts/validate-prototype.mjs"
node "$PACKAGE_ROOT/outbound/prototype-v4.0.0/scripts/validate-prototype.mjs"
HARNESS_TMP="$(mktemp -d "${TMPDIR:-/tmp}/t7-harness-validate.XXXXXX")"
trap 'rm -rf "$HARNESS_TMP"' EXIT
cp -a "$PACKAGE_ROOT/harness/." "$HARNESS_TMP/"
(
  cd "$HARNESS_TMP"
  python3 validate_harness_pack.py . --strict
)
