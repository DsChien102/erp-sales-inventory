# TH-05 — API contracts (FE ↔ BE)

> **Schema/RPC authority (2026-08-14 clean bootstrap):** all active drafts remain the continuous `001`–`015` sequence; Sales owns `005`–`015`. Manual prerequisite: user removes existing `sales` schema. Draft `005` refuses to run while `sales` exists, reinstalls platform messaging, and owns **all** Sales DDL (including former deferred support tables). Drafts `006`–`015` are RPC/helper owners only. Legacy Group B–I and intermediate `600_draft`/`601`–`604` generations remain removed. Status: **draft SQL + static/application/infrastructure tests complete**; live Supabase E2E remains **blocked/not run** (no promote / no agent schema drop).


Frozen catalog cho **34** slice (S01–S34) sau re-harness Theme-5 Phase 1. **Contract state:** `frozen`. S01 là runtime contract không có Sales CQRS. Application Dart contracts trong `modules/sales/application` đã sync Phase 1 (note-only + session discard).

## B5 — Phạm vi cập nhật 2026-09-09

- `sales.void_sales_payment(uuid,uuid,uuid,uuid,uuid,text,text,text,text,uuid)` bị loại bỏ bởi draft 025. Không có API/UI thay thế cho hủy riêng lần ghi nhận thu/hoàn. Các scenario/read enum `voided` bên dưới chỉ còn ý nghĩa tương thích dữ liệu lịch sử, không cấp quyền tạo void mới.
- Draft 026 giữ nguyên signature `record_sales_payment`/`record_sales_refund`. Thu mới trên đơn cancelled trả `ORDER_CANCELLED`; replay đã thành công giữ result cũ trước lifecycle/capacity gate.
- `record_sales_refund.p_related_transaction_id` vẫn optional. Có giá trị: nguồn phải là collection confirmed cùng tenant/settlement, chưa bị reversal; refund không vượt phần chưa hoàn của nguồn. Không có giá trị: giữ kiểm tra net collected của settlement, không suy phân bổ nguồn.
- Giới hạn nguồn và settlement cùng dùng lỗi `REFUND_EXCEEDS_COLLECTED`; nguồn không hợp lệ dùng `CONTEXT_INVALID`/`REFERENCE_UNAVAILABLE` như contract hiện hữu.
- SQL chưa apply/verify bởi agent. Người dùng chạy kịch bản B5 trong `sales-review-regression-matrix.md`.

## Global conventions

- CQRS symbols: mutation `*Command`, read/precheck `*Query`, outputs `*Dto`.
- RPC target: schema `sales.<snake_case>`; target đã implement trong BE lane vẫn là draft-only cho tới khi promoted/applied; `n/a` khi runtime-only hoặc provider-owned.
- Tenant/store/actor lấy từ `IExecutionContext`; server validate lại, client-supplied tenant không authoritative.
- Money là integer minor units + currency; quantity phân số là integer micros scale 6; timestamp UTC ISO-8601; ids UUID; version integer monotonic.
- Sensitive mutation carries commandId, idempotencyKey, payloadHash, correlationId, causationId, sourceVersion.
- Query list dùng stable sort + opaque cursor; DTO không leak aggregate.

## Frozen field catalog

Các section S01–S34 tham chiếu bảng này như field-level contract duy nhất. Dấu `?` nghĩa là nullable; `List<T>` là immutable; `DateTime` luôn UTC. Tenant/actor không phải wire input đáng tin cậy mà được bind từ `IExecutionContext`.

### Scalars, inputs và snapshots

| Type | Exact fields |
| --- | --- |
| `MoneyDto` | `amountMinor:int`; `currencyCode:String` |
| `QuantityDto` | `quantityMicros:int`; fixed scale `1_000_000`; không dùng `double` |
| `SalesOrderDraftLineInput` | `productId:String`; `productSku:String`; `productName:String`; `productUnitId:String`; `unitCode:String`; `unitName:String`; `quantity:QuantityDto`; `appliedUnitPrice:MoneyDto`; `lineTotal:MoneyDto`; `listUnitPrice:MoneyDto?`; `manualUnitPriceMinor:int?`; `manualDiscountMinor:int?`; `manualDiscountBasisPoints:int?`; `pricingSourceCode:String?`; `pricingWarningCodes:List<String>`; `pricingBlockingCodes:List<String>`; `note:String?`; `needsRevalidation:bool` — **no** floor price / available stock (live-only on restore) |
| `SalesOrderDraftLineDto` | same snapshot fields as line input plus `lineId:String` |
| `CheckoutLineInput` | `productId:String`; `productUnitId:String`; `quantity:QuantityDto`; `unitPrice:MoneyDto?`; `note:String?` |
| `PaymentIntentInput` | `method:SalesPaymentMethod`; `amount:MoneyDto`; `reference:String?` |
| `FinalizeSalesOrderCommand.orderNote` | `orderNote:String?` (nullable/empty after normalize = no original note); immutable checkout note on finalize |
| ~~`ApplyOrderNoteAdjustmentInput`~~ | **superseded** (EP-04 / S22) |
| `ReturnExchangeLineInput` | `kind:ReturnExchangeLineKind`; `productId:String`; `productUnitId:String`; `quantity:QuantityDto`; `originalSalesOrderLineId:String?` |
| `ActorSnapshotDto` | `actorId:String`; `displayName:String` |
| `CustomerSnapshotDto` | `customerId:String`; `displayName:String`; `phoneNumber:String?`; `taxCode:String?`; `existingDebtMinor:int` (draft persistence maps `0` — debt is not commercial draft truth) |
| `ProductSnapshotDto` | `productId:String`; `sku:String`; `displayName:String` |
| `ProductUnitSnapshotDto` | `productUnitId:String`; `unitCode:String`; `unitName:String` |
| `PricingSnapshotDto` | `unitPrice:MoneyDto`; `source:String`; `pricedAt:DateTime`; `sourceVersion:int?` |
| `StoreSnapshotDto` | `storeId:String`; `storeCode:String`; `displayName:String` |
| `SalesBlockerDto` | `code:String`; `message:String`; `field:String?` |
| `OpaqueCursorPageDto<T>` | `items:List<T>`; `hasMore:bool`; `nextCursor:String?` |

### Runtime và result DTOs

| Slice family | Exact public result schema |
| --- | --- |
| Working state | `SalesOrderWorkingStateDto(store, customer?, currencyCode, lines)`; `CustomerSelectionDto(customer?, isWalkIn)`; `DraftLinePreviewDto(product, unit, quantity, unitPrice, lineTotal)`; `PricingPreviewDto(lines, summary, blockers)` |
| Draft | `SalesOrderDraftDto(draftId, version, status, storeId, savedAt, savedByActorId, lines, total, customer?, orderNote?, pricingPreviewToken?, needsRevalidation)`; `SalesOrderDraftForRestoreDto(draft, savedAt, savedByActorId)` (`savedAt`/`savedByActorId` must equal `draft.*`); `PagedSalesOrderDraftListDto(page)` |
| Checkout | `CheckoutMonetarySummaryDto(subtotal, discountTotal, grandTotal)`; `PaymentIntentSummaryDto(method, amount, status)`; `ReceivableRequirementDto(isRequired, amount, customerId?)`; `CheckoutPrecheckDto(canFinalize, blockers, monetarySummary, receivableRequirement)`; `CheckoutResultDto(idempotencyKey, salesOrderId, salesOrderVersion, status)`; `CheckoutResultViewDto(checkout, order, payment, integration)` |
| Order | `SalesOrderDto(salesOrderId, orderNumber, version, lifecycleStatus, lockStatus, total)`; `SalesOrderLineDto(lineId, product, unit, quantity, unitPrice, lineTotal, note?)`; `SalesOrderDetailDto(order, store, customer?, lines)`; `PagedSalesOrderListDto(page)` |
| Settlement | `SalesOrderSettlementDto(settlementId, salesOrderId, version, status, outstanding)`; `SalesOrderPaymentSummaryDto(status, orderTotal, paidTotal, outstandingTotal, refundedTotal, netCollectedTotal, originalPayableTotal, adjustmentTotal, collectedCash, collectedBank, dueAt, originalOrder, returnSlips)` — `paidTotal` is gross collected; `outstandingTotal` is settlement outstanding; `originalOrder.paidCash/paidBank` is checkout collection only; `collectedCash/collectedBank` is all confirmed collections including extra, not refunds; `dueAt` is date-only from `payment_due_date` or null; `SalesPaymentTransactionDto(transactionId, method, amount, status, recordedAt, transactionType, direction, relatedTransactionId?, sourceContext, actorId, reasonCode?, reason?)`; `SalesPaymentTransactionsDto(page)` |
| Receipt/timeline | `SalesReceiptDto(receiptId, salesOrderId, version, status, generatedAt)`; `SalesOrderTimelineDto(salesOrderId, entries)`; entry `(eventId, eventType, occurredAt, sourceVersion, actor?)` — actor is the fact/source actor, null when evidence is missing, never the reader |
| Integration | `OrderIntegrationStatusDto(salesOrderId, inventory, receivable, eInvoice)` — **S20 deferred:** stub returns `notRequired` per target; ~~`IntegrationCommandStatusDto`~~ / ~~`ImpactRequestStatusDto`~~ withdrawn from active Sales contract (Model B deferred) |
| Post-sale entry | `AvailablePostSaleActionsDto(canCancel, canReturnExchange)` — ~~`canAdjust`~~ removed (EP-04 superseded) |
| ~~Adjustment (Phase 1 note-only)~~ | **superseded** — `OrderAdjustment*Dto` withdrawn with S22 |
| Cancellation | `CancellationReasonDto(reasonText)`; `CancellationPrecheckDto(allowed, sourceVersion, sourceSettlementVersion, blockers)`; `SalesOrderCancellationResultDto(cancellationId, salesOrderId, salesOrderVersion, status)`; `CancellationImpactStatusDto(cancellationId, integration)`; `SalesOrderCancellationDetailDto(result, reason, cancelledAt)` |
| Return/exchange | `ReturnableOrderLineDto(salesOrderLineId, product, unit, soldQuantity, returnableQuantity, originalUnitPrice)`; `ReturnableOrderLinesDto(salesOrderId, sourceVersion, lines)`; `ReturnExchangePrecheckDto(allowed, sourceVersion, blockers)`; `ReturnExchangeDraftDto(returnExchangeId, salesOrderId, version, status, lines)` (technical recovery; không user draft list Phase 1); `ReturnExchangeValuationDto(returnValue, exchangeValue, settlementDifference, sourceOrderVersion, pricingSourceVersion?)`; `ReturnExchangeSettlementResultDto(returnExchangeId, difference, status)`; `ReturnExchangeResultDto(returnExchangeId, salesOrderId, version, status)`; `SalesOrderReturnSummaryDto(salesOrderId, returns)` |

### Frozen enums

| Enum | Values |
| --- | --- |
| `SalesDraftStatus` | `active`, `converted`, `cancelled`, `expired` |
| `CheckoutResultStatus` | `processing`, `succeeded`, `blocked`, `failed`, `uncertain` |
| `SalesOrderLifecycleStatus` | `completed`, `cancelled` |
| `SalesOrderLockStatus` | `unlocked`, `locked` |
| `SalesSettlementStatus` | `unpaid`, `partiallyPaid`, `paid`, `partiallyRefunded`, `refunded` |
| `SalesPaymentStatus` | `pending`, `confirmed`, `failed`, `voided` |
| `SalesPaymentMethod` | `cash`, `manualBankTransfer` |
| ~~`OrderAdjustmentStatus`~~ | **superseded** (EP-04 / S22) |
| ~~`OrderAdjustmentType`~~ | **superseded** (EP-04 / S22) |
| `SalesOrderCancellationStatus` | `requested`, `validating`, `confirmed`, `processing`, `completed`, `blocked`, `failed`, `cancelled` |
| `ReturnExchangeStatus` | `draft` (technical recovery only), `confirmed`, `processing`, `completed`, `cancelled`, `blocked`, `failed` |
| `SalesReceiptStatus` | `generated`, `superseded`, `archived` |
| `IntegrationDeliveryStatus` | `notRequired`, `queued`, `delivered`, `retryScheduled`, `failed`, `deadLetter`, `unknown` |
| `BusinessIntegrationStatus` | `notRequired`, `pending`, `accepted`, `rejected`, `reconciliationRequired`, `reconciled` |
| `SalesImpactKind` | `inventory`, `receivable`, `eInvoice` |
| ~~`SalesAdjustmentField`~~ | **removed Phase 1** — note-only; không whitelist multi-field |
| `ReturnExchangeLineKind` | `returnLine`, `exchangeLine` |

### Command/query and RPC mapping

| Public field | RPC parameter | Rule |
| --- | --- | --- |
| `id` | `command_id` / `query_id` | command UUID v4; query UUID v7 |
| `tenantId` | `tenant_id` | server-bound from execution context |
| `actorId` | `actor_id` | server-bound from execution context |
| `idempotencyKey` | `idempotency_key` | required on mutation |
| `payloadHash` | `payload_hash` | required on sensitive mutation |
| `correlationId` | `correlation_id` | required on sensitive mutation/recovery |
| `causationId` | `causation_id` | nullable only when there is no upstream cause |
| `expectedSourceVersion` | `expected_source_version` | optimistic concurrency for source-bound mutation |
| `cursor` | `cursor` | opaque; client must not parse |
| `pageSize` | `page_size` | positive bounded integer |

All RPC names below are **contract-only / unimplemented**. They are neither SQL drafts nor applied migrations.

## Error envelope

| Field | Semantics |
| --- | --- |
| `code` | stable uppercase error code |
| `message` | user-safe message; không dùng làm branching key |
| `fieldErrors` | optional field → stable code map |
| `blockers` | optional business blocker list + source/version |
| `correlationId` | support/recovery trace |
| `retryable` | technical retry hint; business blocker mặc định false |

Precheck chỉ advisory; command chính revalidate. Same idempotency key + same payload returns stored result; same key + different payload returns `IDEMPOTENCY_CONFLICT`.

## Slice catalog

