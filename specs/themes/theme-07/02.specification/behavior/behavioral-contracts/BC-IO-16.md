---
id: BC-IO-16
type: behavioral-contract
theme: theme-07
title: "Maintain operation draft"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-16"></a>
# BC-IO-16 — Maintain operation draft

## 1. Ý định

Tạo hoặc sửa payload draft mà không tạo movement/lot/approval.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Create/update command idempotency key, `operation_request_id`, operation ID?, expected version?, source identity/version, supplier reference khi là purchase receipt, draft receipt items và technical lines.

## 4. Điều kiện trước

Operation mới hoặc status `DRAFT`; source current; permission/scope; optimistic version; purchase receipt có đúng một Supplier đã tồn tại; Product/UOM đã tồn tại; mỗi receipt item có một transaction UOM; Quick không duplicate Product+UOM item.

## 5. Quy tắc nghiệp vụ

Persist/update draft + CommandReceipt; giữ receipt-item grouping khi một item materialize thành nhiều technical lines theo lot/state; validate schema mềm; chưa khóa submitted payload hash và chưa tạo business outbox.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Stable operation ID, draft version và validation findings.

## 9. Kết quả và semantics lỗi

`OPERATION_NOT_DRAFT`, `VERSION_CONFLICT`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, `SOURCE_VERSION_STALE`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/10`.
- Trace: Cross-cutting `ST-20.01`; `SG-10`; `API-C-25`; synchronous result.
