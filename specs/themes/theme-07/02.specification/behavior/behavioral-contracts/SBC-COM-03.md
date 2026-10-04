---
id: SBC-COM-03
type: behavioral-contract
theme: theme-07
title: "Kết quả và hướng phục hồi"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="sbc-com-03"></a>
# SBC-COM-03 — Kết quả và hướng phục hồi

## 1. Ý định

Result gồm `operation_id?`, `status`, `result_code`, `entity_version?`, `committed_at?`, `ledger_sequence?`, `event_id?`, `warnings[]`, `correlation_id` và `recovery_guidance`.

## 2. Phạm vi áp dụng

- Loại: Dùng chung theo source v3.10.1
- Owner nguồn: Common
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Các dữ kiện đầu vào được giữ trong định nghĩa nguồn bên dưới.

## 4. Điều kiện trước

Các điều kiện trước được quy định bởi common envelope/permission/finality contracts.

## 5. Quy tắc nghiệp vụ

Result gồm `operation_id?`, `status`, `result_code`, `entity_version?`, `committed_at?`, `ledger_sequence?`, `event_id?`, `warnings[]`, `correlation_id` và `recovery_guidance`.

`recovery_guidance` là dữ liệu trình bày dẫn xuất, gồm:

- `effect_status`: `NONE`, `COMMITTED` hoặc `UNKNOWN`;
- `user_message_key`: khóa thông điệp tiếng Việt nghiệp vụ, không thay thế `result_code` ổn định;
- `allowed_next_actions[]`: chỉ tham chiếu query/command và Screen Action đã có, đã lọc theo quyền/trạng thái;
- `preserve_input`: cho biết client có giữ dữ liệu nhập khi quay lại hay không.

Metadata này không phải nguồn finality, không tạo transition hoặc mutation. Nếu metadata mâu thuẫn với `status/result_code`, trạng thái và bằng chứng authoritative thắng; lỗi hợp đồng phải được ghi nhận.

Mọi BC mutation — không chỉ create/update/submit — phải persist hoặc hoàn tất idempotency record trong cùng transaction với kết quả authoritative của command.

<a id="sbc-com-04"></a>

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
