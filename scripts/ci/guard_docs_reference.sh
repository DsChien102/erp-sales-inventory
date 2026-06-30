#!/usr/bin/env bash
# Fail when key agent docs link to paths that do not exist on disk.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failed=0

docs=(
  "$root/AGENTS.md"
  "$root/docs/architecture/harness-engineering.md"
  "$root/docs/harness/PROGRESS.md"
  "$root/docs/themes/TH-03-partner/README.md"
)

resolve_target() {
  local doc="$1"
  local link="$2"
  local base
  base="$(dirname "$doc")"

  [[ "$link" =~ ^https?:// ]] && return 0
  [[ "$link" =~ ^# ]] && return 0
  [[ "$link" =~ ^mailto: ]] && return 0

  local target="${link%%#*}"
  [[ -z "$target" ]] && return 0

  local resolved
  if [[ "$target" = /* ]]; then
    resolved="$target"
  else
    resolved="$(cd "$base" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")"
  fi

  if [[ -e "$resolved" ]]; then
    return 0
  fi

  echo "ERROR: broken link in $(basename "$doc"): $link (resolved: $resolved)"
  failed=1
}

for doc in "${docs[@]}"; do
  [[ -f "$doc" ]] || continue
  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    resolve_target "$doc" "$link"
  done < <(rg -o '\[[^]]+\]\([^)]+\)' "$doc" 2>/dev/null | sed -E 's/^\[[^]]+\]\(([^)]+)\)$/\1/' || true)
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: agent doc links resolve"
