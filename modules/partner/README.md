# Partner — TH-03 bounded context

Second bounded context with **codegen enabled** (mirror IAM). Theme harness: [docs/themes/TH-03-partner/](docs/themes/TH-03-partner/).

## Folder map

```text
modules/partner/
  application/          # commands, queries, handlers, DTOs, ports, FakePartnerModule
  domain/               # BusinessPartner aggregate, PartnerPermissions, value objects
  infrastructure/
    lib/src/configuration/
      data_access/      # gateways only (no handler singletons)
      mediation/        # registerGeneratedPartnerHandlers + queries
      processing/       # codegen triggers + PartnerCommandPipeline
        generated/      # *.g.dart — commit after melos run codegen
    lib/src/domain/     # Supabase RPC adapters
  presentation/         # reusable dialogs/widgets (DeactivatePartnerDialog, …)
```

## Codegen ritual

```bash
melos bootstrap
cd modules/partner/infrastructure && dart run build_runner build --delete-conflicting-outputs
# or: melos run codegen
```

Builders in `infrastructure/build.yaml`:

- `cqrs_registrar` → `registerGeneratedPartnerHandlers` / `registerGeneratedPartnerQueries`
- `cqrs_infrastructure` → `PartnerCommandPipeline` bus extensions
- `access_metadata` → `partnerAccessMetadataRegistry` (messages need `implements ICommand` / `IQuery`)
- `module_manifest` → scans `PartnerModuleDefinition`; handlers from `vet45_partner_application`
- `cqrs_integration_event_registry` → `createGeneratedPartnerIntegrationEventDispatcher` (scans `*_integration_event_handler.dart` in application)

**Important:** command/query classes must explicitly `implements ICommand<T>` / `IQuery<T>` for access metadata generation.

## Handler annotations

```dart
import 'package:vet45_partner_domain/domain.dart';

@CommandHandlerFor(RegisterPartnerCommand)
final class RegisterPartnerCommandHandler implements ICommandHandler<...> { ... }

@RequiresPermission(PartnerPermissions.create) // domain constant — không hardcode string
@RequiresTenant()
final class RegisterPartnerCommand extends CommandBase<RegisterPartnerResult>
    implements ICommand<RegisterPartnerResult>, ITenantScopedCommand { ... }
```

`@ModuleManifest` permissions: `PartnerPermissions.*` trong `PartnerModuleDefinition`.

Validators: `implements ICommandValidator<MyCommand>` — auto-registered by codegen.

**Note:** `IPartnerDuplicateChecker` lives in domain (`abstract interface class`) — re-exported from `application.dart` for generated registrar imports.

## Host wiring (ERP)

`PartnerStartup.initialize` receives `IPermissionChecker` + `ITenantAccessChecker` from IAM runtime (host injects checkers).

`PartnerCommandPipeline.buildBusinessPipeline` injects generated `partnerAccessMetadataRegistry` + checkers from GetIt.

## Messaging worker

Partner Epic-03 consume path chạy trong `apps/messaging_worker` qua **cùng composition root** `PartnerStartup` — không còn processor tay tách rời.

```dart
import 'package:vet45_partner_infrastructure/infrastructure.dart';

final partnerModule = PartnerMessagingModule.create(
  supabase: serviceRoleClient,
  loggerFactory: loggerFactory,
);
// MessagingModuleRegistry([partnerModule])
```

`PartnerMessagingModule.create` gọi `PartnerStartup.initializeForMessaging` (allow-all checkers vì recurring processing không đi qua business authorization pipeline) và delegate `processMessagingOnce` về `IPartnerModule.executeCommandAsync`:

```text
worker → ProcessInboxCommand / ProcessInternalCommandsCommand (IRecurringCommand)
  → CommandBus → DefaultCommandPipeline
  → ProcessInboxCommandHandler → PartnerIntegrationEventRegistry (deserialize)
    → PartnerIntegrationEventDispatcher (codegen) → consumer handler (application layer)
    → IPartnerInternalCommandDispatcher → CommandBus (internal pipeline)
    → RecordPartnerTransactionHistoryCommandHandler → write gateway RPC
  → ProcessInternalCommandsCommandHandler → CommandBus (internal pipeline)
```

Điểm mấu chốt (align doc 07):

- **Mapping event → command** nằm ở **application layer** (`application/lib/src/integration_events/*_integration_event_handler.dart` implement `IIntegrationEventNotificationHandler`), không ở infrastructure.
- Inbox / internal-command xử lý **qua `CommandBus` + pipeline** bằng `IRecurringCommand` — không gọi handler trực tiếp.
- Contract RPC schema `partner` giữ nguyên (claim-token): `claim_inbox_batch` / `complete_inbox_message` / `fail_inbox_message` / `claim_internal_commands_batch` / `complete_internal_command` / `fail_internal_command`.
- Internal-command deserialize (`RecordPartnerTransactionHistoryCommand.fromJson`) là concern của infrastructure; `ISerializableInternalCommand`/`InternalCommandSerializer` (nay ở `vet45_adapters`) **không** dùng ở đây để tránh application → adapters.

Cross-module E2E vẫn blocked cho đến khi platform outbox relay + source publishers ship.

## New handler checklist

1. Annotate handler (`@CommandHandlerFor` / `@QueryHandlerFor`)
2. Annotate message (`@RequiresPermission`, `@RequiresTenant`, `implements ICommand` / `IQuery`)
3. `melos run codegen` → commit `processing/generated/*.g.dart`
4. Handler test + `./scripts/ci/verify_harness.sh`

Golden reference for layout: [modules/iam/README.md](../iam/README.md).
