# Màn hình của `apps/admin` và phương án chuyển sang `apps/erp`

> 2026-10-09 · Kiểm kê từ code `apps/admin/lib` (router, pages, widgets, bottom sheet).
> Quyết định đã chốt (2026-10-09): **chỉ giữ** quản lý tổ chức (tạm ngừng / khôi phục / đóng) và **chuyển chủ sở hữu**. Bỏ Tổng quan, Người dùng nền tảng, Nhật ký nền tảng.
> Vị trí đặt trong `erp`: **chưa chốt** (mục 4).

## 1. Danh sách màn của `apps/admin`

Ký hiệu cột "Quyết định": ✅ giữ (chuyển sang erp) · ❌ bỏ · ♻️ đã có bản mới ở erp.

### 1.1 Màn có route

| # | Màn | Route cũ | File chính | Nội dung | Thao tác | Quyết định |
|---|---|---|---|---|---|---|
| M1 | Đăng nhập admin | `/login` | `features/auth/presentation/pages/login_page.dart` | "Nền tảng quản trị", "Chào mừng bạn quay trở lại!", email, mật khẩu | Đăng nhập; chặn "Tài khoản không có quyền Platform Admin" | ❌ dùng `/login` chung |
| M2 | Khung chính (5 tab) | `/`, `/dashboard/{home,users,organizations,audit,more}` | `features/dashboard/presentation/dashboard_page.dart`, `widgets/admin_bottom_navigation.dart`, `models/admin_tab.dart` | Thanh dưới: Tổng quan · Người dùng · Tổ chức · Nhật ký · Thêm; đầu trang "Tổng quan quản trị" có lối tắt Tổ chức, Người dùng nền tảng (N người dùng), Nhật ký nền tảng, Cài đặt thêm | Chuyển tab; lối tắt mở wizard tạo tổ chức | ❌ (không còn khu riêng — xem mục 4) |
| M3 | Tổng quan | `/dashboard/home` | `features/overview/presentation/pages/admin_overview_page.dart`, `iam/presentation/overview/widgets/*` | Thẻ số liệu: Tổ chức đang quản lý, Người dùng nền tảng, Thao tác đặc quyền (Trong 24 giờ), Thao tác bị chặn, Cần rà soát; "Hoạt động đặc quyền gần đây" | Xem | ❌ |
| M4 | **Danh sách tổ chức** | `/dashboard/organizations` | `features/organizations/presentation/pages/organizations_page.dart`, `iam/presentation/organizations/widgets/{organization_list_content, organization_card_item, organization_search_bar, organization_filter_chips, organization_filter_bottom_sheet, organization_empty_view}.dart` | Ô "Tìm tên hoặc mã tổ chức"; thẻ tổ chức; bộ lọc "Bộ lọc tổ chức nền tảng": Vòng đời (Tất cả / … / Tạm ngừng / Đã đóng), **Mức hoàn thiện** (Đủ điều kiện / Còn thiếu / Có cảnh báo); trạng thái trống / lỗi / không quyền | Mở chi tiết; "Khởi tạo tổ chức" | ✅ (bỏ bộ lọc Mức hoàn thiện, bỏ "Khởi tạo tổ chức") |
| M5 | Wizard khởi tạo tổ chức | `/dashboard/organizations/new` | `features/organizations/presentation/pages/platform_onboarding_page.dart`, `iam/presentation/widgets/platform_onboarding_step_{organization,owner,review}.dart` | Bước Tổ chức (tên, tên hiển thị, liên hệ, tỉnh / xã, địa chỉ, loại chủ thể, MST, tên pháp lý); bước Chủ sở hữu (chọn người có sẵn / tạo mới); xem lại | Tạo tổ chức `provisioning` + lời mời Owner | ❌ (BR-01: tổ chức chỉ tạo qua `/signup`) |
| M6 | **Chi tiết tổ chức** | `/dashboard/organizations/:tenantId` | `features/organizations/presentation/pages/platform_tenant_detail_page.dart`, `iam/presentation/organizations/views/organization_detail_page.dart`, `widgets/organization_detail_{header_card, owner_card, members_card, platform_info_card, alerts, bottom_bar}.dart` | Thẻ đầu (tên, trạng thái); "Chủ sở hữu"; "Thành viên tổ chức" (N thành viên); "Thông tin nền tảng" (Ngày tạo, Kích hoạt lúc, Tạm ngừng lúc, Đóng lúc, Lý do, Người thực hiện, Hoạt động gần nhất, Phiên bản dữ liệu); cảnh báo: "Quyền vận hành đã bị chặn", "Tổ chức đã đóng vĩnh viễn", "Hồ sơ cơ bản chưa hoàn thiện", "Email Chủ sở hữu chưa xác minh", "Lời mời hết hạn" | Nút "Thao tác" (M6a) | ✅ (bỏ "Phiên bản dữ liệu", bỏ 2 cảnh báo email / lời mời Owner, bỏ "Kích hoạt lúc" nếu không còn ý nghĩa) |
| M7 | Người dùng nền tảng | `/dashboard/users` | `features/users/presentation/pages/platform_users_page.dart`, `widgets/platform_users_filter_sheet.dart` | Ô "Tìm tên hoặc email"; chip Tất cả / Hoạt động / Tạm ngừng; bộ lọc | Mở chi tiết | ❌ |
| M8 | Chi tiết người dùng | `/dashboard/users/:userId` | `features/users/presentation/pages/platform_user_detail_page.dart`, `widgets/platform_user_action_sheet.dart`, `iam/presentation/widgets/platform_user_*` | "Thông tin tài khoản" (email xác minh, đăng nhập gần nhất, ngày tạo, ngày tạm ngừng, lý do); "Tổ chức đang tham gia"; cảnh báo "Chưa hoàn tất kích hoạt" / "Quyền truy cập đã bị tạm ngừng" | Tạm ngừng / Khôi phục người dùng (lý do); Gửi yêu cầu đặt lại mật khẩu | ❌ |
| M9 | Nhật ký nền tảng | `/dashboard/audit` | `features/audit/presentation/pages/audit_logs_page.dart` (+ khung audit dùng chung) | Danh sách + chi tiết nhật ký, lọc | Xem | ❌ |
| M10 | Thêm | `/dashboard/more` | `features/more/presentation/pages/more_page.dart` | "Cài đặt thêm" (giữ chỗ), "Đăng xuất" | Đăng xuất | ❌ |

