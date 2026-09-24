# 07 — Hợp đồng kỹ thuật

## 1. Nguyên tắc tổ chức

Part 05 sở hữu Use Case; Part 06 sở hữu nghĩa dùng chung của BC. Part 07 chỉ khóa cách thực thi:

- mỗi BC có đúng một authoritative application handler;
- REST, event consumer, batch và UI là adapter;
- handler gọi domain aggregate/service và commit qua một transaction boundary được chỉ định;
- API/event không tự thêm một nhánh nghiệp vụ;
- trace ID ổn định nối BC, endpoint/event và test.

## 2. Common request/response contract

### 2.1 Headers

| Header | Bắt buộc | Ý nghĩa |
|---|---:|---|
| `Authorization` | Có | Identity/session token |
| `Idempotency-Key` | Có với mọi mutation | Stable command replay key; không phải `operation_request_id` |
| `X-Correlation-Id` | Có | Trace xuyên hệ thống; server sinh nếu thiếu từ trusted UI |
| `X-Source-Type` | Có với source-driven command | `PURCHASE`, `SALES`, `POS`, `ACCOUNTING`, `ADMIN`… |
| `X-Source-Version` | Có với source-driven command | Monotonic source version |
| `If-Match` | Có khi update aggregate mutable | Expected entity version/ETag |
| `X-Tenant-Id` | Theo auth architecture | Phải khớp token; không tin client nếu token đã scope tenant |

`store_id` và `warehouse_id` nằm trong command envelope/body. Phase 1 server validate đúng cặp mặc định; UI có thể không cho người dùng chọn.

Mọi mutation tạo/hoàn tất `CommandReceipt` theo `(tenant_id, command_type, Idempotency-Key)` trong cùng transaction với authoritative result. Inventory Operation còn nhận `operation_request_id` trong body/source identity; hai khóa được hash và quan sát độc lập.

Gate kỹ thuật cắt ngang, thực thi trước domain mutation:

| Gate | Kết quả từ chối |
|---|---|
| Inventory activation khác `ACTIVE` | `INVENTORY_NOT_ACTIVATED`; ngoại lệ chỉ cho opening prepare/commit và query được phép |
| Product `DISCONTINUED`, receipt không có continuation assertion/version hợp lệ | `PRODUCT_DISCONTINUED_FOR_RECEIPT` |
| Product `ARCHIVED` | `PRODUCT_ARCHIVED` cho mọi mutation |
| Sửa base UOM sau khi đã có movement | `BASE_UOM_IMMUTABLE` |

### 2.2 Success envelope

```json
{
  "data": {},
  "meta": {
    "correlation_id": "corr_...",
    "operation_id": "op_...",
    "status": "COMPLETED",
    "entity_version": 4,
    "ledger_sequence": 12501,
    "committed_at": "2026-08-15T10:00:00Z",
    "warnings": [],
    "recovery_guidance": {
      "effect_status": "COMMITTED",
      "user_message_key": "inventory.operation.completed",
      "preserve_input": false,
      "allowed_next_actions": [
        {"action_id": "ACT-01-REFRESH", "bc_id": "BC-IO-01", "kind": "QUERY"}
      ]
    }
  }
}
```

### 2.3 Error envelope

```json
{
  "error": {
    "code": "LOT_ATTRIBUTE_CONFLICT",
    "message": "Dữ liệu lô không khớp hồ sơ hiện có.",
    "fields": [{"path": "lines[2].expiry_date", "code": "MISMATCH"}],
    "retryable": false,
    "operation_id": "op_...",
    "current_status": "EXECUTION_REJECTED",
    "correlation_id": "corr_...",
    "recovery_guidance": {
      "effect_status": "NONE",
      "user_message_key": "inventory.lot.attribute_conflict",
      "preserve_input": true,
      "allowed_next_actions": [
        {"action_id": "ACT-10-SAVE-DRAFT", "bc_id": "BC-IO-16", "kind": "COMMAND"}
      ]
    }
  }
}
```

Message được địa phương hóa; `code` ổn định và không chứa dữ liệu nhạy cảm. `user_message_key` không quyết định logic. `effect_status` được suy ra từ bằng chứng finality: lỗi trước commit là `NONE`, kết quả đã commit là `COMMITTED`, còn chưa đủ bằng chứng là `UNKNOWN`.

Mỗi phần tử `allowed_next_actions` phải tham chiếu `Action ID + BC ID` đã tồn tại hoặc một query link được công bố trong API catalog. Server lọc theo permission, scope, lifecycle và capability boundary; client từ chối action không nhận diện được. Recovery metadata không được tạo endpoint, command, transition hoặc quyền mới.

## 3. HTTP/result semantics

| HTTP | Dùng khi |
|---:|---|
| `200` | Query hoặc idempotent retry trả kết quả đã có |
| `201` | Tạo aggregate/operation mới ở trạng thái hợp lệ |
| `202` | Batch/operation đang xử lý hoặc `UNKNOWN`; trả resource URL để poll |
| `400` | Payload/schema/business format invalid |
| `401` | Chưa xác thực |
| `403` | Thiếu permission/scope hoặc financial field forbidden |
| `404` | Resource không tồn tại trong tenant scope |
| `409` | Version/idempotency/lock/state/concurrency conflict |
| `422` | Business guard failed như thiếu tồn, sai lô, return cap |
| `423` | Inventory scope locked |
| `501` | Capability có contract nhưng ngoài phạm vi Phase 1; body có structured code |

