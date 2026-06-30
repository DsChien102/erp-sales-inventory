#!/usr/bin/env bash
# Enforce traceability exemplar when theme marks exemplar-complete.
# Skips while <!-- exemplar-complete: deferred --> is present.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
themes_root="$root/docs/themes"
failed=0

report() {
  echo "ERROR: $1"
  failed=1
}

for theme_dir in "$themes_root"/TH-*/; do
  [[ -d "$theme_dir" ]] || continue

  traceability="$theme_dir/harness/05-traceability.md"
  [[ -f "$traceability" ]] || continue

  if rg -q 'exemplar-complete:\s*deferred' "$traceability" 2>/dev/null; then
    echo "SKIP: traceability exemplar deferred for $(basename "$theme_dir")"
    continue
  fi

  # When exemplar is marked complete, every SCN row needs a test id.
  while IFS= read -r line; do
    [[ "$line" =~ SCN ]] || continue
    if [[ ! "$line" =~ scn_[a-z0-9_]+ ]]; then
      report "SCN row missing test id in $traceability: $line"
    fi
  done < <(rg 'SCN' "$traceability" 2>/dev/null || true)
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: theme traceability guards passed"
