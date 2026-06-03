#!/usr/bin/env bash
# Fail if any infrastructure package still depends on Flutter or supabase_flutter.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pubspecs=(
  "$root/packages/vet45_shared/infrastructure/pubspec.yaml"
  "$root"/modules/*/infrastructure/pubspec.yaml
)

failed=0
for f in "${pubspecs[@]}"; do
  [[ -f "$f" ]] || continue
  if rg -q "^\s*(flutter:|supabase_flutter:)" "$f"; then
    echo "ERROR: $f still lists flutter or supabase_flutter in dependencies"
    failed=1
  fi
  if rg -q "^\s*flutter:" "$f" && rg -q "sdk:\s*flutter" "$f"; then
    echo "ERROR: $f still uses flutter SDK in environment or dependencies"
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: infrastructure packages are Dart-only (no flutter / supabase_flutter in pubspec dependencies)"
