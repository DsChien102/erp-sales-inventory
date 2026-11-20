#!/usr/bin/env bash
# Pubspec.yaml version read/write (Dart/Flutter Pub ecosystem).
#
# Usage (source from a framework scheme):
#   pubspec_read_version <path>
#   pubspec_write_version <path> <version>
set -euo pipefail

pubspec_read_version() {
  local path="$1"
  local line
  if [[ ! -f "$path" ]]; then
    echo "Missing pubspec: ${path}" >&2
    exit 1
  fi
  line="$(grep -E '^version:[[:space:]]*[0-9]' "$path" | head -1)"
  if [[ -z "$line" ]]; then
    echo "Could not find version in ${path}" >&2
    exit 1
  fi
  echo "${line#version: }" | tr -d '[:space:]'
}

pubspec_write_version() {
  local path="$1"
  local new_version="$2"
  local tmp
  if [[ ! -f "$path" ]]; then
    echo "Missing pubspec: ${path}" >&2
    exit 1
  fi
  tmp="$(mktemp)"
  awk -v new_version="$new_version" '
    /^version:[[:space:]]*[0-9]/ {
      print "version: " new_version
      next
    }
    { print }
  ' "$path" > "$tmp"
  mv "$tmp" "$path"
}