### 1.2 Màn phụ (sheet, trang đẩy từ M6)

| # | Màn | File | Nội dung | Quyết định |
|---|---|---|---|---|
| M6a | **Sheet "Thao tác"** | `organization_actions_bottom_sheet.dart` | "Tạm ngừng tổ chức — Chặn toàn bộ quyền vận hành"; "Khôi phục tổ chức — Cho phép vận hành trở lại"; "Đóng tổ chức — Ngừng hoạt động vĩnh viễn, không thể khôi phục"; "Thay đổi chủ sở hữu — Chọn Chủ sở hữu mới"; "Gửi lại email — Gửi lại liên kết thiết lập cho Chủ sở hữu" | ✅ bỏ dòng "Gửi lại email" |
| M6b | **Xác nhận tạm ngừng** | `organization_suspend_confirmation_bottom_sheet.dart` | "Tạm ngừng tổ chức?" — "Mọi nghiệp vụ trong tổ chức sẽ bị chặn. Dữ liệu và lịch sử vẫn được giữ lại."; "Lý do" * ("Lý do được lưu trong lịch sử quản trị."); Quay lại / Tạm ngừng | ✅ |
| M6c | **Xác nhận khôi phục** | `organization_restore_confirmation_bottom_sheet.dart` | "Khôi phục tổ chức?" — "Thành viên có thể tiếp tục vận hành theo quyền hiện hành sau khi khôi phục."; "Lý do" *; Quay lại / Khôi phục | ✅ |
| M6d | **Xác nhận đóng** | `organization_close_confirmation_bottom_sheet.dart` | "Đóng tổ chức?" — "Tổ chức sẽ ngừng hoạt động vĩnh viễn và không thể khôi phục. Dữ liệu và lịch sử vẫn được giữ để tra cứu."; "Lý do đóng" *; Quay lại / Đóng tổ chức | ✅ |
| M6e | **Thay đổi chủ sở hữu** (trang) | `organization_change_owner_page.dart` | "Thay đổi chủ sở hữu"; "Tìm tên hoặc email"; "Chọn thành viên đang hoạt động"; "Vai trò hiện hành của thành viên sẽ được giữ nguyên."; trống: "Chưa có thành viên đang hoạt động" / "Không tìm thấy thành viên phù hợp"; Hủy / Tiếp tục | ✅ |
| M6f | **Xác nhận chuyển chủ sở hữu** | `organization_change_owner_confirmation_bottom_sheet.dart` | "Chuyển quyền sở hữu cho `<tên>`?" — "Bạn vẫn giữ vai trò Chủ cửa hàng. `<tên>` tiếp tục giữ vai trò `<vai trò>`."; Quay lại / Chuyển quyền | ✅ (sửa câu: người thao tác là Platform Admin, không phải Owner cũ → "Owner hiện tại vẫn giữ vai trò …") |
| M6g | Gửi lại email thiết lập | `owner_invitation_resend_sheet.dart` | "Gửi lại email thiết lập?", sửa "Email nhận liên kết" | ❌ (không còn lời mời Owner) |

