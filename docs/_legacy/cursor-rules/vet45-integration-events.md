---
description: Integration events must be past business facts — never command/request disguised as outbox events
alwaysApply: true
---

# Vet45 Integration Events — Fact vs Command (mandatory)

Agents **MUST NOT** violate these rules when designing or implementing messaging.

## Definitions (never blur)

| Kind | Meaning | Transport | Naming |
| --- | --- | --- | --- |
| **Domain event** | Fact inside one module/aggregate | In-process only | Past tense (`SalesOrderFinalized`) |
| **Integration event** | Cross-module **business fact** that already happened in the publisher | `{module}.outbox_messages` → worker → inbox | Past fact + version: `{context}_{entity}_{past}.v1` (e.g. `sales_order_finalized.v1`) |
| **Integration / delivery command** | Request for another module (or same module async) to **do work** | `{module}.integration_commands` (+ intent tables such as `*_impact_requests`) | Imperative OK: `sales.{owner}.{action}.v1` (e.g. `sales.inventory.apply_impact.v1`) |
| **Internal command** | Deferred work inside the same module | `{module}.internal_commands` via `ICommandScheduler` | Command type name |

## Hard rules

1. **Outbox carries facts only.** An outbox `event_type` MUST describe something that **already occurred** in the publisher’s business (completed, cancelled, recorded, confirmed, changed).
2. **Never publish imperative / request-shaped “events”.** Forbidden on outbox / `integration_events` package as IE types:
   - `*.requested`, `*.request`, `*_requested`
   - verbs like `apply`, `retry`, `reconcile`, `reverse`, `deliver`, `send` used as the primary event meaning
   - names that mean “please do X for me” rather than “X already happened here”
3. **Cross-module work requests** go to **`integration_commands`** (and Sales-owned intent rows such as impact requests). Do **not** also invent a parallel `*.requested.v1` outbox event for the same handoff.
4. **Map correctly:** domain/business commit → (optional) durable intent + command → **separately** emit lifecycle **facts** when the publisher’s state changed (`sales_order_finalized.v1`, `sales_order_cancelled.v1`, …). Facts do not replace commands; commands do not replace facts.
5. **Package `modules/*/integration_events`** holds **integration event** contracts (facts). Command/handoff payloads are **not** integration events — do not subclass `TenantScopedIntegrationEvent` for “please apply impact” envelopes.
6. **Consumer pattern:** fact IE → application `IIntegrationEventNotificationHandler` → enqueue **internal command** in the owning module. Do not treat an outbox row as a remote procedure call.

## Allowed vs rejected examples

| Allowed (fact / outbox IE) | Rejected (disguised command) |
| --- | --- |
| `sales_order_finalized.v1` | `sales.inventory_impact.requested.v1` |
| `sales_order_cancelled.v1` | `sales.receivable_impact.requested.v1` |
| `sales_payment_recorded.v1` | `sales.order.pricing_reversal_requested` |
| `return_exchange_completed.v1` | `sales.integration.retry_requested` as an “event” |

If Sales needs Inventory/Receivable work: persist `*_impact_requests` + `integration_commands` with imperative `command_name`; emit **separate** lifecycle facts on the Sales mutation. Do not put the handoff itself on outbox as a fake event.

## Docs to read

- [docs/architecture/07-integration-and-messaging.md](docs/architecture/07-integration-and-messaging.md) — Fact vs command section
- [docs/integration_event_flow.md](docs/integration_event_flow.md)
- TH-05: [harness/01-domain-model.md](docs/themes/TH-05-sales-orders/harness/01-domain-model.md) §9; impact design may still describe legacy debt — **follow this rule for new work**

## Review rejection

Reject PRs/slices that add or keep **new** outbox / IE types whose names or payloads are primarily “request to act”, unless the user has explicitly approved a documented grandfathered exception.

**Known debt (do not copy):** Sales `*.impact.requested.v1` outbox; IAM notification routing may still use request-shaped names — normalize via dedicated slices, never as the pattern for new cross-module handoffs.
