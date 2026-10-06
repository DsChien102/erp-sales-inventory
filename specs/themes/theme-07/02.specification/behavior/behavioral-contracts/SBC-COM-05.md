---
id: SBC-COM-05
type: behavioral-contract
theme: theme-07
title: "Quyền và phê duyệt"
owner: BA
status: FROZEN
source_baseline: v4.6.7
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
- Với operation được định tuyến theo giá trị rủi ro: `risk_value_vnd = Σ_i |base_quantity_i × price_basis_i × source_fx_to_vnd_i|`; không bù trừ dòng tăng với dòng giảm. Căn cứ mỗi dòng ưu tiên official cost có hiệu lực, nếu chưa có thì dùng giá thực tế có phiên bản từ nguồn.
- Với operation risk-based có draft lifecycle, thiếu căn cứ giá/tỷ giá giữ `DRAFT` và trả `APPROVAL_PRICE_BASIS_REQUIRED`; không tự đẩy lên cấp cao nhất và không dùng giá trị `UNKNOWN`.
- **quick receipt/UC-02-02 là nhánh bắt buộc duyệt không dựa trên price/FX tại BJ02**: create-and-submit không yêu cầu `risk_value_vnd`, không trả `APPROVAL_PRICE_BASIS_REQUIRED`, và không snapshot price/FX như điều kiện approval. ApprovalPolicy phải resolve được tuyến/người duyệt quick receipt mà không cần căn cứ giá; nếu không có approver hợp lệ thì trả `APPROVER_CONFIGURATION_MISSING`.
- Với operation risk-based, snapshot lưu quantity, price source/version, source currency, FX source/version, VND line amount, tổng risk value và đúng một `required_approval_level`; quick receipt snapshot chỉ giữ các facts BJ02/evidence/ownership/policy cần cho quyết định nhận hàng.
- Khi gửi phải tồn tại ít nhất một người đang có quyền, phạm vi kho và level phù hợp. Với operation có draft lifecycle, nếu thiếu approver thì giữ `DRAFT`; **với quick receipt/UC-02-02**, lệnh create-and-submit bị từ chối và không tạo goods receipt. Cả hai nhánh trả `APPROVER_CONFIGURATION_MISSING`.
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
