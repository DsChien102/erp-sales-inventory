# Application commands và Internal commands

Tài liệu này mô tả hai loại command trong Vet45 — cùng là CQRS command, nhưng **mục tiêu, trigger, lifecycle và cách xử lý lỗi khác nhau**.

```text
Command thông thường (business command) = use case được gọi từ bên ngoài module (UI, facade).
Internal command                     = công việc nội bộ module, lưu durable và xử lý sau.
```

Nguồn tham chiếu implementation:

| Thành phần | Package / vị trí |
| ---------- | ---------------- |
| `ICommand`, `CommandBase` | `vet45_shared_application` |
| `InternalCommandBase`, `ISerializableInternalCommand` | Application module + `vet45_adapters` |
| `CommandBus`, `DefaultCommandPipeline` | `vet45_shared_infrastructure` |
| Serialize / deserialize | `vet45_adapters` (`InternalCommandSerializer`, `InternalCommandMapper`) |
| Handler & registry codegen | `vet45_generator` |
| Bảng Postgres | `{module}.internal_commands` |
| Processor | `apps/messaging_worker`, `{Module}Startup.processInternalCommandsOnce` |

---

## 1. Command thông thường (business command)

**Business command** đại diện cho **ý định nghiệp vụ trực tiếp** từ người dùng hoặc app shell.

Ví dụ trong Vet45:

```text
CreateProductCommand
CreatePartnerCommand
StartSalesOrderDraftCommand
CheckoutSalesOrderCommand
ReceivePaymentCommand
AdjustStockCommand
InviteTenantMemberCommand          # thuộc iam, không có module tenant riêng
```

### Luồng xử lý

```text
Flutter UI (BLoC / Notifier)
  -> I{Module}Module.executeCommandAsync()   # IModuleMediator
    -> ScopedCommandExecutor (GetIt lifetime scope)
      -> CommandBus.execute()
        -> DefaultCommandPipeline (business)
          -> Logging
          -> Authorization / tenant guard   # khi có IAccessMetadataRegistry
          -> Validation                     # khi có ICommandValidator
          -> ICommandHandler.handle()
            -> Aggregate / domain logic
            -> ICommandGateway → Supabase RPC
            -> (outbox ghi trong cùng transaction RPC)
        -> return TResult cho UI
```

Pipeline mặc định: [`DefaultCommandPipeline`](../../packages/vet45_shared/infrastructure/lib/src/cqrs/default_command_pipeline.dart). Metadata truy cập có thể sinh từ `@RequiresPermission`, `@RequiresTenant` (`vet45_annotations` + `vet45_generator`).

### Contract

```dart
abstract interface class ICommand<TResult> {
  String get id;
}

abstract class CommandBase<TResult> implements ICommand<TResult> {
  @override
  final String id;

  CommandBase([String? id]) : id = id ?? const Uuid().v4();
}
```

Handler:

```dart
abstract interface class ICommandHandler<TCommand extends ICommand<TResult>, TResult> {
  Future<TResult> handle(TCommand command);
}
```

### Mục tiêu

Business command trả lời:

```text
Người dùng / app shell đang muốn hệ thống làm gì ngay bây giờ?
```

Đây là **use case chính** — nếu fail, request nên fail và UI nhận lỗi.

### Logic handler điển hình

```text
1. Validate input (validator hoặc aggregate).
2. Check permission / tenant (pipeline decorator).
3. Load aggregate hoặc snapshot qua port.
4. Gọi method nghiệp vụ trên aggregate — invariant nằm ở domain.
5. Persist qua ICommandGateway → RPC (defense in depth: RLS, permission DB).
6. Domain event → integration event (outbox trong cùng transaction RPC).
7. Return kết quả (Id, summary DTO — không trả aggregate).
```

Ví dụ:

```text
CheckoutSalesOrderCommand
  -> check sales.order.checkout
  -> load SalesOrderDraft + snapshots (product, customer, stock)
  -> SalesOrder.checkoutFromDraft()
  -> sales.checkout_order RPC
  -> outbox: sales.order.checked_out
  -> return orderId
```

---

## 2. Internal command

**Internal command** là command **nội bộ module** — module tự enqueue để xử lý việc **không cần hoàn thành trong request hiện tại**.

Ví dụ:

```text
CreateInventoryReservationAfterCheckoutCommand
CreateReceivableAfterSalesOrderCheckedOutCommand
SendOrderReceiptEmailCommand
RebuildProductSearchProjectionCommand
GrantLoyaltyPointsForOrderCommand
ProcessOutboxCommand
ProcessInboxCommand
ProcessInternalCommandsCommand
```

### Contract

Internal command vẫn implement `ICommand<void>`, thêm khả năng serialize để lưu Postgres:

