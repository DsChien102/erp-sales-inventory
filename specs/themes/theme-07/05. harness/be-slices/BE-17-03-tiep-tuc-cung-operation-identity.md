---
id: BE-17-03
type: be-slice
theme: theme-07
title: "Tiếp tục cùng operation identity"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# BE-17-03 — Tiếp tục cùng operation identity

## 1. Mục tiêu

Hiện thực backend outcome đã được đặc tả bởi `UC-17-03`; Slice không tạo thêm business behavior.

## 2. Use Case

- `UC-17-03`

## 3. Scope

### 3.1 Owns

Application behavior/orchestration cần để hiện thực UC theo technical trace nguồn v3.10.1.

### 3.2 Does not own

Business rule, Domain/Entity và Screen Contract; các nguồn đó được tham chiếu thay vì sao chép.

## 4. Nguồn đầu vào

- `UC-17-03`
- `BC-IC-05`
- `SBC-COM-01`
- `SBC-COM-02`
- `SBC-COM-03`
- `SBC-COM-04`

## 5. Application Command / Query

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 6. Application orchestration

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 7. Architecture dependencies

- `FND-TECH-01`
- `BC-IC-05`
- `SBC-COM-01`
- `SBC-COM-02`
- `SBC-COM-03`
- `SBC-COM-04`

## 8. Published API / Event

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 9. Error / Permission behavior

Theo mục Ngoại lệ/thất bại của `UC-17-03` và common technical contract.

## 10. Verification

Acceptance scenarios `AS-UC-17-03-*` và test prefix được ghi trong technical trace nguồn nếu có.

## 11. Delivery

Chưa có implementation delivery trong baseline v3.10.1; Slice được materialize để phù hợp template mới.
