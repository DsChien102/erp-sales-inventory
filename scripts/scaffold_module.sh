#!/usr/bin/env bash
# Scaffold Vet45 module layer packages (greenfield skeleton).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULES_ROOT="$ROOT/modules"

ANALYSIS_OPTIONS_DART='include: package:vet45_lints/dart.yaml'
ANALYSIS_OPTIONS_FLUTTER='include: package:vet45_lints/flutter.yaml'

pascal_case() {
  local name="$1"
  echo "$name" | awk -F_ '{for(i=1;i<=NF;i++){printf toupper(substr($i,1,1)) substr($i,2)}} END{print ""}'
}

create_analysis_options() {
  local dir="$1"
  local kind="$2"
  if [[ "$kind" == "flutter" ]]; then
    printf '%s\n' "$ANALYSIS_OPTIONS_FLUTTER" >"$dir/analysis_options.yaml"
  else
    printf '%s\n' "$ANALYSIS_OPTIONS_DART" >"$dir/analysis_options.yaml"
  fi
}

create_domain() {
  local module="$1"
  local dir="$MODULES_ROOT/$module/domain"
  local pkg="vet45_${module}_domain"
  mkdir -p "$dir/lib/src"
  create_analysis_options "$dir" dart
  cat >"$dir/pubspec.yaml" <<EOF
name: $pkg
description: ${module} bounded context — domain layer (skeleton).
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: '>=3.11.1 <4.0.0'

dependencies:
  vet45_shared_domain:
    path: ../../../packages/vet45_shared/domain
  equatable: ^2.0.8
  meta: ^1.17.0

dev_dependencies:
  vet45_lints: ^1.0.0
  test: ^1.25.0
EOF
  cat >"$dir/lib/domain.dart" <<EOF
/// ${module} domain layer — add aggregates and value objects here.
library;
EOF
  touch "$dir/lib/src/.gitkeep"
}

create_application() {
  local module="$1"
  local pascal
  pascal="$(pascal_case "$module")"
  local dir="$MODULES_ROOT/$module/application"
  local pkg="vet45_${module}_application"
  mkdir -p "$dir/lib/src/contracts"
  create_analysis_options "$dir" dart
  cat >"$dir/pubspec.yaml" <<EOF
name: $pkg
description: ${module} bounded context — application layer (skeleton).
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: '>=3.11.1 <4.0.0'

dependencies:
  vet45_${module}_domain:
    path: ../domain
  vet45_shared_application:
    path: ../../../packages/vet45_shared/application
  meta: ^1.17.0

dev_dependencies:
  vet45_lints: ^1.0.0
  test: ^1.25.0
EOF
  cat >"$dir/lib/application.dart" <<EOF
library;

export 'src/contracts/i_${module}_module.dart';
EOF
  cat >"$dir/lib/src/contracts/i_${module}_module.dart" <<EOF
import 'package:vet45_shared_application/application.dart';

/// Public facade for the ${module} bounded context.
abstract interface class I${pascal}Module implements IModuleMediator {}
EOF
  touch "$dir/lib/src/.gitkeep"
}

create_infrastructure() {
  local module="$1"
  local pascal
  pascal="$(pascal_case "$module")"
  local dir="$MODULES_ROOT/$module/infrastructure"
  local pkg="vet45_${module}_infrastructure"
  mkdir -p "$dir/lib/src/configuration/data_access"
  mkdir -p "$dir/lib/src/configuration/mediation"
  create_analysis_options "$dir" dart
  cat >"$dir/pubspec.yaml" <<EOF
name: $pkg
description: ${module} bounded context — infrastructure layer (skeleton).
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: '>=3.11.1 <4.0.0'

dependencies:
  get_it: ^9.2.1
  meta: ^1.17.0
  supabase: ^2.12.2
  vet45_${module}_application:
    path: ../application
  vet45_${module}_domain:
    path: ../domain
  vet45_${module}_integration_events:
    path: ../integration_events
  vet45_shared_application:
    path: ../../../packages/vet45_shared/application
  vet45_shared_domain:
    path: ../../../packages/vet45_shared/domain
  vet45_shared_infrastructure:
    path: ../../../packages/vet45_shared/infrastructure

dev_dependencies:
  build_runner: ^2.15.0
  vet45_lints: ^1.0.0
  test: ^1.26.2
  vet45_generator:
    path: ../../../packages/vet45_generator
EOF
  cat >"$dir/build.yaml" <<EOF
targets:
  \$default:
    builders:
      vet45_generator|cqrs_registrar:
        enabled: false
EOF
  cat >"$dir/lib/infrastructure.dart" <<EOF
library;

export 'src/configuration/${module}_startup.dart';
export 'src/configuration/data_access/data_access_module.dart';
export 'src/configuration/mediation/mediation_module.dart';
EOF
  cat >"$dir/lib/src/configuration/data_access/data_access_module.dart" <<EOF
/// Registers ${module} gateways and repositories (skeleton).
final class ${pascal}DataAccessModule {
  const ${pascal}DataAccessModule();
}
EOF
  cat >"$dir/lib/src/configuration/mediation/mediation_module.dart" <<EOF
/// Registers ${module} command/query handlers (skeleton).
final class ${pascal}MediationModule {
  const ${pascal}MediationModule();
}
EOF
  cat >"$dir/lib/src/configuration/${module}_startup.dart" <<EOF
import 'package:supabase/supabase.dart';
import 'package:vet45_${module}_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _${pascal}ModuleStub implements I${pascal}Module {
  const _${pascal}ModuleStub();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError('${pascal} module not implemented yet.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError('${pascal} module not implemented yet.');
  }
}

