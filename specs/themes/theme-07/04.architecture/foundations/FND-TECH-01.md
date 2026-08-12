---
id: FND-TECH-01
type: foundation
theme: theme-07
title: "Technical execution contracts"
owner: SA
status: FROZEN
source_baseline: v3.10.1
---
# FND-TECH-01 — Technical execution contracts

## 1. Vấn đề cần giải quyết

Materialize các execution contract dùng chung đã tồn tại trong `07 — Hợp đồng kỹ thuật` của baseline v3.10.1 mà không thay đổi semantics.

## 2. Scope

### 2.1 Owns

Request/response, API/event realization, transaction/concurrency/finality, permission/error/security/observability technical contract của Theme 7.

### 2.2 Does not own

Business semantics của Decision/BJ/UC/BC.

## 3. Execution protocol

### 1. Nguyên tắc tổ chức

Part 05 sở hữu Use Case; Part 06 sở hữu nghĩa dùng chung của BC. Part 07 chỉ khóa cách thực thi:

- mỗi BC có đúng một authoritative application handler;
- REST, event consumer, batch và UI là adapter;
- handler gọi domain aggregate/service và commit qua một transaction boundary được chỉ định;
- API/event không tự thêm một nhánh nghiệp vụ;
- trace ID ổn định nối BC, endpoint/event và test.

### 2. Common request/response contract

#### 2.1 Headers

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

#### 2.2 Success envelope

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

#### 2.3 Error envelope

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

### 3. HTTP/result semantics

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

### 4. BC realization matrix