| Slice | US | Type | Primary symbols | State |
| --- | --- | --- | --- | --- |
| S01 | EP-01/US-01 | runtime | SalesOrderWorkingStateDto (no Sales CQRS) | frozen |
| S02 | EP-01/US-02 | runtime/port | SearchPartnersQuery; CreatePartnerCommand (Partner-owned) | frozen |
| S03 | EP-01/US-03 | runtime/port | SearchSellableProductsQuery; ResolveSellableBarcodeQuery; ListSellableProductUnitsQuery (Catalog-owned) | frozen |
| S04 | EP-01/US-04 | runtime/port | PreviewSalesWorkingStatePricingQuery; EvaluateSalesManualPriceQuery (Pricing-owned) | frozen |
| S05 | EP-01/US-05 | cross-module write | ResolveApplicableCustomerPriceRuleQuery; CreateCustomerPriceRuleCommand; UpdateCustomerPriceRuleCommand (Pricing-owned) | frozen |
| S06 | EP-01/US-06 | write | SaveSalesOrderDraftCommand; UpdateSalesOrderDraftCommand | frozen |
| S07 | EP-01/US-07 | read/write | ListSalesOrderDraftsQuery; GetSalesOrderDraftForRestoreQuery; UpdateSalesOrderDraftCommand; CancelSalesOrderDraftCommand | frozen |
| S08 | EP-02/US-01 | validation/read | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand | frozen |
| S09 | EP-02/US-02 | runtime/checkout input | FinalizeSalesOrderCommand (`paymentIntents`) | frozen |
| S10 | EP-02/US-03 | orchestration/write | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand; InitializeSalesOrderSettlementCommand | frozen |
| S11 | EP-02/US-04 | validation/read | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand | frozen |
| S12 | EP-02/US-05 | orchestration/write | FinalizeSalesOrderCommand; GetCheckoutResultQuery | frozen |
| S13 | EP-02/US-06 | read | GetCheckoutResultQuery; GetSalesOrderQuery; GetSalesOrderPaymentSummaryQuery; GetOrderIntegrationStatusQuery | frozen |
| S14 | EP-02/US-07 | read/write | GenerateSalesReceiptCommand; RecordSalesReceiptPrintedCommand; RecordSalesReceiptSharedCommand; ArchiveSalesReceiptCommand; GetSalesReceiptQuery | frozen |
| S15 | EP-03/US-01 | read | ListSalesOrdersQuery; SearchSalesOrdersQuery | frozen |
| S16 | EP-03/US-02 | read | GetSalesOrderDetailQuery; GetSalesOrderQuery | frozen |
| S17 | EP-03/US-03 | read | GetSalesOrderPaymentSummaryQuery; GetSalesOrderSettlementQuery; GetSalesOrderPaymentTransactionsQuery | frozen |
| S18 | EP-03/US-04 | read | GetSalesOrderTimelineQuery; GetSalesOrderReturnSummaryQuery | frozen |
| S19 | EP-03/US-05 | read/write | GetSalesReceiptQuery; GenerateSalesReceiptCommand; RecordSalesReceiptPrintedCommand; RecordSalesReceiptSharedCommand; ArchiveSalesReceiptCommand | frozen |
| S20 | EP-03/US-06 | read/technical write | GetOrderIntegrationStatusQuery; GetIntegrationCommandStatusQuery; GetImpactRequestStatusQuery; RetryIntegrationCommand; ReconcileIntegrationResultCommand | frozen |
| S21 | EP-03/US-07 | read/entry | GetSalesOrderDetailQuery; GetAvailablePostSaleActionsQuery; PrecheckSalesOrderCancellationQuery; PrecheckReturnExchangeQuery | frozen |
| S22 | EP-04/US-01 | read/write | *(withdrawn)* PrecheckOrderAdjustmentQuery; ApplyOrderAdjustmentCommand; GetOrderAdjustmentHistoryQuery | **superseded** |
| S23 | EP-05/US-01 | validation/read | PrecheckSalesOrderCancellationQuery; GetSalesOrderSettlementQuery; GetReturnExchangeOrdersBySalesOrderQuery | frozen |
| S24 | EP-05/US-02 | validation/runtime | PrecheckSalesOrderCancellationQuery; ConfirmSalesOrderCancellationCommand; ListSalesOrderCancellationReasonsQuery (BE–FE read, 2026-08-13) | frozen |
| S25 | EP-05/US-03 | orchestration/write | ConfirmSalesOrderCancellationCommand; CancelSalesOrderCommand; GetSalesOrderCancellationQuery | frozen |
| S26 | EP-05/US-04 | read/technical write | GetOrderIntegrationStatusQuery; RetryIntegrationCommand; RetryInventoryImpactCommand; RetryReceivableImpactCommand; RetryEInvoiceImpactCommand; ReconcileIntegrationResultCommand | frozen |
| S27 | EP-05/US-05 | read | GetSalesOrderCancellationQuery; GetSalesOrderDetailQuery; GetSalesOrderTimelineQuery; GetSalesOrderPaymentSummaryQuery; GetOrderIntegrationStatusQuery | frozen |
| S28 | EP-06/US-01 | read/write | PrecheckReturnExchangeQuery; GetReturnableOrderLinesQuery; StartReturnExchangeCommand | frozen |
| S29 | EP-06/US-02 | read/write | GetReturnableOrderLinesQuery; UpdateReturnExchangeCommand; EvaluateReturnPricingImpactQuery | frozen |
| S30 | EP-06/US-03 | write | UpdateReturnExchangeCommand | frozen |
| S31 | EP-06/US-04 | runtime | CancelReturnExchangeCommand (discard session / technical draft); session working state | frozen |
| S32 | EP-06/US-05 | validation/read | EvaluateReturnPricingImpactQuery; UpdateReturnExchangeCommand; GetSalesOrderSettlementQuery | frozen |
| S33 | EP-06/US-06 | orchestration/write | RecordSalesPaymentCommand; RecordSalesRefundCommand; IReceivableImpactPort (Receivable-owned collection) | frozen |
| S34 | EP-06/US-07 | orchestration/read | ConfirmReturnExchangeCommand; CompleteReturnExchangeCommand; GetSalesOrderReturnSummaryQuery; GetOrderIntegrationStatusQuery | frozen |

## §S01 — [EP-01/US-01](../Epic-01-order-drafting-and-drafts/US-01.md) — Khởi tạo đơn hàng đang lập

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target (contract-only / unimplemented) | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales + provider owner | runtime | SalesOrderWorkingStateDto (no Sales CQRS) | SalesOrderWorkingStateDto | sales flow access | n/a — runtime only | n/a — no Sales RPC | PERMISSION_DENIED; CONTEXT_INVALID; REFERENCE_UNAVAILABLE; STALE_DATA |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e01_u01_scn01_khoi_tao_don_moi_voi_khach_le` | SCN-01 — Khởi tạo đơn mới với Khách lẻ |
| `e01_u01_scn02_khoi_tao_don_tu_ho_so_khach_hang` | SCN-02 — Khởi tạo đơn từ hồ sơ khách hàng |
| `e01_u01_scn03_tenant_yeu_cau_ca_ban_nhung_chua_co_ca_hop_le` | SCN-03 — Tenant yêu cầu ca bán nhưng chưa có ca hợp lệ |
| `e01_u01_scn04_khong_co_quyen_tai_cua_hang` | SCN-04 — Không có quyền tại cửa hàng |
| `e01_u01_scn05_roi_working_state_da_co_du_lieu` | SCN-05 — Rời working state đã có dữ liệu |
| `e01_u01_scn06_bo_working_state_rong` | SCN-06 — Bỏ working state rỗng |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S02 — [EP-01/US-02](../Epic-01-order-drafting-and-drafts/US-02.md) — Xác định khách hàng cho đơn hàng

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales + provider owner | runtime/port | SearchPartnersQuery; CreatePartnerCommand (Partner-owned) | CustomerSelectionDto | sales flow access + Partner owner permission | n/a — runtime selection | n/a — Partner-owned contracts | PERMISSION_DENIED; CONTEXT_INVALID; REFERENCE_UNAVAILABLE; STALE_DATA |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e01_u02_scn01_tiep_tuc_ban_cho_khach_le` | SCN-01 — Tiếp tục bán cho Khách lẻ |
| `e01_u02_scn02_chon_khach_hang_co_ho_so` | SCN-02 — Chọn khách hàng có hồ sơ |
| `e01_u02_scn03_quay_lai_khach_le` | SCN-03 — Quay lại Khách lẻ |
| `e01_u02_scn04_tao_nhanh_khach_hang_thanh_cong` | SCN-04 — Tạo nhanh khách hàng thành công |
| `e01_u02_scn05_huy_luong_tao_nhanh_khach_hang` | SCN-05 — Hủy luồng tạo nhanh khách hàng |
| `e01_u02_scn06_khach_hang_khong_con_hoat_dong_khi_checkout` | SCN-06 — Khách hàng không còn hoạt động khi checkout |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S03 — [EP-01/US-03](../Epic-01-order-drafting-and-drafts/US-03.md) — Thêm và quản lý dòng hàng

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Catalog owner + Sales presentation adapter | runtime/port | SearchSellableProductsQuery; ResolveSellableBarcodeQuery; ListSellableProductUnitsQuery | sellable products/units with price bands; `displayName` từ `products.name`, nullable `tradeName` từ `products.trade_name` | `catalog.product.view` + active scoped store | read-only | `catalog.search_sellable_products`; `catalog.resolve_sellable_barcode`; `catalog.list_sellable_product_units` | permission/store denied; malformed owner payload; transport unavailable |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e01_u03_scn01_them_san_pham_bang_tim_kiem` | SCN-01 — Thêm sản phẩm bằng tìm kiếm |
| `e01_u03_scn02_them_san_pham_bang_barcode` | SCN-02 — Thêm sản phẩm bằng barcode |
| `e01_u03_scn03_them_lai_cung_san_pham_va_don_vi` | SCN-03 — Thêm lại cùng sản phẩm và đơn vị |
| `e01_u03_scn04_thay_doi_don_vi_ban` | SCN-04 — Thay đổi đơn vị bán |
| `e01_u03_scn05_nhap_so_luong_khong_hop_le` | SCN-05 — Nhập số lượng không hợp lệ |
| `e01_u03_scn06_san_pham_da_ngung_ban` | SCN-06 — Sản phẩm đã ngừng bán |
| `e01_u03_scn07_chan_thanh_toan_khi_co_dong_khong_hop_le` | SCN-07 — Chặn Thanh toán khi có dòng không hợp lệ |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

Presentation field contract: dòng tiêu đề suggestion dùng `displayName`; dòng phụ dùng `tradeName · unitName`, và chỉ còn `unitName` khi `tradeName` null/rỗng.

## §S04 — [EP-01/US-04](../Epic-01-order-drafting-and-drafts/US-04.md) — Kiểm tra và điều chỉnh giá bán

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pricing owner + Sales presentation adapter | runtime/port | PreviewSalesWorkingStatePricingQuery; EvaluateSalesManualPriceQuery | complete versioned line preview/manual evaluation | `pricing.sales.preview`; `pricing.sales.manual_price.adjust`; floor override policy | response context version + canonical preview token | `pricing.preview_sales_working_state_pricing`; `pricing.evaluate_sales_manual_price` | permission/store denied; incomplete line set; blocker codes; transport unavailable |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e01_u04_scn01_lay_pricing_preview_thanh_cong` | SCN-01 — Lấy pricing preview thành công |
| `e01_u04_scn02_gia_thay_doi_khi_doi_khach_hang` | SCN-02 — Giá thay đổi khi đổi khách hàng |
| `e01_u04_scn03_dieu_chinh_gia_thu_cong_hop_le` | SCN-03 — Điều chỉnh giá thủ công hợp lệ |
| `e01_u04_scn04_khong_co_quyen_sua_gia` | SCN-04 — Không có quyền sửa giá |
| `e01_u04_scn05_gia_duoi_san_bi_chan` | SCN-05 — Giá dưới sàn bị chặn |
| `e01_u04_scn06_gia_duoi_san_duoc_override` | SCN-06 — Giá dưới sàn được override |
| `e01_u04_scn07_khong_lay_duoc_gia_hop_le` | SCN-07 — Không lấy được giá hợp lệ |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S05 — [EP-01/US-05](../Epic-01-order-drafting-and-drafts/US-05.md) — Lưu giá riêng hoặc nhớ giá từ đơn hàng

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pricing owner + ERP orchestration | cross-module write | ResolveApplicableCustomerPriceRuleQuery; CreateCustomerPriceRuleCommand; UpdateCustomerPriceRuleCommand | immediate private-rule result | Pricing view/create/update + floor override policy | stable `sales-private-price-v1` key; expectedVersion; read-back on uncertainty | existing Pricing customer-price-rule RPCs | overwrite confirmation; floor blocker; state changed; transport uncertainty |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e01_u05_scn01_mo_flow_luu_gia_rieng` | SCN-01 — Mở flow lưu giá riêng |
| `e01_u05_scn02_chan_khach_le_luu_gia_rieng` | SCN-02 — Chặn Khách lẻ lưu giá riêng |
| `e01_u05_scn03_luu_rule_thanh_cong` | SCN-03 — Lưu rule thành công |
| `e01_u05_scn04_huy_flow_theme_4` | SCN-04 — Hủy flow Theme 4 |
| `e01_u05_scn05_theme_4_tu_choi_do_rule_trung` | SCN-05 — Theme 4 từ chối do rule trùng |
| `e01_u05_scn06_khong_tai_duoc_pricing_preview_sau_khi_luu_rule` | SCN-06 — Không tải được pricing preview sau khi lưu rule |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S06 — [EP-01/US-06](../Epic-01-order-drafting-and-drafts/US-06.md) — Lưu đơn hàng thành đơn nháp

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | write | SaveSalesOrderDraftCommand; UpdateSalesOrderDraftCommand | SalesOrderDraftDto (full persisted snapshot) | sales.draft.create; sales.draft.update | required `storeId`; save/update require `idempotencyKey`; `payloadHash` optional (Dart `super.payloadHash` / SQL `p_payload_hash text default null`); update requires `expectedVersion`; replay uses SQL `IS DISTINCT FROM` on stored vs request hash — same key + same hash (including both null) returns prior result; same key + different hash (incl. null↔value) → `IDEMPOTENCY_CONFLICT`; version mismatch → `STALE_DATA` | sales.save_sales_order_draft; sales.update_sales_order_draft | PERMISSION_DENIED; DATA_SCOPE_DENIED; CONTEXT_INVALID; REFERENCE_UNAVAILABLE; STALE_DATA; IDEMPOTENCY_CONFLICT |

### Working-state / RPC field contract (Group B live)

| Surface | Required fields / params |
| --- | --- |
| `SaveSalesOrderDraftCommand` | `storeId`; `currencyCode`; `lines:List<SalesOrderDraftLineInput>` (non-empty); `idempotencyKey`; optional `customer`, `orderNote`, `pricingPreviewToken`, `needsRevalidation`, `payloadHash` |
| `UpdateSalesOrderDraftCommand` | `draftId`; `storeId`; `currencyCode`; `lines`; `expectedVersion`; `idempotencyKey`; same optional snapshot fields as save |
| RPC save params | `p_tenant_id`; `p_actor_id`; `p_store_id`; `p_customer`; `p_currency_code`; `p_order_note`; `p_pricing_preview_token`; `p_needs_revalidation`; `p_lines`; `p_idempotency_key`; optional `p_payload_hash` / `p_correlation_id` / `p_causation_id` |
| RPC update params | save params plus `p_draft_id`; `p_expected_version` |
| Line JSON | product/unit IDs + display snapshots, quantity micros, applied/list price minors, manual price/discount fields, pricing source/warnings/blockers, note, `needs_revalidation` — **never** `floor_price_minor` / stock fields |

**Semantics (authoritative for Group B):**

- Persist is a **reference snapshot** of compose working state. Restore always revalidates current Catalog/Partner/Pricing; snapshot prices are not current commercial truth for checkout.
- Floor price and available stock are **not** persisted; they are resolved live on restore/compose.
- Pricing unavailable at save time still allows persistence with `needsRevalidation=true` (and/or line-level revalidation flags); it does not invent prices.
- Optimistic concurrency: update compares `expectedVersion` to row version under store scope.
- Idempotency: `idempotencyKey` is required on save/update; `payloadHash` / `p_payload_hash` is **optional** (matches Dart + draft SQL). When a prior key exists, draft SQL compares hashes with `IS DISTINCT FROM`: both absent/null → replay prior result; both equal non-null → replay; any mismatch including null vs non-null → `IDEMPOTENCY_CONFLICT`. Clients may omit hash; omitting does not invent a required-hash gate on this wire.
- Store scope: every mutation independently verifies authenticated actor, permission, tenant membership, and active `storeId`.
- No SalesOrder / payment / receivable / stock / receipt / e-invoice impacts on save/update.

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e01_u06_scn01_luu_draft_thanh_cong` | SCN-01 — Lưu draft thành công |
| `e01_u06_scn02_luu_draft_co_khach_hang_dinh_danh` | SCN-02 — Lưu draft có khách hàng định danh |
| `e01_u06_scn03_khong_cho_luu_draft_rong` | SCN-03 — Không cho lưu draft rỗng |
| `e01_u06_scn04_luu_draft_khi_pricing_preview_can_lam_moi` | SCN-04 — Lưu draft khi pricing preview cần làm mới |
| `e01_u06_scn05_submit_luu_draft_nhieu_lan` | SCN-05 — Submit lưu draft nhiều lần |
| `e01_u06_scn06_luu_draft_that_bai` | SCN-06 — Lưu draft thất bại |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE/FE evidence and scenario closure

