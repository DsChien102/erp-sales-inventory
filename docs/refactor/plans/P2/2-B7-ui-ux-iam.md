# 2-B7 — Hoàn thiện UI/UX các màn IAM (người dùng, lời mời, vai trò, hồ sơ, tài khoản, lịch sử)

> Phase: P2 · Trạng thái: Plan ✅ (duyệt 2026-10-13) | Làm ⬜ | Review ⬜
> Độc lập với [2-B6](2-B6-ui-ux-auth.md) (khác file; cùng sửa design system ở file khác nhau). Làm trước hay sau đều được; ai làm sau thì bump version sau.
> Nguồn: `/impeccable audit apps/erp/lib/features/iam` (2026-10-13; đọc mã nguồn 11.470 dòng presentation + đối chiếu TH-01 mục 4 EP-06, 5.7–5.10, 5.12, BR-21). Điểm: **13/20** (Tiếp cận 2 · Hiệu năng 3 · Theme 3 · Chuẩn nền tảng 2 · Thích ứng 3).
> Tài liệu liên quan: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) US-06.1, US-06.2 (FR-01…06), 5.8 ID-14…18, BR-21; 10-6 (vùng chạm), [DESIGN.md](../../../../DESIGN.md).

## 1. Mục tiêu

Khu quản trị tổ chức (Owner dùng để demo "mời nhân viên") **khớp TH-01**, không có ô nhập chặn nghiệp vụ, dùng component design system thay cho bản tự dựng, và dùng được với VoiceOver / TalkBack. Không đổi luồng, RPC hay chuỗi đã chốt (trừ khi Q1 chọn khác).

## 2. Hiện trạng (đo 2026-10-13)

Quét toàn module: **0** `Semantics`, 6 `IconButton` thì 5 không `tooltip`, ~19 vùng chạm tự dựng bằng `GestureDetector` / `InkWell`, 30 `VToast` (9 lỗi). Không có `Icons.*` Material, không có `fontSize` viết cứng, màu gần như đều qua `context.vColors` — tốt.

### 2.1 Chặn nghiệp vụ / lệch đặc tả (P1)

| # | Vấn đề | Vị trí | Đặc tả |
|---|---|---|---|
| A | Ô **Mã số thuế** dùng `TextInputType.number`: bàn phím số của iPhone **không có dấu "-"** → không nhập được MST chi nhánh `0123456789-001` | `organization_profile/views/organization_legal_profile_form_page.dart:374-381` | BR-21 (10 số, 12 số, hoặc 10-3 có gạch) |
| B | Màn "Người dùng" **không có nút mời** trên app bar; chỉ có FAB tự dựng ở **tab Lời mời**. Ở tab Thành viên (tab mặc định) muốn mời phải đổi tab | `users/views/organization_users_page.dart:131-143`, `users/widgets/organization_users_body.dart:338-367` | 5.8 ID-14 wireframe: `←  Người dùng  [+]` |
| C | Thẻ thành viên **không có nhãn "Chủ sở hữu"** dù `MemberUiModel.isOwner` có sẵn | `users/widgets/member_card.dart` | US-06.1 FR-02; 5.8 wireframe `[Chủ sở hữu]` |
| D | Màn "Mời thành viên" chỉ có Email + Vai trò; đặc tả có thêm **Họ và tên đệm, Tên, Số điện thoại**. RPC `create_tenant_invitation` không nhận 3 trường này (bảng `tenant_invitations` và `accept_invitation` thì có) | `users/views/organization_invite_member_page.dart`; `data/invitation_repository.dart:79`; migration `20260916005` | US-06.2 FR-01 — **xem Q1** |

### 2.2 Tiếp cận (P1–P2)