Không dùng HTTP timeout của client làm bằng chứng operation thất bại. Client poll `GET /v1/inventory-operations/{operation_id}` hoặc retry cùng idempotency key.

## 4. BC realization matrix

| BC | Authoritative handler | Primary adapter | Transaction boundary | Event/result | Test prefix |
|---|---|---|---|---|---|
| `BC-IO-01` | `QueryInventoryAvailability` | `API-Q-01` — `GET /v1/inventory/availability` | Read snapshot/transactional read | Query result only | `TST-BC-IO-01` |
| `BC-IO-02` | `ReceivePurchasedGoods` | `API-C-02` — `POST /v1/inventory/receipts` | Operation + movement + `VALUATION_PENDING` balance + lot + receipt + outbox; no value movement | `EVT-IO-01 ReceiptRecorded` | `TST-BC-IO-02` |
| `BC-IV-01` | `ConfirmReceiptDirectCost` | `API-C-20` — `POST /v1/receipt-valuations/confirm` | Receipt valuation + value/state movement + balance + outbox | `EVT-IV-03 ReceiptValuationConfirmed` | `TST-BC-IV-01` |
| `BC-IO-03` | `ReserveOrderQuantity` | `API-C-03` — `POST /v1/reservations` | Reservation + ReservationBucket + outbox | `EVT-IO-02 ReservationChanged` | `TST-BC-IO-03` |
| `BC-IO-04` | `CompleteOnlinePosCheckout` | `API-C-04` — `POST /v1/pos-checkouts/inventory-completion` | Issue/value movement + balance + result + outbox | `EVT-IO-03 PosInventoryCompleted` | `TST-BC-IO-04` |
| `BC-IO-05` | `HandOverFulfillment` | `API-C-05` — `POST /v1/fulfillments/{id}/handover` | Active allocation set/version + reservation consume + issue/value + balance + outbox | `EVT-IO-04 FulfillmentHandedOver` | `TST-BC-IO-05` |
| `BC-IO-06` | `ReleaseOrReallocateReservation` | `API-C-06` — `POST /v1/reservations/{id}/release-or-reallocate` | Reservation + ReservationBucket + allocation release + outbox | `EVT-IO-05 ReservationChanged` | `TST-BC-IO-06` |
| `BC-IO-07` | `ReceiveCustomerReturn` | `API-C-07` — `POST /v1/customer-return-receipts` | Per-component cap/lot/value + receipt/value movement + balance + outbox, all-or-nothing | `EVT-IO-06 CustomerReturnReceived` | `TST-BC-IO-07` |
| `BC-IO-08` | `ClassifyCustomerReturn` | `API-C-08` — `POST /v1/customer-return-receipts/{id}/classifications` | State movements + balances + outbox | `EVT-IO-07 CustomerReturnClassified` | `TST-BC-IO-08` |
| `BC-IO-09` | `HandOverSupplierReturn` | `API-C-09` — `POST /v1/supplier-returns/{id}/handover` | State/issue/value + balances + outbox | `EVT-IV-01 SupplierReturnHandedOver` | `TST-BC-IO-09` |
| `BC-IC-01` | `OpenStockCount` | `API-C-14` — `POST /v1/stock-counts` | Session + materialized lines + locks | Synchronous result; không phát integration event Phase 1 | `TST-BC-IC-01` |
| `BC-IC-02` | `SubmitStockCount` | `API-C-15` — `POST /v1/stock-counts/{id}/submissions` | Session/line versions | Synchronous result; không phát integration event Phase 1 | `TST-BC-IC-02` |
| `BC-IC-03` | `ApproveCountAndAdjust` | `API-C-16` — `POST /v1/stock-counts/{id}/approval-decisions` | Approval + adjustment operation/movement/value + unlock | `EVT-IC-01 StockCountCompleted` | `TST-BC-IC-03` |
| `BC-IO-10` | `ChangeInventoryState` | `API-C-10` — `POST /v1/inventory/state-changes` | State movement + balances + reservation impact + outbox | `EVT-IO-08 InventoryStateChanged` | `TST-BC-IO-10` |
| `BC-IO-11` | `DisposeInventory` | `API-C-11` — `POST /v1/inventory/disposals` | Issue/value + balance + outbox | `EVT-IV-02 InventoryDisposed` | `TST-BC-IO-11` |
| `BC-IO-12` | `CancelInventoryOperation` | `API-C-12` — `POST /v1/inventory-operations/{id}/cancellation` | Operation state + locks/approval cleanup + outbox | `EVT-IO-09 OperationCancelled` | `TST-BC-IO-12` |
| `BC-IO-13` | `CorrectInventoryOperation` | `API-C-13` — `POST /v1/inventory-operations/{id}/corrections` | New operation + chain + delta movements/value + outbox | `EVT-IO-10 OperationCorrected` | `TST-BC-IO-13` |
| `BC-IC-04` | `CommitOpeningBalance` | `API-C-17` — `POST /v1/opening-balance-batches/{id}/commit` | Batch + opening quantity/value/cost + report + activation `PREPARING→ACTIVE` + outbox | `EVT-IC-02 OpeningBalanceCommitted` | `TST-BC-IC-04` |
| `BC-IV-02` | `CalculateInventoryCost` | `API-C-21` — `POST /v1/cost-calculation-runs` | Run snapshot/results only | Async run result | `TST-BC-IV-02` |
| `BC-IV-03` | `PublishInventoryCost` | `API-C-22` — `POST /v1/cost-calculation-runs/{id}/publication` | Adjustment batch/lines + value ledger + cost versions + outbox | `EVT-IV-04 OfficialCostPublished` | `TST-BC-IV-03` |
| `BC-IO-14` | `QueryLowStockSuggestions` | `API-Q-02` — `GET /v1/inventory/low-stock` | Read projection | Query result only | `TST-BC-IO-14` |
| `BC-IC-05` | `ReconcileAndRebuild` | `API-C-18` — `POST /v1/reconciliation-cases/{id}/resolution-runs` | Case/action/rebuild evidence; target mutation in controlled steps | `EVT-IC-03 ReconciliationResolved` | `TST-BC-IC-05` |
| `BC-IC-06` | `DecideApproval` | `API-C-19` — `POST /v1/approval-cases/{id}/decisions` | Approval case + operation state + outbox | `EVT-IC-04 ApprovalDecided` | `TST-BC-IC-06` |
| `BC-XD-01` | `CalculatePurchaseDiscountScenario` | External `API-X-01` — `POST /v1/purchase-discount-scenarios` | Scenario/version only; no inventory transaction | Synchronous calculation result; no inventory event | `TST-BC-XD-01` |
| `BC-XD-02` | `PublishPricingCostBasis` | External `API-X-02` — `POST /v1/pricing-cost-bases` | Pricing basis + draft only | `EVT-XD-01 PricingCostBasisPublished` | `TST-BC-XD-02` |
| `BC-XD-03` | `ApplyPricingBasisReview` | External `API-X-03` — `POST /v1/pricing-basis-reviews/{id}/decisions` | Review decisions + basis/drafts only | `EVT-XD-02 PricingBasisReviewApplied` | `TST-BC-XD-03` |
| `BC-XD-04` | `QueryMarginComparison` | `API-Q-03` — `GET /v1/inventory-reports/margin-comparison` | Consistent report snapshot | Query result only | `TST-BC-XD-04` |
| `BC-IV-04` | `RecordLateLandedCost` | `API-C-23` — `POST /v1/receipt-valuations/{id}/late-costs` | Natural-key receipt + adjustment/value + dirty scope + outbox | `EVT-IV-05 LateLandedCostRecorded` | `TST-BC-IV-04` |
| `BC-IO-15` | `SavePickAllocation` | `API-C-24` — `PUT /v1/fulfillments/{id}/pick-allocation` | Allocation set/version/lines only | Synchronous result | `TST-BC-IO-15` |
| `BC-IO-16` | `MaintainOperationDraft` | `API-C-25` — `POST /v1/inventory-operations`; `PUT /v1/inventory-operations/{id}` | Draft + lines + CommandReceipt | Synchronous result | `TST-BC-IO-16` |
| `BC-IC-07` | `SubmitInventoryOperation` | `API-C-26` — `POST /v1/inventory-operations/{id}/submission` | Payload lock + risk/policy + approval case + CommandReceipt | Synchronous result | `TST-BC-IC-07` |
| `BC-IC-08` | `CancelStockCount` | `API-C-27` — `POST /v1/stock-counts/{id}/cancellation` | Session cancel + lock release + CommandReceipt | `EVT-IC-05 StockCountCancelled` | `TST-BC-IC-08` |
| `BC-IC-09` | `PrepareOpeningBalanceBatch` | `API-C-28` — `POST /v1/opening-balance-batches`; `PUT /v1/opening-balance-batches/{id}` | Batch staging/version + validation/approval refs | Synchronous result | `TST-BC-IC-09` |
| `BC-XD-05` | `ConfigureInventoryProductPolicy` | External `API-X-04` — `PUT /v1/product-stock-policies/{product_id}` | Low-stock/near-expiry policy version; no inventory ledger | `EVT-XD-03 InventoryProductPolicyChanged` | `TST-BC-XD-05` |

