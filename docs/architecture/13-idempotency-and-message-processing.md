# Idempotency và Message / Command Processing

> **Nguồn chân lý (source of truth)** cho idempotency, định danh message, và mối quan hệ với Outbox / Inbox / command processing trong Vet45.
>
> Agent rule (mandatory): [.cursor/rules/vet45-idempotency-and-commands.mdc](../../.cursor/rules/vet45-idempotency-and-commands.mdc)
>
> Liên quan: [07-integration-and-messaging.md](07-integration-and-messaging.md) · [09-application-commands.md](09-application-commands.md) · [integration_event_flow.md](../integration_event_flow.md)

## 1. Idempotency là gì?

Một operation được gọi là **idempotent** nếu thực hiện nhiều lần vẫn tạo ra **cùng một business effect** như thực hiện một lần.

> Cùng một logical operation có thể được gửi hoặc xử lý nhiều lần, nhưng business state chỉ thay đổi một lần.

Ví dụ POS checkout: client gửi lại `Checkout #CHECKOUT-001` do timeout. Không có idempotency → ba order (`SO-001`, `SO-002`, `SO-003`). Có idempotency → ba request vẫn map về một logical checkout → một `SalesOrder`.

**Idempotency xử lý duplicate execution, không phải duplicate delivery.** Duplicate delivery là bình thường trong distributed system / at-least-once messaging.

## 2. Vì sao cần Idempotency?

Đặc biệt quan trọng khi có: mạng không ổn định, retry, timeout, message queue, event bus, at-least-once delivery, offline-first, background worker, client gửi lại request, consumer xử lý lại message.

Kịch bản phổ biến: server đã `COMMIT` nhưng response mất → client retry. Nếu request thứ hai bị coi là operation mới → business effect bị nhân đôi.

## 3. Bốn loại ID quan trọng

| Khái niệm | Câu hỏi | Vai trò trong Vet45 |
| --------- | ------- | ------------------- |
| `messageId` / `command.id` | Đây là message / command instance nào? | Tracing, logging, audit, liên kết Outbox/Inbox row |
| `correlationId` | Thuộc workflow / business process nào? | Theo dõi chuỗi checkout → order → receivable |
| `causationId` | Message nào trực tiếp gây ra message này? | Chain causality giữa command / event / internal command |
| `idempotencyKey` | Có phải cùng một logical operation không? | Bảo vệ side effect nghiệp vụ khỏi thực hiện nhiều lần |

### Message identity ≠ Operation identity

```text
Request 1: messageId = MSG-001, idempotencyKey = CHECKOUT-001
Request 2: messageId = MSG-002, idempotencyKey = CHECKOUT-001
```

Hai message khác nhau, **một** logical operation. **Cấm** dùng `messageId` / `command.id` làm `idempotencyKey` khi client retry (mỗi lần gửi thường tạo `command.id` mới).

Golden Sales: `SalesMutationContract` tách `id` (command instance) và `idempotencyKey` / `correlationId` / `causationId` / `payloadHash`.

## 4. Bốn tầng bảo vệ

```text
┌───────────────────────────────────────┐
│ 1. Message Identity                   │
│    messageId / correlationId /        │
│    causationId                        │
└───────────────────┬───────────────────┘
                    │
┌───────────────────▼───────────────────┐
│ 2. Delivery Reliability               │
│    Outbox / Inbox                     │
└───────────────────┬───────────────────┘
                    │
┌───────────────────▼───────────────────┐
│ 3. Operation Idempotency              │
│    idempotencyKey / idempotency record│
└───────────────────┬───────────────────┘
                    │
┌───────────────────▼───────────────────┐
│ 4. Business Correctness               │
│    UNIQUE / CHECK / transaction / lock│
└───────────────────────────────────────┘
```

Không có một cơ chế duy nhất giải quyết tất cả.

| Cơ chế | Giải quyết |
| ------ | ---------- |
| Outbox | Business state change và publication không lệch nhau (reliable publish) |
| Inbox | Message này đã được consumer xử lý chưa? (reliable consume / delivery dedup) |
| Idempotency | Logical operation này đã tạo business effect chưa? |
| DB constraints | Business identity / invariant có được phép trùng không? |

## 5. Idempotency Record và Scope

Khóa định danh operation trong multi-tenant:

```text
(tenant_id, scope, idempotency_key)
```

