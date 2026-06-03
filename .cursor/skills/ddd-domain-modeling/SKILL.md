---
name: ddd-domain-modeling
description: Analyzes business requirements and designs Tactical DDD models for modular monolith ERP modules — bounded contexts, aggregates, entities, value objects, business rules, commands, queries, and domain events. Use when analyzing epics/user stories, designing a new module domain layer, refactoring God aggregates, naming use cases, or when the user mentions DDD, bounded context, aggregate, value object, domain modeling, or business rules.
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

**Tham chiếu chi tiết:** [reference.md](reference.md) · **Ví dụ thực tế:** [examples.md](examples.md) · Mẫu module: `docs/SALES_MODULES.md`

---

## Khi nào dùng

- Phân tích Epic / User Story / Business Rule mới
- Thiết kế bounded context và ranh giới module
- Thiết kế aggregate, entity, value object, business rule
- Đặt tên command/query theo **intent nghiệp vụ**
- Review domain model tránh God Aggregate
- Chuẩn bị implement `modules/<module>/domain/`

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

**Quy tắc `lib/src/`:** mỗi aggregate là một thư mục; value object, policy, service thuộc aggregate nằm **trong** thư mục đó; barrel `lib/domain.dart` export public API.

```text
modules/<module>/domain/
  pubspec.yaml
  lib/
    domain.dart                          # barrel export
    src/
      <aggregate_name>/
        <aggregate>.dart                 # aggregate root
        <entity>.dart                      # entity con (nếu có)
        <value_object>.dart                # VO thuộc aggregate
        <aggregate>_repository.dart
        <aggregate>_status.dart            # enum nếu cần
        policies/
          <policy_name>.dart               # policy thuộc aggregate
        services/
          <calculator|helper>.dart         # domain service thuộc aggregate
        events/
          <event_name>_domain_event.dart   # một event / file
        rules/
          <rule_name>_rule.dart            # một rule / file
      shared/                              # chỉ calculator/policy dùng chéo nhiều aggregate
        <cross_aggregate_calculator>.dart
```

**Không** gom nhiều rule vào một file (`product_rules.dart`). Mỗi class `implements IBusinessRule` = một file trong `rules/`.

**Không** gom nhiều event vào một file (`product_domain_events.dart`). Mỗi class extends `DomainEventBase` = một file trong `events/` (`<event_name>_domain_event.dart`).

**VO placement:** VO gắn với một aggregate → đặt cùng thư mục aggregate (ví dụ `ProductName` trong `products/`). Chỉ dùng `shared/` khi logic thực sự cross-aggregate (ví dụ `OrderTotalsCalculator` trong Sales).

Base types từ `vet45_shared_domain`:

```text
Entity<Id>          — aggregate root & entity con
ValueObject         — immutable, Equatable
IBusinessRule       — isBroken() + message
IAggregateRoot      — marker interface
IDomainEvent        — domain event contract
IRepository<T, Id>  — persistence contract
```

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
[ ] Idempotency key cho complete/checkout/payment
[ ] Domain layer không phụ thuộc infrastructure/UI
[ ] Money dùng integer minor units
```

---

## Tài liệu thêm

- Chi tiết pattern & decision tree: [reference.md](reference.md)
- Ví dụ Sales module: [examples.md](examples.md)
- Template module: `docs/MODULES_IMPLEMENTATION_TEMPLATE.md`
- Phân tích Sales Theme 1: `docs/SALES_MODULES.md`
