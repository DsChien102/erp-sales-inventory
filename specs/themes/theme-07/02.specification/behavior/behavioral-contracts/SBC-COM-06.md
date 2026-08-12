---
id: SBC-COM-06
type: behavioral-contract
theme: theme-07
title: "Vòng đời sản phẩm"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="sbc-com-06"></a>
# SBC-COM-06 — Vòng đời sản phẩm

## 1. Ý định

| Trạng thái/thuộc tính | Hành vi bắt buộc | |---|---| | `ACTIVE` | Cho phép mutation theo các guard còn lại.

## 2. Phạm vi áp dụng

- Loại: Dùng chung theo source v3.10.1
- Owner nguồn: Common
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Các dữ kiện đầu vào được giữ trong định nghĩa nguồn bên dưới.

## 4. Điều kiện trước

Các điều kiện trước được quy định bởi common envelope/permission/finality contracts.

## 5. Quy tắc nghiệp vụ

| Trạng thái/thuộc tính | Hành vi bắt buộc |
|---|---|
| `ACTIVE` | Cho phép mutation theo các guard còn lại. |
| `DISCONTINUED` | Chặn cam kết mua và receipt mới; chỉ cho receipt tiếp tục khi có source continuation assertion/version được chụp trước mốc ngừng. Vẫn cho bán hết, return, RTV, correction và disposal. |
| `ARCHIVED` | Chặn mọi mutation mới; chỉ cho query lịch sử có quyền. |
| Base UOM sau movement | Bất biến; trả `BASE_UOM_IMMUTABLE`, chỉ sản phẩm mới hoặc migration có kiểm soát được phép thay đổi. |

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Theo outcome được nêu trong định nghĩa nguồn.

## 9. Kết quả và semantics lỗi

Không có error list riêng trong contract nguồn; dùng common result/finality semantics.

## 10. Domain và UC sử dụng

- Theo phạm vi và consumer được nêu trong nguồn v3.10.1.
