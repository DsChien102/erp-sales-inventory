#!/usr/bin/env bash
# Forward to c45 switch (AOT or dart run via c45.sh).
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/c45.sh" switch "$@"