- Artifacts: full-snapshot commands/DTOs/validators; `ISalesOrderDraftGateway` + `SalesOrderDraftRpcMapper` + `SupabaseSalesOrderDraftGateway` + in-memory gateway; ERP `SalesDraftBackend` orchestration (Catalog/Partner/Pricing via mediators); draft-only `supabase/migrations/_drafts/007_sales_draft_rpcs.sql` (not promoted/applied).
- Unit/contract coverage: `sales_order_draft_handlers_test.dart`; `sales_order_draft_rpc_mapper_test.dart`; `sales_order_draft_sql_contract_test.dart`; `sales_group_b_startup_test.dart`; presentation/ERP draft-backend and no-fake DI tests.
- Live E2E remains **blocked**: missing `VET45_E2E_*` seed defines and rebuild draft `007_sales_draft_rpcs.sql` not promoted/applied (`REGISTRY.yaml` has no Sales rebuild RPC ownership yet). Guarded test `apps/erp/integration_test/sales_group_b_s06_s07_live_test.dart` skips cleanly when `VET45_RUN_LIVE_GROUP_B` is unset. Do **not** mark E2E done.

## §S07 — [EP-01/US-07](../Epic-01-order-drafting-and-drafts/US-07.md) — Khôi phục và quản lý đơn nháp

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/write | ListSalesOrderDraftsQuery; GetSalesOrderDraftForRestoreQuery; UpdateSalesOrderDraftCommand; CancelSalesOrderDraftCommand | `PagedSalesOrderDraftListDto` / `SalesOrderDraftForRestoreDto` / `SalesOrderDraftDto` | sales.draft.restore; sales.draft.update; sales.draft.delete | required `storeId` on list/restore/update/cancel; update/cancel require `expectedVersion` + idempotency; soft-cancel only (status → cancelled); active-only list/restore | sales.list_sales_order_drafts; sales.get_sales_order_draft_for_restore; sales.update_sales_order_draft; sales.cancel_sales_order_draft | PERMISSION_DENIED; DATA_SCOPE_DENIED; CONTEXT_INVALID; REFERENCE_UNAVAILABLE; STALE_DATA; IDEMPOTENCY_CONFLICT |

### Working-state / RPC field contract (Group B live)

| Surface | Required fields / params |
| --- | --- |
| `ListSalesOrderDraftsQuery` | `storeId`; optional `cursor`; `pageSize` (default 25) |
| `GetSalesOrderDraftForRestoreQuery` | `draftId`; `storeId`; optional `expectedSourceVersion` |
| `CancelSalesOrderDraftCommand` | `draftId`; `storeId`; `expectedVersion`; `idempotencyKey`; optional `payloadHash` |
| RPC list | `p_tenant_id`; `p_actor_id`; `p_store_id`; `p_cursor`; `p_page_size` |
| RPC restore | `p_tenant_id`; `p_actor_id`; `p_draft_id`; `p_store_id`; optional `p_expected_version` |
| RPC cancel | `p_tenant_id`; `p_actor_id`; `p_draft_id`; `p_store_id`; `p_expected_version`; `p_idempotency_key`; optional hash/correlation/causation |

**Semantics:**

- List/restore are **active-store scoped**; cancelled drafts are not restored/listed as active.
- Restore returns the persisted snapshot; ERP `SalesDraftBackend.bindRestore` revalidates Partner/Catalog/Pricing and surfaces issues (inactive product/unit, pricing unavailable, price drift) without inventing authoritative live values into Sales SQL.
- Soft cancel requires `idempotencyKey`; `payloadHash` optional (same `IS DISTINCT FROM` replay/conflict rules as §S06). Wrong version → `STALE_DATA`; wrong store/tenant scope → `DATA_SCOPE_DENIED` / `REFERENCE_UNAVAILABLE` as implemented in draft SQL.
- `expires_at` is not written or read by save/update/list/restore. A draft with `expires_at` in the past and `status = active` is still listed and restored. Expiry is only `status = expired`. No RPC flips that status. Past `payment_due_date` is allowed. Finding: `policy decision required` if product wants time-based expiry. Do not treat `expires_at` as a live gate.
- `p_cursor` / `next_cursor` on draft list are integer offsets encoded as text, not a keyset cursor. Sort is `created_at desc, id desc`, then `OFFSET`. Insert or delete between pages can skip or repeat rows. Order inquiry list/search is a separate keyset contract. Draft list stability is `policy decision required`; do not change the RPC until that decision and a reproduced failure.

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e01_u07_scn01_xem_danh_sach_draft_active` | SCN-01 — Xem danh sách draft active |
| `e01_u07_scn02_khoi_phuc_draft_khong_co_thay_doi` | SCN-02 — Khôi phục draft không có thay đổi |
| `e01_u07_scn03_khoi_phuc_draft_co_gia_thay_doi` | SCN-03 — Khôi phục draft có giá thay đổi |
| `e01_u07_scn04_khoi_phuc_draft_co_san_pham_khong_con_hop_le` | SCN-04 — Khôi phục draft có sản phẩm không còn hợp lệ |
| `e01_u07_scn05_cap_nhat_draft_thanh_cong` | SCN-05 — Cập nhật draft thành công |
| `e01_u07_scn06_version_conflict` | SCN-06 — Version conflict |
| `e01_u07_scn07_huy_mem_draft` | SCN-07 — Hủy mềm draft |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE/FE evidence and scenario closure

- Artifacts: list/restore/update/cancel handlers + store-scoped gateway/RPC/SQL; `SalesDraftListCubit` / compose restore via `SalesDraftBackend`; same draft SQL `007_sales_draft_rpcs.sql`.
- Live E2E remains **blocked** for the same seed + unpromoted draft RPC reasons as §S06. Guarded disabled-gate skip is evidenced; live gate was not executed. Do **not** mark E2E done.

## §S08 — [EP-02/US-01](../Epic-02-checkout-and-completion/US-01.md) — Kiểm tra tổng tiền và nghĩa vụ thanh toán

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | validation/read | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand | CheckoutMonetarySummaryDto | sales.checkout.create | finalize revalidates preview | sales.precheck_sales_order_checkout | CHECKOUT_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; DEPENDENCY_UNAVAILABLE; UNCERTAIN_RESULT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e02_u01_scn01_don_chua_co_payment_intent` | SCN-01 — Đơn chưa có payment intent |
| `e02_u01_scn02_don_da_nhap_thanh_toan_mot_phan` | SCN-02 — Đơn đã nhập thanh toán một phần |
| `e02_u01_scn03_don_da_nhap_du_thanh_toan` | SCN-03 — Đơn đã nhập đủ thanh toán |
| `e02_u01_scn04_tong_payment_intent_vuot_tong_phai_tra` | SCN-04 — Tổng payment intent vượt tổng phải trả |
| `e02_u01_scn05_gia_thay_doi_lam_payment_intent_khong_con_hop_le` | SCN-05 — Giá thay đổi làm payment intent không còn hợp lệ |
| `e02_u01_scn06_quay_lai_sua_don` | SCN-06 — Quay lại sửa đơn |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S09 — [EP-02/US-02](../Epic-02-checkout-and-completion/US-02.md) — Ghi nhận một hoặc nhiều khoản thanh toán

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | runtime/checkout input | FinalizeSalesOrderCommand (`paymentIntents`) | PaymentIntentSummaryDto | sales.checkout.create | payment intent becomes transaction only inside authoritative finalize commit | n/a — no persisted payment-intent RPC | CHECKOUT_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; DEPENDENCY_UNAVAILABLE; UNCERTAIN_RESULT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e02_u02_scn01_thanh_toan_toan_bo_bang_tien_mat` | SCN-01 — Thanh toán toàn bộ bằng tiền mặt |
| `e02_u02_scn02_thanh_toan_toan_bo_bang_chuyen_khoan_thu_cong` | SCN-02 — Thanh toán toàn bộ bằng chuyển khoản thủ công |
| `e02_u02_scn03_ket_hop_nhieu_phuong_thuc` | SCN-03 — Kết hợp nhiều phương thức |
| `e02_u02_scn04_cap_nhat_payment_intent` | SCN-04 — Cập nhật payment intent |
| `e02_u02_scn05_xoa_payment_intent` | SCN-05 — Xóa payment intent |
| `e02_u02_scn06_chan_tong_thanh_toan_vuot_nghia_vu` | SCN-06 — Chặn tổng thanh toán vượt nghĩa vụ |
| `e02_u02_scn07_checkout_bi_chan_truoc_commit` | SCN-07 — Checkout bị chặn trước commit |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S10 — [EP-02/US-03](../Epic-02-checkout-and-completion/US-03.md) — Xử lý đơn hàng còn phải thu

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | orchestration/write | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand; InitializeSalesOrderSettlementCommand | ReceivableRequirementDto | sales.checkout.create | idempotency required; customer eligibility live | sales.precheck_sales_receivable; sales.finalize_sales_order | CHECKOUT_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; DEPENDENCY_UNAVAILABLE; UNCERTAIN_RESULT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e02_u03_scn01_khach_hang_thanh_toan_mot_phan` | SCN-01 — Khách hàng thanh toán một phần |
| `e02_u03_scn02_khach_hang_chua_thanh_toan` | SCN-02 — Khách hàng chưa thanh toán |
| `e02_u03_scn03_chan_khach_le_ban_thieu` | SCN-03 — Chặn Khách lẻ bán thiếu |
| `e02_u03_scn04_chan_nguoi_dung_khong_co_quyen_ban_thieu` | SCN-04 — Chặn người dùng không có quyền bán thiếu |
| `e02_u03_scn05_ngay_hen_thanh_toan_khong_hop_le` | SCN-05 — Ngày hẹn thanh toán không hợp lệ |
| `e02_u03_scn06_don_da_thanh_toan_du` | SCN-06 — Đơn đã thanh toán đủ |
| `e02_u03_scn07_theme_6_xu_ly_cham` | SCN-07 — Theme 6 xử lý chậm |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S11 — [EP-02/US-04](../Epic-02-checkout-and-completion/US-04.md) — Kiểm tra điều kiện checkout

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | validation/read | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand | CheckoutPrecheckDto | sales.checkout.create | precheck advisory; finalize authoritative | sales.precheck_sales_order_checkout | CHECKOUT_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; DEPENDENCY_UNAVAILABLE; UNCERTAIN_RESULT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e02_u04_scn01_precheck_san_sang` | SCN-01 — Precheck sẵn sàng |
| `e02_u04_scn02_gia_thay_doi_truoc_checkout` | SCN-02 — Giá thay đổi trước checkout |
| `e02_u04_scn03_san_pham_khong_con_duoc_ban` | SCN-03 — Sản phẩm không còn được bán |
| `e02_u04_scn04_khong_du_ton_kho_khi_cam_am_kho` | SCN-04 — Không đủ tồn kho khi cấm âm kho |
| `e02_u04_scn05_thieu_thong_tin_ban_thieu` | SCN-05 — Thiếu thông tin bán thiếu |
| `e02_u04_scn06_dependency_tam_thoi_khong_phan_hoi` | SCN-06 — Dependency tạm thời không phản hồi |
| `e02_u04_scn07_du_lieu_thay_doi_sau_precheck` | SCN-07 — Dữ liệu thay đổi sau precheck |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

## §S12 — [EP-02/US-05](../Epic-02-checkout-and-completion/US-05.md) — Hoàn tất đơn hàng an toàn

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | orchestration/write | FinalizeSalesOrderCommand; GetCheckoutResultQuery | CheckoutResultDto | sales.checkout.create; sales.payment.record; sales.order.view | idempotency key + payload hash required | sales.finalize_sales_order; sales.get_checkout_result | CHECKOUT_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; DEPENDENCY_UNAVAILABLE; UNCERTAIN_RESULT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e02_u05_scn01_checkout_thanh_cong` | SCN-01 — Checkout thành công |
| `e02_u05_scn02_retry_cung_payload` | SCN-02 — Retry cùng payload |
| `e02_u05_scn03_tai_su_dung_key_voi_payload_khac` | SCN-03 — Tái sử dụng key với payload khác |
| `e02_u05_scn04_timeout_sau_khi_server_commit` | SCN-04 — Timeout sau khi server commit |
| `e02_u05_scn05_checkout_bi_blocked_tai_command_time` | SCN-05 — Checkout bị blocked tại command time |
| `e02_u05_scn06_checkout_uncertain` | SCN-06 — Checkout uncertain |
| `e02_u05_scn07_draft_nguon_duoc_converted` | SCN-07 — Draft nguồn được converted |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

