# Checklist nghiệm thu màn hình

> Lập ngày 2026-10-07 (PLAN P0.4) từ `apps/erp/lib/core/router/app_router.dart`, `sales_typed_routes.dart`, `apps/admin/lib` và bảng màn hình trong `docs/02-yeu-cau/TH-0X`. Mốc bản cũ: tag `v-legacy-arch`.
>
> **Cách dùng:**
> - Cột **Cũ**: tick khi đã chạy bản cũ (Supabase local) và xác nhận màn tồn tại, thao tác chính chạy được. Ghi lỗi sẵn có vào "Ghi chú" để không tính là lỗi refactor.
> - Cột **Mới**: tick khi màn đã chuyển xong ở phase tương ứng và đạt đúng tài liệu TH (kể cả các sửa 🔧).
> - 🆕 = màn chưa có ở bản cũ (không kiểm cột Cũ). Sheet / hộp thoại ghi "(sheet)" ở cột Route.

## Tổng hợp

| Phase | Nhóm | Số mục |
|---|---|---|
| P2 | Auth, tổ chức, người dùng (TH-01) | 33 |
| P3 | Sản phẩm, cài đặt sản phẩm (TH-02) | 22 |
| P4 | Đối tác (TH-03) | 12 |
| P5 | Giá riêng (TH-04) | 10 |
| P6 | Bán hàng, đơn hàng (TH-05) | 19 |
| P7 | Hóa đơn điện tử (TH-08) | 13 |
| P8 | Quản trị tổ chức (TH-01 ID-31…33) | 3 |
| — | Khung chung | 4 |

---

## Khung chung

| Mã | Màn | Route | Thao tác chính | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| APP-01 | Trang chủ (dashboard) | `/` | Mở được sau đăng nhập; điều hướng tab | ☐ | ☐ | |
| APP-02 | Thêm → Thiết lập hệ thống | `/more/settings` | Liệt kê các mục thiết lập (có "Hóa đơn điện tử") | ☐ | ☐ | |
| APP-03 | Mức sẵn sàng | `/more/readiness` | Mở được, số liệu đúng | ☐ | ☐ | Bỏ ở app cửa hàng (2-B3). DB và màn platform để P8 |
| APP-04 | Chọn cửa hàng / tổ chức | (sheet) | Đổi cửa hàng, dữ liệu tải lại theo cửa hàng | ☐ | ☐ | TH-01 ID-08 |

## P2 — TH-01 Tổ chức và người dùng

