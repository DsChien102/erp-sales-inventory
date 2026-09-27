---
id: PRJ-08
type: read-model
theme: theme-07
title: LowStockView
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-08 — LowStockView

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-08` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `product_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `available_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Product-level availability |
| `monitoring_config_status` | `VARCHAR(30)` | — | Bắt buộc | — | `CONFIGURED`, `NOT_CONFIGURED` |
| `threshold_quantity` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Bắt buộc khi CONFIGURED |
| `target_quantity` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Bắt buộc khi CONFIGURED |
| `suggested_quantity` | `DECIMAL(20,6)` | — | Nullable | `NULL` | `max(target - available, 0)`; null khi NOT_CONFIGURED |
| `policy_version_id` | `UUID` | Tham chiếu logic → policy ngoài miền | Nullable | `NULL` | Có khi CONFIGURED |
| `policy_source` | `VARCHAR(30)` | — | Nullable | `NULL` | Tenant default hoặc product override |
| `stock_level_status` | `VARCHAR(30)` | — | Bắt buộc | — | `OUT`, `LOW`, `NORMAL`, `NOT_CONFIGURED` |
| `near_expiry_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Dẫn xuất từ LOT |
| `expired_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Lượng LOT đã hết hạn còn physical |
| `near_expiry_days` | `INTEGER` | — | Nullable | `NULL` | Policy hiện hành |
| `near_expiry_action` | `VARCHAR(30)` | — | Nullable | `NULL` | `WARN` hoặc `BLOCK_SALE` |
| `expiry_attention` | `VARCHAR(40)` | — | Bắt buộc | `NONE` | `NONE`, `NEAR_EXPIRY_WARN`, `NEAR_EXPIRY_BLOCKED`, `HAS_EXPIRED_STOCK` |
| `last_ledger_sequence` | `BIGINT` | — | Bắt buộc | — | Trace kỹ thuật |
| `query_as_of` | `TIMESTAMPTZ` | — | Bắt buộc | — | Cùng snapshot với availability response |

Đây không phải `InventoryAlert`. `stock_level_status` và `expiry_attention` là hai dimension độc lập và có thể cùng khác NORMAL/NONE. Product override ưu tiên tenant default; `BLOCK_SALE` làm lượng tương ứng không eligible/available. Thiếu threshold/target phải trả `NOT_CONFIGURED`, không tự sinh policy.

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