| BC | Authoritative handler | Primary adapter | Transaction boundary | Event/result | Test prefix |
|---|---|---|---|---|---|
| `BC-IO-01` | `QueryInventoryAvailability` | `API-Q-01` — `GET /v1/inventory/availability` | Read snapshot/transactional read | Query result only | `TST-BC-IO-01` |
| `BC-IO-02` | `ReceivePurchasedGoods` | `API-C-02` — `POST /v1/inventory/receipts` | Operation + movement + `VALUATION_PENDING` balance + lot + receipt + outbox; no value movement | `EVT-IO-01 ReceiptRecorded` | `TST-BC-IO-02` |
| `BC-IV-01` | `ConfirmReceiptDirectCost` | `API-C-20` — `POST /v1/receipt-valuations/confirm` | Recheck selected basis-hash/scope-version + deterministic allocated value + ReceiptValuation + receipt-business-date value movement + valuation-state balance transfer + OfficialCost compare-and-create + availability + outbox | `EVT-IV-03 ReceiptValuationConfirmed` | `TST-BC-IV-01` |
| `BC-IV-05` | `BuildReceiptValuationPreview` | `API-Q-11` — `POST /v1/receipt-valuations/preview` | Build complete DirectCostBasis candidates + deterministic allocation/rounding + basis/scope hashes; read/derive only | Query result only | `TST-BC-IV-05` |
| `BC-IV-06` | `BuildLateLandedCostPreview` | `API-Q-12` — `POST /v1/late-landed-costs/preview` | Resolve stable economic key/route + authoritative target scope + exposure/metric/period snapshots; derive basis/allocation hashes; no mutation | Query result only | `TST-BC-IV-06` |
| `BC-IO-03` | `ReserveOrderQuantity` | `API-C-03` — `POST /v1/reservations` | ReservationGroup? + child Reservation + ReservationBucket + outbox; combo atomic | `EVT-IO-02 ReservationChanged` | `TST-BC-IO-03` |
| `BC-IO-04` | `CompleteOnlinePosCheckout` | `API-C-04` — `POST /v1/pos-checkouts/inventory-completion` | Issue/value movement + balance + result + outbox | `EVT-IO-03 PosInventoryCompleted` | `TST-BC-IO-04` |
| `BC-IO-05` | `HandOverFulfillment` | `API-C-05` — `POST /v1/fulfillments/{id}/handover` | Source/allocation version recheck + actual handover <= picked−consumed + immutable HandoverEvidence + reservation consume + issue/value + balance + outbox | `EVT-IO-04 FulfillmentHandedOver` | `TST-BC-IO-05` |
| `BC-IO-06` | `AdjustReservationCapacity` | `API-C-06` — `POST /v1/reservations/{id}/adjustments` | Reservation/Group + ReservationBucket + allocation-review signal + outbox; no PickAllocation mutation | `EVT-IO-05 ReservationChanged` | `TST-BC-IO-06` |
| `BC-IO-07` | `ReceiveCustomerReturn` | `API-C-07` — `POST /v1/customer-return-receipts` | Per-component cap/lot/value + receipt/value movement + balance + outbox, all-or-nothing | `EVT-IO-06 CustomerReturnReceived` | `TST-BC-IO-07` |
| `BC-IO-08` | `ClassifyCustomerReturn` | `API-C-08` — `POST /v1/customer-return-receipts/{id}/classifications` | State movements + balances + outbox | `EVT-IO-07 CustomerReturnClassified` | `TST-BC-IO-08` |
| `BC-IO-09` | `HandOverSupplierReturn` | `API-C-09` — `POST /v1/supplier-returns/{id}/handover` | Current source snapshot + exact pending source slices + issue/value + balances + source-agnostic HandoverEvidence + outbox | `EVT-IV-01 SupplierReturnHandedOver` | `TST-BC-IO-09` |
| `BC-IC-01` | `OpenStockCount` | `API-C-14` — `POST /v1/stock-counts` | Atomic scope barrier + CountScopeSnapshot + cutoff + session/lines/lock | Synchronous result; không phát integration event Phase 1 | `TST-BC-IC-01` |
| `BC-IC-02` | `SubmitStockCount` | `API-C-15` — `POST /v1/stock-counts/{id}/submissions` | Immutable StockCountSubmission + line projection; zero-variance completion or approval route | `EVT-IC-01` only when session completes | `TST-BC-IC-02` |
| `BC-IC-03` | `ApproveCountAndAdjust` | `API-C-16` — `POST /v1/stock-counts/{id}/approval-decisions` | Approval decision + optional adjustment operation/movement/value + completion/unlock | `EVT-IC-01 StockCountCompleted` on completed | `TST-BC-IC-03` |
| `BC-IO-10` | `ChangeInventoryState` | `API-C-10` — `POST /v1/inventory/state-changes` | Exact StateChangeBasis recheck + source-slice STATE_TRANSFER + balances + atomic reservation reconciliation + CommandReceipt/outbox; no value movement | `EVT-IO-08 InventoryStateChanged` | `TST-BC-IO-10` |
| `BC-IO-11` | `DisposeInventory` | `API-C-11` — `POST /v1/inventory/disposals` | Issue/value + balance + outbox | `EVT-IV-02 InventoryDisposed` | `TST-BC-IO-11` |
| `BC-IO-12` | `CancelInventoryOperation` | `API-C-12` — `POST /v1/inventory-operations/{id}/cancellation` | Operation state + locks/approval cleanup + outbox | `EVT-IO-09 OperationCancelled` | `TST-BC-IO-12` |
| `BC-IO-13` | `CorrectInventoryOperation` | `API-C-13` — `POST /v1/inventory-operations/{id}/corrections` | New operation + chain + delta movements/value + outbox | `EVT-IO-10 OperationCorrected` | `TST-BC-IO-13` |
| `BC-IC-04` | `CommitOpeningBalance` | `API-C-17` — `POST /v1/opening-balance-batches/{id}/commit` | Batch + opening quantity/value/cost + report + activation `PREPARING→ACTIVE` + outbox | `EVT-IC-02 OpeningBalanceCommitted` | `TST-BC-IC-04` |
| `BC-IV-02` | `CalculateInventoryCost` | `API-C-21` — `POST /v1/cost-calculation-runs` | Unified valuation-timeline snapshot + CostCalculationRun + immutable ProductCostResult set; no ledger mutation | Async run result | `TST-BC-IV-02` |
| `BC-IV-03` | `PublishInventoryCost` | `API-C-22` — `POST /v1/cost-calculation-runs/{id}/publication` | Recheck run/result/scope hashes → incremental reconciliation adjustment + value ledger + forward-effective cost versions + exact dirty-cause clear + outbox | `EVT-IV-04 OfficialCostPublished` | `TST-BC-IV-03` |
| `BC-IO-14` | `QueryLowStockSuggestions` | `API-Q-02` — `GET /v1/inventory/low-stock` | Read projection | Query result only | `TST-BC-IO-14` |
| `BC-IC-05` | `ReconcileAndRebuild` | `API-C-18` — `POST /v1/reconciliation-cases/{id}/resolution-runs` | Case/action/rebuild evidence; target mutation in controlled steps | `EVT-IC-03 ReconciliationResolved` | `TST-BC-IC-05` |
| `BC-IC-06` | `DecideApproval` | `API-C-19` — `POST /v1/approval-cases/{id}/decisions` | Approval case + operation state + outbox | `EVT-IC-04 ApprovalDecided` | `TST-BC-IC-06` |
| `BC-XD-01` | `CalculatePurchaseDiscountScenario` | External `API-X-01` — `POST /v1/purchase-discount-scenarios` | Scenario/version only; no inventory transaction | Synchronous calculation result; no inventory event | `TST-BC-XD-01` |
| `BC-XD-02` | `PublishPricingCostBasis` | External `API-X-02` — `POST /v1/pricing-cost-bases` | Pricing basis + draft only | `EVT-XD-01 PricingCostBasisPublished` | `TST-BC-XD-02` |
| `BC-XD-03` | `ApplyPricingBasisReview` | External `API-X-03` — `POST /v1/pricing-basis-reviews/{id}/decisions` | Review decisions + basis/drafts only | `EVT-XD-02 PricingBasisReviewApplied` | `TST-BC-XD-03` |
| `BC-XD-04` | `QueryMarginComparison` | `API-Q-03` — `GET /v1/inventory-reports/margin-comparison` | Consistent report snapshot | Query result only | `TST-BC-XD-04` |
| `BC-IV-04` | `RecordLateLandedCost` | `API-C-23` — `POST /v1/late-landed-costs` | Stable-key late-cost + exposure allocations + 1..N posting-period adjustment batches/value movements + Product/posting-period dirty scopes + outbox, all-or-nothing | `EVT-IV-05 LateLandedCostRecorded` | `TST-BC-IV-04` |
| `BC-IO-15` | `SavePickAllocation` | `API-C-24` — `PUT /v1/fulfillments/{id}/pick-allocation` | Allocation set/version + allocated/picked/physical-correction assertions; no issue movement | Synchronous result | `TST-BC-IO-15` |
| `BC-IO-16` | `MaintainOperationDraft` | `API-C-25` — `POST /v1/inventory-operations`; `PUT /v1/inventory-operations/{id}` | Draft + lines + CommandReceipt | Synchronous result | `TST-BC-IO-16` |
| `BC-IO-17` | `SynchronizeSupplierReturnAuthorization` | `IN-EVT-01` — `SupplierReturnAuthorized/Amended/Cancelled` | Source snapshot + exact source slices + `RTV_PENDING` state movements/balances + outbox | `EVT-IO-11 SupplierReturnPendingSynchronized` | `TST-BC-IO-17` |
| `BC-IC-07` | `SubmitInventoryOperation` | `API-C-26` — `POST /v1/inventory-operations/{id}/submission` | Payload lock + risk/policy + approval case + CommandReceipt | Synchronous result | `TST-BC-IC-07` |
| `BC-IC-08` | `CancelStockCount` | `API-C-27` — `POST /v1/stock-counts/{id}/cancellation` | Session cancel + lock release + CommandReceipt | `EVT-IC-05 StockCountCancelled` | `TST-BC-IC-08` |
| `BC-IC-09` | `PrepareOpeningBalanceBatch` | `API-C-28` — `POST /v1/opening-balance-batches`; `PUT /v1/opening-balance-batches/{id}` | Batch staging/version + validation/approval refs | Synchronous result | `TST-BC-IC-09` |
| `BC-XD-05` | `ConfigureInventoryProductPolicy` | External `API-X-04` — `PUT /v1/product-stock-policies/{product_id}` | Low-stock/near-expiry policy version; no inventory ledger | `EVT-XD-03 InventoryProductPolicyChanged` | `TST-BC-XD-05` |

