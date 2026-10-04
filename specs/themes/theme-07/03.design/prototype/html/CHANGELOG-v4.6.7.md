# CHANGELOG — v4.6.7

## BJ02 — nhập hàng nhanh approval không phụ thuộc price/FX

- Bỏ `APPROVAL_PRICE_BASIS_REQUIRED` khỏi `UC-02-02`, `SCR-010` và runtime state của nhập hàng nhanh.
- `API-C-26` Quick create-and-submit không mang/không yêu cầu price-FX basis.
- Thiếu price/FX không chặn tạo goods receipt; success vẫn tạo goods receipt ở `PENDING_APPROVAL`.
- `APPROVER_CONFIGURATION_MISSING` vẫn chặn create-and-submit khi không resolve được approver theo policy nhập hàng nhanh.
- `SCR-011` Quick không dùng aggregate risk total như căn cứ bắt buộc; nhánh document/risk-based giữ semantics risk hiện hành.
- Căn cứ giá/tỷ giá tiếp tục thuộc BJ03/BJ13.
- `UC-02-01` không thay đổi.
