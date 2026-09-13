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

### Changed

### Fixed

### Internal

## [1.4.1] - 2026-09-13

### Changed

- `VSearchBar` compose trên `VInput` + `VTextFieldFocusRing` (parity TextField); `VInput` thêm `fillColor` / `hintColor` optional.
- `VButton` secondary: map `tone: success` (fill/hover/press + chữ + border); idle fill danger/warning/success dùng `surface` thay `transparent`.
- `VSearchBar`: thêm khoảng cách ngang sau icon search (prefix).
- `VTextFieldFocusRing`: ring danger dùng `dangerBg`, ring mặc định dùng `successBg` (bỏ `focusRing` + alpha thủ công).

### Internal

- `VBanner`: bỏ import barrel thừa.

## [1.4.0] - 2026-09-13

### Added

- `VComboboxEmpty` — empty overlay copy khi filter không khớp; `preferredHeight` ổn định cho shell.
- `VCombobox` composition: host `VCombobox` + `Input` / `Content` / `List` / `Item` / `Footer`; `VComboboxItem` nhận `child` Widget; `searchText` optional (filter); label input qua `displayTextForValue`.

### Changed

- `VCombobox` giữ menu mở khi 0 match và hiển thị slot `empty` (mặc định `VComboboxEmpty`); chiều cao panel theo empty, không ép `_menuHeight` (300).
- `VCombobox` trigger dùng `VInput` + `VTextFieldFocusRing` (parity `VTextField`; bỏ `TextField` + decoration thủ công); `TapRegion`/`groupId` giữ focus khi scroll menu.
- `VField.resolveInvalid` + `VFieldScope`: V*Field (`VTextField` / `VTextArea` / wrappers / `VSelect` / `VCombobox` / OTP / `VChoiceList` / `VPhoneField`) nhận `bool? invalid` và inherit chrome danger từ `VField(invalid:)`.
- `VBanner`: bỏ `icon` thủ công (chỉ icon theo status/tone); border semantic giống `VCard`; layout icon căn giữa hàng title, description/footer indent thẳng hàng title; `message` deprecated → dùng `description`.
- `VIcons.error`: glyph Lucide `circleX` (thay `alertCircle`).
- `VButton`: `leading`/`trailing` dùng `VIcons` (deprecate `leadingIcon`/`trailingIcon` Widget); factory `VButton.icon`; `expandText` + `textAlign` cho text slot.
- Field chrome (`VInput` / TextField / Select / Combobox / SearchBar / DatePicker): chiều cao single-line theo `VDensity.controlHeightMedium` (khớp `VButton` medium; comfortable 44).

### Fixed

- Input (`VInput` / `VTextField`): dismiss ngoài field bằng `onTapUpOutside` + touch-slop — tap thật thì unfocus; drag scroll parent giữ focus/IME. `VTextArea` / `VSearchBar` / `VVerificationCodeField`: mặc định `onTapOutside` theo Flutter.
- `VCombobox`: không unfocus khi ancestor scroll đóng overlay; dismiss ngoài field qua `onTapUpOutside` (+ touch-slop); giữ text/query khi vẫn focus. `VInput` expose `onTapUpOutside`.

## [1.3.0] - 2026-09-10

### Added

- `VPhoneField` + `VPhoneValidator` — input SĐT (9–11 chữ số, cho phép space); reject ký tự không hợp lệ; validate debounce; message required/invalid tùy chỉnh; preview forms + tests.
- `VDateTime.calendarDate` / `parseAndFormatCalendarDate` / `currentBusinessDate` / `businessDayRangeUtc` — format/parse ngày lịch không lệch timezone + khoảng business day ICT → UTC.
- `VTypography.labelDefault` / `labelDefaultMono` (14px / height 20 / w600) + `VTextVariant` tương ứng.
- `VTypography.headingH1Mono` / `headingH2Mono` + `VTextVariant` tương ứng.
- `VTypography.actionDefault` (14px / height 20 / w600, sans) + `VTextVariant` tương ứng.

### Changed

- `VNumericKeypadSheet` display → editable `VInput` (caret/select, `readOnly` + custom keypad); money format nghìn `,` live + suffix `đ`; `onSave` vẫn raw digits.
- Bỏ `VColors.neutral25`; `VColors.neutral100` lấy giá trị cũ của `neutral25` (`#F6F8F9`) — ảnh hưởng light `background` / scaffold và `surfaceAlt` / `surfacePressed` / `disabledBg`.
- Bỏ `VBorders.medium` (1.3); `VBorders.thick` `1.6` → `2.0`; `widthFor` non-strong và call site cũ dùng `medium` → `thin`.
- `VTextFormField` marked `@Deprecated` — bridge `extends VTextArea`; prefer `VTextArea`.
- Disabled state: giữ màu enabled + opacity 0.4 (`vDisabledOpacity`); ngừng dùng palette `primaryDisabled` / `disabledBg` / `disabledBorder` / `disabledFg` trong package.
- `VColorScheme.primaryDisabled` / `disabledBg` / `disabledBorder` / `disabledFg` marked `@Deprecated` — prefer `vDisabledOpacity` / `VOpacity.disabled` (bridge vẫn gán giá trị).