| # | Vấn đề | Vị trí |
|---|---|---|
| E | 5 `IconButton` **không nhãn**: 4 nút quay lại tự dựng ở lịch sử quản trị (ghi đè `VAppBar` nên mất `tooltip: 'Quay lại'` của 10-6), 1 nút bộ lọc ở "Người dùng"; nút bộ lọc ở lịch sử là `InkWell` không nhãn | `audit_logs/views/audit_log_detail_page.dart:89, 112`, `audit_logs/widgets/audit_log_detail_body.dart:64`, `audit_logs/views/organization_audit_logs_page.dart:213, 245`, `users/widgets/organization_users_body.dart:228` |
| F | **Bộ lọc đang bật chỉ báo bằng màu** (viền / nền xanh) — trái 5.12 "Nhãn trạng thái có chữ, không chỉ màu" | `organization_users_body.dart:213-234`; lịch sử: không báo |
| G | Tab "Thành viên / Lời mời" tự dựng (`_TabButton` = `InkWell` + gạch chân): trình đọc không biết tab nào đang chọn | `organization_users_body.dart:373-410` |
| H | Chip lọc ("Tất cả / Hoạt động / Tạm ngừng"…) là `VChip(onTap)`: cao ~34 (< 44), không báo **đã chọn** cho trình đọc (chỉ đổi tone) | `organization_users_body.dart:412-433`; DS `primitives/v_chip.dart` (10-6 chỉ nới chip có `onRemove`) |
| I | Thẻ chạm được (`VCard(onTap)`: thẻ thành viên, lời mời, tổ chức…) không có vai trò **nút** trong semantics | DS `components/v_card.dart` |
| J | Nút chữ "Thử lại" / hành động trống làm bằng `GestureDetector` + `VText`: vùng chạm bằng dòng chữ (~22), không vai trò nút | `roles/views/organization_roles_page.dart:118`, `organizations/widgets/organization_empty_view.dart:147`, `audit_logs/widgets/audit_log_empty_view.dart:126` |
| K | Nút sao chép ở chi tiết nhật ký: `constraints: BoxConstraints()` + `compact` → vùng chạm ~26 | `audit_logs/widgets/audit_detail_row.dart:120-131` |

### 2.3 Trình bày / UX (P2)

| # | Vấn đề | Vị trí | Đặc tả |
|---|---|---|---|
| L | Mời thành viên: lỗi kiểm ("Vui lòng nhập email và chọn vai trò.") và lỗi máy chủ (email đã là thành viên — AC-01) **chỉ hiện toast**, ô Email không đỏ; ô dùng `VTextField` thay `VEmailField`; câu "Người nhận phải đăng nhập đúng email." lặp 2 lần (đoạn mở đầu + mô tả ô) | `organization_invite_member_page.dart:81-112, 224-247` | FR-06, AC-01 |
| M | **Không chặn rời màn khi có thay đổi chưa lưu** ở 3 form: sửa tài khoản, sửa hồ sơ tổ chức, hồ sơ pháp lý — bấm quay lại / vuốt là mất dữ liệu | `users/views/edit_my_account_page.dart`, `organization_profile/views/organization_edit_profile_page.dart`, `…/organization_legal_profile_form_page.dart` (không có `PopScope`) | — |
| N | Sửa tài khoản: xoá trống Họ / Tên thì nút "Lưu thay đổi" **tắt mà không nói vì sao** (không `VFieldError` cho 2 ô tên) | `edit_my_account_page.dart:195-198, 380-410` | FR (chuỗi "Vui lòng nhập họ và tên đệm" / "Vui lòng nhập tên") |
| O | FAB tự dựng (`Material` + `InkWell` + `Colors.white` viết cứng, không nhãn) thay vì `VFloatingActionButton` | `organization_users_body.dart:338-367` | — |

### 2.4 Trùng lặp / dọn (P3)

| # | Vấn đề | Vị trí |
|---|---|---|
| P | **File chết** `users/widgets/organization_users_widgets.dart` (363 dòng: `OrganizationUsersTab`, `OrganizationUsersFilterChip`, `OrganizationUsersEmptyState`, `OrganizationUsersMainContent`) — không file nào import | — |
| Q | 3 bản "thẻ hành động" giống hệt nhau (icon + tiêu đề + mô tả + chevron, biến thể nguy hiểm) — 2 bản `InkWell`, 1 bản `GestureDetector` | `member_detail_bottom_sheets.dart:13-70`, `member_lifecycle_actions.dart:90-159`, `organization_invitation_detail_page.dart:309-376` |
| R | Tiêu đề màn / nhóm (52 chỗ `headingH*`) không có `header` semantics | toàn module |
| T | Chính tả lệch: design system dùng "Xoá" (nhãn nút xoá chip `Xoá <nhãn>`, phím `⌫` đọc `Xoá` — từ 10-6), app và TH-0X dùng "Xóa" | DS `primitives/v_chip.dart`, `components/v_numeric_keypad_grid.dart` + test |
| S | Màu nhấn tự pha `colors.primary.withValues(alpha: 0.1)` / `colors.success.withValues(alpha: 0.1)` thay token có sẵn (`surfaceBrand`, `successBg`) | `organization_users_body.dart:216`, `select_organization_bottom_sheet.dart:213` |

