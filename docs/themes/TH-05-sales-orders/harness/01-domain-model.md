# TH-05 — Domain model

> Quyết định 2026-09-09: không hỗ trợ hủy riêng khoản thu/hoàn đã xác nhận. Bỏ API/method tạo void. SQL đã xoá `void_sales_payment` và giá trị `reversal`/`voided` (Sales refactor bảng 10, 2026-09-23).

Engineering truth dẫn xuất từ [canonical §2–§3](../Theme-5-sales-orders.md). Đây là target model cho `modules/sales/`, không phải mô tả code hiện hữu.

## 1. Nghiệp vụ và lifecycle

```text
SalesOrderWorkingState (runtime, không persist)
  ├─ bỏ phiên → không tạo business record
  ├─ save → SalesOrderDraft(active)
  └─ checkout → idempotency record → SalesOrder(completed)

SalesOrder
  ├─ SalesOrderSettlement → collection/refund/receivable requirement
  ├─ SalesReceipt + inquiry projections
  └─ Post-sale
       ├─ ~~OrderAdjustment~~ (superseded / out of scope)
       ├─ SalesOrderCancellation
       └─ ReturnExchangeOrder
```

Commit points:

1. Save/update draft chỉ commit draft aggregate.
2. Finalize checkout tạo `SalesOrder` + immutable commercial snapshot; cùng transaction tạo settlement + lifecycle outbox facts (không enqueue impact/command tại Sales).
3. Payment/refund append transaction trong settlement; không sửa payment gốc.
4. Cancellation/return-exchange tạo aggregate riêng; không ghi đè SalesOrderLine. (OrderAdjustment superseded.)

## 2. Bounded context map

| Context trong Sales | Type | Owns | Does not own | Ubiquitous language |
| --- | --- | --- | --- | --- |
| Sales Order Lifecycle | Core | draft, idempotent checkout, order, commercial snapshot, order/lock lifecycle | pricing, inventory, receivable, payment gateway | working state, draft, checkout, finalize, snapshot |
| Sales Settlement | Supporting | settlement, payment/refund transaction, outstanding, payment status | receivable ledger, bank reconciliation | collection, refund, outstanding |
| Post-sale Operations | Supporting | cancellation, return/exchange, return status | order snapshot, inventory/receivable/e-invoice ledger; ~~adjustment~~ superseded | precheck, blocker, returnable, valuation |
| Sales Order Inquiry & Documents | Read/supporting | receipt, distribution activity, sales read projections | authoritative order/settlement/post-sale state | list, detail, timeline, receipt |

V1 triển khai bốn context trong một module `sales`, nhưng consistency boundary và folder phải giữ riêng. Điểm tách module tương lai chỉ được cân nhắc khi settlement hoặc return/exchange có ownership/team/lifecycle độc lập đủ lớn.

## 3. Aggregate catalog

| Aggregate root | Entities / records | Value objects / snapshots | State chính | Target folder |
| --- | --- | --- | --- | --- |
| `SalesOrderDraft` | `SalesOrderDraftLine` | `PricingPreview`, `Money`, `Quantity`, customer/product references | active, converted, cancelled, expired. `expires_at` is not a status. Save/restore do not auto-expire. | `domain/lib/src/sales_order_draft/` |
| `SalesOrder` | `SalesOrderLine` | sales/customer/product/unit/pricing/tax snapshots, `MonetarySummary` | completed, cancelled; lock riêng | `domain/lib/src/sales_order/` |
| `SalesOrderSettlement` | `SalesPaymentTransaction` | `SettlementSummary`, `PaymentMethodSnapshot`, `PaymentAllocation` | unpaid, partiallyPaid, paid, partiallyRefunded, refunded | `domain/lib/src/sales_order_settlement/` |
| ~~`OrderAdjustment`~~ | — | — | **Superseded / out of scope** (EP-04 / S22 removed) | — |
| `SalesOrderCancellation` | — | precheck/required-impact/blocker snapshots | requested, validating, confirmed, processing, completed, blocked, failed | `domain/lib/src/sales_order_cancellation/` |
| `ReturnExchangeOrder` | `ReturnExchangeLine`, `ReturnExchangeValuation` | summary, condition, current product/unit/pricing snapshots | technical draft (recovery), confirmed, processing, completed, cancelled, blocked, failed | `domain/lib/src/return_exchange_order/` |
| `SalesReceipt` | `SalesReceiptActivity` | receipt snapshot/template/content hash/distribution context | generated, superseded, archived | `domain/lib/src/sales_receipt/` |

