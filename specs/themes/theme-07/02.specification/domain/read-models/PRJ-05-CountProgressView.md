---
id: PRJ-05
type: read-model
theme: theme-07
title: CountProgressView
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-05 — CountProgressView

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-05` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `session_id` | `UUID` | PK logic | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | — | Bắt buộc | — | — |
| `status` | `VARCHAR(30)` | — | Bắt buộc | — | — |
| `scope_hash` | `CHAR(64)` | — | Bắt buộc | — | — |
| `cutoff_sequence` | `BIGINT` | — | Bắt buộc | — | — |
| `total_lines` | `INTEGER` | — | Bắt buộc | `0` | — |
| `uncounted_lines` | `INTEGER` | — | Bắt buộc | `0` | — |
| `counted_lines` | `INTEGER` | — | Bắt buộc | `0` | — |
| `recount_lines` | `INTEGER` | — | Bắt buộc | `0` | — |
| `variance_lines` | `INTEGER` | — | Bắt buộc | `0` | — |
| `pending_approval_lines` | `INTEGER` | — | Bắt buộc | `0` | — |
| `lock_id` | `UUID` | Tham chiếu logic → `InventoryLock` | Nullable | `NULL` | — |
| `last_activity_at` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
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
