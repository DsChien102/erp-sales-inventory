---
id: ENT-IC-08
type: business-entity
theme: theme-07
title: CountScopeSnapshot
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-08 — CountScopeSnapshot

## 1. Ý nghĩa nghiệp vụ

Frozen scope canonical của stock count

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

immutable scope hash + resolved membership

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu | Bắt buộc | Ghi chú |
|---|---|---|---|
| `count_scope_snapshot_id` | UUID | Có | PK |
| `tenant_id` | UUID | Có | Tenant isolation |
| `warehouse_id` | UUID | Có | Scope warehouse |
| `scope_type` | VARCHAR(20) | Có | `WAREHOUSE`, `PRODUCT`, `PRODUCT_GROUP`, `LOT` |
| `normalized_predicate` | JSONB | Có | Predicate canonical được dùng cho prospective-key guard |
| `resolved_product_ids` | JSONB | Có | Exact frozen Product membership; whole-warehouse có thể dùng sentinel/predicate theo contract |
| `resolved_lot_keys` | JSONB | Không | Bắt buộc với LOT scope |
| `source_master_versions` | JSONB | Có | Product/group/tracking versions cần tái hiện membership |
| `scope_hash` | CHAR(64) | Có | Stable canonical hash |
| `created_by` | UUID | Có | Audit |
| `created_at` | TIMESTAMPTZ | Có | Audit |

## 5. Quan hệ

immutable scope hash + resolved membership

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Immutable frozen scope được tạo trong atomic open transaction.

Snapshot bất biến sau open. Group membership về sau không được mutate snapshot; prospective LOT chỉ hợp lệ nếu normalized frozen scope cho phép.

## 8. Behavioral Contract / Use Case liên quan

Không có liên kết trực tiếp được ghi nhận trong nguồn v3.10.1.
