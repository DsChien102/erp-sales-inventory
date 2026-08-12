---
id: ENT-IV-03
type: business-entity
theme: theme-07
title: CostCalculationRun
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-03 — CostCalculationRun

## 1. Ý nghĩa nghiệp vụ

Cut-off, input hash, hai phương pháp, blocker và publish state

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

unique run ID; tenant + period + scope

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `run_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `accounting_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Legacy compatibility alias; phải bằng `calculation_period_id` với period-close, không dùng để suy posting ở ad-hoc |
| `run_type` | `VARCHAR(30)` | — | Bắt buộc | — | `PERIOD_CLOSE` hoặc `AD_HOC` |
| `calculation_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Kỳ mà fact set được tính/đối soát |
| `posting_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Một run chỉ có đúng một posting period |
| `scope_origin` | `VARCHAR(40)` | — | Bắt buộc | — | `PERIOD_CLOSE_POLICY`, `LATE_COST_DIRTY`, `CORRECTION_DIRTY`… |
| `scope` | `JSONB` | — | Bắt buộc | — | Immutable Product scope |
| `scope_hash` | `CHAR(64)` | — | Bắt buộc | — | Stable scope identity |
| `dirty_scope_snapshot` | `JSONB` | — | Nullable | `NULL` | Exact Product + posting-period set + cause IDs khi source là DIRTY |
| `dirty_scope_version` | `VARCHAR(80)` | — | Nullable | `NULL` | Current source-owned dirty-scope version |
| `dirty_scope_hash` | `CHAR(64)` | — | Nullable | `NULL` | Binds exact Product/cause membership |
| `cutoff_valuation_sequence` | `BIGINT` | — | Bắt buộc | — | Authoritative costing cutoff trên unified valuation timeline |
| `cutoff_ledger_sequence` | `BIGINT` | — | Bắt buộc | — | Quantity audit cursor; không suy cross-ledger order |
| `cutoff_value_sequence` | `BIGINT` | — | Bắt buộc | — | Value audit cursor; không suy cross-ledger order |
| `input_hash` | `CHAR(64)` | — | Bắt buộc | — | Toàn bộ run input snapshot gồm timeline/scope/policy/period |
| `product_result_set_hash` | `CHAR(64)` | — | Nullable | `NULL` | Aggregate hash của immutable ProductCostResult set |
| `status` | `VARCHAR(30)` | — | Bắt buộc | `DRAFT` | Không có `CANCELLED` Phase 1 |
| `moving_average_result_uri` | `TEXT` | — | Nullable | `NULL` | Immutable result set |
| `moving_average_result_hash` | `CHAR(64)` | — | Nullable | `NULL` | — |
| `periodic_average_result_uri` | `TEXT` | — | Nullable | `NULL` | Immutable result set |
| `periodic_average_result_hash` | `CHAR(64)` | — | Nullable | `NULL` | — |
| `selected_method_snapshot` | `JSONB` | — | Nullable | `NULL` | Snapshot policy method/version đã khóa cho kỳ; không phải reviewer override |
| `blockers_snapshot` | `JSONB` | — | Bắt buộc | `[]` | — |
| `supersedes_run_id` | `UUID` | FK → `CostCalculationRun` | Nullable | `NULL` | Re-run tạo ID mới |
| `calculated_by` | `UUID` | FK → `User` | Nullable | `NULL` | — |
| `calculated_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `published_by` | `UUID` | FK → `User` | Nullable | `NULL` | — |
| `published_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Publish recheck bằng expected version |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `accounting_period_id`: FK → `AccountingPeriod`.
- `calculation_period_id`: FK → `AccountingPeriod`.
- `posting_period_id`: FK → `AccountingPeriod`.
- `supersedes_run_id`: FK → `CostCalculationRun`.
- `calculated_by`: FK → `User`.
- `published_by`: FK → `User`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái



## 7. Quy tắc và Điều kiện bắt buộc

Các constraint được giữ trực tiếp trong bảng thuộc tính nguồn.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IV-02`