External adapters are contract boundaries, not ownership claims. If modules are deployed together initially, namespace/handler owner vẫn phải giữ như bảng.

Ngoài các aggregate liệt kê, **mọi** transaction boundary của BC mutation trong ma trận đều bao gồm `CommandReceipt`; query không tạo receipt.

### 5. Resource/query API catalog

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
| `API-Q-10` | `GET /v1/cost-calculation-runs/{id}` | Immutable run + ProductCostResult summaries/details + blockers + reconciliation/effective-time consequences | `inventory.cost.view` |
| `API-Q-11` | `POST /v1/receipt-valuations/preview` | Pending scopes + complete DirectCostBasis candidates + authoritative allocated-value/UOM/availability preview | `inventory.financial.view` |
| `API-Q-12` | `POST /v1/late-landed-costs/preview` | Stable component/route + source/tax/FX normalization + authoritative target scope + ValuationExposure/metric snapshots + 1..N exposure allocation + per-line period/dirty-scope + basis/allocation hashes | `inventory.financial.view` |

Pagination dùng cursor ổn định. Report/export ghi filters, timezone, view mode, cut-off/sequence và generated-at.

#### 5.1 Query closure

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
| `API-Q-11` | `BC-IV-05` pending-scope/direct-cost preview; trả `valuation_basis_key/basis_version/basis_hash/scope_version/calculation_hash`; request chỉ chọn read scope, không mutation/UNKNOWN finality | `TST-API-Q-11` |
| `API-Q-12` | `BC-IV-06` late-cost basis preview; stable economic key, route, target-scope hash, exposure/metric/period snapshots, `late_cost_basis_hash` + `allocation_hash`; allowed methods do policy/source trả; không mutation | `TST-API-Q-12` |

#### 5.2 BJ03 direct receipt valuation payload contract

**API-Q-11 preview response — theo từng candidate basis/scope:**

- `receipt_item_ref`, `valuation_basis_key`, `basis_version`, `basis_hash`;
- `direct_cost_basis`: primary commercial source + component provenance `{component_type, source_id, source_version, amount/currency, allocation_method_version, tax_provenance, fx_provenance}`;
- transaction UOM snapshot, conversion-to-base/version, normalized base UOM consequence;
- `scope_key`, `scope_version`, pending/selected quantity;
- deterministic allocated full-scope value, cumulative partial preview và `calculation_hash`;
- authoritative availability preview (advisory until commit);
- candidate bootstrap consequence `official_cost_base_uom` nếu product chưa có Official Cost.

Hai candidate chỉ conflict khi complete `basis_hash`/authoritative value facts khác nhau. Query failure/timeout không tạo business `UNKNOWN` và có thể refetch.

**API-C-20 confirm request:**

- command/idempotency envelope;
- selected `{valuation_basis_key, basis_version, basis_hash, scope_key, scope_version, confirm_quantity, calculation_hash}`;
- explicit selected basis + reason khi preview có conflict.

**API-C-20 server behavior/result:**

- re-derive toàn selected basis/scope; một selected token stale → reject toàn selected-set command trước mutation;
- authoritative amount dùng deterministic cumulative allocation, không tin client `unit_cost × quantity`;
- direct value movement dùng `business_date=receipt_business_date`, `recorded_at=commit time`, period của receipt business date;
- initial Official Cost compare-and-create theo tenant+product; result trả `INITIALIZED`, `ALREADY_INITIALIZED` hoặc `NOT_APPLICABLE` cùng base-UOM unit cost;
- result trả commit-authoritative availability effect; preview availability không phải write authority.


#### 6.x — Stock Count atomic barrier, submissions và approval basis

**API-C-14 OpenStockCount**
1. Canonicalize request scope and resolve `CountScopeSnapshot`.
2. Acquire warehouse/scope barrier **before** choosing cutoff; block conflicting mutation commit path including prospective keys that match frozen scope.
3. Drain/serialize in-flight scope mutations, then allocate/read `cutoff_ledger_sequence`.
4. Aggregate balance rows to `PhysicalCountKey = warehouse + product + stock_state + lot_key` only when their valuation composition is resolved. If any key has `VALUATION_PENDING` or mixed valuation-state quantity, reject `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION` before session creation.
5. In one transaction persist CountScopeSnapshot, InventoryLock, StockCountSession, StockCountLine projections and CommandReceipt. Rejection/rollback releases barrier and leaves no orphan row.

**API-C-15 SubmitStockCount**
- Request carries `round_type`, assignment version and base-UOM observations. Server validates frozen scope/tracking/physical state; never accepts valuation state as a counter-selected dimension.
- `StockCountSubmission` is append-only and deduped by command identity/payload hash. FIRST/RECOUNT history is never overwritten.
- Zero variance completes + unlocks atomically without ApprovalCase/adjustment. Non-zero FIRST routes recount. Non-zero recount builds `CountAdjustmentBasis`; missing surplus basis returns `PRICE_BASIS_REQUIRED` while lock remains.

