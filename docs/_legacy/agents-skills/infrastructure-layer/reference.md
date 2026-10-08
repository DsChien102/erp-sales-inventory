# Infrastructure Layer — Reference

Canonical source: [`docs/infrastructure_layer_skill.md`](../../../docs/infrastructure_layer_skill.md)

Reference implementation: **`modules/sales/infrastructure`**

---

## Section Index

| § | Topic |
|---|-------|
| 1 | Purpose |
| 2 | Package layout (`lib/src/`) |
| 3 | `domain/` folder rules (per aggregate) |
| 4 | `configuration/` modules & load order |
| 5 | Cross-cutting folders (`rpc`, `supabase`, `adapters`, `errors`) |
| 6 | Mutation vs query (RPC outbox) |
| 7 | Messaging (outbox / inbox / internal commands) |
| 8 | Public barrel rules |
| 9 | Tests (mirror `domain/`) |
| 10 | Refactor checklist for other modules |

---

## Quick Reference

### Module layout

```text
modules/<module_name>/
  domain/              # lib/domain.dart
  application/         # lib/application.dart
  integration_events/
  infrastructure/      # lib/infrastructure.dart  ← this skill
  presentation/        # optional
```

### Infrastructure `lib/src/` (canonical)

```text
configuration/     # DI modules, startup, processing, events_bus, mediation
domain/            # per-aggregate repos, gateways, mappers (Meetings Domain/)
  <aggregate>/
  shared/
rpc/
supabase/
adapters/
errors/
<module>_module.dart
```

**Deprecated (do not add):** `composition/`, root `repositories/`, `read_models/`, `mappers/`.

### Package barrel rule

```text
- Barrel: lib/infrastructure.dart — startup, composition root, module facade, public errors
- Implementation: lib/src/ — private
- External import: package:vet45_<module>_infrastructure/infrastructure.dart
- Never import package:.../src/... from outside the package
```

### `domain/<aggregate>/` file types

```text
<aggregate>_mapper.dart
supabase_<aggregate>_repository.dart       → I<Aggregate>Repository
supabase_<aggregate>_read_gateway.dart     → I<...>ReadGateway
supabase_<aggregate>_command_gateway.dart   → I<...>CommandGateway
```

Shared cross-aggregate mappers → `domain/shared/`.

### `configuration/` load order

```text
LoggingModule
→ DataAccessModule        (registers domain/* + rpc + adapters)
→ EventsBusModule
→ OutboxModule            (IDomainNotificationMapper)
→ ProcessingModule        (messaging clients + dispatchers)
→ MediationModule         (CommandBus, QueryBus, I<Module>Module)
→ EventsBusStartup.initialize()
```

### Messaging dispatchers (Infrastructure)

```text
<Module>NotificationDispatcher       → INotificationHandler (shared)
<Module>IntegrationEventDispatcher → IIntegrationEventNotificationHandler (application)
IntegrationEventGenericHandler     → writes inbox (event.id)
```

### RPC naming

```text
<module>_<action>_<entity>
<module>.enqueue_outbox_message      (inside mutation transaction)
<module>.claim_outbox_batch / complete_outbox_message
<module>.receive_integration_event   (p_message_id = event.id)
<module>.claim_inbox_batch / complete_inbox_message
<module>.enqueue_internal_command
```

### Query targets

```text
Prefer:  sales.v_order_summary, sales.v_order_details
Avoid:   sales.orders, sales.order_lines (private write tables)
```

---

## Review Checklist

Before accepting infrastructure work:

```text
[ ] Separate infrastructure package; barrel exports startup/module only
[ ] lib/src/configuration/ for DI (not composition/)
[ ] domain/<aggregate>/ for repos, gateways, mappers (not flat folders)
[ ] domain/shared/ only for truly shared mappers
[ ] DataAccessModule registers all domain adapters
[ ] No presentation or other-module infrastructure imports
[ ] Critical mutations + outbox via RPC same transaction
[ ] Idempotency: unique (tenant, scope, key) + lock; begin/complete in same txn; map IDEMPOTENCY_CONFLICT
[ ] No command.id-as-idempotencyKey for client retries
[ ] No IDomainEventsBus / Dart IOutboxWriter on production path
[ ] ProcessOutbox uses DomainNotificationMapper keys matching RPC event_type
[ ] Integration events use event.id; inbox PK = event.id
[ ] Application *IntegrationEventHandler / INotificationHandler (shared)
[ ] EventsBusStartup subscribes IntegrationEventGenericHandler
[ ] CommandsExecutor + GetIt scope; handlers not calling GetIt directly
[ ] RPC client maps errors; repos/gateways have no business rules
[ ] Read gateways return DTOs; tenant filter on queries
[ ] claim/complete messaging RPCs; idempotent internal commands (sourceEventId dedup)
[ ] Tests under test/domain/<aggregate>/ mirroring lib/src/domain/
[ ] Codegen registrar in configuration/processing/generated/
```

---

## SQL pattern — idempotency_records (module-owned)

```sql
-- Conceptual; author in _drafts/, promote when requested.
-- Identity: (tenant_id, command_scope, idempotency_key)
create table if not exists <module>.idempotency_records (
  id uuid primary key,
  tenant_id uuid not null,
  command_scope text not null,
  idempotency_key text not null,
  payload_hash text not null default '',
  status text not null, -- in_progress | succeeded | …
  result_type text,
  result_id uuid,
  result_snapshot jsonb,
  correlation_id uuid,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (tenant_id, command_scope, idempotency_key)
);

-- Inside mutation RPC: advisory lock → begin → mutate + outbox → complete
-- Reference: sales._begin_sales_idempotency / sales._complete_sales_idempotency
```

Doc: [docs/architecture/13-idempotency-and-message-processing.md](../../../docs/architecture/13-idempotency-and-message-processing.md)
---

## Testing layout

```text
<module>_infrastructure/test/
  domain/
    <aggregate>/
      *_mapper_test.dart
  configuration/
    *_composition_root_test.dart
  messaging/
  rpc/
  errors/
```

Use `Fake<Module>RpcClient` with `responses` map for unit tests.

---

## Refactor other modules (Catalog, …)

Follow §10 in [infrastructure_layer_skill.md](../../../docs/infrastructure_layer_skill.md):

1. Scaffold `configuration/` + `domain/` from Sales
2. Move existing flat files into `domain/<aggregate>/`
3. Consolidate DI in `data_access_module.dart`
4. Align messaging with Meetings-style identity
5. Update tests to mirror `domain/`
6. Trim barrel exports