- `scope` (Vet45: `command_scope`) — ví dụ `finalize_sales_order`, `save_sales_order_draft`, `sales.checkout`
- Không dùng `idempotencyKey` global một mình: cùng chuỗi `CHECKOUT-001` có thể thuộc nhiều context / tenant khác nhau

Bản ghi điển hình:

```text
tenant_id, command_scope, idempotency_key, payload_hash,
status, result_type, result_id, result_snapshot,
correlation_id, created_at, completed_at
```

Reference Sales: bảng `sales.idempotency_records` + helpers `sales._begin_sales_idempotency` / `sales._complete_sales_idempotency`.

## 6. Database là lớp bảo vệ cuối cùng

**Cấm** chỉ dựa vào application check:

```text
SELECT ... IF NOT EXISTS → INSERT   -- race giữa hai request đồng thời
```

Bắt buộc:

1. Unique / primary key trên `(tenant_id, command_scope, idempotency_key)`
2. Khóa đồng thời trong transaction — Sales dùng `pg_advisory_xact_lock` + `SELECT ... FOR UPDATE`
3. So sánh `payload_hash`: cùng key + khác hash → `IDEMPOTENCY_CONFLICT`

## 7. Transaction atomicity

Idempotency record phải nằm **cùng transaction** với business state, domain/outbox events:

```text
BEGIN
  claim / begin idempotency (in_progress)
  validate + mutate business state
  insert outbox (lifecycle facts)
  complete idempotency (succeeded + result_snapshot)
COMMIT
```

**Cấm** đánh dấu `succeeded` / `COMPLETED` trước khi business commit. Nếu không:

```text
IdempotencyRecord = COMPLETED  nhưng  SalesOrder chưa tồn tại
→ retry bị từ chối dù business chưa tạo
```

Rollback transaction → rollback cả idempotency claim.

## 8. Pipeline và trạng thái quyết định

```text
Command
  → Validation / Authorization (pipeline)
  → Handler → Gateway → RPC
      → begin idempotency
          ├── replay      → trả result_snapshot
          ├── in_progress → chờ / CONCURRENT_MUTATION
          ├── conflict    → IDEMPOTENCY_CONFLICT
          └── new         → mutate + outbox + complete → COMMIT
```

Idempotency **không** thay thế business validation. Lần đầu vẫn phải kiểm tra rule nghiệp vụ.

Duplicate ≠ ignore:

| Trạng thái | Hành vi |
| ---------- | ------- |
| Completed + hash khớp | Replay kết quả cũ |
| In progress | Không chạy lại business logic như thao tác mới |
| Chưa có | Thực thi mới |
| Hash lệch | Conflict |

## 9. Inbox, Outbox, Internal command

### Inbox ≠ Idempotency

- Inbox: “Event / message delivery này đã consume chưa?” (thường theo `event.id`)
- Idempotency: “Logical operation đã có business effect chưa?”

Hai cơ chế có thể cùng tồn tại. Event-driven: at-least-once delivery + idempotent consumer.

### Outbox ≠ Idempotency

Outbox đảm bảo publish atomic với mutation. Không đảm bảo consumer chỉ xử lý một lần.

### Internal command / worker

Worker retry cũng cần idempotent. Pattern Vet45:

- Enqueue từ integration event: dedup `(tenant_id, source_event_id, command_type)`
- Có thể dùng `sourceEventId` làm operation identity **khi** semantics khớp “một event → một side effect”
- Không máy móc gán mọi operation = `event.id` — hỏi: logical operation nào chỉ được chạy một lần?

Chi tiết command types: [09-application-commands.md](09-application-commands.md). Fact vs command trên outbox: [07-integration-and-messaging.md](07-integration-and-messaging.md).

## 10. Offline-first và client retry

Client (POS / mobile) tạo logical id ổn định (ví dụ `checkoutId`) làm `idempotencyKey` trước khi gửi. Mỗi lần retry:

- `command.id` / `messageId` **mới**
- `idempotencyKey` **giữ nguyên**
- `payloadHash` phải khớp payload của lần đầu (nếu không → conflict)

Server replay `result_snapshot` → client nhận đúng kết quả dù response lần trước bị mất.

## 11. Business uniqueness ≠ Operation idempotency

| | Idempotency | Business uniqueness |
| - | ----------- | ------------------- |
| Câu hỏi | Request / operation này đã thực hiện chưa? | State nghiệp vụ này có được phép tồn tại hai lần không? |
| Ví dụ | `CHECKOUT-001`, `idempotencyKey` | `UNIQUE(order_number)`, `UNIQUE(sku)` |