### Fixed

- `VNumericKeypadSheet` — tap trong sheet không cướp focus display (`TapRegion` + `VInput.groupId`); outside = ngoài sheet.

### Internal

- `VInput` — package-internal TextField chrome
- `VNumericKeypadGrid` key cell dùng `VCard` thay Material/InkWell thủ công; bọc `ExcludeFocus` để không nhận focus.

## [1.2.1] - 2026-09-07

### Added

- `VTabsList` / `VTabsTrigger` / `VTabsContent` — compound tabs: bar + body đồng bộ qua `selectedIndex`/`onTabSelected`; vuốt trên bar (khi không scrollable) hoặc body (PageView) để đổi tab; `VTabsListVariant` (`line` | `plain`); `VTabsOrientation` (`horizontal` | `vertical`); tab disabled bị bỏ qua khi swipe.
- `VTextArea` — canonical multiline form control (copy từ `VTextFormField`).
- `VOpacity.disabled` (0.4) + `vDisabledOpacity` — chuẩn disabled state toàn control.

### Changed

- `VTabs` chuyển sang compound API — prefer `VTabs` + `VTabsList` + `VTabsTrigger` + `VTabsContent`; `VTabs.tabs` và `VTabs.isScrollable` marked `@Deprecated` với bridge tự dựng `VTabsList` để call site cũ không vỡ.

## [1.2.0] - 2026-08-28

### Added

- `VField` / `VFieldLabel` / `VFieldDescription` / `VFieldError` — compound field shell; control là child trực tiếp; `vFieldShell` legacy bridge.
- `VDatePicker.iconPosition` (`left` | `right`, mặc định `left`).
- `VCard.enabled` — soft-inherit `VComponentScope`; disabled → border `borderDefault`, bỏ `onTap`, cascade `enabled: false`.
- `VBadgeVariant` (`soft` | `strong`) — `soft` giữ nền tint (shade 50) + foreground theo tone; `strong` nền màu 500 của tone + foreground `textInverse`.
- `VColorScheme.backgroundForTone` / `borderForTone` — nền tint (shade 50) và border đặc theo tone (`neutral` → `borderStrong`, `primary` → `borderBrand`, còn lại dùng chính màu tone); dùng chung bởi `VBadge` và `VChip`.
- `VIconWeight` (`thin` → `semiBold`) + `VIcon.weight` — chọn độ dày stroke của icon Lucide bằng cách đổi font family (`Lucide100`..`Lucide600`). Mặc định `null` = giữ family `Lucide` như trước nên không đổi giao diện hiện có; bỏ qua với `assetPath` và với Material `iconData` (deprecated). Icon có `weight` render qua `Text` thay vì `Icon` để không tạo `IconData` runtime (giữ được `--tree-shake-icons`).

### Changed

- `VDatePicker` calendar icon mặc định bên trái (trước đây bên phải); dùng `iconPosition: right` để giữ layout cũ.
- Flat field chrome (`label` / `helperText` / `errorText` / `isRequired`, plus `VChoiceList.title` / `VDatePicker.required`) marked `@Deprecated` — prefer `VField` + `VFieldLabel` / `VFieldDescription` / `VFieldError`; bridge vẫn hoạt động.
- `VSearchBar`: height = `VTextField.controlHeight`, radius `VRadius.card`; variant `filled` luôn có border (`borderDefault` / focus `borderStrong`); icon muted hơn.
- `VBadge` dùng `VComponentTone` (+ ambient `VComponentScope`) cho màu; `VBadgeStatus`, `VBadge.status` và `toneFromBadgeStatus` marked `@Deprecated` — bridge status → tone vẫn hoạt động, `status` giờ optional.
- `VBadge` tone `neutral`: soft = `surfaceAlt` + `textPrimary` (trước là `textSecondary`); status `locked` đổi nền `background` → `surfaceAlt`.
- `VChip` lấy toàn bộ màu từ `VComponentTone` (+ ambient `VComponentScope`), một kiểu soft duy nhất: nền tint + chữ theo tone + border đặc; tone mặc định `neutral`, `primary` dùng `surfaceBrand` / `textBrand`.
- `VChip` icon và nút xóa bị chặn theo line height của label (20px) — trước đây nút xóa 24x24 làm chip cao hơn một dòng chữ.
- `VChip.selected` và `VChip.emphasis` marked `@Deprecated` — bridge `selected: true` → tone `primary`, `emphasis: strong` → `primary`, `subtle`/`medium` → `neutral`. Chip đang chọn giờ là soft brand thay vì fill xanh lá + chữ trắng.

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
