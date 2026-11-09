#!/usr/bin/env bash
# Fail when presentation page/screen files exceed the line limit.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
max_lines=500
failed=0

report() {
  echo "ERROR: $1"
  failed=1
}

check_file() {
  local file="$1"
  local lines
  lines=$(wc -l <"$file" | tr -d ' ')
  if [[ "$lines" -gt "$max_lines" ]]; then
    report "presentation file exceeds ${max_lines} lines ($lines): $file"
  fi
}

while IFS= read -r -d '' file; do
  check_file "$file"
done < <(find "$root/apps/erp/lib" \( -name '*_page.dart' -o -name '*_screen.dart' \) -print0 2>/dev/null)

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: presentation file sizes within ${max_lines} lines"
