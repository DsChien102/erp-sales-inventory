#!/usr/bin/env bash
# Forward to vet45 switch (AOT or dart run via vet45.sh).
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/vet45.sh" switch "$@"