**API-C-16 ApproveCountAndAdjust**
- Approval subject is StockCountSession and binds scope/cutoff/lock/latest submission/risk-value basis/policy hashes.
- `REQUEST_RECOUNT` is a final decision for that case but no inventory mutation; it creates recount requirement and retains lock.
- `APPROVE` revalidates all basis versions and excluded actors immediately before commit. Stale risk/value basis returns `COUNT_APPROVAL_SNAPSHOT_STALE`/`COUNT_VALUE_BASIS_STALE`, effect NONE, and requires successor case.
- Successful APPROVE commits approval + adjustment quantity/value facts + session completion + lock release + outbox atomically.
- Any timeout with unresolved finality returns UNKNOWN with the same command identity; recovery queries CommandReceipt/ledger before retry.

**Lock enforcement:** while a stock-count lock is ACTIVE, every mutation path that can create/update an existing or prospective PhysicalCountKey evaluates the immutable CountScopeSnapshot predicate before commit. Application lock does not replace DB row/CAS controls.

### 6. Event contract

#### 6.1 Envelope

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

#### 6.2 Delivery semantics

- Transactional outbox ghi cùng commit với aggregate/ledger result.
- Delivery at-least-once; producer retry cùng `event_id`; consumer inbox/dedup required.
- Ordering được bảo đảm theo aggregate version; không cam kết total order toàn tenant nếu không nêu rõ.
- Consumer nhận version cũ/duplicate trả ack idempotent; gap version được quarantine/retry/reconcile.
- Delivery failure không rollback operation; quá threshold tạo metric/work item.
- Schema backward-compatible trong cùng major event version; breaking change tạo `.v2` và migration window.

#### 6.3 Event catalog tối thiểu

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

#### 6.4 Payload schema tối thiểu

Mọi payload ngoài envelope phải chứa đúng các reference dưới đây; ID list phải ổn định và amount/quantity luôn kèm currency/UOM khi áp dụng.

| Event | Required payload fields |
|---|---|
| `EVT-IO-01` | `operation_id`, `receipt_id`, `source_version`, `warehouse_id`, `line_ids`, `physical_delta`, `lot_ids`, `valuation_pending=true`; no official value fields |
| `EVT-IV-03` | `operation_id`, `receipt_valuation_id`, `receipt_line_ids`, `value_movement_ids`, `released_quantity`, `official_cost_version_id?` |
| `EVT-IO-02`, `EVT-IO-05` | `reservation_id`, `reservation_group_id?`, `reservation_bucket_version`, `source_line_id`, transaction-UOM snapshot/version, `requested`, `current_reserved`, `consumed`, `remaining_required`, `shortage`, `reservation_policy`, priority facts, trigger/reason, `allocation_review_required`, `status` |
| `EVT-IO-03` | `operation_id`, `checkout_id`, `issue_movement_ids`, `value_movement_ids`, `allocation_ids`, `initial_cogs` |
| `EVT-IO-04` | `operation_id`, `fulfillment_id`, `allocation_set_id`, `allocation_version`, `pick_allocation_ids`, `issue_movement_ids`, `reservation_ids`, `initial_cogs` |
| `EVT-IO-06` | `operation_id`, `return_receipt_id`, `component_results`, `original_issue_line_ids`, `quantity_movement_ids`, `value_movement_ids`, `original_period_ids` |
| `EVT-IO-07` | `operation_id`, `return_receipt_id`, `state_movement_ids`, `classification_totals` |
| `EVT-IV-01` | `operation_id`, `supplier_return_id`, `issue_movement_ids`, `value_movement_ids`, `supplier_approved_amount`, `difference_amount` |
| `EVT-IC-01` | `session_id`, `completion_type=ZERO_VARIANCE|ADJUSTED`, `adjustment_operation_id?`, `movement_ids`, `value_movement_ids`, `scope_hash`, `final_submission_hash`, `lock_released_at` |
| `EVT-IO-08` | `operation_id`, `state_change_basis_id`, `basis_hash`, `policy_version_id`, `movement_ids`, `source_slice_lineage`, `from_state`, `to_state`, `quantity`, `reservation_impacts`, `allocation_review_required` |
| `EVT-IV-02` | `operation_id`, `disposal_id`, `issue_movement_ids`, `value_movement_ids`, `reason_code` |
| `EVT-IO-09` | `operation_id`, `source_identity`, `cancel_reason`, `cancelled_at` |
| `EVT-IO-10` | `operation_id`, `original_operation_id`, `correction_chain_id`, `movement_ids`, `value_movement_ids` |
| `EVT-IC-02` | `batch_id`, `baseline_id`, `operation_ids`, `control_totals`, `report_hash`, `official_cost_version_ids`, `activation_status=ACTIVE` |
| `EVT-IV-04` | `run_id`, `run_type`, `calculation_period_id`, `posting_period_id`, `cutoff_valuation_sequence`, `run_input_hash`, `scope_hash`, `dirty_scope_hash?`, `selected_method`, `product_result_hashes`, `adjustment_batch_id`, `value_movement_ids`, `official_cost_version_ids`, `reconciled_product_ids`, `cleared_dirty_cause_ids`, `predecessor_run_id?` |
| `EVT-IC-03` | `case_id`, `case_type`, `scope`, `resolution_code`, `evidence_hash`, `rebuild_sequences?` |
| `EVT-IC-04` | `approval_case_id`, `subject_type`, `subject_id`, `operation_id?`, `decision`, `required_level`, `actor_id`, `subject_status`, `subject_snapshot_hash` |
| `EVT-XD-01` | `pricing_basis_version_id`, `product_id`, `source_type`, `source_version`, `draft_id`, `effective_at` |
| `EVT-XD-02` | `review_id`, `official_cost_version_ids`, `decision_items`, `new_basis_version_ids`, `draft_ids` |
| `EVT-IV-05` | `late_cost_id`, stable `source_component_key`, `source_revision`, `late_cost_basis_hash`, `allocation_hash`, `late_cost_allocation_ids`, `valuation_exposure_keys`, `adjustment_batch_ids`, `value_movement_ids`, per-allocation `{receipt_business_date, original_period_id, posting_period_id}`, exact `product_id + posting_period_id` dirty scopes, `superseding_run_id?` |
| `EVT-IC-05` | `session_id`, `scope_hash`, `reason`, `cancelled_by`, `lock_released_at` |
| `EVT-XD-03` | `product_id`, `warehouse_id`, `policy_version`, `threshold`, `target`, `near_expiry_days?`, `near_expiry_action?`, `near_expiry_source`, `effective_at` |

