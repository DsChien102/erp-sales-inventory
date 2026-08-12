---
id: PRJ-07
type: read-model
theme: theme-07
title: ValuationWorkbenchView
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-07 — ValuationWorkbenchView

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-07` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `run_id` | `UUID` | PK logic | Bắt buộc | — | — |
| `accounting_period_id` | `UUID` | — | Bắt buộc | — | — |
| `status` | `VARCHAR(30)` | — | Bắt buộc | — | — |
| `scope_hash` | `CHAR(64)` | — | Bắt buộc | — | — |
| `cutoff_ledger_sequence` | `BIGINT` | — | Bắt buộc | — | — |
| `cutoff_value_sequence` | `BIGINT` | — | Bắt buộc | — | — |
| `product_count` | `INTEGER` | — | Bắt buộc | `0` | — |
| `blocker_count` | `INTEGER` | — | Bắt buộc | `0` | — |
| `dirty_scope_count` | `INTEGER` | — | Bắt buộc | `0` | — |
| `moving_result_hash` | `CHAR(64)` | — | Nullable | `NULL` | — |
| `periodic_result_hash` | `CHAR(64)` | — | Nullable | `NULL` | — |
| `selected_method` | `VARCHAR(30)` | — | Nullable | `NULL` | — |
| `supersedes_run_id` | `UUID` | Tham chiếu logic → `CostCalculationRun` | Nullable | `NULL` | — |
| `calculated_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `published_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
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