S12 checkout `orderNote`: nullable note is normalized and persisted as the immutable original note during finalize. (S22 note-adjustment / effective-note fallback **superseded** — no longer active contract.) Checkout emits lifecycle outbox facts only — **no** Sales-owned `*_impact_requests` / `integration_commands` enqueue (option B reactive).

### Cross-module handoff — deferred (option B reactive, 2026-09)

Sales mutations (checkout/cancellation/return) publish lifecycle outbox facts (`sales_order_finalized.v1`, …) in the same business transaction. Inventory/receivable/e-invoice **work** is owner responsibility: TH-06/07/08 consume Sales facts via inbox handlers. Sales **does not** enqueue `sales.*.apply_impact.v1` or maintain impact/command rows in the current phase. E-invoice read fallback `notRequired`. E2E owner consumption remains `todo` until canonical owner modules exist.

**Constraints (M2, draft `032_sales_review_constraints.sql`, not promoted):** New related-payment and receipt-supersession foreign keys are same tenant and same parent, added `NOT VALID`. Returned lines need exactly one source. `base_quantity_micros > 0`. Header payable is `subtotal - discount + tax + rounding`. Collection is inflow and refund is outflow; reversal direction is not forced by CHECK. Existing rows are not rewritten or validated by this draft. Audit is `sales.audit_sales_review_invariants()` and is SELECT-only.

**Fact ownership (M1, draft `031_sales_review_facts.sql`, not promoted):** Lifecycle facts own goods effects. `sales_settlement_changed.v1` is the money snapshot and is a replacement, not a delta. Do not add collected/refunded from both a lifecycle fact and the settlement fact. `sales_payment_recorded.v1` / `sales_refund_recorded.v1` are transaction facts only. `sales_reporting_cancellation_recorded.v1` is a deprecated transitional producer with no in-repo consumer; Reporting must consume `sales_order_cancelled.v1`. Owner handlers are `MISSING`. Readiness: `docs/operations/2026-09-08-sales-owner-readiness.md`.

~~Model B command table (`sales.enqueue_impact_handoff`, apply_impact payloads)~~ — **withdrawn / deferred**; see harness [01-domain-model §9.2](01-domain-model.md#92-cross-module-handoff--deferred-not-sales-owned-in-current-phase).

## §S13 — [EP-02/US-06](../Epic-02-checkout-and-completion/US-06.md) — Xem kết quả giao dịch

<a id="check-out"></a>

### Checkout recovery contract — quyết định 2026-09-10

Quyết định này thay thế thiết kế persisted checkout attempt trong canonical cũ. Sửa trực tiếp migration bootstrap/checkout hiện có theo yêu cầu người dùng; chỉ có hiệu lực khi dựng DB từ đầu, không phải migration chuyển đổi DB đã apply.

- `GetCheckoutResultQuery` nhận execution context, `storeId`, `idempotencyKey`; không nhận attempt ID hoặc expected draft version.
- RPC: `sales.get_checkout_result(p_query_id uuid, p_tenant_id uuid, p_actor_id uuid, p_store_id uuid, p_idempotency_key text)`.
- Finalize/replay/query trả `CheckoutResultDto(idempotencyKey, salesOrderId, salesOrderVersion, status)`. Chưa thành công giữ order ID rỗng và order version 0. `CheckoutResultStatus`: processing, succeeded, blocked, failed, uncertain.
- Storage chỉ dùng `sales.idempotency_records`, scope `finalize_sales_order`. `result_snapshot` envelope gồm `storeId`, `requestedByUserId`, `checkoutResult`; metadata không trả cho UI. Finalize replay unwrap `checkoutResult`. Các scope khác không đổi.
- Query kiểm tra actor/tenant và quyền xem đơn tại store bằng helper hiện hữu, đối chiếu store của record; không mở quyền đọc trực tiếp bảng idempotency. Không tìm thấy hoặc record không thuộc store yêu cầu không được làm lộ dữ liệu ngoài scope.
- `CHECKOUT_RESULT_NOT_FOUND` không có nghĩa chắc chắn chưa tạo đơn: transaction đang chạy có thể chưa visible. UI poll có giới hạn; khi retry giữ nguyên key và payload. Không sinh key mới vì timeout. Sửa dữ liệu sau blocked/failed tạo key mới.
- Blocked từ application precheck xảy ra trước RPC finalize: hiển thị trực tiếp, không chạy recovery query. Không thêm thời hạn xóa checkout idempotency records.
- Không còn bảng `checkout_attempts`, cột `sales_orders.checkout_attempt_id`, RPC `get_checkout_attempt_status` hoặc field `checkoutAttemptId` trong active checkout fact. Request envelope trong UI chỉ phục vụ retry trong bộ nhớ.

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read | GetCheckoutResultQuery; GetSalesOrderQuery; GetSalesOrderPaymentSummaryQuery; GetOrderIntegrationStatusQuery | CheckoutResultViewDto | sales.order.view; sales.payment.view; sales.integration.view_sync_status; sales.receipt.view | read only; storeId + idempotencyKey lookup | sales.get_checkout_result; sales.get_sales_order; sales.get_order_integration_status | CHECKOUT_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; DEPENDENCY_UNAVAILABLE; UNCERTAIN_RESULT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e02_u06_scn01_don_thanh_toan_du` | SCN-01 — Đơn thanh toán đủ |
| `e02_u06_scn02_don_con_phai_thu` | SCN-02 — Đơn còn phải thu |
| `e02_u06_scn03_downstream_impacts_dang_pending` | SCN-03 — Downstream impacts đang pending |
| `e02_u06_scn04_khong_yeu_cau_hoa_don_dien_tu` | SCN-04 — Không yêu cầu hóa đơn điện tử |
| `e02_u06_scn05_checkout_dang_uncertain` | SCN-05 — Checkout đang uncertain |
| `e02_u06_scn06_mo_chi_tiet_don` | SCN-06 — Mở chi tiết đơn |
| `e02_u06_scn07_tao_don_moi` | SCN-07 — Tạo đơn mới |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** SG-06 loads via `SalesTransactionResultCubit` → `ISalesModule.executeQueryAsync` for all four queries; `CheckoutResultViewDto` is composed in presentation only. Authoritative read surface uses `SalesOrderResultDto` (store/seller/customer snapshots + `committedAt`; payment due date comes from `SalesOrderPaymentSummaryDto.dueAt` when present). Typed route handoff is identity-only (`SalesCheckoutResultArgs.result` = `CheckoutResultDto` with `idempotencyKey` + `salesOrderId`; route args also carry `storeId`). Rebuild draft `010_sales_inquiry_receipt_rpcs.sql` remains unpromoted/unapplied; E2E and live RPC verification remain `todo`.

## §S14 — [EP-02/US-07](../Epic-02-checkout-and-completion/US-07.md) — Xem, in hoặc chia sẻ phiếu bán hàng

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/write | GenerateSalesReceiptCommand; RecordSalesReceiptPrintedCommand; RecordSalesReceiptSharedCommand; ArchiveSalesReceiptCommand; GetSalesReceiptQuery | SalesReceiptDto | sales.receipt.generate; sales.receipt.view; sales.receipt.print; sales.receipt.share; sales.receipt.archive | generate/archive idempotent; activities append-only | sales.generate_sales_receipt; sales.get_sales_receipt; sales.record_sales_receipt_activity | CHECKOUT_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; DEPENDENCY_UNAVAILABLE; UNCERTAIN_RESULT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e02_u07_scn01_tao_receipt_sau_checkout` | SCN-01 — Tạo receipt sau checkout |
| `e02_u07_scn02_xem_receipt` | SCN-02 — Xem receipt |
| `e02_u07_scn03_in_receipt` | SCN-03 — In receipt |
| `e02_u07_scn04_chia_se_receipt` | SCN-04 — Chia sẻ receipt |
| `e02_u07_scn05_receipt_chua_tao_xong` | SCN-05 — Receipt chưa tạo xong |
| `e02_u07_scn06_du_lieu_master_thay_doi_sau_ban` | SCN-06 — Dữ liệu master thay đổi sau bán |
| `e02_u07_scn07_goi_tao_receipt_lap_lai` | SCN-07 — Gọi tạo receipt lặp lại |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** Receipt UI uses typed `SalesReceiptDocumentDto` end-to-end (generate/get command results → PDF preview/print/share). Device callbacks run before append-only print/share audit commands; activity warnings surface without blocking order success. Native print/share is presentation-only via `SalesPdfRunner` — not verified on physical devices in this slice. Rebuild draft `010_sales_inquiry_receipt_rpcs.sql` remains unpromoted/unapplied; E2E remains `todo`.

**Receipt lifecycle (C4, draft `030_sales_review_receipt_lifecycle.sql`, not promoted):** `generate_sales_receipt` locks `sales_orders` then settlement, then payment and adjustment rows, before reading money. Supersession is same tenant and order, never self. `printed`/`shared` require status `generated`. `archived` is allowed from `generated` or `superseded`, no-op when already archived, and does not rewrite `receipt_snapshot` or `content_hash`. Two-session concurrency is not verified by a single connection.

**Receipt snapshot (C3, draft `029_sales_review_receipt.sql`, not promoted):** `lines` / `subtotal` / `discountTotal` / `taxTotal` / `roundingTotal` / `orderTotal` are the original sale. `orderTotal` is `sales_orders.payable_amount_minor`, not settlement current payable. `settlementSnapshot` is separate: `originalPayable`, `adjustment`, `currentPayable`, `collected`, `refunded`, `netCollected`, `outstanding`, `adjustmentSources`. Example: original 1_000_000, return 200_000 → `orderTotal` 1_000_000, `adjustment` −200_000, `currentPayable` 800_000. `content_hash` is `md5(receipt_snapshot)`; `p_payload_hash` is command identity only. Existing receipt rows are not rewritten. Documents without `settlementSnapshot` still parse; PDF then keeps the label “Tổng đơn”. When the block is present, PDF labels are “Giá trị đơn gốc”, “Điều chỉnh sau bán”, “Phải trả hiện tại”, “Còn phải thu”.

## §S15 — [EP-03/US-01](../Epic-03-order-inquiry-and-tracking/US-01.md) — Tra cứu danh sách đơn hàng

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read | ListSalesOrdersQuery; SearchSalesOrdersQuery | PagedSalesOrderListDto | sales.order.view | cursor/sort stable on `(completedAt, id)`; filter/search apply before cursor; `totalMatching` and facets are the full filtered set | sales.list_sales_orders; sales.search_sales_orders | NOT_FOUND; PERMISSION_DENIED; PROJECTION_PENDING; DATA_SCOPE_DENIED |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e03_u01_scn01_mo_danh_sach_don_hang` | SCN-01 — Mở danh sách đơn hàng |
| `e03_u01_scn02_tim_theo_ma_don` | SCN-02 — Tìm theo mã đơn |
| `e03_u01_scn03_tim_theo_customer_snapshot` | SCN-03 — Tìm theo customer snapshot |
| `e03_u01_scn04_loc_theo_nhieu_dieu_kien` | SCN-04 — Lọc theo nhiều điều kiện |
| `e03_u01_scn05_empty_state` | SCN-05 — Empty state |
| `e03_u01_scn06_no_result_state` | SCN-06 — No-result state |
| `e03_u01_scn07_khong_co_quyen` | SCN-07 — Không có quyền |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** `SalesOrderListCubit` loads via `ISalesModule` + `ISalesActiveStoreContext` with server cursor/filter (`SalesOrderListFilterInput` / facets). No local demo enrichment or `so-demo-*` branches. Guard: `apps/erp/test/features/sales/group_f_no_demo_contract_test.dart`. Rebuild draft `010_sales_inquiry_receipt_rpcs.sql` remains unpromoted/unapplied; E2E remains `blocked`.

## §S16 — [EP-03/US-02](../Epic-03-order-inquiry-and-tracking/US-02.md) — Xem chi tiết giao dịch gốc

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read | GetSalesOrderDetailQuery; GetSalesOrderQuery | SalesOrderDetailDto | sales.order.view | read only; projection version exposed | sales.get_sales_order_detail | NOT_FOUND; PERMISSION_DENIED; PROJECTION_PENDING; DATA_SCOPE_DENIED |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e03_u02_scn01_mo_chi_tiet_tu_danh_sach` | SCN-01 — Mở chi tiết từ danh sách |
| `e03_u02_scn02_product_master_da_thay_doi` | SCN-02 — Product master đã thay đổi |
| `e03_u02_scn03_customer_profile_da_thay_doi` | SCN-03 — Customer profile đã thay đổi |
| `e03_u02_scn04_xem_don_da_huy` | SCN-04 — Xem đơn đã hủy |
| `e03_u02_scn05_deep_link_ngoai_pham_vi` | SCN-05 — Deep link ngoài phạm vi |
| `e03_u02_scn06_khong_tim_thay_don` | SCN-06 — Không tìm thấy đơn |
| `e03_u02_scn07_projection_dang_cap_nhat` | SCN-07 — Projection đang cập nhật |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** `SalesOrderDetailCubit` core load via `GetSalesOrderDetailQuery`; independent section states; blocked/not-found/projection-pending/error UI when core fails (no demo fallback). Rebuild draft `010` unpromoted/unapplied; E2E `blocked`.

## §S17 — [EP-03/US-03](../Epic-03-order-inquiry-and-tracking/US-03.md) — Kiểm tra thanh toán và công nợ của đơn

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read | GetSalesOrderPaymentSummaryQuery; GetSalesOrderSettlementQuery; GetSalesOrderPaymentTransactionsQuery | SalesOrderPaymentSummaryDto | sales.payment.view; sales.order.view | cursor stable for transactions | sales.get_sales_order_payment_summary; sales.get_sales_order_payment_transactions | NOT_FOUND; PERMISSION_DENIED; PROJECTION_PENDING; DATA_SCOPE_DENIED |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e03_u03_scn01_don_da_thanh_toan_du` | SCN-01 — Đơn đã thanh toán đủ |
| `e03_u03_scn02_don_thanh_toan_mot_phan` | SCN-02 — Đơn thanh toán một phần |
| `e03_u03_scn03_don_co_hoan_tien` | SCN-03 — Đơn có hoàn tiền |
| `e03_u03_scn04_payment_bi_void` | SCN-04 — Payment bị void |
| `e03_u03_scn05_mo_cong_no_trong_theme_6` | SCN-05 — Mở công nợ trong Theme 6 |
| `e03_u03_scn06_khong_co_quyen_xem_payment_chi_tiet` | SCN-06 — Không có quyền xem payment chi tiết |
| `e03_u03_scn07_projection_payment_dang_cham` | SCN-07 — Projection payment đang chậm |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** Payment summary + transactions load as independent detail sections (`SalesOrderPaymentVm`); projection-pending/error do not invent empty-success. Rebuild draft `010` unpromoted/unapplied; E2E `blocked`.

## §S18 — [EP-03/US-04](../Epic-03-order-inquiry-and-tracking/US-04.md) — Theo dõi timeline và lịch sử sau bán

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read | GetSalesOrderTimelineQuery; GetSalesOrderReturnSummaryQuery | SalesOrderTimelineDto | sales.order.history.view; sales.return_exchange.view | read only; source id/version required | sales.get_sales_order_timeline; sales.get_sales_order_return_summary | NOT_FOUND; PERMISSION_DENIED; PROJECTION_PENDING; DATA_SCOPE_DENIED |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e03_u04_scn01_xem_timeline_giao_dich_co_ban` | SCN-01 — Xem timeline giao dịch cơ bản |
| `e03_u04_scn02_xem_adjustment_diff` | SCN-02 — Xem adjustment diff |
| `e03_u04_scn03_xem_don_da_huy` | SCN-03 — Xem đơn đã hủy |
| `e03_u04_scn04_xem_return_summary` | SCN-04 — Xem return summary |
| `e03_u04_scn05_tra_toan_bo_hang_nhung_khong_huy_don` | SCN-05 — Trả toàn bộ hàng nhưng không hủy đơn |
| `e03_u04_scn06_khong_co_quyen_mo_source` | SCN-06 — Không có quyền mở source |
| `e03_u04_scn07_timeline_projection_dang_cham` | SCN-07 — Timeline projection đang chậm |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** Timeline/return-summary sections use typed VMs; history/return list pages are presentation-only. Rebuild draft `010` unpromoted/unapplied; E2E `blocked`.

## §S19 — [EP-03/US-05](../Epic-03-order-inquiry-and-tracking/US-05.md) — Xem lại phiếu bán hàng

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/write | GetSalesReceiptQuery; GenerateSalesReceiptCommand; RecordSalesReceiptPrintedCommand; RecordSalesReceiptSharedCommand; ArchiveSalesReceiptCommand | SalesReceiptDto | sales.receipt.view; sales.receipt.generate; sales.receipt.print; sales.receipt.share; sales.receipt.archive | same as S14 | sales.get_sales_receipt; sales.generate_sales_receipt; sales.record_sales_receipt_activity | NOT_FOUND; PERMISSION_DENIED; PROJECTION_PENDING; DATA_SCOPE_DENIED |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e03_u05_scn01_xem_receipt_hien_hanh` | SCN-01 — Xem receipt hiện hành |
| `e03_u05_scn02_sinh_receipt_khi_chua_co` | SCN-02 — Sinh receipt khi chưa có |
| `e03_u05_scn03_xem_nhieu_version` | SCN-03 — Xem nhiều version |
| `e03_u05_scn04_in_lai_receipt` | SCN-04 — In lại receipt |
| `e03_u05_scn05_chia_se_receipt` | SCN-05 — Chia sẻ receipt |
| `e03_u05_scn06_receipt_generation_that_bai` | SCN-06 — Receipt generation thất bại |
| `e03_u05_scn07_product_master_da_doi_ten` | SCN-07 — Product master đã đổi tên |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** Order slip preview/print/share reuses Group E receipt handlers (`SalesReceiptOperationHandler` + `SalesOrderSlipPreviewPage`). Drafts `010` unpromoted/unapplied; E2E `blocked`.

## §S20 — [EP-03/US-06](../Epic-03-order-inquiry-and-tracking/US-06.md) — Theo dõi trạng thái xử lý liên quan

**State:** `deferred` (option B reactive) — product spec retained; implementation stub only.

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read (stub) | GetOrderIntegrationStatusQuery | OrderIntegrationStatusDto (`notRequired` per target) | sales.integration.view_sync_status | read only | `sales.get_order_integration_status` (SQL stub) | NOT_FOUND; PERMISSION_DENIED |

**Withdrawn / deferred from active contract:** `GetIntegrationCommandStatusQuery`, `GetImpactRequestStatusQuery`, `RetryIntegrationCommand`, `RetryInventoryImpact`, `RetryReceivableImpact`, `RetryEInvoiceImpact`, `ReconcileIntegrationResultCommand`, `sales.retry_integration_command`, `sales.reconcile_integration_result` — FR-05+ retry/reconcile **not implemented** until owner themes (TH-06/07/08) emit consumable outcomes + thin Sales projection slice.

### Fake scenarios

Product scenarios (SCN-01–07) remain canonical for future slice; fakes today return stub `notRequired` only.

**Current implementation (2026-09):** `sales.get_order_integration_status` SQL stub returns `notRequired` for inventory/receivable/e-invoice. No impact/command rows at Sales. Real integration UI deferred — see harness [01-domain-model §9.2](01-domain-model.md#92-cross-module-handoff--deferred-not-sales-owned-in-current-phase).

## §S21 — [EP-03/US-07](../Epic-03-order-inquiry-and-tracking/US-07.md) — Khởi tạo thao tác sau bán

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/entry | GetAvailablePostSaleActionsQuery; PrecheckSalesOrderCancellationQuery; PrecheckReturnExchangeQuery | AvailablePostSaleActionsDto | sales.order.cancel; sales.return_exchange.create; sales.order.view | available-actions advisory; authoritative prechecks on later owners | sales.get_available_post_sale_actions; sales.precheck_sales_order_cancellation; sales.precheck_return_exchange | NOT_FOUND; PERMISSION_DENIED; PROJECTION_PENDING; DATA_SCOPE_DENIED |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e03_u07_scn01_mo_flow_dieu_chinh` | ~~SCN-01 — Mở flow điều chỉnh~~ **superseded** (EP-04) |
| `e03_u07_scn02_mo_flow_huy_don` | SCN-02 — Mở flow hủy đơn |
| `e03_u07_scn03_mo_flow_doi_tra` | SCN-03 — Mở flow đổi trả |
| `e03_u07_scn04_khong_co_quyen` | SCN-04 — Không có quyền |
| `e03_u07_scn05_state_thay_doi_sau_khi_action_hien_thi` | SCN-05 — State thay đổi sau khi action hiển thị |
| `e03_u07_scn06_huy_flow_sau_ban` | SCN-06 — Hủy flow sau bán |
| `e03_u07_scn07_quay_lai_sau_nghiep_vu_thanh_cong` | SCN-07 — Quay lại sau nghiệp vụ thành công |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-12):** Detail action bar/sheet loads `GetAvailablePostSaleActionsQuery`. Before navigation, FE runs authoritative owner prechecks for cancellation/return. **Adjust / EP-04 removed from available-actions.** Drafts remain unpromoted/unapplied; E2E `blocked`.