### 7. Concurrency and transaction rules

1. Normalize và sort balance keys `(tenant, warehouse, product, state, lot_key)` trước lock; `NONE` dùng sentinel/DB-equivalent để unique key không phụ thuộc nullable `lot_id`.
2. Reserve/release khóa `ReservationBucket`; save pick compare-and-swap active allocation set/version; issue khóa bucket + physical balance + đúng active PickAllocation version. Check và mutation trong một transaction, không ghi reserved vào balance theo lô.
3. Combo reserve/issue/return khóa mọi component key theo thứ tự xác định; một lỗi rollback toàn bộ.
4. Return cap khóa từng original component issue aggregate theo thứ tự xác định.
5. Lot upsert uses unique constraint; concurrent create re-read existing record and revalidate attributes.
6. Approval/state transition uses expected version; first commit wins.
7. Count locks kiểm `scope_predicate_snapshot` cho cả existing/prospective key trước mutation; database concurrency vẫn bắt buộc cho mutation ngoài scope.
8. Cost publish rechecks blockers, run/input hash, cutoff valuation sequence, ProductCostResult hashes, exact scope/dirty version-hash, posting-period state và effective-time rule inside transaction; cost run không có cancellation. Rerun tạo successor link, không reuse ID và chỉ post incremental reconciliation delta.
9. Late-cost stable `source_component_key` được insert/lock trước adjustment; source revision không tạo economic row mới. Duplicate trả cùng result; mọi exposure allocation, 1..N posting-period batches/value movements và exact `Product + posting period` dirty scopes commit hoặc rollback cùng nhau.
10. Long batch calculations occur outside transaction on immutable unified valuation timeline snapshot; publication transaction only validates/rechecks and writes incremental deltas, forward-effective cost versions and exact dirty-cause clear.

### 8. `UNKNOWN` and recovery protocol

| Tình huống | Protocol |
|---|---|
| Client timeout, operation ID known | Trả/hiển thị `effect_status=UNKNOWN`; `GET` status; retry cùng command idempotency key nếu hợp đồng cho phép |
| Server knows commit succeeded | Mark/return `COMPLETED`, `effect_status=COMMITTED`; outbox delivery independent |
| Server proves no commit | Continue same operation safely hoặc terminal `EXECUTION_REJECTED`, `effect_status=NONE` |
| Evidence insufficient | Keep `UNKNOWN`, giữ cùng identity/input cần thiết, lock affected scope if risk warrants, open Reconciliation Case |
| Manual request to set result | Reject `MANUAL_FINALITY_OVERRIDE_NOT_ALLOWED`, `effect_status=NONE`; không đưa action sửa tay vào guidance |

Recovery after outage validates ledger integrity, balances/projections and all `UNKNOWN` before opening mutation. `RPO=0` applies to completed operation, ledgers, transactional balance and outbox in the same durable commit.

### 9. Permission catalog

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

### 10. Error catalog

#### 10.1 Identity/version/concurrency

`IDEMPOTENCY_PAYLOAD_MISMATCH`, `SOURCE_VERSION_STALE`, `VERSION_CONFLICT`, `BALANCE_CONFLICT`, `LOCK_CONFLICT`, `APPROVAL_ALREADY_DECIDED`, `OPERATION_NOT_CANCELLABLE`, `OPERATION_TERMINAL`, `PICK_ALLOCATION_ALREADY_CONSUMED`.

#### 10.2 Stock/tracking

`INSUFFICIENT_AVAILABLE`, `INSUFFICIENT_STOCK`, `INSUFFICIENT_IN_STATE`, `STATE_SOURCE_SLICE_AMBIGUOUS`, `STATE_CHANGE_BASIS_STALE`, `STATE_POLICY_VERSION_STALE`, `APPROVAL_BASIS_MISMATCH`, `EXPIRED_SYSTEM_DERIVED`, `LOT_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`, `LOT_NOT_ELIGIBLE`, `EXPIRY_REQUIRED`, `EXPIRED_CANNOT_BE_SELLABLE`, `TRACKING_CHANGE_REQUIRES_ZERO_STOCK`, `RETURN_LOT_MISMATCH`, `COMBO_COMPONENT_MISMATCH`, `RETURN_VALUE_BASIS_MISSING`.

#### 10.3 Source/authority/control

`OWNERSHIP_ASSERTION_REQUIRED`, `HANDOVER_ASSERTION_REQUIRED`, `PRICE_EVIDENCE_REQUIRED`, `SOURCE_DOCUMENT_NOT_FOUND`, `RETURN_LIMIT_EXCEEDED`, `SELF_APPROVAL_NOT_ALLOWED`, `APPROVER_NOT_ELIGIBLE`, `RISK_LEVEL_INSUFFICIENT`, `REJECTION_REASON_REQUIRED`, `INVENTORY_NOT_ACTIVATED`, `PRODUCT_DISCONTINUED_FOR_RECEIPT`, `PRODUCT_ARCHIVED`, `BASE_UOM_IMMUTABLE`.

