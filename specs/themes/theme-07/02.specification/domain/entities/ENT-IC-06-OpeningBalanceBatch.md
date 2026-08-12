---
id: ENT-IC-06
type: business-entity
theme: theme-07
title: OpeningBalanceBatch
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-06 — OpeningBalanceBatch

## 1. Ý nghĩa nghiệp vụ

Batch migration, control totals và immutable report

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

max one completed per tenant/baseline

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `batch_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `baseline_id` | `VARCHAR(128)` | UK thành phần | Bắt buộc | — | Tối đa một completed batch/tenant/baseline |
| `cutoff_at` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
| `scope_snapshot` | `JSONB` | — | Bắt buộc | — | Store/warehouse/product scope |
| `source_uri` | `TEXT` | — | Bắt buộc | — | Không chứa secret |
| `source_hash` | `CHAR(64)` | — | Bắt buộc | — | Bằng chứng input |
| `control_quantity_totals` | `JSONB` | — | Bắt buộc | — | Theo warehouse/key đã khóa |
| `control_value_totals` | `JSONB` | — | Bắt buộc | — | Theo product/currency |
| `status` | `VARCHAR(30)` | — | Bắt buộc | `DRAFT` | Preparation/approval/commit lifecycle |
| `approval_case_id` | `UUID` | FK → `ApprovalCase` | Nullable | `NULL` | — |
| `committed_operation_ids` | `JSONB` | — | Nullable | `NULL` | Stable ordered list |
| `immutable_report_uri` | `TEXT` | — | Nullable | `NULL` | Bắt buộc khi completed |
| `immutable_report_hash` | `CHAR(64)` | — | Nullable | `NULL` | Bắt buộc khi completed |
| `activation_from_status` | `VARCHAR(20)` | — | Nullable | `NULL` | Kỳ vọng `PREPARING` |
| `activation_to_status` | `VARCHAR(20)` | — | Nullable | `NULL` | Kỳ vọng `ACTIVE` |
| `completed_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Concurrency |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `approval_case_id`: FK → `ApprovalCase`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Staging trước commit là transient storage, không phải Dữ liệu gốc và không thuộc authoritative entity model.

## 7. Quy tắc và Điều kiện bắt buộc

Staging trước commit là transient storage, không phải Dữ liệu gốc và không thuộc authoritative entity model.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IC-04`
- `BC-IC-09`
