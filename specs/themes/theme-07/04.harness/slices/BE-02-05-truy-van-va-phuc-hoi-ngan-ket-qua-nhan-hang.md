---
id: BE-02-05
type: be-slice
theme: theme-07
title: "Truy vấn và phục hồi ngắn kết quả nhận hàng"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# BE-02-05 — Truy vấn và phục hồi ngắn kết quả nhận hàng

## 1. Mục tiêu

Hiện thực backend outcome đã được đặc tả bởi `UC-02-05`; Slice không tạo thêm business behavior.

## 2. Use Case

- `UC-02-05`

## 3. Scope

### 3.1 Owns

Application behavior/orchestration cần để hiện thực UC theo technical trace nguồn v3.10.1.

### 3.2 Does not own

Business rule, Domain/Entity và Screen Contract; các nguồn đó được tham chiếu thay vì sao chép.

## 4. Nguồn đầu vào

- `UC-02-05`
- `BC-IO-02`
- `SBC-COM-01`
- `SBC-COM-03`
- `SBC-COM-04`

## 5. Application Command / Query

Xem [hợp đồng kỹ thuật dùng chung](../../02.specification/technical-contracts/FND-TECH-01.md#8-unknown-and-recovery-protocol).

| Contract | Handler | Adapter/API | Transaction boundary | Kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-02 result query | `QueryOperationResult` | `API-Q-04` — `GET /v1/inventory-operations/{id}` | Read-only authoritative operation/result/ledger evidence | `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; không mutation | `TST-API-Q-04` |

- Retry command chỉ dùng lại chính request envelope và fingerprint nguồn; payload khác phải trả idempotency conflict.
- Nếu bằng chứng không đủ, adapter tạo handoff reference cho BJ-17 thay vì tự kích hoạt authoritative reconciliation mutation từ BJ-02.

## 6. Application orchestration

Xem [hợp đồng kỹ thuật dùng chung](../../02.specification/technical-contracts/FND-TECH-01.md#8-unknown-and-recovery-protocol).

| Contract | Handler | Adapter/API | Transaction boundary | Kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-02 result query | `QueryOperationResult` | `API-Q-04` — `GET /v1/inventory-operations/{id}` | Read-only authoritative operation/result/ledger evidence | `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; không mutation | `TST-API-Q-04` |

- Retry command chỉ dùng lại chính request envelope và fingerprint nguồn; payload khác phải trả idempotency conflict.
- Nếu bằng chứng không đủ, adapter tạo handoff reference cho BJ-17 thay vì tự kích hoạt authoritative reconciliation mutation từ BJ-02.

## 7. Architecture dependencies

- `FND-TECH-01`
- `BC-IO-02`
- `SBC-COM-01`
- `SBC-COM-03`
- `SBC-COM-04`

## 8. Published API / Event

Xem [hợp đồng kỹ thuật dùng chung](../../02.specification/technical-contracts/FND-TECH-01.md#8-unknown-and-recovery-protocol).

| Contract | Handler | Adapter/API | Transaction boundary | Kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-02 result query | `QueryOperationResult` | `API-Q-04` — `GET /v1/inventory-operations/{id}` | Read-only authoritative operation/result/ledger evidence | `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; không mutation | `TST-API-Q-04` |

- Retry command chỉ dùng lại chính request envelope và fingerprint nguồn; payload khác phải trả idempotency conflict.
- Nếu bằng chứng không đủ, adapter tạo handoff reference cho BJ-17 thay vì tự kích hoạt authoritative reconciliation mutation từ BJ-02.

## 9. Error / Permission behavior

Theo mục Ngoại lệ/thất bại của `UC-02-05` và common technical contract.

## 10. Verification

Acceptance scenarios `AS-UC-02-05-*` và test prefix được ghi trong technical trace nguồn nếu có.

## 11. Delivery

Chưa có implementation delivery trong baseline v3.10.1; Slice được materialize để phù hợp template mới.