| Mã | Màn | Route | Thao tác chính | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| ID-01 | Đăng nhập | `/login` | Đăng nhập đúng/sai; banner từ luồng khác | ☐ | ☐ | (a) xong 2-A3 |
| ID-02 🆕 | Đăng ký cửa hàng (3 bước) | `/signup` | Tạo tài khoản + cửa hàng | — | ☐ | (b) xong 2-B1; đăng ký lại cùng email (A3), đếm ngược gửi lại (A4) ở 2-B4 |
| ID-03 🆕 | Xác minh email (OTP) | `/verify-email` | Nhập mã, gửi lại mã | — | ☐ | (b) xong 2-B1; gửi lại ngay khi vào từ đăng nhập (2-B3) |
| ID-04 | Quên mật khẩu | `/login/reset-password` | Gửi email đặt lại | ☐ | ☑ | Chuyển kiến trúc 2-A1; email qua Edge Function (2-B2); chưa kiểm tay hộp thư trên Dev |
| ID-05 🆕 | Chưa thuộc tổ chức nào | `/no-organization` | Hiện đúng khi không có membership | — | ☐ | (b) xong 2-B1 |
| ID-06 | Nhập mã lời mời | `/invitation` | Mã đúng/sai/hết hạn | ☐ | ☐ | (a) xong 2-A3 |
| ID-07 | Kích hoạt tài khoản theo lời mời | `/invitation` (bước 2) | Đặt mật khẩu, vào tổ chức | ☐ | ☐ | (a) xong 2-A3 |
| ID-08 | Chọn tổ chức | (sheet) | Chọn khi có nhiều tổ chức | ☐ | ☐ | (a) xong 2-A3 |
| ID-09 | Tổ chức không thể truy cập | (màn chặn) | Tổ chức tạm ngừng / đóng | ☐ | ☐ | (a) xong 2-A3 |
| ID-10 | Hub Người dùng & vai trò | `/more/users-and-roles` | Điều hướng 3 mục | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3 |
| ID-11 | Hồ sơ tổ chức | `/more/organization-profile` | Xem thông tin | ☐ | ☑ | Chuyển kiến trúc 2-A1; chưa kiểm tay trên Dev |
| ID-12 | Sửa thông tin tổ chức | `…/edit` | Lưu, kiểm dữ liệu | ☐ | ☑ | Chuyển kiến trúc 2-A1; chưa kiểm tay trên Dev |
| ID-13 | Hồ sơ pháp lý | `…/legal` | Lưu MST, tên, địa chỉ | ☐ | ☑ | Chuyển kiến trúc 2-A1; chưa kiểm tay trên Dev. Dùng cho TH-08 |
| ID-14 | Người dùng (Thành viên / Lời mời) | `/more/users` | 2 tab, tìm, lọc | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3 |
| ID-15 | Mời thành viên | `/more/users/invite` | Mời, chọn vai trò (gồm Chủ cửa hàng) | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3; email qua Edge Function (2-B2); chưa kiểm tay hộp thư |
| ID-16 | Chi tiết lời mời | `/more/users/invitations/:id` | Gửi lại, thu hồi | ☐ | ☐ | Route cũ còn `/more/users/invitation-detail`. (a) xong 2-A2; (b) xong 2-B3; email qua Edge Function (2-B2); chưa kiểm tay hộp thư |
| ID-17 | Chi tiết thành viên | `/more/users/members/:id` | Tạm ngừng / kích hoạt, đổi vai trò, chuyển Owner | ☐ | ☐ | Route cũ còn `/more/users/member-detail`. (a) xong 2-A2; (b) xong 2-B3 |
| ID-18a | Chọn vai trò | `/more/users/select-role` | Chọn vai trò | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3 |
| ID-18b | Xem trước đổi vai trò | `/more/users/preview-role-change` | Xác nhận đổi | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3 |
| ID-19a | Vai trò | `/more/roles` | Danh sách vai trò | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3 |
| ID-19b | Chi tiết vai trò | `/more/roles/detail` | Xem quyền | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3. Route chi tiết thật là `/more/roles/:code`; `/detail` chuyển về danh sách |
| ID-20a | Lịch sử quản trị | `/more/audit-logs` | Danh sách, lọc | ☐ | ☐ | (a) xong 2-A2; (b) xong 2-B3 |
| ID-20b | Chi tiết lịch sử | `/more/audit-logs/:id` | Xem chi tiết | ☐ | ☐ | Route cũ còn `/more/audit-logs/detail`. (a) xong 2-A2; (b) xong 2-B3 |
| ID-21 | Tài khoản của tôi | `/more/my-account` | Xem, đăng xuất | ☐ | ☑ | Chuyển kiến trúc 2-A1; chưa kiểm tay trên Dev |
| ID-22 | Sửa tài khoản | `/more/my-account/edit` | Lưu tên, SĐT | ☐ | ☑ | Chuyển kiến trúc 2-A1; chưa kiểm tay trên Dev |
| ID-23 | Đặt lại mật khẩu (đã đăng nhập) | `/more/my-account/reset-password` | Đổi mật khẩu | ☐ | ☑ | Chuyển kiến trúc 2-A1; chưa kiểm tay trên Dev |
| ID-x1 | Đăng nhập lỗi mạng | `/login` | Thông điệp lỗi, không treo | ☐ | ☐ | Trạng thái A-03 |
| ID-x2 | Banner "Tham gia tổ chức thành công" | `/login` | Hiện sau kích hoạt lời mời | ☐ | ☐ | A-04 |
| ID-x3 | Router guard: chưa đăng nhập | mọi route | Về `/login` | ☐ | ☐ | SCOPE 3.5 |
| ID-x4 | Chưa xác minh email 🆕 | `/login` | Đăng nhập lỗi `email_not_confirmed` → `/verify-email` | — | ☐ | (b) xong 2-B1. Không phải guard: lúc này chưa có phiên |
| ID-x5 | Router guard: không có tổ chức 🆕 | mọi route | Về `/no-organization` | — | ☐ | (b) xong 2-B1 (G5, G6) |
| ID-x6 | Router guard: tổ chức bị chặn | mọi route | Màn ID-09 | ☐ | ☐ | |
| ID-x7 | Router guard: Quản trị nền tảng 🆕 | `/more/platform/**` | Người không phải Platform Admin → `/` | — | ☐ | Phương án A (2026-10-09): không còn khu `/admin` |

