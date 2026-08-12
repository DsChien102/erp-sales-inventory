---
id: BC-IV-04
type: behavioral-contract
theme: theme-07
title: "Record late landed cost"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-iv-04"></a>
# BC-IV-04 — Record late landed cost

## 1. Ý định

Ghi một economic late-cost component có nguồn mà không rewrite receipt/direct valuation/cost run cũ.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IV
- Journey chính: `BJ-13`

## 3. Đầu vào nghiệp vụ

Stable `source_component_key` + current revision/evidence; source/normalized amount; route=`LATE`; selected method/policy; authoritative target scope; 1..N valuation exposure allocations; per-allocation periods; `late_cost_basis_hash`; `allocation_hash`; command/idempotency identity.

## 4. Điều kiện trước

Financial permission; source revision current nhưng dedup theo **stable economic key**; route vẫn LATE; target-scope/exposure/metric/period versions current; all targets initial-valued; method still allowed; basis/allocation hashes current; sums reconcile; all posting periods open.

## 5. Quy tắc nghiệp vụ

Rebuild preview → persist one `LateLandedCost` keyed by source component → persist all exposure allocations → group by posting period and create **1..N `LATE_LANDED_COST` ValuationAdjustmentBatch** + lines/value movements → mark exact `Product + posting period` dirty scopes → outbox, all-or-nothing. Không quantity movement; không auto-publish Official Cost.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Một economic component được ghi đúng một lần bất kể source revision; full provenance + exposure linkage; 1..N adjustment batches; affected product/posting-period scopes ready for BJ14.

## 9. Kết quả và semantics lỗi

`LATE_COST_SOURCE_REQUIRED`, `LATE_COST_SOURCE_STALE`, `LATE_COST_ALREADY_RECORDED`, `LATE_COST_ROUTE_DIRECT`, `LATE_COST_TARGET_SCOPE_INVALID`, `LATE_COST_TARGET_NOT_INITIAL_VALUED`, `LATE_COST_ALLOCATION_METHOD_INVALID`, `LATE_COST_BASIS_STALE`, `LATE_COST_ALLOCATION_MISMATCH`, `LATE_COST_EXPOSURE_STALE`, `POSTING_PERIOD_NOT_OPEN`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IV-02/05/06/07/08`; read `ENT-IV-01`, ReceiptValuation, AccountingPeriod.
- Trace: `BJ-13`; `UC-13-03`; `API-C-23`; `EVT-IV-05`; `T7-DR-157…163`.
