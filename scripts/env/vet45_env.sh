#!/usr/bin/env bash
# Vet45 environment manager — thin wrapper around tools/vet45_env Dart CLI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLI=(dart run "$ROOT/tools/vet45_env/bin/vet45_env.dart")

usage() {
  cat <<'EOF'
Usage: vet45_env.sh <command> [args]

Commands:
  list                    List environments and active selection
  use <id>                Set active environment + align supabase link
  sync [--env <id>] [--target <id>]
                          Align supabase link + generate target .env files
  link [--env <id>]       Align supabase link only
  doctor [--env <id>] [--target <id>] [--offline]
                          Validate configuration (per-target key deps)
  resolve [--env <id>]    Print JSON resolve payload
  resolve-shell [--env <id>]
                          Print shell KEY=value exports
  active                  Print active environment id
  run <target> <action>   Run app command for active environment

Run targets:
  erp debug|debug:web|debug:ios|build-ios|deploy-ios
  worker serve|once|docker|deploy
EOF
}

require_ios_deploy_env() {
  case "${VET45_ENV_ID:-}" in
    staging | production) ;;
    *)
      echo "iOS build/deploy requires active env staging or production (current: ${VET45_ENV_ID:-unknown})"
      echo "Run: melos run env:use:staging  (or env:use:production)"
      exit 1
      ;;
  esac
}

require_railway_deploy_env() {
  if [[ -z "${RAILWAY_ENVIRONMENT:-}" ]]; then
    echo "Worker deploy requires Railway target (active: ${VET45_ENV_ID:-unknown})"
    echo "Run: melos run env:use:staging  (or env:use:production)"
    exit 1
  fi
}

load_resolve_shell() {
  local target="${1:-}"
  local env_id="${2:-}"
  local lines
  local sync_args=()
  local resolve_args=()

  if [[ -n "$target" ]]; then
    sync_args+=(--target "$target")
  fi
  if [[ -n "$env_id" ]]; then
    sync_args+=(--env "$env_id")
    resolve_args+=(--env "$env_id")
  fi

  # Sync only the run target so missing unrelated secrets do not block.
  "${CLI[@]}" sync "${sync_args[@]}" >/dev/null
  lines="$("${CLI[@]}" resolve-shell "${resolve_args[@]}")"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    export "$line"
  done <<<"$lines"
}

cmd_run() {
  local target="${1:-}" action="${2:-}"
  shift 2 || true

  local env_id=""
  local filtered=()
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == --env && $# -ge 2 ]]; then
      env_id="$2"
      shift 2
    else
      filtered+=("$1")
      shift
    fi
  done

  load_resolve_shell "$target" "$env_id"

  # Bash 3.2 + set -u: "${filtered[@]}" on an empty array is unbound; ${filtered+"${filtered[@]}"} is safe.
  case "$target" in
    erp)
      case "$action" in
        debug)
          cd "$ROOT/apps/erp"
          # shellcheck disable=SC2086
          flutter run --flavor "$ERP_FLAVOR" --dart-define-from-file="$ERP_ENV_BASENAME" ${filtered+"${filtered[@]}"}
          ;;
        debug:web)
          cd "$ROOT/apps/erp"
          # shellcheck disable=SC2086
          flutter run -d chrome --flavor "$ERP_FLAVOR" --dart-define-from-file="$ERP_ENV_BASENAME" ${filtered+"${filtered[@]}"}
          ;;
        debug:ios)
          cd "$ROOT/apps/erp"
          # shellcheck disable=SC2086
          flutter run -d ios --flavor "$ERP_FLAVOR" --dart-define-from-file="$ERP_ENV_BASENAME" ${filtered+"${filtered[@]}"}
          ;;
        build-ios)
          require_ios_deploy_env
          # shellcheck disable=SC2086
          exec "$ROOT/apps/erp/scripts/build_ios.sh" --env "$VET45_ENV_ID" ${filtered+"${filtered[@]}"}
          ;;
        deploy-ios)
          require_ios_deploy_env
          # Validate shared deploy secrets without requiring worker keys.
          "${CLI[@]}" doctor --target deploy --offline --env "$VET45_ENV_ID"
          "$ROOT/apps/erp/scripts/build_ios.sh" --env "$VET45_ENV_ID"
          exec "$ROOT/apps/erp/deploy-ios.sh" --env "$VET45_ENV_ID"
          ;;
        *)
          echo "Unknown erp action: $action"
          exit 64
          ;;
      esac
      ;;
    worker)
      case "$action" in
        serve | once | docker)
          export WORKER_ENV_FILE
          if [[ -n "${WORKER_DOCKER_SUPABASE_URL:-}" ]]; then
            export WORKER_SUPABASE_URL="$WORKER_DOCKER_SUPABASE_URL"
          fi
          exec "$ROOT/scripts/dev/run_messaging_worker.sh" "$action"
          ;;
        deploy)
          require_railway_deploy_env
          # shellcheck disable=SC2086
          exec "$ROOT/apps/messaging_worker/scripts/deploy.sh" --env "$RAILWAY_ENVIRONMENT" ${filtered+"${filtered[@]}"}
          ;;
        *)
          echo "Unknown worker action: $action"
          exit 64
          ;;
      esac
      ;;
    *)
      echo "Unknown run target: $target"
      exit 64
      ;;
  esac
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    list | use | sync | link | doctor | resolve | resolve-shell | active)
      "${CLI[@]}" "$cmd" "$@"
      ;;
    run)
      cmd_run "$@"
      ;;
    -h | --help | "")
      usage
      ;;
    *)
      echo "Unknown command: $cmd"
      usage
      exit 64
      ;;
  esac
}

main "$@"
