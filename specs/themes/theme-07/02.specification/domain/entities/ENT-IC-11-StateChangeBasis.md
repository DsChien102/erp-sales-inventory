---
id: ENT-IC-11
type: business-entity
theme: theme-07
title: StateChangeBasis
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-11 — StateChangeBasis

## 1. Ý nghĩa nghiệp vụ

Immutable exact basis cho state-change request/approval/execution

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

FK operation/line + exact source slices + policy version; basis hash

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `state_change_basis_id` | `UUID` | PK | Bắt buộc | Sinh UUID | Immutable request basis identity |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | Tenant scope |
| `operation_id` | `UUID` | FK → `InventoryOperation` | Bắt buộc | — | State-change operation |
| `operation_line_id` | `UUID` | FK → `InventoryOperationLine` | Bắt buộc | — | Exact line scope |
| `warehouse_id` | `UUID` | FK → `Warehouse` | Bắt buộc | — | — |
| `product_id` | `UUID` | FK → `Product` | Bắt buộc | — | — |
| `lot_id` | `UUID` | FK → `Lot` | Nullable | `NULL` | Theo tracking snapshot |
| `from_state` | `VARCHAR(40)` | — | Bắt buộc | — | Source physical state |
| `to_state` | `VARCHAR(40)` | — | Bắt buộc | — | Destination business state; không nhận `EXPIRED/VALUATION_PENDING/RETURN_PENDING/RTV_PENDING` từ user |
| `quantity_base` | `DECIMAL(20,6)` | — | Bắt buộc | — | `>0` |
| `source_balance_slices_snapshot` | `JSONB` | — | Bắt buộc | `[]` | 1..N exact `{balance_id,balance_version,valuation_state,quantity}`; tổng quantity đúng bằng request |
| `state_transition_policy_version_id` | `UUID` | FK → `StateTransitionPolicyVersion` | Bắt buộc | — | Exact policy used at submit |
| `policy_hash` | `CHAR(64)` | — | Bắt buộc | — | Must match policy version |
| `reason_snapshot` | `TEXT` | — | Nullable theo policy | `NULL` | Immutable from submit |
| `evidence_snapshot` | `JSONB` | — | Bắt buộc | `[]` | Exact evidence references/hashes theo policy |
| `business_date` | `DATE` | — | Bắt buộc | — | Expiry evaluation date |
| `expiry_fact_snapshot` | `JSONB` | — | Bắt buộc | `{}` | LOT expiry + derived expiry result/version |
| `reservation_impact_snapshot` | `JSONB` | — | Bắt buộc | `{}` | Preview eligibility/capacity/review signals; execution recheck authoritative state |
| `basis_hash` | `CHAR(64)` | — | Bắt buộc | — | SHA-256 canonical basis payload |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Maker/system actor |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Append-only |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `operation_id`: FK → `InventoryOperation`.
- `operation_line_id`: FK → `InventoryOperationLine`.
- `warehouse_id`: FK → `Warehouse`.
- `product_id`: FK → `Product`.
- `lot_id`: FK → `Lot`.
- `state_transition_policy_version_id`: FK → `StateTransitionPolicyVersion`.
- `created_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

`StateChangeBasis` không được update sau submit. Nếu policy/source balance/version/expiry/reservation facts làm basis không còn current trước execution, basis cũ không executable; approval case liên quan phải `SUPERSEDED`/được thay bằng case mới thay vì áp quyết định cũ lên payload mới.
## 5. Chi tiết thực thể Inventory Valuation

## 8. Behavioral Contract / Use Case liên quan

Không có liên kết trực tiếp được ghi nhận trong nguồn v3.10.1.
