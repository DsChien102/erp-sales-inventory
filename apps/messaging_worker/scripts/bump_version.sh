#!/usr/bin/env bash
# Bump apps/messaging_worker version in pubspec.yaml, cut CHANGELOG [Unreleased],
# and optionally commit/push for CI/CD.
#
# Framework: dart_exec (MAJOR.MINOR.PATCH, no Flutter build number)
#
# Usage:
#   ./apps/messaging_worker/scripts/bump_version.sh [options]
#
# Options:
#   --patch          Bump patch segment (default) (x.y.z → x.y.(z+1))
#   --minor          Bump minor segment (x.y.z → x.(y+1).0)
#   --major          Bump major segment (x.y.z → (x+1).0.0)
#   --set VERSION    Set explicit version (e.g. 0.3.0)
#   --date YYYY-MM-DD  Changelog release date (default: UTC today)
#   --skip-changelog Do not cut apps/messaging_worker/CHANGELOG.md
#   --commit         Stage pubspec.yaml + CHANGELOG and create a git commit
#   --push           Push commit to the current branch (implies --commit)
#   --tag            Create annotated tag messaging_worker-v<version> (implies --commit)
#   --ci             Non-interactive CI mode
#   --allow-dirty    Allow uncommitted changes besides pubspec.yaml / CHANGELOG
#   --dry-run        Print the new version without writing files
#   --output-file F  Write NEW_VERSION=<version> to file (for CI artifacts)
#
# Examples:
#   ./apps/messaging_worker/scripts/bump_version.sh --patch --commit --tag
#   ./apps/messaging_worker/scripts/bump_version.sh --minor --dry-run
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
UNIT_ID="messaging_worker"
UNIT_PATH="apps/messaging_worker"
TAG_PREFIX="messaging_worker"
TAG_MESSAGE_PREFIX="messaging_worker"
BUMP_ENTRYPOINT="$0"

# shellcheck source=../../../scripts/release/frameworks/dart_exec.sh
source "${ROOT}/scripts/release/frameworks/dart_exec.sh"
bump_main "$@"
