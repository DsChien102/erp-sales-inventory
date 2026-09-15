---
description: Idempotency and command/message processing — messageId vs idempotencyKey, DB-backed records, Outbox/Inbox separation
alwaysApply: true
---

# Vet45 Idempotency & Command Processing (mandatory)

Agents **MUST NOT** violate these rules when designing or implementing mutations, RPC, or messaging consumers.

## Definitions (never blur)

| Concept | Answers | Typical Vet45 field |
| --- | --- | --- |
| **messageId / command.id** | Which *delivery* / command *instance* is this? | `ICommand.id`, outbox/inbox row id, `IntegrationEvent.id` |
| **correlationId** | Which workflow / business process? | `correlationId` on mutation contracts |
| **causationId** | Which message directly caused this one? | Parent `command.id` / `event.id` |
| **idempotencyKey** | Is this the same *logical operation*? | `idempotencyKey` — stable across client retries |
| **Inbox** | Has this *message delivery* been consumed? | `{module}.inbox_messages` (often by `event.id`) |
| **Outbox** | Was the event stored reliably with the business commit? | `{module}.outbox_messages` in same RPC txn |
| **Business UNIQUE** | May this *business identity* exist twice? | e.g. `UNIQUE(order_number)`, SKU |

Full doc: [docs/architecture/13-idempotency-and-message-processing.md](docs/architecture/13-idempotency-and-message-processing.md)

## Hard rules

1. **`messageId` ≠ `idempotencyKey`.** Client/worker retries may create a new `command.id` every time; the logical operation key must stay the same. Never use `command.id` alone as the operation idempotency key for user/client retries.

2. **Critical mutations require `idempotencyKey` + DB protection.** Required for: checkout/finalize, record payment, cancel order, stock reserve/adjust, onboarding, complete return/exchange, and other money/inventory/lifecycle side effects. Queries do not need an idempotency record.

3. **Database is the last line of defense.** Reject application-only checks (`if (!exists) create`). Persist `(tenant_id, scope/command_scope, idempotency_key)` with a unique/PK constraint and concurrency control (`pg_advisory_xact_lock` and/or `SELECT … FOR UPDATE`). Reference: `sales._begin_sales_idempotency` / `sales.idempotency_records`.

4. **Atomic with business state and outbox.** Begin/complete idempotency, business mutation, and outbox inserts MUST share the same Postgres transaction. Never mark `succeeded`/`COMPLETED` before business commit; never commit the idempotency row in a separate transaction from the mutation.

5. **Replay and payload hash.** Same key + matching `payload_hash` → return prior `result_snapshot` (replay). Same key + different hash → raise `IDEMPOTENCY_CONFLICT`. In-progress → do not re-run as a new operation (wait / concurrent status).

6. **Inbox ≠ operation idempotency.** Inbox dedups *delivery*. Operation idempotency protects *logical effect*. Event consumers: Inbox by `event.id`, then enqueue internal commands with dedup `(tenant_id, source_event_id, command_type)`. Do not assume Inbox alone makes every business mutation safe under worker retry.

7. **Business uniqueness ≠ idempotency.** `UNIQUE` constraints protect invariants; they do not replace `(tenant, scope, idempotency_key)` for “same checkout retried three times”.

8. **Offline-first / POS:** client generates a stable logical id (e.g. checkout id) as `idempotencyKey` before send; retries keep that key and reuse the same payload hash.

## Allowed vs rejected

| Allowed | Rejected |
| --- | --- |
| `FinalizeSalesOrderCommand` with `idempotencyKey` + RPC `_begin_*` / `_complete_*` | Retry with new key each time, or key = `command.id` |
| Replay snapshot when hash matches | Silent ignore of duplicate without returning prior result |
| Inbox + `sourceEventId` enqueue dedup | “We have Inbox, so no idempotency on create receivable” when retries can double-create |
| Outbox facts in same txn as mutation | Idempotency completed in Dart after RPC returns |

## Docs to read

- [docs/architecture/13-idempotency-and-message-processing.md](docs/architecture/13-idempotency-and-message-processing.md)
- [docs/architecture/09-application-commands.md](docs/architecture/09-application-commands.md) — §2.1 `command.id` vs `idempotencyKey`
- [docs/architecture/07-integration-and-messaging.md](docs/architecture/07-integration-and-messaging.md) — Outbox / Inbox / Idempotency
- [docs/integration_event_flow.md](docs/integration_event_flow.md)

## Review rejection

Reject PRs/slices that add critical mutations without DB-backed idempotency, that treat `command.id` as the retry key, that persist idempotency outside the business+outbox transaction, or that conflate Inbox delivery dedup with operation idempotency for new cross-module side effects.