## §S22 — [EP-04/US-01](../Epic-04-post-sale-order-adjustments/US-01.md) — Cập nhật ghi chú đơn hàng

**State:** `superseded` / withdrawn — out of scope; implementation removed (CQRS, RPC, SG-09, `sales.order.adjust`, `order_adjustments`).

Historical contract (no longer active):

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/write | ~~PrecheckOrderAdjustmentQuery; ApplyOrderAdjustmentCommand; GetOrderAdjustmentHistoryQuery~~ | ~~OrderAdjustment*Dto~~ | ~~sales.order.adjust~~ | — | ~~sales.precheck_order_adjustment; sales.apply_order_adjustment; sales.get_order_adjustment_history~~ | — |

Product US kept for history under Epic-04. Do not re-implement without explicit theme scope reopen.

## §S23 — [EP-05/US-01](../Epic-05-post-sale-order-cancellation/US-01.md) — Kiểm tra điều kiện và tác động hủy đơn

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | validation/read | PrecheckSalesOrderCancellationQuery; GetSalesOrderSettlementQuery; GetReturnExchangeOrdersBySalesOrderQuery | CancellationPrecheckDto | sales.order.cancel; sales.order.view | expectedVersion + live blockers | sales.precheck_sales_order_cancellation | CANCELLATION_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e05_u01_scn01_don_chua_co_tien_thuc_thu_rong` | SCN-01 — Đơn chưa có tiền thực thu ròng |
| `e05_u01_scn02_don_da_co_tien_thuc_thu` | SCN-02 — Đơn đã có tiền thực thu |
| `e05_u01_scn03_khoan_thu_da_duoc_hoan_hoac_void_day_du` | SCN-03 — Khoản thu đã được hoàn hoặc void đầy đủ |
| `e05_u01_scn04_don_da_bi_huy` | SCN-04 — Đơn đã bị hủy |
| `e05_u01_scn05_co_phieu_doi_tra_da_xac_nhan` | SCN-05 — Có phiếu đổi trả đã xác nhận |
| `e05_u01_scn06_co_phieu_doi_tra_draft` | SCN-06 — Có phiếu đổi trả draft |
| `e05_u01_scn07_don_con_khoan_phai_thu_chua_thu` | SCN-07 — Đơn còn khoản phải thu chưa thu |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `SalesOrderCancellation` + `CancellationPrecheckSnapshot` / `CancellationMustPassPrecheckRule`; `PrecheckSalesOrderCancellationQueryHandler`; `GetReturnExchangeOrdersBySalesOrderQueryHandler` (adapts frozen return-conflict query onto `ISalesOrderInquiryGateway.getReturnSummary`); `ISalesOrderCancellationGateway`; `SalesOrderCancellationRpcMapper`; `SupabaseSalesOrderCancellationGateway`; generated Sales CQRS/access wiring; draft-only `supabase/migrations/_drafts/011_sales_adjustment_cancellation_rpcs.sql` (`sales.precheck_sales_order_cancellation` is read-only — no insert/update/delete).
- SCN-01 (`e05_u01_scn01_don_chua_co_tien_thuc_thu_rong`): SQL net-collection formula + ready precheck envelope; domain `isConfirmable` with zero net; mapper/gateway ready decode in `sales_order_cancellation_rpc_mapper_test.dart` / `supabase_sales_order_cancellation_gateway_test.dart`; application owner-gateway routing in `group_h_cancellation_test.dart`.
- SCN-02 (`e05_u01_scn02_don_da_co_tien_thuc_thu`): SQL blocker `PAYMENT_ALREADY_COLLECTED`; domain rejects positive `netConfirmedCollectionMinor`; mapper blocked-precheck decode.
- SCN-03 (`e05_u01_scn03_khoan_thu_da_duoc_hoan_hoac_void_day_du`): SQL net formula subtracts `refunded_total_minor` / `voided_total_minor` so fully reversed collections can become confirmable without inventing refunds in EP-05.
- SCN-04 (`e05_u01_scn04_don_da_bi_huy`): SQL blocker `ORDER_ALREADY_CANCELLED`; domain completed cancellation cannot re-confirm (`postsale_aggregate_test.dart`).
- SCN-05 (`e05_u01_scn05_co_phieu_doi_tra_da_xac_nhan`): SQL blocker `RETURN_EXCHANGE_CONFLICT`; S23 adapter handler + inquiry return-summary evidence in `group_h_cancellation_test.dart`.
- SCN-06 (`e05_u01_scn06_co_phieu_doi_tra_draft`): SQL blocker `DRAFT_RETURN_ACTIVE` over Sales-owned return/exchange stub rows.
- SCN-07 (`e05_u01_scn07_don_con_khoan_phai_thu_chua_thu`): unpaid receivable is not a payment-collection blocker; confirm still emits receivable impact request when needed (see §S25/§S26), while precheck remains read-only.
- Permission-before-gateway for `sales.order.cancel` / `sales.return_exchange.view` is covered in `group_h_cancellation_test.dart`; SQL also enforces actor/store scope. Live E2E remains blocked: draft-only SQL, unresolved authoritative store-scope ownership, and unpromoted/unapplied rebuild drafts `008`/`011`/`015`.

## §S24 — [EP-05/US-02](../Epic-05-post-sale-order-cancellation/US-02.md) — Xác định lý do hủy

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales + provider owner | validation/runtime | PrecheckSalesOrderCancellationQuery; ConfirmSalesOrderCancellationCommand | CancellationReasonDto | sales.order.cancel | reason included in canonical payload hash | n/a — reason capture before confirm RPC | CANCELLATION_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Contract correction — 2026-09-09

Cancellation uses optional free-text `reason` only. `CancellationReasonDto.reasonText`
uses `''` for absent text; domain/factory trim whitespace. There is no reason code
in the confirm command, canonical payload hash or cancellation row. The UI hides
the entire reason card when text is empty. Existing reason text is preserved;
legacy codes are never used as display fallback.

The original promoted migrations are updated directly: schema owner
`20260830005_sales_rebuild_schema.sql` omits `reason_code` from cancellation DDL;
`20260830011_sales_adjustment_cancellation_rpcs.sql` and final confirm owner
`20260904001_sales_normalize_outbox_and_commands.sql` remove the confirm
`reason_code` parameter and its validation/storage. Detail returns
`reason: {reasonText}` using only stored `reason`. Grants match the new signature.
No additional migration or draft is retained. Database application is handled
by the maintainer; editing migration sources does not update an existing DB.
Read mapping tolerates and ignores `reasonCode` from older servers.
The legacy reason-catalog query remains available for compatibility, but is not
used by the current free-text cancellation UI. Historical SCN-02/03 code-based
requirements below are superseded: empty/whitespace reason is now accepted.

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e05_u02_scn01_chon_ly_do_hop_le` | SCN-01 — Chọn lý do hợp lệ |
| `e05_u02_scn02_ly_do_khac_yeu_cau_mo_ta` | SCN-02 — Lý do Khác yêu cầu mô tả |
| `e05_u02_scn03_reason_note_chi_co_khoang_trang` | SCN-03 — Reason note chỉ có khoảng trắng |
| `e05_u02_scn04_khong_hien_thi_phuong_an_hoan_tien` | SCN-04 — Không hiển thị phương án hoàn tiền |
| `e05_u02_scn05_settlement_thay_doi_sau_precheck` | SCN-05 — Settlement thay đổi sau precheck |
| `e05_u02_scn06_phat_sinh_tien_thuc_thu_moi` | SCN-06 — Phát sinh tiền thực thu mới |
| `e05_u02_scn07_huy_flow` | SCN-07 — Hủy flow |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `CancellationReason.create` normalization; `ConfirmSalesOrderCancellationCommandValidator` (pipeline-only); confirm command reason fields wired through mapper/gateway; default reason catalog and confirm reason guards in `011_sales_adjustment_cancellation_rpcs.sql`. There is **no** separate S24 mutation/RPC — reason validation rides on S25 confirm.
- **BE–FE integration (2026-08-13, updated 2026-08-17):** added an authoritative reason-catalog **read** contract so SG-10 no longer hardcodes reasons — `ListSalesOrderCancellationReasonsQuery` → `List<CancellationReasonPolicyDto>{reasonCode, displayName, requiresNote, sortOrder}` via `ISalesOrderCancellationGateway.listReasons` (permission `sales.order.cancel`, tenant-scoped). RPC `sales.list_sales_order_cancellation_reasons` is owned by draft `011` and returns the default catalog ordered by `sort_order, reason_code`; no Sales table backs this catalog in the current flow.
- SCN-01 (`e05_u02_scn01_chon_ly_do_hop_le`): domain normalized reason + confirmation evidence; validator accepts nonblank code; SQL accepts the provided reason code without policy-table lookup.
- SCN-02 (`e05_u02_scn02_ly_do_khac_yeu_cau_mo_ta`): domain + validator require nonblank `OTHER` note (`postsale_aggregate_test.dart`, `group_h_cancellation_test.dart`); SQL also requires note when `reason_code = 'OTHER'`.
- SCN-03 (`e05_u02_scn03_reason_note_chi_co_khoang_trang`): trim/reject blank-only note for `OTHER` in domain and validator.
- SCN-04 (`e05_u02_scn04_khong_hien_thi_phuong_an_hoan_tien`): EP-05 is refund-free — SQL contract forbids `refund_treatment` and `insert into sales.sales_payment_transactions`; confirm creates cancellation + impact request + `integration_commands` + lifecycle outbox fact only.
- SCN-05 (`e05_u02_scn05_settlement_thay_doi_sau_precheck`): confirm carries `expected_settlement_version`; SQL/gateway preserve `STALE_VERSION`.
- SCN-06 (`e05_u02_scn06_phat_sinh_tien_thuc_thu_moi`): authoritative confirm re-evaluates net collection and returns `PAYMENT_ALREADY_COLLECTED` / `CANCELLATION_BLOCKED`.
- SCN-07 (`e05_u02_scn07_huy_flow`): abandoning the flow performs no BE write until confirm; only the confirm command mutates via gateway/RPC.
- Live E2E remains blocked by the same draft/store-scope/owner-contract reasons as §S23.

