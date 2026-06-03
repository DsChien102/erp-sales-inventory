# DDD Domain Modeling — Reference

## 1. Strategic DDD trong ERP Modular Monolith

### Context mapping nhanh

```text
Partnership     — hai team cùng evolve contract (hiếm)
Customer-Supplier — module A cung cấp snapshot/event cho B
Conformist      — B chấp nhận model của A (Customers → Sales snapshot)
Anti-Corruption — adapter khi model ngoài quá khác (ít dùng nội bộ)
Shared Kernel   — vet45_shared_domain (Money, Entity, IBusinessRule)
```

### Ranh giới module

```text
Module A KHÔNG import implementation nội bộ Module B.
Giao tiếp: Integration Event + Outbox/Inbox + public contract.
Sales KHÔNG sở hữu: product, customer, stock, payment, receivable.
Sales SỞ HỮU: sales transaction + snapshot tại thời điểm giao dịch.
```

---

## 2. Decision Tree — Chọn Aggregate

```text
Có nhiều trạng thái commit khác nhau trong cùng flow?
  └─ Có → tách aggregate (Draft vs Order)

Thay đổi có cần atomic với entity con?
  └─ Có → gom trong cùng aggregate root

Có tính toán settlement/phụ lifecycle riêng?
  └─ Có → aggregate riêng (ReturnExchangeRequest)

Chỉ cần biết "đã xảy ra" không cần list con lớn?
  └─ Có → event/read model reference, không nhét list vào aggregate

Cần dữ liệu module khác?
  └─ Snapshot qua application layer, không reference entity
```

---

## 3. Entity vs Value Object — Checklist

**Chọn Entity khi:**
- Cần track theo `id` qua nhiều thao tác
- Cùng aggregate, thay đổi theo lifecycle cha
- Ví dụ: `SalesOrderDraftLine`, `ReturnLine`, `ExchangeLine`

**Chọn Value Object khi:**
- Định nghĩa bằng attributes, không cần id
- Immutable, thay thế whole object khi đổi
- Ví dụ: `Money`, `Quantity`, `LineDiscount`, `CustomerSnapshot`

**Chọn Enum khi:**
- Tập trạng thái hữu hạn, closed set
- Ví dụ: `FulfillmentStatus`, `PaymentStatus`, `SalesOrderDraftStatus`

---

## 4. Snapshot Types (cross-context)

| Snapshot | Chứa | Nguồn module |
|----------|------|--------------|
| `CustomerSnapshot` | id, name, active, walk-in | Customers |
| `ProductSnapshot` | id, sku, name, unit, unitPrice | Catalog |
| `ProductSellabilitySnapshot` | active, sellable | Catalog |
| `AvailableStockSnapshot` | productId, qty, checkedAt | Inventory |
| `OriginalOrderSnapshot` | order + returnable lines | Sales (read model) |

Aggregate **chỉ validate** dựa snapshot — không gọi API module khác.

---

## 5. Business Rule Template

```dart
// rules/<name>_rule.dart
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class <Name>Rule implements IBusinessRule {
  const <Name>Rule(/* deps */);

  @override
  bool isBroken() => /* condition */;

  @override
  String get message => '<user-facing invariant message>';
}
```

Gọi trong aggregate:

```dart
checkRule(DraftMustBeOpenForMutationRule(status));
// hoặc extension:
DraftMustBeOpenForMutationRule(status).ensureValid();
```

---

## 6. Aggregate Method Pattern (immutable)

Prefer return new instance với domain events:

```dart
SalesOrderDraft addProduct({...}) {
  _ensureOpen();
  OnlySellableProductCanBeAddedRule(sellability).ensureValid();
  // ... compute new lines
  final updated = _copyWith(lines: newLines, totals: newTotals);
  updated.addDomainEvent(DraftProductAddedDomainEvent(...));
  return updated;
}
```

Factory cho creation:

```dart
factory SalesOrder.checkoutFromDraft({...}) {
  CheckoutRequiresValidDraftRule(draft.status).ensureValid();
  // ...
  order.addDomainEvent(SalesOrderCheckedOutDomainEvent(...));
  return order;
}
```

---

## 7. Command Design

### Naming convention

```text
<Verb><AggregateOrConcept>Command

Verbs: Start, Assign, Add, Remove, Change, Apply, Validate,
       Checkout, Confirm, Mark, Record, Cancel, Complete
```

### Command fields

