---
id: BC-IV-06
type: behavioral-contract
theme: theme-07
title: "Build late landed cost preview"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-iv-06"></a>
# BC-IV-06 — Build late landed cost preview

## 1. Ý định

Đọc/chuẩn hóa source component và dựng authoritative late-cost basis/allocation preview; không mutation.

## 2. Phạm vi áp dụng

- Loại: Query/preview
- Owner nguồn: IV
- Journey chính: `BJ-13`

## 3. Đầu vào nghiệp vụ

`source_component_key`, source revision/evidence, route, target-scope contract, allowed allocation method/policy, expected exposure/metric/period versions.

## 4. Điều kiện trước

Financial permission; source current; component chưa commit; route=`LATE`; authoritative target scope hợp lệ; **mọi target exposure đã có initial valuation**; selected method allowed; posting period mapping tồn tại.

## 5. Quy tắc nghiệp vụ

Normalize tax/currency/FX → resolve authoritative target scope → materialize immutable `ValuationExposure` snapshots → load method metric snapshots → resolve original/posting period per exposure → allocate by stable exposure order with deterministic rounding → derive dirty `Product + posting period` scopes → calculate `late_cost_basis_hash` and `allocation_hash`. Không mutation.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`LateCostPreview` gồm stable economic identity, source revision/provenance, route, normalized signed VND amount, target scope/hash, allowed methods, exposure+metric snapshots, per-line original/posting periods, 1..N posting-period groups, dirty scopes, `late_cost_basis_hash`, `allocation_hash`.

## 8. Tính nguyên tử và kết quả cuối

`LateCostPreview` gồm stable economic identity, source revision/provenance, route, normalized signed VND amount, target scope/hash, allowed methods, exposure+metric snapshots, per-line original/posting periods, 1..N posting-period groups, dirty scopes, `late_cost_basis_hash`, `allocation_hash`.

## 9. Kết quả và semantics lỗi

`LATE_COST_SOURCE_REQUIRED`, `LATE_COST_SOURCE_STALE`, `LATE_COST_ALREADY_RECORDED`, `LATE_COST_ROUTE_DIRECT`, `LATE_COST_TARGET_SCOPE_INVALID`, `LATE_COST_TARGET_NOT_INITIAL_VALUED`, `LATE_COST_ALLOCATION_METHOD_INVALID`, `LATE_COST_EXPOSURE_STALE`, `POSTING_PERIOD_NOT_AVAILABLE`.

## 10. Domain và UC sử dụng

- Entity/Read model: Read `ENT-IV-01/02`, ReceiptValuation, AccountingPeriod; derive valuation exposures; không tạo `ENT-IV-07/08`.
- Trace: `BJ-13`; `UC-13-01/02`; `API-Q-12`; `T7-DR-157…163`.
