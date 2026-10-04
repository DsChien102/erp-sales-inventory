---
id: PRJ-04
type: read-model
theme: theme-07
title: OperationWorkQueue
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-04 — OperationWorkQueue

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-04` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `operation_id` | `UUID` | PK logic | Bắt buộc | — | — |
| `operation_type` | `VARCHAR(40)` | — | Bắt buộc | — | — |
| `status` | `VARCHAR(40)` | — | Bắt buộc | — | — |
| `store_id` | `UUID` | — | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | — | Bắt buộc | — | — |
| `source_type` | `VARCHAR(40)` | — | Bắt buộc | — | — |
| `source_document_id` | `VARCHAR(128)` | — | Nullable | `NULL` | — |
| `business_date` | `DATE` | — | Bắt buộc | — | — |
| `approval_required` | `BOOLEAN` | — | Bắt buộc | `false` | Luôn true với phiếu nhận hàng nhanh đã submit |
| `approval_case_id` | `UUID` | Tham chiếu logic → `ApprovalCase` | Nullable | `NULL` | — |
| `required_level` | `INTEGER` | — | Nullable | `NULL` | — |
| `lock_status` | `VARCHAR(20)` | — | Nullable | `NULL` | — |
| `unknown_since` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `assignee_id` | `UUID` | — | Nullable | `NULL` | — |
| `version` | `BIGINT` | — | Bắt buộc | — | Source aggregate version |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
| `as_of` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |

## 4. Nguồn dữ liệu

Xem Entity/ledger references được ghi trực tiếp trong data shape nguồn.

## 5. Projection rules

Các rule derive được giữ nguyên trong ghi chú của data shape nguồn.

## 6. Consistency và freshness

Consistency/time semantics nghiệp vụ xem `DOM-COM`. Contract thực thi của outcome thuộc work slice lúc review để implement.

## 7. Query shape

Query/filter/paging contract được giữ ở BC/API technical source nếu có.

## 8. Rebuild / backfill

Xem `PROC-01` và BC reconciliation nếu projection tham gia rebuild.

## 9. Failure / degradation

Theo technical/finality contract của baseline v3.10.1.

## 10. Verification

Đối chiếu data shape, source sequence/as-of và các BC/query tiêu thụ projection.
