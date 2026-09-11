# Changelog

All notable changes to the **ERP** Flutter app (`apps/erp`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
with Flutter build numbers (`MAJOR.MINOR.PATCH+BUILD`).

Ship unit: this app only. Internal modules are not versioned separately — note them under
**Internal** when they affect this app.

## [Unreleased]

### Added

### Changed

- Design system: card border đậm hơn (`borderStrong`); input / select / combobox / nút secondary outline nhẹ hơn (`borderDefault`).
- Design system: text chính light dùng `neutral900` thay `primary900`.
- Design system: `VCard` hỗ trợ `enabled` (disabled → border nhẹ hơn, không tap).
- Design system: `VSearchBar` cao/radius khớp field; variant filled luôn có viền (`borderDefault` / focus `borderStrong`).
- Design system: `VDatePicker` icon lịch mặc định bên trái (`iconPosition`); dùng `right` nếu cần layout cũ.
- Design system: badge trạng thái `draft` / `cancelled` chữ đậm hơn (`textPrimary`), `locked` đổi nền sang `surfaceAlt`.
- Design system: filter chip đổi sang một kiểu soft theo tone — chip đang chọn dùng màu brand nhạt (`surfaceBrand` + `textBrand`) thay vì fill xanh lá chữ trắng; chip thường nền `surfaceAlt` + viền `borderStrong`.
- Design system: chip có nút xóa thấp lại, không còn cao hơn một dòng chữ.
- Lời mời tổ chức: banner sau khi tiếp nhận nêu rõ tên tổ chức vừa tham gia (`Đã tham gia tổ chức "X" thành công`), áp dụng cho cả luồng tài khoản mới lẫn tài khoản đã có.

### Fixed

- Login: sai email/mật khẩu (`invalidCredentials`) hiện trên `VFieldError` của field email; các lỗi login khác vẫn dùng toast.

- Dashboard: lời chào theo buổi không kèm tên user (tránh trùng với tên tổ chức); bỏ hardcode tên/chi nhánh trên header.
- Lời mời tổ chức (tài khoản đã tồn tại): bấm "Xác nhận" là trở thành thành viên ngay — lời mời hết kẹt "Đang chờ" phía người mời, và đăng nhập xong vào thẳng tổ chức vừa tham gia thay vì rơi về tổ chức cũ. Trước đây màn xác nhận chỉ điều hướng sang đăng nhập mà không hề gọi lệnh tiếp nhận.
- Lời mời tổ chức: lỗi khi tiếp nhận (mã hết hạn / bị thu hồi / đã dùng) hiện toast rõ ràng thay vì bị nuốt, và bottom sheet xác nhận không tự bật lại thành vòng lặp.
- Lời mời tổ chức: tài khoản đã có không còn thoáng thấy form đăng ký tài khoản mới trong lúc hệ thống đang tiếp nhận lời mời.

### Internal

- App-owned presentation (ADR 11): UI Partner/Pricing/Catalog/Dashboard/IAM chuyển vào `apps/erp`; xóa package `modules/*/presentation` (trừ Sales). Catalog widget preview: `apps/erp/example`.

- Design system: bỏ `VComponentState`; dashboard `QuickActionButton` / pricing form dùng `enabled` inherit qua `VComponentScope`.
- Design system: flat `label`/`helperText`/`errorText`/`isRequired` trên fields → `@Deprecated` (prefer `VField`); call sites chưa migrate sẽ thấy analyze warning.
- Design system: `VBadgeStatus` / `VBadge.status` → `@Deprecated`; dùng `tone` + `variant` (`VBadgeVariant.soft` | `strong`); call sites hiện tại vẫn chạy qua bridge nhưng sẽ thấy analyze warning.
- Design system: `VChip.selected` / `VChip.emphasis` → `@Deprecated`; dùng `tone` (`primary` cho chip đang chọn); bridge vẫn hoạt động, call sites chưa migrate sẽ thấy analyze warning.
- IAM: `InvitationAcceptanceCubit.acceptExistingAccount()` — tiếp nhận lời mời ngay khi xác nhận, không cần session; token vẫn không rời cubit.
- Route `/login` nhận thêm `organizationName` qua `extra` để dựng banner; không truyền token hay `targetTenantId` qua điều hướng.
- Draft SQL `004_iam_patch_accept_invitation_anon` (`accept_invitation` cho phép gọi ẩn danh theo `invitee_email`, tái dùng membership sẵn có thay vì `DUPLICATE_MEMBERSHIP`, ghi `user_preferences.last_selected_tenant_id`) — cần promote trước khi ship DB, và phải kiểm chứng bằng `set local role anon;` vì đây là hàm `anon` đầu tiên ghi vào bảng có RLS.

## [1.7.2+38] - 2026-08-26

### Added

- Lịch sử quản trị tổ chức (tenant audit V2): lọc theo danh mục, tìm kiếm, chi tiết sự kiện tiếng Việt kèm diff Trước/Sau, che dữ liệu nhạy cảm và badge nguồn thông tin (snapshot / hiện tại / hệ thống).

### Changed

- Bỏ luồng kích hoạt owner riêng; owner onboard trực tiếp qua invitation tenant.
- Đơn giản hóa màn invitation (xác nhận / đăng ký) cho khớp luồng invitation thống nhất.
- Hiển thị ngày giờ theo giờ Việt Nam (ICT, UTC+7) trên lịch sử thay đổi và các màn IAM liên quan.

### Fixed

- Trạng thái tải readiness IAM tách riêng khỏi session — banner/ready state không “treo” khi readiness lỗi.

### Internal

- IAM: read ports / mapper / catalog tenant audit V2; gắn nguồn app qua header `X-Vet45-App: tenant_app`.
- Draft SQL audit/owner-activation cleanup (`002`, `004`, `006`, `007`; bản cũ archive) — cần promote trước khi ship DB.

## [1.7.1+37] - 2026-08-20

### Added

- Chặn đăng nhập khi tài khoản không còn membership active nào (thông báo rõ trên màn login).
- App icon / launcher icons mới (iOS + Android) qua `flutter_launcher_icons`.

### Changed

- Đồng bộ UI với design system mới: `VSelect` / `VCombobox` / `VDatePicker`, nút secondary, feedback tương tác cập nhật trên catalog, partner, invitation và IAM screens.

### Fixed

- Session restore: nếu không còn tenant accessible thì sign-out sạch, không giữ session “treo”.

### Internal

- IAM: xử lý `MembershipDeactivated` (xóa preference tenant stale); codegen integration-event registry; bỏ `IMessagingModule` facade.
- Analysis options: exclude thư mục build/platform.

## [1.7.0+36] - 2026-08-20

### Internal

- Baseline entry when introducing app-scoped changelog process.
