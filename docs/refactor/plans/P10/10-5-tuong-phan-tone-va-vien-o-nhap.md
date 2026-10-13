# 10-5 — Tương phản các tone trạng thái, chữ phụ và viền ô nhập

> Phase: P10 · Trạng thái: Plan ✅ | Làm ✅ (2026-10-13) | Review ✅ (2026-10-13; còn kiểm tay 6.2, 6.3)
> Độc lập với phase nghiệp vụ; làm sau [10-4](10-4-tuong-phan-mau-thanh-dieu-huong.md) (cùng cách: đổi ánh xạ trong theme sáng, không đổi API dùng màu).
> Nguồn: `/impeccable audit packages/vet45_design_system` (2026-10-13), mục P1 "tone cảnh báo", P2 "tone wash", P2 "`textMuted`", P2 "viền ô nhập".
> Tài liệu liên quan: [DESIGN.md](../../../../DESIGN.md) mục Colors, [SCOPE](../../SCOPE.md) 2.3 (ngoại lệ khả năng tiếp cận).

## 1. Mục tiêu

Ở **theme sáng**, mọi chữ / icon mang màu trạng thái và mọi chữ phụ đạt **4.5:1** (WCAG 1.4.3); viền ô nhập, checkbox, radio đạt **3:1** (WCAG 1.4.11). Theme tối không đổi trong plan này (app đang khoá `ThemeMode.light`; theme tối để việc sau).

## 2. Hiện trạng (đo 2026-10-13)

### 2.1 Tone trạng thái

Theme sáng dùng bậc 500 của mỗi thang làm màu chữ / icon / nền nút:

| Tone | Màu | Trên trắng | Trên nền wash của nó | Chữ trắng trên nút |
|---|---|---|---|---|
| warning | `yellow500` `#D98A0B` | **2.77** ❌ | **2.51** ❌ (`#FDF3E0`) | **2.77** ❌ |
| danger | `red500` `#D14343` | 4.57 ✅ | **3.88** ❌ (`#FBE8E8`) | 4.57 ✅ |
| info | `blue500` `#2F6FE0` | 4.70 ✅ | **4.09** ❌ (`#E8F0FC`) | — |
| success | `primary600` (10-4) | 5.30 ✅ | 4.75 ✅ | 5.30 ✅ |

