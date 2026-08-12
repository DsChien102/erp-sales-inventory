---
id: ENT-IC-02
type: business-entity
theme: theme-07
title: ApprovalCase
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-02 — ApprovalCase

## 1. Ý nghĩa nghiệp vụ

Snapshot route, quyết định và actor

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

FK operation/policy version

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `approval_case_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `subject_type` | `VARCHAR(32)` | — | Bắt buộc | `INVENTORY_OPERATION` | `INVENTORY_OPERATION`, `STOCK_COUNT_SESSION`; mở rộng phải version contract |
| `subject_id` | `UUID` | logical FK | Bắt buộc | — | Trỏ aggregate theo subject_type |
| `operation_id` | `UUID` | FK → `InventoryOperation` | Nullable | `NULL` | Bắt buộc khi subject_type=`INVENTORY_OPERATION`; NULL với stock count |
| `approval_scope` | `VARCHAR(24)` | — | Bắt buộc | `OPERATION` | `OPERATION`, `LINE_EXCEPTION`, `STOCK_COUNT_VARIANCE`, `STATE_CHANGE` |
| `subject_line_id` | `UUID` | FK → `InventoryOperationLine` | Nullable | `NULL` | Chỉ dùng `LINE_EXCEPTION` |
| `subject_snapshot` | `JSONB` | — | Bắt buộc | `{}` | Immutable business/evidence snapshot; stock count bind session/scope/cutoff/round/variance/basis/lock; `STATE_CHANGE` bind `state_change_basis_id + basis_hash` |
| `subject_snapshot_hash` | `CHAR(64)` | — | Bắt buộc | — | Stable hash của exact subject snapshot |
| `predecessor_case_id` | `UUID` | FK → `ApprovalCase` | Nullable | `NULL` | Case trước khi request recount/basis stale |
| `superseded_by_case_id` | `UUID` | FK → `ApprovalCase` | Nullable | `NULL` | Successor case; không rewrite decision cũ |
| `superseded_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `approval_policy_version_id` | `UUID` | FK → `ApprovalPolicy` | Bắt buộc | — | Policy exact version |
| `required_approval_level` | `INTEGER` | — | Bắt buộc | — | Cấp cao nhất cần đáp ứng |
| `requester_id` | `UUID` | FK → `User` | Bắt buộc | — | Maker/request owner |
| `excluded_actor_ids` | `JSONB` | — | Bắt buộc | `[]` | Actor không được duyệt; stock count gồm mọi count/recount contributor của snapshot |
| `risk_value_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | `Σ abs(line_amount_vnd)` khi có risk value |
| `risk_lines_snapshot` | `JSONB` | — | Bắt buộc | `[]` | Quantity + exact cost/value basis/version từng dòng |
| `eligible_approvers_snapshot` | `JSONB` | — | Bắt buộc | `[]` | Route snapshot sau khi loại excluded actors |
| `status` | `VARCHAR(30)` | — | Bắt buộc | `PENDING` | `PENDING`, `APPROVED`, `REJECTED`, `RECOUNT_REQUIRED`, `CANCELLED`, `SUPERSEDED` |
| `decision_level` | `INTEGER` | — | Nullable | `NULL` | Có khi đã quyết định |
| `decision_actor_id` | `UUID` | FK → `User` | Nullable | `NULL` | Recheck permission/scope tại decision time |
| `decision` | `VARCHAR(24)` | — | Nullable | `NULL` | `APPROVE`, `REJECT`, `REQUEST_RECOUNT` theo subject contract |
| `decision_reason` | `TEXT` | — | Nullable | `NULL` | Bắt buộc với `REJECT/REQUEST_RECOUNT` |
| `decided_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `submitted_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | — |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | First valid decision wins/CAS |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `subject_id`: logical FK.
- `operation_id`: FK → `InventoryOperation`.
- `subject_line_id`: FK → `InventoryOperationLine`.
- `predecessor_case_id`: FK → `ApprovalCase`.
- `superseded_by_case_id`: FK → `ApprovalCase`.
- `approval_policy_version_id`: FK → `ApprovalPolicy`.
- `requester_id`: FK → `User`.
- `decision_actor_id`: FK → `User`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Maker và mọi `excluded_actor_ids` không được quyết định case đó. Một approver đủ `required_approval_level` quyết định; không tuần tự qua các cấp. Với StockCountSession, chỉ một case `PENDING` cho current `(session_id, final_submission_hash, count_adjustment_basis_hash)`; request recount hoặc basis stale tạo successor, giữ case trước bất biến.

## 7. Quy tắc và Điều kiện bắt buộc

Maker và mọi `excluded_actor_ids` không được quyết định case đó. Một approver đủ `required_approval_level` quyết định; không tuần tự qua các cấp. Với StockCountSession, chỉ một case `PENDING` cho current `(session_id, final_submission_hash, count_adjustment_basis_hash)`; request recount hoặc basis stale tạo successor, giữ case trước bất biến.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IO-10`
- `BC-IC-02`
- `BC-IC-03`
