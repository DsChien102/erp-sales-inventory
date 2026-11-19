# shellcheck shell=bash
# Activate Mosaic Retail env/profile for the current shell (like Python venv).
#
# Usage (bash / zsh):
#   source scripts/env/activate.sh
#   . scripts/env/activate.sh
#
# Deactivate:
#   deactivate

# Refuse being executed as a standalone process (cannot mutate parent PS1).
_c45_is_sourced() {
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

if ! _c45_is_sourced; then
  echo "error: activate.sh must be sourced, not executed." >&2
  echo "  source scripts/env/activate.sh" >&2
  unset -f _c45_is_sourced
  exit 1
fi
unset -f _c45_is_sourced

if [ -n "${BASH_VERSION:-}" ]; then
  _C45_ACTIVATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # zsh / other: $0 is the script path when sourced
  _C45_ACTIVATE_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
_C45_ROOT="$(cd "$_C45_ACTIVATE_DIR/../.." && pwd)"
unset _C45_ACTIVATE_DIR

# Re-activate: strip previous wrapping first.
if type deactivate >/dev/null 2>&1; then
  deactivate >/dev/null 2>&1 || true
fi

_c45_read_state() {
  local state_file="$_C45_ROOT/.c45/state.json"
  local active_file="$_C45_ROOT/.c45/active"
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

_c45_prompt_label() {
  local parts profile environment
  parts="$(_c45_read_state)"
  profile="${parts%% *}"
  environment="${parts#* }"
  printf '(%s/%s)' "$profile" "$environment"
}

_c45_refresh_exports() {
  local parts profile environment
  parts="$(_c45_read_state)"
  profile="${parts%% *}"
  environment="${parts#* }"
  export C45_ROOT="$_C45_ROOT"
  export C45_PROFILE="$profile"
  export C45_ENV_ID="$environment"
  export C45_ACTIVE_LABEL="($profile/$environment)"
}

deactivate() {
  if [ -n "${_C45_OLD_PS1+x}" ]; then
    PS1="$_C45_OLD_PS1"
    unset _C45_OLD_PS1
  fi
  if [ -n "${ZSH_VERSION:-}" ] && [ -n "${_C45_OLD_PROMPT+x}" ]; then
    PROMPT="$_C45_OLD_PROMPT"
    unset _C45_OLD_PROMPT
  fi
  if [ -n "${_C45_OLD_PATH+x}" ]; then
    PATH="$_C45_OLD_PATH"
    export PATH
    unset _C45_OLD_PATH
  fi

  unset C45_ROOT C45_PROFILE C45_ENV_ID C45_ACTIVE_LABEL
  unset _C45_ROOT

  unset -f _c45_read_state 2>/dev/null || true
  unset -f _c45_prompt_label 2>/dev/null || true
  unset -f _c45_refresh_exports 2>/dev/null || true
  unset -f deactivate 2>/dev/null || true
}

_c45_refresh_exports

# Prepend AOT bin dir so `c45` resolves without Melos.
_C45_BIN="$_C45_ROOT/.c45/bin"
_C45_OLD_PATH="${PATH-}"
case ":${PATH-}:" in
  *":$_C45_BIN:"*) ;;
  *) export PATH="$_C45_BIN:${PATH-}" ;;
esac

if [ -n "${ZSH_VERSION:-}" ]; then
  _C45_OLD_PROMPT="${PROMPT-}"
  # shellcheck disable=SC2016
  PROMPT='$(_c45_prompt_label) '"${PROMPT-}"
else
  _C45_OLD_PS1="${PS1-}"
  # shellcheck disable=SC2016
  PS1='$(_c45_prompt_label) '"${PS1-}"
fi

echo "Activated Mosaic Retail: $C45_ACTIVE_LABEL"
echo "  root: $C45_ROOT"
if [ -x "$_C45_BIN/c45" ]; then
  echo "  cli:  c45  (AOT on PATH)"
  if [ -t 1 ]; then
    echo "  tip: c45  # interactive TUI (profile/env switch)"
    echo "  tip: eval \"\$(c45 completion zsh)\"  # shell completion (once in ~/.zshrc)"
  fi
else
  echo "  tip: melos run env:build  # compile AOT binary for faster c45"
fi
echo "  tip: melos run env:use:staging  # prompt updates automatically"
echo "  tip: deactivate"
unset _C45_BIN