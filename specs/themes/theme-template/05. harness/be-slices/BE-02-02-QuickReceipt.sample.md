---
id: BE-02-02
type: be-slice
theme: theme-07
title: Chuẩn bị nhập hàng nhanh
owner: SE
status: BLOCKED
sample_of: BE-SLICE.template.md
sample_status: DERIVED_SAMPLE
---
# BE-02-02 — Chuẩn bị nhập hàng nhanh

## 1. Mục tiêu

Hiện thực backend behavior của `UC-02-02`: tạo/sửa Quick Receipt draft an toàn, dùng lại InventoryOperation architecture và Foundation Idempotency; phần Submit chỉ được mở sau khi BA chốt boundary UC/UIF.

## 2. Use Case

- Chính: `UC-02-02`.
- Acceptance chắc chắn trong scope draft: validation/master data, multi-product/UOM, duplicate guard, idempotency retry.
- Acceptance Submit (`AS-UC-02-02-01/05`) hiện bị blocker về ownership transition với `UIF-02-T13`.

## 3. Scope

### 3.1 Owns

- Application Command/handler để tạo/cập nhật Quick Receipt draft.
- Application orchestration: resolve context/master data → load/create Aggregate → gọi Aggregate behavior → persist cùng idempotency result.
- Structured application result/error mapping.
- Submit Application Command **chỉ sau khi blocker được giải quyết**.

### 3.2 Does not own

- Aggregate lifecycle/invariants.
- Product/Supplier master.
- Approval decision của approver.
- Screen rendering.
- Inventory movement execution.

## 4. Nguồn đầu vào

- `UC-02-02`.
- `BC-IO-16`; `BC-IC-07` nếu Submit được xác nhận thuộc UC.
- `AGG-IO-01`.
- `FND-01`.
- Product/Supplier/Warehouse dependency contracts.
- Quyết định `T7-DR-103/104/118/119/121`.

## 5. Application Command / Query

### `MaintainQuickReceiptDraftCommand` *(tên minh họa)*

Payload ứng dụng bao gồm operation identity/version và dữ liệu Quick Receipt draft cần thiết; command sử dụng common request identity/idempotency semantics.

### `SubmitInventoryOperationCommand`

**BLOCKED** trong Slice này cho tới khi BA đồng bộ `UC-02-02`, `UC-02-03` và `UIF-02-T13`.

## 6. Application orchestration

Draft path:

1. Resolve tenant/store/default warehouse/business date.
2. Check permission/scope/capability.
3. Resolve Supplier, Product, UOM và tracking policy từ owner domain.
4. Begin idempotency qua `FND-01`.
5. Load/create `AGG-IO-01` theo version.
6. Gọi Aggregate behavior để update draft.
7. Persist Aggregate + complete idempotency result trong cùng transaction.
8. Trả stable operation ID/version + validation findings.

## 7. Architecture dependencies

- `AGG-IO-01 — InventoryOperation`.
- `FND-01 — Inventory Idempotency`.
- Approval capability nếu/when Submit được mở.

## 8. Published API / Event

Nguồn hiện map BC-IO-16 tới:

- `POST /v1/inventory-operations`
- `PUT /v1/inventory-operations/{id}`

Submit hiện map tới `POST /v1/inventory-operations/{id}/submission`, nhưng ownership trong Slice còn BLOCKED.

Không phát minh event mới cho draft path.

## 9. Error / Permission behavior

Ít nhất phải preserve semantics của:

- `OPERATION_NOT_DRAFT`
- `VERSION_CONFLICT`
- `IDEMPOTENCY_PAYLOAD_MISMATCH`
- `SOURCE_VERSION_STALE`
- permission/scope/capability failures

## 10. Verification

- Create/update draft đúng BC-IO-16.
- Same idempotency key+payload replay cùng result.
- Same key khác payload conflict.
- Duplicate Product+UOM bị chặn.
- LOT/UOM policy không bị Application tự chế.
- Không movement/approval trong maintain draft.
- Submit tests chỉ được mở khi boundary blocker đóng.

## 11. Delivery

`BLOCKED` một phần bởi `SPEC-BOUNDARY-UC-02-02-SUBMIT`.
