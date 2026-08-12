---
id: ENT-IC-05
type: business-entity
theme: theme-07
title: StockCountLine
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-05 — StockCountLine

## 1. Ý nghĩa nghiệp vụ

Materialized balance key, book/count/recount

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

FK session; unique session + balance key

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `stock_count_line_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `session_id` | `UUID` | FK → `StockCountSession` | Bắt buộc | — | — |
| `line_no` | `INTEGER` | UK thành phần | Bắt buộc | — | Stable within session |
| `physical_count_key_hash` | `CHAR(64)` | UK thành phần | Bắt buộc | — | Hash Warehouse+Product+stock_state+lot_key |
| `book_balance_ids_snapshot` | `JSONB` | — | Bắt buộc | `[]` | One or more underlying balance IDs; Phase 1 open guard ensures no unresolved/mixed valuation state |
| `product_id` | `UUID` | FK → `Product` | Bắt buộc | — | — |
| `stock_state` | `VARCHAR(40)` | — | Bắt buộc | — | Physical state observable/selected; valuation_state không thuộc physical key |
| `lot_id` | `UUID` | FK → `Lot` | Nullable | `NULL` | — |
| `lot_key_snapshot` | `VARCHAR(128)` | — | Bắt buộc | — | Stable sentinel khi non-lot |
| `base_uom_id` | `UUID` | FK → `ProductUnit` | Bắt buộc | — | Count authority |
| `base_uom_snapshot` | `JSONB` | — | Bắt buộc | — | Label/precision/step |
| `is_unexpected_key` | `BOOLEAN` | — | Bắt buộc | `false` | Physical key không có trong book snapshot nhưng hợp frozen scope |
| `unexpected_identity_snapshot` | `JSONB` | — | Nullable | `NULL` | Product/state/tracking/lot attributes captured/revalidated |
| `book_quantity_base` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Không lộ trước FIRST submit |
| `first_submission_id` | `UUID` | FK → `StockCountSubmission` | Nullable | `NULL` | Projection ref |
| `latest_recount_submission_id` | `UUID` | FK → `StockCountSubmission` | Nullable | `NULL` | Projection ref |
| `final_count_quantity_base` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Latest accepted physical count |
| `variance_quantity_base` | `DECIMAL(20,6)` | — | Nullable | `NULL` | final - book |
| `surplus_value_basis_snapshot` | `JSONB` | — | Nullable | `NULL` | Bắt buộc trước approval/adjustment nếu variance > 0 |
| `surplus_value_basis_hash` | `CHAR(64)` | — | Nullable | `NULL` | Exact authoritative source/version |
| `shortage_official_cost_version_id` | `UUID` | FK → `OfficialCostVersion` | Nullable | `NULL` | Snapshot risk basis khi variance < 0 |
| `count_adjustment_basis_hash` | `CHAR(64)` | — | Nullable | `NULL` | Bind line into current approval snapshot |
| `adjustment_operation_line_id` | `UUID` | FK → `InventoryOperationLine` | Nullable | `NULL` | Chỉ có khi non-zero variance approved/committed |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Projection CAS |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `session_id`: FK → `StockCountSession`.
- `product_id`: FK → `Product`.
- `lot_id`: FK → `Lot`.
- `base_uom_id`: FK → `ProductUnit`.
- `first_submission_id`: FK → `StockCountSubmission`.
- `latest_recount_submission_id`: FK → `StockCountSubmission`.
- `shortage_official_cost_version_id`: FK → `OfficialCostVersion`.
- `adjustment_operation_line_id`: FK → `InventoryOperationLine`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

`StockCountLine` là **current projection theo PhysicalCountKey**, không phải nơi lưu lịch sử nhập số. Evidence bất biến nằm ở `StockCountSubmission`.

Unique active physical line per `(session_id, physical_count_key_hash)`. Valuation state không xuất hiện trong physical count key; unresolved/mixed valuation composition bị chặn tại session open thay vì bắt counter phân biệt accounting state bằng mắt.

## 8. Behavioral Contract / Use Case liên quan

- `UC-08-02`
