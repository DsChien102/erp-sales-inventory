#!/usr/bin/env bash
# Validate Mosaic Retail environment manager workspace/target manifests and package tests.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

workspace="$root/c45.workspace.json"
if [[ ! -f "$workspace" ]]; then
  echo "FAIL: missing $workspace"
  exit 1
fi

if grep -q '"profiles"' "$workspace"; then
  echo "FAIL: $workspace must not declare profiles (auto-detect from .c45/profiles/)"
  exit 1
fi

for target in \
  apps/erp/c45.target.json \
  packages/c45_design_system/example/c45.target.json \
  deploy/c45.target.json
do
  if [[ ! -f "$root/$target" ]]; then
    echo "FAIL: missing $root/$target"
    exit 1
  fi
done

if [[ -d "$root/tools/c45_env/templates" ]]; then
  echo "FAIL: obsolete templates dir $root/tools/c45_env/templates"
  exit 1
fi

if [[ -d "$root/.c45/templates" ]]; then
  echo "FAIL: obsolete .c45/templates/ — examples are generated from c45.target.json"
  exit 1
fi

if [[ -d "$root/config" ]]; then
  echo "FAIL: obsolete config/ — use deploy/, .c45/profiles"
  exit 1
fi

if [[ ! -f "$root/deploy/deploy.env.example" ]]; then
  echo "FAIL: missing $root/deploy/deploy.env.example"
  exit 1
fi

if [[ ! -x "$root/scripts/env/c45.sh" ]]; then
  echo "FAIL: scripts/env/c45.sh not executable"
  exit 1
fi

if [[ ! -f "$root/scripts/env/c45.bat" ]]; then
  echo "FAIL: missing scripts/env/c45.bat"
  exit 1
fi

if [[ ! -f "$root/scripts/env/c45.ps1" ]]; then
  echo "FAIL: missing scripts/env/c45.ps1"
  exit 1
fi

if [[ ! -x "$root/scripts/env/c45_env.sh" ]]; then
  echo "FAIL: scripts/env/c45_env.sh not executable (compat shim)"
  exit 1
fi

if [[ ! -f "$root/scripts/env/c45_env.bat" ]]; then
  echo "FAIL: missing scripts/env/c45_env.bat (compat shim)"
  exit 1
fi

if [[ ! -f "$root/scripts/env/c45_env.ps1" ]]; then
  echo "FAIL: missing scripts/env/c45_env.ps1 (compat shim)"
  exit 1
fi

for activate in activate.sh activate.ps1 activate.bat deactivate.bat; do
  if [[ ! -f "$root/scripts/env/$activate" ]]; then
    echo "FAIL: missing scripts/env/$activate"
    exit 1
  fi
done

echo "==> activate.sh smoke (sourced)"
# shellcheck disable=SC1091
(
  cd "$root"
  # shellcheck source=/dev/null
  source "$root/scripts/env/activate.sh" >/dev/null
  test -n "${C45_PROFILE:-}"
  test -n "${C45_ENV_ID:-}"
  test -n "${C45_ACTIVE_LABEL:-}"
  deactivate >/dev/null
)

echo "==> c45 dart test"
(cd "$root/tools/c45_env" && dart test)

echo "==> c45 AOT build + smoke"
dart run "$root/tools/c45_env/bin/build_aot.dart"
test -x "$root/.c45/bin/c45"
"$root/.c45/bin/c45" status >/dev/null
"$root/.c45/bin/c45" switch >/dev/null
"$root/.c45/bin/c45" completion bash >/dev/null
help_out="$("$root/.c45/bin/c45" --help)"
echo "$help_out" | grep -q tui
list_out="$("$root/.c45/bin/c45" list)"
echo "$list_out" | grep -q 'manifest:'
"$root/scripts/env/c45.sh" list >/dev/null
test -x "$root/scripts/env/switch.sh"

echo "==> c45 example --check"
"$root/.c45/bin/c45" example --check

echo "==> c45 init (temp smoke, no templates/)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tools/c45_env" "$tmp/apps/erp" \
  "$tmp/packages/c45_design_system/example" "$tmp/deploy"
cp -R "$root/tools/c45_env/bin" "$tmp/tools/c45_env/"
cp -R "$root/tools/c45_env/lib" "$tmp/tools/c45_env/"
cp "$root/tools/c45_env/pubspec.yaml" "$tmp/tools/c45_env/pubspec.yaml"
cp "$root/c45.workspace.json" "$tmp/c45.workspace.json"
cp "$root/apps/erp/c45.target.json" "$tmp/apps/erp/"
cp "$root/packages/c45_design_system/example/c45.target.json" \
  "$tmp/packages/c45_design_system/example/"
cp "$root/deploy/c45.target.json" "$tmp/deploy/"
sed -i '' '/resolution: workspace/d' "$tmp/tools/c45_env/pubspec.yaml" 2>/dev/null || \
  sed -i '/resolution: workspace/d' "$tmp/tools/c45_env/pubspec.yaml"
printf 'name: c45\npublish_to: none\nenvironment:\n  sdk: ">=3.11.1 <4.0.0"\n' > "$tmp/pubspec.yaml"
(cd "$tmp/tools/c45_env" && dart pub get >/dev/null)
(cd "$tmp" && dart run tools/c45_env/bin/c45_env.dart init smokeprofile >/dev/null)
test -f "$tmp/.c45/profiles/smokeprofile/development.env"
test -f "$tmp/.c45/profiles/smokeprofile/development.env.example"
test -f "$tmp/.c45/profiles/smokeprofile/auth.env.example"
test ! -f "$tmp/.c45/profiles/smokeprofile/auth.env"
test -f "$tmp/deploy/deploy.env"
test -f "$tmp/deploy/deploy.env.example"
grep -q '# erp:' "$tmp/.c45/profiles/smokeprofile/development.env.example"
test ! -d "$tmp/.c45/templates"
test ! -d "$tmp/tools/c45_env/templates"
test ! -d "$tmp/config"

echo "OK: environment manager verified"
