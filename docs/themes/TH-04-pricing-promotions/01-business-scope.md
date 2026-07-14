# TH-04 — Business scope

Canonical spec: [Theme-4-pricing-promotions.md](Theme-4-pricing-promotions.md).

## Trong phạm vi active — EP02

| Nhóm | Nội dung |
| ---- | -------- |
| Tra cứu | Danh sách, search, filter, chi tiết giá riêng theo khách hàng |
| Thiết lập | Tạo thủ công hoặc import Excel theo khách hàng × sản phẩm × đơn vị |
| Vòng đời | Chỉnh sửa, vô hiệu hóa, kích hoạt lại, đánh dấu cần rà soát |
| Nhớ giá | Nhận yêu cầu idempotent từ Sales để lưu giá đã chốt |
| Kiểm soát | Kiểm tra trùng khoảng hiệu lực, giá sàn và tham chiếu snapshot |
| Lịch sử | Nhật ký thay đổi append-only, read-only |

## Ngoài phạm vi EP02

| Nhóm | Lý do |
| ---- | ----- |
| Tính giá cuối đơn hàng | Thuộc orchestration/epic áp dụng giá, chưa active |
| Chương trình khuyến mãi | EP03 deferred |
| Stacking và xử lý xung đột | EP04 deferred |
| POS, coupon, voucher | Chưa thuộc delivery hiện tại |
| Export lịch sử, hard delete | Phase sau |

## Epics

| Epic | Mục tiêu | Trạng thái |
| ---- | -------- | ---------- |
| EP01 | Giá cơ sở và bảng giá nền | deferred |
| EP02 | Giá riêng theo khách hàng và nhớ giá từ bán hàng | active |
| EP03 | Chương trình khuyến mãi | deferred |
| EP04 | Ưu tiên và xử lý xung đột chính sách | deferred |
| EP05 | Ghi nhận giá đã áp dụng | deferred |
| EP06 | Kiểm soát và audit chính sách giá | deferred |

Harness: [harness/01-domain-model.md](harness/01-domain-model.md) · Slice: [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md)