Không phải aggregate:

- `SalesOrderWorkingState`: runtime presentation/application model (order drafting và return/exchange Phase 1 session).
- Checkout request envelope: runtime state giữ key/payload cho retry; không có bảng attempt. `sales.idempotency_records` scope `finalize_sales_order` giữ kết quả phục hồi và metadata store/actor; không phải business aggregate.
- List/detail/timeline/payment/return/integration views: read models.
- Idempotency, impact, outbox, inbox: cross-cutting technical records.

Phase 1 note:

- ~~`OrderAdjustment`~~ **superseded** — không còn aggregate/CQRS/RPC trong deliver.
- Return/exchange **user capability** = session working state; technical draft nếu có chỉ recovery trong phiên, không phải danh sách phiếu nháp do user quản lý.

## 4. State dimensions

| Dimension | Owner | Không được gộp với |
| --- | --- | --- |
| Order lifecycle | `SalesOrder` | payment, return, delivery/integration |
| Lock | `SalesOrder` | lifecycle |
| Payment | `SalesOrderSettlement` | order lifecycle |
| Return | Post-sale projection từ confirmed/completed return | payment |
| Business integration | Impact/integration record | delivery transport |
| Delivery transport | Outbox/inbox command | business acceptance |

Cached status trên `sales_orders` chỉ là projection; source of truth vẫn thuộc aggregate/record owner.

## 5. Business rules

| Future rule class | Aggregate/method | Rule |
| --- | --- | --- |
| `DraftMustBeActiveForMutationRule` | Draft update/cancel/convert | terminal draft không được sửa |
| `DraftMustContainValidLineRule` | save/finalize | persisted draft/order cần line hợp lệ |
| `CheckoutMustBeIdempotentRule` | `SalesOrder.finalizeFromDraft` | một business request không tạo hai order |
| `CommercialSnapshotMustBalanceRule` | finalize | totals = lines − discount + tax + rounding |
| `CommercialSnapshotIsImmutableRule` | post-checkout mutation | không sửa product/quantity/price/tax gốc |
| `PaymentAmountMustBePositiveRule` | record/refund | amount > 0 |
| `WalkInCustomerCannotCreateReceivableRule` | settlement initialize/change | outstanding cần customer định danh |
| `RefundCannotExceedRefundableAmountRule` | refund | confirmed refund nằm trong policy |
| ~~`OrderNoteUpdateMustBeNoteOnlyRule`~~ | — | **superseded** (EP-04) |
| ~~`OrderNoteNoOpMustNotPersistRule`~~ | — | **superseded** (EP-04) |
| ~~`OrderNoteUpdateRequiresCompletedOrderRule`~~ | — | **superseded** (EP-04) |
| `CancellationMustPassPrecheckRule` | confirm cancellation | lifecycle/lock/payment/return/e-invoice/version/reason hợp lệ |
| `ReturnLineMustReferenceOriginalLineRule` | add/update return line | hàng trả thuộc order line nguồn |
| `ReturnQuantityCannotExceedReturnableRule` | confirm return | cumulative return không vượt remaining |
| `ReturnExchangeMustHaveReturnedItemRule` | confirm | ít nhất một returned item |
| `ReceiptMustUseCommittedSnapshotRule` | generate receipt | receipt sinh từ SalesOrder hợp lệ |

Rule cần dữ liệu ngoài: application load snapshot/decision qua port rồi truyền vào aggregate; aggregate không gọi module khác.

## 6. Command catalog

CQRS symbol thêm hậu tố `Command`.