#### 10.4 Valuation/reconciliation

`DIRECT_PRICE_ALREADY_CONFIRMED`, `COST_RUN_BLOCKED`, `COST_RUN_ALREADY_PUBLISHED`, `ADJUSTMENT_TOTAL_MISMATCH`, `COST_EFFECTIVE_INTERVAL_OVERLAP`, `INSUFFICIENT_EVIDENCE`, `LEDGER_INTEGRITY_FAILED`, `REBUILD_VALIDATION_FAILED`, `MANUAL_FINALITY_OVERRIDE_NOT_ALLOWED`.

#### 10.5 Structured capability exclusion

`CAPABILITY_NOT_AVAILABLE_INTERNAL_TRANSFER`, `CAPABILITY_NOT_AVAILABLE_WAREHOUSE_LIFECYCLE`, `CAPABILITY_NOT_AVAILABLE_OFFLINE_SALE`, `CAPABILITY_NOT_AVAILABLE_SERIAL_TRACKING`, `CAPABILITY_NOT_AVAILABLE_CUSTODY`, `CAPABILITY_NOT_AVAILABLE_SKU_TRANSFORMATION`, `CAPABILITY_NOT_AVAILABLE_REPLENISHMENT_WORKFLOW`.

#### 10.6 Catalog đầy đủ theo hợp đồng hành vi

- Supplier return source sync/handover: `SOURCE_VERSION_CONFLICT`, `SOURCE_ALLOCATION_ID_CONFLICT`, `SOURCE_ALLOCATION_MISMATCH`, `SOURCE_SLICE_MISMATCH`, `SOURCE_STATE_AMBIGUOUS`, `INSUFFICIENT_RTV_PENDING`, `SOURCE_CANCELLED`.
- Draft/approval/control: `APPROVAL_PRICE_BASIS_REQUIRED`, `APPROVAL_REQUIRED`, `APPROVER_CONFIGURATION_MISSING`, `DRAFT_VALIDATION_FAILED`, `OPERATION_NOT_DRAFT`, `COUNT_NOT_READY`, `CONTROL_TOTAL_MISMATCH`, `MIGRATION_VALIDATION_FAILED`, `MASTER_NOT_FOUND`, `OPENING_BATCH_ALREADY_EXISTS`, `LOT_OR_EXPIRY_REQUIRED`.
- Count/lock: `COUNT_ALREADY_ACTIVE`, `COUNT_ALREADY_SUBMITTED`, `COUNT_LINE_OUT_OF_SCOPE`, `COUNT_NOT_CANCELLABLE`, `COUNT_SCOPE_EMPTY`, `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION`, `COUNT_ACTOR_NOT_ASSIGNED`, `COUNT_PHYSICAL_STATE_REQUIRED`, `COUNT_SURPLUS_VALUE_BASIS_REQUIRED`, `COUNT_APPROVAL_SNAPSHOT_STALE`, `COUNT_VALUE_BASIS_STALE`, `RECOUNT_REQUIRED`, `LOCK_LOST`, `LOCK_OWNERSHIP_MISMATCH`, `CANCELLATION_REASON_REQUIRED`.
- Reservation/pick/fulfillment: `RESERVATION_NOT_ACTIVE`, `COMPONENT_SHORTAGE`, `INSUFFICIENT_AT_EXECUTION`, `PICK_ALLOCATION_CONFLICT`, `PICK_ALLOCATION_ALREADY_CONSUMED`, `PICK_EXCEEDS_RESERVATION`, `OVERRIDE_REASON_REQUIRED`, `WAREHOUSE_ROUTING_NOT_AVAILABLE`.
- Receipt/return/state/disposal: `RECEIPT_EXCEEDS_TOLERANCE`, `RECEIPT_NOT_VALUATION_PENDING`, `CURRENCY_MISMATCH`, `CLASSIFICATION_TOTAL_MISMATCH`, `RETURN_ALREADY_CLASSIFIED`, `ORIGINAL_ISSUE_NOT_FOUND`, `LOT_MISMATCH`, `COMBO_COMPONENT_MISMATCH`, `RETURN_VALUE_BASIS_MISSING`, `STATE_TRANSITION_NOT_ALLOWED`, `STATE_SOURCE_SLICE_AMBIGUOUS`, `STATE_CHANGE_BASIS_STALE`, `STATE_POLICY_VERSION_STALE`, `APPROVAL_BASIS_MISMATCH`, `EXPIRED_SYSTEM_DERIVED`, `DISPOSAL_NOT_APPROVED`, `DISPOSAL_CONFIRMATION_REQUIRED`.
- Correction/reconciliation: `CORRECTION_ALREADY_ACTIVE`, `CORRECTION_NOT_FEASIBLE`, `ORIGINAL_NOT_COMPLETED`, `PERIOD_POLICY_VIOLATION`, `CASE_NOT_ACTIVE`.
- Cost/late cost: `COST_VERSION_MISSING`, `INPUT_SNAPSHOT_INCONSISTENT`, `CALCULATION_FAILED`, `PERIOD_NOT_CALCULABLE`, `LATE_COST_SOURCE_REQUIRED`, `LATE_COST_ALREADY_RECORDED`, `LATE_COST_ALLOCATION_MISMATCH`, `POSTING_PERIOD_NOT_OPEN`.
- Query/config/pricing: `FORBIDDEN_SCOPE`, `PRODUCT_NOT_FOUND`, `SNAPSHOT_NOT_AVAILABLE`, `NOT_CONFIGURED`, `REPLENISHMENT_CONFIG_INVALID`, `NEAR_EXPIRY_POLICY_INVALID`, `FINANCIAL_VIEW_FORBIDDEN`, `MARGIN_SOURCE_INCOMPLETE`, `SCENARIO_INPUT_INVALID`, `BENEFIT_RULE_AMBIGUOUS`, `SCENARIO_VERSION_CONFLICT`, `PRICING_SOURCE_INVALID`, `PRICING_SOURCE_VERSION_STALE`, `PRICING_POLICY_MISSING`, `PRICING_PROVENANCE_MISSING`, `PROJECTED_SOURCE_DECISION_REQUIRED`, `REVIEW_ALREADY_APPLIED`.