## §S25 — [EP-05/US-03](../Epic-05-post-sale-order-cancellation/US-03.md) — Xác nhận hủy toàn bộ đơn hàng

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | orchestration/write | ConfirmSalesOrderCancellationCommand; CancelSalesOrderCommand; GetSalesOrderCancellationQuery | SalesOrderCancellationResultDto | sales.order.cancel | idempotency key + expectedVersion required | sales.confirm_sales_order_cancellation; sales.get_sales_order_cancellation | CANCELLATION_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e05_u03_scn01_xac_nhan_huy_thanh_cong` | SCN-01 — Xác nhận hủy thành công |
| `e05_u03_scn02_retry_cung_payload` | SCN-02 — Retry cùng payload |
| `e05_u03_scn03_cung_key_nhung_payload_khac` | SCN-03 — Cùng key nhưng payload khác |
| `e05_u03_scn04_phat_sinh_tien_thuc_thu_sau_precheck` | SCN-04 — Phát sinh tiền thực thu sau precheck |
| `e05_u03_scn05_version_conflict` | SCN-05 — Version conflict |
| `e05_u03_scn06_lifecycle_command_dang_xu_ly` | SCN-06 — Lifecycle command đang xử lý |
| `e05_u03_scn07_downstream_delivery_that_bai` | SCN-07 — Downstream delivery thất bại |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `ConfirmSalesOrderCancellationCommandHandler` + validator; `ISalesOrderCancellationGateway.confirm`; mapper/gateway confirm wire; domain confirmation evidence + no reopen; draft-only `sales.confirm_sales_order_cancellation` (advisory lock → idempotency → row lock → atomic cancellation + `lifecycle_status = cancelled` + conditional inventory/receivable impact handoffs via `sales.enqueue_impact_handoff` (impact request + `integration_commands` only) + lifecycle outbox fact `sales_order_cancelled.v1`; no payment/refund inserts; **no new E-invoice impact writes**). Normalized RPC body authority: draft `016_sales_normalize_outbox_and_commands.sql` (contract correction / normalize 2026-09-04).
- SCN-01 (`e05_u03_scn01_xac_nhan_huy_thanh_cong`): application confirm delegates once (`group_h_cancellation_test.dart`); mapper/gateway success envelopes; SQL atomic insert/update + lifecycle outbox path.
- SCN-02 (`e05_u03_scn02_retry_cung_payload`): SQL same-key/same-hash replay returns committed result; gateway preserves committed mapping.
- SCN-03 (`e05_u03_scn03_cung_key_nhung_payload_khac`): SQL/gateway `IDEMPOTENCY_CONFLICT`.
- SCN-04 (`e05_u03_scn04_phat_sinh_tien_thuc_thu_sau_precheck`): confirm-time zero-net recheck → `PAYMENT_ALREADY_COLLECTED` / `CANCELLATION_BLOCKED`.
- SCN-05 (`e05_u03_scn05_version_conflict`): expected order/settlement version guards → `STALE_VERSION` (SQL + gateway stable-code allow-list).
- SCN-06 (`e05_u03_scn06_lifecycle_command_dang_xu_ly`): competing/in-flight cancellation surfaces via `COMPETING_CANCELLATION` / processing result statuses; mapper decodes `processing`.
- SCN-07 (`e05_u03_scn07_downstream_delivery_that_bai`): order remains `cancelled`; impacts may be pending/failed; domain has no reopen transition; §S26 draft forbids reopening lifecycle from retry/reconcile.
- Inventory/receivable effects are Sales-owned impact requests + initial `integration_commands` (`version=1`/`queued`/`attempt=0`/`max=5`; `sales.inventory.apply_impact.v1` / `sales.receivable.apply_impact.v1`) — **no** typed impact outbox; no cross-owner table writes; impact business status stays `pending` (no fake `accepted`). Command payload field catalog same as §S12 table. Lifecycle/reporting facts use canonical names (e.g. `sales_order_cancelled.v1`, `sales_reporting_cancellation_recorded.v1`). Cancellation **does not wait** for owner acceptance. E-invoice write deferred; read fallback `notRequired`. Live E2E remains `todo`: draft-only SQL + unpromoted/unapplied rebuild drafts `008`/`011`/`015`/`016`; live owner consumption awaits canonical TH-06/TH-07.

## §S26 — [EP-05/US-04](../Epic-05-post-sale-order-cancellation/US-04.md) — Theo dõi các tác động hoàn nguyên

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/technical write | GetOrderIntegrationStatusQuery; RetryIntegrationCommand; RetryInventoryImpactCommand; RetryReceivableImpactCommand; RetryEInvoiceImpactCommand; ReconcileIntegrationResultCommand | CancellationImpactStatusDto | sales.integration.view_sync_status | retry/reconcile idempotent | sales.get_order_integration_status; sales.retry_integration_command | CANCELLATION_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e05_u04_scn01_xem_impact_summary_sau_huy` | SCN-01 — Xem impact summary sau hủy |
| `e05_u04_scn02_hoan_nguyen_khoan_phai_thu_chua_thu` | SCN-02 — Hoàn nguyên khoản phải thu chưa thu |
| `e05_u04_scn03_khong_co_cong_no_can_hoan_nguyen` | SCN-03 — Không có công nợ cần hoàn nguyên |
| `e05_u04_scn04_yeu_cau_hoan_nguyen_ton_kho` | SCN-04 — Yêu cầu hoàn nguyên tồn kho |
| `e05_u04_scn05_dao_pricing_commitment` | SCN-05 — Đảo pricing commitment |
| `e05_u04_scn06_retry_delivery_that_bai` | SCN-06 — Retry delivery thất bại |
| `e05_u04_scn07_downstream_that_bai_khong_mo_lai_don` | SCN-07 — Downstream thất bại không mở lại đơn |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: thin `RetryInventoryImpactCommandHandler` / `RetryReceivableImpactCommandHandler` / `RetryEInvoiceImpactCommandHandler`; `ISalesIntegrationGateway` typed retries; `SalesIntegrationRpcMapper` typed params (`impact_kind` + `impact_request_id`); `SupabaseSalesIntegrationGateway` typed RPC calls; reused Group F `GetOrderIntegrationStatusQuery` / generic retry/reconcile handlers; draft-only `supabase/migrations/_drafts/015_sales_integration_rpcs.sql` replacing `sales.retry_integration_command` / `sales.reconcile_integration_result` (draft-only, not applied).
- SCN-01 (`e05_u04_scn01_xem_impact_summary_sau_huy`): Group F integration status read envelope reused; confirm SQL seeds impact rows/`not_required` markers consumed by status projection.
- SCN-02 (`e05_u04_scn02_hoan_nguyen_khoan_phai_thu_chua_thu`): confirm emits receivable impact request; typed `retryReceivable` routes exact kind (`group_f_integration_test.dart`, gateway typed wire tests).
- SCN-03 (`e05_u04_scn03_khong_co_cong_no_can_hoan_nguyen`): confirm SQL can mark impacts `not_required` when no reversal is needed.
- SCN-04 (`e05_u04_scn04_yeu_cau_hoan_nguyen_ton_kho`): inventory impact request + typed `retryInventory` routing/SQL kind lookup.
- SCN-05 (`e05_u04_scn05_dao_pricing_commitment`): confirm may enqueue pricing reverse via `integration_commands` and/or publish reporting lifecycle fact `sales_reporting_cancellation_recorded.v1` without writing Pricing owner tables.
- SCN-06 (`e05_u04_scn06_retry_delivery_that_bai`): technical retry allowlist (`failed`/`uncertain`/`deadLetter`) inserts outbox retry only (`retryScheduled`); business rejection cannot be retried (`BUSINESS_REJECTION`); reconcile records owner result without mutating original payload; typed retries remain idempotent and cannot insert new `*_impact_requests`.
- SCN-07 (`e05_u04_scn07_downstream_that_bai_khong_mo_lai_don`): impact SQL contract asserts no `lifecycle_status = 'completed'` reopen and no `update sales.sales_orders` from retry/reconcile; domain completed cancellation cannot re-confirm.
- **Durable handoff (2026-08-26; contract correction / normalize 2026-09-04):** pending backlog + latest command `created`/`queued`/`sent` → retry returns `IMPACT_PENDING` (no new delivery rows). Status read shows business `pending` / delivery `queued`. Handoff command names: `sales.inventory.apply_impact.v1` / `sales.receivable.apply_impact.v1` (same payload field catalog as §S12); **no** typed impact outbox. Draft `016_sales_normalize_outbox_and_commands.sql` is authority for normalized RPC bodies. E-invoice write deferred; read `notRequired`. E2E remains `todo` — no owner consumer; drafts unpromoted.

