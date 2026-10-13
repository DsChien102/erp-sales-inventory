# 10-4 — Tương phản màu xanh chủ đạo và nhãn thanh điều hướng dưới

> Phase: P10 · Trạng thái: Plan ✅ | Làm ✅ (2026-10-13) | Review ✅ (2026-10-13; còn kiểm tay 6.2, 6.3)
> Không phụ thuộc phase nghiệp vụ nào; làm được bất cứ lúc nào (chỉ đụng `vet45_design_system` và 1 file ERP).
> Nguồn: `/impeccable document` (2026-10-13) phát hiện khi trích xuất [DESIGN.md](../../../../DESIGN.md).
> Tài liệu liên quan: [LUONG-UNG-DUNG](../../../02-yeu-cau/LUONG-UNG-DUNG.md) mục 1 (tên 5 tab), [SCOPE](../../SCOPE.md) mục 2.3, README `packages/vet45_design_system` (quy tắc example catalog, version).

## 1. Mục tiêu

Sửa 2 lỗi khả năng tiếp cận (không phải thiết kế lại):

1. **Tương phản:** chữ trắng trên nút xanh và chữ / icon xanh trên nền sáng đạt tối thiểu 4.5:1 (WCAG AA).
2. **Thanh dưới:** mỗi tab hiện nhãn chữ dưới icon; VoiceOver / TalkBack đọc được tên tab và trạng thái đang chọn.

## 2. Hiện trạng (đo 2026-10-13)

### 2.1 Tương phản

Theme sáng dùng `VColors.primary500` (`#3B9448`) cho `primary` **và** `success`:

| Cặp màu | Tỉ lệ | AA (4.5) |
|---|---|---|
| Chữ trắng trên nút `#3B9448` | 3.81 | ❌ |
| Link / tab chọn `#3B9448` trên trắng | 3.81 | ❌ |
| Badge success `#3B9448` trên `successBg` `#E8F6EC` | 3.41 | ❌ |

Nếu đổi sang `primary600` (`#2F7A3A`):

| Cặp màu | Tỉ lệ |
|---|---|
| Chữ trắng trên `#2F7A3A` | 5.30 ✅ |
| `#2F7A3A` trên trắng / `#F6F8F9` / `#E8F6EC` | 5.30 / 4.97 / 4.75 ✅ |
| Chữ trắng trên `primary800` `#1F4D26` (pressed mới) | 9.78 ✅ |

