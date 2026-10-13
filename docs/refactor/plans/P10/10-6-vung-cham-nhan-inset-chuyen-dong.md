# 10-6 — Vùng chạm, nhãn cho trình đọc màn hình, inset thanh dưới, giảm chuyển động

> Phase: P10 · Trạng thái: Plan ✅ | Làm ✅ (2026-10-13) | Review ✅ (2026-10-13; còn kiểm tay 6.2, 6.3)
> Độc lập với phase nghiệp vụ. Làm sau [10-5](10-5-tuong-phan-tone-va-vien-o-nhap.md) cũng được, trước cũng được (không đụng cùng dòng code; chỉ cùng bump version — ai làm sau thì bump sau).
> Nguồn: `/impeccable audit packages/vet45_design_system` (2026-10-13), các mục P1 "vùng chạm", "control chỉ có icon", "inset thanh dưới" và P2 "Reduce Motion".
> Tài liệu liên quan: [10-4](10-4-tuong-phan-mau-thanh-dieu-huong.md) (thanh dưới), SCOPE 2.3 (ngoại lệ khả năng tiếp cận).

## 1. Mục tiêu

1. Mọi control chạm được trong design system có vùng chạm **≥ 44pt** (`VSpacing.minTouchTarget`).
2. Mọi control chỉ có icon có **nhãn tiếng Việt** cho VoiceOver / TalkBack; hành động ẩn của `VSwipeReveal` dùng được bằng trình đọc màn hình.
3. Thanh dưới chừa **đủ** inset của thanh Home (iPhone) / thanh điều hướng cử chỉ (Android).
4. Khi người dùng bật **Giảm chuyển động** (iOS Reduce Motion / Android Remove animations), skeleton đứng yên và `VSwipeReveal` không trượt.

## 2. Hiện trạng (đo 2026-10-13)

| # | Component | Vấn đề | Vị trí |
|---|---|---|---|
| A | `VPasswordField` nút ẩn / hiện | Vùng chạm `tightFor(24×24)` + `shrinkWrap`. Có tooltip tiếng Việt (tốt). Dùng 7 chỗ, gồm đăng nhập / đăng ký / nhận lời mời | `forms/v_password_field.dart:142-155` |
| B | `VChip` nút xoá | `_RemoveButton` cạnh = `lineHeight` ≈ 20px; tooltip chung chung `'Xóa'`. App dùng `onRemove` 7 chỗ | `primitives/v_chip.dart:116-123, 190-215` |
| C | `VIconBox` khi có `onTap` | Không nới vùng chạm (mặc định 40, combobox dùng 24); không có tham số nhãn (`label` hiện là **chữ hiển thị** kiểu chữ tắt avatar, không phải nhãn semantics). App: 66 chỗ, 5 chỗ có `onTap` | `primitives/v_icon_box.dart:126-140` |
| D | `VCombobox` mũi tên | `VIconBox` 24px, không nhãn. Bấm vào ô nhập cũng mở danh sách nên ít nghiêm trọng hơn A | `components/v_combobox_input.dart:133-137, 165-190` |
| E | `VAppBar` nút quay lại | `IconButton` không `tooltip` → trình đọc chỉ nói "nút" | `components/v_app_bar.dart:79-86` |
| F | `VNumericKeypadGrid` | Phím là `VCard(onTap)` không có vai trò nút; phím `⌫` đọc ra ký hiệu | `components/v_numeric_keypad_grid.dart:79-108` |
| G | `VSwipeReveal` | **Đính chính so với báo cáo audit:** hành động *không* bị mất khỏi cây semantics — chúng nằm trong `Stack`, bị thẻ che khi đóng. Vấn đề thật: khi đóng, VoiceOver vẫn dừng ở các nút **vô hình** (người dùng không biết chúng ở đâu), và không có cách "mở hành động" theo kiểu của trình đọc màn hình. App dùng 2 chỗ: `sales_order_line_row.dart:79` (Chiết khấu, Xóa), `sales_draft_list_card.dart:54` (Xóa) | `components/v_swipe_reveal.dart:100-133` |
| H | `VBottomNavigationBar` inset | `bottom: bottomInset * 0.4 + 6` → iPhone có thanh Home (34pt) chỉ chừa ~19.6pt; nhãn tab (10-4) nằm trong vùng vuốt về Home | `components/v_bottom_navigation_bar.dart:46-49` |
| I | `VSkeleton` | `AnimationController..repeat()` chạy mãi, ở cả `VSkeleton` và `VSkeletonScope`; không xét `MediaQuery.disableAnimations` | `primitives/v_skeleton.dart:35-44` (scope), `:132-147` (cục bộ) |
| J | `VSwipeReveal` chuyển động | `animateTo` 200ms, không xét giảm chuyển động | `components/v_swipe_reveal.dart:76-83` |