External adapters are contract boundaries, not ownership claims. If modules are deployed together initially, namespace/handler owner vẫn phải giữ như bảng.

Ngoài các aggregate liệt kê, **mọi** transaction boundary của BC mutation trong ma trận đều bao gồm `CommandReceipt`; query không tạo receipt.

## 5. Resource/query API catalog

| ID | Method/path | Mục đích | Permission |
|---|---|---|---|
| `API-Q-01` | `GET /v1/inventory/availability` | Availability/status/lot | `inventory.view` |
| `API-Q-02` | `GET /v1/inventory/low-stock` | Low/out status + suggested qty | `inventory.view` |
| `API-Q-03` | `GET /v1/inventory-reports/margin-comparison` | Three margin views | `inventory.financial.view` |
| `API-Q-04` | `GET /v1/inventory-operations/{id}` | Operation state/result/timeline | `inventory.operation.view` + scope |
| `API-Q-05` | `GET /v1/inventory/stock-card` | Stock card at cut-off | `inventory.view` |
| `API-Q-06` | `GET /v1/inventory-reports/historical-stock` | Recorded/business-date views | `inventory.report.view` |
| `API-Q-07` | `GET /v1/lots/{id}` | Lot attributes/history | `inventory.view` |
| `API-Q-08` | `GET /v1/approval-cases` | Approval work queue | `inventory.approval.view` |
| `API-Q-09` | `GET /v1/reconciliation-cases` | Trust/reconciliation work queue | `inventory.reconciliation.view` |
| `API-Q-10` | `GET /v1/cost-calculation-runs/{id}` | Run/results/blockers | `inventory.cost.view` |

