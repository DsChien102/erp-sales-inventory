# Infrastructure Layer — Canonical Specification

**Reference tạm thời:** layout mục tiêu trong tài liệu này + `packages/vet45_generator/test/fixtures/`. Tất cả `modules/*/infrastructure/` hiện là skeleton (`{Name}Startup` trả stub). Golden module **IAM** planned — xem [docs/harness/PROGRESS.md](harness/PROGRESS.md).

## 1. Purpose

Infrastructure implements **how** a module talks to Postgres, Supabase, cache, and the ERP integration bus. It must not decide business behavior.

```text
Application decides what use case runs.
Domain decides what is valid business behavior.
Infrastructure implements RPC, persistence adapters, messaging clients, mappers.
Presentation decides UI.
```

---

## 2. Package layout (`lib/src/`)

Infrastructure packages are **Dart-only** (no Flutter SDK). Use `package:supabase` for `SupabaseClient`, `PostgrestException`, etc. The ERP app (`supabase_flutter`) and messaging worker (`package:supabase`) inject a `SupabaseClient` into `<Module>Startup.initialize(supabase: ...)`. Tests use `package:test` + `mocktail` (not `flutter_test`).

```text
modules/<module>/infrastructure/
  pubspec.yaml                     # sdk only; supabase + get_it + meta
  lib/
    infrastructure.dart              # barrel: startup, composition root, public exceptions only
    src/
      <module>_module.dart           # implements I<Module>Module facade
      configuration/                 # Meetings ConfigureCompositionRoot
        <module>_startup.dart
        <module>_composition_root.dart
        logging/
        data_access/
          data_access_module.dart    # wires domain/ + rpc + adapters
        events_bus/
          events_bus_module.dart
          events_bus_startup.dart
          <module>_integration_event_generic_handler.dart
        outbox/
          outbox_module.dart         # DomainNotificationMapper BiMap
        processing/
          processing_module.dart
          commands_executor.dart
          <module>_command_pipeline.dart
          decorators/
          generated/                 # vet45_generator output
          outbox/                    # claim/complete clients + ProcessOutbox handler
          inbox/
          internal_commands/
          <module>_notification_dispatcher.dart
          <module>_integration_event_dispatcher.dart
        mediation/
          mediation_module.dart      # CommandBus, QueryBus, handler registration
      domain/                        # per aggregate — Meetings Infrastructure/Domain/
        <aggregate_snake_case>/
          <aggregate>_mapper.dart
          supabase_<aggregate>_repository.dart          # if aggregate has write model
          supabase_<aggregate>_read_gateway.dart          # if module exposes read DTOs
          supabase_<aggregate>_command_gateway.dart       # if mutation via RPC gateway port
        shared/                      # mappers shared across aggregates (read DTOs, snapshots)
      rpc/
        i_<module>_rpc_client.dart
        supabase_<module>_rpc_client.dart
      supabase/
        supabase_query_executor.dart
      adapters/                      # cross-module lookup ports (not owned by one aggregate)
      errors/
        <module>_error_mapper.dart
        <module>_infrastructure_exception.dart
      test/                          # mirror domain/ + configuration/ + rpc/
```

### Sales reference tree (current)

```text
domain/
  sales_order_drafts/     # draft mapper, repository, read gateway, command gateway
  sales_orders/           # order mapper, repository, read gateway, command gateway
  return_exchanges/       # mapper, read + command gateways
  shared/                 # sales_order_read_mapper (draft + order list/detail DTOs)
```

**Không dùng** thư mục phẳng cũ: `repositories/`, `read_models/`, `mappers/` ở root `lib/src/`.

---

## 3. `domain/` folder rules

Align với Meetings `Infrastructure/Domain/<Aggregate>/`:

| File pattern | Implements (Application/Domain port) | Notes |
|--------------|--------------------------------------|-------|
| `<aggregate>_mapper.dart` | Row ↔ aggregate / command payload | Pure mapping; no business rules |
| `supabase_<aggregate>_repository.dart` | `I<Aggregate>Repository` | Load/save via RPC |
| `supabase_<aggregate>_read_gateway.dart` | `I<...>ReadGateway` | Views / RPC reads → DTOs |
| `supabase_<aggregate>_command_gateway.dart` | `I<...>CommandGateway` | Mutations via RPC |

