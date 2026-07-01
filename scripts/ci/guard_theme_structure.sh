#!/usr/bin/env bash
# Enforce folder structure for in_progress theme packages under docs/themes/.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
themes_root="$root/docs/themes"
failed=0

report() {
  echo "ERROR: $1"
  failed=1
}

require_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    report "missing $label: $path"
  fi
}

harness_files=(
  "00-agent-ritual.md"
  "01-domain-model.md"
  "02-module-map.md"
  "03-architecture-and-flows.md"
  "04-slice-roadmap.md"
  "05-traceability.md"
  "06-harness-notes.md"
  "07-api-contracts.md"
)

is_in_progress_theme() {
  local readme="$1"
  rg -q 'in_progress' "$readme" 2>/dev/null
}

for theme_dir in "$themes_root"/TH-*/; do
  [[ -d "$theme_dir" ]] || continue

  readme="$theme_dir/README.md"
  require_file "$readme" "theme README"

  if [[ ! -f "$readme" ]]; then
    continue
  fi

  if ! is_in_progress_theme "$readme"; then
    continue
  fi

  theme_name="$(basename "$theme_dir")"
  echo "Checking in_progress theme: $theme_name"

  require_file "$theme_dir/01-business-scope.md" "01-business-scope.md in $theme_name"

  for harness_file in "${harness_files[@]}"; do
    require_file "$theme_dir/harness/$harness_file" "harness/$harness_file in $theme_name"
  done

  while IFS= read -r -d '' epic_dir; do
    epic_name="$(basename "$epic_dir")"
    require_file "$epic_dir/01-overview.md" "Epic overview in $theme_name/$epic_name"

    while IFS= read -r -d '' us_dir; do
      us_name="$(basename "$us_dir")"
      require_file "$us_dir/01-overview.md" "US overview in $theme_name/$epic_name/$us_name"

      if [[ -f "$us_dir/overview.md" ]]; then
        report "legacy overview.md found (rename to 01-overview.md): $us_dir/overview.md"
      fi
    done < <(find "$epic_dir" -mindepth 1 -maxdepth 1 -type d -name 'US-*' -print0 2>/dev/null)
  done < <(find "$theme_dir" -mindepth 1 -maxdepth 1 -type d -name 'Epic-*' -print0 2>/dev/null)

  catalog_readme="$themes_root/README.md"
  if ! rg -q "\]\(${theme_name}/\)" "$catalog_readme" 2>/dev/null; then
    report "docs/themes/README.md must link to $theme_name/"
  fi
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: theme structure guards passed"
