---
name: infrastructure-layer
description: Designs, generates, reviews, and refactors the Infrastructure layer for ERP Flutter/Supabase modules. Use when working on module infrastructure packages, Supabase RPC clients, repositories, read gateways, outbox/inbox workers, DI configuration modules, domain/ aggregate folders, or when the user mentions infrastructure layer, Supabase RPC, or module technical adapters.
---

# Infrastructure Layer

## Purpose

Infrastructure implements **how** a module talks to the outside world. It must not decide business behavior.

```text
Infrastructure implements how the module talks to the outside world.
Application decides what use case is being executed.
Domain decides what is valid business behavior.
Presentation decides how the user sees and interacts with it.
```

**Read first:** [reference.md](reference.md) · **Canonical spec:** [docs/infrastructure_layer_skill.md](../../../docs/infrastructure_layer_skill.md) · **Reference module:** `modules/sales/infrastructure`

---

## When to Apply

- Creating or scaffolding `<module>_infrastructure` for a new module
- Refactoring flat `repositories/` / `read_models/` / `mappers/` → `domain/<aggregate>/`
- Implementing Supabase RPC clients, repositories, read gateways under `domain/`
- Adding outbox/inbox/internal-command clients under `configuration/processing/`
- Wiring DI via `configuration/*_startup.dart` + ordered modules (Meetings pattern)
- Reviewing infrastructure PRs for boundary violations

---

## Workflow

### 1. Clarify module scope

Identify `<module_name>` and aggregates from domain layer. Map each aggregate to a `domain/<aggregate>/` folder.

```text
Capability              Location (Sales reference)
RPC + query executor    rpc/, supabase/
Aggregate persistence   domain/<aggregate>/supabase_*_repository.dart
Read DTOs               domain/<aggregate>/supabase_*_read_gateway.dart
Mutations via port      domain/<aggregate>/supabase_*_command_gateway.dart
Row mapping             domain/<aggregate>/*_mapper.dart
Shared read mappers     domain/shared/
Cross-module ports      adapters/
Messaging               configuration/processing/{outbox,inbox,internal_commands}/
Integration bus         configuration/events_bus/
DI / buses              configuration/{logging,data_access,mediation,outbox}/
```

Skip folders the module does not need yet.

### 2. Verify package boundaries

```text
Infrastructure MAY depend on:
  <module>_application, <module>_domain, <module>_integration_events,
  shared packages, supabase (Dart package), get_it, meta, etc.

Infrastructure MUST NOT depend on:
  flutter SDK, supabase_flutter (app/worker host initializes Supabase)
  <module>_presentation
  other_module_infrastructure
  other_module_presentation
```

### 3. Choose mutation vs query strategy

| Operation | Mechanism |
|-----------|-----------|
| Important mutations | Postgres RPC in same transaction |
| Outbox integration events | `enqueue_outbox_message` **inside** mutation RPC |
| Reads / lists | Module views via `SupabaseQueryExecutor` |
| Cross-module async | `IEventsBus` → inbox → `*IntegrationEventHandler` |

Do **not** use Dart-side `IDomainEventsBus` or post-command outbox writers for atomic paths.

### 4. Generate skeleton (Meetings + Sales canonical)

```text
modules/<module>/infrastructure/
  lib/
    infrastructure.dart
    src/
      <module>_module.dart
      configuration/
        <module>_startup.dart
        <module>_composition_root.dart
        logging/
        data_access/data_access_module.dart
        events_bus/
        outbox/outbox_module.dart
        processing/
          processing_module.dart
          commands_executor.dart
          <module>_command_pipeline.dart
          generated/
          outbox/ inbox/ internal_commands/
          <module>_notification_dispatcher.dart
          <module>_integration_event_dispatcher.dart
        mediation/mediation_module.dart
      domain/
        <aggregate>/
          *_mapper.dart
          supabase_*_repository.dart
          supabase_*_read_gateway.dart
          supabase_*_command_gateway.dart
        shared/
      rpc/
      supabase/
      adapters/
      errors/
```

**Do not** create root-level `repositories/`, `read_models/`, `mappers/`, or `composition/`.

### 5. Implement contracts in `domain/<aggregate>/`

| Port (Application/Domain) | Infrastructure file |
|---------------------------|---------------------|
| `I<Aggregate>Repository` | `supabase_<aggregate>_repository.dart` |
| `I<...>ReadGateway` | `supabase_<aggregate>_read_gateway.dart` |
| `I<...>CommandGateway` | `supabase_<aggregate>_command_gateway.dart` |

Register all in `DataAccessModule.load()`.

Patterns:

- `I<Module>RpcClient` + `Supabase<Module>RpcClient` in `rpc/`
- Errors via `<Module>ErrorMapper`
- `idempotency_key` / `command.id` on critical RPC params

### 6. Messaging (if module publishes/consumes integration events)

```text
Outbox:  RPC writes row → ProcessOutboxCommandHandler → INotificationHandler → IEventsBus
Inbound: EventsBusStartup → IntegrationEventGenericHandler → inbox (id = event.id)
Inbox:   ProcessInboxCommandHandler → IntegrationEventDispatcher → *IntegrationEventHandler
Async:   handler → ICommandScheduler.enqueue(sourceEventId: event.id)
```

