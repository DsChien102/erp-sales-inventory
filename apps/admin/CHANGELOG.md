# Changelog

All notable changes to the **Admin** Flutter app (`apps/admin`) are documented in this file.

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

### Fixed

### Internal

- Design system: bỏ `VComponentState`; interactive controls dùng `enabled` (+ soft inherit `VComponentScope`).
- Design system: flat `label`/`helperText`/`errorText`/`isRequired` trên fields → `@Deprecated` (prefer `VField`); call sites chưa migrate sẽ thấy analyze warning.

## [1.0.2+3] - 2026-08-26

### Added

- Chi tiết audit platform: target user/tổ chức rõ hơn, bảng diff Trước/Sau và nhãn nguồn ứng dụng (ERP / Platform Admin).

### Internal

- Gắn nguồn app qua header `X-Vet45-App: platform_admin_app` khi init Supabase.
- Shared IAM: DTO/platform audit fields (`auditNo`, `targetType`, change maps) đi cùng ERP khi ship module.

## [1.0.1+2] - 2026-08-20

### Changed

- Đồng bộ nút / sheet platform (onboarding, user detail, user actions/filters) với design system (`secondary` buttons và component mới).
- Env banner dùng màu theo `BuildContext` (theme-aware).

### Internal

- iOS `MinimumOSVersion` → 15.6.
- Analysis options: exclude thư mục build/platform.
- Shared IAM: membership deactivate / session preference cleanup đi cùng ERP khi ship module presentation + infrastructure.

## [1.0.0+1] - 2026-08-20

### Internal

- Baseline entry when introducing app-scoped changelog process.