Mỗi code có đúng một HTTP class theo §3, message tiếng Việt có thể bản địa hóa, và `details` không được làm lộ tenant/object/financial field ngoài quyền. Test catalog phải có ít nhất một assertion cho mọi code xuất hiện ở dòng `Lỗi` của Part 05.

### 11. Security and data protection

- Tenant boundary enforced in query and mutation; object ID alone never bypasses tenant/scope.
- Financial masking occurs server-side, not CSS/client-only.
- `FINANCIAL_RESTRICTED` tối thiểu gồm purchase/direct/landed cost; official cost/carrying value; COGS/adjustment/true-up; projected/pricing-reference cost và purchase-discount scenario. Field policy áp đồng nhất cho response, export, event/projection và log; giá trị không được render vào DOM khi actor thiếu quyền.
- Evidence file access uses short-lived authorized URLs or proxy; hash and metadata retained.
- Logs redact token, personal data, purchase price/value unless secured telemetry sink requires it.
- Audit log records actor, impersonation/delegation if any, source, reason, before/after for mutable policy/lot and correlation ID.
- Rate limits separate query, mutation, export and batch; idempotent retry không bị tính như business duplicate.

### 12. Performance, capacity and observability

#### 12.1 SLO

- Availability `p95 ≤ 300 ms` at normal load.
- Reserve/issue `p95 ≤ 1 s`, `p99 ≤ 2 s`.
- 100 concurrent sessions/tenant; 50 inventory mutations/second; 10M movement lines/year minimum.
- Batch/report lớn chạy async với progress/cancel khi hợp đồng cho phép; **cost calculation run không có cancel trong Phase 1** và rerun dùng successor ID.

#### 12.2 Metrics

`operation_started/completed/rejected/unknown`, latency by BC/error, balance lock wait/deadlock, idempotency replay/mismatch, lot conflict, approval wait, count lock duration, cost blockers/run duration, outbox lag/retry/dead-letter, reconciliation age, projection sequence lag, rebuild duration/result.

#### 12.3 Trace/log

Trace attributes: `tenant_id`, `operation_id`, `bc_id`, `operation_request_id_hash`, `idempotency_key_hash`, `source_type/id/version`, `warehouse_id`, `aggregate_id/version`, `ledger_sequence`, `event_id`, `correlation_id`. Không ghi raw sensitive payload.

### 13. Technical quality gates

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
### 14. NFR hiệu năng và năng lực xử lý

#### `PERFORMANCE_SLO` — Mục tiêu độ trễ

- Availability ở tải chuẩn: `p95 ≤ 300 ms`.
- Giữ/xuất: `p95 ≤ 1 s`, `p99 ≤ 2 s`.
- Batch lớn chạy bất đồng bộ; không dùng timeout của client để kết luận operation thất bại.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.

<a id="nfr-nang-luc-xu-ly"></a>
#### `CAPACITY_TARGET` — Mục tiêu năng lực xử lý

- Tối thiểu 100 phiên đồng thời trên mỗi tenant.
- Tối thiểu 50 operation thay đổi tồn mỗi giây.
- Tối thiểu 10 triệu movement line mỗi năm trên mỗi tenant.
- Tải cao không được gây trùng hoặc mất movement.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.

<a id="durability-rpo-va-rebuildability"></a>
#### `DURABILITY_RPO` — Độ bền, RPO và khả năng dựng lại

- Operation đã Hoàn tất, ledger, số dư giao dịch và outbox đã commit có `RPO = 0`.
- Projection phải dựng lại được từ ledger; việc dựng lại không tạo authority hoặc finality mới.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.


### 15. PROC-01 và boundary chuyển giao v4.1.0

- [PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho](../../07.evidence/legacy-v3.10.1/implementation/legacy-harness/frozen-source/srs/07-technical-procedures/PROC-01-dung-lai-du-lieu-dan-xuat-tu-so-kho/00-procedure.md) chỉ được gọi từ BJ-16 sau khi chứng minh ledger đúng/projection sai.
- `BC-XD-01` là contract chuyển giao Theme 10 — Mua hàng; `BC-XD-02/03` thuộc Theme 2 — Sản phẩm; `BC-XD-04` thuộc Reporting/Analytics.
- Các boundary contract này được giữ để khóa payload/finality trong thời gian `outbound/` còn nằm ở Theme 7, không tạo implementation ownership cho Theme 7.


#### 5.3 BJ13 late landed cost payload contract

**API-Q-12 request/response**

- Request identifies `source_component_key` and current source revision/evidence; route is resolved/snapshotted as `DIRECT` or `LATE`.
- Response for LATE includes `target_scope_key/version/hash` and candidate membership; fixed scopes are not user-editable.
- Each target is a `valuation_exposure_key/version/hash` snapshot with initial-valued base quantity/value and ReceiptValuation lineage.
- Each allowed method provides authoritative metric `{value, unit, metric_version, metric_hash}`; value-based method uses **initial/direct receipt value before prior late-cost adjustments**.
- Response resolves `receipt_business_date`, `original_period_id`, `posting_period_id` per exposure, groups posting periods, derives dirty `product_id + posting_period_id`, and returns `late_cost_basis_hash` plus `allocation_hash`.
- Rounding uses stable exposure order; UI row order is never the residual rule. Query timeout is a safe refetch, not business UNKNOWN.

**API-C-23 request/commit**

