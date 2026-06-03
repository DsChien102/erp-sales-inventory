# DDD Domain Modeling — Examples

Canonical example trong repo: **`docs/SALES_MODULES.md`** và `modules/sales/domain/`.

---

## Ví dụ 1 — Tránh God Aggregate

**Sai:**

```text
Order (một aggregate)
  - cart lines
  - customer
  - payment
  - inventory reservation
  - return list
  - invoice
  - edit history
```

**Đúng (Sales Theme 1):**

```text
SalesOrderDraft     → lập đơn tạm, chiết khấu, tính tiền
SalesOrder          → đơn chính thức sau checkout
ReturnExchangeRequest → đổi/trả, settlement riêng

Payments            → module riêng, sở hữu giao dịch thanh toán
Inventory           → module riêng, sở hữu tồn kho
Customers/Catalog   → snapshot cho Sales
```

---

## Ví dụ 2 — Tách trạng thái độc lập

**Sai:**

```dart
enum OrderStatus { paid, unpaid, delivered, cancelled }
```

**Đúng:**

```dart
enum FulfillmentStatus {
  pendingConfirmation, delivering, delivered, completed, cancelled,
}
enum PaymentStatus { unpaid, partiallyPaid, paid, refunded }
```

Một đơn có thể `delivered` + `unpaid` (bán ghi nợ).

---

## Ví dụ 3 — Command intent vs CRUD

| CRUD (tránh) | Intent (dùng) |
|--------------|---------------|
| `UpdateCartItem` | `AddProductToDraftCommand` / `ChangeDraftLineQuantityCommand` |
| `SaveDraft` | `StartSalesOrderDraftCommand` (auto-save là infrastructure concern) |
| `UpdateOrder` | `EditSalesOrderCommand` / `CancelSalesOrderCommand` |
| `CreateReturn` | `StartReturnExchangeRequestCommand` |

---

## Ví dụ 4 — Snapshot flow (AddProduct)

```text
AddProductToDraftCommand
  → Application: ProductLookupService.getSnapshot(productId)
  → Application: InventoryAvailabilityChecker.getSnapshot(productId)
  → SalesOrderDraft.addProduct(product, sellability, stock)
       → OnlySellableProductCanBeAddedRule
       → ProductWithZeroAvailableStockCannotBeAddedRule
       → SameProductMustMergeIntoExistingLineRule (merge line)
  → Repository.save(draft)
  → DraftProductAddedDomainEvent
```

---

## Ví dụ 5 — Checkout orchestration

```text
CheckoutSalesOrderCommand
  → ValidateDraftForCheckoutCommand (hoặc inline validate)
  → Application reload price/stock snapshots
  → SalesOrder.checkoutFromDraft(draft, amountPaid, fulfillmentStatus, ...)
       → WalkInCustomerMustPayFullyRule
       → ProfileCustomerCanBuyOnCreditOnlyIfTenantAllowsRule
  → draft.markCheckedOut()
  → SalesOrderCheckedOutDomainEvent
  → Outbox: SalesOrderCheckedOutIntegrationEvent
       → Inventory, Payments, AR consume
```

---

## Ví dụ 6 — Business rules (SalesOrderDraft)

| Rule | Method |
|------|--------|
| `DraftMustStartWithWalkInCustomerIfNoCustomerSelectedRule` | `start()` |
| `OnlySellableProductCanBeAddedRule` | `addProduct()` |
| `DraftLineQuantityCannotExceedAvailableStockRule` | `addProduct()`, `changeQuantity()` |
| `LineDiscountAmountCannotExceedUnitPriceRule` | `applyDiscount()` |
| `DraftMustHaveAtLeastOneValidLineForCheckoutRule` | `validateForCheckout()` |

File layout (convention mục tiêu):

```text
modules/sales/domain/lib/
  domain.dart
  src/
    sales_order_drafts/
      sales_order_draft.dart
      sales_order_draft_line.dart
      rules/
        only_sellable_product_can_be_added_rule.dart
        ...
      events/
        draft_product_added_domain_event.dart
        ...
```

---

## Ví dụ 7 — Return/Exchange aggregate

```text
StartReturnExchangeRequestCommand
  → Load SalesOrder (completed/delivered)
  → ReturnExchangeRequest.start(sourceOrder, originalOrderSnapshot)
       → OnlyCompletedSalesOrderCanBeReturnedRule
       → CancelledOrDraftOrderCannotBeReturnedRule

AddReturnLineCommand
  → ReturnLineMustBelongToOriginalOrderRule
  → ReturnQuantityCannotExceedReturnableQuantityRule

CompleteReturnExchangeRequestCommand (idempotencyKey bắt buộc)
  → ReturnExchangeCompletionMustBeIdempotentRule
  → RefundAmountCannotExceedReturnDifferenceRule
```

---

## Ví dụ 8 — Domain service (tính tiền)

```dart
class LineAmountCalculator {
  LineAmount calculate({
    required Money unitPrice,
    required Quantity quantity,
    required LineDiscount discount,
  }) { /* integer math, no double */ }
}

class OrderTotalsCalculator {
  OrderTotals calculate({
    required Iterable<LineAmount> lineAmounts,
    required int totalQuantity,
    TaxBreakdown? taxBreakdown,
  }) { ... }
}
```

UI có thể preview — backend/domain là source of truth cho tiền.

---

## Ví dụ 9 — Query vs Command

**Command (mutation):**

```dart
final class CancelSalesOrderCommand extends Command<void> {
  const CancelSalesOrderCommand({
    required super.id,
    required this.orderId,
    required this.tenantId,
  });
  final String orderId;
  final String tenantId;
}
```

**Query (read):**

```dart
final class GetSalesOrderDetailsQuery extends Query<SalesOrderDetailsDto?> {
  const GetSalesOrderDetailsQuery({
    required this.tenantId,
    required this.orderId,
  });
  final String tenantId;
  final String orderId;
}
```

Handler query → `ISalesOrderReadGateway` → view `sales.v_order_details`.

---

## Ví dụ 10 — Khi nào tách module mới

Từ phân tích Theme 1:

| Signal | Action |
|--------|--------|
| Return/exchange phình to, nhiều rule settlement | Tách `SalesReturns` bounded context |
| Notification phức tạp | `Communication` consume event |
| Công nợ nhiều rule | `AccountsReceivable` riêng |

Giai đoạn đầu có thể gom trong Sales nếu team nhỏ — document điểm tách tương lai.