Pagination dùng cursor ổn định. Report/export ghi filters, timezone, view mode, cut-off/sequence và generated-at.

### 5.1 Query closure

| Query API | Owner/contract | Test bắt buộc |
|---|---|---|
| `API-Q-01` | `BC-IO-01` current availability | `TST-API-Q-01` |
| `API-Q-02` | `BC-IO-14` low-stock query | `TST-API-Q-02` |
| `API-Q-03` | `BC-XD-04` margin comparison | `TST-API-Q-03` |
| `API-Q-04` | Operation lifecycle common rule | `TST-API-Q-04` |
| `API-Q-05` | `BC-IO-01` stock-card view | `TST-API-Q-05` |
| `API-Q-06` | `BC-IO-01` historical dual-date view | `TST-API-Q-06` |
| `API-Q-07` | Lot aggregate read contract | `TST-API-Q-07` |
| `API-Q-08` | `BC-IC-06/07` approval work queue | `TST-API-Q-08` |
| `API-Q-09` | `BC-IC-05` reconciliation work queue | `TST-API-Q-09` |
| `API-Q-10` | `BC-IV-02/03` cost-run detail | `TST-API-Q-10` |

## 6. Event contract

### 6.1 Envelope

```json
{
  "event_id": "evt_...",
  "event_type": "inventory.official_cost.published.v1",
  "event_version": 1,
  "tenant_id": "t_...",
  "aggregate_type": "CostCalculationRun",
  "aggregate_id": "run_...",
  "aggregate_version": 3,
  "occurred_at": "2026-08-15T10:00:00Z",
  "business_date": "2026-08-15",
  "correlation_id": "corr_...",
  "causation_id": "op_or_command_...",
  "payload": {}
}
```

### 6.2 Delivery semantics

- Transactional outbox ghi cùng commit với aggregate/ledger result.
- Delivery at-least-once; producer retry cùng `event_id`; consumer inbox/dedup required.
- Ordering được bảo đảm theo aggregate version; không cam kết total order toàn tenant nếu không nêu rõ.
- Consumer nhận version cũ/duplicate trả ack idempotent; gap version được quarantine/retry/reconcile.
- Delivery failure không rollback operation; quá threshold tạo metric/work item.
- Schema backward-compatible trong cùng major event version; breaking change tạo `.v2` và migration window.

### 6.3 Event catalog tối thiểu

| Event ID | Type | Consumer chính |
|---|---|---|
| `EVT-IO-01` | `inventory.receipt.recorded.v1` | Purchase, reporting |
| `EVT-IV-03` | `inventory.receipt_valuation.confirmed.v1` | Accounting, sales availability |
| `EVT-IO-02` | `inventory.reservation.changed.v1` | Sales/fulfillment; reserve result |
| `EVT-IO-05` | `inventory.reservation.changed.v1` | Sales/fulfillment; release/reallocate result |
| `EVT-IO-03` | `inventory.pos_completion.completed.v1` | POS, accounting |
| `EVT-IO-04` | `inventory.fulfillment.handed_over.v1` | Sales, accounting |
| `EVT-IO-06` | `inventory.customer_return.received.v1` | Sales/accounting |
| `EVT-IO-07` | `inventory.customer_return.classified.v1` | Sales/accounting |
| `EVT-IV-01` | `inventory.supplier_return.handed_over.v1` | Purchase/accounting |
| `EVT-IC-01` | `inventory.stock_count.completed.v1` | Reporting/accounting |
| `EVT-IO-08` | `inventory.state.changed.v1` | Sales/reporting |
| `EVT-IV-02` | `inventory.disposal.completed.v1` | Accounting |
| `EVT-IO-09` | `inventory.operation.cancelled.v1` | Source system/accounting |
| `EVT-IO-10` | `inventory.operation.corrected.v1` | Source system/accounting |
| `EVT-IC-02` | `inventory.opening_balance.committed.v1` | Accounting/reporting |
| `EVT-IV-04` | `inventory.official_cost.published.v1` | Accounting/pricing/reporting |
| `EVT-IC-03` | `inventory.reconciliation.resolved.v1` | Operations/reporting |
| `EVT-IC-04` | `inventory.approval.decided.v1` | Requesting context |
| `EVT-XD-01` | `pricing.cost_basis.published.v1` | Pricing/sales; never inventory ledger mutation |
| `EVT-XD-02` | `pricing.basis_review.applied.v1` | Pricing/sales; never inventory ledger mutation |
| `EVT-IV-05` | `inventory.late_landed_cost.recorded.v1` | Accounting/valuation |
| `EVT-IC-05` | `inventory.stock_count.cancelled.v1` | Operations/reporting |
| `EVT-XD-03` | `product.inventory_policy.changed.v1` | Inventory read model/reporting |

