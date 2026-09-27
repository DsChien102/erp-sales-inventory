---
id: BE-03-03
type: be-slice
theme: theme-07
title: "Xác nhận giá trị"
owner: SE
status: DRAFT
source_baseline: v3.12.0
materialization: template-migration
---
# BE-03-03 — Xác nhận giá trị

## 1. Mục tiêu

> **Carry-forward v3.12.0:** Slice này được giữ để bảo toàn delivery/UI mapping của v3.11.0, nhưng các UC lịch sử `UC-03-03` đã được hợp nhất. Nguồn semantic canonical hiện hành là `UC-03-01`. Không được dùng tên/ranh giới UC cũ để tạo business rule mới; consolidation vật lý của Slice/Screen sẽ đi cùng lượt parity downstream.

Hiện thực backend outcome đã được đặc tả bởi `UC-03-01`; Slice không tạo thêm business behavior.

## 2. Use Case

- `UC-03-01`

## 3. Scope

### 3.1 Owns

Application behavior/orchestration cần để hiện thực UC theo technical trace nguồn v3.10.1.

### 3.2 Does not own

Business rule, Domain/Entity và Screen Contract; các nguồn đó được tham chiếu thay vì sao chép.

## 4. Nguồn đầu vào

- `UC-03-01`
- `BC-IV-01`
- `SBC-COM-01`
- `SBC-COM-02`
- `SBC-COM-03`
- `SBC-COM-04`

## 5. Application Command / Query

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IV-01 | ConfirmReceiptDirectCost | API-C-20 — POST /v1/receipt-valuations/confirm | Receipt valuation + value/state movement + balance + outbox | EVT-IV-03 ReceiptValuationConfirmed | TST-BC-IV-01 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 6. Application orchestration

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IV-01 | ConfirmReceiptDirectCost | API-C-20 — POST /v1/receipt-valuations/confirm | Receipt valuation + value/state movement + balance + outbox | EVT-IV-03 ReceiptValuationConfirmed | TST-BC-IV-01 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 7. Architecture dependencies

- `FND-TECH-01`
- `BC-IV-01`
- `SBC-COM-01`
- `SBC-COM-02`
- `SBC-COM-03`
- `SBC-COM-04`

## 8. Published API / Event

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IV-01 | ConfirmReceiptDirectCost | API-C-20 — POST /v1/receipt-valuations/confirm | Receipt valuation + value/state movement + balance + outbox | EVT-IV-03 ReceiptValuationConfirmed | TST-BC-IV-01 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

## 9. Error / Permission behavior

Theo mục Ngoại lệ/thất bại của `UC-03-01` và common technical contract.

## 10. Verification

Acceptance scenarios `AS-UC-03-01-*` và test prefix được ghi trong technical trace nguồn nếu có.

## 11. Delivery

Chưa có implementation delivery trong baseline v3.10.1; Slice được materialize để phù hợp template mới.
