#!/usr/bin/env bash
# Backward-compatible alias → scripts/env/vet45.sh
exec "$(cd "$(dirname "$0")" && pwd)/vet45.sh" "$@"
