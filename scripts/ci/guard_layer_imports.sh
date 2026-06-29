#!/usr/bin/env bash
# Fail on common layer import violations in module packages.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0

report() {
  echo "ERROR: $1"
  failed=1
}

# Domain: no supabase, flutter, or get_it imports.
while IFS= read -r -d '' file; do
  if rg -n "^\s*import\s+['\"]package:(supabase|flutter|get_it)" "$file" >/dev/null 2>&1; then
    report "domain layer must not import supabase/flutter/get_it: $file"
    rg -n "^\s*import\s+['\"]package:(supabase|flutter|get_it)" "$file" || true
  fi
done < <(find "$root/modules" -path '*/domain/lib/*.dart' -print0 2>/dev/null)

# Application: no infrastructure or supabase imports.
while IFS= read -r -d '' file; do
  if rg -n "^\s*import\s+['\"]package:vet45_[^'\"]+_infrastructure/" "$file" >/dev/null 2>&1; then
    report "application layer must not import infrastructure: $file"
    rg -n "^\s*import\s+['\"]package:vet45_[^'\"]+_infrastructure/" "$file" || true
  fi
  if rg -n "^\s*import\s+['\"]package:supabase" "$file" >/dev/null 2>&1; then
    report "application layer must not import supabase: $file"
    rg -n "^\s*import\s+['\"]package:supabase" "$file" || true
  fi
done < <(find "$root/modules" -path '*/application/lib/*.dart' -print0 2>/dev/null)

# Cross-package src/ imports (deep imports into another package's private API).
while IFS= read -r -d '' file; do
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
  if [[ "$line" =~ import[[:space:]]+[\'\"]package:([^/\'\"]+)/src/ ]]; then
      imported_pkg="${BASH_REMATCH[1]}"
      # Resolve owning package from file path: .../modules/foo/application/lib/... or packages/...
      if [[ "$file" =~ /modules/([^/]+)/([^/]+)/lib/ ]]; then
        owner="vet45_${BASH_REMATCH[1]}_${BASH_REMATCH[2]}"
      elif [[ "$file" =~ /packages/([^/]+)/lib/ ]]; then
        owner="${BASH_REMATCH[1]}"
      elif [[ "$file" =~ /packages/vet45_shared/([^/]+)/lib/ ]]; then
        owner="vet45_shared_${BASH_REMATCH[1]}"
      elif [[ "$file" =~ /apps/([^/]+)/lib/ ]]; then
        owner="${BASH_REMATCH[1]}"
      else
        owner=""
      fi
      if [[ "$imported_pkg" != "$owner" ]]; then
        report "cross-package src/ import in $file: $line"
      fi
    fi
  done < <(rg -n "^\s*import\s+['\"]package:[^'\"]+/src/" "$file" 2>/dev/null || true)
done < <(find "$root/modules" "$root/packages" "$root/apps" -name '*.dart' -path '*/lib/*' -print0 2>/dev/null)

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: no layer import violations detected"
