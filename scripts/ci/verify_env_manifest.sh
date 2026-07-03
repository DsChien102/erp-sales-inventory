#!/usr/bin/env bash
# Validate Vet45 environment manifest and vet45_env package tests.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

manifest="$root/config/environments.json"
if [[ ! -f "$manifest" ]]; then
  echo "FAIL: missing $manifest"
  exit 1
fi

for example in development local staging production; do
  if [[ ! -f "$root/config/secrets/${example}.env.example" ]]; then
    echo "FAIL: missing config/secrets/${example}.env.example"
    exit 1
  fi
done

if [[ ! -x "$root/scripts/env/vet45_env.sh" ]]; then
  echo "FAIL: scripts/env/vet45_env.sh not executable"
  exit 1
fi

echo "==> vet45_env dart test"
(cd "$root/tools/vet45_env" && dart test)

echo "==> vet45_env list"
dart run "$root/tools/vet45_env/bin/vet45_env.dart" list >/dev/null

echo "OK: environment manifest verified"
