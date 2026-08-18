---
name: ddd-domain-modeling
description: Analyzes business requirements and produces Tactical DDD domain model artifacts for ERP modules — bounded contexts, aggregates, value objects, business rules, commands, queries, and domain events. Use when analyzing epics/user stories, writing or updating harness/01-domain-model.md, designing bounded context boundaries, or when the user mentions DDD analysis, domain modeling, or business rules discovery (not domain code implementation).
---

# DDD Domain Modeling

## Mục đích

Skill này hướng dẫn **phân tích nghiệp vụ** và **thiết kế domain model** theo Tactical DDD cho hệ thống ERP Modular Monolith (Flutter/Dart + Supabase).

```text
Domain quyết định hành vi nghiệp vụ hợp lệ.
Application điều phối use case.
Infrastructure triển khai kỹ thuật.
Presentation hiển thị cho người dùng.
```

**Tham chiếu chi tiết:** [reference.md](reference.md) · **Ví dụ:** [examples.md](examples.md) · Canonical doc: `docs/ddd_domain_modeling_skill.md` · **Implement code:** [domain-layer](../domain-layer/SKILL.md)

---

## Khi nào dùng

- Phân tích Epic / User Story / Business Rule mới
- Viết hoặc cập nhật `docs/themes/TH-xx/harness/01-domain-model.md`
- Thiết kế bounded context và ranh giới module
- Thiết kế aggregate, entity, value object, business rule (ở mức tài liệu)
- Đặt tên command/query theo **intent nghiệp vụ**
- Review domain model tránh God Aggregate

**Không** dùng khi implement Dart trong `modules/*/domain/` — dùng [domain-layer](../domain-layer/SKILL.md).

---

## Quy trình (7 bước)

### Bước 1 — Hiểu lifecycle nghiệp vụ

Trước khi đặt tên class, trả lời:

```text
- Transaction lifecycle là gì? (draft → confirm → fulfill → complete?)
- Ai sở hữu dữ liệu gốc? (Sales không sở hữu Product/Customer/Stock)
- Điểm commit nghiệp vụ ở đâu? (checkout, payment confirm, return complete)
- Trạng thái nào độc lập? (fulfillment ≠ payment)
- Rule nào là invariant của aggregate vs rule cần snapshot ngoài?
```

**Output:** mô tả lifecycle + danh sách capability (không phải màn hình).

### Bước 2 — Chia Bounded Context

Tách theo **capability sở hữu**, không theo UI:

| Câu hỏi | Nếu "có" → context riêng |
|---------|--------------------------|
| Có master data riêng lifecycle? | Catalog, Customers |
| Có side-effect vật lý/tài chính? | Inventory, Payments, AR |
| Có transaction lifecycle riêng? | Sales, Returns |
| Chỉ cần đọc snapshot? | Giữ snapshot trong aggregate, không import module khác |

Mỗi context ghi rõ:

```text
- Trách nhiệm (owns)
- Không chịu trách nhiệm (does not own)
- Ubiquitous language (bảng thuật ngữ)
- Integration events publish/consume
```

### Bước 3 — Xác định Aggregate

**Một aggregate = một cluster consistency boundary.**

Quy tắc chọn aggregate root:

```text
✓ Cùng lifecycle commit
✓ Cùng invariant cần enforce atomic
✓ Thay đổi cùng lúc trong một use case

✗ Gom cart + payment + inventory + return vào một Order
✗ List con vô hạn (returns[], payments[], history[])
✗ Reference trực tiếp aggregate của module khác
```

**Tách aggregate khi:**

- Draft ≠ Order chính thức (ví dụ: `SalesOrderDraft` vs `SalesOrder`)
- Return/Exchange có tính toán settlement riêng (`ReturnExchangeRequest`)
- Payment status và fulfillment status độc lập

Mỗi aggregate document:

```text
Aggregate Root:
  - Entity con
  - Value Objects
  - Trạng thái (enum)
  - Repository interface
  - Invariants chính
```

### Bước 4 — Entity vs Value Object

| Entity | Value Object |
|--------|--------------|
| Có identity (`id`) | So sánh bằng giá trị |
| Lifecycle thay đổi | Immutable |
| `SalesOrderDraftLine` | `Money`, `Quantity`, `CustomerSnapshot` |
| `ReturnLine` | `LineDiscount`, `OrderTotals` |

**Snapshot pattern** (bắt buộc cho cross-context):

```text
Sales giữ CustomerSnapshot, ProductSnapshot — không giữ Customer/Product entity.
Application layer load snapshot từ module khác trước khi gọi aggregate.
Aggregate kiểm tra rule dựa trên snapshot (sellability, stock), không query trực tiếp.
```

**Money:** dùng `Money` từ `vet45_shared_domain` — integer minor units, không dùng `double`.

### Bước 5 — Business Rules

Mỗi rule = một class `implements IBusinessRule`:

```dart
class DraftLineQuantityCannotExceedAvailableStockRule implements IBusinessRule {
  const DraftLineQuantityCannotExceedAvailableStockRule({...});
  @override
  bool isBroken() => ...;
  @override
  String get message => '...';
}
```

Phân loại:

| Loại | Vị trí |
|------|--------|
| Invariant aggregate | `rules/` trong aggregate folder; gọi trong method aggregate |
| Cần dữ liệu ngoài | Application load snapshot → truyền vào aggregate |
| Policy cross-cutting | Domain service (`PaymentStatusPolicy`, `SalesOrderEditPolicy`) |
| Orchestration | Application service — **không** đặt trong aggregate |

