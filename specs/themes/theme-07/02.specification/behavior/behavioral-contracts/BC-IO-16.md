---
id: BC-IO-16
type: behavioral-contract
theme: theme-07
title: "Maintain operation draft"
owner: BA
status: FROZEN
source_baseline: v4.6.6
---
<a id="bc-io-16"></a>
# BC-IO-16 — Maintain operation draft

## 1. Ý định

Tạo hoặc sửa payload `DRAFT` cho **các operation có lifecycle nháp** mà không tạo movement/lot/approval.

> **Loại trừ bắt buộc:** `QUICK_RECEIPT` / UC-02-02 **không sử dụng BC-IO-16**. Dữ liệu nhập hàng nhanh trước submit chỉ tồn tại trong phiên UI; không tạo operation/receipt draft.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: Cross-cutting, ngoại trừ Quick Receipt.
- API: `API-C-25` chỉ phục vụ operation có draft; **không dùng cho Nhập hàng nhanh**.

## 3. Đầu vào nghiệp vụ

Create/update command idempotency key, `operation_request_id`, operation ID?, expected version?, source identity/version và payload draft của loại operation **có hỗ trợ draft**.

## 4. Điều kiện trước

Operation mới theo lifecycle cho phép draft hoặc status `DRAFT`; source current; permission/scope; optimistic version. Nếu `operation_type=QUICK_RECEIPT`, server phải từ chối việc dùng contract này vì Quick Receipt không maintain draft.

## 5. Quy tắc nghiệp vụ

Persist/update draft + CommandReceipt; validate theo loại operation; chưa khóa submitted payload hash và chưa tạo business outbox. Contract này không được dùng như cơ chế autosave cho `SCR-008/SCR-009/SCR-084` ở Quick Receipt.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Stable operation ID, draft version và validation findings **chỉ đối với operation có draft lifecycle**. Không có state effect cho Quick Receipt.

## 9. Kết quả và semantics lỗi

`OPERATION_NOT_DRAFT`, `VERSION_CONFLICT`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, `SOURCE_VERSION_STALE` áp dụng cho nhánh draft-supported; không phải error contract của UC-02-02.

## 10. Domain và UC sử dụng

- Entity/Read model: các operation/entity có draft lifecycle tương ứng.
- Trace: Cross-cutting `ST-20.01`; `SG-10`; `API-C-25`; synchronous result.
- **Không trace tới `UC-02-02`.**
