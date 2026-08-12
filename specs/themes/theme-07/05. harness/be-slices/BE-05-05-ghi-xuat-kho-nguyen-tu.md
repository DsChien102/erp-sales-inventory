---
id: BE-05-05
type: be-slice
theme: theme-07
title: "Ghi xuất kho nguyên tử"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# BE-05-05 — Ghi xuất kho nguyên tử

## 1. Mục tiêu

Hiện thực backend outcome đã được đặc tả bởi `UC-05-05`; Slice không tạo thêm business behavior.

## 2. Use Case

- `UC-05-05`

## 3. Scope

### 3.1 Owns

Application behavior/orchestration cần để hiện thực UC theo technical trace nguồn v3.10.1.

### 3.2 Does not own

Business rule, Domain/Entity và Screen Contract; các nguồn đó được tham chiếu thay vì sao chép.

## 4. Nguồn đầu vào

- `UC-05-05`
- `BC-IO-04`
- `BC-IO-05`
- `SBC-COM-01`
- `SBC-COM-02`
- `SBC-COM-03`
- `SBC-COM-04`

## 5. Application Command / Query

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-04 | CompleteOnlinePosCheckout | API-C-04 — POST /v1/pos-checkouts/inventory-completion | Issue/value movement + balance + result + outbox | EVT-IO-03 PosInventoryCompleted | TST-BC-IO-04 |
| BC-IO-05 | HandOverFulfillment | API-C-05 — POST /v1/fulfillments/{id}/handover | Source/allocation version recheck + actual handover <= picked−consumed + immutable HandoverEvidence + reservation consume + issue/value + balance + outbox | EVT-IO-04 FulfillmentHandedOver | TST-BC-IO-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 6. Application orchestration

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-04 | CompleteOnlinePosCheckout | API-C-04 — POST /v1/pos-checkouts/inventory-completion | Issue/value movement + balance + result + outbox | EVT-IO-03 PosInventoryCompleted | TST-BC-IO-04 |
| BC-IO-05 | HandOverFulfillment | API-C-05 — POST /v1/fulfillments/{id}/handover | Source/allocation version recheck + actual handover <= picked−consumed + immutable HandoverEvidence + reservation consume + issue/value + balance + outbox | EVT-IO-04 FulfillmentHandedOver | TST-BC-IO-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 7. Architecture dependencies

- `FND-TECH-01`
- `BC-IO-04`
- `BC-IO-05`
- `SBC-COM-01`
- `SBC-COM-02`
- `SBC-COM-03`
- `SBC-COM-04`

## 8. Published API / Event

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-04 | CompleteOnlinePosCheckout | API-C-04 — POST /v1/pos-checkouts/inventory-completion | Issue/value movement + balance + result + outbox | EVT-IO-03 PosInventoryCompleted | TST-BC-IO-04 |
| BC-IO-05 | HandOverFulfillment | API-C-05 — POST /v1/fulfillments/{id}/handover | Source/allocation version recheck + actual handover <= picked−consumed + immutable HandoverEvidence + reservation consume + issue/value + balance + outbox | EVT-IO-04 FulfillmentHandedOver | TST-BC-IO-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 9. Error / Permission behavior

Theo mục Ngoại lệ/thất bại của `UC-05-05` và common technical contract.

## 10. Verification

Acceptance scenarios `AS-UC-05-05-*` và test prefix được ghi trong technical trace nguồn nếu có.

## 11. Delivery

Chưa có implementation delivery trong baseline v3.10.1; Slice được materialize để phù hợp template mới.
