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

### Fixed

### Internal

- Design system: bỏ `VComponentState`; dashboard `QuickActionButton` / pricing form dùng `enabled` inherit qua `VComponentScope`.
- Design system: flat `label`/`helperText`/`errorText`/`isRequired` trên fields → `@Deprecated` (prefer `VField`); call sites chưa migrate sẽ thấy analyze warning.
- Design system: `VBadgeStatus` / `VBadge.status` → `@Deprecated`; dùng `tone` + `variant` (`VBadgeVariant.soft` | `strong`); call sites hiện tại vẫn chạy qua bridge nhưng sẽ thấy analyze warning.

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