Cả hai cần tồn tại. Constraint bảo vệ invariant; idempotency bảo vệ operation semantics.

## 12. Khi nào bắt buộc / khi nào không

**Thường bắt buộc** `idempotencyKey` (+ DB record) cho mutation có side effect quan trọng và có thể retry:

```text
Checkout / Finalize order, Record payment, Cancel order,
Reserve / adjust stock, Create receivable, Onboarding,
Complete return/exchange, Transfer money, Issue invoice
```

**Thường không cần** idempotency record cho query đọc thuần.

Không áp dụng máy móc cho mọi command — nhưng mutation tài chính / kho / vòng đời đơn hàng mặc định cần.

## 13. Implementation reference (Vet45)

| Thành phần | Vị trí |
| ---------- | ------ |
| Contract metadata | `SalesMutationContract` — `idempotencyKey`, `payloadHash`, `correlationId`, `causationId` |
| RPC helpers | `sales._begin_sales_idempotency`, `sales._complete_sales_idempotency` |
| Bảng | `sales.idempotency_records` |
| IAM onboarding | `iam.onboarding_operations` (key + result snapshot) |
| Internal enqueue dedup | `(tenant_id, source_event_id, command_type)` |

Quyết định RPC điển hình từ `_begin_*`: `new` | `replay` | `in_progress` (+ `IDEMPOTENCY_CONFLICT` khi hash lệch).

## 14. Checklist thiết kế

### Operation

- [ ] Logical operation là gì? Identity là gì? Có cần `idempotencyKey` không?

### Message / command metadata

- [ ] `command.id` / `messageId` tạo riêng mỗi lần gửi?
- [ ] `correlationId` / `causationId` propagate đúng?
- [ ] `idempotencyKey` ổn định qua retry?

### Persistence

- [ ] Idempotency record ở đâu? Unique `(tenant, scope, key)`?
- [ ] Có `payload_hash` và replay snapshot không?

### Transaction

- [ ] Idempotency + business state + outbox cùng transaction?
- [ ] Không mark completed trước commit?

### Messaging

- [ ] Accept at-least-once? Consumer có Inbox?
- [ ] Internal command dedup theo `sourceEventId` / scope riêng?

### Retry

- [ ] Client / worker retry trả replay hay in_progress?
- [ ] Timeout sau commit được xử lý an toàn?

### Business correctness

- [ ] UNIQUE / CHECK / locking / optimistic concurrency khi cần?

## 15. Nguyên tắc cốt lõi

1. Duplicate delivery là bình thường — đừng giả định “message chỉ đến một lần”.
2. `messageId` ≠ `idempotencyKey`.
3. Idempotency là property của **operation**, không phải của HTTP endpoint hay broker.
4. Database phải tham gia bảo vệ (constraint + lock).
5. Idempotency không thay Outbox / Inbox; mỗi cơ chế một việc.
6. Business invariant vẫn cần DB constraint + transaction + concurrency control.
7. Làm cho retry an toàn — không cố ngăn retry.
8. Offline-first đặc biệt cần `idempotencyKey` ổn định từ client.

## 16. Anti-patterns (từ chối)

- Dùng `messageId` / `command.id` làm idempotency key cho mọi retry
- Chỉ check duplicate bằng Dart (`if (!exists) create`)
- Chỉ có Idempotency mà thiếu Inbox khi consume event at-least-once (hoặc ngược lại: chỉ Inbox mà thiếu business uniqueness / operation identity khi cần)
- Lưu `idempotency_records` ngoài transaction với business mutation + outbox
- Đánh dấu completed trước khi business logic commit
- Nhầm `UNIQUE(order_number)` với đủ idempotency cho checkout
- Áp dụng idempotency record máy móc cho mọi query

## Liên kết

- Rule: [.cursor/rules/vet45-idempotency-and-commands.mdc](../../.cursor/rules/vet45-idempotency-and-commands.mdc)
- [07-integration-and-messaging.md](07-integration-and-messaging.md)
- [09-application-commands.md](09-application-commands.md)
- [integration_event_flow.md](../integration_event_flow.md)
- Application skill §16: [application_layer_skill.md](../application_layer_skill.md)
- Infrastructure skill §6–7: [infrastructure_layer_skill.md](../infrastructure_layer_skill.md)
