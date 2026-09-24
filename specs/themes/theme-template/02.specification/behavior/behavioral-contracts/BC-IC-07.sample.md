---
id: BC-IC-07
type: behavioral-contract
theme: theme-07
title: Submit inventory operation
owner: BA
status: FROZEN
sample_of: BC.template.md
sample_status: NON_CANONICAL_EXAMPLE
---
# BC-IC-07 — Submit inventory operation

## 1. Ý định

Khóa payload draft, tính/snapshot policy và risk, sau đó đưa operation sang tuyến xử lý sau submit.

## 2. Phạm vi áp dụng

Các Inventory Operation có bước submit. Với `QUICK_RECEIPT`, approval là bắt buộc.

## 3. Đầu vào nghiệp vụ

- Operation ID/version.
- Submit idempotency key.
- Requested execution context.

## 4. Điều kiện trước

- Draft hợp lệ.
- Source còn current.
- Có đủ price/FX basis cho mọi dòng khi policy/risk yêu cầu.
- Với Quick Receipt: có ApprovalPolicy active và ít nhất một eligible approver.

## 5. Quy tắc nghiệp vụ

1. Hash và khóa payload.
2. Snapshot risk basis và policy version.
3. Với Quick Receipt: luôn tạo ApprovalCase.
4. Quick Receipt chuyển `PENDING_APPROVAL`; không có nhánh đi thẳng `READY`.
5. `CommandReceipt` nằm cùng transaction.

## 6. Điều kiện bắt buộc

- Quick Receipt không được bỏ qua duyệt.
- Thiếu policy/approver/price basis → giữ `DRAFT`.
- Submitted payload đã khóa không được sửa trực tiếp.

## 7. Ảnh hưởng trạng thái

`DRAFT → PENDING_APPROVAL` đối với Quick Receipt hợp lệ.

## 8. Tính nguyên tử và kết quả cuối

Payload lock + risk/policy snapshot + ApprovalCase + CommandReceipt phải tạo thành một kết quả submit authoritative.

## 9. Kết quả và semantics lỗi

Kết quả: immutable submitted payload và route/status xác định.

Lỗi: `DRAFT_VALIDATION_FAILED`, `APPROVAL_PRICE_BASIS_REQUIRED`, `APPROVER_CONFIGURATION_MISSING`, `OPERATION_NOT_DRAFT`.

## 10. Domain và UC sử dụng

- Domain: Inventory Operations (`IO`) + Inventory Control (`IC`).
- Entity: `ENT-IO-01/02/10`, `ENT-IC-01/02`.
- Consumer pilot: UC-02-02 sở hữu việc lập và gửi yêu cầu; UC-02-03 tiếp nhận hồ sơ đã gửi để phê duyệt.
