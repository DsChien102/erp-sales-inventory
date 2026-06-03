# vet45_generator

In-house `build_runner` codegen for CQRS handler registration and internal command serializer registries. **Module-agnostic** — each infrastructure package configures its own `module_name` in `build.yaml`.

## Builders

| Builder | Trigger (convention) | Output (convention) |
|---------|----------------------|---------------------|
| `cqrs_registrar` | `lib/src/configuration/mediation/mediation_module.dart` | `processing/generated/{module}_cqrs_registrar.g.dart` |
| `cqrs_internal_registry` | `lib/src/configuration/processing/processing_module.dart` | `processing/generated/{module}_internal_command_registry.g.dart` |
| `cqrs_infrastructure` | `lib/src/configuration/processing/{module}_command_pipeline.dart` | `processing/generated/{module}_command_registration.g.dart`, `processing/generated/{module}_command_bus_extensions.g.dart` |
| `access_metadata` | `lib/src/configuration/processing/processing_module.dart` | `processing/generated/{module}_access_metadata.g.dart` |
| `module_manifest` | `lib/src/configuration/processing/processing_module.dart` | `processing/generated/{module}_module_manifest.g.dart` |

## Module configuration (`build.yaml`)

Required options per builder:

```yaml
options:
  module_name: sales          # snake_case — drives naming conventions
  scan_package: vet45_sales_application
  output: lib/src/configuration/processing/generated/sales_cqrs_registrar.g.dart
```

### Naming conventions (from `module_name`)

| `module_name: sales` | Derived value |
|----------------------|---------------|
| Application package | `vet45_sales_application` |
| Domain package | `vet45_sales_domain` |
| Command bus | `CommandBus` (shared) |
| Query bus | `QueryBus` (shared) |
| Registration helper | `SalesCommandRegistration` |
| Handler fn | `registerGeneratedSalesHandlers` |
| Internal serializer fn | `createGeneratedSalesInternalCommandSerializer` |

Override any symbol via optional keys: `application_package`, `command_bus_type`, `query_bus_type`, `registration_class`, `internal_command_client_type`, `import_domain: false`, etc.

Reference: [`modules/sales/infrastructure/build.yaml`](../../modules/sales/infrastructure/build.yaml).

## Handler discovery

Scanned from `{scan_package}` by file naming + interface:

| Pattern | Registration |
|---------|--------------|
| `*_command_handler.dart` + `ICommandHandler<C,R>` | Business or internal (`C extends InternalCommandBase`) |
| `*_query_handler.dart` + `IQueryHandler<Q,R>` | Query bus |
| `*_command_validator.dart` + `ICommandValidator<C>` | GetIt factory |
| `*_command.dart` + `ISerializableInternalCommand` | Internal command serializer |

Constructor deps: required params → `container.get<T>()`; optional with defaults skipped.

Annotations: [`packages/vet45_annotations`](../../packages/vet45_annotations/) — `@CommandHandlerFor`, `@QueryHandlerFor`, `@RequiresPermission`, `@ModuleManifest`, etc. Legacy `@CqrsBusinessHandler` / `@CqrsQueryHandler` remain supported.

### Handler annotation discovery (Phase 9B)

| Pattern | Registration |
|---------|--------------|
| `@CommandHandlerFor(C)` on handler | Business command handler for `C` |
| `@QueryHandlerFor(Q)` on handler | Query handler for `Q` |
| Duplicate handler for same message type | Build error (`vet45_generator:HB:`) |

### Access metadata builder (Phase 9C)

Opt-in per module `build.yaml`:

```yaml
targets:
  $default:
    builders:
      vet45_generator|access_metadata:
        enabled: true
        options:
          module_name: catalog
          scan_package: vet45_catalog_infrastructure
          access_scan_package: vet45_catalog_application
          strict_access_metadata: false
```

Annotate **command/query classes** (not handlers) with `@RequiresPermission`, `@PublicAccess`, `@RequiresTenant`, `@Idempotent`.

### Module manifest builder (Phase 9D)

Opt-in per module. Requires exactly one `@ModuleManifest` class in infrastructure configuration. Merges declared permissions with permissions found in access metadata and lists registered command/query types.

## Troubleshooting

| Diagnostic prefix | Meaning |
|-------------------|---------|
| `vet45_generator:HB:` | Handler registry error (duplicate handler, annotation conflict) |
| `vet45_generator:AC:` | Access metadata error (conflicting annotations, invalid idempotency field) |
| `vet45_generator:MF:` | Module manifest error (missing or duplicate `@ModuleManifest`) |

Runtime buses work without codegen. Generated registries are optional convenience.

See [codegen migration guide](../../docs/architecture/codegen-migration.md).

## Onboard a new module

1. Scaffold infrastructure configuration layout (mirror sales):
   - `configuration/processing/{module}_command_pipeline.dart` (hand-written — triggers infrastructure codegen)
   - Point `generate_for` at `mediation_module.dart` and `processing_module.dart`
2. Wire shared buses via typedef (no duplicate bus implementation):

```dart
typedef InventoryCommandBus = CommandBus;
typedef InventoryQueryBus = QueryBus;
```

3. Copy [`modules/sales/infrastructure/build.yaml`](../../modules/sales/infrastructure/build.yaml); set `module_name` + `scan_package`
4. Add dev deps to `{module}/infrastructure/pubspec.yaml`: `build_runner`, `vet45_generator`
5. Add package to root workspace `pubspec.yaml`
6. Use shared [`json_coercion`](../../packages/vet45_shared/infrastructure/lib/mapping/json_coercion.dart) in read mappers
7. Run `melos run codegen` (any package with `build_runner` dependency)

## Run

```bash
melos run codegen
```

Or per module:

```bash
cd modules/{module}/infrastructure && dart run build_runner build
```

## Integration event serialization (`json_serializable`)

**Not** handled by `vet45_generator`. Use `json_serializable` in `modules/{module}/integration_events/`:

| Concern | Tool |
|---------|------|
| Integration event `fromJson` / `toPayload` | `json_serializable` + `*.g.dart` |
| Handler wiring, internal command registry | `vet45_generator` |

Shared helpers: `normalizeIntegrationEventJson`, `DateTimeUtcConverter` in `vet45_shared_infrastructure` (re-exported from `vet45_shared_application`). Reference: `modules/sales/integration_events`, `modules/catalog/integration_events`.

## Internal command serialization (`json_serializable`)

**Not** handled by `vet45_generator`. Use `json_serializable` in `modules/{module}/application/` for classes implementing `ISerializableInternalCommand`:

| Concern | Tool |
|---------|------|
| Internal command `toJson` / `fromJson` | `json_serializable` + `*.g.dart` |
| Registry `commandType → fromJson` | `vet45_generator` (`cqrs_internal_registry`) |

Shared helpers: `normalizeInternalCommandDeserializeJson`, `stripInternalCommandRowId` in `vet45_shared_application`. Row `id` inject lúc deserialize; payload persist **không** chứa `id` hoặc `command_type`. Reference: `modules/sales/application` (`AttachCustomerToDraftCommand`).