## 3. Quyết định cần bạn duyệt

| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | Chip có nút xoá cao thêm để đủ vùng chạm 44? | Có, theo cách `InputChip` của Material: **khung bố cục** cao 44 (trong suốt), **phần vẽ** chip giữ nguyên; vùng 44×44 ở đuôi chip là nút xoá. Chip không có `onRemove` không đổi |
| Q2 | `VIconBox` có `onTap` thì tự nới bố cục lên 44 (giống `VButton`)? | Có. Phần vẽ giữ `size`; bố cục tối thiểu 44×44. Kiểm 5 chỗ app + mũi tên combobox |
| Q3 | Chiều cao thanh dưới sau khi chừa đủ inset | `top: 4`, ô tab `minHeight: 48` (chuẩn Android 48dp), `bottom: bottomInset` (≥ 12 khi không có inset). iPhone có thanh Home: 4 + 48 + 34 = **86pt** (gần tab bar gốc của iOS 83pt); trước đây ≈ 80pt |
| Q4 | API mới cho `VSwipeReveal` | Thêm `semanticActions: List<VSwipeSemanticAction>` (tuỳ chọn). Khi có: các nút ẩn bị loại khỏi cây semantics lúc đóng, và hành động được công bố qua `customSemanticsActions` trên thẻ (VoiceOver: vuốt lên / xuống để chọn "Chiết khấu", "Xóa") |

## 4. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `forms/v_password_field.dart` | sửa | Vùng chạm nút ẩn / hiện 44×44 (A) |
| `primitives/v_chip.dart` | sửa | Khung 44 + vùng xoá 44×44, nhãn `'Xoá <label>'` (B, Q1) |
| `primitives/v_icon_box.dart` | sửa | Thêm `semanticLabel`; khi có `onTap`: `Semantics(button)` + bố cục ≥ 44 (C, Q2) |
| `components/v_combobox_input.dart` | sửa | `_TrailingChevron` truyền `semanticLabel: open ? 'Đóng danh sách' : 'Mở danh sách'` (D) |
| `components/v_app_bar.dart` | sửa | `tooltip: 'Quay lại'` (E) |
| `components/v_numeric_keypad_grid.dart` | sửa | `Semantics(button: true, label: …)` cho mỗi phím, `⌫` → `'Xoá'` (F) |
| `components/v_swipe_reveal.dart` | sửa | `VSwipeSemanticAction`, tham số `semanticActions`, loại nút ẩn khỏi semantics lúc đóng (G, Q4); bỏ animation khi giảm chuyển động (J) |
| `components/v_bottom_navigation_bar.dart` | sửa | Padding và `minHeight` theo Q3 (H) |
| `primitives/v_skeleton.dart` | sửa | Dừng nhịp khi giảm chuyển động (I) |
| `lib/design_system.dart` | sửa | Export `VSwipeSemanticAction` nếu đặt ở file riêng (nếu khai báo trong `v_swipe_reveal.dart` thì đã được export cùng) |
| `apps/erp/lib/features/sales/presentation/widgets/sales_order_line_row.dart`, `sales_draft_list_card.dart` | sửa | Truyền `semanticActions` (G) |
| `example/lib/preview/components_tab.dart` | sửa | Có `VChip` với `onRemove`, `VIconBox` có `onTap`, `VSwipeReveal` có `semanticActions` |
| Test (mục 6.1) | tạo / sửa | Bổ sung `test/primitives/v_chip_test.dart`, `test/forms/v_password_field_test.dart`, `test/components/v_bottom_navigation_bar_test.dart`; tạo `test/primitives/v_icon_box_test.dart`, `test/components/v_swipe_reveal_test.dart`, `test/primitives/v_skeleton_test.dart`, `test/components/v_app_bar_test.dart` |
| `CHANGELOG.md`, `pubspec.yaml` | sửa | `[Unreleased]` + `scripts/bump_version.sh --minor` (thêm API) |