Rules:

- **One folder per aggregate** (snake_case, match `modules/<module>/domain/lib/src/<aggregate>/`).
- Cross-aggregate mappers → `domain/shared/` (e.g. read mapper dùng cho draft + order).
- Aggregate folder may import `../../rpc/`, `../../supabase/`; **never** import `configuration/`.
- `DataAccessModule` registers all domain adapters; không register từng file rải rác.

Naming:

```text
Class:  SupabaseSalesOrderDraftRepository
File:   domain/sales_order_drafts/supabase_sales_order_draft_repository.dart
RPC:    sales.checkout_order, sales.save_draft (schema prefix in SQL)
```

---

## 4. `configuration/` modules (composition order)

[`SalesStartup`](../../modules/sales/infrastructure/lib/src/configuration/sales_startup.dart):

```text
1. LoggingModule
2. DataAccessModule      → rpc, query executor, domain/* repositories/gateways, adapters
3. EventsBusModule       → ERP singleton IEventsBus
4. OutboxModule          → IDomainNotificationMapper
5. ProcessingModule      → messaging clients, dispatchers, process handlers
6. MediationModule       → CommandBus, QueryBus, ISalesModule
→ EventsBusStartup.initialize()  (subscribe generic handlers on IEventsBus)
→ <Module>CompositionRoot.setContainer(container)
```

Business code enters via `CommandsExecutor.execute` (GetIt lifetime scope per command), not raw `GetIt` in handlers.

Codegen (`vet45_generator`):

- `configuration/processing/<module>_command_pipeline.dart` → `generated/*_registrar.g.dart`, `*_command_registration.g.dart`
- `MediationModule` calls `registerGenerated<Module>Handlers`

---

## 5. Cross-cutting folders (not under `domain/`)

| Folder | Purpose |
|--------|---------|
| `rpc/` | Typed wrapper over Supabase RPC; error mapping |
| `supabase/` | Schema-scoped query executor (views) |
| `adapters/` | Ports spanning modules (product lookup, inventory stub) |
| `errors/` | Map Postgrest/ RPC errors → app failures |

---

## 6. Mutation vs query

| Operation | Mechanism |
|-----------|-----------|
| Critical mutations (checkout, payment, stock) | **Postgres RPC** in same transaction as domain write |
| Outbox for integration events | **`enqueue_outbox_message` inside mutation RPC** — not Dart `IOutboxWriter` after command |
| Reads / lists | Module **views** (`sales.v_*`) via `SupabaseQueryExecutor` |
| Cross-module async work | `IEventsBus` → inbox → `*IntegrationEventHandler` → internal commands |

**Không dùng** `IDomainEventsBus` / Dart-side outbox writer cho production path — Dart không có UoW atomic với Postgres.

---

## 7. Messaging (§17)

Cross-module routing follows **Meetings** pattern with **Meetings-style event identity** (`event.id` = inbox PK).

### Principles

- Postgres: **claim/complete** RPCs for locking, persistence, idempotency.
- **Outbox write**: RPC trong cùng transaction (e.g. `sales.checkout_order` → `event_type = sales.order.checked_out`).
- **ProcessOutbox**: claim → deserialize via `DomainNotificationMapper` → `<Module>NotificationDispatcher` → `INotificationHandler` → `IEventsBus.publish(IntegrationEvent)`.
- **Inbound**: `EventsBusStartup` registers types in `IntegrationEventTypeRegistry`, then `IEventsBus.subscribe(IntegrationEventGenericHandler<T>)` → `receive_integration_event(messageId: event.id, occurredOn: event.occurredOn)`.
- **ProcessInbox**: deserialize → `<Module>IntegrationEventDispatcher.publish` → Application `IIntegrationEventNotificationHandler` — **never** republish to bus.
- Same-module loopback: subscribe on `IEventsBus` → generic handler → inbox → handler (optional no-op if side effect already in RPC).