Theme tối **đã đạt**, không sửa: `#5FB36C` trên `#2F3640` = 4.73; chữ `primary900` trên nút `#5FB36C` = 4.92. App cũng đang khoá `ThemeMode.light` ([main.dart:43](../../../../apps/erp/lib/main.dart#L43)).

`primary500` nằm ở 2 nơi:
- `VColorScheme.light` ([v_color_scheme.dart](../../../../packages/vet45_design_system/lib/src/theme/v_color_scheme.dart)): `primary`, `primaryFocus`, `success` (+ `primaryHover` = 600, `primaryPressed` = 700).
- `VTheme.lightThemeForDensity` ([v_theme.dart:16-80](../../../../packages/vet45_design_system/lib/src/theme/v_theme.dart#L16-L80)), 5 chỗ: `ColorScheme.light.primary`, `cursorColor`, `selectionHandleColor`, `focusedBorder`, `elevatedButtonTheme.backgroundColor`. Đây là màu cho widget Material thuần (`ElevatedButton`, `TextField` không qua `V*`, `Checkbox`…).

Không có chỗ nào trong `apps/`, `modules/`, `packages/` (ngoài `tokens_tab.dart` của example) dùng thẳng `VColors.primary*` hay `0xFF3B9448` → đổi ánh xạ là đủ. Không test nào khẳng định giá trị màu cụ thể.

### 2.2 Thanh dưới

- [v_bottom_navigation_bar.dart](../../../../packages/vet45_design_system/lib/src/components/v_bottom_navigation_bar.dart): `VBottomNavigationItem` **có** `label` nhưng widget không dùng tới: chỉ vẽ icon 29px trong ô `minHeight: 50`, không `Text`, không `Semantics`, không `Tooltip`. `InkWell` cho nút, nhưng trình đọc màn hình chỉ đọc "nút", không có tên, không có trạng thái chọn.
- [erp_bottom_navigation.dart](../../../../apps/erp/lib/features/dashboard/presentation/widgets/erp_bottom_navigation.dart): truyền nhãn `Trang chủ`, `Đơn hàng`, `Sản phẩm`, **`KH&NCC`**, `Thêm`. Đặc tả LUONG-UNG-DUNG ghi tab 4 là **`Đối tác`**. Trước đây nhãn không hiện nên lệch không ai thấy.
- Nơi dùng: chỉ `dashboard_page.dart:332`. Test: `default_pair_gate_test.dart` chỉ `find.byType(ErpBottomNavigation)`, không phụ thuộc nhãn. Design system chưa có test cho widget này.
- Example: `components_tab.dart:1598` (3 tab tiếng Anh), `ui_audit_tab.dart:61, 188`.

## 3. Quyết định cần bạn duyệt

| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | Màu chủ đạo mới cho theme sáng | `primary600` `#2F7A3A` (đậm hơn một bậc, giữ thang `VColors`) |
| Q2 | Nhãn tab 4 | **`Đối tác`** theo LUONG-UNG-DUNG (đặc tả là chuẩn; `KH&NCC` khó hiểu với người mới). Sửa ở ERP, không đụng đặc tả |
| Q3 | Ghi ngoại lệ vào SCOPE 2.3 ("không thiết kế lại UI") | Có: thêm 1 dòng "sửa lỗi khả năng tiếp cận (10-4) không tính là thiết kế lại" |

## 4. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `packages/vet45_design_system/lib/src/theme/v_color_scheme.dart` | sửa | `light`: `primary` 500→600, `primaryHover` 600→700, `primaryPressed` 700→800, `primaryFocus` 500→600, `success` 500→600. `dark` giữ nguyên |
| `packages/vet45_design_system/lib/src/theme/v_theme.dart` | sửa | `lightThemeForDensity`: 5 chỗ `VColors.primary500` → `VColors.primary600`. `darkThemeForDensity` giữ nguyên |
| `packages/vet45_design_system/lib/src/components/v_bottom_navigation_bar.dart` | sửa | Hiện nhãn, icon 24px, `Semantics` (mục 5.2) |
| `packages/vet45_design_system/test/components/v_bottom_navigation_bar_test.dart` | tạo | Test mục 6 |
| `packages/vet45_design_system/example/lib/preview/components_tab.dart` | sửa | Section `VBottomNavigationBar`: 5 tab tiếng Việt giống ERP + 1 tab `enabled: false` để xem trạng thái vô hiệu |
| `packages/vet45_design_system/CHANGELOG.md` + `pubspec.yaml` | sửa | Ghi `[Unreleased]`, bump **minor** (1.4.1 → 1.5.0) bằng `scripts/bump_version.sh --minor` vì đổi hình thức nhìn thấy được |
| `apps/erp/lib/features/dashboard/presentation/widgets/erp_bottom_navigation.dart` | sửa | `ErpTab.partners.label`: `'KH&NCC'` → `'Đối tác'` (nếu Q2 duyệt) |
| `docs/refactor/SCOPE.md` | sửa | Dòng ngoại lệ ở 2.3 (nếu Q3 duyệt) |

Không đụng: `VColors` (thang gốc), `textBrand` (`primary700`, đã 7.41), `focusRing`, các màu `*Bg`, theme tối, `ProductFormBottomBar`.

## 5. Các bước

### 5.0 Trước khi sửa

Theo CLAUDE.md, chạy `impact` (upstream) cho `VColorScheme`, `VTheme`, `VBottomNavigationBar`, `ErpTab` và ghi blast radius vào mục Review. `VColorScheme` / `VTheme` chắc chắn ra **HIGH/CRITICAL** (mọi màn đều dùng) — rủi ro ở đây là **thay đổi thị giác**, không đổi API hay hành vi, nên chấp nhận được; nhưng cần kiểm tay mục 6.3.

### 5.1 Màu (A)

```dart
// v_color_scheme.dart — VColorScheme.light
primary: VColors.primary600,
primaryHover: VColors.primary700,
primaryPressed: VColors.primary800,
primaryFocus: VColors.primary600,
success: VColors.primary600,
```

```dart
// v_theme.dart — lightThemeForDensity: thay cả 5 chỗ
colorScheme: const ColorScheme.light(primary: VColors.primary600, …),
cursorColor: VColors.primary600,
selectionHandleColor: VColors.primary600,
focusedBorder: VBorders.outlineInput(VColors.primary600, width: VBorders.thick),
elevatedButtonTheme: … backgroundColor: VColors.primary600,
```

Kiểm nhanh sau khi sửa: `git grep -n "primary500" packages/vet45_design_system/lib` chỉ còn trong `v_colors.dart` (định nghĩa) và theme tối nếu có.

### 5.2 Thanh dưới (B)

Trong `List.generate` của `VBottomNavigationBar.build`, thay phần con của `InkWell`:

```dart
return Expanded(
  child: MergeSemantics(
    child: Semantics(
      selected: isSelected,
      button: true,
      child: vDisabledOpacity(
        enabled: isEnabled,
        child: InkWell(
          onTap: isEnabled ? () => onTap(index) : null,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 24),
                  child: item.icon,
                ),
                const VGap(VSpacing.space1),
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: VTypography.labelSmall.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
```

Ghi chú:
- `MergeSemantics` gộp nhãn của `Text` + hành động chạm của `InkWell` + `selected` thành **một** nút; `Icon` không có `semanticLabel` nên không bị đọc thừa.
- Không bọc `ExcludeSemantics` quanh `InkWell` (sẽ mất hành động chạm với trình đọc màn hình).
- Chiều cao: nội dung mới ≈ 24 + 4 + 14 = 42px, vẫn nằm trong `minHeight: 50` → **thanh không cao thêm**, không cần sửa padding của màn nào.
- `withClampedTextScaling(1.3)`: chữ vẫn phóng theo cài đặt cỡ chữ nhưng không vỡ thanh; nhãn dài nhất "Trang chủ" ở 11px ≈ 50px, vừa ô ~75px trên màn 375px kể cả ×1.3.
- Thêm import `../tokens/v_typography.dart`, `../tokens/v_spacing.dart`, `../patterns/v_gap.dart` nếu file chưa có.

### 5.3 ERP và example

1. `ErpTab.partners`: `label: 'Đối tác'` (Q2).
2. Example `components_tab.dart`: đổi 3 tab tiếng Anh thành 5 tab ERP, thêm `VBottomNavigationItem(…, enabled: false)` vào một bản xem trạng thái vô hiệu. `ui_audit_tab.dart` không cần đổi (chỉ liệt kê tên).

### 5.4 Tài liệu

1. `CHANGELOG.md` `[Unreleased]`:
   - *Changed:* theme sáng dùng `primary600` cho `primary` / `success` / Material `ColorScheme.primary` (đạt WCAG AA 4.5:1).
   - *Fixed:* `VBottomNavigationBar` hiện nhãn và có semantics (tên tab, trạng thái chọn).
2. `scripts/bump_version.sh --minor`.
3. SCOPE 2.3: dòng ngoại lệ (Q3).
4. PLAN.md: P10 thêm dòng 10-4; danh sách plan thêm link.
5. Sau review: Claude cập nhật `DESIGN.md` + `.impeccable/design.json` (Clinic Leaf Green → `#2F7A3A`, hover/pressed, mục Navigation có nhãn; bỏ dòng Don't về tương phản `#3B9448` hoặc sửa lại cho khớp).

## 6. Kiểm tra

### 6.1 Tự động
- [ ] `flutter analyze` trong `packages/vet45_design_system` và `apps/erp`: không lỗi mới.
- [ ] `flutter test` trong `packages/vet45_design_system` (có test mới) và `apps/erp/test/features/dashboard`.
- [ ] Test mới `v_bottom_navigation_bar_test.dart`:
  - hiện đủ `Text` cho mọi `label`;
  - `tester.getSemantics(find.text('Đơn hàng'))` có `label: 'Đơn hàng'`, `isButton`, `isSelected` đúng theo `currentIndex`;
  - chạm tab bật → gọi `onTap(index)`; chạm tab `enabled: false` → không gọi;
  - màu nhãn tab chọn = `colors.primary`, tab khác = `colors.textSecondary`.
- [ ] `detect_changes()` trước commit: chỉ đụng các symbol ở mục 4.

### 6.2 Example catalog
- [ ] `melos run design-system:example`: tab Components → nút primary / secondary / tertiary / link, badge & chip success, ô nhập focus, thanh dưới (có nhãn, có tab vô hiệu).

### 6.3 Kiểm tay trên app (iOS + Android)
- [ ] Đăng nhập → Trang chủ: thanh dưới có 5 nhãn, tab chọn xanh, chiều cao không đổi so với trước.
- [ ] VoiceOver (iOS) / TalkBack (Android): vuốt qua thanh dưới đọc "Trang chủ, đã chọn, nút" / "Đơn hàng, nút"…
- [ ] Cài đặt cỡ chữ lớn nhất: nhãn không tràn, không đẩy vỡ thanh.
- [ ] Lướt các màn có nhiều màu xanh (đăng nhập, đăng ký, lập đơn, chi tiết đơn, thẻ trạng thái): màu đậm hơn nhưng không lệch tông; nút nhấn giữ có phản hồi.

## 7. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Đổi màu toàn app trông "tối" hơn ở vài chỗ dùng `primary` làm mảng nền lớn | Kiểm tay 6.3; nếu có chỗ chỉ trang trí (không chữ) thì cân nhắc `surfaceBrand` thay vì giữ `primary500` riêng |
| Ảnh chụp / tài liệu báo cáo cũ có màu cũ | Chụp lại khi làm P10-1 / 10-2 (làm sau 10-4) |
| Nhãn "Đối tác" khác thói quen nếu đã demo "KH&NCC" | Nhãn trước đây không hiện nên chưa ai thấy |

## Review

### Lần 1 — 2026-10-13: đạt (còn kiểm tay)

Diff (chưa commit) khớp mục 4; Q1–Q3 đều làm theo đề xuất.

| Mục | Kết quả |
|---|---|
| `VColorScheme.light` | `primary` 600, `primaryHover` 700, `primaryPressed` 800, `primaryFocus` 600, `success` 600 ✅. Theme tối giữ nguyên (`success: primary500` ở dòng 190 là của `dark`, đúng plan) |
| `VTheme.lightThemeForDensity` | Đủ 5 chỗ → `primary600` ✅. `git grep primary500 lib` chỉ còn `v_colors.dart` và theme tối |
| `VBottomNavigationBar` | Đúng mẫu 5.2: `MergeSemantics` + `Semantics(selected, button)`, icon 24, `VGap(space1)`, nhãn `labelSmall` có `withClampedTextScaling(1.3)`; giữ `minHeight: 50` nên thanh không cao thêm ✅ |
| Test mới | 4 test (nhãn, semantics tên / nút / đã chọn, tab vô hiệu không gọi `onTap`, màu nhãn) — đạt ✅ |
| ERP | `ErpTab.partners` → `Đối tác` ✅; không còn `KH&NCC` trong `apps/erp` |
| Example | 5 tab tiếng Việt + tab `Thêm` vô hiệu ✅ |
| CHANGELOG / version | 1.5.0, Changed + Fixed đúng nội dung. Mục `VEmptyState` đang nằm ở `[Unreleased]` được chuyển vào 1.5.0 — hợp lý vì phát hành cùng |
| SCOPE 2.3 | Có dòng ngoại lệ ✅ |

Chạy:
- `flutter test` trong `packages/vet45_design_system`: 292 đạt, **2 lỗi không liên quan** ở `test/v_overlay_menu_shell_test.dart` (khẳng định bóng `e2`, widget đang dùng `e1`). File test, `v_overlay_menu_shell.dart` và `v_shadows.dart` không nằm trong diff; lần cuối đổi ở `ac72a2f65` → lỗi có từ trước, để việc riêng.
- `flutter test test/features/dashboard` (ERP): đạt.
- `flutter analyze` **bị crash** (analysis server lỗi `FormatException` khi đọc gói LSP — nghi do đường dẫn có dấu "Đồ án"), nên dùng `dart analyze`: `lib` + `test` của design system chỉ 1 warning cũ (`v_combobox_layout_test.dart:46`); `components_tab.dart` sạch; `apps/erp/lib/features/dashboard` 27 info `deprecated_member_use` có từ trước, không có ở `erp_bottom_navigation.dart`.
- `impact` / `detect_changes` của GitNexus: phiên review không có công cụ GitNexus → **chưa chạy**; chạy `detect_changes()` trước khi commit theo CLAUDE.md.

Còn lại (bạn làm):
- [ ] 6.2 Example catalog.
- [ ] 6.3 Kiểm tay iOS + Android: VoiceOver / TalkBack, cỡ chữ lớn nhất, các màn nhiều màu xanh.
- [ ] Commit (gợi ý: `fix(design-system): WCAG AA primary contrast and labelled bottom navigation (10-4)`).

Đã cập nhật theo kết quả: `DESIGN.md` + `.impeccable/design.json` (Clinic Leaf Green `#2F7A3A`, hover / pressed mới, thanh dưới có nhãn).
