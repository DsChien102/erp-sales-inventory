---
id: ENT-IC-03
type: business-entity
theme: theme-07
title: InventoryLock
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-03 — InventoryLock

## 1. Ý nghĩa nghiệp vụ

Khóa balance key/range có owner và lease

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

unique active lock target

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `lock_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `warehouse_id` | `UUID` | FK → `Warehouse` | Bắt buộc | — | — |
| `lock_type` | `VARCHAR(40)` | — | Bắt buộc | — | Count, reconciliation, migration, recovery… |
| `owner_type` | `VARCHAR(40)` | — | Bắt buộc | — | Loại aggregate sở hữu lock |
| `owner_id` | `UUID` | — | Bắt buộc | — | ID aggregate owner |
| `count_scope_snapshot_id` | `UUID` | FK → `CountScopeSnapshot` | Nullable | `NULL` | Bắt buộc với `lock_type=STOCK_COUNT` |
| `scope_type` | `VARCHAR(40)` | — | Bắt buộc | — | Key, range hoặc predicate |
| `scope_predicate_snapshot` | `JSONB` | — | Bắt buộc | — | Kiểm cả key hiện hữu và key có thể phát sinh |
| `scope_predicate_hash` | `CHAR(64)` | — | Bắt buộc | — | Stable scope identity |
| `materialized_key_snapshot` | `JSONB` | — | Nullable | `NULL` | Keys tại cut-off |
| `materialized_key_hash` | `CHAR(64)` | — | Nullable | `NULL` | Hash snapshot keys |
| `barrier_acquired_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | Stock-count barrier phải active trước khi cutoff được chốt |
| `cutoff_ledger_sequence` | `BIGINT` | — | Bắt buộc | — | Stock count: sequence được chốt sau barrier; không mutation scope nào commit sau sequence này khi lock active |
| `status` | `VARCHAR(20)` | — | Bắt buộc | `ACTIVE` | `ACTIVE`, `RELEASED`, `EXPIRED` |
| `acquired_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | — |
| `expires_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | Lease nếu áp dụng |
| `released_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `release_reason` | `TEXT` | — | Nullable | `NULL` | Bắt buộc khi release ngoài normal completion |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Concurrency |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `warehouse_id`: FK → `Warehouse`.
- `count_scope_snapshot_id`: FK → `CountScopeSnapshot`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Cần partial/exclusion constraint chống hai active lock có scope xung đột. Lock ứng dụng không thay row lock/CAS của balance.

## 7. Quy tắc và Điều kiện bắt buộc

Cần partial/exclusion constraint chống hai active lock có scope xung đột. Lock ứng dụng không thay row lock/CAS của balance.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IC-01`
- `BC-IC-05`