### 6.4 Payload schema tối thiểu

Mọi payload ngoài envelope phải chứa đúng các reference dưới đây; ID list phải ổn định và amount/quantity luôn kèm currency/UOM khi áp dụng.

| Event | Required payload fields |
|---|---|
| `EVT-IO-01` | `operation_id`, `receipt_id`, `source_version`, `warehouse_id`, `line_ids`, `physical_delta`, `lot_ids`, `valuation_pending=true`; no official value fields |
| `EVT-IV-03` | `operation_id`, `receipt_valuation_id`, `receipt_line_ids`, `value_movement_ids`, `released_quantity`, `official_cost_version_id?` |
| `EVT-IO-02`, `EVT-IO-05` | `reservation_id`, `reservation_bucket_version`, `source_line_id`, `requested`, `reserved`, `shortage`, `status` |
| `EVT-IO-03` | `operation_id`, `checkout_id`, `issue_movement_ids`, `value_movement_ids`, `allocation_ids`, `initial_cogs` |
| `EVT-IO-04` | `operation_id`, `fulfillment_id`, `allocation_set_id`, `allocation_version`, `pick_allocation_ids`, `issue_movement_ids`, `reservation_ids`, `initial_cogs` |
| `EVT-IO-06` | `operation_id`, `return_receipt_id`, `component_results`, `original_issue_line_ids`, `quantity_movement_ids`, `value_movement_ids`, `original_period_ids` |
| `EVT-IO-07` | `operation_id`, `return_receipt_id`, `state_movement_ids`, `classification_totals` |
| `EVT-IV-01` | `operation_id`, `supplier_return_id`, `issue_movement_ids`, `value_movement_ids`, `supplier_approved_amount`, `difference_amount` |
| `EVT-IC-01` | `session_id`, `adjustment_operation_id`, `movement_ids`, `value_movement_ids`, `scope_hash`, `lock_released_at` |
| `EVT-IO-08` | `operation_id`, `movement_ids`, `from_state`, `to_state`, `reservation_impacts` |
| `EVT-IV-02` | `operation_id`, `disposal_id`, `issue_movement_ids`, `value_movement_ids`, `reason_code` |
| `EVT-IO-09` | `operation_id`, `source_identity`, `cancel_reason`, `cancelled_at` |
| `EVT-IO-10` | `operation_id`, `original_operation_id`, `correction_chain_id`, `movement_ids`, `value_movement_ids` |
| `EVT-IC-02` | `batch_id`, `baseline_id`, `operation_ids`, `control_totals`, `report_hash`, `official_cost_version_ids`, `activation_status=ACTIVE` |
| `EVT-IV-04` | `run_id`, `period_id`, `selected_method`, `adjustment_batch_id`, `value_movement_ids`, `official_cost_version_ids` |
| `EVT-IC-03` | `case_id`, `case_type`, `scope`, `resolution_code`, `evidence_hash`, `rebuild_sequences?` |
| `EVT-IC-04` | `approval_case_id`, `operation_id`, `decision`, `required_level`, `actor_id`, `operation_status` |
| `EVT-XD-01` | `pricing_basis_version_id`, `product_id`, `source_type`, `source_version`, `draft_id`, `effective_at` |
| `EVT-XD-02` | `review_id`, `official_cost_version_ids`, `decision_items`, `new_basis_version_ids`, `draft_ids` |
| `EVT-IV-05` | `late_cost_id`, `source_identity_hash`, `receipt_line_ids`, `adjustment_batch_id`, `value_movement_ids`, `original_period_id`, `posting_period_id`, `dirty_scopes`, `superseding_run_id?` |
| `EVT-IC-05` | `session_id`, `scope_hash`, `reason`, `cancelled_by`, `lock_released_at` |
| `EVT-XD-03` | `product_id`, `warehouse_id`, `policy_version`, `threshold`, `target`, `near_expiry_days?`, `near_expiry_action?`, `near_expiry_source`, `effective_at` |

## 7. Concurrency and transaction rules

1. Normalize và sort balance keys `(tenant, warehouse, product, state, lot_key)` trước lock; `NONE` dùng sentinel/DB-equivalent để unique key không phụ thuộc nullable `lot_id`.
2. Reserve/release khóa `ReservationBucket`; save pick compare-and-swap active allocation set/version; issue khóa bucket + physical balance + đúng active PickAllocation version. Check và mutation trong một transaction, không ghi reserved vào balance theo lô.
3. Combo reserve/issue/return khóa mọi component key theo thứ tự xác định; một lỗi rollback toàn bộ.
4. Return cap khóa từng original component issue aggregate theo thứ tự xác định.
5. Lot upsert uses unique constraint; concurrent create re-read existing record and revalidate attributes.
6. Approval/state transition uses expected version; first commit wins.
7. Count locks kiểm `scope_predicate_snapshot` cho cả existing/prospective key trước mutation; database concurrency vẫn bắt buộc cho mutation ngoài scope.
8. Cost publish rechecks blockers and run version inside transaction; cost run không có cancellation. Rerun tạo successor link, không reuse ID.
9. Late-cost natural key được insert/lock trước adjustment; duplicate trả cùng result, còn scope ảnh hưởng được đánh dấu `DIRTY` nguyên tử.
10. Long batch calculations occur outside transaction on immutable snapshot; publication transaction only validates/rechecks and writes deltas.