| Command | Aggregate / owner | Purpose |
| --- | --- | --- |
| `SaveSalesOrderDraftCommand` | Draft | persist working state lần đầu |
| `UpdateSalesOrderDraftCommand` | Draft | update active draft với expected version |
| `CancelSalesOrderDraftCommand` / `ExpireSalesOrderDraftCommand` | Draft | terminal transition |
| `FinalizeSalesOrderCommand` | Checkout orchestration → Order | validate lại và commit order idempotent |
| `CancelSalesOrderCommand` | Order | internal transition từ cancellation |
| `LockSalesOrderCommand` / `UnlockSalesOrderCommand` | Order | control lock lifecycle |
| `InitializeSalesOrderSettlementCommand` | Settlement | tạo settlement authoritative |
| `RecordSalesPaymentCommand` | Settlement | append confirmed/pending collection |
| `RecordSalesRefundCommand` | Settlement | append refund |
| Receivable-owned collection qua `IReceivableImpactPort` / `ReconcileSalesSettlementCommand` | Settlement | sync/reconcile authoritative summary; Sales không sở hữu collection command |
| ~~`ApplyOrderAdjustmentCommand`~~ | — | **superseded** (EP-04 / S22) |
| `RequestSalesOrderCancellationCommand` / `ConfirmSalesOrderCancellationCommand` | Cancellation | precheck/confirm cancellation case |
| `StartReturnExchangeCommand` | ReturnExchange | mở flow / technical draft recovery-only nếu cần |
| `UpdateReturnExchangeCommand` | ReturnExchange | cập nhật technical draft trong phiên (không phải user “Lưu nháp”) |
| `ConfirmReturnExchangeCommand` / `CancelReturnExchangeCommand` / `CompleteReturnExchangeCommand` | ReturnExchange | confirm = business fact; cancel = bỏ phiên / technical draft |
| `GenerateSalesReceiptCommand` | Receipt | generate version from order snapshot |
| `RecordSalesReceiptPrintedCommand` / `RecordSalesReceiptSharedCommand` | Receipt | append distribution activity |
| `ArchiveSalesReceiptCommand` | Receipt | archive receipt version |

Handlers map một primary aggregate; multi-owner checkout/cancellation/return uses application orchestrator, lifecycle outbox facts, và owner ports cho synchronous precheck (không Sales-owned durable impact/command enqueue).

## 7. Query catalog

| Query / operation | Result DTO/read model | Source |
| --- | --- | --- |
| `GetSalesOrderDraftForRestoreQuery` | `SalesOrderDraftForRestoreDto` | draft read gateway |
| `PrecheckSalesOrderCheckoutQuery` | `CheckoutPrecheckDto` | live ports + draft/working payload |
| `GetCheckoutResultQuery(storeId, idempotencyKey)` | `CheckoutResultDto` | idempotency record scope `finalize_sales_order` |
| `GetSalesOrderQuery` | `SalesOrderDto` | authoritative order gateway |
| `GetSalesOrderSettlementQuery` | `SalesOrderSettlementDto` | settlement |
| `GetSalesOrderPaymentTransactionsQuery` | paged payment DTO | settlement transactions |
| `GetSalesOrderPaymentSummaryQuery` | `SalesOrderPaymentSummaryDto` | payment projection |
| ~~`PrecheckOrderAdjustmentQuery`~~ / ~~`GetOrderAdjustmentHistoryQuery`~~ | — | **superseded** (EP-04 / S22) |
| `PrecheckSalesOrderCancellationQuery` | `CancellationPrecheckDto` | order/settlement/post-sale + external policy |
| `GetReturnableOrderLinesQuery` / `PrecheckReturnExchangeQuery` | returnable/precheck DTO | committed snapshot + return records |
| `ListSalesOrdersQuery` / `SearchSalesOrdersQuery` | paged `SalesOrderListItemDto` | inquiry view |
| `GetSalesOrderDetailQuery` / `GetSalesOrderTimelineQuery` | detail/timeline DTO | inquiry views |
| `GetSalesOrderReturnSummaryQuery` | return summary DTO | post-sale projection |
| `GetSalesReceiptQuery` | receipt DTO | receipt |
| `GetSalesOrderOriginalReceiptQuery` | receipt document (as-sold, read-only) | tab «Đơn gốc»: dòng đơn gốc + tổng lúc bán + khoản thu checkout; không lưu, không activity |
| `GetOrderIntegrationStatusQuery` | integration status DTO | **stub** (`notRequired`) until TH-06/07/08 + thin projection slice |

