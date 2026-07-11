# shellcheck shell=bash
# Activate Vet45 env/profile for the current shell (like Python venv).
#
# Usage (bash / zsh):
#   source scripts/env/activate.sh
#   . scripts/env/activate.sh
#
# Deactivate:
#   deactivate

# Refuse being executed as a standalone process (cannot mutate parent PS1).
_vet45_is_sourced() {
  if [ -n "${BASH_VERSION:-}" ]; then
    [ "${BASH_SOURCE[0]}" != "$0" ]
    return $?
  fi
  if [ -n "${ZSH_VERSION:-}" ]; then
    case "${ZSH_EVAL_CONTEXT:-}" in
      *:file*) return 0 ;;
      *) return 1 ;;
    esac
  fi
  # Unknown shell: assume sourced when PS1 exists.
  [ -n "${PS1:-}" ]
}

if ! _vet45_is_sourced; then
  echo "error: activate.sh must be sourced, not executed." >&2
  echo "  source scripts/env/activate.sh" >&2
  unset -f _vet45_is_sourced
  exit 1
fi
unset -f _vet45_is_sourced

if [ -n "${BASH_VERSION:-}" ]; then
  _VET45_ACTIVATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # zsh / other: $0 is the script path when sourced
  _VET45_ACTIVATE_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
_VET45_ROOT="$(cd "$_VET45_ACTIVATE_DIR/../.." && pwd)"
unset _VET45_ACTIVATE_DIR

# Re-activate: strip previous wrapping first.
if type deactivate >/dev/null 2>&1; then
  deactivate >/dev/null 2>&1 || true
fi

_vet45_read_state() {
  local state_file="$_VET45_ROOT/.vet45/state.json"
  local active_file="$_VET45_ROOT/.vet45/active"
  local profile="default"
  local environment="development"

  if [ -f "$state_file" ]; then
    local parsed_profile parsed_env
    parsed_profile="$(sed -n 's/.*"profile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$state_file" | head -1)"
    parsed_env="$(sed -n 's/.*"environment"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$state_file" | head -1)"
    [ -n "$parsed_profile" ] && profile="$parsed_profile"
    [ -n "$parsed_env" ] && environment="$parsed_env"
  elif [ -f "$active_file" ]; then
    environment="$(tr -d '[:space:]' <"$active_file")"
    [ -z "$environment" ] && environment="development"
  fi

  printf '%s %s' "$profile" "$environment"
}

_vet45_prompt_label() {
  local parts profile environment
  parts="$(_vet45_read_state)"
  profile="${parts%% *}"
  environment="${parts#* }"
  printf '(%s/%s)' "$profile" "$environment"
}

_vet45_refresh_exports() {
  local parts profile environment
  parts="$(_vet45_read_state)"
  profile="${parts%% *}"
  environment="${parts#* }"
  export VET45_ROOT="$_VET45_ROOT"
  export VET45_PROFILE="$profile"
  export VET45_ENV_ID="$environment"
  export VET45_ACTIVE_LABEL="($profile/$environment)"
}

deactivate() {
  if [ -n "${_VET45_OLD_PS1+x}" ]; then
    PS1="$_VET45_OLD_PS1"
    unset _VET45_OLD_PS1
  fi
  if [ -n "${ZSH_VERSION:-}" ] && [ -n "${_VET45_OLD_PROMPT+x}" ]; then
    PROMPT="$_VET45_OLD_PROMPT"
    unset _VET45_OLD_PROMPT
  fi

  unset VET45_ROOT VET45_PROFILE VET45_ENV_ID VET45_ACTIVE_LABEL
  unset _VET45_ROOT

  unset -f _vet45_read_state 2>/dev/null || true
  unset -f _vet45_prompt_label 2>/dev/null || true
  unset -f _vet45_refresh_exports 2>/dev/null || true
  unset -f deactivate 2>/dev/null || true
}

_vet45_refresh_exports

if [ -n "${ZSH_VERSION:-}" ]; then
  _VET45_OLD_PROMPT="${PROMPT-}"
  # shellcheck disable=SC2016
  PROMPT='$(_vet45_prompt_label) '"${PROMPT-}"
else
  _VET45_OLD_PS1="${PS1-}"
  # shellcheck disable=SC2016
  PS1='$(_vet45_prompt_label) '"${PS1-}"
fi

echo "Activated Vet45: $VET45_ACTIVE_LABEL"
echo "  root: $VET45_ROOT"
echo "  tip: melos run env:use:staging  # prompt updates automatically"
echo "  tip: deactivate"