## 8. `UNKNOWN` and recovery protocol

| Tình huống | Protocol |
|---|---|
| Client timeout, operation ID known | Trả/hiển thị `effect_status=UNKNOWN`; `GET` status; retry cùng command idempotency key nếu hợp đồng cho phép |
| Server knows commit succeeded | Mark/return `COMPLETED`, `effect_status=COMMITTED`; outbox delivery independent |
| Server proves no commit | Continue same operation safely hoặc terminal `EXECUTION_REJECTED`, `effect_status=NONE` |
| Evidence insufficient | Keep `UNKNOWN`, giữ cùng identity/input cần thiết, lock affected scope if risk warrants, open Reconciliation Case |
| Manual request to set result | Reject `MANUAL_FINALITY_OVERRIDE_NOT_ALLOWED`, `effect_status=NONE`; không đưa action sửa tay vào guidance |

Recovery after outage validates ledger integrity, balances/projections and all `UNKNOWN` before opening mutation. `RPO=0` applies to completed operation, ledgers, transactional balance and outbox in the same durable commit.

## 9. Permission catalog

| Permission | Cho phép |
|---|---|
| `inventory.view` | Quantity/state/lot in scope |
| `inventory.operation.create` | Create allowed operation types |
| `inventory.receipt.receive` | Receive purchased goods |
| `inventory.reservation.manage` | Reserve/release/reallocate |
| `inventory.pos.complete` | Online POS inventory completion |
| `inventory.fulfillment.handover` | Handover issue |
| `inventory.fulfillment.pick` | Save/change pick allocation |
| `inventory.return.receive` | Customer return receipt/classification |
| `inventory.supplier_return.handover` | Supplier return handover |
| `inventory.state.manage` | State change/demo/quarantine |
| `inventory.disposal.complete` | Disposal command |
| `inventory.count.create/count/approve/cancel` | Separate count actions |
| `inventory.operation.cancel/correct` | Separate cancel/correction |
| `inventory.approval.decide.{level}` | Approval by level |
| `inventory.opening_balance.prepare/commit` | Separate migration preparation/commit |
| `inventory.cost.view/calculate/publish/late_cost` | Separate valuation actions |
| `inventory.financial.view` | Purchase/official cost, value, margin |
| `inventory.reconciliation.manage` | Case/rebuild/unlock |
| `pricing.scenario.manage` | Purchase-discount scenario |
| `pricing.cost_basis.publish` | Pricing cost basis/draft |
| `pricing.review.apply` | Period-end pricing review |
| `product.stock_policy.manage` | Configure low-stock threshold/target và near-expiry override/action |

Mỗi permission mutation được AND với warehouse scope. Approval kiểm maker–checker và policy level ngoài permission đơn thuần.

## 10. Error catalog

### 10.1 Identity/version/concurrency

`IDEMPOTENCY_PAYLOAD_MISMATCH`, `SOURCE_VERSION_STALE`, `VERSION_CONFLICT`, `BALANCE_CONFLICT`, `LOCK_CONFLICT`, `APPROVAL_ALREADY_DECIDED`, `OPERATION_NOT_CANCELLABLE`, `OPERATION_TERMINAL`, `PICK_ALLOCATION_ALREADY_CONSUMED`.

### 10.2 Stock/tracking

`INSUFFICIENT_AVAILABLE`, `INSUFFICIENT_STOCK`, `INSUFFICIENT_IN_STATE`, `LOT_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`, `LOT_NOT_ELIGIBLE`, `EXPIRY_REQUIRED`, `EXPIRED_CANNOT_BE_SELLABLE`, `TRACKING_CHANGE_REQUIRES_ZERO_STOCK`, `RETURN_LOT_MISMATCH`, `COMBO_COMPONENT_MISMATCH`, `RETURN_VALUE_BASIS_MISSING`.

### 10.3 Source/authority/control

`OWNERSHIP_ASSERTION_REQUIRED`, `HANDOVER_ASSERTION_REQUIRED`, `PRICE_EVIDENCE_REQUIRED`, `SOURCE_DOCUMENT_NOT_FOUND`, `RETURN_LIMIT_EXCEEDED`, `SELF_APPROVAL_NOT_ALLOWED`, `APPROVER_NOT_ELIGIBLE`, `RISK_LEVEL_INSUFFICIENT`, `REJECTION_REASON_REQUIRED`, `INVENTORY_NOT_ACTIVATED`, `PRODUCT_DISCONTINUED_FOR_RECEIPT`, `PRODUCT_ARCHIVED`, `BASE_UOM_IMMUTABLE`.

