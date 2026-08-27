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

- `VCard.enabled` — soft-inherit `VComponentScope`; disabled → border `borderDefault`, bỏ `onTap`, cascade `enabled: false`.

### Changed

- `VSearchBar`: height = `VTextField.controlHeight`, radius `VRadius.card`; variant `filled` luôn có border (`borderDefault` / focus `borderStrong`); icon muted hơn.

### Internal

## [1.1.0] - 2026-08-27

### Added

- `VComponentScope` — ambient soft inherit (`tone` + `enabled` / `resolveTone` / `resolveEnabled`); `vProvideComponentScope` / `requireAncestor`.
- `VCardHeader.tone` / `VCardTitle.tone` — inherit via `VComponentScope`; structural assert nếu ngoài `VCard` / `VCardHeader`.
- `VColorScheme.borderBrand` — border brand (light `primary200`, dark `primary700`).
- `VColorScheme.foregroundForTone` — map `VComponentTone` → semantic foreground.
- `VText.tone` — soft-inherit từ `VComponentScope` (`color` vẫn thắng).
- `VDivider` — separator horizontal/vertical; thickness mặc định `VBorders.thin` (1), màu `borderDefault`.

### Changed

- `VEmptyHeader` / `VCard` dùng `VComponentScope` thay private tone InheritedWidget.
- Interactive widgets: `bool? enabled` soft-inherit từ `VComponentScope` (local override); bỏ `VComponentState`.
- `VButton` / `VIconBox` / `VBadge` / `VChip` resolve tone từ `VComponentScope` khi local null.
- `VBanner` provide `VComponentScope` cho trailing/footer.
- `VCardHeader` / `VCardContent` / `VCardFooter` / `VCardIcon` / `VCardAction` bắt buộc đúng ancestry parent (runtime `FlutterError`).
- `VCard` tone `primary`: border dùng `borderBrand` thay `primary`.
- `VEmptyState` flat API (`title` / `icon*` / `action*`) marked `@Deprecated` — prefer `child` composition. `tone` remains on the shell and cascades via `VComponentScope`.
- `VEmptyTitle` / `VCardTitle` dùng `VText.tone` thay map màu tay.
- `VCard` default border → `borderStrong`; `VTextField` / `VTextFormField` / `VSelect` / `VCombobox` resting và `VButton` secondary → `borderDefault`.
- Light `textPrimary` → `neutral900` (dark giữ `neutral0`).

### Removed

- `VComponentState` enum (`enabled` / `disabled` / `loading` / `error`). Disable → `enabled`; error → `errorText`/API riêng; loading CTA → `VButton.isLoading`.
- `VQuantitySelector` component (export + example + audit matrix).

## [1.0.1] - 2026-08-26

### Added

- `VDateTime` — format ngày/giờ cố định ICT (UTC+7), không theo timezone thiết bị.
- Versioning theo ship unit: Keep a Changelog + `scripts/bump_version.sh` (framework `flutter_lib`).
- `VEmptyTitle.tone` (`VComponentTone`) — màu title theo tone (legacy `VEmptyState` truyền xuống).
- `VEmptyHeader.tone` Inherited scope: `VEmptyMedia` / `VEmptyTitle` / `VEmptyDescription` inherit tone (local override); throw nếu dùng ngoài header.

### Changed

- `VSwipeReveal` là primitive swipe-trái public (example + UI audit cover trực tiếp).
- Typography của `VButton` theo variant (primary/secondary/tertiary/link) thay vì theo size.
- `VSegmentedControl` segment dùng `VButton` (primary/secondary) thay Material/InkWell thủ công.
- `VPagePadding` mặc định inset ngang = `VSpacing.screenMobile` (bỏ `horizontalForWidth` theo breakpoint).
- `VRadio` bỏ `tone`; selected = `primary`, unselected = `borderDefault`.

### Internal

- Component audit: gỡ entry `VSwipeActionRecord` sau khi xóa widget.
- Inspector scope: public widgets wrap chrome bằng `vInspectorHide` (`DisableWidgetInspectorScope`); slot caller re-enable qua `vInspectorShow`.

### Removed

- `VSwipeActionRecord` — compose nội dung hàng trên `VSwipeReveal`.

## [1.0.0] - 2026-08-23

### Added

- Baseline package version for design-system ship-unit versioning.