```dart
abstract class InternalCommandBase<TResult> implements ICommand<TResult> {
  @override
  final String id;

  InternalCommandBase([String? id]) : id = id ?? const Uuid().v7();
}

abstract interface class ISerializableInternalCommand {
  String get commandType;   // ví dụ: inventory.create_reservation_after_checkout
  String get tenantId;
  Map<String, dynamic> toJson();
}
```

- `command_type` và row `id` lưu ở **cột DB** — không nằm trong payload JSON.
- Dùng `json_serializable` trong application package; deserialize qua `normalizeInternalCommandDeserializeJson` (`vet45_adapters`).

Handler trả `Future<void>`. Đăng ký trên `CommandBus` qua pipeline **internal** (generated `{Module}CommandPipeline.buildInternalPipeline`) — thường **không** chạy auth decorator vì trigger từ worker/inbox, không từ user trực tiếp.

### Bảng durable

Mỗi module có schema Postgres riêng:

```text
{module}.internal_commands
  id
  command_type
  payload          -- JSON từ toJson(), không chứa row id
  enqueued_at
  processed_at
  failed_at
  error
  retry_count
```

Idempotency khi enqueue từ integration event: dedup theo `(tenant_id, source_event_id, command_type)` (payload mang `source_event_id` nếu cần).

---

## 3. Luồng Internal command

```text
Command handler / Integration event handler / domain notification handler
  -> I{Module}InternalCommandClient.enqueue(command)
    -> INSERT {module}.internal_commands (command_type, payload, ...)

Messaging worker (hoặc ERP scheduler khi dev)
  -> {Module}Startup.processInternalCommandsOnce()
    -> claim row chưa xử lý (processed_at IS NULL)
    -> InternalCommandSerializer.deserializeRow()
    -> CommandBus.execute(deserialized command)
      -> Internal command handler
    -> UPDATE processed_at hoặc ghi error + retry_count
```

Processor đọc theo `enqueued_at`, retry trước khi ghi lỗi cuối — tương tự outbox/inbox. Worker: [`MessagingWorkerLoop`](../../apps/messaging_worker/lib/messaging_worker_loop.dart) gọi `IMessagingModule.processMessagingOnce` (outbox, inbox, internal commands) trên từng module đã đăng ký.

Registry map `command_type` ↔ Dart class: codegen `vet45_generator|internal_registry` + `InternalCommandMapper`.

---

## 4. So sánh nhanh

| Tiêu chí | Business command | Internal command |
| -------- | ---------------- | ---------------- |
| Ai gọi? | UI, app shell, `I{Module}Module` | Module tự enqueue (handler, inbox handler, scheduler) |
| Mục tiêu | Use case chính | Side effect / background / eventual work |
| Thời điểm | Ngay trong request hiện tại | Sau đó, bởi worker |
| Lưu DB trước khi chạy? | Thường không (trừ idempotency key riêng) | Có — `{module}.internal_commands` |
| Trả kết quả cho UI? | Có (`TResult`) | Không (`void`) |
| Lỗi ảnh hưởng user? | Fail request, UI thấy lỗi | Ghi vào row; request gốc có thể đã thành công |
| Pipeline | `DefaultCommandPipeline` — logging, auth, validation | `{Module}CommandPipeline.buildInternalPipeline` — nhẹ hơn |
| Boundary | Public application command | Private / module-internal |
| Ví dụ | `CheckoutSalesOrderCommand` | `CreateReceivableAfterSalesOrderCheckedOutCommand` |

---

## 5. Tại sao cần Internal command?

Không phải việc gì cũng nên xử lý đồng bộ trong business command.

Khi checkout đơn hàng:

```text
CheckoutSalesOrderCommand
  -> tạo SalesOrder
  -> ghi RPC + outbox sales.order.checked_out
  -> return orderId
```

Sau đó hệ thống có thể cần (ở module khác hoặc cùng module):

```text
- trừ / reserve tồn kho (inventory)
- tạo công nợ (accounting)
- gửi email biên lai
- cập nhật projection / search index
```

Nếu nhét hết vào `CheckoutSalesOrderCommandHandler`:

- Handler phình to, khó test
- Request chậm
- Lỗi phụ (email, projection) có thể làm fail checkout — không mong muốn

Pattern đúng:

```text
CheckoutSalesOrderCommandHandler
  -> nghiệp vụ chính + outbox
  -> kết thúc request

Worker / module nhận
  -> inbox → integration event handler
  -> enqueue internal command
  -> processor xử lý state module nhận
```

---

## 6. Internal command vs Integration event