Ngoài phạm vi (để quyết định sau, xem mục 8): theme tối, hướng adaptive cho iOS, bộ icon Material trong app, rail trên tablet, nhãn mặc định tiếng Anh của FAB / Checkbox.

## 5. Các bước

### 5.0 Trước khi sửa

Chạy `impact` (upstream) cho `VPasswordField`, `VChip`, `VIconBox`, `VAppBar`, `VNumericKeypadGrid`, `VSwipeReveal`, `VBottomNavigationBar`, `VSkeleton`; ghi blast radius vào mục Review. Chú ý `VIconBox` (66 chỗ) và `VChip`: thay đổi bố cục chỉ áp dụng khi có `onTap` / `onRemove`.

Hằng dùng chung: `VSpacing.minTouchTarget` (44). Không tạo hằng mới.

### 5.1 (A) `VPasswordField`

```dart
return IconButton(
  onPressed: isEnabled ? _toggleObscured : null,
  icon: VIcon(icon: _obscured ? VIcons.visibility : VIcons.visibilityOff, iconColor: VIconColor.muted),
  tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints.tightFor(
    width: VSpacing.minTouchTarget,
    height: VSpacing.minTouchTarget,
  ),
);
```

Bỏ `visualDensity: compact` và `tapTargetSize: shrinkWrap`. Icon vẫn 24; ô nhập cao 44 (`comfortable`) nên không đổi chiều cao ô. Ở mật độ `compact` (ô 40) nút 44 sẽ đẩy ô cao lên 44 — chấp nhận (đúng chuẩn).

### 5.2 (B) `VChip` nút xoá

Phần vẽ giữ nguyên; `_RemoveButton` thành icon thuần (không bắt chạm, không semantics). Vùng chạm nằm ở lớp ngoài:

```dart
// trong build(), sau khi dựng chipBody (Container trang trí) và vDisabledOpacity
if (onRemove != null) {
  chipBody = ConstrainedBox(
    constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
    child: Stack(
      alignment: Alignment.centerLeft,
      children: [
        chipBody,
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: VSpacing.minTouchTarget,
          child: Semantics(
            button: true,
            enabled: isEnabled,
            label: 'Xoá $label',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isEnabled ? onRemove : null,
            ),
          ),
        ),
      ],
    ),
  );
}
```

```dart
// _RemoveButton: bỏ IconButton, chỉ vẽ icon
return ExcludeSemantics(
  child: SizedBox(
    width: extent,
    height: extent,
    child: Icon(Icons.close, size: iconSize, color: color),
  ),
);
```

Ghi chú:
- Vùng 44 ở đuôi phủ icon xoá và một đoạn cuối nhãn — giống `InputChip`. Nếu chip có cả `onTap` và `onRemove`, phần còn lại của chip vẫn là `onTap`.
- `Icons.close` (Material) → đổi sang `VIcon(icon: VIcons.close, …)` (đã có trong `VIcons`) cho đúng bộ icon Lucide.
- Chip có `onRemove` cao thêm (≈ 32 → 44 bố cục). Kiểm 7 chỗ app ở 6.3.

### 5.3 (C, D) `VIconBox` + mũi tên combobox

```dart
// v_icon_box.dart — field mới
/// Accessibility label; required in practice when [onTap] is set and there is no visible [label].
final String? semanticLabel;
```

```dart
if (onTap != null) {
  return vInspectorHide(
    Semantics(
      button: true,
      label: semanticLabel ?? trimmedLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: VSpacing.minTouchTarget,
          minHeight: VSpacing.minTouchTarget,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: InkWell(/* như cũ */ child: container),
        ),
      ),
    ),
  );
}
```

Khi `onTap != null` và cả `semanticLabel`, `label` đều rỗng: thêm `assert` trong debug (`'VIconBox with onTap needs semanticLabel'`) để bắt 5 chỗ app chưa có nhãn — sửa từng chỗ với nhãn tiếng Việt phù hợp.

`_TrailingChevron` (`v_combobox_input.dart`):

```dart
return VIconBox(
  …,
  semanticLabel: open ? 'Đóng danh sách' : 'Mở danh sách',
  onTap: enabled ? onTap : null,
);
```