Queries không trả aggregate và không được dùng làm authoritative input cho mutation.

## 8. Domain events

| Aggregate | Events |
| --- | --- |
| Draft | `SalesOrderDraftSaved`, `Updated`, `Cancelled`, `Expired`, `Converted` |
| Order | `SalesOrderFinalized`, `Cancelled`, `Locked`, `Unlocked` |
| Settlement | `Initialized`, `SalesPaymentRecorded`, `Voided`, `SalesRefundRecorded`, `SalesSettlementChanged`, `SalesReceivableRequired/Cleared`, `Reconciled` |
| Post-sale | cancellation requested/confirmed/blocked, return started/valued/confirmed/cancelled/completed (~~`OrderAdjustmentApplied`~~ superseded) |
| Receipt | `SalesReceiptGenerated`, `Printed`, `Shared`, `Archived` |

Domain event ở trong module; event không tự publish trực tiếp sang module khác.

## 9. Integration events and cross-module commands

**Platform rule:** outbox / `integration_events` = **past business facts only**. Agents must follow [.cursor/rules/vet45-integration-events.mdc](../../../.cursor/rules/vet45-integration-events.mdc) and [docs/architecture/07-integration-and-messaging.md](../../../architecture/07-integration-and-messaging.md).

**TH-05 current phase (option B — reactive):** Sales **chỉ** publish lifecycle facts trên outbox. Sales **không** sở hữu `*_impact_requests`, `integration_commands`, apply/retry/reconcile enqueue, hay authoritative integration outcome projection. TH-06/07/08 (và TH-08 e-invoice khi có) consume Sales facts và sở hữu ledger/work bên owner. Thin read projection cho EP-03/US-06 (`GetOrderIntegrationStatus`) = **future slice** sau khi owner modules tồn tại — hiện stub `notRequired`.

### 9.1 Business facts (outbox IE) — publish khi có consumer

Canonical names (`{snake}_{past}.v1`):

- `sales_order_finalized.v1`, `sales_order_cancelled.v1`, `sales_order_cancellation_confirmed.v1`
- `sales_payment_recorded.v1`, `sales_refund_recorded.v1`, `sales_settlement_changed.v1`
- ~~`order_adjustment_applied.v1`~~ — **superseded** (EP-04 / S22 out of scope)
- `return_exchange_confirmed.v1`, `return_exchange_completed.v1`
- `sales_receipt_generated.v1` chỉ khi có consumer nghiệp vụ
- `sales_reporting_cancellation_recorded.v1` — deprecated transitional producer. No in-repo consumer. Reporting should consume `sales_order_cancelled.v1`. Not a money or goods owner.

Checkout/cancellation/return mutations emit lifecycle facts trong cùng transaction business commit; **không** chờ owner acceptance.

### 9.2 Cross-module handoff — deferred (not Sales-owned in current phase)

Sales-owned durable handoff qua `integration_commands` + intent tables (`sales.inventory.apply_impact.v1`, `sales.receivable.apply_impact.v1`, retry/reconcile, …) là **Model B legacy / deferred** — không phải path triển khai hiện tại.

| Concern | Current TH-05 | Future (owner themes live) |
| --- | --- | --- |
| Inventory / receivable / e-invoice work | Owner consumes Sales **facts** | Owner module `IIntegrationEventNotificationHandler` → internal command → ledger |
| Integration status UI (US-06 / S20) | Stub `notRequired` | Thin projection từ owner outcome events / read APIs |
| Technical retry/reconcile (FR-05+) | **Not implemented** at Sales | Owner or platform ops surface — not Sales `integration_commands` |