### 10.4 Valuation/reconciliation

`DIRECT_PRICE_ALREADY_CONFIRMED`, `COST_RUN_BLOCKED`, `COST_RUN_ALREADY_PUBLISHED`, `ADJUSTMENT_TOTAL_MISMATCH`, `COST_EFFECTIVE_INTERVAL_OVERLAP`, `INSUFFICIENT_EVIDENCE`, `LEDGER_INTEGRITY_FAILED`, `REBUILD_VALIDATION_FAILED`, `MANUAL_FINALITY_OVERRIDE_NOT_ALLOWED`.

### 10.5 Structured capability exclusion

`CAPABILITY_NOT_AVAILABLE_INTERNAL_TRANSFER`, `CAPABILITY_NOT_AVAILABLE_WAREHOUSE_LIFECYCLE`, `CAPABILITY_NOT_AVAILABLE_OFFLINE_SALE`, `CAPABILITY_NOT_AVAILABLE_SERIAL_TRACKING`, `CAPABILITY_NOT_AVAILABLE_CUSTODY`, `CAPABILITY_NOT_AVAILABLE_SKU_TRANSFORMATION`, `CAPABILITY_NOT_AVAILABLE_REPLENISHMENT_WORKFLOW`.

### 10.6 Catalog đầy đủ theo hợp đồng hành vi

- Draft/approval/control: `APPROVAL_PRICE_BASIS_REQUIRED`, `APPROVAL_REQUIRED`, `APPROVER_CONFIGURATION_MISSING`, `DRAFT_VALIDATION_FAILED`, `OPERATION_NOT_DRAFT`, `COUNT_NOT_READY`, `CONTROL_TOTAL_MISMATCH`, `MIGRATION_VALIDATION_FAILED`, `MASTER_NOT_FOUND`, `OPENING_BATCH_ALREADY_EXISTS`, `LOT_OR_EXPIRY_REQUIRED`.
- Count/lock: `COUNT_ALREADY_ACTIVE`, `COUNT_ALREADY_SUBMITTED`, `COUNT_LINE_OUT_OF_SCOPE`, `COUNT_NOT_CANCELLABLE`, `COUNT_SCOPE_EMPTY`, `RECOUNT_REQUIRED`, `LOCK_LOST`, `LOCK_OWNERSHIP_MISMATCH`, `CANCELLATION_REASON_REQUIRED`.
- Reservation/pick/fulfillment: `RESERVATION_NOT_ACTIVE`, `COMPONENT_SHORTAGE`, `INSUFFICIENT_AT_EXECUTION`, `PICK_ALLOCATION_CONFLICT`, `PICK_ALLOCATION_ALREADY_CONSUMED`, `PICK_EXCEEDS_RESERVATION`, `OVERRIDE_REASON_REQUIRED`, `WAREHOUSE_ROUTING_NOT_AVAILABLE`.
- Receipt/return/state/disposal: `RECEIPT_EXCEEDS_TOLERANCE`, `RECEIPT_NOT_VALUATION_PENDING`, `CURRENCY_MISMATCH`, `CLASSIFICATION_TOTAL_MISMATCH`, `RETURN_ALREADY_CLASSIFIED`, `ORIGINAL_ISSUE_NOT_FOUND`, `LOT_MISMATCH`, `COMBO_COMPONENT_MISMATCH`, `RETURN_VALUE_BASIS_MISSING`, `STATE_TRANSITION_NOT_ALLOWED`, `DISPOSAL_NOT_APPROVED`, `DISPOSAL_CONFIRMATION_REQUIRED`.
- Correction/reconciliation: `CORRECTION_ALREADY_ACTIVE`, `CORRECTION_NOT_FEASIBLE`, `ORIGINAL_NOT_COMPLETED`, `PERIOD_POLICY_VIOLATION`, `CASE_NOT_ACTIVE`.
- Cost/late cost: `COST_VERSION_MISSING`, `INPUT_SNAPSHOT_INCONSISTENT`, `CALCULATION_FAILED`, `PERIOD_NOT_CALCULABLE`, `LATE_COST_SOURCE_REQUIRED`, `LATE_COST_ALREADY_RECORDED`, `LATE_COST_ALLOCATION_MISMATCH`, `POSTING_PERIOD_NOT_OPEN`.
- Query/config/pricing: `FORBIDDEN_SCOPE`, `PRODUCT_NOT_FOUND`, `SNAPSHOT_NOT_AVAILABLE`, `NOT_CONFIGURED`, `REPLENISHMENT_CONFIG_INVALID`, `NEAR_EXPIRY_POLICY_INVALID`, `FINANCIAL_VIEW_FORBIDDEN`, `MARGIN_SOURCE_INCOMPLETE`, `SCENARIO_INPUT_INVALID`, `BENEFIT_RULE_AMBIGUOUS`, `SCENARIO_VERSION_CONFLICT`, `PRICING_SOURCE_INVALID`, `PRICING_SOURCE_VERSION_STALE`, `PRICING_POLICY_MISSING`, `PRICING_PROVENANCE_MISSING`, `PROJECTED_SOURCE_DECISION_REQUIRED`, `REVIEW_ALREADY_APPLIED`.