| Bus / handler | Package | Purpose |
|-----|---------|---------|
| `IntegrationEvent` | `vet45_shared_infrastructure` | Base DTO (`id`, `occurredOn`, `eventType`) |
| `IEventsBus` | `vet45_shared_infrastructure` | ERP-wide integration bus; `subscribe(IIntegrationEventHandler<T>)` |
| `IIntegrationEventHandler<T>` | `vet45_shared_infrastructure` | Bus → inbox (`IntegrationEventGenericHandler`) |
| `IIntegrationEventNotificationHandler<T>` | `vet45_shared_infrastructure` | Inbox → business (MediatR `INotificationHandler` equivalent) |
| `INotificationHandler` | `vet45_shared_application` | Outbox domain notification handlers |

### Worker

ERP [`MessagingWorkerScheduler`](../../apps/erp/lib/core/messaging/messaging_worker_scheduler.dart) calls `<Module>Startup.processOutboxOnce` / `processInboxOnce` / `processInternalCommandsOnce`.

Internal commands: `ISerializableInternalCommand` + codegen registry; dedup via `(tenant_id, source_event_id, command_type)`.

**Postgres schema:** migration chính thức trong `supabase/migrations/YYYYMMDDHHMMSS_*.sql`; agents viết draft tại `supabase/migrations/_drafts/` ([AGENTS.md](../AGENTS.md)). Ví dụ messaging: `20260623000001_platform_messaging_foundation.sql` + `20260623000002_*`. Ops: [operations/messaging_schema.md](../operations/messaging_schema.md).

---

## 8. Public barrel

[`infrastructure.dart`](../../modules/sales/infrastructure/lib/infrastructure.dart) exports **only**:

- `<Module>Startup`, `<Module>CompositionRoot`
- `I<Module>Module` facade
- Public infrastructure exceptions

Do **not** export `domain/`, `rpc/`, `configuration/processing/` internals.

---

## 9. Tests

Mirror production layout:

```text
test/
  domain/
    <aggregate>/
      <aggregate>_mapper_test.dart
  configuration/
    <module>_composition_root_test.dart
  messaging/
  rpc/
  errors/
```

Use `Fake<Module>RpcClient` for unit tests; composition tests via:

```dart
static I{Module}Module initializeForTesting({
  required SupabaseClient supabase,
  GetIt? container,
});
```

IAM golden module (phase 2) implements đầu tiên. Handler tests dùng `vet45_shared_testing` — xem `packages/vet45_shared/testing/test/shared_testing_test.dart`.

CI guards: `scripts/ci/verify_harness.sh` (includes `guard_infra_dart_only.sh`, `guard_layer_imports.sh`).

---

## 10. Refactor checklist (other modules → Sales structure)

When migrating e.g. Catalog infrastructure:

```text
[ ] Create configuration/ with *_startup, *_composition_root, ordered modules
[ ] Move flat repositories/read_models/mappers → domain/<aggregate>/
[ ] Add domain/shared/ only for truly shared mappers
[ ] Wire all domain adapters in data_access_module.dart
[ ] Move processing (outbox/inbox/internal) under configuration/processing/
[ ] Use IntegrationEventGenericHandler + IntegrationEventDispatcher (not *InboxHandler in infra)
[ ] Outbox via RPC in transaction; ProcessOutbox uses DomainNotificationMapper event_type keys
[ ] Register handlers in MediationModule + codegen registrar
[ ] Update test/ tree to mirror domain/
[ ] Barrel exports startup + module only
[ ] Remove dead composition/, IDomainEventsBus, Dart IOutboxWriter if present
```

---

## Related docs

- E2E checklist: [messaging_e2e_checklist.md](./messaging_e2e_checklist.md)
- Module template: [MODULES_IMPLEMENTATION_TEMPLATE.md](./MODULES_IMPLEMENTATION_TEMPLATE.md)
- Agent skill: [.cursor/skills/infrastructure-layer/SKILL.md](../.cursor/skills/infrastructure-layer/SKILL.md)
