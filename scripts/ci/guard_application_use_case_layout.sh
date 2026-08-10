#!/usr/bin/env bash
# Enforce application layer use_case subfolder layout for guarded aggregates.
# Golden reference: modules/partner/application/lib/src/partner/commands/create_partner/
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0

report() {
  echo "ERROR: $1"
  failed=1
}

uses_cqrs_split() {
  local area_path="$1"
  [[ -d "$area_path/commands" || -d "$area_path/queries" ]]
}

check_use_case_dirs() {
  local parent="$1"
  local label="$2"

  while IFS= read -r -d '' file; do
    report "flat application file forbidden in $label (use <use_case>/ subfolder): ${file#$root/}"
  done < <(find "$parent" -maxdepth 1 -name '*.dart' -print0 2>/dev/null)

  while IFS= read -r -d '' dir; do
    count="$(find "$dir" -maxdepth 1 -name '*.dart' | wc -l | tr -d ' ')"
    if [[ "$count" -eq 0 ]]; then
      report "use_case folder must contain at least one .dart file: ${dir#$root/}"
    fi
  done < <(find "$parent" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
}

# Aggregates that MUST use subfolder layout (no flat *.dart at aggregate root).
guarded_areas=(
  "modules/catalog/application/lib/src/product"
  "modules/catalog/application/lib/src/product_unit"
  "modules/catalog/application/lib/src/product_stock_profile"
  "modules/catalog/application/lib/src/product_base_price_profile"
  "modules/catalog/application/lib/src/product_unit_price_band"
  "modules/catalog/application/lib/src/store_price_rule"
  "modules/catalog/application/lib/src/product_readiness"
  "modules/catalog/application/lib/src/product_change_history"
  "modules/catalog/application/lib/src/custom_field"
  "modules/catalog/application/lib/src/product_custom_field_value"
  "modules/partner/application/lib/src/partner"
  "modules/partner/application/lib/src/partner_history"
  "modules/iam/application/lib/src/authentication"
  "modules/iam/application/lib/src/invitation"
  "modules/iam/application/lib/src/tenant"
  "modules/iam/application/lib/src/identity"
  "modules/iam/application/lib/src/platform"
  "modules/iam/application/lib/src/notification"
)

# Non-use-case dirs allowed beside commands/queries/shared (skill layout).
allowed_aggregate_dirs=(
  shared
  commands
  queries
  ports
  integration_events
  testing
  event_handlers
  services
  internal_commands
  notifications
)

is_allowed_aggregate_dir() {
  local name="$1"
  local allowed
  for allowed in "${allowed_aggregate_dirs[@]}"; do
    [[ "$name" == "$allowed" ]] && return 0
  done
  return 1
}

for area in "${guarded_areas[@]}"; do
  area_path="$root/$area"
  [[ -d "$area_path" ]] || continue

  while IFS= read -r -d '' file; do
    report "flat application file forbidden in guarded aggregate (use commands/ or queries/ subfolder): ${file#$root/}"
  done < <(find "$area_path" -maxdepth 1 -name '*.dart' -print0 2>/dev/null)

  if uses_cqrs_split "$area_path"; then
    for kind in commands queries; do
      kind_path="$area_path/$kind"
      [[ -d "$kind_path" ]] || continue
      check_use_case_dirs "$kind_path" "$kind/"
    done

    while IFS= read -r -d '' dir; do
      base="$(basename "$dir")"
      if is_allowed_aggregate_dir "$base"; then
        continue
      fi
      report "use_case folder must live under commands/ or queries/, not directly under aggregate: ${dir#$root/}"
    done < <(find "$area_path" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  else
    while IFS= read -r -d '' dir; do
      base="$(basename "$dir")"
      [[ "$base" == "shared" ]] && continue
      count="$(find "$dir" -maxdepth 1 -name '*.dart' | wc -l | tr -d ' ')"
      if [[ "$count" -eq 0 ]]; then
        report "use_case folder must contain at least one .dart file: ${dir#$root/}"
      fi
    done < <(find "$area_path" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "Fix: modules/<module>/application/lib/src/<aggregate>/commands/<use_case>/ or queries/<use_case>/"
  echo "See modules/partner/application/lib/src/partner/commands/create_partner/"
  exit 1
fi

echo "OK: application use_case layout guard passed"
