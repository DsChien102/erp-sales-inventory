#!/usr/bin/env bash
# Backward-compatible alias → scripts/env/c45.sh
exec "$(cd "$(dirname "$0")" && pwd)/c45.sh" "$@"
