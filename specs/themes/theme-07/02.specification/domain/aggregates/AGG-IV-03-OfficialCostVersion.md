---
id: AGG-IV-03
type: aggregate
theme: theme-07
title: "OfficialCostVersion Aggregate"
owner: SA
status: IN_REVIEW
source_baseline: v3.12.0
---
# AGG-IV-03 — OfficialCostVersion Aggregate

## 1. Trách nhiệm nghiệp vụ

Giữ phiên bản **giá vốn chính thức** có hiệu lực cho tenant + Product. Chỉ BJ14 publication được tạo phiên bản mới.

## 2. Boundary

**Thuộc Aggregate:** `ENT-IV-04 OfficialCostVersion`.

**Không thuộc Aggregate:** initial receipt value, source invoices, tenant policy master, pricing-basis decision của Theme giá bán.

## 3. Invariant

- Source bắt buộc là một `CostCalculationRun` đã publish.
- Method snapshot phải trùng tenant policy bound trong run.
- Effective interval của cùng tenant + Product không overlap.
- `effectiveFrom` không được backdate trước publication commit theo policy hiện hành.
- Warehouse/LOT không tạo Official Cost riêng; Phase 1 authority ở tenant + Product + base UOM.
- BJ03/BJ13 không được gọi aggregate này để “khởi tạo giá”.

## 4. Hành vi chính

- `publishFromRun()` — tạo version mới từ ProductCostResult đã reconcile.
- `closeInterval()` — kết thúc hiệu lực version trước khi version kế nhiệm bắt đầu.

## 5. Trace

`BJ-14` → `UC-14-04` → `BC-IV-03` → `ENT-IV-04` → `T7-DR-167`, `T7-DR-194/195`.
