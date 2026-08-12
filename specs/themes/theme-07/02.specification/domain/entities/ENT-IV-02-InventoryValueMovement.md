---
id: ENT-IV-02
type: business-entity
theme: theme-07
title: InventoryValueMovement
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-02 — InventoryValueMovement

## 1. Ý nghĩa nghiệp vụ

Ledger giá trị bất biến

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

FK operation/value batch; monotonic value sequence

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `value_movement_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `value_sequence` | `BIGINT` | UK | Bắt buộc | Cấp tuần tự | Monotonic trong tenant/shard |
| `valuation_sequence` | `BIGINT` | Chỉ mục ordering chung | Bắt buộc | Cấp từ valuation timeline | Ordering authoritative dùng chung với quantity movement cho costing |
| `within_transaction_ordinal` | `INTEGER` | — | Bắt buộc | `0` | Thứ tự deterministic của nhiều valuation fact trong cùng transaction |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `product_id` | `UUID` | FK → `Product` | Bắt buộc | — | Official value scope |
| `warehouse_id` | `UUID` | FK → `Warehouse` | Nullable | `NULL` | Bắt buộc khi gắn quantity operation |
| `operation_line_id` | `UUID` | FK → `InventoryOperationLine` | Nullable | `NULL` | Một trong hai source line |
| `valuation_adjustment_line_id` | `UUID` | FK → `ValuationAdjustmentLine` | Nullable | `NULL` | Một trong hai source line |
| `value_type` | `VARCHAR(40)` | — | Bắt buộc | — | Receipt, COGS, return, true-up… |
| `amount` | `DECIMAL(20,6)` | — | Bắt buộc | — | Signed delta |
| `currency` | `CHAR(3)` | — | Bắt buộc | — | — |
| `business_date` | `DATE` | — | Bắt buộc | — | Với direct receipt value: bằng `receipt_business_date` của receipt source; không dùng `recorded_at` hoặc ngày chứng từ thay thế |
| `recorded_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | — |
| `accounting_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Direct receipt value dùng kỳ chứa `receipt_business_date`; kỳ khóa legacy/recovery phải block/escalate, không back-post âm thầm |
| `original_period_id` | `UUID` | FK → `AccountingPeriod` | Nullable | `NULL` | Kỳ gốc với late/true-up |
| `source_identity` | `JSONB` | — | Bắt buộc | — | — |
| `source_identity_hash` | `CHAR(64)` | — | Bắt buộc | — | — |
| `reversal_of_value_movement_id` | `UUID` | FK → `InventoryValueMovement` | Nullable | `NULL` | Không tự tham chiếu/cycle |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Actor/system identity |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Append-only |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `product_id`: FK → `Product`.
- `warehouse_id`: FK → `Warehouse`.
- `operation_line_id`: FK → `InventoryOperationLine`.
- `valuation_adjustment_line_id`: FK → `ValuationAdjustmentLine`.
- `accounting_period_id`: FK → `AccountingPeriod`.
- `original_period_id`: FK → `AccountingPeriod`.
- `reversal_of_value_movement_id`: FK → `InventoryValueMovement`.
- `created_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Append-only; đúng một trong `operation_line_id` hoặc `valuation_adjustment_line_id` phải có giá trị. Value-only cấp tenant có thể không có kho nhưng phải giữ allocation basis ở source adjustment.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IO-04`
- `BC-IO-05`
- `BC-IO-07`
- `BC-IO-09`
- `BC-IO-11`
- `BC-IO-13`
- `BC-IC-03`
- `BC-IC-04`
- `BC-IV-02`
- `BC-IV-03`
- `BC-IV-04`
