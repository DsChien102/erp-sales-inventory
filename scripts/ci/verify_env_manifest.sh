#!/usr/bin/env bash
# Validate Vet45 environment manager workspace/target manifests and package tests.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

workspace="$root/vet45.workspace.json"
if [[ ! -f "$workspace" ]]; then
  echo "FAIL: missing $workspace"
  exit 1
fi

if grep -q '"profiles"' "$workspace"; then
  echo "FAIL: $workspace must not declare profiles (auto-detect from .vet45/profiles/)"
  exit 1
fi

for target in \
  apps/erp/vet45.target.json \
  apps/admin/vet45.target.json \
  apps/messaging_worker/vet45.target.json \
  packages/vet45_design_system/example/vet45.target.json \
  deploy/vet45.target.json
do
  if [[ ! -f "$root/$target" ]]; then
    echo "FAIL: missing $root/$target"
    exit 1
  fi
done

if [[ -d "$root/tools/vet45_env/templates" ]]; then
  echo "FAIL: obsolete templates dir $root/tools/vet45_env/templates"
  exit 1
fi

if [[ -d "$root/.vet45/templates" ]]; then
  echo "FAIL: obsolete .vet45/templates/ — examples are generated from vet45.target.json"
  exit 1
fi

if [[ -d "$root/config" ]]; then
  echo "FAIL: obsolete config/ — use deploy/, .vet45/profiles"
  exit 1
fi

if [[ ! -f "$root/deploy/deploy.env.example" ]]; then
  echo "FAIL: missing $root/deploy/deploy.env.example"
  exit 1
fi

if [[ ! -x "$root/scripts/env/vet45.sh" ]]; then
  echo "FAIL: scripts/env/vet45.sh not executable"
  exit 1
fi

if [[ ! -f "$root/scripts/env/vet45.bat" ]]; then
  echo "FAIL: missing scripts/env/vet45.bat"
  exit 1
fi

if [[ ! -f "$root/scripts/env/vet45.ps1" ]]; then
  echo "FAIL: missing scripts/env/vet45.ps1"
  exit 1
fi

if [[ ! -x "$root/scripts/env/vet45_env.sh" ]]; then
  echo "FAIL: scripts/env/vet45_env.sh not executable (compat shim)"
  exit 1
fi

if [[ ! -f "$root/scripts/env/vet45_env.bat" ]]; then
  echo "FAIL: missing scripts/env/vet45_env.bat (compat shim)"
  exit 1
fi

if [[ ! -f "$root/scripts/env/vet45_env.ps1" ]]; then
  echo "FAIL: missing scripts/env/vet45_env.ps1 (compat shim)"
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
  test -n "${VET45_PROFILE:-}"
  test -n "${VET45_ENV_ID:-}"
  test -n "${VET45_ACTIVE_LABEL:-}"
  deactivate >/dev/null
)

echo "==> vet45 dart test"
(cd "$root/tools/vet45_env" && dart test)

echo "==> vet45 AOT build + smoke"
dart run "$root/tools/vet45_env/bin/build_aot.dart"
test -x "$root/.vet45/bin/vet45"
"$root/.vet45/bin/vet45" status >/dev/null
"$root/.vet45/bin/vet45" switch >/dev/null
"$root/.vet45/bin/vet45" completion bash >/dev/null
help_out="$("$root/.vet45/bin/vet45" --help)"
echo "$help_out" | grep -q tui
list_out="$("$root/.vet45/bin/vet45" list)"
echo "$list_out" | grep -q 'manifest:'
"$root/scripts/env/vet45.sh" list >/dev/null
test -x "$root/scripts/env/switch.sh"

echo "==> vet45 example --check"
"$root/.vet45/bin/vet45" example --check

echo "==> vet45 init (temp smoke, no templates/)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tools/vet45_env" "$tmp/apps/erp" "$tmp/apps/admin" "$tmp/apps/messaging_worker" \
  "$tmp/packages/vet45_design_system/example" "$tmp/deploy"
cp -R "$root/tools/vet45_env/bin" "$tmp/tools/vet45_env/"
cp -R "$root/tools/vet45_env/lib" "$tmp/tools/vet45_env/"
cp "$root/tools/vet45_env/pubspec.yaml" "$tmp/tools/vet45_env/pubspec.yaml"
cp "$root/vet45.workspace.json" "$tmp/vet45.workspace.json"
cp "$root/apps/erp/vet45.target.json" "$tmp/apps/erp/"
cp "$root/apps/admin/vet45.target.json" "$tmp/apps/admin/"
cp "$root/apps/messaging_worker/vet45.target.json" "$tmp/apps/messaging_worker/"
cp "$root/packages/vet45_design_system/example/vet45.target.json" \
  "$tmp/packages/vet45_design_system/example/"
cp "$root/deploy/vet45.target.json" "$tmp/deploy/"
sed -i '' '/resolution: workspace/d' "$tmp/tools/vet45_env/pubspec.yaml" 2>/dev/null || \
  sed -i '/resolution: workspace/d' "$tmp/tools/vet45_env/pubspec.yaml"
printf 'name: vet45\npublish_to: none\nenvironment:\n  sdk: ">=3.11.1 <4.0.0"\n' > "$tmp/pubspec.yaml"
(cd "$tmp/tools/vet45_env" && dart pub get >/dev/null)
(cd "$tmp" && dart run tools/vet45_env/bin/vet45_env.dart init smokeprofile >/dev/null)
test -f "$tmp/.vet45/profiles/smokeprofile/development.env"
test -f "$tmp/.vet45/profiles/smokeprofile/development.env.example"
test -f "$tmp/.vet45/profiles/smokeprofile/auth.env.example"
test ! -f "$tmp/.vet45/profiles/smokeprofile/auth.env"
test -f "$tmp/deploy/deploy.env"
test -f "$tmp/deploy/deploy.env.example"
grep -q '# erp:' "$tmp/.vet45/profiles/smokeprofile/development.env.example"
grep -q '# worker:' "$tmp/.vet45/profiles/smokeprofile/development.env.example"
test ! -d "$tmp/.vet45/templates"
test ! -d "$tmp/tools/vet45_env/templates"
test ! -d "$tmp/config"

echo "OK: environment manager verified"
