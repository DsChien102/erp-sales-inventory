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
  participant SCH as ICommandScheduler
  participant Q as internal_commands
  participant PIC as ProcessInternalCommandsHandler
  participant CE as CommandsExecutor
  participant RH as InternalCommandHandler
  participant GW as Gateway_RPC

  W->>CB: execute ProcessInboxCommand (IRecurringCommand)
  CB->>IBH: handle
  IBH->>Reg: deserialize (event_type + payload)
  IBH->>Disp: publish(event)
  Disp->>CH: handle(event)
  CH->>SCH: enqueue(internal command, sourceEventId)
  SCH->>Q: enqueue_internal_command RPC

  W->>CB: execute ProcessInternalCommandsCommand
  CB->>PIC: handle
  PIC->>Q: claim batch
  PIC->>CE: execute(deserialized command)
  CE->>CB: CommandBus pipeline
  CB->>RH: validate → log → completion → handler
  RH->>GW: idempotent projection write
```

- **Deserialize** (`{Module}IntegrationEventRegistry`) + inbox draining là concern của infrastructure.
- **Mapping event → command** là concern của application (consumer handler), không đặt ở infrastructure.
- Consumer handler **chỉ enqueue** qua `ICommandScheduler`; execution thuộc `ProcessInternalCommandsCommandHandler` + `CommandsExecutor`.
- Dispatcher wiring do codegen sinh (`createGenerated{Module}IntegrationEventDispatcher`).
- Internal-command serialize/deserialize: `ISerializableInternalCommand` + `InternalCommandSerializer` (`vet45_shared`) + codegen `cqrs_internal_registry`.
- Golden layout: `modules/sales/` (`SalesStartup.processMessagingOnce`, `Process{Outbox,Inbox,InternalCommands}`, `SupabaseSalesCommandScheduler`); inbox projection ví dụ: `modules/partner/`.

## Package integration events

```text
modules/{name}/integration_events/lib/src/events/
```

Registry deserialize: `IamIntegrationEventRegistry`, tương tự catalog/sales.

## Messaging worker

- `apps/messaging_worker` — self-loop tick, service role Supabase
- **P1 (triển khai):** module binding registry (`MessagingModuleBinding` + `IMessagingCommandFactory`) và pool song song theo partition key `(tenant_id, module_schema, queue_type)` với `WORKER_CONCURRENCY`
- Discovery RPC `platform.list_tenants_with_pending_messaging(p_limit, p_modules)` — worker truyền `p_modules` từ danh sách module đã bind
- **P3 (chưa triển khai):** replica shard theo `hashtext(tenant_id) % replica_count`; xem [operations/messaging_worker_scaling.md](../operations/messaging_worker_scaling.md)
- **Không** khuyến nghị client POST `/tick` — xem playbook deploy

## Trạng thái module (2026-07)

| Module | Messaging Dart hôm nay | Ghi chú |
| ------ | ---------------------- | ------- |
| **Target (golden)** | `ProcessOutbox` → `ProcessInbox` → `ProcessInternalCommands` qua `CommandBus` + `ICommandScheduler`; folder `configuration/processing/{outbox,inbox,internal_commands}` | Golden = `modules/sales/infrastructure` (`SalesStartup.processMessagingOnce` + `Process{Outbox,Inbox,InternalCommands}` + `SupabaseSalesCommandScheduler`); catalog/partner cùng pattern; sequence “Luồng consume (target)” ở trên |
| **IAM (S-NOTIFY)** | Consume: `ProcessOutbox` → `ProcessInbox` (self-consume) → `ProcessInternalCommands` qua `IamStartup.processMessagingOnce`. Publish: **mutation RPC** `enqueue_outbox_message` (không Dart client). Folder `configuration/processing/{outbox,inbox,internal_commands}`; adapters `src/adapters/notification/` | `IIamOutboxClient` chỉ claim/complete/fail; event `iam.email.delivery_requested` → `SendEmailDeliveryCommand` qua `ICommandScheduler` |
| Partner (working tree) | Greenfield / reboot TH-03 | Rebuild theo golden khi implement |

Reference code IAM: `EmailDeliveryRequestedIntegrationEvent`, `ICommandScheduler`, `SendEmailDeliveryCommand`, `IamStartup.processMessagingOnce`, `IamMessagingCommandFactory` (worker binding).

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
- [operations/messaging_worker_scaling.md](../operations/messaging_worker_scaling.md) — worker concurrency (P1) và replica shard playbook (P3)