### 1.3 Bản chép của màn cửa hàng (không có route trong `apps/admin`)

`features/iam/presentation/{users, roles, organization_profile, audit_logs, readiness, shared, testing}` và `my_account*` trong `apps/admin` là bản sao màn IAM phía cửa hàng. `apps/erp` đã có bản mới (2-A1 … 2-B3). → ♻️ không chuyển.

## 2. Phần cần chuyển sang `erp`

| Màn | RPC (schema `iam`, kiểm `has_platform_permission`) |
|---|---|
| M4 Danh sách tổ chức | `search_platform_tenants` |
| M6 Chi tiết tổ chức | `get_platform_tenant`, `list_platform_tenant_members` |
| M6b / M6c / M6d | `suspend_platform_tenant`, `restore_platform_tenant`, `close_platform_tenant` |
| M6e / M6f | `transfer_platform_tenant_ownership` (sửa KI-08: chặn người nhận đã là Owner nơi khác — BR-32) |

Cả 7 RPC đã có (`20260811010…012`, `20260911003`); kiểm lại chữ ký khi viết plan.

## 3. Ảnh hưởng của việc bỏ các màn còn lại

| Bỏ | Hệ quả | Cách thay |
|---|---|---|
| M7, M8 Người dùng nền tảng | Không tạm ngừng / khôi phục tài khoản trên app; không "gửi yêu cầu đặt lại mật khẩu" hộ người dùng | SQL / Supabase Dashboard; người dùng tự "Quên mật khẩu" |
| M3 Tổng quan, M9 Nhật ký nền tảng | Không xem nhật ký nền tảng trên app (dữ liệu vẫn ghi vào `iam.audit_logs`) | Xem bảng trong Supabase |
| TH-01 EP-09 | US-09.1, US-09.5, US-09.6 → ngoài phạm vi | Cập nhật TH-01 khi chốt vị trí |

## 4. Vị trí trong `erp` — chưa chốt

Chỉ còn 2 nhóm màn (danh sách tổ chức → chi tiết → 4 thao tác), nên hai phương án:

| | A. Mục "Quản trị nền tảng" trong tab **Thêm** | B. Khu `/admin` riêng (5 tab) |
|---|---|---|
| Khung | Không có khung mới; `/more/platform/organizations`, `/:id`, `/:id/owner` | Shell `/admin` + thanh dưới riêng + "Chuyển không gian" |
| Ai thấy | Chỉ Platform Admin (mục ẩn với người khác) | Chỉ Platform Admin |
| Admin không có cửa hàng | Vào từ `/no-organization` ▸ "Quản trị nền tảng" | Đăng nhập vào thẳng `/admin` |
| Khối lượng | Ít (2 trang + 4 sheet + guard 1 nhánh) | Nhiều (shell, 5 tab cho 1 chức năng, guard G3/G4, nhớ khu) |

Với phạm vi đã thu gọn, **A hợp lý hơn**. Khi chốt, Claude cập nhật [LUONG-UNG-DUNG](../02-yeu-cau/LUONG-UNG-DUNG.md), TH-01 (EP-09, mục 5.11) và PLAN P8, rồi thiết kế màn.
