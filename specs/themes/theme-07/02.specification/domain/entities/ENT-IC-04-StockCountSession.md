---
id: ENT-IC-04
type: business-entity
theme: theme-07
title: StockCountSession
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-04 — StockCountSession

## 1. Ý nghĩa nghiệp vụ

Scope, cut-off và lifecycle kiểm kê

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

FK warehouse; unique active conflicting scope

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `session_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `store_id` | `UUID` | FK → `Store` | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | FK → `Warehouse` | Bắt buộc | — | — |
| `count_scope_snapshot_id` | `UUID` | FK → `CountScopeSnapshot` | Bắt buộc từ open | — | Frozen scope canonical |
| `scope_snapshot_hash` | `CHAR(64)` | — | Bắt buộc từ open | — | Bằng hash của CountScopeSnapshot |
| `cutoff_ledger_sequence` | `BIGINT` | — | Bắt buộc từ open | — | Chốt sau atomic barrier |
| `assigned_counter_id` | `UUID` | FK → `User` | Bắt buộc từ open | — | Counter authoritative |
| `assignment_version` | `BIGINT` | — | Bắt buộc | `1` | Recheck actor assignment |
| `assignment_snapshot` | `JSONB` | — | Bắt buộc | `{}` | Scope/role provenance; không suy từ UI |
| `status` | `VARCHAR(30)` | — | Bắt buộc | `DRAFT` | `DRAFT`, `OPEN`, `RECOUNT_REQUIRED`, `PRICE_BASIS_REQUIRED`, `PENDING_APPROVAL`, `COMPLETED`, `CANCELLED`, `UNKNOWN` |
| `lock_id` | `UUID` | FK → `InventoryLock` | Nullable | `NULL` | Bắt buộc từ `OPEN` đến trước final release |
| `latest_submission_id` | `UUID` | FK → `StockCountSubmission` | Nullable | `NULL` | Current evidence projection |
| `latest_approval_case_id` | `UUID` | FK → `ApprovalCase` | Nullable | `NULL` | Current case; historical cases qua lineage |
| `opened_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `completed_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | Cả zero variance và approved adjustment completion |
| `cancelled_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `completed_by` | `UUID` | FK → `User` | Nullable | `NULL` | System/approver actor theo path |
| `cancelled_by` | `UUID` | FK → `User` | Nullable | `NULL` | — |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Concurrency/CAS |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `store_id`: FK → `Store`.
- `warehouse_id`: FK → `Warehouse`.
- `count_scope_snapshot_id`: FK → `CountScopeSnapshot`.
- `assigned_counter_id`: FK → `User`.
- `lock_id`: FK → `InventoryLock`.
- `latest_submission_id`: FK → `StockCountSubmission`.
- `latest_approval_case_id`: FK → `ApprovalCase`.
- `completed_by`: FK → `User`.
- `cancelled_by`: FK → `User`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Zero variance không tạo ApprovalCase/InventoryOperation adjustment: session completion và lock release vẫn là một transaction có CommandReceipt/finality.

## 7. Quy tắc và Điều kiện bắt buộc

Zero variance không tạo ApprovalCase/InventoryOperation adjustment: session completion và lock release vẫn là một transaction có CommandReceipt/finality.

## 8. Behavioral Contract / Use Case liên quan

- `UC-08-03`
- `BC-IC-02`
