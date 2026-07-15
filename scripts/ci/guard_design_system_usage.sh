#!/usr/bin/env bash
# Fail when presentation UI bypasses vet45_design_system layout/overlay/typography rules.
#
# Tiers:
#   ENFORCED  — ERROR / exit 1 (golden migrated surfaces)
#   MONITORED — WARN only (debt visibility; expand enforce when lane migrated)
#
# Env:
#   GUARD_DESIGN_SYSTEM_LEGACY=1  — treat ENFORCED as WARN (never fail)
#   GUARD_DESIGN_SYSTEM_STRICT=1  — treat MONITORED as ERROR (full fail)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0
warn_count=0
legacy_mode="${GUARD_DESIGN_SYSTEM_LEGACY:-0}"
strict_mode="${GUARD_DESIGN_SYSTEM_STRICT:-0}"

report_error() {
  if [[ "$legacy_mode" == "1" ]]; then
    echo "WARN: $1"
    warn_count=$((warn_count + 1))
    return
  fi
  echo "ERROR: $1"
  failed=1
}

report_warn() {
  if [[ "$strict_mode" == "1" ]]; then
    report_error "$1"
    return
  fi
  echo "WARN: $1"
  warn_count=$((warn_count + 1))
}

# Returns: enforced | monitored | skip
file_tier() {
  local file="$1"
  local rel="${file#$root/}"

  if rg -q 'harness:allow-design-system-bypass' "$file" 2>/dev/null; then
    echo skip
    return
  fi

  # Non-UI artifacts under presentation trees
  case "$rel" in
    */bloc/*|*_cubit.dart|*_state.dart|*_formatters.dart|*/mappers/*|*/models/*|*/services/*|*/data/*)
      echo skip
      return
      ;;
  esac

  # --- ENFORCED (golden) ---
  case "$rel" in
    apps/erp/lib/features/catalog/presentation/pages/product_control_center_page.dart|\
    apps/erp/lib/features/catalog/presentation/widgets/product_control_center_*|\
    apps/erp/lib/features/catalog/presentation/pages/product_catalog_tab_page.dart|\
    apps/erp/lib/features/catalog/presentation/widgets/product_catalog_*|\
    apps/erp/lib/features/catalog/presentation/widgets/product_list_filter.dart)
      echo enforced
      return
      ;;
  esac

  # --- MONITORED (scan / warn) ---
  case "$rel" in
    apps/erp/lib/features/*/presentation/*|\
    modules/*/presentation/lib/src/widgets/*)
      echo monitored
      return
      ;;
  esac

  echo skip
}

emit() {
  local tier="$1"
  local msg="$2"
  if [[ "$tier" == "enforced" ]]; then
    report_error "$msg"
  else
    report_warn "$msg"
  fi
}

check_magic_spacing() {
  local file="$1"
  local tier="$2"
  if rg -q 'EdgeInsets\.(all|symmetric|only)\(\s*[0-9]' "$file" 2>/dev/null; then
    emit "$tier" "magic EdgeInsets literal — use VSpacing / VGap / VPagePadding: $file"
    rg -n 'EdgeInsets\.(all|symmetric|only)\(\s*[0-9]' "$file" 2>/dev/null | head -5 || true
  fi
}

check_raw_overlays() {
  local file="$1"
  local tier="$2"
  if rg -q '\bAlertDialog\s*\(' "$file" 2>/dev/null; then
    emit "$tier" "raw AlertDialog — use showVConfirmDialog + widgets/: $file"
  fi
  if rg -q '\bshowModalBottomSheet\s*\(' "$file" 2>/dev/null; then
    emit "$tier" "raw showModalBottomSheet — use showVBottomSheet: $file"
  fi
  if rg -q '\bElevatedButton\s*\(' "$file" 2>/dev/null; then
    emit "$tier" "raw ElevatedButton — use VButton: $file"
  fi
}

check_raw_text() {
  local file="$1"
  local tier="$2"
  local hits
  hits=$(rg -n '(?<![A-Za-z])Text\s*\(' "$file" -P 2>/dev/null | rg -v 'TextSpan|TextStyle|TextButton|TextField|TextEditing|TextAlign|TextOverflow|TextDirection|TextPainter|TextInput|TextTheme|TextScaler' || true)
  if [[ -n "$hits" ]]; then
    emit "$tier" "raw Text( — use VText: $file"
    echo "$hits" | head -5
  fi
}

check_raw_scaffold() {
  local file="$1"
  local tier="$2"
  # Only pages: prefer VPageScaffold for app-bar shells
  case "$file" in
    *_page.dart|*_screen.dart) ;;
    *) return ;;
  esac
  if rg -q '\bScaffold\s*\(' "$file" 2>/dev/null && ! rg -q '\bVPageScaffold\s*\(' "$file" 2>/dev/null; then
    emit "$tier" "raw Scaffold — prefer VPageScaffold for page shells: $file"
  fi
}

check_raw_colors() {
  local file="$1"
  local tier="$2"
  local hits
  hits=$(rg -n '\bColors\.(grey|black|white|red|blue|green)\b' "$file" 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    emit "$tier" "raw Colors.* — use context.vColors / VColors semantic: $file"
    echo "$hits" | head -5
  fi
}

check_file() {
  local file="$1"
  [[ "$file" == *.g.dart ]] && return
  [[ "$file" == */test/* ]] && return

  local tier
  tier=$(file_tier "$file")
  if [[ "$tier" == "skip" ]]; then
    return
  fi

  check_magic_spacing "$file" "$tier"
  check_raw_overlays "$file" "$tier"
  check_raw_text "$file" "$tier"
  check_raw_scaffold "$file" "$tier"
  check_raw_colors "$file" "$tier"
}

while IFS= read -r -d '' file; do
  check_file "$file"
done < <(
  find "$root/apps/erp/lib/features" -path '*/presentation/*' -name '*.dart' -print0 2>/dev/null
  find "$root/modules" -path '*/presentation/lib/src/widgets/*' -name '*.dart' -print0 2>/dev/null
)

echo ""
echo "Summary: enforced lane = product_control_center* + product_catalog*"
echo "         monitored = apps/erp features presentation + modules/*/presentation widgets"
if [[ "$warn_count" -gt 0 ]]; then
  echo "WARN count: $warn_count (set GUARD_DESIGN_SYSTEM_STRICT=1 to fail on monitored)"
fi

if [[ "$failed" -ne 0 ]]; then
  echo "Hint: packages/vet45_design_system/docs/polaris/07-token-migration-checklist.md"
  echo "      packages/vet45_design_system/docs/polaris/09-adoption-checklist.md"
  echo "Bypass (temporary): // harness:allow-design-system-bypass"
  exit 1
fi

echo "OK: design system usage guard passed (enforced lane clean)"