### 2.5 Điểm tốt (giữ)

- Đặt lại mật khẩu (`reset_password_*`), sửa hồ sơ tổ chức, hồ sơ pháp lý: lỗi từng trường, `*`, quy tắc mật khẩu, `VVerificationCodeField` — **mẫu chuẩn**.
- Danh sách thành viên / lời mời: `ListView.separated` + tải thêm + `RefreshIndicator`; tiêu đề phụ "Đang tải thành viên" / "`n` thành viên" đúng FR-01; trạng thái trống / không kết quả / không quyền / lỗi đủ.
- Thao tác nguy hiểm (tạm ngừng, loại, thu hồi) đều có bước xác nhận; `STATE_CHANGED` báo "Dữ liệu đã thay đổi".
- Hồ sơ tổ chức / tài khoản có nút "Thao tác" và banner "Bổ sung hồ sơ pháp lý" đúng wireframe 5.7, 5.10; chọn tổ chức dùng nhóm radio (có trạng thái chọn).

## 3. Quyết định (đã chốt 2026-10-13)

**Chốt:** Q1 sửa TH-01 theo code · Q2 **bàn phím số + tự chèn gạch** (khác đề xuất ban đầu) · Q3 `+` trên app bar, bỏ FAB · Q4 làm trong 2-B7, tham số mới `isSelected` · Q5 `IamActionTile` trong IAM · Q6 hộp thoại "Bỏ thay đổi?" · Q7 thống nhất chính tả "Xóa" (mục T).


| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | (D) Màn mời thiếu Họ và tên đệm / Tên / SĐT so với FR-01 | **Sửa TH-01 cho khớp code** (bỏ 3 trường khỏi FR-01 và wireframe), giữ 2-B7 thuần UI. Nếu muốn có 3 trường (để điền sẵn form kích hoạt của nhân viên) thì cần đổi RPC + migration → tách plan DB riêng, không gộp vào đây |
| Q2 | (A) Kiểu bàn phím cho MST | ~~Bàn phím chữ + lọc `[0-9-]`~~ → **Chốt: bàn phím số + tự chèn gạch** (mục 5.1) |
| Q3 | (B, O) Nút mời | Thêm action `+` trên app bar (đúng wireframe, có ở cả 2 tab, `tooltip: 'Mời thành viên'`); **bỏ** FAB tự dựng (một lối vào, không trùng) |
| Q4 | (H, I) Sửa trong design system ngay trong plan này? | **Có**: `VChip(onTap)` nới vùng chạm 44 + tham số `selected` cho semantics; `VCard(onTap)` thêm `Semantics(button: true)`. Nhỏ, có lợi cho mọi module |
| Q6 | (M) Chuỗi hộp thoại rời form chưa lưu | "Bỏ thay đổi?" · "Các thay đổi chưa lưu sẽ bị mất." · "Tiếp tục sửa" / "Bỏ thay đổi" (đỏ); ghi bổ sung TH-01 |
| Q7 | (T) Chính tả "Xoá" (DS, 10-6) / "Xóa" (app, đặc tả) | Thống nhất **"Xóa"** theo đặc tả |
| Q5 | (Q) Gộp 3 thẻ hành động | Tạo **một** widget dùng chung trong `features/iam/presentation/shared/iam_action_tile.dart` (chưa đưa vào DS — chỉ IAM dùng) |