Mỗi code có đúng một HTTP class theo §3, message tiếng Việt có thể bản địa hóa, và `details` không được làm lộ tenant/object/financial field ngoài quyền. Test catalog phải có ít nhất một assertion cho mọi code xuất hiện ở dòng `Lỗi` của Part 05.

## 11. Security and data protection

- Tenant boundary enforced in query and mutation; object ID alone never bypasses tenant/scope.
- Financial masking occurs server-side, not CSS/client-only.
- `FINANCIAL_RESTRICTED` tối thiểu gồm purchase/direct/landed cost; official cost/carrying value; COGS/adjustment/true-up; projected/pricing-reference cost và purchase-discount scenario. Field policy áp đồng nhất cho response, export, event/projection và log; giá trị không được render vào DOM khi actor thiếu quyền.
- Evidence file access uses short-lived authorized URLs or proxy; hash and metadata retained.
- Logs redact token, personal data, purchase price/value unless secured telemetry sink requires it.
- Audit log records actor, impersonation/delegation if any, source, reason, before/after for mutable policy/lot and correlation ID.
- Rate limits separate query, mutation, export and batch; idempotent retry không bị tính như business duplicate.

## 12. Performance, capacity and observability

### 12.1 SLO

- Availability `p95 ≤ 300 ms` at normal load.
- Reserve/issue `p95 ≤ 1 s`, `p99 ≤ 2 s`.
- 100 concurrent sessions/tenant; 50 inventory mutations/second; 10M movement lines/year minimum.
- Batch/report lớn chạy async với progress/cancel khi hợp đồng cho phép; **cost calculation run không có cancel trong Phase 1** và rerun dùng successor ID.

### 12.2 Metrics

`operation_started/completed/rejected/unknown`, latency by BC/error, balance lock wait/deadlock, idempotency replay/mismatch, lot conflict, approval wait, count lock duration, cost blockers/run duration, outbox lag/retry/dead-letter, reconciliation age, projection sequence lag, rebuild duration/result.

### 12.3 Trace/log

Trace attributes: `tenant_id`, `operation_id`, `bc_id`, `operation_request_id_hash`, `idempotency_key_hash`, `source_type/id/version`, `warehouse_id`, `aggregate_id/version`, `ledger_sequence`, `event_id`, `correlation_id`. Không ghi raw sensitive payload.

## 13. Technical quality gates

1. 34/34 BC có đúng một handler và primary adapter trong realization matrix.
2. 100% mutation endpoint kiểm auth + warehouse scope + idempotency/source version.
3. 100% event có event ID/version/correlation/causation và consumer dedup test.
4. Concurrency tests chứng minh no oversell, no double return, no duplicate lot, first approval decision wins.
5. Fault-injection test chứng minh atomic rollback và outbox finality.
6. Structured capability endpoints trả `501`/catalog code và zero mutation.
7. SLO/capacity test không có lost/duplicate movement.
8. Recovery test từ durable commit đạt `RPO=0` và projection rebuild đúng hash/totals.
9. Schema/contract test chứng minh mọi success/error có recovery guidance hợp lệ, nhãn tiếng Việt được resolve và next action không vượt Action/BC/permission catalog.


<a id="nfr-hieu-nang"></a>
## 14. NFR hiệu năng và năng lực xử lý

### `PERFORMANCE_SLO` — Mục tiêu độ trễ

- Availability ở tải chuẩn: `p95 ≤ 300 ms`.
- Giữ/xuất: `p95 ≤ 1 s`, `p99 ≤ 2 s`.
- Batch lớn chạy bất đồng bộ; không dùng timeout của client để kết luận operation thất bại.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.

<a id="nfr-nang-luc-xu-ly"></a>
### `CAPACITY_TARGET` — Mục tiêu năng lực xử lý

- Tối thiểu 100 phiên đồng thời trên mỗi tenant.
- Tối thiểu 50 operation thay đổi tồn mỗi giây.
- Tối thiểu 10 triệu movement line mỗi năm trên mỗi tenant.
- Tải cao không được gây trùng hoặc mất movement.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.

<a id="durability-rpo-va-rebuildability"></a>
### `DURABILITY_RPO` — Độ bền, RPO và khả năng dựng lại

- Operation đã Hoàn tất, ledger, số dư giao dịch và outbox đã commit có `RPO = 0`.
- Projection phải dựng lại được từ ledger; việc dựng lại không tạo authority hoặc finality mới.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.


## 15. PROC-01 và boundary chuyển giao v4.1.0

- [PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho](07-technical-procedures/PROC-01-dung-lai-du-lieu-dan-xuat-tu-so-kho/00-procedure.md) chỉ được gọi từ BJ-16 sau khi chứng minh ledger đúng/projection sai.
- `BC-XD-01` là contract chuyển giao Theme 10 — Mua hàng; `BC-XD-02/03` thuộc Theme 2 — Sản phẩm; `BC-XD-04` thuộc Reporting/Analytics.
- Các boundary contract này được giữ để khóa payload/finality trong thời gian `outbound/` còn nằm ở Theme 7, không tạo implementation ownership cho Theme 7.
