#!/usr/bin/env bash
# Enforce application layer use_case subfolder layout for guarded feature areas.
# Golden reference: modules/partner/application/lib/src/business_partner/<use_case>/
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0

report() {
  echo "ERROR: $1"
  failed=1
}

# Areas that MUST use <feature_area>/<use_case>/ (no flat *.dart at feature root).
# Add new feature areas here when they adopt the partner/IAM layout.
guarded_areas=(
  "modules/catalog/application/lib/src/custom_fields"
)

for area in "${guarded_areas[@]}"; do
  area_path="$root/$area"
  [[ -d "$area_path" ]] || continue

  while IFS= read -r -d '' file; do
    report "flat application file forbidden in guarded area (use <use_case>/ subfolder): ${file#$root/}"
  done < <(find "$area_path" -maxdepth 1 -name '*.dart' -print0 2>/dev/null)

  while IFS= read -r -d '' dir; do
  base="$(basename "$dir")"
  [[ "$base" == "shared" ]] && continue
  count="$(find "$dir" -maxdepth 1 -name '*.dart' | wc -l | tr -d ' ')"
  if [[ "$count" -eq 0 ]]; then
    report "use_case folder must contain at least one .dart file: ${dir#$root/}"
  fi
  done < <(find "$area_path" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
done

if [[ "$failed" -ne 0 ]]; then
  echo "Fix: modules/<module>/application/lib/src/<feature_area>/<use_case>/"
  echo "See modules/partner/application/lib/src/business_partner/register_partner/"
  exit 1
fi

echo "OK: application use_case layout guard passed"
