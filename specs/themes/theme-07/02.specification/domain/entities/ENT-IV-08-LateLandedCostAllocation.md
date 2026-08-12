---
id: ENT-IV-08
type: business-entity
theme: theme-07
title: LateLandedCostAllocation
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-08 — LateLandedCostAllocation

## 1. Ý nghĩa nghiệp vụ

Dòng phân bổ immutable tới `ValuationExposure`, giữ metric/period/dirty-scope snapshots

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

FK late cost + exposure + adjustment line; unique stable component + exposure key

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `late_cost_allocation_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `late_cost_id` | `UUID` | FK → `LateLandedCost` | Bắt buộc | — | — |
| `line_no` | `INTEGER` | UK thành phần | Bắt buộc | — | Deterministic stable-exposure order |
| `valuation_exposure_key` | `VARCHAR(180)` | — | Bắt buộc | — | Allocation target identity |
| `valuation_exposure_version` | `VARCHAR(80)` | — | Bắt buộc | — | — |
| `valuation_exposure_hash` | `CHAR(64)` | — | Bắt buộc | — | Binds initial-valued exposure snapshot |
| `receipt_item_ref` | `VARCHAR(180)` | — | Bắt buộc | — | Commercial lineage |
| `receipt_operation_line_id` | `UUID` | FK → `InventoryOperationLine` | Bắt buộc | — | Technical lineage only; not sole allocation identity |
| `receipt_valuation_references` | `JSONB` | — | Bắt buộc | — | Direct valuation IDs/sequences included in exposure |
| `product_id` | `UUID` | FK → `Product` | Bắt buộc | — | Dirty-scope owner |
| `initial_valued_base_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | — | Immutable exposure fact |
| `initial_direct_value_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | — | Before late-cost adjustments |
| `allocation_metric` | `JSONB` | — | Bắt buộc | — | `{method, metric_value, unit, metric_version, metric_hash}`; weight non-negative |
| `allocated_amount_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | — | Signed value-only delta |
| `rounding_adjustment_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Residual determined by stable exposure order |
| `allocation_natural_key_hash` | `CHAR(64)` | UK | Bắt buộc | — | tenant + stable source_component_key + valuation_exposure_key |
| `receipt_business_date` | `DATE` | — | Bắt buộc | — | Business date of target receipt |
| `original_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Period containing receipt business date |
| `posting_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Open period where adjustment is posted |
| `dirty_scope` | `JSONB` | — | Bắt buộc | — | Exact **Product + posting period** |
| `adjustment_batch_id` | `UUID` | FK → `ValuationAdjustmentBatch` | Bắt buộc khi completed | — | Batch for this allocation's posting period |
| `adjustment_line_id` | `UUID` | FK → `ValuationAdjustmentLine` | Bắt buộc khi completed | — | — |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Append-only |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `late_cost_id`: FK → `LateLandedCost`.
- `receipt_operation_line_id`: FK → `InventoryOperationLine`.
- `product_id`: FK → `Product`.
- `original_period_id`: FK → `AccountingPeriod`.
- `posting_period_id`: FK → `AccountingPeriod`.
- `adjustment_batch_id`: FK → `ValuationAdjustmentBatch`.
- `adjustment_line_id`: FK → `ValuationAdjustmentLine`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Unique `(late_cost_id, line_no)` and unique `allocation_natural_key_hash`. One command commits all exposure allocations and every required posting-period batch atomically; no quantity movement.

## 8. Behavioral Contract / Use Case liên quan

Không có liên kết trực tiếp được ghi nhận trong nguồn v3.10.1.