## 4. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| **Design system** (Q4) | | |
| `packages/vet45_design_system/lib/src/primitives/v_chip.dart` | sửa | `onTap` → khung bố cục ≥ 44 (như `onRemove`); thêm `bool? selected` → `Semantics(selected:)` |
| `…/components/v_card.dart` | sửa | `onTap != null` → `Semantics(button: true)` |
| `…/primitives/v_chip.dart`, `…/components/v_numeric_keypad_grid.dart` + `test/primitives/v_chip_test.dart`, `test/components/v_numeric_keypad_grid_test.dart` | sửa | "Xoá" → "Xóa" (T) |
| `CHANGELOG.md`, `pubspec.yaml` | sửa | `[Unreleased]` + bump minor |
| **IAM** | | |
| `organization_profile/views/organization_legal_profile_form_page.dart` | sửa | Bàn phím + formatter MST (A); `PopScope` (M) |
| `users/views/organization_users_page.dart` | sửa | Action `+` (B, Q3) |
| `users/widgets/organization_users_body.dart` | sửa | Bỏ FAB (O); `VTabs` / `VSegmentedControl` (G); chip `selected` (H); nút lọc có nhãn + chấm / số bộ lọc (E, F); token màu (S) |
| `users/widgets/member_card.dart` | sửa | Badge "Chủ sở hữu" (C) |
| `users/views/organization_invite_member_page.dart` + cubit | sửa | `VEmailField`, lỗi dưới ô, bỏ câu lặp (L) |
| `users/views/edit_my_account_page.dart` | sửa | Lỗi 2 ô tên (N); `PopScope` (M) |
| `organization_profile/views/organization_edit_profile_page.dart` | sửa | `PopScope` (M) |
| `audit_logs/views/audit_log_detail_page.dart`, `audit_logs/widgets/audit_log_detail_body.dart`, `audit_logs/views/organization_audit_logs_page.dart` | sửa | Bỏ `leading` tự dựng, dùng nút mặc định `VAppBar` (E); nút lọc có nhãn + chỉ báo (E, F) |
| `audit_logs/widgets/audit_detail_row.dart` | sửa | Vùng chạm nút sao chép 44 (K) |
| `roles/views/organization_roles_page.dart`, `organizations/widgets/organization_empty_view.dart`, `audit_logs/widgets/audit_log_empty_view.dart` | sửa | "Thử lại" / hành động → `VButton` (J) |
| `shared/iam_action_tile.dart` | tạo | Thẻ hành động dùng chung (Q, Q5) |
| `member_detail_bottom_sheets.dart`, `member_lifecycle_actions.dart`, `organization_invitation_detail_page.dart` | sửa | Dùng `IamActionTile` (Q) |
| `users/widgets/organization_users_widgets.dart` | xoá | File chết (P) |
| Các màn có tiêu đề | sửa | `Semantics(header: true)` cho tiêu đề màn và tiêu đề nhóm (R) |
| `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md` | sửa | Nếu Q1 = sửa đặc tả: US-06.2 FR-01 bỏ 3 trường; ghi chú phiên bản |
| Test (mục 6.1) | sửa / tạo | `apps/erp/test/features/iam/**`, `test/features/invitations/**`, DS `v_chip_test`, `v_card_test` |

## 5. Các bước

### 5.0 Trước khi sửa

`impact` (upstream) cho `VChip`, `VCard`, `OrganizationUsersBody`, `OrganizationUsersPage`, `MemberCard`, `OrganizationInviteMemberPage`, `OrganizationInviteMemberCubit`, `EditMyAccountPage`, `OrganizationLegalProfileFormPage`, `OrganizationEditProfilePage`, các trang audit log. `VCard` / `VChip` ra HIGH (cả app) — chỉ **thêm** semantics / vùng chạm cho biến thể có `onTap`.

### 5.1 (A) Mã số thuế — bàn phím số + tự chèn gạch (Q2)

Người dùng chỉ gõ **chữ số**; ô tự hiển thị dấu gạch khi đủ 13 số (dạng chi nhánh BR-21). 10 và 12 số giữ nguyên, không gạch — phân biệt được vì dạng chi nhánh luôn có đúng 13 chữ số.

```dart
/// Chữ số → MST hiển thị: ≤ 12 số giữ nguyên; 13 số → `XXXXXXXXXX-XXX`.
/// Dán `0123456789-001` (hoặc có khoảng trắng) cũng ra đúng dạng.
class TaxCodeInputFormatter extends TextInputFormatter {
  static const maxDigits = 13;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final text = digits.length == maxDigits
        ? '${digits.substring(0, 10)}-${digits.substring(10)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
```

```dart
VTextField(
  hintText: 'Nhập mã số thuế',
  controller: _taxCodeController,
  keyboardType: TextInputType.number,
  inputFormatters: [TaxCodeInputFormatter()],
  …
)
```