Handlers live in **Application** (`*IntegrationEventHandler`, `*NotificationHandler`), not Infrastructure `*InboxHandler`.

**Serialization boundary:** `json_serializable` chỉ dùng trong package `integration_events` (payload `fromJson` / `toPayload`). Infrastructure dùng registry + `event.toPayload()`; không thêm `@JsonSerializable` cho integration events ở infrastructure/application. Handler/command wiring vẫn do `vet45_generator`.

### 7. DI / configuration modules

Load order in `<Module>Startup._configureCompositionRoot`:

```text
LoggingModule → DataAccessModule → EventsBusModule → OutboxModule
→ ProcessingModule → MediationModule → EventsBusStartup.initialize()
```

**Module-private container (Direction A — canonical host wiring):**

- `<Module>Startup.initialize()` always creates `GetIt.asNewInstance()` for internal DI (`CommandBus`, gateways, outbox/inbox workers, mappers, …).
- Host (ERP) **never** passes its `getIt` into `initialize()`. Host only registers the returned `I<Module>Module` facade plus shared cross-cutting services (`ILoggerFactory`, `IEventsBus`).
- Shared `IEventsBus` is injected via `integrationEventBus:` param (same instance on host and inside each module container).
- Tests that need to inspect registrations use `@visibleForTesting initializeForTesting(container: ...)`.

```dart
// ERP host (apps/erp/lib/core/di/injection.dart)
final salesModule = SalesStartup.initialize(
  supabase: supabase.client,
  loggerFactory: getIt(),
  integrationEventBus: getIt<IEventsBus>(),
);
getIt.registerSingleton<ISalesModule>(salesModule);
```

Entry point for commands: `CommandsExecutor.execute` (uses module-private `*CompositionRoot.container`).

**Anti-pattern:** passing host `getIt` into `*Startup.initialize(container: getIt)` — causes GetIt type collisions between modules (`CommandBus`, `IDomainNotificationMapper`, etc.).

### 8. Validate before finishing

Run checklist in [reference.md](reference.md#review-checklist).

---

## Required Agent Output

When designing or generating infrastructure:

```text
1.  Infrastructure responsibility summary
2.  Proposed folder structure (domain/<aggregate>/ + configuration/)
3.  Required dependencies (pubspec)
4.  Ports → domain/ file mapping per aggregate
5.  Supabase RPC list
6.  Read views list
7.  Outbox/Inbox/InternalCommands plan (or N/A)
8.  configuration/ module list + load order
9.  DI skeleton (DataAccessModule registrations)
10. Error mapper skeleton
11. Test layout (test/domain/<aggregate>/)
12. Review checklist (checked)
13. Anti-pattern warnings
```

---

## Supabase schema (agents)

- Viết DDL/RPC tạm vào `supabase/migrations/_drafts/<scope>_<description>.sql` (không prefix timestamp).
- Không tạo/sửa `supabase/migrations/[0-9]*.sql` trừ khi user yêu cầu promote migration.
- Chi tiết: [AGENTS.md](../../../AGENTS.md) — **Schema & migration**.

## Anti-Patterns (reject these)

```text
- Timestamped migration files during normal agent slices (use _drafts/)
- Flat repositories/, read_models/, mappers/ at lib/src root
- composition/ folder (use configuration/)
- Dart writes outbox after command without RPC transaction
- IDomainEventsBus for production messaging
- *InboxHandler in Infrastructure (use Application *IntegrationEventHandler)
- Flutter writes private business tables directly
- Business rules inside repository/mapper/gateway
- Infrastructure imports another module's infrastructure
- Queries hit private write tables instead of views
- Missing idempotency on critical mutations
- Host passes its GetIt container into `<Module>Startup.initialize(container: ...)`
- `supabase_flutter` or `flutter` in infrastructure `pubspec.yaml` (use `package:supabase`; inject `SupabaseClient` from host)
- Calling `<Module>Startup.initialize()` without `supabase:` (client is required)
```

---

## Additional Resources

- Full specification: [docs/infrastructure_layer_skill.md](../../../docs/infrastructure_layer_skill.md)
- Detail index: [reference.md](reference.md)

---

## Test harness

Handler và composition tests dùng `vet45_shared_testing`:

| Utility | Use for |
| ------- | ------- |
| `PipelineTestHarness` | Test validation/auth decorators run before handler |
| `InMemoryCommandBus` | Execute commands without Supabase |
| `FakeExecutionContext` | Tenant/user context in tests |
| `FakePermissionChecker` | RBAC decorator tests |

```dart
<Module>Startup.initializeForTesting(
  supabase: fakeSupabaseClient,
  container: GetIt.asNewInstance(),
);
```

Canonical example: `packages/vet45_shared/testing/test/shared_testing_test.dart`

Test layout: `test/domain/<aggregate>/`, `test/configuration/<module>_composition_root_test.dart`
