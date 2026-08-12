---
id: PRJ-02
type: read-model
theme: theme-07
title: StockCardView
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-02 — StockCardView

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-02` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `product_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `lot_id` | `UUID` | Khóa projection | Nullable | `NULL` | — |
| `movement_id` | `UUID` | Tham chiếu logic → `InventoryMovement` | Bắt buộc | — | Unique row identity |
| `ledger_sequence` | `BIGINT` | — | Bắt buộc | — | Stable ordering |
| `operation_id` | `UUID` | Tham chiếu logic → `InventoryOperation` | Bắt buộc | — | — |
| `operation_type` | `VARCHAR(40)` | — | Bắt buộc | — | — |
| `business_date` | `DATE` | — | Bắt buộc | — | — |
| `recorded_at` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
| `stock_state` | `VARCHAR(40)` | — | Bắt buộc | — | — |
| `quantity_delta` | `DECIMAL(20,6)` | — | Bắt buộc | — | — |
| `running_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | — | Tại ledger sequence |
| `source_type` | `VARCHAR(40)` | — | Bắt buộc | — | — |
| `source_document_id` | `VARCHAR(128)` | — | Nullable | `NULL` | — |
| `as_of` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |

## 4. Nguồn dữ liệu

Xem Entity/ledger references được ghi trực tiếp trong data shape nguồn.

## 5. Projection rules

Các rule derive được giữ nguyên trong ghi chú của data shape nguồn.

## 6. Consistency và freshness

Xem `DOM-COM` và `FND-TECH-01` cho consistency/time semantics của baseline.

## 7. Query shape

Query/filter/paging contract được giữ ở BC/API technical source nếu có.

## 8. Rebuild / backfill

Xem `PROC-01` và BC reconciliation nếu projection tham gia rebuild.

## 9. Failure / degradation

Theo technical/finality contract của baseline v3.10.1.

## 10. Verification

Đối chiếu data shape, source sequence/as-of và các BC/query tiêu thụ projection.
