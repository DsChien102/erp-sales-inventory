---
id: ENT-IV-05
type: business-entity
theme: theme-07
title: ValuationAdjustmentBatch
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-05 — ValuationAdjustmentBatch

## 1. Ý nghĩa nghiệp vụ

Header batch điều chỉnh cuối kỳ/giữa kỳ

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

FK cost run; batch type/period

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `adjustment_batch_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `batch_type` | `VARCHAR(30)` | — | Bắt buộc | — | `PERIOD_CLOSE`, `AD_HOC`, `LATE_LANDED_COST`, `CORRECTION` |
| `run_id` | `UUID` | FK → `CostCalculationRun` | Nullable | `NULL` | Bắt buộc với period close từ run |
| `accounting_period_id` | `UUID` | FK → `AccountingPeriod` | Bắt buộc | — | Posting period |
| `cutoff_valuation_sequence` | `BIGINT` | — | Nullable | `NULL` | Unified valuation cutoff của costing publication |
| `cutoff_ledger_sequence` | `BIGINT` | — | Nullable | `NULL` | Quantity audit cursor |
| `cutoff_value_sequence` | `BIGINT` | — | Nullable | `NULL` | Value audit cursor |
| `reconciliation_baseline_hash` | `CHAR(64)` | — | Nullable | `NULL` | Binds authoritative COGS/carrying baseline used to derive incremental delta |
| `cutoff_at` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
| `total_amount` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Bằng tổng line delta |
| `currency` | `CHAR(3)` | — | Bắt buộc | — | — |
| `status` | `VARCHAR(30)` | — | Bắt buộc | `DRAFT` | — |
| `published_by` | `UUID` | FK → `User` | Nullable | `NULL` | — |
| `published_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `outbox_correlation_id` | `UUID` | — | Nullable | `NULL` | Trace commit/event |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Concurrency |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `run_id`: FK → `CostCalculationRun`.
- `accounting_period_id`: FK → `AccountingPeriod`.
- `published_by`: FK → `User`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái



## 7. Quy tắc và Điều kiện bắt buộc

Các constraint được giữ trực tiếp trong bảng thuộc tính nguồn.

## 8. Behavioral Contract / Use Case liên quan

Không có liên kết trực tiếp được ghi nhận trong nguồn v3.10.1.