| | Integration event | Internal command |
| - | ----------------- | ---------------- |
| Ý nghĩa | Sự thật nghiệp vụ đã xảy ra — module khác có thể quan tâm | Module **này** cần tự làm một việc |
| Phạm vi | Liên module (contract trong `integration_events`) | Nội bộ một bounded context |
| Ví dụ | `SalesOrderCheckedOutIntegrationEvent` | `CreateReceivableAfterSalesOrderCheckedOutCommand` |
| Lưu trữ | `{module}.outbox_messages` / `{module}.inbox_messages` | `{module}.internal_commands` |

Luồng modular monolith Vet45:

```text
Aggregate
  -> Domain event
    -> RPC mutation (cùng transaction)
      -> outbox row

Outbox processor
  -> publish IntegrationEvent (IEventsBus / worker)
    -> inbox module đích

Inbox processor
  -> IIntegrationEventNotificationHandler
    -> enqueue InternalCommand (nếu cần đổi state)
      -> Internal command processor
        -> ICommandHandler (internal)
```

**Rule:** Integration event handler **không** chứa mutation phức tạp — delegate sang internal command hoặc business command của module nhận. Không gọi trực tiếp repository/use case nội bộ module khác.

Chi tiết messaging: [07-integration-and-messaging.md](07-integration-and-messaging.md).

---

## 7. Ví dụ end-to-end (Sales → Accounting)

### Business command (Sales)

```text
User bấm "Checkout"
  -> CheckoutSalesOrderCommand
    -> SalesOrderDraft.checkoutFromDraft()
    -> sales.checkout_order RPC
    -> outbox: sales.order.checked_out
    -> return orderId
```

### Internal command (Accounting, sau inbox)

```text
SalesOrderCheckedOutIntegrationEvent
  -> accounting inbox handler
    -> enqueue CreateReceivableAfterSalesOrderCheckedOutCommand
      -> accounting.internal_commands

Worker processInternalCommandsOnce
  -> handler tạo Receivable qua RPC
  -> mark processed_at
```

Gửi email / rebuild index tương tự — internal command, không block checkout.

---

## 8. Rule quyết định nhanh

### Dùng business command khi:

```text
- Hành động trực tiếp từ user / UI / app shell.
- User cần biết kết quả ngay.
- Đây là use case chính của bounded context.
- Nếu fail thì request nên fail.
```

### Dùng internal command khi:

```text
- Hệ thống tự làm sau event / sau command chính.
- Không cần user chờ.
- Cần durable + retry (app restart, worker delay).
- Side effect tách khỏi use case chính.
- Module nhận integration event và cần đổi state riêng.
```

### Đặt tên

Vẫn là **ý định nghiệp vụ**, không đặt tên quá kỹ thuật:

```text
✓ CreateReceivableAfterSalesOrderCheckedOutCommand
✓ SendOrderReceiptEmailCommand

✗ RunHandlerStep3Command
✗ ProcessRowCommand
```

---

## 9. Codegen và đăng ký handler

`vet45_generator` (opt-in, `build.yaml`):

| Builder | Output |
| ------- | ------ |
| `cqrs_registrar` | Đăng ký `ICommandHandler` business + internal lên `CommandBus` |
| `internal_registry` | Map `command_type` → `fromJson` factory |
| `access_metadata` | Permission/tenant cho business command |

Phân biệt business vs internal: handler có command class `extends InternalCommandBase` → đăng ký qua `registerInternalHandler`; còn lại → `registerBusinessHandler` với full pipeline.

Xem [codegen-migration.md](codegen-migration.md) và [shared-toolkit.md](shared-toolkit.md).

---

## 10. Câu chốt

```text
Business command  = use case chính, gọi từ ngoài module, chạy đồng bộ qua CommandBus + pipeline đầy đủ.

Internal command  = task nội bộ, enqueue vào {module}.internal_commands,
                    xử lý sau bởi messaging worker, tách side effect khỏi request chính.
```

Cả hai đều là command trong CQRS; ranh giới nằm ở **ai trigger**, **có cần durable defer hay không**, và **có trả kết quả cho caller bên ngoài hay không**.

---

## Liên kết

- [02-architecture-style.md](02-architecture-style.md) — CQRS, RPC-first
- [05-layered-module-structure.md](05-layered-module-structure.md) — handler pattern theo layer
- [07-integration-and-messaging.md](07-integration-and-messaging.md) — outbox, inbox, worker
- [application_layer_skill.md](../application_layer_skill.md) — §5 Command, §11 Internal commands
- [infrastructure_layer_skill.md](../infrastructure_layer_skill.md) — §6 Mutation vs query, §7 Messaging
- [MODULES_IMPLEMENTATION_TEMPLATE.md](../MODULES_IMPLEMENTATION_TEMPLATE.md) — §6.3, §11, §17
