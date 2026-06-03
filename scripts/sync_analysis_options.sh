#!/usr/bin/env bash
# Ensure every workspace package uses vet45_lints for analysis_options.yaml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FLUTTER_MARKER='/presentation/analysis_options.yaml'
FLUTTER_PACKAGES=(
  apps/erp
  packages/vet45_design_system
)

is_flutter_package() {
  local dir="$1"
  for flutter_pkg in "${FLUTTER_PACKAGES[@]}"; do
    if [[ "$dir" == "$ROOT/$flutter_pkg" ]]; then
      return 0
    fi
  done
  if [[ "$dir" == *"/presentation" ]]; then
    return 0
  fi
  return 1
}

write_analysis_options() {
  local dir="$1"
  local kind="$2"
  cat >"$dir/analysis_options.yaml" <<EOF
include: package:vet45_lints/${kind}.yaml
EOF
}

ensure_pubspec_dep() {
  local pubspec="$1"
  if grep -q 'vet45_lints:' "$pubspec"; then
    return 0
  fi

  if grep -q '^dev_dependencies:' "$pubspec"; then
  python3 - "$pubspec" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = "dev_dependencies:\n"
if needle not in text:
    raise SystemExit(f"missing dev_dependencies in {path}")
text = text.replace(
    needle,
    needle + "  vet45_lints: ^1.0.0\n",
    1,
)
path.write_text(text)
PY
  else
    cat >>"$pubspec" <<'EOF'

dev_dependencies:
  vet45_lints: ^1.0.0
EOF
  fi
}

while IFS= read -r pubspec; do
  dir="$(cd "$(dirname "$pubspec")" && pwd)"
  if is_flutter_package "$dir"; then
    write_analysis_options "$dir" flutter
  else
    write_analysis_options "$dir" dart
  fi
  ensure_pubspec_dep "$pubspec"
done < <(find apps packages modules -name pubspec.yaml -not -path '*/.dart_tool/*' -not -path '*/vet45_lints/*' -not -path '*/vet45_design_system/example/*' | sort)

echo "Synced analysis_options.yaml for all workspace packages."
