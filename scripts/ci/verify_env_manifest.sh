#!/usr/bin/env bash
# Validate Vet45 environment manager templates and package tests.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

templates="$root/tools/vet45_env/templates/config"
manifest="$templates/environments.json"
if [[ ! -f "$manifest" ]]; then
  echo "FAIL: missing $manifest"
  exit 1
fi

if [[ ! -f "$templates/profiles.json" ]]; then
  echo "FAIL: missing $templates/profiles.json"
  exit 1
fi

for example in development local staging production deploy auth; do
  if [[ ! -f "$templates/secrets/${example}.env.example" ]]; then
    echo "FAIL: missing $templates/secrets/${example}.env.example"
    exit 1
  fi
done

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
"$root/.vet45/bin/vet45" --help | grep -q tui
"$root/scripts/env/vet45.sh" list >/dev/null
test -x "$root/scripts/env/switch.sh"

echo "==> vet45 init (temp smoke)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tools/vet45_env"
cp -R "$root/tools/vet45_env/bin" "$tmp/tools/vet45_env/"
cp -R "$root/tools/vet45_env/lib" "$tmp/tools/vet45_env/"
cp -R "$root/tools/vet45_env/templates" "$tmp/tools/vet45_env/"
cp "$root/tools/vet45_env/pubspec.yaml" "$tmp/tools/vet45_env/pubspec.yaml"
sed -i '' '/resolution: workspace/d' "$tmp/tools/vet45_env/pubspec.yaml" 2>/dev/null || \
  sed -i '/resolution: workspace/d' "$tmp/tools/vet45_env/pubspec.yaml"
printf 'name: vet45\npublish_to: none\nenvironment:\n  sdk: ">=3.11.1 <4.0.0"\n' > "$tmp/pubspec.yaml"
(cd "$tmp/tools/vet45_env" && dart pub get >/dev/null)
(cd "$tmp" && dart run tools/vet45_env/bin/vet45_env.dart init >/dev/null)
test -f "$tmp/config/environments.json"

echo "OK: environment manager verified"