### Bước 6 — Commands (mutation intent)

**Đặt tên theo intent, không CRUD:**

```text
✓ StartSalesOrderDraftCommand
✓ AddProductToDraftCommand
✓ CheckoutSalesOrderCommand
✓ CompleteReturnExchangeRequestCommand

✗ UpdateCartItemCommand
✗ SaveDraftCommand
✗ UpdateOrderInfoCommand
```

Mỗi command map 1 aggregate root (hoặc orchestration rõ ràng draft → order).

**Idempotency (thiết kế, không implement RPC ở bước này):**

```text
Mutation có side effect tiền / kho / vòng đời đơn / onboarding?
  → đánh dấu cần idempotencyKey (ổn định qua retry) trong harness / commands table
  → tách biệt với business identity (order_number, SKU UNIQUE)
  → command.id = instance gửi đi; idempotencyKey = logical operation
  → doc: docs/architecture/13-idempotency-and-message-processing.md
```

**Permission codes (RBAC):** định nghĩa `static const` trong `{module}/domain/` (vd. `IamPermissions`, `PartnerPermissions`). Application dùng constant trong `@RequiresPermission` — không literal string. SQL seed comment tham chiếu tên constant.

Command structure (application layer):

```text
commands/<use_case>/
  <use_case>_command.dart       # id + params
  <use_case>_command_handler.dart
  <use_case>_command_validator.dart  # optional
```

Command handler flow:

```text
1. Load aggregate (repository)
2. Load snapshots/ports (application service)
3. Gọi method aggregate
4. Save aggregate
5. Publish domain events → map sang integration events (outbox)
```

### Bước 7 — Queries (read intent)

Query **không** thay đổi state; trả DTO/read model:

```text
✓ GetSalesOrderQuery
✓ GetRecentSalesOrdersQuery
✓ GetReturnableLinesQuery

Query handler → read gateway (infrastructure) → DTO
Không trả aggregate ra presentation.
```

---

## Cấu trúc thư mục domain (project convention)

Khi document aggregate trong `01-domain-model.md`, ghi folder target theo convention:

```text
modules/<module>/domain/lib/src/<aggregate_name>/
  <aggregate>.dart, rules/, events/, policies/, services/
```

Chi tiết implement (templates, một file / rule, tests): [domain-layer](../domain-layer/SKILL.md) · [reference.md](../domain-layer/reference.md).

Base types: `vet45_shared_domain` — `Entity`, `ValueObject`, `IBusinessRule`, `DomainEventBase`, `IAggregateRoot`.

---

## Output bắt buộc khi dùng skill

Khi phân tích/thiết kế, agent phải xuất:

```text
1.  Tóm tắt nghiệp vụ & lifecycle
2.  Bounded context map (owns / not owns / language)
3.  Danh sách aggregate (root, entities, VOs, states)
4.  Business rules table (rule class → áp dụng ở method nào)
5.  Commands table (command → aggregate → mục đích)
6.  Queries table (query → DTO → nguồn đọc)
7.  Domain events (khi nào phát)
8.  Integration events (publish/consume)
9.  Domain services (nếu có)
10. Snapshot/ports cần application load
11. Anti-pattern warnings
12. Review checklist (đã pass chưa)
```

**Implement Dart** → [domain-layer](../domain-layer/SKILL.md) (đọc `01-domain-model.md` + `02-module-map.md`).

---

## Anti-patterns (từ chối)

```text
- God Aggregate (Order quản lý mọi thứ)
- CRUD command thay intent nghiệp vụ
- Một enum OrderStatus gộp payment + fulfillment
- Aggregate query Inventory/Customers trực tiếp
- Business rule trong repository/infrastructure/UI
- double cho tiền tệ
- Domain import Flutter/Supabase
- Domain event publish trực tiếp sang module khác (dùng integration event)
- Return/Exchange nhét vào SalesOrder như list con lớn
```

---

## Review checklist

```text
[ ] Mỗi aggregate có boundary consistency rõ
[ ] Domain package dùng lib/domain.dart + lib/src/ (không flat lib/)
[ ] Không God Aggregate
[ ] Draft và committed entity tách khi lifecycle khác
[ ] Trạng thái độc lập được tách enum
[ ] Cross-module data = snapshot, không entity reference
[ ] Rule có class riêng, một file / rule trong `rules/`
[ ] Domain event có class riêng, một file / event trong `events/`
[ ] VO, policy, service của aggregate nằm trong thư mục aggregate đó
[ ] Command đặt tên theo intent
[ ] Query trả DTO, không leak aggregate
[ ] Domain event cho in-module; integration event cho cross-module
[ ] Idempotency key cho complete/checkout/payment/cancel/stock (tách với business UNIQUE)
[ ] Domain layer không phụ thuộc infrastructure/UI
[ ] Money dùng integer minor units
```

---

## Tài liệu thêm

- Chi tiết pattern & decision tree: [reference.md](reference.md)
- Ví dụ Sales module: [examples.md](examples.md)
- Implement domain code: [domain-layer](../domain-layer/SKILL.md)
- Idempotency: `docs/architecture/13-idempotency-and-message-processing.md`
- Template module: `docs/MODULES_IMPLEMENTATION_TEMPLATE.md`
- Harness progress: `docs/harness/PROGRESS.md`