## P3 — TH-02 Sản phẩm và giá bán

| Mã | Màn | Route | Thao tác chính | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| SP-01 | Danh sách sản phẩm | `/products/items` | Tìm, chip lọc, tải thêm | ☐ | ☐ | |
| SP-02 | Lọc thông tin bổ sung | (sheet) | Áp dụng / bỏ lọc | ☐ | ☐ | |
| SP-03 | Tạo nhanh sản phẩm | `/products/items/new` | Tạo sản phẩm | ☐ | ☐ | |
| SP-04 | Product Control Center | `/products/items/pcc` | Mở các mục con | ☐ | ☐ | |
| SP-05 | Hồ sơ sản phẩm | `…/pcc/profile-maintenance` | Lưu hồ sơ | ☐ | ☐ | |
| SP-06 | Ảnh sản phẩm | `…/pcc/images-maintenance` | Thêm, xóa, đặt ảnh chính | ☐ | ☐ | |
| SP-07 | Ghi chú | `…/pcc/note` | Lưu ghi chú | ☐ | ☐ | |
| SP-08 | Nhập nhóm thông tin bổ sung | `…/pcc/custom-fields/edit` | Lưu giá trị; hỏi khi rời | ☐ | ☐ | |
| SP-09 | Đơn vị đo lường | `…/pcc/measurement-units` | Thêm, sửa, xóa đơn vị | ☐ | ☐ | |
| SP-10 | Tồn kho | `…/pcc/stock` | Điều chỉnh tồn | ☐ | ☐ | KI-01…07 TH-02 |
| SP-11 | Giá cơ sở | `…/pcc/manual-base-price` | Lưu giá cơ sở | ☐ | ☐ | |
| SP-12 | Khung giá bán | `…/pcc/price-bands` | Xem khung giá | ☐ | ☐ | |
| SP-13 | Sửa khung giá một đơn vị | `…/pcc/price-bands/edit` | Lưu khung giá | ☐ | ☐ | |
| SP-14 | Cài đặt sản phẩm | `/more/product-settings` | Điều hướng | ☐ | ☐ | |
| SP-15 | Nhóm & trường thông tin | `…/custom-fields` | Danh sách nhóm | ☐ | ☐ | |
| SP-16 | Chi tiết / sửa nhóm | `…/custom-fields/:groupId`, `…/upsert-group` | Tạo, sửa nhóm | ☐ | ☐ | |
| SP-17 | Tạo / sửa trường | `…/custom-fields/:groupId/upsert-field` | Tạo, sửa trường | ☐ | ☐ | |
| SP-18 | Khung giá cửa hàng | `…/store-price-rule` | Xem | ☐ | ☐ | |
| SP-19 | Sửa khung giá cửa hàng | `…/store-price-rule/edit` | Lưu | ☐ | ☐ | |
| SP-20 | Lịch sử khung giá cửa hàng | `…/store-price-rule/history` | Xem | ☐ | ☐ | |
| SP-21 | Checklist readiness | `…/pcc/checklist` | Xem blocker | ☐ | ☐ | |
| SP-22 | Lịch sử thay đổi sản phẩm | `…/pcc/change-history` | Xem | ☐ | ☐ | |

## P4 — TH-03 Đối tác giao dịch

