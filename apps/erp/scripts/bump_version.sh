#!/usr/bin/env bash
# Bump apps/erp version in pubspec.yaml and optionally commit/push for CI/CD.
#
# Flutter reads version as name+build (e.g. 1.2.1+5):
#   - name  → iOS CFBundleShortVersionString / Android versionName
#   - build → iOS CFBundleVersion / Android versionCode
#
# Usage:
#   ./apps/erp/scripts/bump_version.sh [options]
#
# Options:
#   --build          Bump build number only (default)
#   --patch          Bump patch segment (x.y.z → x.y.(z+1))
#   --minor          Bump minor segment (x.y.z → x.(y+1).0)
#   --major          Bump major segment (x.y.z → (x+1).0.0)
#   --set VERSION    Set explicit version (e.g. 1.3.0+12)
#   --commit         Stage pubspec.yaml and create a git commit
#   --push           Push commit to the current branch (implies --commit)
#   --tag            Create an annotated git tag erp-v<version> (implies --commit)
#   --ci             Non-interactive CI mode (skip dirty-tree check unless --allow-dirty)
#   --allow-dirty    Allow uncommitted changes besides pubspec.yaml
#   --dry-run        Print the new version without writing files
#   --output-file F  Write NEW_VERSION=<version> to file (for CI artifacts)
#
# Examples:
#   ./apps/erp/scripts/bump_version.sh --build --commit
#   ./apps/erp/scripts/bump_version.sh --patch --commit --push --ci
#   ./apps/erp/scripts/bump_version.sh --set 2.0.0+1 --commit --tag
#
# GitLab CI (push back to the same branch):
#   variables:
#     GIT_STRATEGY: clone
#   before_script:
#     - git config user.email "${GIT_USER_EMAIL:-ci@gitlab.com}"
#     - git config user.name "${GIT_USER_NAME:-GitLab CI}"
#     - git remote set-url origin "https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
#   script:
#     - ./apps/erp/scripts/bump_version.sh --build --push --ci --output-file bump_version.env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PUBSPEC="${ROOT}/apps/erp/pubspec.yaml"

BUMP_KIND="build"
EXPLICIT_VERSION=""
DO_COMMIT=false
DO_PUSH=false
DO_TAG=false
CI_MODE=false
ALLOW_DIRTY=false
DRY_RUN=false
OUTPUT_FILE=""

usage() {
  sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) BUMP_KIND="build"; shift ;;
    --patch) BUMP_KIND="patch"; shift ;;
    --minor) BUMP_KIND="minor"; shift ;;
    --major) BUMP_KIND="major"; shift ;;
    --set)
      EXPLICIT_VERSION="$2"
      BUMP_KIND="set"
      shift 2
      ;;
    --commit) DO_COMMIT=true; shift ;;
    --push) DO_PUSH=true; DO_COMMIT=true; shift ;;
    --tag) DO_TAG=true; DO_COMMIT=true; shift ;;
    --ci) CI_MODE=true; shift ;;
    --allow-dirty) ALLOW_DIRTY=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --output-file)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -h|--help) usage 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
  esac
done

if [[ ! -f "$PUBSPEC" ]]; then
  echo "Missing pubspec: ${PUBSPEC}" >&2
  exit 1
fi

read_current_version() {
  local line
  line="$(grep -E '^version:[[:space:]]*[0-9]' "$PUBSPEC" | head -1)"
  if [[ -z "$line" ]]; then
    echo "Could not find version in ${PUBSPEC}" >&2
    exit 1
  fi
  echo "${line#version: }" | tr -d '[:space:]'
}

validate_version_format() {
  local version="$1"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
    echo "Invalid version format '${version}' (expected x.y.z+build)" >&2
    exit 1
  fi
}

bump_version() {
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
  esac

  echo "${major}.${minor}.${patch}+${build}"
}

assert_clean_tree() {
  if [[ "$ALLOW_DIRTY" == true ]]; then
    return
  fi

  if [[ -n "$(git -C "$ROOT" status --porcelain --ignore-submodules)" ]]; then
    echo "Working tree is dirty. Commit or stash changes, or pass --allow-dirty." >&2
    git -C "$ROOT" status --short
    exit 1
  fi
}

write_pubspec_version() {
  local new_version="$1"
  local tmp
  tmp="$(mktemp)"

  awk -v new_version="$new_version" '
    /^version:[[:space:]]*[0-9]/ {
      print "version: " new_version
      next
    }
    { print }
  ' "$PUBSPEC" > "$tmp"

  mv "$tmp" "$PUBSPEC"
}

current_version="$(read_current_version)"
validate_version_format "$current_version"
new_version="$(bump_version "$current_version")"
validate_version_format "$new_version"

echo "Current version: ${current_version}"
echo "New version:     ${new_version}"

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run — no files changed."
  exit 0
fi

if [[ "$current_version" == "$new_version" ]]; then
  echo "Version unchanged." >&2
  exit 1
fi

if [[ "$DO_COMMIT" == true ]] || [[ "$DO_PUSH" == true ]] || [[ "$DO_TAG" == true ]]; then
  if [[ "$ALLOW_DIRTY" != true ]]; then
    assert_clean_tree
  fi
fi

write_pubspec_version "$new_version"
echo "Updated ${PUBSPEC}"

if [[ -n "$OUTPUT_FILE" ]]; then
  printf 'NEW_VERSION=%s\n' "$new_version" > "$OUTPUT_FILE"
  echo "Wrote ${OUTPUT_FILE}"
fi

if [[ "$DO_COMMIT" != true ]]; then
  exit 0
fi

if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository: ${ROOT}" >&2
  exit 1
fi

git -C "$ROOT" add apps/erp/pubspec.yaml

commit_msg="chore(erp): bump version to ${new_version}"
if [[ "$CI_MODE" == true ]]; then
  commit_msg="${commit_msg} [skip ci]"
fi

if git -C "$ROOT" diff --cached --quiet; then
  echo "Nothing to commit." >&2
  exit 1
fi

git -C "$ROOT" commit -m "$commit_msg"
echo "Created commit: ${commit_msg}"

if [[ "$DO_TAG" == true ]]; then
  tag_name="erp-v${new_version}"
  if git -C "$ROOT" rev-parse "$tag_name" >/dev/null 2>&1; then
    echo "Tag already exists: ${tag_name}" >&2
    exit 1
  fi
  git -C "$ROOT" tag -a "$tag_name" -m "ERP release ${new_version}"
  echo "Created tag: ${tag_name}"
fi

if [[ "$DO_PUSH" == true ]]; then
  branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
  if [[ "$branch" == "HEAD" ]]; then
    echo "Detached HEAD — cannot push. Checkout a branch first." >&2
    exit 1
  fi

  git -C "$ROOT" push origin "HEAD:${branch}"

  if [[ "$DO_TAG" == true ]]; then
    git -C "$ROOT" push origin "$tag_name"
  fi

  echo "Pushed to origin/${branch}"
fi
