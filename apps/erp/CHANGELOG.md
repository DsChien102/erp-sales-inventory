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

### Fixed

### Internal

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
