# Changelog

All notable changes to the **vet45_design_system** Flutter package
(`packages/vet45_design_system`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(`MAJOR.MINOR.PATCH`, no Flutter build number).

Ship unit: this library only. Deploy tags: `vet45_design_system-vX.Y.Z`.
User-facing UI that ships inside ERP/Admin should also be noted under those apps'
changelogs when relevant.

## [Unreleased]

### Added

- Versioning theo ship unit: Keep a Changelog + `scripts/bump_version.sh` (framework `flutter_lib`).

### Changed

- `VSwipeReveal` là primitive swipe-trái public (example + UI audit cover trực tiếp).
- Typography của `VButton` theo variant (primary/secondary/tertiary/link) thay vì theo size.
- `VSegmentedControl` segment dùng `VButton` (primary/secondary) thay Material/InkWell thủ công.

### Fixed

### Internal

- Component audit: gỡ entry `VSwipeActionRecord` sau khi xóa widget.
- Inspector scope: public widgets wrap chrome bằng `vInspectorHide` (`DisableWidgetInspectorScope`); slot caller re-enable qua `vInspectorShow`.

### Removed

- `VSwipeActionRecord` — compose nội dung hàng trên `VSwipeReveal`.

## [1.0.0] - 2026-08-23

### Added

- Baseline package version for design-system ship-unit versioning.
