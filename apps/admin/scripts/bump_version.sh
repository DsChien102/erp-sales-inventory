#!/usr/bin/env bash
# Bump apps/admin version in pubspec.yaml, cut CHANGELOG [Unreleased], and optionally
# commit/push for CI/CD.
#
# Framework: flutter_exec (MAJOR.MINOR.PATCH+BUILD)
# Flutter reads version as name+build (e.g. 1.2.1+5):
#   - name  → iOS CFBundleShortVersionString / Android versionName
#   - build → iOS CFBundleVersion / Android versionCode
#
# Usage:
#   ./apps/admin/scripts/bump_version.sh [options]
#
# Options:
#   --build          Bump build number only (default)
#   --patch          Bump patch segment (x.y.z → x.y.(z+1))
#   --minor          Bump minor segment (x.y.z → x.(y+1).0)
#   --major          Bump major segment (x.y.z → (x+1).0.0)
#   --set VERSION    Set explicit version (e.g. 1.3.0+12)
#   --date YYYY-MM-DD  Changelog release date (default: UTC today)
#   --skip-changelog Do not cut apps/admin/CHANGELOG.md
#   --commit         Stage pubspec.yaml + CHANGELOG and create a git commit
#   --push           Push commit to the current branch (implies --commit)
#   --tag            Create an annotated git tag admin-v<version> (implies --commit)
#   --ci             Non-interactive CI mode (skip dirty-tree check unless --allow-dirty)
#   --allow-dirty    Allow uncommitted changes besides pubspec.yaml / CHANGELOG
#   --dry-run        Print the new version without writing files
#   --output-file F  Write NEW_VERSION=<version> to file (for CI artifacts)
#
# Examples:
#   ./apps/admin/scripts/bump_version.sh --build --commit
#   ./apps/admin/scripts/bump_version.sh --patch --commit --push --ci
#   ./apps/admin/scripts/bump_version.sh --set 2.0.0+1 --commit --tag
#
# GitLab CI (push back to the same branch):
#   variables:
#     GIT_STRATEGY: clone
#   before_script:
#     - git config user.email "${GIT_USER_EMAIL:-ci@gitlab.com}"
#     - git config user.name "${GIT_USER_NAME:-GitLab CI}"
#     - git remote set-url origin "https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
#   script:
#     - ./apps/admin/scripts/bump_version.sh --build --push --ci --output-file bump_version.env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
UNIT_ID="admin"
UNIT_PATH="apps/admin"
TAG_PREFIX="admin"
TAG_MESSAGE_PREFIX="ADMIN"
BUMP_ENTRYPOINT="$0"

# shellcheck source=../../../scripts/release/frameworks/flutter_exec.sh
source "${ROOT}/scripts/release/frameworks/flutter_exec.sh"
bump_main "$@"