- Command/idempotency envelope + stable `source_component_key` + current revision/evidence + route=LATE.
- Exact target-scope token, exposure/metric tokens, per-allocation period mapping, normalized amount, selected method/policy, `late_cost_basis_hash`, `allocation_hash`.
- Server re-derives every token. Any selected source/tax/FX/policy/scope/exposure/metric/period change rejects the whole command before mutation.
- Dedup uses stable component key and stable component+exposure allocation key; source revision is **not** part of economic uniqueness.
- Commit creates one LateLandedCost, all allocations, **1..N ValuationAdjustmentBatch grouped by posting period**, corresponding value movements and exact Product+posting-period dirty scopes in one transaction.
- A component routed DIRECT is rejected by BJ13; a LATE component with any not-yet-initial-valued target remains waiting and cannot be partially consumed by BJ03.


#### 5.4 BJ14 cost-run and publication payload contract

**API-C-21 request / calculation snapshot**

- Request carries `run_type`, `calculation_period_id`, one `posting_period_id`, `scope_origin`, immutable `scope_hash`; DIRTY origin additionally carries exact Product+posting-period membership, cause IDs and `dirty_scope_version/hash`.
- Server resolves one authoritative `cutoff_valuation_sequence`; `cutoff_ledger_sequence` and `cutoff_value_sequence` may be returned for audit but never define cross-ledger ordering.
- Every quantity/value fact relevant to costing is ordered by `{valuation_sequence, within_transaction_ordinal}`. Both moving and periodic methods consume the same ordered fact set.
- Server materializes one immutable `ProductCostResult` per Product and a run-level `product_result_set_hash`; global totals are aggregates only.
- Product result carries fact hash, predecessor Official Cost, target cumulative COGS, authoritative COGS baseline, target ending inventory value, authoritative carrying value, incremental deltas, proposed Official Cost and Product-level blocker/result state.
- `NEGATIVE_QUANTITY` / unsupported `NEGATIVE_VALUATION_RESULT` are blockers. Denominator zero yields `NO_NEW_COST_BASIS`; zero unit cost is valid only with complete authoritative provenance.

**API-Q-10 review contract**

- Read-only. Returns immutable run + ProductCostResult set or paginated Product detail, blocker evidence, posting period, exact dirty-scope origin and effective-time consequence.
- UC-14-03 never calls publication BC and never creates business UNKNOWN. Query timeout is a safe refetch.

**API-C-22 publication request / commit**

- Command/idempotency envelope + run ID/version + `run_input_hash` + `cutoff_valuation_sequence` + scope hash + dirty-scope version/hash when applicable + reviewed Product result hashes + requested effective time.
- Server re-derives current blockers and every selected hash. A new dirty cause/fact, period-state change or Product result mismatch rejects the entire publication before mutation.
- For each Product, publish only `target cumulative COGS - authoritative COGS already posted` and `target ending inventory value - authoritative carrying value`. Prior true-up, late cost and correction are part of the baseline. Same facts/baseline => delta zero.
- One run posts one `posting_period_id`; `original_period_id` remains per adjustment line.
- OfficialCostVersion for new transactions cannot start before publication commit. Future effective time is allowed only if publication happens before that time; if a planned time has passed, commit time (or later policy-approved time) is used.
- Exact Product+posting-period dirty causes are cleared only after successful reconciliation of the bound cause/version.
- Publish commit atomically writes non-zero adjustment lines/value movements, any new OfficialCostVersion, run finality, exact dirty-cause clear, CommandReceipt and outbox. `UNKNOWN` preserves the same publication identity; no blind retry.


#### BJ08 approval-subject compatibility
ApprovalCase subject có thể là InventoryOperation hoặc StockCountSession theo `subject_type/subject_id`; state-change approval dùng `approval_scope=STATE_CHANGE` và bind immutable `state_change_basis_id + basis_hash` trong subject snapshot; `operation_id` là optional khi subject không phải operation. EVT-IC-04 phải phát subject identity, không được giả mọi approval đều sở hữu InventoryOperation.


#### API-C-10 deep-review contract v3.10.1

`POST /v1/inventory/state-changes` là **system execution endpoint** của BC-IO-10, không phải một CTA approver. Request tối thiểu chứa `state_change_basis_id`, `basis_hash`, command/idempotency identity và expected operation version. Server phải reload basis, policy version, source balance versions, approval subject và reservation state trong transaction trước khi ghi.

- Nếu basis/policy/source stale: trả structured conflict; **zero movement**.
- Nếu source slices ambiguous: `STATE_SOURCE_SLICE_AMBIGUOUS`; không chọn arbitrary valuation slice.
- Nếu expiry path: user request tới `EXPIRED` trả `EXPIRED_SYSTEM_DERIVED`; system materializer dùng internal command identity riêng.
- Thành công: movement rows `movement_kind=STATE_TRANSFER`, mỗi row giữ `valuation_state_snapshot`; không sinh `InventoryValueMovement`.
- Reservation capacity/reconciliation cùng commit; active PickAllocation chỉ nhận review/stale signal.
- HTTP timeout giữ same idempotency/operation identity và query CommandReceipt; không blind retry bằng identity mới.

## 4. Technical model / state

Được giữ trong execution protocol nguồn ở mục 3.

## 5. Shared boundary / usage contract

Consumer phải tuân theo API/Event/transaction/finality contract nguồn; không tự thêm behavior.

## 6. Failure và recovery

Xem `UNKNOWN and recovery protocol` trong mục 3.

## 7. Concurrency / transaction semantics

Xem `Concurrency and transaction rules` trong mục 3.

## 8. Consumers

Các BE Slice/SA Slice và integration adapter của Theme 7.

## 9. Verification

Technical quality gates và test prefixes được giữ nguyên trong mục 3.
