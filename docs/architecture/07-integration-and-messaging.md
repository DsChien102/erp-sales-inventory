# Integration và messaging

> Nội dung chi tiết luồng event: [integration_event_flow.md](../integration_event_flow.md)

## Mô hình

| Loại | Mục đích | Nơi chạy |
| ---- | -------- | -------- |
| **Integration event** | Contract liên module (JSON, versioned type) | Package `integration_events` |
| **Domain event** | Nội bộ aggregate | Domain layer — map ra integration ở handler |
| **Outbox/Inbox** | Durable delivery | Postgres + `messaging_worker` |
| **App event bus** | UI refresh local | Flutter — không thay outbox |

## Luồng publish (target)

```mermaid
sequenceDiagram
  participant H as CommandHandler
  participant RPC as Supabase_RPC
  participant OB as Outbox_Table
  participant W as MessagingWorker
  participant IH as IntegrationHandler

  H->>RPC: persist mutation
  RPC->>OB: insert outbox row
  W->>OB: poll pending
  W->>IH: dispatch event
  IH->>IH: update read model / stock / ...
```

## Luồng consume (target)

Consumer **luôn** là handler ở **application layer** (`IIntegrationEventNotificationHandler`), và inbox/internal-command được xử lý **qua `CommandBus` + `DefaultCommandPipeline`** bằng `IRecurringCommand` — không gọi command handler trực tiếp từ infrastructure.

```mermaid
sequenceDiagram
  participant W as MessagingWorker
  participant CB as CommandBus_Pipeline
  participant IBH as ProcessInboxCommandHandler
  participant Reg as IntegrationEventRegistry
  participant Disp as IntegrationEventDispatcher
  participant CH as ConsumerHandler_application
  participant RH as InternalCommandHandler
  participant GW as Gateway_RPC

  W->>CB: execute ProcessInboxCommand (IRecurringCommand)
  CB->>IBH: handle
  IBH->>Reg: deserialize (event_type + payload)
  IBH->>Disp: publish(event)
  Disp->>CH: handle(event)
  CH->>CB: execute internal command
  CB->>RH: pipeline (validate → log → handler)
  RH->>GW: idempotent projection write
```

- **Deserialize** (`{Module}IntegrationEventRegistry`) + inbox draining là concern của infrastructure.
- **Mapping event → command** là concern của application (consumer handler), không đặt ở infrastructure.
- Dispatcher wiring do codegen sinh (`createGenerated{Module}IntegrationEventDispatcher`).
- Reference: `modules/partner/` (inbox projection cho transaction history).

## Package integration events

```text
modules/{name}/integration_events/lib/src/events/
```

Registry deserialize: `IamIntegrationEventRegistry`, tương tự catalog/sales.

## Messaging worker

- `apps/messaging_worker` — self-loop tick, service role Supabase
- Module handlers đăng ký trong worker bootstrap
- **Không** khuyến nghị client POST `/tick` — xem playbook deploy

## ERP client messaging

- `MessagingOrchestrator` — đăng ký module messaging adapters
- `MessagingPollPolicy` — có thể disable client poll (`MESSAGING_POLL_ENABLED=false`)
- Flush sau mutation: optional UX; backbone là worker

## Ví dụ event theo theme

| Theme | Event ví dụ |
| ----- | ----------- |
| TH-02 | `ProductCreated`, `AvailableStockChanged` |
| TH-04 | `SalesOrderCheckedOut` |
| TH-01 | `TenantCreated`, `TenantMemberRoleChanged` |
| TH-06 | `StockAdjusted` (consumer) |

## Liên kết

- [integration_event_flow.md](../integration_event_flow.md)
- [messaging_e2e_checklist.md](../messaging_e2e_checklist.md)
- [operations/messaging_schema.md](../operations/messaging_schema.md) — Postgres migrations + RPC reference
