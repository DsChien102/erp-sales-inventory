---
id: SBC-COM-04
type: behavioral-contract
theme: theme-07
title: "Finality và tính nguyên tử"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="sbc-com-04"></a>
# SBC-COM-04 — Finality và tính nguyên tử

## 1. Ý định

Khi một BC mutation hoàn tất, operation result, movement/value movement, balance, lot/state effect và outbox liên quan commit cùng transaction.

## 2. Phạm vi áp dụng

- Loại: Dùng chung theo source v3.10.1
- Owner nguồn: Common
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Các dữ kiện đầu vào được giữ trong định nghĩa nguồn bên dưới.

## 4. Điều kiện trước

Các điều kiện trước được quy định bởi common envelope/permission/finality contracts.

## 5. Quy tắc nghiệp vụ

Khi một BC mutation hoàn tất, operation result, movement/value movement, balance, lot/state effect và outbox liên quan commit cùng transaction. Lỗi một phần rollback toàn bộ. Event delivery xảy ra sau commit và không quyết định finality.

Vì là yêu cầu cắt ngang, mọi dòng `Entity` của BC mutation mặc nhiên bao gồm ghi/hoàn tất `ENT-IO-10 CommandReceipt`, dù bảng chi tiết chỉ liệt kê các aggregate nghiệp vụ chính.

<a id="sbc-com-05"></a>

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