### 5.4 (E) `VAppBar`

```dart
IconButton(
  tooltip: 'Quay lại',
  icon: VIcon(icon: VIcons.chevronLeft, color: dynamicColors.textPrimary),
  onPressed: () => Navigator.of(context).pop(),
)
```

### 5.5 (F) Bàn phím số

Trong `_Key.build`, bọc `VCard`:

```dart
return Semantics(
  button: true,
  label: switch (label) { '⌫' => 'Xoá', '.' => 'Dấu thập phân', _ => label },
  excludeSemantics: true,
  child: VCard(/* như cũ */),
);
```

### 5.6 (G, J) `VSwipeReveal`

```dart
/// One hidden swipe action, exposed to screen readers as a custom action.
class VSwipeSemanticAction {
  const VSwipeSemanticAction({required this.label, required this.onInvoke});
  final String label;
  final VoidCallback onInvoke;
}

// VSwipeReveal: tham số mới
final List<VSwipeSemanticAction> semanticActions; // mặc định const []
```

Trong `build`:

```dart
final hideActionsFromA11y = semanticActions.isNotEmpty && !_isOpen;

Positioned(
  right: 0, top: 0, bottom: 0,
  child: ExcludeSemantics(
    excluding: hideActionsFromA11y,
    child: vInspectorShow(widget.actionsBuilder(context, _close)),
  ),
),
…
child: Semantics(
  customSemanticsActions: {
    for (final a in widget.semanticActions)
      CustomSemanticsAction(label: a.label): a.onInvoke,
  },
  child: GestureDetector(/* như cũ */),
),
```

`_isOpen` là getter đọc `_controller.value` (dòng 47) nên `build` không tự chạy lại khi mở / đóng xong: bọc phần `ExcludeSemantics` trong `AnimatedBuilder(animation: _controller, …)` để cây semantics cập nhật.

Giảm chuyển động (J):

```dart
void _animateTo(double target) {
  if (MediaQuery.disableAnimationsOf(context)) {
    _controller.value = target;
  } else {
    _controller.animateTo(target);
  }
}
// _open() / _close() gọi _animateTo(1) / _animateTo(0)
```

Lưu ý `_close()` có thể được gọi trong `initState` (dòng 67): ở đó chưa đọc được `MediaQuery` → giữ `_controller.value = …` trực tiếp cho lần khởi tạo.

App (2 chỗ):

```dart
// sales_order_line_row.dart
semanticActions: [
  if (onDiscount != null) VSwipeSemanticAction(label: 'Chiết khấu', onInvoke: onDiscount!),
  if (onDelete != null) VSwipeSemanticAction(label: 'Xóa', onInvoke: onDelete!),
],
// sales_draft_list_card.dart
semanticActions: [VSwipeSemanticAction(label: 'Xóa', onInvoke: /* callback nút Xóa hiện có */)],
```

Giữ đúng điều kiện `enabled` của từng nút như `_actionSlot` đang làm.

### 5.7 (H) `VBottomNavigationBar`

```dart
padding: EdgeInsets.only(
  top: VSpacing.space1,
  bottom: bottomInset > 0 ? bottomInset : VSpacing.space3,
),
…
constraints: const BoxConstraints(minHeight: 48),
```

Nội dung tab (24 + 4 + 14 = 42) vẫn nằm trong 48.

### 5.8 (I) `VSkeleton`

