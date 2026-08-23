#!/usr/bin/env bash
# Shared bump orchestration for ship-unit version scripts.
# Language / framework agnostic — no knowledge of pubspec, Cargo, go.mod, etc.
#
# Required before source (set by wrapper):
#   ROOT, UNIT_ID, UNIT_PATH, TAG_PREFIX, TAG_MESSAGE_PREFIX
#
# Required scheme hooks (defined by frameworks/<framework>_<deploy>.sh before sourcing):
#   scheme_default_bump_kind   -> echo build|patch|…
#   scheme_accepts_build       -> return 0 if --build allowed
#   scheme_validate_version VERSION
#   scheme_compute_next_version CURRENT  (uses BUMP_KIND, EXPLICIT_VERSION)
#   scheme_read_version        -> stdout current version from manifest
#   scheme_write_version VERSION
#   scheme_version_files       -> relative paths (to ROOT) to git-add after write
#
# Optional:
#   scheme_reject_build_message  -> stderr text when --build rejected
#
# Entry: bump_run "$@"
set -euo pipefail

if [[ -z "${ROOT:-}" || -z "${UNIT_ID:-}" || -z "${UNIT_PATH:-}" ]]; then
  echo "bump_common: ROOT, UNIT_ID, and UNIT_PATH must be set" >&2
  exit 1
fi

: "${TAG_PREFIX:=${UNIT_ID}}"
: "${TAG_MESSAGE_PREFIX:=${UNIT_ID}}"

CHANGELOG="${ROOT}/${UNIT_PATH}/CHANGELOG.md"
CUT_CHANGELOG="${ROOT}/scripts/release/cut_changelog_unreleased.py"

# Entrypoint path for --help (wrapper $0 when sourced from wrapper).
BUMP_ENTRYPOINT="${BUMP_ENTRYPOINT:-$0}"

BUMP_KIND=""
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

_bump_usage() {
  sed -n '2,45p' "${BUMP_ENTRYPOINT}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

_bump_assert_clean_tree() {
  if [[ "$ALLOW_DIRTY" == true ]]; then
    return
  fi

  if [[ -n "$(git -C "$ROOT" status --porcelain --ignore-submodules)" ]]; then
    echo "Working tree is dirty. Commit or stash changes, or pass --allow-dirty." >&2
    git -C "$ROOT" status --short
    exit 1
  fi
}

_bump_parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build)
        if ! scheme_accepts_build; then
          if declare -F scheme_reject_build_message >/dev/null; then
            scheme_reject_build_message >&2
          else
            echo "${UNIT_ID} does not support --build; use --patch|--minor|--major" >&2
          fi
          exit 1
        fi
        BUMP_KIND="build"
        shift
        ;;
      --patch) BUMP_KIND="patch"; shift ;;
      --minor) BUMP_KIND="minor"; shift ;;
      --major) BUMP_KIND="major"; shift ;;
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
      -h|--help) _bump_usage 0 ;;
      *)
        echo "Unknown option: $1" >&2
        _bump_usage 1
        ;;
    esac
  done

  if [[ -z "$BUMP_KIND" ]]; then
    BUMP_KIND="$(scheme_default_bump_kind)"
  fi
}

bump_run() {
  _bump_parse_args "$@"

  local current_version new_version version_file
  current_version="$(scheme_read_version)"
  scheme_validate_version "$current_version"
  new_version="$(scheme_compute_next_version "$current_version")"
  scheme_validate_version "$new_version"

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
      _bump_assert_clean_tree
    fi
  fi

  scheme_write_version "$new_version"
  while IFS= read -r version_file; do
    [[ -z "$version_file" ]] && continue
    echo "Updated ${ROOT}/${version_file}"
  done < <(scheme_version_files)

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

  while IFS= read -r version_file; do
    [[ -z "$version_file" ]] && continue
    git -C "$ROOT" add "$version_file"
  done < <(scheme_version_files)

  if [[ "$SKIP_CHANGELOG" != true ]]; then
    git -C "$ROOT" add "${UNIT_PATH}/CHANGELOG.md"
  fi

  local commit_msg="chore(${UNIT_ID}): bump version to ${new_version}"
  if [[ "$CI_MODE" == true ]]; then
    commit_msg="${commit_msg} [skip ci]"
  fi

  if git -C "$ROOT" diff --cached --quiet; then
    echo "Nothing to commit." >&2
    exit 1
  fi

  git -C "$ROOT" commit -m "$commit_msg"
  echo "Created commit: ${commit_msg}"

  local tag_name=""
  if [[ "$DO_TAG" == true ]]; then
    tag_name="${TAG_PREFIX}-v${new_version}"
    if git -C "$ROOT" rev-parse "$tag_name" >/dev/null 2>&1; then
      echo "Tag already exists: ${tag_name}" >&2
      exit 1
    fi
    git -C "$ROOT" tag -a "$tag_name" -m "${TAG_MESSAGE_PREFIX} release ${new_version}"
    echo "Created tag: ${tag_name}"
  fi

  if [[ "$DO_PUSH" == true ]]; then
    local branch
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
}
