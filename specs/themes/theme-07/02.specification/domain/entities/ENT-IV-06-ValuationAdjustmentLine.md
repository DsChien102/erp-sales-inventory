---
id: ENT-IV-06
type: business-entity
theme: theme-07
title: ValuationAdjustmentLine
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-06 — ValuationAdjustmentLine

## 1. Ý nghĩa nghiệp vụ

Chi tiết COGS true-up, tồn cuối kỳ hoặc late-cost value-only

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

FK batch; source issue/value reference

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `adjustment_line_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `adjustment_batch_id` | `UUID` | FK → `ValuationAdjustmentBatch` | Bắt buộc | — | — |
| `line_no` | `INTEGER` | UK thành phần | Bắt buộc | — | Unique trong batch |
| `product_id` | `UUID` | FK → `Product` | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | FK → `Warehouse` | Nullable | `NULL` | Breakdown phân tích nếu có |
| `adjustment_type` | `VARCHAR(30)` | — | Bắt buộc | — | `COGS_TRUE_UP`, `ENDING_INVENTORY`, `LATE_LANDED_COST`, `OTHER_VALUE_ONLY` |
| `source_issue_line_id` | `UUID` | FK → `InventoryOperationLine` | Nullable | `NULL` | Bắt buộc với COGS true-up |
| `source_value_movement_id` | `UUID` | FK → `InventoryValueMovement` | Nullable | `NULL` | Source value nếu áp dụng |
| `quantity_basis` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Bắt buộc khi adjustment dựa trên quantity |
| `old_unit_cost` | `DECIMAL(20,6)` | — | Nullable | `NULL` | — |
| `new_unit_cost` | `DECIMAL(20,6)` | — | Nullable | `NULL` | — |
| `delta_amount` | `DECIMAL(20,6)` | — | Bắt buộc | — | Chỉ ghi delta |
| `currency` | `CHAR(3)` | — | Bắt buộc | — | — |
| `business_date` | `DATE` | — | Bắt buộc | — | — |
| `original_period_id` | `UUID` | FK → `AccountingPeriod` | Nullable | `NULL` | Kỳ gốc nếu khác posting period |
| `accounting_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Posting period |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Append-only sau publish |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `adjustment_batch_id`: FK → `ValuationAdjustmentBatch`.
- `product_id`: FK → `Product`.
- `warehouse_id`: FK → `Warehouse`.
- `source_issue_line_id`: FK → `InventoryOperationLine`.
- `source_value_movement_id`: FK → `InventoryValueMovement`.
- `original_period_id`: FK → `AccountingPeriod`.
- `accounting_period_id`: FK → `AccountingPeriod`.
- `created_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Unique `(adjustment_batch_id, line_no)`; tổng `delta_amount` của line phải bằng batch total.

## 8. Behavioral Contract / Use Case liên quan

Không có liên kết trực tiếp được ghi nhận trong nguồn v3.10.1.
