---
id: ENT-IC-07
type: business-entity
theme: theme-07
title: ReconciliationCase
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-07 — ReconciliationCase

## 1. Ý nghĩa nghiệp vụ

Sai lệch, evidence, action và unlock gate

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

case type + affected scope + lifecycle

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `case_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `case_type` | `VARCHAR(40)` | — | Bắt buộc | — | UNKNOWN, source mismatch, ledger/projection mismatch… |
| `severity` | `VARCHAR(20)` | — | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | FK → `Warehouse` | Nullable | `NULL` | Affected scope |
| `product_id` | `UUID` | FK → `Product` | Nullable | `NULL` | Affected scope |
| `operation_id` | `UUID` | FK → `InventoryOperation` | Nullable | `NULL` | Affected scope |
| `accounting_period_id` | `UUID` | FK → `AccountingPeriod` | Nullable | `NULL` | Affected scope |
| `detected_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | — |
| `expected_evidence_refs` | `JSONB` | — | Nullable | `NULL` | — |
| `actual_evidence_refs` | `JSONB` | — | Nullable | `NULL` | — |
| `status` | `VARCHAR(30)` | — | Bắt buộc | `OPEN` | `OPEN`, `INVESTIGATING`, `RESOLVED`, `UNRESOLVED` |
| `assigned_to` | `UUID` | FK → `User` | Nullable | `NULL` | — |
| `actions` | `JSONB` | — | Bắt buộc | `[]` | Append-only action history trong case snapshot |
| `resolution_code` | `VARCHAR(80)` | — | Nullable | `NULL` | — |
| `resolution_evidence` | `JSONB` | — | Nullable | `NULL` | — |
| `resolution_evidence_hash` | `CHAR(64)` | — | Nullable | `NULL` | — |
| `locked_scope_id` | `UUID` | FK → `InventoryLock` | Nullable | `NULL` | — |
| `duplicate_of_case_id` | `UUID` | FK → `ReconciliationCase` | Nullable | `NULL` | Không tự tham chiếu |
| `reopened_from_case_id` | `UUID` | FK → `ReconciliationCase` | Nullable | `NULL` | Trace reopen |
| `resolved_by` | `UUID` | FK → `User` | Nullable | `NULL` | — |
| `resolved_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Concurrency |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `warehouse_id`: FK → `Warehouse`.
- `product_id`: FK → `Product`.
- `operation_id`: FK → `InventoryOperation`.
- `accounting_period_id`: FK → `AccountingPeriod`.
- `assigned_to`: FK → `User`.
- `locked_scope_id`: FK → `InventoryLock`.
- `duplicate_of_case_id`: FK → `ReconciliationCase`.
- `reopened_from_case_id`: FK → `ReconciliationCase`.
- `resolved_by`: FK → `User`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Tồn thấp/cận hạn không tạo Reconciliation Case.

## 7. Quy tắc và Điều kiện bắt buộc

Tồn thấp/cận hạn không tạo Reconciliation Case.

## 8. Behavioral Contract / Use Case liên quan

Không có liên kết trực tiếp được ghi nhận trong nguồn v3.10.1.
