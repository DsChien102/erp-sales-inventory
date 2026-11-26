# Changelog

All notable changes to the **c45_design_system** Flutter package
(`packages/c45_design_system`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(`MAJOR.MINOR.PATCH`, no Flutter build number).

Ship unit: this library only. Deploy tags: `c45_design_system-vX.Y.Z`.
User-facing UI that ships inside ERP/Admin should also be noted under those apps'
changelogs when relevant.

## [Unreleased]

### Added

### Changed

### Fixed

- `VFieldLabel`: nhãn dài xuống dòng thay vì tràn khi chữ phóng to (10-8e).
- `VTypography`: mọi vai chữ đặt `letterSpacing` (0 nếu trước đó trống), không còn thừa hưởng 0,25 / 0,5 của Material; chữ khớp prototype (10-8e).

### Internal

## [1.10.0] - 2026-11-25

### Added

- `VVerificationCodeLayout` (`compact` / `fill` / `split4`) và tham số `VVerificationCodeField.layout`; con trỏ đứng yên ở ô đang nhập còn trống (10-8d).
- `VStepProgress` (`standard` / `mobile`): thanh tiến độ các bước, mỗi bước một đoạn cao 4 + nhãn "n. Tên bước" (10-8d).

### Changed

- `VConfirmDialog` rộng tối đa 440, đệm 24 khi cửa sổ ≥ 1024 (trước đó rộng theo cửa sổ).

### Fixed

- `VVerificationCodeField`: khi lỗi (`VField.invalid`, `invalid`, `errorText`) cả dãy ô viền `danger`, không chỉ ô đang focus.

## [1.9.0] - 2026-11-24

### Added

- `VIcons.messageCircle`, `VIcons.maximize` (Lucide `message-circle`, `maximize-2`): nút nổi và nút mở toàn màn hình "Hỏi Mosaic Retail" trên Trang chủ (10-8b).

## [1.8.0] - 2026-11-23

### Added

- `VListDetailLayout`: layout 2 cột danh sách – chi tiết khi bề rộng ≥ `minSplitWidth` (mặc định 840), hẹp hơn chỉ hiển thị chi tiết; hỗ trợ `isSplitOf(context)`.
- `VCard.isSelected`: hỗ trợ trạng thái được chọn (`surfaceBrand` + `borderBrand` và `Semantics(selected: true)`).
- `showVAdaptiveSheet` / `VSheetDialog`: bottom sheet tự động chuyển thành hộp thoại trên desktop (≥ 1024).
- `VAppBar.popNearest`: pop navigator gần nhất pop được.
- `VSideNavigation` / `VSideNavigationItem`: thanh điều hướng bên trái cho màn hình rộng (desktop ≥ 1024), mục có con mở menu nổi, vùng chạm ≥ 44pt, semantics selected, focus viền bàn phím rõ ràng, token màu chuẩn Design System.
- `VSideNavigationItem.description` / `menuTitle`, `VSideNavigationAction` (tab icon + nhãn cho footer, `destructive`), `VColors.neutral150`, `VColorScheme.surfaceHoverStrong`, `VIcons.layers` (10-8a).
- `VChip.isSelected` exposes chip selection to semantics.
- `VPageScaffold.contentMaxWidth` (+ `defaultContentMaxWidth`, `fullWidth`): từ breakpoint tablet, body và `bottomBar` nằm trong một cột giữa (640 tablet / 720 desktop); điện thoại giữ nguyên full-width. FAB bám mép cột. Trang tự chia pane truyền `VPageScaffold.fullWidth`.
- `VPageScaffold` chừa inset ngang an toàn (tai thỏ / đảo động) cho body khi xoay ngang.
- `VInput`, `VTextField`, `VEmailField`, `VPasswordField` và `VPhoneField` nhận `autofillHints` / `textInputAction`; các field form có mặc định autofill phù hợp.

### Changed

- `VSideNavigation` (10-8a): thành thanh biểu tượng rộng 84 (mặc định `width` 240 → 84). Mục không có `children` là tab icon + nhãn; mục có `children` vẽ ở đáy và mở menu nổi (`OverlayPortal`, đóng bằng Esc / bấm ngoài / chọn mục). Mục tab đang chọn tô `surfaceBrand`; nhánh có con đang chọn cũng `surfaceBrand` (bỏ 50%). `header` / `footer` giữ nguyên chữ ký, footer không còn viền trên.
- `VAppBar` uses `Navigator.maybePop()` for its default back action.
- 10-7.2 layout: `VSpacing.hairline` (1px) replaces the misnamed `space0` (deprecated); `VSection` keeps an 8px gap before the trailing action and centers a lone title on it; `VPageScaffold.bottomBar` uses a hairline top border instead of `elevation: 8`.

### Removed

- `VCombobox`: bỏ `filter`, `tone`, `emphasis` (không nơi nào dùng; trạng thái lỗi vẫn kế thừa `VField.invalid` / `invalid`). Bỏ `kVComboboxControlHeight` (dùng `VCombobox.controlHeight`).
- `VComboboxContent.padding` / `defaultPadding`, `VComboboxItem.onSelect`: bỏ.
- `VComboboxFooter`: bỏ. Truyền thẳng widget vào `VComboboxContent.footer`; cần controller thì `vComboboxOf(context)` trong `Builder`. Khoảng cách trên footer do panel đảm nhiệm.

### Fixed

- `VListDetailLayout`: toast không còn hiện ở cả hai cột.
- `VAppBar`: nút ← hiện ở trang đầu của navigator lồng (`ShellRoute`), pop navigator gần nhất pop được.
- `VChip(onTap)` keeps its drawn pill compact while exposing a 44px touch target; `VCard(onTap)` exposes button semantics. Remove/keypad labels use "Xóa".
- `VButton` dạng link có vùng chạm tối thiểu 44x44 mà không làm đổi kích thước chữ.
- `VInput` một dòng khoá chiều cao: vùng chạm / semantics của ô nhập bằng cả chiều cao ô (≥ 44); vị trí chữ không đổi.

### Internal

- `VCombobox`: gộp `_VComboboxHost` vào state, gom nhịp "đồng bộ focus ↔ menu" về một helper, bỏ `updateShouldNotify` luôn trả `false`.

## [1.7.0] - 2026-10-13

### Added

- `VIconBox.semanticLabel`: tên cho trình đọc màn hình khi có `onTap` (debug assert nếu thiếu cả `semanticLabel` lẫn `label`).
- `VSwipeReveal.semanticActions` + `VSwipeSemanticAction`: hành động ẩn công bố qua custom semantics actions trên thẻ; nút ẩn bị loại khỏi semantics khi thẻ đóng.

### Changed

- `VIconBox` có `onTap`: vùng chạm tối thiểu 44×44 (phần vẽ giữ `size`). `VChip` có `onRemove`: khung bố cục cao 44, vùng xoá 44×44 ở đuôi chip, nhãn `Xoá <label>`; icon xoá dùng `VIcons.close`.
- `VBottomNavigationBar`: chừa trọn inset dưới (thanh Home / cử chỉ) thay vì 40%; `top` 4, ô tab `minHeight` 48.
- `VInput` (khoá chiều cao): bỏ padding dọc quanh hàng prefix / text / suffix để affix chạm được dùng đủ chiều cao; vị trí chữ và chiều cao ô không đổi.

### Fixed

- Vùng chạm ≥ 44 cho nút ẩn / hiện của `VPasswordField`; nhãn cho nút quay lại `VAppBar` (`Quay lại`), mũi tên `VCombobox` (`Mở danh sách` / `Đóng danh sách`) và phím của `VNumericKeypadGrid` (`⌫` đọc `Xoá`, `.` đọc `Dấu thập phân`, phím trống bị ẩn).
- `VSkeleton` / `VSkeletonScope` đứng yên và `VSwipeReveal` mở / đóng tức thì khi bật Giảm chuyển động (`MediaQuery.disableAnimations`).

### Internal

- Test mới: `v_icon_box_test`, `v_swipe_reveal_test`, `v_skeleton_test`, `v_app_bar_test`, `v_numeric_keypad_grid_test`, `accessibility_guidelines_test`; mở rộng test chip, password field, bottom navigation.

## [1.6.0] - 2026-10-13

### Added

- `VColors.neutral450` (`#868E98`) và token ngữ nghĩa `VColorScheme.borderInput` (sáng `neutral450`, tối `neutral400`): viền ranh giới control, đạt 3:1 (WCAG 1.4.11).

### Changed

- Theme sáng, tone trạng thái đạt 4.5:1 (WCAG 1.4.3) trên `surface` và trên nền wash của tone: `warning` → `yellow700` (hover `yellow800`, pressed `yellow900`), `danger` → `red600` (hover `red700`, pressed `red800`), `info` → `blue600` (hover `blue700`, pressed `blue800`). Các `*Bg` giữ nguyên.
- Theme sáng, chữ phụ: `textSecondary` → `neutral600`, `textMuted` → `neutral500`. Quy ước: `textMuted` chỉ đặt trên `surface`, không đặt thẳng trên nền trang.
- `VInput`, `VTextArea`, `VSelect`, `VDatePicker`, `VVerificationCodeField`, `VCheckbox`, `VRadio`: viền trạng thái thường dùng `borderInput` thay `borderDefault` / `borderStrong`. Viền vô hiệu giữ `borderDefault`; `VSelect` / `VDatePicker` nay cũng phân biệt viền vô hiệu.
- `VTheme.lightTheme`: `ColorScheme.error`, `errorBorder`, `focusedErrorBorder` → `red600`; `border` / `enabledBorder` → `neutral450`. Theme tối giữ nguyên.

### Internal

- Test `test/theme/v_color_scheme_contrast_test.dart` kiểm tương phản `VColorScheme.light` (tone, chữ phụ, `borderInput`).

## [1.5.0] - 2026-10-13

### Changed

- Theme sáng dùng `primary600` (`#2F7A3A`) cho `VColorScheme.primary` / `success` và Material `ColorScheme.primary` (đạt WCAG AA 4.5:1); `primaryHover` → `primary700`, `primaryPressed` → `primary800`. Theme tối giữ nguyên.

### Fixed

- `VBottomNavigationBar`: hiện nhãn dưới icon (icon 24px) và có semantics (tên tab, nút, trạng thái đang chọn).
- `VEmptyState`: không còn RenderFlex overflow khi chiều cao parent bị siết (vd. bàn phím mở trên màn tạo đơn).

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