**Do not** put apply/retry/reconcile imperatives on outbox as integration events.

**Cấn trừ công nợ qua nhiều đơn — deferred (Receivable).** Dùng tiền lẽ ra hoàn của đơn này để trả nợ đơn khác cùng khách là thu nợ (collection) của Receivable, không phải Sales. Sales chỉ tách trong phạm vi **một đơn**: `refund_amount_minor` (hoàn tối đa bằng số đã thu) + `receivable_reverse_amount_minor` (phần nợ của chính đơn được xoá). Công tắc «Cấn trừ công nợ hiện tại» trên màn quyết toán đổi/trả hiện **chỉ đổi số hiển thị**, không gửi lên server (2026-09-24); nối với server khi theme công nợ live — Sales chỉ phát fact khoản hoàn, Receivable quyết định cấn trừ hay chi tiền.

### 9.3 Legacy debt (do not copy)

Promoted Sales SQL có thể còn artifact Model B (`*_impact_requests`, `integration_commands`, `enqueue_impact_handoff`, request-shaped outbox như `sales.inventory_impact.requested.v1`) cho tới khi normalize migration được reconcile với option B. **New harness/code must follow facts-only reactive** — không thêm Sales-owned apply enqueue hay `*.requested` IE.

Reporting / other modules may consume Sales **facts**; downstream failure must not block the Sales transaction.

## 10. Domain/application services

| Service/port | Layer | Responsibility |
| --- | --- | --- |
| `OrderTotalsCalculator` | domain | integer-money totals/rounding |
| `SettlementSummaryCalculator` | domain | paid/refunded/outstanding/status |
| `ReturnExchangeValuationCalculator` | domain | return/exchange difference |
| `SalesOrderEditPolicy` | domain | Phase 1: note-only eligibility (completed, not cancelled; lock không chặn) |
| `ProductSnapshotProvider` | application port | product/unit/sellability |
| `CustomerSnapshotProvider` | application port | customer/credit input |
| `SalesPricingPort` | application port | preview/final/commit/reverse |
| `InventoryImpactPort` | application port | availability precheck (sync); durable impact deferred to owner via facts |
| `ReceivableImpactPort` | application port | eligibility precheck (sync); durable ledger deferred to owner via facts |
| `EInvoicePolicyPort` | application port | post-sale legal blocker |
| `CheckoutOrchestrator` | application | reload snapshot, validate, commit owners |

## 11. Snapshot policy

- Snapshot immutable: sales/store/actor, customer, buyer tax, product/unit, pricing/promotion, tax/rounding.
- Live reference chỉ dùng ở precheck/commit; không ghi đè lịch sử.
- Original return line dùng original order snapshot; exchange line dùng product/unit/pricing hiện hành.
- `Money` dùng integer minor units từ `vet45_shared_domain`.
- Mọi idempotent command mang key + payload hash + correlation/causation/source version.

## 12. Anti-patterns và review

Không được:

- God Aggregate chứa draft + payment + inventory + return + receipt.
- Một `OrderStatus` gộp lifecycle/payment/return/integration.
- Sales update trực tiếp Catalog/Partner/Pricing/Inventory/Accounting tables.
- Business rule trong UI/gateway/RPC-only.
- Query trả aggregate hoặc read model ghi ngược business entity.
- `double` cho tiền; direct Supabase write từ UI.
- Append payment/refund bằng cách sửa/xóa transaction gốc.

Review checklist:

- [x] Mỗi aggregate có consistency boundary riêng.
- [x] Draft, committed order, settlement và return lifecycle tách biệt.
- [x] Cross-module data dùng snapshot/port/event.
- [x] Command theo intent; query trả DTO.
- [x] Domain event và integration event tách biệt.
- [x] Idempotency bắt buộc cho checkout/payment/refund/cancellation/return.
- [x] Domain target không phụ thuộc Flutter/Supabase.
- [x] Money dùng integer minor units.
