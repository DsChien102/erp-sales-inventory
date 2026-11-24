#!/usr/bin/env bash
# Framework: Flutter executable (apps) — MAJOR.MINOR.PATCH+BUILD via pubspec.yaml
#
# Wrapper must set ROOT, UNIT_ID, UNIT_PATH, TAG_PREFIX, TAG_MESSAGE_PREFIX
# then: source this file; bump_main "$@"
set -euo pipefail

_FW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/manifests/pubspec.sh
source "${_FW_DIR}/../lib/manifests/pubspec.sh"

VERSION_FILE="${ROOT}/${UNIT_PATH}/pubspec.yaml"

scheme_default_bump_kind() {
  echo "build"
}

scheme_accepts_build() {
  return 0
}

scheme_read_version() {
  pubspec_read_version "$VERSION_FILE"
}

scheme_write_version() {
  pubspec_write_version "$VERSION_FILE" "$1"
}

scheme_version_files() {
  echo "${UNIT_PATH}/pubspec.yaml"
}

scheme_validate_version() {
  local version="$1"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
    echo "Invalid version format '${version}' (expected x.y.z+build)" >&2
    exit 1
  fi
}

scheme_compute_next_version() {
  local current="$1"
  local name="${current%%+*}"
  local build="${current##*+}"
  local major minor patch

  IFS='.' read -r major minor patch <<< "$name"

  case "$BUMP_KIND" in
    build)
      build=$((build + 1))
      ;;
    patch)
      patch=$((patch + 1))
      build=$((build + 1))
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      build=$((build + 1))
      ;;
    major)
      major=$((major + 1))
      minor=0
      patch=0
      build=$((build + 1))
      ;;
    set)
      echo "$EXPLICIT_VERSION"
      return
      ;;
    *)
      echo "Unknown bump kind: ${BUMP_KIND}" >&2
      exit 1
      ;;
  esac

  echo "${major}.${minor}.${patch}+${build}"
}

# shellcheck source=../lib/bump_common.sh
source "${_FW_DIR}/../lib/bump_common.sh"

bump_main() {
  bump_run "$@"
}
