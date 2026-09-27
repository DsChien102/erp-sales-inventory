---
id: PRJ-09
type: read-model
theme: theme-07
title: TrustAndReconciliationView
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-09 — TrustAndReconciliationView

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-09` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `case_id` | `UUID` | PK logic | Bắt buộc | — | — |
| `case_type` | `VARCHAR(40)` | — | Bắt buộc | — | — |
| `severity` | `VARCHAR(20)` | — | Bắt buộc | — | — |
| `status` | `VARCHAR(30)` | — | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | — | Nullable | `NULL` | — |
| `product_id` | `UUID` | — | Nullable | `NULL` | — |
| `operation_id` | `UUID` | — | Nullable | `NULL` | — |
| `lock_id` | `UUID` | — | Nullable | `NULL` | — |
| `effect_status` | `VARCHAR(20)` | — | Nullable | `NULL` | NONE/COMMITTED/UNKNOWN |
| `expected_sequence` | `BIGINT` | — | Nullable | `NULL` | — |
| `actual_sequence` | `BIGINT` | — | Nullable | `NULL` | — |
| `assigned_to` | `UUID` | — | Nullable | `NULL` | — |
| `last_action_code` | `VARCHAR(80)` | — | Nullable | `NULL` | — |
| `resolution_code` | `VARCHAR(80)` | — | Nullable | `NULL` | — |
| `detected_at` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
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