- Đặt formatter ở `apps/erp/lib/core/validation/tax_code_input_formatter.dart` (cạnh `password_policy.dart`); dùng lại cho mọi ô MST khác nếu có (`grep -rn "Mã số thuế" apps/erp/lib`).
- Con trỏ luôn về cuối (MST ngắn, sửa giữa chuỗi hiếm); xoá lùi từ `0123456789-001` → 12 số, gạch tự biến mất.
- Giá trị gửi lên giữ dấu gạch như hiện tại; kiểm BR-21 hiện có không đổi.
- `controller.text` ban đầu (MST đã lưu) đã có gạch → hiển thị đúng, không cần chuyển đổi.
- Thêm `VFieldDescription('10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.')` khi không lỗi (diễn giải BR-21; ghi bổ sung TH-01 nếu cần chuỗi chuẩn).

### 5.2 (B, O, Q3) Nút mời trên app bar

`OrganizationUsersPage.build`: `VPageScaffold(actions: [...])`:

```dart
IconButton(
  key: const Key('users_invite'),
  tooltip: 'Mời thành viên',
  icon: VIcon(icon: VIcons.add, color: context.vColors.textPrimary),
  onPressed: () => _navigateInvite(context),
),
```

Chỉ hiện khi người dùng có quyền mời (dùng cùng điều kiện đang ẩn / hiện FAB và trạng thái "không quyền" của FR-07). Xoá khối `Positioned(... Material(... InkWell ...))` ở `organization_users_body.dart:338-367` và tham số / callback chỉ phục vụ FAB nếu không còn dùng.

### 5.3 (C) Badge "Chủ sở hữu"

`member_card.dart`, sau tên:

```dart
Row(children: [
  Flexible(child: VText(member.name, …)),
  if (member.isOwner) ...[
    const VGap.horizontalXs(),
    const VBadge(label: 'Chủ sở hữu', tone: VComponentTone.primary, variant: VBadgeVariant.soft, isSmall: true),
  ],
]),
```


### 5.4 (G, H, F, E, S) Thanh tab, chip, nút lọc ở "Người dùng"

- Tab: thay 2 `_TabButton` bằng `VTabs` (hoặc `VSegmentedControl` nếu `VTabs` cần nội dung con) với 2 mục "Thành viên", "Lời mời"; giữ logic `selectTab` + đồng bộ `_searchController`. Xoá `_TabButton`.
- Chip: `_FilterChip` → `VChip(label:, tone:, isSelected: selected, onTap:)` (tham số mới, 5.7).
- Nút lọc:

```dart
Stack(clipBehavior: Clip.none, children: [
  IconButton(
    tooltip: isFilterActive ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc',
    icon: VIcon(icon: VIcons.tune, size: 20, color: colors.textPrimary),
    onPressed: () => _openFilterBottomSheet(context),
  ),
  if (isFilterActive)
    Positioned(top: 6, right: 6, child: ExcludeSemantics(child: Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
    ))),
]),
```

  Chấm là dấu hiệu hình dạng (không chỉ màu); nhãn nói rõ cho trình đọc. Áp dụng **cùng mẫu** cho nút lọc ở `organization_audit_logs_page.dart:245` (thay `InkWell`).
- Màu (S): `colors.primary.withValues(alpha: 0.1)` → `colors.surfaceBrand`; `colors.success.withValues(alpha: 0.1)` → `colors.successBg`.

### 5.5 (L) Mời thành viên

- Ô Email: `VEmailField(controller:, hintText:, onChanged:)`; `VField(invalid: state.emailError != null)` + `VFieldError(state.emailError)`.
- Cubit: tách lỗi kiểm thành `emailError` / `roleError` (giữ chuỗi FR-06 "Vui lòng nhập email và chọn vai trò." — hiện dưới ô còn thiếu; nếu thiếu cả hai thì dưới ô Email); lỗi máy chủ AC-01 (email đã là thành viên) → `emailError` với thông điệp từ mapper; lỗi khác vẫn toast.
- Kiểm định dạng email bằng `VEmailValidator` thay `contains('@')`.
- Bỏ đoạn mở đầu lặp "Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày." **hoặc** bỏ `VFieldDescription` trùng — giữ đúng một chỗ theo FR-01 ("ghi chú" chung của form): đề xuất giữ đoạn mở đầu, bỏ mô tả ô.

### 5.6 (M, N) Form sửa

`PopScope` dùng chung cho 3 form:

