---
id: SBC-COM-02
type: behavioral-contract
theme: theme-07
title: "Quyền, phạm vi và điều kiện cần"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="sbc-com-02"></a>
# SBC-COM-02 — Quyền, phạm vi và điều kiện cần

## 1. Ý định

- Functional permission + warehouse scope tại thời điểm hành động.

## 2. Phạm vi áp dụng

- Loại: Dùng chung theo source v3.10.1
- Owner nguồn: Common
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Các dữ kiện đầu vào được giữ trong định nghĩa nguồn bên dưới.

## 4. Điều kiện trước

Các điều kiện trước được quy định bởi common envelope/permission/finality contracts.

## 5. Quy tắc nghiệp vụ

- Functional permission + warehouse scope tại thời điểm hành động.
- Tenant/store/warehouse hoạt động và đúng cặp mặc định.
- Tenant inventory activation phải là `ACTIVE`; khi còn `PREPARING`, mọi mutation thường trả `INVENTORY_NOT_ACTIVATED`, trừ prepare/commit opening balance và các query được phép.
- Source version không cũ hơn version đã ghi nhận.
- Cùng `command_scope + idempotency_key` phải có cùng payload hash và một idempotency record; `operation_request_id` là identity nghiệp vụ riêng, không bị thay bằng command identity.
- Không có Inventory Lock xung đột.
- Entity version khớp khi command sửa aggregate mutable.
- Operation ở trạng thái cho phép; payload khóa sau `DRAFT`.

<a id="sbc-com-03"></a>

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Theo outcome được nêu trong định nghĩa nguồn.

## 8. Tính nguyên tử và kết quả cuối

Theo SBC-COM-03/04 và technical finality contract.

## 9. Kết quả và semantics lỗi

Không có error list riêng trong contract nguồn; dùng common result/finality semantics.

## 10. Domain và UC sử dụng

- Theo phạm vi và consumer được nêu trong nguồn v3.10.1.
