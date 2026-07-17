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

for target in \
  apps/erp/vet45.target.json \
  apps/admin/vet45.target.json \
  apps/messaging_worker/vet45.target.json \
  config/deploy/vet45.target.json
do
  if [[ ! -f "$root/$target" ]]; then
    echo "FAIL: missing $root/$target"
    exit 1
  fi
done

if [[ -d "$root/tools/vet45_env/templates" ]]; then
  echo "FAIL: obsolete templates dir $root/tools/vet45_env/templates (removed — use config/<profile>/*.env.example)"
  exit 1
fi

if [[ -d "$root/config/secrets" ]]; then
  echo "FAIL: obsolete config/secrets/ — use config/<profileId>/ (e.g. config/default/)"
  exit 1
fi

for example in development local staging production auth; do
  if [[ ! -f "$root/config/default/${example}.env.example" ]]; then
    echo "FAIL: missing $root/config/default/${example}.env.example"
    exit 1
  fi
done

if [[ ! -f "$root/config/deploy/deploy.env.example" ]]; then
  echo "FAIL: missing $root/config/deploy/deploy.env.example"
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

echo "==> vet45 init (temp smoke — copy examples to env)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tools/vet45_env" "$tmp/apps/erp" "$tmp/apps/admin" "$tmp/apps/messaging_worker" "$tmp/config/deploy" "$tmp/config/default"
cp -R "$root/tools/vet45_env/bin" "$tmp/tools/vet45_env/"
cp -R "$root/tools/vet45_env/lib" "$tmp/tools/vet45_env/"
cp "$root/tools/vet45_env/pubspec.yaml" "$tmp/tools/vet45_env/pubspec.yaml"
cp "$root/vet45.workspace.json" "$tmp/vet45.workspace.json"
cp "$root/apps/erp/vet45.target.json" "$tmp/apps/erp/"
cp "$root/apps/admin/vet45.target.json" "$tmp/apps/admin/"
cp "$root/apps/messaging_worker/vet45.target.json" "$tmp/apps/messaging_worker/"
cp "$root/config/deploy/vet45.target.json" "$tmp/config/deploy/"
cp "$root/config/default/"*.env.example "$tmp/config/default/"
cp "$root/config/deploy/deploy.env.example" "$tmp/config/deploy/"
sed -i '' '/resolution: workspace/d' "$tmp/tools/vet45_env/pubspec.yaml" 2>/dev/null || \
  sed -i '/resolution: workspace/d' "$tmp/tools/vet45_env/pubspec.yaml"
printf 'name: vet45\npublish_to: none\nenvironment:\n  sdk: ">=3.11.1 <4.0.0"\n' > "$tmp/pubspec.yaml"
(cd "$tmp/tools/vet45_env" && dart pub get >/dev/null)
(cd "$tmp" && dart run tools/vet45_env/bin/vet45_env.dart init >/dev/null)
test -f "$tmp/config/default/development.env"
test ! -d "$tmp/tools/vet45_env/templates"
test ! -f "$tmp/config/environments.json"

echo "OK: environment manager verified"