## §S27 — [EP-05/US-05](../Epic-05-post-sale-order-cancellation/US-05.md) — Xem kết quả và lịch sử hủy đơn

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read | GetSalesOrderCancellationQuery; GetSalesOrderDetailQuery; GetSalesOrderTimelineQuery; GetSalesOrderPaymentSummaryQuery; GetOrderIntegrationStatusQuery | SalesOrderCancellationDetailDto | sales.order.view; sales.order.history.view; sales.payment.view; sales.receipt.view; sales.integration.view_sync_status | read only | sales.get_sales_order_cancellation; sales.get_sales_order_timeline | CANCELLATION_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e05_u05_scn01_xem_ket_qua_huy_thanh_cong` | SCN-01 — Xem kết quả hủy thành công |
| `e05_u05_scn02_khong_phat_sinh_hoan_tien_trong_ep_05` | SCN-02 — Không phát sinh hoàn tiền trong EP-05 |
| `e05_u05_scn03_xem_commercial_snapshot_goc` | SCN-03 — Xem commercial snapshot gốc |
| `e05_u05_scn04_xem_timeline_huy` | SCN-04 — Xem timeline hủy |
| `e05_u05_scn05_xem_receipt_cua_don_da_huy` | SCN-05 — Xem receipt của đơn đã hủy |
| `e05_u05_scn06_tao_don_moi` | SCN-06 — Tạo đơn mới |
| `e05_u05_scn07_projection_dang_cap_nhat` | SCN-07 — Projection đang cập nhật |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

**BE–FE integration (2026-08-13):** `SalesOrderCancellationDetailDto` extended with `cancelledByActorId` (historical actor id, shown as-is — no IAM join/fabricated name) and `netConfirmedCollectionMinor` (authoritative decision-row value; `0` for a valid refund-free cancellation). Both are returned in place by `sales.get_sales_order_cancellation` (draft `011`, single-owner). SG-08 composes an independent cancellation section: `NOT_FOUND`/`IMPACT_PENDING` → projection-pending without discarding core; no refund status/action.

### BE evidence and scenario closure

- Artifacts: `GetSalesOrderCancellationQueryHandler`; `ISalesOrderCancellationGateway.getDetail`; mapper/gateway nested `{ result, reason, cancelledAt }` envelope; draft-only `sales.get_sales_order_cancellation`; commercial/payment/timeline/receipt/integration history reused from Group E/F inquiry and receipt surfaces (no duplicate owner RPCs).
- SCN-01 (`e05_u05_scn01_xem_ket_qua_huy_thanh_cong`): application detail permission-before-gateway + single delegation (`group_h_cancellation_test.dart`); mapper/gateway/SQL detail success envelopes.
- SCN-02 (`e05_u05_scn02_khong_phat_sinh_hoan_tien_trong_ep_05`): detail/reason envelope has no refund treatment; confirm SQL never inserts payment/refund rows.
- SCN-03 (`e05_u05_scn03_xem_commercial_snapshot_goc`): reused `GetSalesOrderDetailQuery` / Group F inquiry detail evidence preserves original commercial snapshot after cancel.
- SCN-04 (`e05_u05_scn04_xem_timeline_huy`): reused `GetSalesOrderTimelineQuery` / Group F timeline evidence for cancellation history events.
- SCN-05 (`e05_u05_scn05_xem_receipt_cua_don_da_huy`): reused Group E/F receipt read/generate surface for cancelled orders.
- SCN-06 (`e05_u05_scn06_tao_don_moi`): navigation to a new working order is presentation/runtime; BE cancellation lane does not reopen the cancelled order and does not block creating a distinct new order.
- SCN-07 (`e05_u05_scn07_projection_dang_cap_nhat`): detail/result may remain `processing` while impacts catch up; gateway preserves `IMPACT_PENDING` / processing envelopes; integration status reads remain authoritative for pending projections.
- Live E2E remains blocked: draft-only Group H detail RPC, unreused live projections until Group D/H drafts are promoted/applied, and unresolved store-scope/owner contracts.

## §S28 — [EP-06/US-01](../Epic-06-returns-exchanges-and-settlement/US-01.md) — Khởi tạo phiếu đổi/trả từ đơn hàng gốc

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/write | PrecheckReturnExchangeQuery; GetReturnableOrderLinesQuery; StartReturnExchangeCommand | ReturnExchangeDraftDto | sales.return_exchange.create; sales.order.view | idempotent start | sales.precheck_return_exchange; sales.get_returnable_order_lines; sales.start_return_exchange | RETURN_EXCHANGE_BLOCKED; RETURN_QUANTITY_EXCEEDED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e06_u01_scn01_khoi_tao_flow_chuan` | SCN-01 — Khởi tạo flow chuẩn |
| `e06_u01_scn02_chuyen_tu_thao_tac_huy_da_bi_chan` | SCN-02 — Chuyển từ thao tác Hủy đã bị chặn |
| `e06_u01_scn03_don_da_huy` | SCN-03 — Đơn đã hủy |
| `e06_u01_scn04_cancellation_dang_xu_ly` | SCN-04 — Cancellation đang xử lý |
| `e06_u01_scn05_khong_con_hang_co_the_tra` | SCN-05 — Không còn hàng có thể trả |
| `e06_u01_scn06_quick_flow_chi_con_phan_chua_tra` | SCN-06 — Quick flow chỉ còn phần chưa trả |
| `e06_u01_scn07_retry_khoi_tao` | SCN-07 — Retry khởi tạo |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `PrecheckReturnExchangeQueryHandler`; `GetReturnableOrderLinesQueryHandler`; `StartReturnExchangeCommandHandler` + validator; `IReturnExchangeReadGateway` / `IReturnExchangeCommandGateway` / `IReturnExchangeReferencePort` (server-only Catalog/Pricing/Inventory decisions — never client-trusted); `ReturnExchangeRpcMapper`; `SupabaseReturnExchangeReadGateway` / `SupabaseReturnExchangeCommandGateway`; `UnavailableReturnExchangeReferencePort` fail-closed default; generated Sales CQRS/access wiring; draft-only `supabase/migrations/_drafts/012_sales_return_exchange_session_rpcs.sql`.
- **FE contract extension (2026-08-13, draft-only):** `GetReturnExchangeFormPolicyQuery` / `GetReturnExchangeDetailQuery` + DTOs; draft `012_sales_return_exchange_session_rpcs.sql` owns session RPCs including `sales.get_return_exchange_form_policy` + `sales.get_return_exchange_detail` (reason/condition/entrySource); valuation/settlement in `013`, confirm/complete in `014`. FE: `SalesReturnExchangeSessionCubit` (SG-11). **Do not claim live E2E** from unit/widget/SQL contract tests.
- **Policy catalogs removed (2026-09-07, re-baselined 2026-09-08):** promoted owners giữ signature/quyền của `sales.get_return_exchange_form_policy` nhưng trả `{"reasons":[],"conditions":[]}` (không fallback hardcode). `start`/`confirm` không còn validate membership vào `return_exchange_*_policy`. Context luôn `reservationIds: []`; `start`/`update` giữ input `reference_decision` nhưng không persist `return_exchange_reservation_refs`. Checkout không phụ thuộc `checkout_store_policies`; `iam.bootstrap_owner` không seed bảng đó. Cột reason/condition trên dòng trả và Dart contract giữ nguyên. Transaction đã apply thành công qua SQL Editor theo xác nhận người dùng; live smoke chưa chạy — xem `docs/operations/sales-remove-unused-policy-tables-verification.md`.
- Sign / frozen-field notes: public DTOs omit user `reason`/`condition`/`entrySource`; BE persists nullable server-derived evidence only (see §S34). Settlement difference sign is documented under §S32.
- SCN-01 (`e06_u01_scn01_khoi_tao_flow_chuan`): `group_i_session_test.dart` / `S29 start delegates ready reference decision to command gateway`; `sales_return_exchange_group_i_session_sql_contract_test.dart` / `start/update/cancel lock, compare idempotency hash, and keep technical draft only` (advisory lock + draft insert).
- SCN-02 (`e06_u01_scn02_chuyen_tu_thao_tac_huy_da_bi_chan`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `precheck enforces tenant/store scope, cancellation conflict, and remaining qty` (`COMPETING_CANCELLATION` over `sales.sales_order_cancellations`).
- SCN-03 (`e06_u01_scn03_don_da_huy`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `precheck enforces tenant/store scope, cancellation conflict, and remaining qty` — `lifecycle_status` must be `completed` else `RETURN_EXCHANGE_BLOCKED`.
- SCN-04 (`e06_u01_scn04_cancellation_dang_xu_ly`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `precheck enforces tenant/store scope, cancellation conflict, and remaining qty` — in-flight cancellations share `COMPETING_CANCELLATION` path.
- SCN-05 (`e06_u01_scn05_khong_con_hang_co_the_tra`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `precheck enforces tenant/store scope, cancellation conflict, and remaining qty` + `get_returnable subtracts confirmed/processing reserved return micros`.
- SCN-06 (`e06_u01_scn06_quick_flow_chi_con_phan_chua_tra`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `get_returnable subtracts confirmed/processing reserved return micros` (`returnableQuantity`); `group_i_session_test.dart` / `S28 get-returnable delegates to read gateway after permission`.
- SCN-07 (`e06_u01_scn07_retry_khoi_tao`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `start/update/cancel lock, compare idempotency hash, and keep technical draft only` (same-key/same-hash vs `IDEMPOTENCY_CONFLICT`).
- Live E2E blocked: draft-only Group I SQL, unavailable Inventory/Pricing/Receivable/E-invoice owners, unresolved store-scope ownership, unpromoted/unapplied drafts.

## §S29 — [EP-06/US-02](../Epic-06-returns-exchanges-and-settlement/US-02.md) — Ghi nhận hàng khách trả

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | read/write | GetReturnableOrderLinesQuery; UpdateReturnExchangeCommand; EvaluateReturnPricingImpactQuery | ReturnExchangeDraftDto | sales.return_exchange.update | expectedVersion required | sales.get_returnable_order_lines; sales.update_return_exchange | RETURN_EXCHANGE_BLOCKED; RETURN_QUANTITY_EXCEEDED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e06_u02_scn01_them_dong_tra_hop_le` | SCN-01 — Thêm dòng trả hợp lệ |
| `e06_u02_scn02_prefill_quick_full_return` | SCN-02 — Prefill quick full-return |
| `e06_u02_scn03_giam_quantity_lam_chuyen_sang_standard_return` | SCN-03 — Giảm quantity làm chuyển sang standard return |
| `e06_u02_scn04_chan_so_luong_vuot_kha_dung` | SCN-04 — Chặn số lượng vượt khả dụng |
| `e06_u02_scn05_lay_gia_tri_theo_commercial_snapshot` | SCN-05 — Lấy giá trị theo commercial snapshot |
| `e06_u02_scn06_khong_mac_dinh_hang_nhap_lai_kho_ban_duoc` | SCN-06 — Không mặc định hàng nhập lại kho bán được |
| `e06_u02_scn07_conflict_do_phieu_khac_hoan_tat` | SCN-07 — Conflict do phiếu khác hoàn tất |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: returned-line domain rules (`sourceOrderLineId` required, cumulative qty); `UpdateReturnExchangeCommandHandler` + validator; get-returnable + evaluate gateways; draft-only session/settlement RPCs.
- SCN-01 (`e06_u02_scn01_them_dong_tra_hop_le`): `group_i_session_test.dart` / `S29 update loads context then delegates ready decision`; `S29 returned product may appear only with a valid original line id`; `sales_return_exchange_group_i_session_sql_contract_test.dart` / `start/update/cancel lock, compare idempotency hash, and keep technical draft only` (line rewrite).
- SCN-02 (`e06_u02_scn02_prefill_quick_full_return`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `get_returnable subtracts confirmed/processing reserved return micros` (`returnableQuantity` prefill source).
- SCN-03 (`e06_u02_scn03_giam_quantity_lam_chuyen_sang_standard_return`): `postsale_aggregate_test.dart` / `updateLines aggregates repeated returned lines before enforcing remaining quantity` (draft remains mutable); **FE-only** mode switch to standard return presentation; BE keeps technical draft only.
- SCN-04 (`e06_u02_scn04_chan_so_luong_vuot_kha_dung`): `postsale_aggregate_test.dart` / `rejects over-return quantity`; `sales_return_exchange_group_i_session_sql_contract_test.dart` / `start/update/cancel lock, compare idempotency hash, and keep technical draft only` (`RETURN_QUANTITY_EXCEEDED`).
- SCN-05 (`e06_u02_scn05_lay_gia_tri_theo_commercial_snapshot`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `get_returnable subtracts confirmed/processing reserved return micros` (`originalUnitPrice` / `unit_price_minor`); `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` (`from sales.sales_order_lines`).
- SCN-06 (`e06_u02_scn06_khong_mac_dinh_hang_nhap_lai_kho_ban_duoc`): `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `confirm stores nullable reason/condition/entrySource and does not invent client fields` (no `sellable` / `available_for_sale` defaults).
- SCN-07 (`e06_u02_scn07_conflict_do_phieu_khac_hoan_tat`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `precheck enforces tenant/store scope, cancellation conflict, and remaining qty` + `start/update/cancel lock, compare idempotency hash, and keep technical draft only` (confirmed/processing/completed reduce remaining micros).
- Live E2E blocked as §S28.

## §S30 — [EP-06/US-03](../Epic-06-returns-exchanges-and-settlement/US-03.md) — Ghi nhận hàng khách nhận đổi

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | write | UpdateReturnExchangeCommand | ReturnExchangeDraftDto | sales.return_exchange.update | expectedVersion required | sales.update_return_exchange | RETURN_EXCHANGE_BLOCKED; RETURN_QUANTITY_EXCEEDED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e06_u03_scn01_them_dong_exchange_hop_le` | SCN-01 — Thêm dòng exchange hợp lệ |
| `e06_u03_scn02_gia_hien_hanh_duoc_ap_dung` | SCN-02 — Giá hiện hành được áp dụng |
| `e06_u03_scn03_product_khong_con_ban_duoc` | SCN-03 — Product không còn bán được |
| `e06_u03_scn04_khong_du_ton_kho` | SCN-04 — Không đủ tồn kho |
| `e06_u03_scn05_cap_nhat_quantity` | SCN-05 — Cập nhật quantity |
| `e06_u03_scn06_xoa_dong_exchange` | SCN-06 — Xóa dòng exchange |
| `e06_u03_scn07_chan_phieu_chi_co_hang_exchange` | SCN-07 — Chặn phiếu chỉ có hàng exchange |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: exchange-line rules (null `originalSalesOrderLineId`); update handler with `reserveExchangeStock=true`; server-only `reference_decision.exchange_pricing_by_product_unit_id`.
- SCN-01 (`e06_u03_scn01_them_dong_exchange_hop_le`): `group_i_session_test.dart` / `S29 exchange lines require null originalSalesOrderLineId`; `S29 update loads context then delegates ready decision`.
- SCN-02 (`e06_u03_scn02_gia_hien_hanh_duoc_ap_dung`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` (`exchange_pricing_by_product_unit_id` from `reference_decision`).
- SCN-03 (`e06_u03_scn03_product_khong_con_ban_duoc`): `group_i_session_test.dart` / `S29 reference blocker prevents command gateway calls` (`RETURN_EXCHANGE_BLOCKED` before update RPC).
- SCN-04 (`e06_u03_scn04_khong_du_ton_kho`): `group_i_session_test.dart` / `S30 inventory/catalog unavailable maps to RETURN_EXCHANGE_BLOCKED before update gateway` (`INVENTORY_UNAVAILABLE`).
- SCN-05 (`e06_u03_scn05_cap_nhat_quantity`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `start/update/cancel lock, compare idempotency hash, and keep technical draft only` (`STALE_VERSION` + line replace).
- SCN-06 (`e06_u03_scn06_xoa_dong_exchange`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `start/update/cancel lock, compare idempotency hash, and keep technical draft only` — `delete from sales.return_exchange_lines` then reinsert (empty exchange set allowed while returned lines remain).
- SCN-07 (`e06_u03_scn07_chan_phieu_chi_co_hang_exchange`): `postsale_aggregate_test.dart` / `confirm rejects exchange-only tickets without a returned line`.
- Live E2E blocked as §S28.

## §S31 — [EP-06/US-04](../Epic-06-returns-exchanges-and-settlement/US-04.md) — Giữ và bỏ thay đổi chưa xác nhận trong phiên đổi/trả

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | runtime | session working state; CancelReturnExchangeCommand (discard technical draft if any) | void / discarded | sales.return_exchange.create; sales.return_exchange.cancel | discard idempotent; no user draft list Phase 1 | sales.cancel_return_exchange (technical); n/a for pure session | RETURN_EXCHANGE_BLOCKED; STALE_VERSION; IDEMPOTENCY_CONFLICT |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e06_u04_scn01_giu_working_state_giua_sg` | SCN-01 — Giữ working state giữa SG-10 và SG-11 |
| `e06_u04_scn02_confirmation_khi_thoat` | SCN-02 — Confirmation khi thoát flow có thay đổi |
| `e06_u04_scn03_tiep_tuc_giu_state` | SCN-03 — Tiếp tục giữ nguyên working state |
| `e06_u04_scn04_bo_thay_doi_release_reservation` | SCN-04 — Bỏ thay đổi xóa working state và release reservation |
| `e06_u04_scn05_khong_co_quan_ly_phieu_nhap` | SCN-05 — Phase 1 không có quản lý phiếu nháp |

Frozen evidence: documentation contract Phase 1 session discard; không expose user draft CRUD. Dart fakes synced (5 SCN). Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `CancelReturnExchangeCommandHandler` (release then cancel); domain idempotent technical discard; draft-only cancel + `return_exchange_reservation_release_requests`.
- SCN-01 (`e06_u04_scn01_giu_working_state_giua_sg`): **runtime/FE-only** — working state between SG-10/SG-11 is presentation session; BE exposes technical draft recovery only (no user draft list) — see SCN-05 SQL exclusion.
- SCN-02 (`e06_u04_scn02_confirmation_khi_thoat`): **runtime/FE-only** — exit confirmation sheet is presentation; BE mutation occurs only on explicit cancel/confirm commands.
- SCN-03 (`e06_u04_scn03_tiep_tuc_giu_state`): **runtime/FE-only** — continue keeps client working state; no BE discard.
- SCN-04 (`e06_u04_scn04_bo_thay_doi_release_reservation`): `group_i_session_test.dart` / `S31 cancel releases recorded reservations once then cancels`; `S31 cancel continues when release is unavailable after durable request`; `postsale_aggregate_test.dart` / `technical discard is idempotent and confirmed work cannot be discarded`; `sales_return_exchange_group_i_session_sql_contract_test.dart` / `start/update/cancel lock, compare idempotency hash, and keep technical draft only` (`return_exchange_reservation_release_requests`).
- SCN-05 (`e06_u04_scn05_khong_co_quan_ly_phieu_nhap`): `sales_return_exchange_group_i_session_sql_contract_test.dart` / `excludes user list/restore RPCs and foreign owner tables`.
- Live E2E blocked as §S28.

## §S32 — [EP-06/US-05](../Epic-06-returns-exchanges-and-settlement/US-05.md) — Xem giá trị và chênh lệch đổi/trả

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | validation/read | EvaluateReturnPricingImpactQuery; UpdateReturnExchangeCommand; GetSalesOrderSettlementQuery | ReturnExchangeValuationDto | sales.return_exchange.view; sales.return_exchange.update | valuation carries source versions | sales.evaluate_return_exchange_valuation | RETURN_EXCHANGE_BLOCKED; RETURN_QUANTITY_EXCEEDED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e06_u05_scn01_khach_phai_tra_them` | SCN-01 — Khách phải trả thêm |
| `e06_u05_scn02_doanh_nghiep_phai_hoan_tien` | SCN-02 — Doanh nghiệp phải hoàn tiền |
| `e06_u05_scn03_full_return_don_da_thanh_toan_du` | SCN-03 — Full return đơn đã thanh toán đủ |
| `e06_u05_scn04_full_return_don_thanh_toan_mot_phan` | SCN-04 — Full return đơn thanh toán một phần |
| `e06_u05_scn05_khong_phat_sinh_chenh_lech` | SCN-05 — Không phát sinh chênh lệch |
| `e06_u05_scn06_valuation_stale_do_settlement_thay_doi` | SCN-06 — Valuation stale do settlement thay đổi |
| `e06_u05_scn07_chua_tao_transaction` | SCN-07 — Chưa tạo transaction |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `ReturnExchangeValuation` / `ReturnExchangeSettlementPlan`; `EvaluateReturnPricingImpactQueryHandler` (permission → context → reference `reserve=false` → evaluate RPC); draft-only `013_sales_return_exchange_settlement_rpcs.sql`.
- **Sign convention (binding):** `settlementDifference = exchangeValue - returnValue` (`net_difference_minor = exchange_value_minor - return_value_minor`). Positive → collect / receivable create; negative → refund / receivable reverse; zero → balanced.
- SCN-01 (`e06_u05_scn01_khach_phai_tra_them`): `postsale_aggregate_test.dart` / `positive difference balances collect and receivable create`; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` (`exchange_value_minor - return_value_minor`); `group_i_valuation_settlement_test.dart` / `S32 evaluate loads context, calls reference with reserve=false, delegates once`.
- SCN-02 (`e06_u05_scn02_doanh_nghiep_phai_hoan_tien`): `postsale_aggregate_test.dart` / `negative difference balances refund and receivable reverse`; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact`.
- SCN-03 (`e06_u05_scn03_full_return_don_da_thanh_toan_du`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` — refund capacity via `net_confirmed_collection` / `least(...)` when fully paid.
- SCN-04 (`e06_u05_scn04_full_return_don_thanh_toan_mot_phan`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` — `least(v_net_difference_minor, v_net_confirmed_collection)` + receivable reverse remainder.
- SCN-05 (`e06_u05_scn05_khong_phat_sinh_chenh_lech`): `postsale_aggregate_test.dart` / `zero difference requires every component zero`.
- SCN-06 (`e06_u05_scn06_valuation_stale_do_settlement_thay_doi`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` (`STALE_VERSION`); `postsale_aggregate_test.dart` / `applyValuation stores plan and updateLines clears stale valuation evidence`.
- SCN-07 (`e06_u05_scn07_chua_tao_transaction`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` — `isNot(contains('insert into sales.sales_payment_transactions'))` and `isNot(contains('insert into sales.receivable_impact_requests'))`.
- Reuses Group F `GetSalesOrderSettlementQuery` for settlement context reads. Live E2E blocked as §S28.

## §S33 — [EP-06/US-06](../Epic-06-returns-exchanges-and-settlement/US-06.md) — Quyết toán chênh lệch đổi/trả

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales + Receivable owner | orchestration/write | RecordSalesPaymentCommand; RecordSalesRefundCommand; IReceivableImpactPort (Receivable-owned collection) | ReturnExchangeSettlementResultDto | sales.payment.record; sales.payment.refund | idempotency + expectedVersion required | sales.settle_return_exchange_difference (draft-only `013`); Receivable collection via durable impact request + later owner delivery | RETURN_EXCHANGE_BLOCKED; RETURN_QUANTITY_EXCEEDED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e06_u06_scn01_thu_them_toan_bo` | SCN-01 — Thu thêm toàn bộ |
| `e06_u06_scn02_hoan_tien_toan_bo` | SCN-02 — Hoàn tiền toàn bộ |
| `e06_u06_scn03_tra_toan_bo_don_da_thanh_toan_mot_phan` | SCN-03 — Trả toàn bộ đơn đã thanh toán một phần |
| `e06_u06_scn04_can_tru_cong_no_trong_doi_tra` | SCN-04 — Cấn trừ công nợ trong đổi trả |
| `e06_u06_scn05_chan_khach_le_dung_cong_no` | SCN-05 — Chặn Khách lẻ dùng công nợ |
| `e06_u06_scn06_khong_phat_sinh_tien` | SCN-06 — Không phát sinh tiền |
| `e06_u06_scn07_theme_6_tu_choi_impact` | SCN-07 — Theme 6 từ chối impact |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `RecordSalesPaymentCommandHandler` / `RecordSalesRefundCommandHandler` → `IReturnExchangeSettlementGateway`; `SupabaseReturnExchangeSettlementGateway`; draft-only `sales.settle_return_exchange_difference` (Sales payment/refund append + `sales.receivable_impact_requests` only — never `receivable.*` / `accounting.*` ledgers).
- SCN-01 (`e06_u06_scn01_thu_them_toan_bo`): `group_i_valuation_settlement_test.dart` / `S33 payment handler delegates exactly once to settlement gateway`; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `settle locks rows, appends transactions, tracks partial commit, no owner ledger` (`'collection'` path).
- SCN-02 (`e06_u06_scn02_hoan_tien_toan_bo`): `group_i_valuation_settlement_test.dart` / `S33 refund handler delegates exactly once to settlement gateway`; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `settle locks rows, appends transactions, tracks partial commit, no owner ledger` (`'refund'` path).
- SCN-03 (`e06_u06_scn03_tra_toan_bo_don_da_thanh_toan_mot_phan`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` (`least(...)`) + `settle locks rows, appends transactions, tracks partial commit, no owner ledger` (`refund_amount = least` / `receivable_reversal_amount`).
- SCN-04 (`e06_u06_scn04_can_tru_cong_no_trong_doi_tra`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `settle locks rows, appends transactions, tracks partial commit, no owner ledger` (`insert into sales.receivable_impact_requests` + `correlation_id`); `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `confirm auto-settle uses plan correlation and confirmation-context GUC`.
- SCN-05 (`e06_u06_scn05_chan_khach_le_dung_cong_no`): `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `evaluate stores valuation/plan with sign convention and no payment/impact` (walk-in) + `settle locks rows, appends transactions, tracks partial commit, no owner ledger` (`walk_in` / `customer_id is null` → `RETURN_EXCHANGE_BLOCKED`).
- SCN-06 (`e06_u06_scn06_khong_phat_sinh_tien`): `postsale_aggregate_test.dart` / `zero difference requires every component zero`; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `settle locks rows, appends transactions, tracks partial commit, no owner ledger` (`amount_minor is null or amount_minor <= 0` → `RETURN_EXCHANGE_BLOCKED`); `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `confirm auto-settle uses plan correlation and confirmation-context GUC` (`remainder_collect_minor > 0` / `remainder_refund_minor > 0` skip zero remainder).
- SCN-07 (`e06_u06_scn07_theme_6_tu_choi_impact`): Sales durable-request boundary only — `sales_return_exchange_group_i_settlement_sql_contract_test.dart` / `settle locks rows, appends transactions, tracks partial commit, no owner ledger` (`insert into sales.receivable_impact_requests`; forbids `receivable.*` / `accounting.*` ledgers); `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `complete requires accepted impacts and updates return projection only` (`IMPACT_PENDING`); `group_i_confirmation_test.dart` / `S34 complete passes gateway exceptions through unchanged`. **Owner Theme-6 BUSINESS_REJECTION delivery is runtime / blocked-by-TH-06-owner-contract** — no `BUSINESS_REJECTION` string exists in Sales/Group F tests (do not claim Group F reuse for that code).
- Live E2E blocked by TH-06 Receivable owner + draft-only settlement SQL + store-scope.

## §S34 — [EP-06/US-07](../Epic-06-returns-exchanges-and-settlement/US-07.md) — Xác nhận và theo dõi kết quả đổi/trả

**State:** `frozen`

| Owner | Type | Symbols | Success | Permission | Concurrency/idempotency | RPC target | Stable errors |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sales | orchestration/read | ConfirmReturnExchangeCommand; CompleteReturnExchangeCommand; GetSalesOrderReturnSummaryQuery; GetOrderIntegrationStatusQuery | ReturnExchangeResultDto | sales.return_exchange.confirm; sales.return_exchange.complete; sales.return_exchange.view; sales.integration.view_sync_status | idempotency key + expectedVersion required | sales.confirm_return_exchange; sales.complete_return_exchange; sales.get_sales_order_return_summary | RETURN_EXCHANGE_BLOCKED; RETURN_QUANTITY_EXCEEDED; STALE_VERSION; IDEMPOTENCY_CONFLICT; IMPACT_PENDING |

### Fake scenarios

| scenario_id | Canonical scenario |
| --- | --- |
| `e06_u07_scn01_xac_nhan_phieu_thanh_cong` | SCN-01 — Xác nhận phiếu thành công |
| `e06_u07_scn02_hoan_tat_nghiep_vu` | SCN-02 — Hoàn tất nghiệp vụ |
| `e06_u07_scn03_tra_mot_phan_don` | SCN-03 — Trả một phần đơn |
| `e06_u07_scn04_hoan_tat_full_return_tu_thao_tac_huy` | SCN-04 — Hoàn tất full return từ thao tác Hủy |
| `e06_u07_scn05_result_cua_don_thanh_toan_mot_phan` | SCN-05 — Result của đơn thanh toán một phần |
| `e06_u07_scn06_retry_cung_confirmation` | SCN-06 — Retry cùng confirmation |
| `e06_u07_scn07_downstream_inventory_failed` | SCN-07 — Downstream inventory failed |

Frozen evidence: public Dart contract + field catalog + permission/concurrency/error semantics + canonical fake scenarios; Appendix 6.1 was not inferred.

### BE evidence and scenario closure

- Artifacts: `ConfirmReturnExchangeCommandHandler` / `CompleteReturnExchangeCommandHandler` + validators; `ReturnExchangeConfirmationSnapshot`; `SalesOrderReturnStatusCalculator`; draft-only `014_sales_return_exchange_confirmation_rpcs.sql`; **reuses Group F** `GetSalesOrderReturnSummaryQuery` / integration status reads (`014` does not replace `sales.get_sales_order_return_summary`; summary remains on `010`).
- **Single-phase completion (2026-08-17 / handoff 2026-08-26; contract correction / normalize 2026-09-04):** `sales.confirm_return_exchange` finalizes to `completed` in one call (projection + lifecycle fact `return_exchange_completed.v1`) and **does not wait** for owner acceptance. Inventory/Receivable impacts use `sales.enqueue_impact_handoff`: `business_status = 'pending'`, initial command `version=1`/`queued`/`attempt=0`/`max=5`, `command_name` `sales.inventory.apply_impact.v1` / `sales.receivable.apply_impact.v1` (payload field catalog as §S12) — **no** typed impact outbox. Draft `016_sales_normalize_outbox_and_commands.sql` is authority for normalized RPC bodies. **E-invoice write deferred**; read fallback `notRequired`. `sales.complete_return_exchange` retained (gates on accepted impacts → `IMPACT_PENDING`) but unreachable in normal FE flow. Retry on pending+created/queued/sent → `IMPACT_PENDING`.
- Frozen limitation: reason/condition/entrySource are nullable server-only columns (GUC/correlation-derived); public DTOs unchanged — reopen CONTRACT before adding client fields.
- SCN-01 (`e06_u07_scn01_xac_nhan_phieu_thanh_cong`): `group_i_confirmation_test.dart` / `S34 confirm revalidates providers before command gateway`; `S34 confirm delegates exact ready decision and returns gateway result`; `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `confirm follows idempotency-before-mutation lock and revalidation order`.
- SCN-02 (`e06_u07_scn02_hoan_tat_nghiep_vu`): `group_i_confirmation_test.dart` / `S34 complete delegates once without provider revalidation`; `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `complete requires accepted impacts and updates return projection only` (no `update sales.sales_orders`).
- SCN-03 (`e06_u07_scn03_tra_mot_phan_don`): `postsale_aggregate_test.dart` / `same completed quantities calculate partiallyReturned or fullyReturned`; `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `complete requires accepted impacts and updates return projection only` (`'partially_returned'`).
- SCN-04 (`e06_u07_scn04_hoan_tat_full_return_tu_thao_tac_huy`): `postsale_aggregate_test.dart` / `full return status is independent from order lifecycle`; `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `complete requires accepted impacts and updates return projection only` (`'fully_returned'` without `lifecycle_status = 'cancelled'`).
- SCN-05 (`e06_u07_scn05_result_cua_don_thanh_toan_mot_phan`): `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `confirm auto-settle uses plan correlation and confirmation-context GUC` (remainder collect/refund + plan correlation).
- SCN-06 (`e06_u07_scn06_retry_cung_confirmation`): `group_i_confirmation_test.dart` / `S34 confirm same-result replay returns identical gateway DTO`; `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `confirm stores nullable reason/condition/entrySource and does not invent client fields` (plan correlation dedupe).
- SCN-07 (`e06_u07_scn07_downstream_inventory_failed`): `sales_return_exchange_group_i_confirmation_sql_contract_test.dart` / `complete requires accepted impacts and updates return projection only` (`IMPACT_PENDING` / `business_status`); `group_i_confirmation_test.dart` / `S34 complete passes gateway exceptions through unchanged` (`IMPACT_PENDING`); `group_f_integration_test.dart` / `S20 retry surfaces a gateway IMPACT_PENDING as SalesContractException` (pending/failed impact read reuse — not BUSINESS_REJECTION).
- Live E2E remains `todo`: draft-only confirmation SQL, unpromoted/unapplied rebuild drafts `012`–`014`, no owner consumer. No promoted migrations claimed.

## Contract freeze checklist

- [x] Input/output fields and nullability frozen from canonical/entity/UI/domain evidence (Phase 1 note-only + session return).
- [x] Permission constant and data scope frozen.
- [x] Version/idempotency/payload hash behavior frozen.
- [x] RPC params/result/error mapper frozen or explicitly contract-only / `n/a`.
- [x] Fake scenarios registered per slice section; Dart registry **234** IDs synced Phase 1.
- [x] Traceability CONTRACT rows point to harness §Sxx IDs S01–S34 after renumber.
- [x] Dart `modules/sales/application` symbols/fakes re-synced (note-only + session discard).
