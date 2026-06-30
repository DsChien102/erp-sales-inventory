#!/usr/bin/env bash
# Fail when pages/screens define inline AlertDialog/Dialog instead of extracted widgets.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0
legacy_mode="${GUARD_PRESENTATION_DIALOGS_LEGACY:-0}"

report() {
  echo "ERROR: $1"
  failed=1
}

is_legacy_allowed() {
  local file="$1"
  if [[ "$legacy_mode" == "1" ]]; then
    return 0
  fi
  if rg -q 'harness:allow-inline-dialog' "$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

check_page_file() {
  local file="$1"

  if is_legacy_allowed "$file"; then
    return
  fi

  if ! rg -q 'showDialog\s*\(' "$file" 2>/dev/null; then
    return
  fi

  if rg -q 'AlertDialog\s*\(' "$file" 2>/dev/null || rg -q '\bDialog\s*\(' "$file" 2>/dev/null; then
    report "inline dialog in page — extract to widgets/: $file"
  fi
}

while IFS= read -r -d '' file; do
  check_page_file "$file"
done < <(find "$root/apps/erp/lib" \( -name '*_page.dart' -o -name '*_screen.dart' \) -print0 2>/dev/null)

if [[ "$failed" -ne 0 ]]; then
  echo "Hint: extract dialog to modules/<module>/presentation/lib/src/widgets/ or apps/erp/.../widgets/"
  echo "Legacy: set GUARD_PRESENTATION_DIALOGS_LEGACY=1 or add // harness:allow-inline-dialog at top of file"
  exit 1
fi

echo "OK: no inline dialogs in presentation pages"
