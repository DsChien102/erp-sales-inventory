# TH-04 — Business scope

Canonical spec: [Theme-4-pricing-promotions.md](Theme-4-pricing-promotions.md).

## Trong phạm vi active — EP02

| Nhóm | Nội dung |
| ---- | -------- |
| Tra cứu | Danh sách, search, filter, chi tiết giá riêng theo khách hàng |
| Thiết lập | Tạo thủ công hoặc import Excel theo khách hàng × sản phẩm × đơn vị |
| Vòng đời | Chỉnh sửa, vô hiệu hóa, kích hoạt lại, đánh dấu cần rà soát |
| Nhớ giá | Nhận yêu cầu idempotent từ Sales để lưu giá đã chốt |
| Kiểm soát | Kiểm tra trùng khoảng hiệu lực (ghi đè có xác nhận), giá sàn và tham chiếu snapshot |
| Lịch sử | Nhật ký thay đổi append-only, read-only (gồm activity ghi đè) |

**Overlap / ghi đè:** Sau khi một command tạo, sửa, import, bật lại hoặc nhớ giá hoàn tất, không được tồn tại nhiều rule active trùng `customer × product × unit` và giao hiệu lực. Khi phát hiện trùng, hệ thống yêu cầu xác nhận ghi đè rồi soft-delete rule active cũ — không auto tạo `needs_review` từ duplicate runtime. Xem Theme-4 EP02 domain (CPR-BR-07, VR-BR-07, RI-BR-10).

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