```text
id              — command id / idempotency (Uuid v7)
tenantId        — khi cần (server validate lại)
aggregateId     — target
payload         — primitive / DTO, không domain object
```

### Command vs Internal Command

| | Command | Internal Command |
|---|---------|------------------|
| Trigger | User / app use case | Inbox handler / worker |
| Layer | Application | Application (async) |
| Scope | Public use case | Module-internal |

---

## 8. Query Design

### Naming convention

```text
Get<Thing>Query
Get<Thing>ListQuery / Search<Thing>Query
Get<Thing>SummaryQuery
```

### Query output

```text
- DTO trong application/queries/<name>/<name>_dto.dart
- Không trả Entity/Aggregate
- Read gateway query view Supabase (infrastructure)
```

---

## 9. Events

### Domain Event (in-module)

```text
- Past tense: SalesOrderCheckedOutDomainEvent
- Phát từ aggregate method
- Dùng cho audit, projection nội module, notification handler
- extends DomainEventBase (vet45_shared_domain)
- Một event / file: events/<event_name>_domain_event.dart
```

### Integration Event (cross-module)

```text
- Past tense module prefix: sales.order.created
- Map từ domain event qua notification handler + outbox
- Payload tối thiểu (ids, tenant, version)
- Không expose domain object nội bộ
```

---

## 10. Domain Services

Dùng khi logic:

```text
- Không thuộc một aggregate cụ thể
- Pure calculation/policy không cần state
- Ví dụ: OrderTotalsCalculator, LineAmountCalculator,
         ReturnExchangeCalculator, PaymentStatusPolicy
```

**Không** dùng domain service để orchestrate cross-module workflow — đó là application service.

---

## 11. Application Services (ports)

Application load dữ liệu trước khi gọi aggregate:

```text
ProductLookupService
CustomerLookupService
InventoryAvailabilityChecker
SalesTaxConfigurationProvider
SalesOrderDraftPricingService
CheckoutOrchestrator
ReturnExchangeSettlementPreviewService
```

---

## 12. Ubiquitous Language Template

```markdown
| Term (English) | Thuật ngữ | Meaning |
|----------------|-----------|---------|
| SalesOrderDraft | Đơn đang lập | Temporary order before checkout |
| Checkout | Thanh toán/chốt đơn | Commit draft to official SalesOrder |
| FulfillmentStatus | Trạng thái giao hàng | Independent from payment |
| Walk-in customer | Khách lẻ | Default anonymous customer |
```

---

## 13. Output Templates

### Aggregate spec table

```markdown
## Aggregate: SalesOrderDraft

| Component | Type |
|-----------|------|
| Root | SalesOrderDraft |
| Entities | SalesOrderDraftLine |
| Value Objects | CustomerSnapshot, ProductSnapshot, Money, Quantity, LineDiscount, OrderTotals |
| Status | Open, Invalid, ReadyForCheckout, CheckedOut, Abandoned |
| Repository | ISalesOrderDraftRepository |
```

### Commands table

```markdown
| Command | Aggregate | Purpose |
|---------|-----------|---------|
| StartSalesOrderDraftCommand | SalesOrderDraft | Open draft, default walk-in |
| AddProductToDraftCommand | SalesOrderDraft | Add/merge product line |
```

### Rules table

```markdown
| Rule | Applied at |
|------|------------|
| OnlySellableProductCanBeAddedRule | addProduct() |
| DraftLineQuantityCannotExceedAvailableStockRule | addProduct(), changeQuantity() |
```

---

## 14. Phân tích User Story — Prompt nội bộ

Khi nhận US/BR, agent tự hỏi:

```text
1. Actor là ai? Trigger gì?
2. Precondition (trạng thái hệ thống trước)?
3. Postcondition (commit gì)?
4. Invariant nào không được vi phạm?
5. Dữ liệu đọc từ module nào (snapshot)?
6. Side-effect module nào (event)?
7. Có idempotency không?
8. Có tách trạng thái độc lập không?
```

---

## 15. Review — Red Flags

```text
🔴 Một class > 500 dòng với mọi method CRUD
🔴 Repository có if/else nghiệp vụ
🔴 UI gọi trực tiếp Supabase cho mutation quan trọng
🔴 float/double cho tiền
🟡 Quá nhiều domain event cho thao tác draft nhỏ (chấp nhận nếu cần audit POS)
🟡 Hai aggregate cùng sửa trong một command (cần orchestrator rõ)
```