/// Composition root entry point for the ${module} module (skeleton).
final class ${pascal}Startup {
  static I${pascal}Module initialize({required SupabaseClient supabase}) {
    // Skeleton: wire DataAccessModule and MediationModule when implementing.
    return const _${pascal}ModuleStub();
  }
}
EOF
}

create_integration_events() {
  local module="$1"
  local dir="$MODULES_ROOT/$module/integration_events"
  local pkg="vet45_${module}_integration_events"
  mkdir -p "$dir/lib/src"
  create_analysis_options "$dir" dart
  cat >"$dir/pubspec.yaml" <<EOF
name: $pkg
description: ${module} module integration event contracts (skeleton).
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: '>=3.11.1 <4.0.0'

dependencies:
  json_annotation: ^4.9.0
  vet45_shared_infrastructure:
    path: ../../../packages/vet45_shared/infrastructure

dev_dependencies:
  build_runner: ^2.15.0
  json_serializable: ^6.9.0
  vet45_lints: ^1.0.0
  test: ^1.30.0
EOF
  cat >"$dir/lib/integration_events.dart" <<EOF
/// ${module} integration events — add contracts here.
library;
EOF
  touch "$dir/lib/src/.gitkeep"
}

create_presentation() {
  local module="$1"
  local pascal
  pascal="$(pascal_case "$module")"
  local dir="$MODULES_ROOT/$module/presentation"
  local pkg="vet45_${module}_presentation"
  mkdir -p "$dir/lib/src"
  create_analysis_options "$dir" flutter
  cat >"$dir/pubspec.yaml" <<EOF
name: $pkg
description: ${module} bounded context — presentation layer (skeleton).
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: '>=3.11.1 <4.0.0'
  flutter: '>=1.17.0'

dependencies:
  flutter:
    sdk: flutter
  get_it: ^9.2.1
  vet45_design_system: ^1.0.0
  vet45_${module}_application: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  vet45_lints: ^1.0.0

flutter:
EOF
  cat >"$dir/lib/presentation.dart" <<EOF
library;

export 'src/${module}_presentation_module.dart';
EOF
  cat >"$dir/lib/src/${module}_presentation_module.dart" <<EOF
import 'package:get_it/get_it.dart';

/// Registers ${module} UI dependencies (skeleton).
final class ${pascal}PresentationModule {
  static void register(GetIt getIt) {}
}
EOF
}

scaffold_presentation_only() {
  local module="$1"
  if [[ -d "$MODULES_ROOT/$module/presentation" ]]; then
    echo "Skip ${module}/presentation — already exists."
    return 0
  fi
  if [[ ! -d "$MODULES_ROOT/$module/application" ]]; then
    echo "Error: ${module}/application missing — scaffold full module first." >&2
    return 1
  fi
  create_presentation "$module"
  echo "Scaffolded ${module}/presentation"
}

scaffold_module() {
  local module="$1"
  local with_presentation="$2"
  create_domain "$module"
  create_application "$module"
  create_integration_events "$module"
  create_infrastructure "$module"
  if [[ "$with_presentation" == "true" ]]; then
    create_presentation "$module"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  scaffold_module.sh all
      Scaffold all 6 original modules (destructive for existing layers).

  scaffold_module.sh module <name> [with_presentation]
      Scaffold one module (domain, application, infrastructure, integration_events).
      Pass "true" as third arg to include presentation.

  scaffold_module.sh presentation <name>...
      Add presentation layer only (skips if already present).

Examples:
  scaffold_module.sh module dashboard true
  scaffold_module.sh presentation iam inventory costing
EOF
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    all)
      for module in catalog sales partner; do
        scaffold_module "$module" true
      done
      for module in iam inventory costing; do
        scaffold_module "$module" false
      done
      echo "Scaffolded 6 modules under $MODULES_ROOT"
      ;;
    module)
      local name="${1:?module name required}"
      local with_presentation="${2:-false}"
      scaffold_module "$name" "$with_presentation"
      echo "Scaffolded module ${name} under $MODULES_ROOT"
      ;;
    presentation)
      if [[ $# -eq 0 ]]; then
        echo "Error: module name(s) required." >&2
        usage
        exit 1
      fi
      for module in "$@"; do
        scaffold_presentation_only "$module"
      done
      ;;
    -h|--help|help|"")
      usage
      exit 0
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