```dart
PopScope(
  canPop: !_hasChanges || _isSaving,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    await showVConfirmDialog(
      context: context,
      title: 'Bỏ thay đổi?',
      message: 'Các thay đổi chưa lưu sẽ bị mất.',
      cancelLabel: 'Tiếp tục sửa',
      actionLabel: 'Bỏ thay đổi',
      isDestructive: true,
      onAction: () {
        _hasChanges = false; // để lần pop này không bị chặn lại
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  },
  child: …,
)
```

(Chuỗi đã chốt (Q6). Chữ ký theo `v_modal.dart:96`. Kiểm `onAction` chạy trước hay sau khi hộp thoại tự đóng — nếu sau, `pop` ở trên đóng đúng trang. Ghi bổ sung chuỗi vào TH-01 mục 5.) Nút "Hủy" ở `bottomBar` đi qua cùng hộp thoại. `organization_edit_profile_page` / `legal_profile_form` cần cờ `_hasChanges` (so giá trị ban đầu) nếu chưa có.

Sửa tài khoản (N): validate khi bấm "Lưu thay đổi" và khi rời ô; hiện `VFieldError('Vui lòng nhập họ và tên đệm')` / `VFieldError('Vui lòng nhập tên')`; nút "Lưu" chỉ tắt khi **chưa có thay đổi** hoặc đang lưu, không tắt vì lỗi (lỗi phải nhìn thấy).

### 5.7 (H, I) Design system

`VChip`:

```dart
final bool? isSelected; // semantics only; visual still via tone
…
// nhánh interactive (onTap != null):
Semantics(button: true, selected: isSelected, enabled: isEnabled, label: semanticsLabel, child: ConstrainedBox(
  constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
  child: Center(heightFactor: 1, child: Material(... InkWell(...) ...)),
))
```

Lưu ý bài học 10-6: `InkWell` phải bọc **khung 44** (đặt `ConstrainedBox` bên trong `InkWell`, phần vẽ ở giữa) để vùng bấm thật là 44, không chỉ bố cục. **Chốt:** tham số mới `final bool? isSelected;` chỉ điều khiển semantics (`Semantics(selected: isSelected)`); `selected` cũ giữ `@Deprecated`, không đổi nghĩa. Ghi CHANGELOG.

`VCard`: khi `onTap != null`, bọc `Semantics(button: true, enabled: isEnabled)` quanh `InkWell` hiện có (không `excludeSemantics` — nội dung thẻ là nhãn).

### 5.8 (E, J, K) Nhãn và vùng chạm còn lại

- Lịch sử quản trị (4 chỗ): xoá `leading: IconButton(...)`, để `VAppBar(showBackButton: true)` tự dựng nút có `tooltip: 'Quay lại'`. Nếu cần `maybePop` thay `pop`, thêm `tooltip: 'Quay lại'` vào `IconButton` hiện có thay vì xoá.
- "Thử lại" / hành động trống (3 chỗ): `VButton(label: …, variant: VButtonVariant.tertiary)` (tone danger cho "Thử lại" ở lỗi vai trò nếu muốn giữ màu đỏ).
- Nút sao chép: bỏ `constraints: BoxConstraints()` và `compact`; `constraints: BoxConstraints.tightFor(width: 44, height: 44)`, `padding: EdgeInsets.zero`.

### 5.9 (Q, P, R) Dọn

- `shared/iam_action_tile.dart`: `IamActionTile({required VIcons icon, required String title, String? subtitle, required VoidCallback onTap, bool isDanger = false})` — bản `InkWell` của `member_lifecycle_actions.dart` làm gốc, thêm `Semantics(button: true)`. Thay ở 3 chỗ, xoá 3 class cũ.
- Xoá `organization_users_widgets.dart`.
- (T) `v_chip.dart`: `'Xoá $label'` → `'Xóa $label'`; `v_numeric_keypad_grid.dart`: `'⌫' => 'Xoá'` → `'Xóa'`; sửa chuỗi trong 2 test tương ứng và CHANGELOG (*Fixed*: thống nhất chính tả "Xóa").
- `Semantics(header: true, child: VText(...))` cho tiêu đề màn (tiêu đề trong body, không phải `VAppBar`) và tiêu đề nhóm ("THÔNG TIN TỔ CHỨC", "HỒ SƠ PHÁP LÝ", "Vai trò hệ thống"…). Có thể thêm helper nhỏ `IamSectionTitle` nếu lặp nhiều.