Ở **cả hai** chỗ tạo controller (`_VSkeletonScopeState` dòng ~35-44 và `_VSkeletonState` dòng ~132-147, bản cục bộ khi không có scope), chuyển việc khởi động nhịp sang `didChangeDependencies` và xét cài đặt:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (MediaQuery.disableAnimationsOf(context)) {
    _controller.stop();
    _controller.value = 0.5; // opacity giữa 0.4–0.8, đứng yên
  } else if (!_controller.isAnimating) {
    _controller.repeat(reverse: true);
  }
}
```

(`initState` chỉ tạo controller, không gọi `repeat`.)

### 5.9 Tài liệu

1. `CHANGELOG.md` `[Unreleased]`:
   - *Added:* `VIconBox.semanticLabel`, `VSwipeReveal.semanticActions` + `VSwipeSemanticAction`.
   - *Fixed:* vùng chạm ≥ 44 cho nút mật khẩu, nút xoá chip, `VIconBox` có `onTap`; nhãn cho nút quay lại `VAppBar`, mũi tên combobox, bàn phím số; thanh dưới chừa đủ inset; skeleton và swipe tôn trọng giảm chuyển động.
2. `scripts/bump_version.sh --minor`.
3. PLAN.md: dòng 10-6.
4. Sau review: Claude cập nhật `DESIGN.md` (Components: chip có nút xoá, icon box chạm được, thanh dưới; Do's: "control chạm được ≥ 44 và có nhãn") và chạy lại `/impeccable audit` để so điểm.

## 6. Kiểm tra

### 6.1 Tự động
- [ ] `dart analyze lib test` (package) và `dart analyze lib/features/sales` (ERP): không lỗi mới.
- [ ] Test (dùng `tester.ensureSemantics()`, `tester.getSize`, `tester.getSemantics`, `meetsGuideline(androidTapTargetGuideline)` / `iOSTapTargetGuideline` / `labeledTapTargetGuideline` của `flutter_test`):
  - `VPasswordField`: nút ẩn / hiện ≥ 44×44; semantics label đổi theo trạng thái.
  - `VChip` có `onRemove`: chạm vào vùng 44 ở đuôi gọi `onRemove`, không gọi `onTap`; semantics có nút "Xoá <nhãn>"; chip không `onRemove` giữ kích thước cũ.
  - `VIconBox` có `onTap`: kích thước ≥ 44, `isButton`, label = `semanticLabel`.
  - `VSwipeReveal` có `semanticActions`: lúc đóng, không tìm thấy semantics của nút ẩn; thẻ có custom action "Xóa"; gọi action → callback chạy. Với `MediaQuery(data: MediaQueryData(disableAnimations: true))`: mở / đóng xong ngay sau 1 `pump()`.
  - `VSkeleton` với `disableAnimations: true`: `tester.hasRunningAnimations` là `false`.
  - `VBottomNavigationBar` với `MediaQueryData(padding: EdgeInsets.only(bottom: 34))`: khoảng cách đáy nội dung tới đáy thanh ≥ 34.
  - `VAppBar` có thể pop: nút quay lại có tooltip "Quay lại".
  - Một test gộp: `expectLater(tester, meetsGuideline(labeledTapTargetGuideline))` trên example `ComponentsPreviewTab` (nếu dựng được trong test) hoặc trên một màn ghép các component đã sửa.
- [ ] `flutter test` (package + `apps/erp/test/features/sales`): không lỗi mới.
- [ ] `detect_changes()` trước commit.

### 6.2 Example catalog
- [ ] Chip có nút xoá, icon box chạm được, swipe reveal, bàn phím số, thanh dưới hiển thị đúng; bật "Show semantics" (DevTools / `showSemanticsDebugger`) để soát nhãn.

### 6.3 Kiểm tay trên app (iPhone có thanh Home + Android cử chỉ)
- [ ] Đăng nhập / đăng ký / nhận lời mời: nút ẩn / hiện mật khẩu dễ bấm; VoiceOver đọc "Hiện mật khẩu, nút".
- [ ] Thanh dưới: nhãn nằm trên vùng thanh Home, vuốt về Home không chạm nhầm tab; chiều cao chấp nhận được.
- [ ] Lập đơn: dòng hàng — VoiceOver đọc tên sản phẩm, vuốt lên / xuống ra "Chiết khấu", "Xóa"; không còn dừng ở nút vô hình. Đơn nháp tương tự.
- [ ] Màn có chip lọc có nút xoá (7 chỗ): bố cục không vỡ khi chip cao thêm.
- [ ] Bật Giảm chuyển động (iOS: Trợ năng › Chuyển động; Android: Hỗ trợ tiếp cận › Xoá hiệu ứng động): skeleton đứng yên, swipe mở / đóng tức thì.

## 7. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| `VIconBox` / `VChip` cao thêm làm lệch bố cục ở màn đang dùng | Chỉ áp dụng khi có `onTap` / `onRemove`; kiểm 5 + 7 chỗ ở 6.3 |
| `assert` nhãn của `VIconBox` làm test / debug app đỏ ở chỗ chưa có nhãn | Đó là mục đích; sửa luôn các chỗ đó trong cùng plan (5 chỗ) |
| `ExcludeSemantics` + trạng thái mở / đóng không cập nhật đúng | Test "lúc đóng không thấy nút ẩn" và kiểm tay VoiceOver |
| Thanh dưới cao thêm ~6pt trên iPhone có thanh Home | Đã cân: 86pt so với 83pt của tab bar gốc |

## 8. Ngoài phạm vi (từ audit, chờ quyết định)

| Vấn đề | Mức | Ghi chú |
|---|---|---|
| Theme tối: màu trắng viết cứng (FAB, checkbox, `VSteps`, switch), tone tối < 4.5 | P2 | App khoá theme sáng; làm khi muốn bật theme tối |
| Hướng adaptive: switch / dialog / toast kiểu Material trên iOS, chevron quay lại trên Android | P2 | Cần chọn: sửa PRODUCT.md thành "Material cho cả hai" hay thêm nhánh `.adaptive` |
| 72 chỗ `Icons.*` trong app (kể cả 5 icon thanh dưới) thay vì `VIcons` | P2 | Có thể gom thành plan riêng hoặc `/impeccable extract` theo feature |
| Thanh dưới không chuyển thành rail trên tablet | P3 | Chỉ cần nếu tablet là thiết bị mục tiêu |
| `VButton.link` không có vùng chạm tối thiểu (~20px); field chưa có `autofillHints` / `textInputAction` | P1 / P2 | **Làm ở [2-B6](../P2/2-B6-ui-ux-auth.md)** (auth cần trước); 10-6 không làm lại |
| Nhãn mặc định tiếng Anh (`'Floating action'`, `'Checkbox'`, tên enum icon của `VButton.icon`) | P3 | App chưa dùng `VButton.icon`; FAB / Checkbox nên có nhãn bắt buộc |

## Review

### Lần 1 — 2026-10-13: đạt (còn kiểm tay)

Q1–Q4 làm theo đề xuất.

| Mục | Kết quả |
|---|---|
| A `VPasswordField` | `tightFor(44×44)`, bỏ `compact` / `shrinkWrap` ✅. Kèm sửa `VInput` (khoá chiều cao: bỏ padding dọc của hàng affix) để nút 44 nằm vừa ô 44 mà chữ không xê dịch — cần thiết, plan chưa lường; đã ghi CHANGELOG |
| B `VChip` | Khung `minHeight` 44 + `Stack`, vùng xoá 44×44 `Semantics(container, button, label: 'Xoá <label>')`; `_RemoveIcon` thuần vẽ, `ExcludeSemantics`, dùng `VIcons.close` ✅ |
| C `VIconBox` | `semanticLabel` + assert debug; `Semantics(button)` + vùng chạm ≥ 44, phần vẽ giữ `size`, `ExcludeSemantics` cho phần vẽ ✅ |
| D Combobox | `Mở danh sách` / `Đóng danh sách` ✅ |
| E `VAppBar` | `tooltip: 'Quay lại'` ✅ |
| F Bàn phím số | `Semantics(button, label, onTap, excludeSemantics)`; `⌫` → `Xoá`, `.` → `Dấu thập phân`; phím trống `ExcludeSemantics` (tốt hơn plan) ✅ |
| G, J `VSwipeReveal` | `VSwipeSemanticAction`, `semanticActions`; `ExcludeSemantics` trong `AnimatedBuilder` (cập nhật theo `_controller`); custom actions chỉ khi `enabled`; `_animateTo` xét `disableAnimations`; `initState` không gọi `MediaQuery` (đặt `value` trực tiếp) ✅ |
| H Thanh dưới | `top: space1`, `bottom: bottomInset` (≥ `space3`), `minHeight: 48` ✅ |
| I `VSkeleton` | `_applyMotionPreference` dùng chung cho scope và bản cục bộ, chạy ở `didChangeDependencies`; `initState` không `repeat()` ✅ |
| App | 5 chỗ `VIconBox(onTap)` đã có nhãn (Quay lại, Quét mã vạch ×2, Đóng, Lọc đơn hàng); nút quay lại màn lập đơn bỏ `Padding` để ô `leading` 56pt là vùng chạm. `semanticActions` ở 2 chỗ Sales ✅ |
| Test | `accessibility_guidelines_test` (≥ 44 + có tên), `v_icon_box`, `v_swipe_reveal`, `v_skeleton`, `v_app_bar`, `v_numeric_keypad_grid`; mở rộng chip, password, bottom nav ✅ |
| CHANGELOG / version | 1.7.0 ✅ |

Lệch so với plan — **đã kiểm, chấp nhận** (phần lớn là lỗi của plan):

| # | Lệch | Đánh giá |
|---|---|---|
| 1 | `VInput` khoá chiều cao bỏ padding dọc của hàng affix (plan không có) | Đúng: padding 8px ép nút 44 còn 28. Ô dense giữ nguyên. Hệ quả: mũi tên combobox rộng 44 thay vì 24 → vùng chữ hẹp đi 20px — kiểm ở 6.3 với nhãn dài |
| 2 | 11 chỗ `VIconBox(onTap)` trong app, plan ghi 5 | Plan đếm sai (grep `-A8` bỏ sót). Đã quét lại theo dấu ngoặc: đúng 11, **cả 11 có nhãn**; `modules/einvoice` có 3 `VIconBox` nhưng không chỗ nào có `onTap` |
| 3 | Bỏ `Padding(space2)` quanh nút quay lại ở `partner_create_page`, `pricing_form_page`, `sales_order_compose_page` | Đúng: `leadingWidth` 56 − padding = 40 < 44. Vùng chạm thành 56, hình vẽ vẫn giữa |
| 4 | `InkWell` đặt ngoài cùng thay vì `Center(InkWell(container))` như snippet 5.3 | **Plan sai**: snippet chỉ nới bố cục, vùng bấm thật vẫn 40. Cách đã làm đúng, có test chạm ở góc ngoài phần vẽ |
| 5 | Bàn phím số: thêm `onTap` tường minh trên `Semantics` | **Plan sai**: `excludeSemantics: true` xoá cả hành động chạm của con. Cách đã làm đúng |
| 6 | Test dùng `iOSTapTargetGuideline` + `labeledTapTargetGuideline`, không dùng `androidTapTargetGuideline` | **Plan mâu thuẫn**: mục tiêu 44 không đạt guideline Android 48. Chuẩn 48dp của Android vẫn là mục P3 ngoài phạm vi (mục 8) — nếu nâng `minTouchTarget` lên 48 thì bật lại guideline Android |
| 7 | Bỏ test guideline cho cả `VPasswordField`, thay bằng test kích thước + semantics của nút | Đúng: guideline bắt node `TextField` cao 22 (không phải nút), báo sai |

Góp ý nhỏ (không chặn):
- **Chính tả "Xoá" / "Xóa" lẫn nhau:** design system dùng `Xoá` (theo plan — lỗi của plan), còn app dùng `Xóa` (nút và `semanticActions` của Sales, TH-0X). Trình đọc màn hình đọc như nhau, nhưng nên thống nhất một kiểu khi có dịp; đề xuất theo chuỗi trong đặc tả (`Xóa`).

Chạy (chung cho 10-5 + 10-6, diff chưa commit, gồm cả 10-4):
- `flutter test` `packages/vet45_design_system`: **349 đạt**, 2 lỗi cũ `v_overlay_menu_shell_test.dart` (có từ trước 10-4, xem review 10-4).
- `flutter test` `apps/erp`: 1.405 đạt / **59 lỗi — cả 59 đều có trong `TEST-BASELINE.md`** (so tên test: 0 lỗi mới). Không test nào vướng assert nhãn của `VIconBox`.
- `dart analyze lib test example/lib` (design system): chỉ 1 warning + 2 info cũ; `dart analyze lib/features/sales`: không error / warning.
- `impact` / `detect_changes` (GitNexus): phiên review không có công cụ → **chưa chạy**; chạy `detect_changes()` trước commit.

Còn lại (bạn làm):
- [ ] 6.2 Example + Show semantics; 6.3 kiểm tay iPhone có thanh Home và Android cử chỉ (nhãn thanh dưới, chip có nút xoá ở 7 chỗ, VoiceOver ở dòng hàng lập đơn, Giảm chuyển động).
- [ ] Commit (gợi ý: `fix(design-system): touch targets, screen-reader labels, safe-area nav and reduced motion (10-6)`).

Đã cập nhật theo kết quả: `DESIGN.md` + `.impeccable/design.json`.
