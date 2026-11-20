#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
python3 "$ROOT/scripts/qa.py"
node --check "$ROOT/src/c45-ds.js"
node --check "$ROOT/src/flutter-font-bridge.js"
node --check "$ROOT/src/preview-material-icons.js"
python3 "$ROOT/scripts/qa_browser.py"
python3 "$ROOT/scripts/qa_fonts.py"