| Mã | Màn | Route | Thao tác chính | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| PT-01 | Danh sách KH & NCC | `/partner` | Tìm, chip, sắp xếp | ☐ | ☐ | |
| PT-02 | Bộ lọc / Sắp xếp | (sheet) | Áp dụng, đặt lại | ☐ | ☐ | |
| PT-03 | Thêm KH & NCC mới | (sheet) | Chọn cá nhân / tổ chức | ☐ | ☐ | |
| PT-04 | Trùng hồ sơ | (sheet) | Chặn trùng SĐT/email/MST | ☐ | ☐ | |
| PT-05 | Tạo / sửa hồ sơ | `/partner/new`, `/partner/:id/edit` | Lưu hồ sơ | ☐ | ☐ | Đích của "Cập nhật thông tin khách hàng" (TH-08) |
| PT-06 | Chọn khu vực hành chính | (sheet) | Tỉnh → xã | ☐ | ☐ | |
| PT-07 | Hồ sơ KH & NCC | `/partner/:id` | Xem, thao tác | ☐ | ☐ | |
| PT-08 | Người liên hệ | `/partner/:id/contacts` | Danh sách | ☐ | ☐ | |
| PT-09 | Thêm / sửa người liên hệ | `…/contacts/new`, `…/:contactId/edit` | Lưu | ☐ | ☐ | |
| PT-10 | Chọn từ cá nhân | `…/contacts/select` | Chọn | ☐ | ☐ | |
| PT-11 | Chuyển thành tổ chức | `/partner/:id/transform` | Chuyển | ☐ | ☐ | |
| PT-12 | Lịch sử thao tác | `/partner/:id/history` | Xem | ☐ | ☐ | Feature mẫu P1.5 |

## P5 — TH-04 Chính sách giá

| Mã | Màn | Route | Thao tác chính | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| PR-01 | Danh sách giá riêng | `/pricing` | Tìm, chip, lọc | ☐ | ☐ | |
| PR-02 | Bộ lọc / Sắp xếp | (sheet) | Áp dụng | ☐ | ☐ | |
| PR-03 | Chọn cách thêm | `/pricing/choose-method` | Tay / Excel | ☐ | ☐ | |
| PR-04 | Tạo / sửa giá riêng | `/pricing/new`, `/pricing/:id/edit` | Lưu; dưới giá sàn; ghi đè trùng | ☐ | ☐ | |
| PR-05 | Chọn khách hàng | `/pricing/pick-customer` | Chọn | ☐ | ☐ | |
| PR-06 | Chọn sản phẩm | `/pricing/pick-product` | Chọn | ☐ | ☐ | |
| PR-07 | Chọn đơn vị bán | `/pricing/pick-unit/:productId` | Chọn | ☐ | ☐ | |
| PR-08 | Chi tiết giá riêng | `/pricing/:ruleId` | Ngừng, khôi phục | ☐ | ☐ | |
| PR-09 | Nhập Excel | `/pricing/import` | 3 chế độ nhập | ☐ | ☐ | |
| PR-10 | Lịch sử giá riêng | `/pricing/:ruleId/history` | Xem | ☐ | ☐ | |

## P6 — TH-05 Bán hàng và đơn hàng

| Mã | Màn | Route | Thao tác chính | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| SG-01 | Đơn nháp | `/sales/drafts` | Tìm, xóa, mở nháp | ☐ | ☐ | |
| SG-02 | Soạn đơn | `/sales/compose?draftId=` | Thêm hàng, khách, giá | ☐ | ☐ | |
| SG-03 | Chọn đơn vị bán | (sheet) | Chọn | ☐ | ☐ | |
| SG-04 | Chọn / tạo nhanh khách | (sheet) | Chọn, tạo | ☐ | ☐ | |
| SG-05 | Điều chỉnh giá | (sheet) | Đổi giá, lưu làm giá riêng | ☐ | ☐ | |
| SG-06 | Thanh toán | `/sales/checkout` | Hoàn tất (đủ / nợ) | ☐ | ☐ | |
| SG-07 | Kết quả bán hàng | `/sales/result/:orderId` | Phiếu, HĐĐT | ☐ | ☐ | Chứa HD-06 |
| SG-08 | Đơn hàng | `/orders` | Tìm, nhóm nhanh, lọc (có HĐĐT) | ☐ | ☐ | |
| SG-09 | Chi tiết đơn hàng | `/sales/orders/:orderId` | Các khối, thao tác | ☐ | ☐ | Chứa HD-06 |
| SG-09b | Thanh toán & công nợ | (màn con) | Xem | ☐ | ☐ | |
| SG-09c | Lịch sử | (màn con) | Xem | ☐ | ☐ | |
| SG-09d | Phiếu đổi/trả của đơn | (màn con) | Xem | ☐ | ☐ | |
| SG-10 | Huỷ đơn | (sheet) | Kiểm điều kiện, xác nhận | ☐ | ☐ | |
| SG-11 🆕 | Thu tiền | (sheet) | Thu phần còn nợ | — | ☐ | |
| SG-12 | Lập phiếu đổi/trả | `/sales/orders/:id/returns/new` | Chọn hàng trả/đổi | ☐ | ☐ | |
| SG-13 | Quyết toán đổi/trả | `…/returns/:id/settle` | Hoàn tiền / thu thêm | ☐ | ☐ | |
| SG-14 | Kết quả đổi/trả | `…/returns/:id/result` | Xem | ☐ | ☐ | |
| SG-15 | Chi tiết phiếu đổi/trả | `…/returns/:id/detail` | Xem | ☐ | ☐ | |
| SG-16 | Xem trước phiếu (PDF) | `/sales/orders/:id/preview`, `…/returns/:id/preview` | In, chia sẻ | ☐ | ☐ | |