`foregroundForTone` / `backgroundForTone` ([v_color_scheme.dart:360-400](../../../../packages/vet45_design_system/lib/src/theme/v_color_scheme.dart#L360-L400)) trả về đúng các field này cho badge, chip, card, button, input → đổi ánh xạ là đủ. App dùng `tone: VComponentTone.warning` 16 chỗ.

`VTheme.lightThemeForDensity` còn `VColors.red500` ở `ColorScheme.light.error`, `errorBorder`, `focusedErrorBorder` (widget Material thuần, chữ lỗi của `InputDecoration`).

### 2.2 Chữ phụ

| Token | Màu | Trên trắng (`surface`) | Trên nền trang `#F6F8F9` | Dùng |
|---|---|---|---|---|
| `textSecondary` | `neutral500` `#6B7480` | 4.74 ✅ | **4.44** ❌ | 517 chỗ app, 27 chỗ DS |
| `textMuted` | `neutral400` `#9AA3AD` | **2.56** ❌ | **2.40** ❌ | 126 chỗ app, 22 chỗ DS (placeholder, chữ phụ, icon trạng thái trống, trạng thái vô hiệu) |

### 2.3 Viền control

| Chỗ | Màu viền | Trên trắng |
|---|---|---|
| `VInput` (`v_input.dart:213, 217`), `VTextArea` (`:222`), `VSelect` (`:352`), `VDatePicker` (`:117`) | `borderDefault` `#E5E8EB` | **1.23** ❌ |
| `VCheckbox` (`:52`), `VRadio` (`:41`), `VVerificationCodeField` (`:231`), `VSelect` (`:408`) | `borderStrong` `#D0D5DA` | **1.48** ❌ |
| `VTheme` `inputDecorationTheme.border` / `enabledBorder` | `VColors.neutral300` | **1.48** ❌ |

`borderDefault` cũng là đường kẻ chia vùng (app bar, thanh dưới, thẻ) → **không** đổi nó, chỉ thêm token riêng cho viền control.

### 2.4 Màu ứng viên (đã tính)

| Màu | Trên trắng | Trên `#F6F8F9` | Trên wash cùng tone | Chữ trắng trên nó |
|---|---|---|---|---|
| `yellow700` `#935A0A` | 5.66 | 5.32 | 5.14 | 5.66 |
| `red600` `#B53232` | 6.06 | 5.69 | 5.14 | 6.06 |
| `blue600` `#2559C4` | 6.35 | 5.97 | 5.54 | 6.35 |
| `neutral600` `#4A535E` | 7.81 | 7.33 | — | — |
| `neutral500` `#6B7480` | 4.74 | 4.44 | — | — |
| mới `neutral450` `#868E98` | 3.31 | 3.11 | — | — |

## 3. Quyết định cần bạn duyệt

| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | Màu chữ / nền nút của các tone | warning → `yellow700`, danger → `red600`, info → `blue600`; hover / pressed dời xuống 1–2 bậc. Nền wash (`*Bg`) giữ nguyên |
| Q2 | Chữ phụ | **Phương án B:** `textSecondary` → `neutral600`, `textMuted` → `neutral500`. Giữ được 2 cấp chữ phụ, cả hai đạt trên nền trắng. Đổi nhìn thấy rõ (chữ phụ đậm hơn ở ~640 chỗ). *Phương án A (ít đổi hơn):* giữ `textSecondary`, chỉ đổi `textMuted` → `neutral500` ⇒ hai token trùng màu, mất một cấp, `textSecondary` trên nền trang vẫn 4.44 |
| Q3 | Viền control | Thêm primitive `VColors.neutral450 = #868E98` và token ngữ nghĩa mới `borderInput` (sáng: `neutral450`; tối: `neutral400`, 4.77 trên `surface` tối). Chỉ dùng cho ranh giới control (ô nhập, checkbox, radio, ô mã) |

Lưu ý Q2B: `textMuted` mới (4.74) trên nền trang vẫn 4.44 → giữ quy ước `textMuted` chỉ đặt trên `surface` (thẻ, ô nhập, sheet), không đặt thẳng trên nền trang. Ghi vào DESIGN.md.

## 4. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `packages/vet45_design_system/lib/src/tokens/v_colors.dart` | sửa | Thêm `neutral450 = Color(0xFF868E98)` giữa `neutral400` và `neutral500` |
| `packages/vet45_design_system/lib/src/theme/v_color_scheme.dart` | sửa | Field mới `borderInput` (constructor, `copyWith`, `lerp`, `light`, `dark`); `light`: ánh xạ mục 5.1 |
| `packages/vet45_design_system/lib/src/theme/v_theme.dart` | sửa | `lightThemeForDensity`: `error` / `errorBorder` / `focusedErrorBorder` → `red600`; `border` / `enabledBorder` → `neutral450` |
| `components/v_input.dart`, `components/v_text_area.dart`, `forms/v_select.dart`, `forms/v_date_picker.dart` | sửa | Viền trạng thái thường: `borderDefault` → `borderInput`. Viền **vô hiệu** giữ `borderDefault` (được miễn tương phản) |
| `components/v_checkbox.dart`, `components/v_radio.dart`, `components/v_verification_code_field.dart`, `forms/v_select.dart:408` | sửa | `borderStrong` → `borderInput` |
| `example/lib/preview/tokens_tab.dart` | sửa | Thêm ô `neutral450`; ô `borderInput` nếu tab có liệt kê token ngữ nghĩa |
| `example/lib/preview/ui_audit_tab.dart` | sửa | (Khuyến nghị) thêm bảng tương phản tự tính cho `foregroundForTone(tone)` trên `surface` và `backgroundForTone(tone)` — để lần sau đổi màu nhìn thấy ngay |
| `test/theme/v_color_scheme_contrast_test.dart` | tạo | Test mục 6.1 |
| `CHANGELOG.md`, `pubspec.yaml` | sửa | `[Unreleased]` + `scripts/bump_version.sh --minor` (1.5.0 → 1.6.0) |

Không đổi: các `*Bg`, `*BgPressed`, `borderDefault`, `borderStrong` (vẫn dùng cho viền thẻ / chia vùng), toàn bộ theme tối ngoài field mới `borderInput`.

## 5. Các bước

### 5.0 Trước khi sửa

Chạy `impact` (upstream) cho `VColorScheme`, `VTheme`, `VInput`, `VTextArea`, `VSelect`, `VDatePicker`, `VCheckbox`, `VRadio`, `VVerificationCodeField`; ghi blast radius vào mục Review. `VColorScheme` sẽ ra HIGH/CRITICAL như 10-4 — thay đổi thị giác, không đổi API (field mới là **thêm**).

### 5.1 Ánh xạ màu theme sáng

```dart
// v_colors.dart
static const Color neutral450 = Color(0xFF868E98);
```

```dart
// v_color_scheme.dart — VColorScheme.light (chỉ các dòng đổi / thêm)
textSecondary: VColors.neutral600,   // Q2 phương án B
textMuted: VColors.neutral500,       // Q2
borderInput: VColors.neutral450,     // Q3 (mới)

warning: VColors.yellow700,
warningHover: VColors.yellow800,
warningPressed: VColors.yellow900,

danger: VColors.red600,
dangerHover: VColors.red700,
dangerPressed: VColors.red800,

info: VColors.blue600,
infoHover: VColors.blue700,
infoPressed: VColors.blue800,
```

```dart
// VColorScheme.dark — chỉ thêm field mới
borderInput: VColors.neutral400,
```

Field mới cần thêm ở 4 chỗ: khai báo `final Color borderInput;`, constructor `required this.borderInput`, `copyWith`, `lerp` (`Color.lerp(borderInput, other.borderInput, t)!`). Đặt cạnh `borderStrong` cho dễ đọc.

### 5.2 `VTheme.lightThemeForDensity`

```dart
colorScheme: const ColorScheme.light(primary: VColors.primary600, error: VColors.red600, surface: VColors.neutral0),
border: VBorders.outlineInput(VColors.neutral450),
enabledBorder: VBorders.outlineInput(VColors.neutral450),
errorBorder: VBorders.outlineInput(VColors.red600),
focusedErrorBorder: VBorders.outlineInput(VColors.red600, width: VBorders.thick),
```

### 5.3 Component

Mỗi file ở bảng mục 4: thay đúng các dòng đã liệt kê. Mẫu cho `VInput` (`v_input.dart:205-220`):

```dart
final restingBorderColor = isInvalid
    ? colors.danger
    : switch (widget.tone) {
        VComponentTone.primary => colors.primary,
        VComponentTone.danger => colors.danger,
        _ => colors.borderInput,          // trước: colors.borderDefault
      };
…
final borderColor = !isEnabled
    ? colors.borderDefault                // vô hiệu: giữ nguyên
    : focused ? focusBorderColor : restingBorderColor;
```

`VTextArea` (`:222`), `VSelect` (`:352`), `VDatePicker` (`:117`) cùng dạng: chỉ đổi nhánh `_ =>` trong `switch (widget.tone)`; `v_text_area.dart:254` (`disabledOutline`) giữ `borderDefault`.

Kiểm nhanh sau khi sửa:
- `git grep -n "yellow500\|red500\|blue500" packages/vet45_design_system/lib/src/theme` chỉ còn trong theme tối.
- `git grep -n "borderDefault" packages/vet45_design_system/lib/src/{components/v_input,components/v_text_area,forms/v_select,forms/v_date_picker}.dart` chỉ còn nhánh vô hiệu.

### 5.4 Tài liệu

1. `CHANGELOG.md` `[Unreleased]`:
   - *Added:* `VColors.neutral450`, `VColorScheme.borderInput`.
   - *Changed:* theme sáng — warning `yellow700`, danger `red600`, info `blue600`, `textSecondary` `neutral600`, `textMuted` `neutral500`; ô nhập / checkbox / radio / ô mã dùng `borderInput` (WCAG 1.4.3, 1.4.11).
2. `scripts/bump_version.sh --minor`.
3. PLAN.md: dòng 10-5.
4. Sau review: Claude cập nhật `DESIGN.md` + `.impeccable/design.json` (màu tone, chữ phụ, token `borderInput`, quy ước `textMuted` chỉ trên `surface`).

## 6. Kiểm tra

### 6.1 Tự động
- [ ] `dart analyze lib test` trong `packages/vet45_design_system` (dùng `dart analyze` vì `flutter analyze` đang crash, xem review 10-4): không lỗi mới.
- [ ] Test mới `test/theme/v_color_scheme_contrast_test.dart`, chạy trên `VColorScheme.light`, có hàm `contrast(a, b)` theo công thức WCAG (`Color.computeLuminance()`):
  - với mỗi tone `success | warning | danger | info`: `foregroundForTone` trên `surface` ≥ 4.5 và trên `backgroundForTone` ≥ 4.5;
  - `textInverse` trên `primary`, `warning`, `danger` ≥ 4.5;
  - `textPrimary`, `textSecondary`, `textMuted` trên `surface` ≥ 4.5; `textSecondary` trên `background` ≥ 4.5;
  - `borderInput` trên `surface` ≥ 3.0.
- [ ] `flutter test` của package: không lỗi mới (2 lỗi cũ `v_overlay_menu_shell_test.dart` vẫn tách riêng).
- [ ] `detect_changes()` trước commit.

### 6.2 Example catalog
- [ ] Tab Tokens: có `neutral450`. Tab Components / Forms: badge, chip, card, button với cả 4 tone; ô nhập thường / focus / lỗi / vô hiệu; checkbox, radio, ô mã.

### 6.3 Kiểm tay trên app
- [ ] Các màn có cảnh báo vàng (tồn kho, hồ sơ pháp lý, lời mời hết hạn…): chữ đọc rõ, màu vẫn nhận ra là "vàng / cam".
- [ ] Form đăng nhập, đăng ký, sản phẩm: viền ô nhập rõ hơn nhưng không nặng nề; ô vô hiệu vẫn nhạt hơn ô thường.
- [ ] Danh sách đơn / sản phẩm: chữ phụ đậm hơn, vẫn phân biệt được với chữ chính.

## 7. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Vàng `#935A0A` ngả nâu, kém "cảnh báo" | Nền wash vẫn vàng nhạt + icon cảnh báo; kiểm tay 6.3. Nếu không ưng, nút cảnh báo có thể giữ nền `yellow500` với chữ `textPrimary` (6.84) — cần thêm field `onWarning`, để lượt sau |
| Chữ phụ đậm hơn ở ~640 chỗ làm giao diện "nặng" | Đây là lý do có Q2; chọn phương án A nếu muốn đổi ít |
| Viền ô nhập đậm hơn làm form trông dày | `#868E98` là mức tối thiểu đạt 3:1; không đậm hơn |

## Review

### Lần 1 — 2026-10-13: đạt (còn kiểm tay)

Q1–Q3 làm theo đề xuất (Q2 phương án B).

| Mục | Kết quả |
|---|---|
| `VColors.neutral450` | ✅ `#868E98` |
| `VColorScheme` | `borderInput` đủ 4 chỗ (field, constructor, `copyWith`, `lerp`); sáng `neutral450`, tối `neutral400` ✅. Theme sáng: `textSecondary` 600, `textMuted` 500, warning 700/800/900, danger 600/700/800, info 600/700/800 ✅. Theme tối không đổi ngoài `borderInput` ✅ |
| `VTheme.lightThemeForDensity` | `error` / `errorBorder` / `focusedErrorBorder` → `red600`; `border` / `enabledBorder` → `neutral450` ✅ |
| Viền control | `VInput`, `VTextArea`, `VSelect` (2 chỗ), `VDatePicker`, `VCheckbox`, `VRadio`, `VVerificationCodeField` → `borderInput` ✅. Nhánh vô hiệu giữ `borderDefault`; `VSelect` / `VDatePicker` nay phân biệt viền vô hiệu (trước đây không) — tốt hơn plan |
| Test tương phản | `test/theme/v_color_scheme_contrast_test.dart`: tone trên `surface` và trên wash, `textInverse` trên nền đặc **kể cả hover / pressed**, chữ phụ, `textSecondary` trên nền trang, `borderInput` (sáng + tối), `borderInput ≠ borderDefault`, `copyWith` / `lerp` — rộng hơn plan ✅ |
| Example | `tokens_tab.dart` có `neutral450` ✅. `ui_audit_tab.dart` (bảng tương phản — khuyến nghị) **chưa làm**; không bắt buộc vì test tương phản đã khoá |
| CHANGELOG / version | 1.6.0 đúng nội dung, ghi quy ước `textMuted` chỉ trên `surface` ✅ |

Lệch so với plan — **đã kiểm, chấp nhận**:

| # | Lệch | Đánh giá |
|---|---|---|
| 1 | `VSelect` / `VDatePicker` thêm nhánh `isEnabled ? borderInput : borderDefault` | **Plan sai**: plan coi như hai widget đã có nhánh vô hiệu; thực tế không có, chỉ đổi `_ =>` sẽ làm ô vô hiệu đậm bằng ô thường, trái 6.3 |
| 2 | Sửa `test/patterns/v_field_test.dart` (dòng 176, 205) từ `borderDefault` sang `borderInput` | Đúng, test khẳng định thiết kế cũ; plan bỏ sót file này |
| 3 | Bỏ bảng tương phản ở `ui_audit_tab.dart` | Đồng ý: tab là danh sách độ phủ widget, không phải nơi đặt bảng màu; test tương phản đã thay vai trò |

Chạy (chung cho 10-5 + 10-6, diff chưa commit, gồm cả 10-4):
- `flutter test` `packages/vet45_design_system`: **349 đạt**, 2 lỗi cũ `v_overlay_menu_shell_test.dart` (có từ trước 10-4, xem review 10-4).
- `flutter test` `apps/erp`: 1.405 đạt / **59 lỗi — cả 59 đều có trong `TEST-BASELINE.md`** (so tên test: 0 lỗi mới). Không test nào vướng assert nhãn của `VIconBox`.
- `dart analyze lib test example/lib` (design system): chỉ 1 warning + 2 info cũ; `dart analyze lib/features/sales`: không error / warning.
- `impact` / `detect_changes` (GitNexus): phiên review không có công cụ → **chưa chạy**; chạy `detect_changes()` trước commit.

Còn lại (bạn làm):
- [ ] 6.2 Example catalog; 6.3 kiểm tay (cảnh báo vàng `#935A0A` còn nhận ra là "vàng" không; viền ô nhập; chữ phụ đậm hơn).
- [ ] Commit (gợi ý: `fix(design-system): WCAG AA status tones, secondary text and input borders (10-5)`).

Đã cập nhật theo kết quả: `DESIGN.md` + `.impeccable/design.json`.
