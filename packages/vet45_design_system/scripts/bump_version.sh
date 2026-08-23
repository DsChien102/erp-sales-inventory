#!/usr/bin/env bash
# Bump packages/vet45_design_system version in pubspec.yaml, cut CHANGELOG
# [Unreleased], and optionally commit/push for CI/CD.
#
# Framework: flutter_lib (MAJOR.MINOR.PATCH, no Flutter build number)
#
# Usage:
#   ./packages/vet45_design_system/scripts/bump_version.sh [options]
#
# Options:
#   --patch          Bump patch segment (default) (x.y.z → x.y.(z+1))
#   --minor          Bump minor segment (x.y.z → x.(y+1).0)
#   --major          Bump major segment (x.y.z → (x+1).0.0)
#   --set VERSION    Set explicit version (e.g. 1.1.0)
#   --date YYYY-MM-DD  Changelog release date (default: UTC today)
#   --skip-changelog Do not cut packages/vet45_design_system/CHANGELOG.md
#   --commit         Stage pubspec.yaml + CHANGELOG and create a git commit
#   --push           Push commit to the current branch (implies --commit)
#   --tag            Create annotated tag vet45_design_system-v<version> (implies --commit)
#   --ci             Non-interactive CI mode
#   --allow-dirty    Allow uncommitted changes besides pubspec.yaml / CHANGELOG
#   --dry-run        Print the new version without writing files
#   --output-file F  Write NEW_VERSION=<version> to file (for CI artifacts)
#
# Examples:
#   ./packages/vet45_design_system/scripts/bump_version.sh --patch --dry-run
#   ./packages/vet45_design_system/scripts/bump_version.sh --minor --commit --tag
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
UNIT_ID="vet45_design_system"
UNIT_PATH="packages/vet45_design_system"
TAG_PREFIX="vet45_design_system"
TAG_MESSAGE_PREFIX="vet45_design_system"
BUMP_ENTRYPOINT="$0"

# shellcheck source=../../../scripts/release/frameworks/flutter_lib.sh
source "${ROOT}/scripts/release/frameworks/flutter_lib.sh"
bump_main "$@"
