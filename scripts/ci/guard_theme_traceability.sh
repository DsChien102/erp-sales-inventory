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

is_valid_role() {
  local role="$1"
  [[ "$role" == "CONTRACT" || "$role" == "BE" || "$role" == "FE" || "$role" == "E2E" ]]
}

for theme_dir in "$themes_root"/TH-*/; do
  [[ -d "$theme_dir" ]] || continue

  traceability="$theme_dir/harness/05-traceability.md"
  [[ -f "$traceability" ]] || continue

  if rg -q 'exemplar-complete:\s*deferred' "$traceability" 2>/dev/null; then
    echo "SKIP: traceability exemplar deferred for $(basename "$theme_dir")"
    continue
  fi

  echo "Checking traceability exemplar: $(basename "$theme_dir")"

  while IFS= read -r line; do
    [[ "$line" =~ ^\| ]] || continue
    [[ "$line" =~ Req\ ID ]] && continue
    [[ "$line" =~ ^\|[[:space:]]*-+[[:space:]]*\| ]] && continue
    [[ "$line" =~ _pending_ ]] && continue
    [[ "$line" =~ placeholder ]] && continue

    # Expect: | Req ID | Role | Contract § | ...
    role="$(echo "$line" | awk -F'|' 'NF >= 3 { gsub(/^ +| +$/, "", $3); print $3 }')"
    if [[ -z "$role" ]] || ! is_valid_role "$role"; then
      report "traceability row missing Role (CONTRACT|BE|FE|E2E) in $traceability: $line"
    fi

    if [[ "$line" =~ SCN ]] && [[ ! "$line" =~ scn_[a-z0-9_]+ ]]; then
      report "SCN row missing scn_* test id in $traceability: $line"
    fi
  done < "$traceability"
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: theme traceability guards passed"
