---
id: ENT-IV-09
type: business-entity
theme: theme-07
title: ProductCostResult
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-09 — ProductCostResult

## 1. Ý nghĩa nghiệp vụ

Kết quả costing immutable theo Product trong một CostCalculationRun

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

FK run + product; unique run + product; result hash

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `product_cost_result_id` | `UUID` | PK | Bắt buộc | Sinh UUID | Immutable result line |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `run_id` | `UUID` | FK → `CostCalculationRun` | Bắt buộc | — | Unique `(run_id, product_id)` |
| `product_id` | `UUID` | FK → `Product` | Bắt buộc | — | Cost authority scope |
| `base_uom_id` | `UUID` | FK → `ProductUnit` | Bắt buộc | — | Official Cost normalization unit |
| `valuation_fact_range` | `JSONB` | — | Bắt buộc | — | Ordered valuation sequence range/ordinals included |
| `valuation_fact_hash` | `CHAR(64)` | — | Bắt buộc | — | Immutable Product fact-set hash |
| `opening_base_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | — |
| `opening_value_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | — |
| `ending_base_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Negative invalid without explicit policy |
| `moving_average_result` | `JSONB` | — | Bắt buộc | — | Includes unit cost/target COGS/ending value or explicit result state |
| `periodic_average_result` | `JSONB` | — | Bắt buộc | — | Same input fact set as moving result |
| `selected_method` | `VARCHAR(30)` | — | Bắt buộc | — | Snapshot of locked policy, not reviewer choice |
| `predecessor_official_cost_version_id` | `UUID` | FK → `OfficialCostVersion` | Nullable | `NULL` | Current official cost before publication |
| `proposed_official_unit_cost` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Null when `NO_NEW_COST_BASIS` |
| `target_cumulative_cogs_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Target at cutoff |
| `authoritative_cogs_baseline_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Includes original issue COGS + prior true-ups/corrections through cutoff |
| `cogs_reconciliation_delta_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Target minus authoritative baseline |
| `target_ending_inventory_value_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Target at cutoff |
| `authoritative_carrying_value_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Includes receipt/late-cost/previous adjustments/corrections |
| `ending_inventory_reconciliation_delta_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Target minus current carrying value |
| `result_state` | `VARCHAR(40)` | — | Bắt buộc | — | `READY`, `BLOCKED`, `NO_NEW_COST_BASIS`; zero unit cost is allowed only with provenance |
| `blocker_codes` | `JSONB` | — | Bắt buộc | `[]` | Product-level blockers incl. negative quantity/value |
| `reconciliation_baseline_hash` | `CHAR(64)` | — | Bắt buộc | — | Binds COGS/carrying baseline |
| `result_hash` | `CHAR(64)` | — | Bắt buộc | — | Binds all Product calculation/reconciliation facts |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Immutable |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `run_id`: FK → `CostCalculationRun`.
- `product_id`: FK → `Product`.
- `base_uom_id`: FK → `ProductUnit`.
- `predecessor_official_cost_version_id`: FK → `OfficialCostVersion`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Rerun trên cùng valuation facts và cùng authoritative reconciliation baseline phải tạo delta bằng 0. `NO_NEW_COST_BASIS` không tạo OfficialCostVersion mới; predecessor vẫn còn hiệu lực. Ending quantity bằng 0 vẫn có thể có COGS true-up nếu goods-available basis hợp lệ.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IV-02`
- `BC-IV-03`
