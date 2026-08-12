---
id: SBC-COM-05
type: behavioral-contract
theme: theme-07
title: "Quyền và phê duyệt"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="sbc-com-05"></a>
# SBC-COM-05 — Quyền và phê duyệt

## 1. Ý định

- Policy được chọn theo loại operation, lý do và mức rủi ro; policy/version được chụp khi gửi.

## 2. Phạm vi áp dụng

- Loại: Dùng chung theo source v3.10.1
- Owner nguồn: Common
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Các dữ kiện đầu vào được giữ trong định nghĩa nguồn bên dưới.

## 4. Điều kiện trước

Các điều kiện trước được quy định bởi common envelope/permission/finality contracts.

## 5. Quy tắc nghiệp vụ

- Policy được chọn theo loại operation, lý do và mức rủi ro; policy/version được chụp khi gửi.
- `risk_value_vnd = Σ_i |base_quantity_i × price_basis_i × source_fx_to_vnd_i|`; không bù trừ dòng tăng với dòng giảm. Căn cứ mỗi dòng ưu tiên official cost có hiệu lực, nếu chưa có thì dùng giá thực tế có phiên bản từ nguồn.
- Thiếu căn cứ giá/tỷ giá của bất kỳ dòng nào: operation giữ `DRAFT`, trả `APPROVAL_PRICE_BASIS_REQUIRED`; không tự đẩy lên cấp cao nhất và không dùng giá trị `UNKNOWN`.
- Snapshot lưu quantity, price source/version, source currency, FX source/version, VND line amount, tổng risk value và đúng một `required_approval_level`.
- Khi gửi phải tồn tại ít nhất một người đang có quyền, phạm vi kho và level phù hợp; nếu không, giữ `DRAFT` và trả `APPROVER_CONFIGURATION_MISSING`.
- Người đáp ứng level được suy ra có thể quyết định trực tiếp. Không đi tuần tự qua các cấp thấp hơn. Phê duyệt chỉ đưa operation sang `READY`, không giữ hoặc thay đổi tồn; lúc thực thi mọi điều kiện hiện hành được kiểm lại.

<a id="sbc-com-06"></a>

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
