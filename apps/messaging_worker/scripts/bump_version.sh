#!/usr/bin/env bash
# Bump apps/messaging_worker version in pubspec.yaml, cut CHANGELOG [Unreleased],
# and optionally commit/push for CI/CD.
#
# Worker uses SemVer without a Flutter build number (e.g. 0.2.0).
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
PUBSPEC="${ROOT}/apps/messaging_worker/pubspec.yaml"
CHANGELOG="${ROOT}/apps/messaging_worker/CHANGELOG.md"
CUT_CHANGELOG="${ROOT}/scripts/release/cut_changelog_unreleased.py"

BUMP_KIND="patch"
EXPLICIT_VERSION=""
RELEASE_DATE=""
SKIP_CHANGELOG=false
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
    --patch) BUMP_KIND="patch"; shift ;;
    --minor) BUMP_KIND="minor"; shift ;;
    --major) BUMP_KIND="major"; shift ;;
    --build)
      echo "messaging_worker has no Flutter build number; use --patch|--minor|--major" >&2
      exit 1
      ;;
    --set)
      EXPLICIT_VERSION="$2"
      BUMP_KIND="set"
      shift 2
      ;;
    --date)
      RELEASE_DATE="$2"
      shift 2
      ;;
    --skip-changelog) SKIP_CHANGELOG=true; shift ;;
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
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format '${version}' (expected x.y.z)" >&2
    exit 1
  fi
}

bump_version() {
  local current="$1"
  local major minor patch

  IFS='.' read -r major minor patch <<< "$current"

  case "$BUMP_KIND" in
    patch)
      patch=$((patch + 1))
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    set)
      echo "$EXPLICIT_VERSION"
      return
      ;;
  esac

  echo "${major}.${minor}.${patch}"
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

if [[ "$SKIP_CHANGELOG" != true ]]; then
  if [[ ! -f "$CHANGELOG" ]]; then
    echo "Missing changelog: ${CHANGELOG}" >&2
    exit 1
  fi
  if [[ ! -f "$CUT_CHANGELOG" ]]; then
    echo "Missing changelog helper: ${CUT_CHANGELOG}" >&2
    exit 1
  fi
  if [[ -n "$RELEASE_DATE" ]]; then
    python3 "$CUT_CHANGELOG" "$CHANGELOG" "$new_version" "$RELEASE_DATE"
  else
    python3 "$CUT_CHANGELOG" "$CHANGELOG" "$new_version"
  fi
  echo "Updated ${CHANGELOG}"
fi

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

git -C "$ROOT" add apps/messaging_worker/pubspec.yaml
if [[ "$SKIP_CHANGELOG" != true ]]; then
  git -C "$ROOT" add apps/messaging_worker/CHANGELOG.md
fi

commit_msg="chore(messaging_worker): bump version to ${new_version}"
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
  tag_name="messaging_worker-v${new_version}"
  if git -C "$ROOT" rev-parse "$tag_name" >/dev/null 2>&1; then
    echo "Tag already exists: ${tag_name}" >&2
    exit 1
  fi
  git -C "$ROOT" tag -a "$tag_name" -m "messaging_worker release ${new_version}"
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
