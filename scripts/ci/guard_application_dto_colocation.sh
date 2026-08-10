#!/usr/bin/env bash
# Enforce DTO colocation in application packages — no global dto/ bucket, no bundled *_dtos.dart.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0

report() {
  echo "ERROR: $1"
  failed=1
}

while IFS= read -r -d '' dto_dir; do
  rel="${dto_dir#$root/}"
  report "global application dto/ folder forbidden (colocate DTOs per use-case): $rel"
done < <(find "$root/modules" -path '*/application/lib/src/dto' -type d -print0 2>/dev/null)

while IFS= read -r -d '' bundled; do
  report "bundled DTO file forbidden (one DTO per file): ${bundled#$root/}"
done < <(find "$root/modules" -path '*/application/lib/src/*' -name '*_dtos.dart' -print0 2>/dev/null)

if [[ "$failed" -ne 0 ]]; then
  echo "Fix: colocate DTOs in <aggregate>/commands/<use_case>/, <aggregate>/queries/<use_case>/, or <aggregate>/shared/"
  echo "See .cursor/skills/application-layer/SKILL.md — DTO colocation rules"
  exit 1
fi

echo "OK: application DTO colocation guard passed"
