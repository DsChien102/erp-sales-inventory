---
id: AGG-IV-02
type: aggregate
theme: theme-07
title: "CostCalculationRun Aggregate"
owner: SA
status: IN_REVIEW
source_baseline: v3.12.0
---
# AGG-IV-02 — CostCalculationRun Aggregate

## 1. Trách nhiệm nghiệp vụ

Khóa một lần tính giá vốn theo đúng kỳ, scope, cutoff và **phương pháp tenant đã cấu hình**, đồng thời sở hữu tập `ProductCostResult` dùng để rà soát/công bố.

## 2. Boundary

**Thuộc Aggregate:** `ENT-IV-03 CostCalculationRun`, `ENT-IV-09 ProductCostResult`.

**Không thuộc Aggregate:** tenant costing policy master; receipt/value adjustment facts nguồn; `OfficialCostVersion` đã công bố là aggregate riêng.

## 3. Invariant

- Costing method snapshot đến từ tenant policy và không được user đổi theo run.
- Moving/periodic calculation dùng cùng ordered valuation fact set/cutoff.
- Dirty scope là exact Product + posting period do hệ thống sở hữu; user không tùy ý bỏ Product.
- Run đã tạo không bị sửa/reuse; dữ liệu thay đổi tạo successor run.
- Publication chỉ dùng immutable ProductCostResult và current hashes.

## 4. Lifecycle

`CREATED → CALCULATING → BLOCKED | READY_FOR_REVIEW → PUBLISHED`.

`BLOCKED` hoặc stale source sau review không được “sửa run”; xử lý nguồn rồi tạo successor.

## 5. Hành vi chính

- `createAndCalculate()` — khóa scope/cutoff/policy, materialize result set.
- `markBlocked()` / `markReadyForReview()` — quyết định theo blocker authoritative.
- `publish()` — recheck result/source/dirty causes rồi điều phối publication transaction.
- `createSuccessor()` — liên kết run mới với run cũ khi cần tính lại.

## 6. Finality

Calculation là read/derive materialization; publication là mutation có idempotency/finality riêng theo `BC-IV-03`.

## 7. Trace

`BJ-14` → `UC-14-01`, `UC-14-04` → `BC-IV-02/03` → `ENT-IV-03/09` → `T7-DR-164…170`, `T7-DR-194/195`.
