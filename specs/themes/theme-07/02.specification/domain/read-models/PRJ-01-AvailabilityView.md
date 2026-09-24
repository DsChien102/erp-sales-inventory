---
id: PRJ-01
type: read-model
theme: theme-07
title: AvailabilityView
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-01 — AvailabilityView

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-01` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `store_id` | `UUID` | Tham chiếu logic → `Store` | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `product_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `grain` | `VARCHAR(10)` | Khóa projection | Bắt buộc | `PRODUCT` | `PRODUCT` hoặc `LOT` |
| `lot_id` | `UUID` | Khóa projection | Nullable | `NULL` | Bắt buộc khi `grain=LOT`; null khi `PRODUCT` |
| `stock_state` | `VARCHAR(40)` | Khóa projection | Bắt buộc | — | — |
| `physical_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Từ TransactionalBalance |
| `eligible_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Sau state/valuation/expiry eligibility |
| `reserved_quantity` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Bắt buộc ở `PRODUCT`, từ ReservationBucket cấp Product + Warehouse; **không có ở LOT** |
| `available_quantity` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Bắt buộc ở `PRODUCT`: eligible − reserved; **không suy ra ở LOT** trước allocation |
| `eligibility_breakdown` | `JSONB` | — | Bắt buộc | `[]` | Product-level reason + quantity cho phần physical không eligible; tổng reason phải khớp `physical−eligible` |
| `expiry_date` | `DATE` | — | Nullable | `NULL` | Chỉ với LOT; normalized date dùng tính eligibility |
| `expiry_date_precision` | `VARCHAR(10)` | — | Nullable | `NULL` | `DAY`, `MONTH`, `YEAR`; UI phải giữ precision gốc |
| `eligibility_status` | `VARCHAR(30)` | — | Bắt buộc | — | Eligible/expired/blocked… |
| `last_ledger_sequence` | `BIGINT` | — | Bắt buộc | `0` | Trace kỹ thuật, không mặc định hiển thị end-user |
| `reservation_bucket_version` | `BIGINT` | — | Nullable | `NULL` | Product grain only; trace/concurrency |
| `query_as_of` | `TIMESTAMPTZ` | — | Bắt buộc | — | Server snapshot time áp cho toàn response; UI diễn đạt là `Dữ liệu đến` |

**Bất biến BJ-01:** `reserved_quantity` và `available_quantity` không được phân bổ xuống LOT nếu chưa có PickAllocation authoritative. LOT row chỉ mang physical/eligible/expiry/eligibility.

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
