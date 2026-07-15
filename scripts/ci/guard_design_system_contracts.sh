#!/usr/bin/env bash
# Fail when design-system public widgets miss required Tone/Emphasis/State/semanticLabel
# contracts defined in docs/audit/contract_matrix.yaml.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root/packages/vet45_design_system"

echo "==> component_audit --fail-on-required"
dart run tool/component_audit.dart --fail-on-required

echo "OK: design system contracts (required) passed"