## P7 — TH-08 Hóa đơn điện tử

| Mã | Màn | Route | Thao tác chính | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| HD-01 | Tổng quan thiết lập | `/more/einvoice` | Mức sẵn sàng, 3 mục | ☐ | ☐ | |
| HD-02 | Kết nối MISA | `/more/einvoice/connection` | Kết nối, chờ, lỗi, kết nối lại | ☐ | ☐ | Cần tài khoản MISA sandbox |
| HD-03 | Xác nhận ngắt kết nối | (sheet) | Ngắt | ☐ | ☐ | |
| HD-04 | Cấu hình phát hành | `/more/einvoice/issuance` | Chọn mẫu, lưu | ☐ | ☐ | KI-01 |
| HD-05 | Tự động hóa | `/more/einvoice/automation` | 2 công tắc, lưu | ☐ | ☐ | KI-02 |
| HD-06 | Dòng "Hóa đơn điện tử" | trong SG-07, SG-09 | 4 trạng thái, tự hỏi lại | ☐ | ☐ | |
| HD-07 | Sheet trước phát hành | (sheet) | Xem trước, banner lỗi, người mua thiếu | ☐ | ☐ | |
| HD-08 | Xác nhận phát hành | (sheet) | Phát hành | ☐ | ☐ | |
| HD-09 | Sheet sau phát hành | (sheet) | Xem chính thức | ☐ | ☐ | |
| HD-10 | Tài liệu XML & PDF | (sheet) | Lưu PDF, XML | ☐ | ☐ | |
| HD-11 | Gửi hóa đơn | (sheet) | Gửi lần đầu | ☐ | ☐ | |
| HD-12 | Gửi lại hóa đơn | (sheet) | Gửi lại | ☐ | ☐ | KI-08 |
| HD-13 | Lịch sử gửi | (trang) | Xem | ☐ | ☐ | |

## P8 — Platform admin (gộp từ `apps/admin`)

| Mã | Màn | Route mới | Route cũ (`apps/admin`) | Cũ | Mới | Ghi chú |
|---|---|---|---|---|---|---|
| ~~ID-30~~ | Tổng quan nền tảng | — | `/dashboard/home` | — | — | ⏭ Bỏ (2026-10-09) |
| ID-31 | Tổ chức (Thêm ▸ Quản trị nền tảng) | `/more/platform/organizations` | `/dashboard/organizations` | ☐ | ☐ | Bản cũ có `organizations/new` — bỏ (SCOPE 3.5) |
| ID-32 | Chi tiết tổ chức | `/more/platform/organizations/:id` | `/dashboard/organizations/:tenantId` | ☐ | ☐ | Tạm ngừng / khôi phục / đóng |
| ID-33 | Thay đổi chủ sở hữu | `/more/platform/organizations/:id/owner` | (trong chi tiết) | ☐ | ☐ | |
| ~~ID-34~~ | Người dùng nền tảng | — | `/dashboard/users`, `/:userId` | — | — | ⏭ Bỏ (2026-10-09) |
| ~~ID-35~~ | Nhật ký nền tảng | — | `/dashboard/audit` | — | — | ⏭ Bỏ (2026-10-09) |

---

**Nghiệm thu cuối (P10):** mọi dòng cột **Mới** đã tick; dòng nào bỏ thì ghi lý do và chỗ quyết định.