### 5.10 Tài liệu

1. CHANGELOG DS: *Added* `VChip.isSelected`; *Fixed* vùng chạm `VChip(onTap)`, semantics nút của `VCard(onTap)`.
2. TH-01: US-06.2 FR-01 bỏ "Họ và tên đệm", "Tên", "Số điện thoại" (Q1, giữ BR-40 phần "tuỳ chọn họ tên, SĐT" ghi chú là chưa dùng ở app); thêm chuỗi hộp thoại "Bỏ thay đổi?" (Q6) vào mục 5; mô tả ô MST (5.1); ghi dòng phiên bản.
3. PLAN.md: dòng 2-B7. CHECKLIST.md P2 — TH-01: tick lại ID-11…ID-21 sau kiểm tay.
4. Sau review: Claude cập nhật `DESIGN.md` (chip chọn được, thẻ chạm được, mẫu nút lọc có chỉ báo).

## 6. Kiểm tra

### 6.1 Tự động
- [ ] `dart analyze lib test` (`apps/erp`, DS): không lỗi mới.
- [ ] DS: `v_chip_test` — chip `onTap` cao ≥ 44, vùng bấm ở mép trên / dưới vẫn gọi `onTap`, semantics `isSelected`; `v_card_test` — `onTap` → `isButton`.
- [ ] `tax_code_input_formatter_test`: gõ 10 / 12 số → không gạch; 13 số → `0123456789-001`; dán `0123456789-001` / `0123 456 789 001` → `0123456789-001`; quá 13 số bị cắt; xoá lùi bỏ gạch.
- [ ] `organization_legal_profile_form` test: ô MST dùng `TextInputType.number`, nhập 13 số lưu ra có gạch.
- [ ] `organization_users_page` test: có nút "Mời thành viên" ở cả 2 tab, không còn FAB; tab đang chọn có `isSelected`; chip "Hoạt động" chọn → `isSelected`; nút lọc có tooltip đổi theo trạng thái.
- [ ] `member_card` test: `isOwner` → badge "Chủ sở hữu".
- [ ] Mời thành viên: trống → lỗi dưới ô (không toast); email đã là thành viên → lỗi dưới ô Email.
- [ ] 3 form: sửa rồi bấm quay lại → hộp thoại "Bỏ thay đổi?"; chưa sửa → rời ngay.
- [ ] Sửa tài khoản: xoá tên → bấm Lưu → hiện "Vui lòng nhập tên".
- [ ] `meetsGuideline(iOSTapTargetGuideline)` + `labeledTapTargetGuideline` cho: Người dùng (2 tab), Lịch sử quản trị, Chi tiết thành viên, Vai trò.
- [ ] `flutter test apps/erp`: không lỗi ngoài `TEST-BASELINE.md`.
- [ ] `detect_changes()` trước commit.

### 6.2 Kiểm tay (iPhone + Android)
- [ ] Hồ sơ pháp lý trên **iPhone**: nhập MST chi nhánh có gạch, lưu được.
- [ ] Người dùng: `+` mời ở tab Thành viên; Owner có nhãn "Chủ sở hữu"; VoiceOver đọc "Thành viên, tab, đã chọn", "Hoạt động, đã chọn", "Bộ lọc (đang áp dụng)".
- [ ] Mời email đã là thành viên → chữ đỏ dưới ô Email.
- [ ] Sửa tài khoản / hồ sơ: vuốt quay lại khi đang sửa → hỏi bỏ thay đổi.
- [ ] Lịch sử quản trị: nút quay lại đọc "Quay lại"; nút sao chép dễ bấm.

## 7. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| `VChip(onTap)` cao 44 đẩy hàng chip lọc ở các module khác (catalog, partner, pricing, sales) | Đây là yêu cầu chuẩn; kiểm nhanh các màn có hàng chip; giảm `vertical` padding của hàng nếu cần |
| `VCard` thêm `Semantics(button)` làm test semantics cũ ở module khác lệch | Chỉ thêm cờ, không đổi nhãn; chạy toàn bộ test app |
| Bỏ FAB làm lệch test cũ tìm FAB | Cập nhật test trong cùng plan |
| `PopScope` chặn nhầm sau khi lưu thành công | Đặt `_hasChanges = false` trước khi `pop` sau lưu |

## Review

_(Claude ghi sau khi bạn làm xong.)_
