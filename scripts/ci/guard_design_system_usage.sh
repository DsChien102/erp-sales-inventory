#!/usr/bin/env bash
# Wrapper to execute the Dart-based Design System Usage Guard.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dart run "$root/tools/guard_design_system_usage.dart"
