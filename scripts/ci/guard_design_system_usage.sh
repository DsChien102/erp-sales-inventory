#!/usr/bin/env bash
# Fail when presentation UI bypasses vet45_design_system layout/overlay/typography rules.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0
legacy_mode="${GUARD_DESIGN_SYSTEM_LEGACY:-0}"

report() {
  if [[ "$legacy_mode" == "1" ]]; then
    echo "WARN: $1"
    return
  fi
  echo "ERROR: $1"
  failed=1
}

is_enforced_file() {
  local file="$1"
  local rel="${file#$root/}"

  # Inline bypass (per-file escape hatch).
  if rg -q 'harness:allow-design-system-bypass' "$file" 2>/dev/null; then
    return 1
  fi

  # Scope: catalog presentation only (expand in later waves).
  case "$rel" in
    apps/erp/lib/features/catalog/presentation/*)
      # Golden lane: enforce product control center first.
      case "$rel" in
        *product_control_center*) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    modules/catalog/presentation/*)
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

check_magic_spacing() {
  local file="$1"
  if rg -n 'EdgeInsets\.(all|symmetric|only)\(\s*[0-9]' "$file" 2>/dev/null; then
    report "magic EdgeInsets literal — use VSpacing / VGap / VPagePadding: $file"
  fi
}

check_raw_overlays() {
  local file="$1"
  if rg -q '\bAlertDialog\s*\(' "$file" 2>/dev/null; then
    report "raw AlertDialog — use showVConfirmDialog + widgets/: $file"
  fi
  if rg -q '\bshowModalBottomSheet\s*\(' "$file" 2>/dev/null; then
    report "raw showModalBottomSheet — use showVBottomSheet: $file"
  fi
}

check_raw_text() {
  local file="$1"
  # Match Text( but not VText(, TextSpan(, TextStyle(, TextButton(, TextField(, etc.
  if rg -n '(?<![A-Za-z])Text\s*\(' "$file" -P 2>/dev/null | rg -v 'TextSpan|TextStyle|TextButton|TextField|TextEditing|TextAlign|TextOverflow|TextDirection|TextPainter|TextInput' >/dev/null; then
    local hits
    hits=$(rg -n '(?<![A-Za-z])Text\s*\(' "$file" -P 2>/dev/null | rg -v 'TextSpan|TextStyle|TextButton|TextField|TextEditing|TextAlign|TextOverflow|TextDirection|TextPainter|TextInput' || true)
    if [[ -n "$hits" ]]; then
      report "raw Text( — use VText: $file"
      echo "$hits" | head -5
    fi
  fi
}

check_file() {
  local file="$1"
  [[ "$file" == *.g.dart ]] && return
  [[ "$file" == */test/* ]] && return

  if ! is_enforced_file "$file"; then
    return
  fi

  check_magic_spacing "$file"
  check_raw_overlays "$file"
  check_raw_text "$file"
}

while IFS= read -r -d '' file; do
  check_file "$file"
done < <(
  find "$root/apps/erp/lib/features/catalog/presentation" -name '*.dart' -print0 2>/dev/null
  find "$root/modules/catalog/presentation" -name '*.dart' -print0 2>/dev/null
)

if [[ "$failed" -ne 0 ]]; then
  echo "Hint: see packages/vet45_design_system/docs/polaris/06-design-system-spec.md"
  echo "Bypass: add // harness:allow-design-system-bypass at top of file (temporary)"
  exit 1
fi

echo "OK: design system usage guard passed (enforced scope)"
