---
id: BC-IO-16
type: behavioral-contract
theme: theme-07
title: Maintain operation draft
owner: BA
status: FROZEN
sample_of: BC.template.md
sample_status: NON_CANONICAL_EXAMPLE
---
# BC-IO-16 — Maintain operation draft

## 1. Ý định

Tạo hoặc sửa payload của một Inventory Operation đang ở `DRAFT` mà **không tạo movement, lot chính thức hoặc approval**.

## 2. Phạm vi áp dụng

Dùng chung cho các Use Case cần chuẩn bị/sửa Inventory Operation trước khi submit, trong đó có `UC-02-02`.

## 3. Đầu vào nghiệp vụ

- Create/update idempotency key.
- `operation_request_id`.
- `operation_id?`.
- `expected_version?`.
- Source identity/version.
- Draft payload.

## 4. Điều kiện trước

- Operation mới hoặc đang `DRAFT`.
- Source còn current.
- Actor có permission/scope hợp lệ.
- Expected version khớp khi sửa draft hiện có.

## 5. Quy tắc nghiệp vụ

- Persist hoặc update draft cùng `CommandReceipt`.
- Validate schema mềm trong khi draft.
- Chưa khóa submitted payload hash.
- Chưa tạo business outbox do submit/execution.

Với Quick Receipt, draft phải giữ được Supplier, receipt-item grouping, Product/UOM và dữ liệu LOT/classification cần thiết theo UC/Decision liên quan.

## 6. Điều kiện bắt buộc

- Payload chỉ mutable ở `DRAFT`.
- Retry cùng idempotency identity không được tạo draft/mutation trùng.
- Cùng key nhưng payload khác phải bị chặn.

## 7. Ảnh hưởng trạng thái

Không thay đổi lifecycle ngoài việc tạo/cập nhật `DRAFT` và tăng version phù hợp.

## 8. Tính nguyên tử và kết quả cuối

Draft mutation và `CommandReceipt` phải nằm cùng transaction authoritative của command.

## 9. Kết quả và semantics lỗi

Kết quả: stable operation ID, draft version và validation findings.

Lỗi chuẩn: `OPERATION_NOT_DRAFT`, `VERSION_CONFLICT`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, `SOURCE_VERSION_STALE`.

## 10. Domain và UC sử dụng

- Domain: Inventory Operations (`IO`).
- Entity: `ENT-IO-01`, `ENT-IO-02`, `ENT-IO-10`.
- Consumer pilot: `UC-02-02`.
