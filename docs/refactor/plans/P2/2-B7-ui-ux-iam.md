# 2-B7 — Hoàn thiện UI/UX các màn IAM (người dùng, lời mời, vai trò, hồ sơ, tài khoản, lịch sử)

> Phase: P2 · Trạng thái: Plan ✅ (duyệt 2026-10-13; rà lại theo code + chốt Q8–Q12 2026-10-27) | Làm ✅ | Review ✅ R3 2026-10-27 — R3-1 xong 2026-10-28 (dòng CHANGELOG `VInput`); kiểm tay (R3-2 + mục 6.2) gộp vào lượt người dùng test Theme 1
> Làm sau [2-B6](2-B6-ui-ux-auth.md) (2-B6 đã làm, chưa commit). Hai plan khác file, trừ `CHANGELOG.md` của design system (cùng ghi vào `[Unreleased]`).
> Nguồn: `/impeccable audit apps/erp/lib/features/iam` (2026-10-13; đọc mã nguồn 11.470 dòng presentation + đối chiếu TH-01 mục 4 EP-06, 5.7–5.10, 5.12, BR-21). Điểm: **13/20** (Tiếp cận 2 · Hiệu năng 3 · Theme 3 · Chuẩn nền tảng 2 · Thích ứng 3).
> Tài liệu liên quan: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) US-06.1, US-06.2 (FR-01…06), 5.8 ID-14…18, BR-21; 10-6 (vùng chạm), [DESIGN.md](../../../../DESIGN.md).

> **Rà lại theo code 2026-10-27 (phiên plan / review): plan vẫn đúng, giao làm được.**
> - Vấn đề A–T **còn nguyên** (đã grep): MST `TextInputType.number` (`organization_legal_profile_form_page.dart:377`), `_TabButton` (`organization_users_body.dart:247`), file chết `organization_users_widgets.dart`, 0 `Semantics`, không `PopScope`, DS còn "Xoá" (`v_chip.dart:163`, `v_numeric_keypad_grid.dart:116`). Số dòng có lệch; tìm theo nội dung.
> - **`VChip` đã có tham số `selected` bị `@Deprecated` ("dùng `tone: primary`")** — Q4 thêm tham số **mới `isSelected`**: **chỉ** điều khiển `Semantics(selected:)`; màu vẫn do `tone` người gọi truyền (như 5.4, 5.7); không dùng lại `selected` cũ.
> - TH-01 **chưa sửa** theo Q1 (FR-01 US-06.2 vẫn có "Họ và tên đệm", "Tên", "Số điện thoại") và Q6 (chuỗi "Bỏ thay đổi?") — hai việc tài liệu này vẫn thuộc plan.
> - Design system: ghi vào `[Unreleased]` đang có (10-7.2 + 2-B6). **Không bump `pubspec.yaml`** — chốt ở 2-B6 R1-10: bump một lần khi phát hành.
> - **Web:** như 2-B6 — sửa UI chung; bố cục web (danh sách – chi tiết, bảng) để W-2.

> **Rà lại lần 2 theo code 2026-10-27 (phiên plan / review) — đã sửa trong plan, phiên làm code chỉ cần làm theo các mục 4–6:**
> - **Q8 (mới):** `VAppBar` nút ← mặc định gọi `Navigator.of(context).pop()` (`v_app_bar.dart:85`) — `pop` **đi vòng qua `PopScope`** ⇒ hộp thoại "Bỏ thay đổi?" (M) không hiện khi bấm ←. Chốt: đổi sang `maybePop()` (5.6).
> - Nút "Hủy" của 3 form cũng gọi `Navigator.of(context).pop()` ⇒ phải đổi `maybePop()` mới qua hộp thoại (5.6). Mẫu cũ `_hasChanges = false` trong `onAction` **bỏ**: ở `edit_my_account_page` `_hasChanges` là getter (không gán được), và `Navigator.pop()` trực tiếp vốn không bị `PopScope` chặn.
> - iPhone: `PopScope(canPop: false)` **tắt cử chỉ vuốt quay lại** (không hiện hộp thoại) — hành vi của Flutter, chấp nhận; hộp thoại hiện khi bấm ← / "Hủy" / nút back Android. Web: nút back của trình duyệt không qua `PopScope` — chấp nhận, ghi ở 6.2.
> - **Q9 (mới):** code **không có** điều kiện quyền cho FAB mời (luôn hiện ở tab Lời mời) và route `/more/users/invite` không kiểm quyền. Chốt: ẩn mọi lối vào "mời" khi thiếu `IamPermissions.memberInvite` (5.2).
> - **Q10 (mới):** email sai định dạng ở màn mời báo **"Email không hợp lệ"** (5.5); ghi bổ sung TH-01.
> - **Q11 (mới):** formatter MST dùng cho **cả 4 ô MST** của app (IAM + khách hàng + đối tác), không chỉ IAM (5.1).
> - Lịch sử quản trị: 4 nút ← tự dựng dùng `maybePop` + callback `onBackPressed` (test dùng) ⇒ **giữ** `IconButton`, chỉ thêm `tooltip` (5.8) — không xoá `leading`.
> - Cubit / state màn mời nằm ở `apps/erp/lib/features/iam/logic/` (file trong `presentation/users/bloc/` chỉ `export`).
> - `VTabsTrigger` đã có `Semantics(button, selected)` ⇒ G dùng `VTabs` (bỏ phương án `VSegmentedControl`).
> - Q7: TH-0X **dùng cả hai** cách viết (43 "Xoá" / 31 "Xóa"), app catalog / inventory cũng có "Xoá". Giữ Q7 nhưng **chỉ** 2 chuỗi design system; không sửa app / đặc tả ở plan này.


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

**Chốt:** Q1 sửa TH-01 theo code · Q2 **bàn phím số + tự chèn gạch** (khác đề xuất ban đầu) · Q3 `+` trên app bar, bỏ FAB · Q4 làm trong 2-B7, tham số mới `isSelected` · Q5 `IamActionTile` trong IAM · Q6 hộp thoại "Bỏ thay đổi?" · Q7 thống nhất chính tả "Xóa" (mục T, chỉ design system) · **2026-10-27:** Q8 `VAppBar` → `maybePop` · Q9 ẩn nút mời theo quyền · Q10 "Email không hợp lệ" · Q11 formatter MST cho cả 4 ô.


| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | (D) Màn mời thiếu Họ và tên đệm / Tên / SĐT so với FR-01 | **Sửa TH-01 cho khớp code** (bỏ 3 trường khỏi FR-01 và wireframe), giữ 2-B7 thuần UI. Nếu muốn có 3 trường (để điền sẵn form kích hoạt của nhân viên) thì cần đổi RPC + migration → tách plan DB riêng, không gộp vào đây |
| Q2 | (A) Kiểu bàn phím cho MST | ~~Bàn phím chữ + lọc `[0-9-]`~~ → **Chốt: bàn phím số + tự chèn gạch** (mục 5.1) |
| Q3 | (B, O) Nút mời | Thêm action `+` trên app bar (đúng wireframe, có ở cả 2 tab, `tooltip: 'Mời thành viên'`); **bỏ** FAB tự dựng (một lối vào, không trùng) |
| Q4 | (H, I) Sửa trong design system ngay trong plan này? | **Có**: `VChip(onTap)` nới vùng chạm 44 + tham số **mới `isSelected`** cho semantics (`selected` cũ giữ `@Deprecated`); `VCard(onTap)` thêm `Semantics(button: true)`. Nhỏ, có lợi cho mọi module |
| Q6 | (M) Chuỗi hộp thoại rời form chưa lưu | "Bỏ thay đổi?" · "Các thay đổi chưa lưu sẽ bị mất." · "Tiếp tục sửa" / "Bỏ thay đổi" (đỏ); ghi bổ sung TH-01 |
| Q7 | (T) Chính tả "Xoá" (DS, 10-6) / "Xóa" (app, đặc tả) | Thống nhất **"Xóa"** theo đặc tả |
| Q5 | (Q) Gộp 3 thẻ hành động | Tạo **một** widget dùng chung trong `features/iam/presentation/shared/iam_action_tile.dart` (chưa đưa vào DS — chỉ IAM dùng) |
| Q8 | (M) Nút ← của `VAppBar` gọi `pop()` nên đi vòng `PopScope` | **Chốt 2026-10-27:** `VAppBar` dùng `Navigator.of(context).maybePop()` (như `BackButton` của Flutter). Cả app; chỉ khác ở màn có `PopScope` |
| Q9 | (B) Ai thấy nút mời | **Chốt 2026-10-27:** ẩn theo quyền `IamPermissions.memberInvite` (`tenant.member.invite`) — nút `+`, nút mời ở 2 trạng thái trống |
| Q10 | (L) Email sai định dạng ở màn mời | **Chốt 2026-10-27:** "Email không hợp lệ" (như FR-03 đăng ký); thiếu email / thiếu vai trò vẫn "Vui lòng nhập email và chọn vai trò." |
| Q11 | (A) Phạm vi formatter MST | **Chốt 2026-10-27:** cả 4 ô MST trong app ngay ở 2-B7 |
| Q12 | (L) Nút "Gửi lời mời" đang tắt khi email trống / chưa chọn vai trò ⇒ lỗi FR-06 không bao giờ hiện | **Chốt 2026-10-27 (review R1):** nút **luôn bật** (`canSubmit = !state.isSubmitting`), bấm khi thiếu → lỗi dưới ô — cùng quy tắc với N và 2-B6 |

## 4. Thay đổi

Đường dẫn IAM viết tắt: `…/` = `apps/erp/lib/features/iam/presentation/`. Mỗi dòng ghi mục (chữ cái) và bước (5.x) tương ứng.

| File | Hành động | Nội dung |
|---|---|---|
| **Design system** (`packages/vet45_design_system/`) | | |
| `lib/src/primitives/v_chip.dart` | sửa | `onTap` → vùng chạm ≥ 44; tham số mới `bool? isSelected` → `Semantics(selected:)`; `'Xoá $label'` → `'Xóa $label'` (H, T · 5.7, 5.9) |
| `lib/src/components/v_card.dart` | sửa | `onTap != null` → `Semantics(button: true)` (I · 5.7) |
| `lib/src/components/v_app_bar.dart` | sửa | Nút ← mặc định: `Navigator.of(context).maybePop()` thay `pop()` (M, Q8 · 5.6) |
| `lib/src/components/v_numeric_keypad_grid.dart` | sửa | `'⌫' => 'Xoá'` → `'Xóa'` (T · 5.9) |
| `test/primitives/v_chip_test.dart`, `test/components/v_card_test.dart`, `test/components/v_app_bar_test.dart`, `test/components/v_numeric_keypad_grid_test.dart` | sửa | Test mục 6.1 |
| `CHANGELOG.md` | sửa | Ghi vào `[Unreleased]` (5.10). **Không** sửa `pubspec.yaml` |
| **Dùng chung** | | |
| `apps/erp/lib/core/validation/tax_code_input_formatter.dart` | tạo | `TaxCodeInputFormatter` (A, Q11 · 5.1) |
| `apps/erp/test/core/validation/tax_code_input_formatter_test.dart` | tạo | 6.1 |
| `apps/erp/lib/core/router/app_router.dart` | sửa | Route `/more/users`: truyền `canInvite: _hasTenantPermission(IamPermissions.memberInvite)` (Q9 · 5.2) |
| **Ô MST ngoài IAM** (Q11 · 5.1) | | |
| `apps/erp/lib/features/partner/presentation/widgets/partner_invoice_section.dart` | sửa | Ô `input_tax_code`: `TextInputType.number` + `TaxCodeInputFormatter()` thay 2 formatter cũ |
| `apps/erp/lib/features/partner/presentation/widgets/partner_transform_organization_form.dart` | sửa | Ô `transform_tax_code`: như trên |
| `apps/erp/lib/features/sales/presentation/widgets/sales_customer_quick_create_sheet.dart` | sửa | Ô "Mã số thuế": thêm `keyboardType: TextInputType.number`, `inputFormatters: [TaxCodeInputFormatter()]` |
| **IAM** | | |
| `…/organization_profile/views/organization_legal_profile_form_page.dart` | sửa | Formatter MST + mô tả (A · 5.1); cờ thay đổi + `PopScope` + "Hủy" `maybePop` (M · 5.6); header (R) |
| `…/organization_profile/views/organization_edit_profile_page.dart` | sửa | Cờ thay đổi + `PopScope` + "Hủy" `maybePop` (M · 5.6) |
| `…/users/views/edit_my_account_page.dart` | sửa | Lỗi 2 ô tên, nút Lưu (N · 5.6); `PopScope` trong `_EditFormScaffold` + "Hủy" `maybePop` (M · 5.6); header (R) |
| `…/users/views/organization_users_page.dart` | sửa | Tham số `canInvite`; action `+` (B, Q3, Q9 · 5.2) |
| `…/users/widgets/organization_users_body.dart` | sửa | Bỏ FAB (O · 5.2); truyền `canInvite` xuống 2 section; `VTabs` (G · 5.4); chip `isSelected` (H · 5.4); nút lọc có nhãn + chấm (E, F · 5.4); token màu (S · 5.4); xoá `_TabButton` |
| `…/users/widgets/member_list_section.dart`, `…/users/widgets/invitation_list_section.dart`, `…/users/widgets/users_empty_state.dart` | sửa | Nút mời ở trạng thái trống chỉ hiện khi `canInvite`; `UsersEmptyState.onAction` nullable (Q9 · 5.2) |
| `…/users/widgets/member_card.dart` | sửa | Badge "Chủ sở hữu" (C · 5.3) |
| `…/users/views/organization_invite_member_page.dart` | sửa | `VEmailField`, lỗi dưới ô Email / Vai trò, `*` cho Vai trò, bỏ câu lặp, chỉ toast lỗi khác (L · 5.5) |
| `apps/erp/lib/features/iam/logic/organization_invite_member_cubit.dart`, `…/logic/organization_invite_member_state.dart` | sửa | `emailError` / `roleError` (L, Q10 · 5.5) |
| `…/select_organization_bottom_sheet.dart` (`…/organizations/widgets/`) | sửa | Token màu (S · 5.4) |
| `…/audit_logs/views/audit_log_detail_page.dart`, `…/audit_logs/widgets/audit_log_detail_body.dart`, `…/audit_logs/views/organization_audit_logs_page.dart` | sửa | `tooltip: 'Quay lại'` cho 4 nút ← (E · 5.8); nút lọc lịch sử theo mẫu 5.4 (E, F) |
| `…/audit_logs/widgets/audit_detail_row.dart` | sửa | Vùng chạm nút sao chép 44 (K · 5.8) |
| `…/roles/views/organization_roles_page.dart`, `…/organizations/widgets/organization_empty_view.dart`, `…/audit_logs/widgets/audit_log_empty_view.dart` | sửa | "Thử lại" / hành động → `VButton` (J · 5.8) |
| `…/shared/iam_action_tile.dart` | tạo | Thẻ hành động dùng chung (Q, Q5 · 5.9) |
| `…/users/widgets/member_detail_bottom_sheets.dart` (`MemberDetailOptionItem`), `…/users/widgets/member_lifecycle_actions.dart` (`_LifecycleActionItem`), `…/users/views/organization_invitation_detail_page.dart` (`_ActionItem`) | sửa | Dùng `IamActionTile`, xoá 3 class cũ (Q · 5.9) |
| `…/users/widgets/organization_users_widgets.dart` | xoá | File chết (P) |
| 32 tệp có `VTextVariant.headingH*` (danh sách ở 5.9) | sửa | `Semantics(header: true)` (R · 5.9) |
| **Tài liệu** | | |
| `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md` | sửa | 5.10 mục 2 |
| `docs/refactor/PLAN.md`, `DESIGN.md` | sửa | 5.10 mục 3–4 |
| **Test app** | sửa / tạo | `apps/erp/test/features/iam/**`, `apps/erp/test/features/partner/**`, `apps/erp/test/features/sales/presentation_module/widgets/sales_customer_quick_create_sheet_test.dart` — mục 6.1 |

## 5. Các bước

### 5.0 Trước khi sửa

`impact` (upstream) cho `VChip`, `VCard`, `VAppBar`, `UsersEmptyState`, `OrganizationUsersBody`, `OrganizationUsersPage`, `MemberListSection`, `InvitationListSection`, `MemberCard`, `OrganizationInviteMemberPage`, `OrganizationInviteMemberCubit`, `OrganizationInviteMemberState`, `EditMyAccountPage`, `OrganizationLegalProfileFormPage`, `OrganizationEditProfilePage`, `PartnerInvoiceSection`, `PartnerTransformOrganizationForm`, `SalesCustomerQuickCreateSheet`, các trang audit log; ghi vào mục Review. `VCard` / `VChip` / `VAppBar` ra HIGH (cả app) — báo người dùng; thay đổi chỉ là **thêm** semantics / vùng chạm cho biến thể có `onTap`, và `pop` → `maybePop` (Q8, đã chốt).

### 5.1 (A, Q11) Mã số thuế — bàn phím số + tự chèn gạch (Q2)

Người dùng chỉ gõ **chữ số**; ô tự hiển thị dấu gạch khi đủ 13 số (dạng chi nhánh BR-21). 10 và 12 số giữ nguyên, không gạch — phân biệt được vì dạng chi nhánh luôn có đúng 13 chữ số.

Tạo `apps/erp/lib/core/validation/tax_code_input_formatter.dart` (cạnh `tax_code.dart`):

```dart
import 'package:flutter/services.dart';

/// Chữ số → MST hiển thị: ≤ 12 số giữ nguyên; 13 số → `XXXXXXXXXX-XXX` (BR-21).
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

Áp dụng **đúng 4 ô** sau, mỗi ô: `keyboardType: TextInputType.number`, `inputFormatters: [TaxCodeInputFormatter()]` (thay toàn bộ formatter cũ của ô đó). Không đổi hint, nhãn, validate, `onChanged`:

| Ô | Tệp | Hiện tại | Ghi chú |
|---|---|---|---|
| Hồ sơ pháp lý | `…/organization_profile/views/organization_legal_profile_form_page.dart` (`VTextField` dưới `VFieldLabel('Mã số thuế', isRequired: true)`) | `TextInputType.number`, không formatter | Thêm `VFieldDescription('10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.')` khi `_taxCodeError == null` |
| Đối tác — hóa đơn | `apps/erp/lib/features/partner/presentation/widgets/partner_invoice_section.dart` (key `input_tax_code`) | `numberWithOptions(signed: true)` + `FilteringTextInputFormatter.allow([0-9-])` + `LengthLimitingTextInputFormatter(14)` | Bỏ 2 formatter cũ |
| Đối tác — chuyển thành tổ chức | `apps/erp/lib/features/partner/presentation/widgets/partner_transform_organization_form.dart` (key `transform_tax_code`) | như trên | Bỏ 2 formatter cũ |
| Khách hàng — tạo nhanh | `apps/erp/lib/features/sales/presentation/widgets/sales_customer_quick_create_sheet.dart` (`VTextField` dưới `VFieldLabel('Mã số thuế')`) | bàn phím chữ, không formatter | Chỉ thêm 2 tham số |

- Con trỏ luôn về cuối (MST ngắn, sửa giữa chuỗi hiếm); xoá lùi từ `0123456789-001` → `012345678900` (12 số), gạch tự biến mất.
- Giá trị gửi lên giữ dấu gạch như hiện tại; `isValidTaxCode` (`core/validation/tax_code.dart`) không đổi.
- Giá trị ban đầu đã lưu (`0123456789-001`): formatter chỉ chạy khi gõ, `controller.text` / `initialValue` hiển thị nguyên — không cần chuyển đổi.
- Hai ô đối tác dùng `initialValue` (không controller): formatter vẫn chạy bình thường qua `inputFormatters`.

### 5.2 (B, O, Q3, Q9) Nút mời trên app bar, theo quyền

1. `app_router.dart`, route `/more/users` (đang trả `OrganizationUsersPage(members:, invitations:)`): thêm `canInvite: _hasTenantPermission(IamPermissions.memberInvite),`.
2. `OrganizationUsersPage`: thêm `final bool canInvite;` (mặc định `true` — test cũ không đổi), truyền xuống `OrganizationUsersBody(canInvite: canInvite, …)`. Trong `VPageScaffold(actions: [...])`:

```dart
if (canInvite)
  IconButton(
    key: const Key('users_invite'),
    tooltip: 'Mời thành viên',
    icon: VIcon(icon: VIcons.add, color: context.vColors.textPrimary),
    onPressed: () => _navigateInvite(context),
  ),
```

3. `OrganizationUsersBody`: thêm `final bool canInvite;`; **xoá** khối FAB `if (!isMemberTab) Positioned(... Material(... InkWell(onTap: widget.onInviteTap ...)))`. Giữ `onInviteTap` (còn dùng ở 2 section). Truyền `canInvite` vào `MemberListSection` và `InvitationListSection`.
4. `users_empty_state.dart`: `onAction` đổi thành `final VoidCallback? onAction;` (bỏ `required`); khi `onAction == null` **không** dựng `VGap.lg()` + `VButton` (12 chỗ gọi khác vẫn truyền hàm ⇒ không đổi). `member_list_section.dart`, `invitation_list_section.dart`: thêm `final bool canInvite;` (mặc định `true`); `UsersEmptyState(… actionText: 'Mời thành viên', onAction: canInvite ? onInviteTap : null)`.
5. Route `/more/users/invite` **không** thêm chặn (RPC vẫn chặn `PERMISSION_DENIED`); chỉ ẩn lối vào.

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

- Tab: thay `Row` 2 `_TabButton` bằng (không dùng `VTabsContent` — nội dung vẫn đổi theo `state.activeTab` như hiện tại):

```dart
VTabs(
  key: const Key('users_tabs'),
  selectedIndex: state.activeTab == OrganizationUsersTab.members ? 0 : 1,
  onTabSelected: (i) => /* gọi đúng logic onTap của 2 _TabButton cũ: selectTab(...) + đồng bộ _searchController */,
  semanticLabel: 'Người dùng',
  child: VTabsList(children: const [
    VTabsTrigger(label: 'Thành viên'),
    VTabsTrigger(label: 'Lời mời'),
  ]),
)
```

  Xoá class `_TabButton`. `VTabsTrigger` đã có `Semantics(button, selected)`. Nếu test guideline (6.1) báo trigger cao < 44 thì thêm `constraints: BoxConstraints(minHeight: VSpacing.minTouchTarget)` cho `Container` của `VTabsTrigger` (`v_tabs.dart`, khối `InkWell → Container(padding: …)`) và ghi CHANGELOG *Fixed*.
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

  Thay khối nút lọc hiện tại (`Container` viền / nền đổi màu theo `isFilterActive` bọc `IconButton`, ~`organization_users_body.dart:213-234`) bằng đoạn trên — **bỏ** viền / nền đổi màu. `isFilterActive` giữ nguyên cách tính hiện có. Chấm là dấu hiệu hình dạng (không chỉ màu); nhãn nói rõ cho trình đọc.
- Nút lọc lịch sử (`organization_audit_logs_page.dart`, `InkWell` 44×44 viền `borderDefault`, `onTap: () => _openFilterBottomSheet(context, state)`): thay bằng **cùng mẫu**, với `final isFilterActive = state.filters.result != null || _resolveTimeRange(state.filters) != '30 ngày';` (mặc định của cubit là `TenantAuditFilter.last30Days`; sheet lọc chỉ đổi `result` và khoảng thời gian; chip danh mục không tính).
- Màu (S): `organization_users_body.dart` `colors.primary.withValues(alpha: 0.1)` → bỏ cùng khối nút lọc ở trên; `select_organization_bottom_sheet.dart` `colors.success.withValues(alpha: 0.1)` → `colors.successBg`.

### 5.5 (L, Q10) Mời thành viên

**State** (`apps/erp/lib/features/iam/logic/organization_invite_member_state.dart`): thêm `final String? emailError;`, `final String? roleError;` + `copyWith(emailError:, roleError:, clearFieldErrors: false)`.

**Cubit** (`…/logic/organization_invite_member_cubit.dart`), `submit()` — thay khối `if (email.isEmpty || !email.contains('@') || roleId == null)`:

| Điều kiện | `emailError` | `roleError` |
|---|---|---|
| email trống, chưa chọn vai trò | "Vui lòng nhập email và chọn vai trò." | `null` |
| email trống, đã chọn vai trò | "Vui lòng nhập email và chọn vai trò." | `null` |
| email có, sai định dạng (`!VEmailValidator.isValid(email)`) | "Email không hợp lệ" | "Vui lòng nhập email và chọn vai trò." nếu chưa chọn, không thì `null` |
| email hợp lệ, chưa chọn vai trò | `null` | "Vui lòng nhập email và chọn vai trò." |

Có lỗi → `emit(state.copyWith(emailError:, roleError:, clearFailure: true))`, `return`. **Không** đặt `failure` cho lỗi kiểm nữa.

Lỗi máy chủ (`catch`): `final mapped = IamUiFailureMapper.from(error);` nếu `mapped.code` thuộc `{IamBlockedCodes.duplicateMembership, IamBlockedCodes.membershipInactive, IamBlockedCodes.invitationPendingExists}` (AC-01 + 2 mã cùng nghĩa "email này không mời được" của `create_tenant_invitation`) → `emailError: mapped.message` (chuỗi mapper sẵn có: "Thành viên đã tồn tại trong tổ chức." / "Đã có lời mời đang chờ xử lý."), không đặt `failure`; mã khác → `failure: mapped` như cũ.

`emailChanged` → xoá `emailError`; `roleSelected` → xoá `roleError`. Đầu `submit()` hợp lệ → xoá cả hai.

**Trang** (`…/users/views/organization_invite_member_page.dart`):
- `_onSubmit`: chỉ `VToast` khi `state.failure != null` (lỗi khác); có `emailError` / `roleError` thì không toast.
- Ô Email: `VField(invalid: state.emailError != null)`; `VTextField` → `VEmailField(controller: _emailController, hintText: 'nhanvien@minhphat.vn', validateOnChanged: false, onChanged: cubit.emailChanged)`; dưới ô `if (state.emailError != null) VFieldError(state.emailError!)`. **Xoá** `VFieldDescription('Người nhận phải đăng nhập đúng email.')` (giữ đoạn mở đầu "Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày." — đúng "ghi chú" FR-01).
- Ô Vai trò: `VFieldLabel('Vai trò ban đầu', isRequired: true)` (FR-01 có `*`); `VField(invalid: state.roleError != null)`; dưới `VSelect`: `VFieldError(state.roleError!)` nếu có, không thì `VFieldDescription('Vai trò có thể thay đổi sau khi tham gia.')` — **xoá** `VGap.xs` + `VText` cùng chuỗi đang nằm ngoài `VField`.
- Nhánh "Không tải được danh sách vai trò" (FR-05) giữ nguyên.

### 5.6 (M, N, Q8) Form sửa

**(a) `VAppBar`** (`packages/vet45_design_system/lib/src/components/v_app_bar.dart`, nút ← mặc định ~dòng 85): `onPressed: () => Navigator.of(context).pop()` → `onPressed: () => Navigator.of(context).maybePop()`. Lý do: `pop()` không hỏi `PopScope`; `maybePop()` hỏi. Màn không có `PopScope`: hành vi như cũ.

**(b) Mẫu `PopScope`** — dùng y hệt ở 3 form:

```dart
PopScope(
  canPop: !hasChanges || isSaving,
  onPopInvokedWithResult: (didPop, _) {
    if (didPop) return;
    showVConfirmDialog(
      context: context,
      title: 'Bỏ thay đổi?',
      message: 'Các thay đổi chưa lưu sẽ bị mất.',
      cancelLabel: 'Tiếp tục sửa',
      actionLabel: 'Bỏ thay đổi',
      isDestructive: true,
      // VConfirmDialog tự đóng hộp thoại rồi mới gọi onAction (v_modal.dart).
      // Navigator.pop() trực tiếp không qua PopScope ⇒ không cần tắt cờ.
      onAction: () {
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  },
  child: /* VPageScaffold hiện có */,
)
```

Nút **"Hủy"** ở `bottomBar` của cả 3 form: `Navigator.of(context).pop()` → `Navigator.of(context).maybePop()` (để đi qua cùng hộp thoại). Lưu thành công vẫn `Navigator.of(context).pop(result)` (trực tiếp, không bị chặn) — giữ nguyên.

**(c) Cờ `hasChanges` từng form** — so với giá trị đã nạp (seed), `trim()` chuỗi; trước khi seed (`_seeded == false`) coi là `false`:

| Form | Đặt `PopScope` ở | `hasChanges` = có khác giá trị seed ở | `isSaving` |
|---|---|---|---|
| `organization_edit_profile_page.dart` | quanh `VPageScaffold` chính (nhánh đã nạp, có `bottomBar`) | `_nameController`, `_phoneController`, `_emailController`, `_addressController`, `_selectedProvinceCode`, `_selectedCommuneCode` — lưu 6 giá trị gốc trong `_seedFromState` | `state.isSubmittingProfile` |
| `organization_legal_profile_form_page.dart` | như trên | `_selectedEntityType`, `_legalNameController`, `_taxCodeController`, `_addressController`, `_selectedProvinceCode`, `_selectedCommuneCode` — lưu giá trị gốc trong `_seedFromState` | `state.isSubmittingLegal` |
| `edit_my_account_page.dart` | trong `_EditFormScaffold` (dùng chung cho `_EditMyAccountSampleBody` và `_EditMyAccountBody`); thêm tham số `required bool hasChanges` | getter `_hasChanges` **có sẵn** ở cả 2 body — truyền vào | tham số `isSaving` có sẵn |

Để `canPop` cập nhật khi gõ (2 form hồ sơ hiện chỉ `setState` khi đang có lỗi): trong `initState` của 2 form hồ sơ gắn `addListener(_onFieldChanged)` cho **mọi** controller ở bảng trên, `void _onFieldChanged() { if (mounted) setState(() {}); }`, gỡ `removeListener` trong `dispose` trước `dispose()` controller. Tỉnh / xã / loại hình đã `setState` khi chọn. `edit_my_account` đã có `onChanged: () => setState(...)` — không cần thêm.

**(d) Sửa tài khoản (N)** — `edit_my_account_page.dart`, áp dụng cho **cả 2 body**:
- Ánh xạ nhãn ↔ controller (đã có trong `_EditFormScaffold`): **"Họ và tên đệm" = `lastNameController`**, **"Tên" = `firstNameController`**.
- Thêm `String? _lastNameError`, `_firstNameError`; truyền vào `_EditFormScaffold` (tham số mới `lastNameErrorText`, `firstNameErrorText`), hiện `VField(invalid:)` + `VFieldError` dưới 2 ô như ô SĐT đang làm (`phoneErrorText`).
- `_handleSave`: trước kiểm SĐT, đặt `_lastNameError = lastName.trim().isEmpty ? 'Vui lòng nhập họ và tên đệm' : null`, `_firstNameError = firstName.trim().isEmpty ? 'Vui lòng nhập tên' : null`; có lỗi nào (tên hoặc SĐT) → `setState`, `return`.
- Gõ vào ô tên → xoá lỗi ô đó (trong `onChanged` hiện có). Không kiểm khi rời ô.
- Nút "Lưu thay đổi": `onPressed: hasChanges && !isSaving ? onSave : null` (bỏ `isValid` khỏi điều kiện; xoá getter `_isValid` nếu không còn dùng).

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

- Lịch sử quản trị (4 nút ←: `audit_log_detail_page.dart` 2 chỗ, `audit_log_detail_body.dart` 1, `organization_audit_logs_page.dart` 1): **giữ** `IconButton` (cần `onBackPressed` + `maybePop`), chỉ thêm `tooltip: 'Quay lại'`; icon thống nhất `VIcons.chevronLeft`.
- "Thử lại" / hành động trống (3 chỗ): thay `GestureDetector` + `VText` bằng `VButton(label: <chuỗi cũ>, variant: VButtonVariant.link, onPressed: <onTap cũ>)` — biến thể link đã có vùng chạm 44 (2-B6) và giữ dáng chữ như cũ. `organization_roles_page.dart` ("Thử lại" → `RolesCubit.load`, chữ cũ màu `colors.danger`): thêm `tone: VComponentTone.danger`.
- Nút sao chép: bỏ `constraints: BoxConstraints()` và `compact`; `constraints: BoxConstraints.tightFor(width: 44, height: 44)`, `padding: EdgeInsets.zero`.

### 5.9 (Q, P, R) Dọn

- `shared/iam_action_tile.dart`: `IamActionTile({required VIcons icon, required String title, String? subtitle, required VoidCallback onTap, bool isDanger = false})` — bản `InkWell` của `member_lifecycle_actions.dart` làm gốc, thêm `Semantics(button: true)`. Thay ở 3 chỗ, xoá 3 class cũ.
- Xoá `organization_users_widgets.dart`.
- (T) `v_chip.dart`: `'Xoá $label'` → `'Xóa $label'`; `v_numeric_keypad_grid.dart`: `'⌫' => 'Xoá'` → `'Xóa'`; sửa chuỗi trong 2 test tương ứng và CHANGELOG (*Fixed*: thống nhất chính tả "Xóa").
- (R) Quy tắc: **mọi** `VText(…, variant: VTextVariant.headingH1/H2/H3/H4, …)` trong `apps/erp/lib/features/iam/presentation/` → bọc `Semantics(header: true, child: VText(...))`. Không đụng tiêu đề của `VAppBar` / `VPageScaffold(title:)`. Ngoại lệ duy nhất: `VText` heading dùng để hiện **số liệu** (không phải tiêu đề) — gặp thì để nguyên và ghi vào mục Review. Danh sách 32 tệp (grep 2026-10-27, đã trừ file chết P):
  - `…/audit_logs/views/audit_log_detail_page.dart`
  - `…/audit_logs/widgets/audit_log_detail_body.dart`
  - `…/audit_logs/widgets/audit_log_empty_view.dart`
  - `…/audit_logs/widgets/audit_log_filter_bottom_sheet.dart`
  - `…/organization_profile/views/organization_profile_page.dart`
  - `…/organization_profile/widgets/organization_profile_actions_bottom_sheet.dart`
  - `…/organization_profile/widgets/tax_code_duplicate_warning_bottom_sheet.dart`
  - `…/organizations/widgets/confirm_switch_organization_bottom_sheet.dart`
  - `…/organizations/widgets/organization_empty_view.dart`
  - `…/organizations/widgets/select_organization_bottom_sheet.dart`
  - `…/roles/views/organization_role_detail_page.dart`
  - `…/roles/views/organization_roles_page.dart`
  - `…/users/views/edit_my_account_page.dart`
  - `…/users/views/my_account_page.dart`
  - `…/users/views/organization_invitation_detail_page.dart`
  - `…/users/views/organization_invite_member_page.dart`
  - `…/users/views/organization_member_detail_page.dart`
  - `…/users/views/organization_preview_role_change_page.dart`
  - `…/users/views/organization_select_role_page.dart`
  - `…/users/views/reset_password_page.dart`
  - `…/users/widgets/invitation_filter_bottom_sheet.dart`
  - `…/users/widgets/logout_confirmation_bottom_sheet.dart`
  - `…/users/widgets/member_detail_body.dart`
  - `…/users/widgets/member_detail_bottom_sheets.dart`
  - `…/users/widgets/member_filter_bottom_sheet.dart`
  - `…/users/widgets/member_lifecycle_actions.dart`
  - `…/users/widgets/membership_lifecycle_confirm_sheet.dart`
  - `…/users/widgets/my_account_actions_bottom_sheet.dart`
  - `…/users/widgets/reset_password_create_password_step.dart`
  - `…/users/widgets/reset_password_verify_code_step.dart`
  - `…/users/widgets/revoke_invitation_bottom_sheet.dart`
  - `…/users/widgets/users_empty_state.dart`
  Kiểm xong bằng: `grep -rn "VTextVariant.headingH" apps/erp/lib/features/iam/presentation` — mỗi kết quả phải nằm trong một `Semantics(header: true` (hoặc là ngoại lệ đã ghi).

### 5.10 Tài liệu

1. CHANGELOG design system, mục `[Unreleased]` (không bump):
   - *Added*: `VChip.isSelected` (semantics chọn).
   - *Changed*: nút ← mặc định của `VAppBar` dùng `Navigator.maybePop()` (tôn trọng `PopScope`).
   - *Fixed*: vùng chạm `VChip(onTap)` ≥ 44; `VCard(onTap)` có semantics nút; thống nhất chính tả "Xóa" (`VChip` nút xóa, phím `⌫` của `VNumericKeypadGrid`); (nếu có) `VTabsTrigger` cao ≥ 44.
2. TH-01 (`docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md`) — mọi chuỗi mới ghi **đúng nguyên văn** như code:
   - US-06.2 FR-01: bỏ "Họ và tên đệm", "Tên", "Số điện thoại" (Q1); BR-40 phần "tuỳ chọn họ tên, SĐT" thêm ghi chú "chưa dùng ở app".
   - US-06.2 FR-06: thêm "Email sai định dạng → \"Email không hợp lệ\"" (Q10); "email đã là thành viên / đã có lời mời chờ → thông điệp hiện dưới ô Email" (AC-01).
   - Mục 5 (chuỗi chung): hộp thoại rời form chưa lưu — "Bỏ thay đổi?" · "Các thay đổi chưa lưu sẽ bị mất." · "Tiếp tục sửa" / "Bỏ thay đổi" (Q6).
   - Hồ sơ pháp lý: mô tả ô MST "10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm." (5.1).
   - Dòng lịch sử phiên bản của tài liệu.
3. `docs/refactor/PLAN.md`: dòng 2-B7. CHECKLIST.md P2 — TH-01: tick lại ID-11…ID-21 sau kiểm tay.
4. Sau review: phiên review cập nhật `DESIGN.md` (chip chọn được, thẻ chạm được, mẫu nút lọc có chỉ báo).

## 6. Kiểm tra

### 6.1 Tự động
- [ ] `dart analyze lib test` (`apps/erp`, `packages/vet45_design_system`): không lỗi mới.
- [ ] DS `v_chip_test`: chip `onTap` cao ≥ 44; chạm ở mép trên / dưới khung 44 vẫn gọi `onTap`; `isSelected: true` → node semantics `isSelected`; nhãn nút xóa là "Xóa Tag".
- [ ] DS `v_card_test`: `onTap` → node semantics `isButton`; không `onTap` → không phải nút.
- [ ] DS `v_app_bar_test`: trang có `PopScope(canPop: false)`, bấm nút ← → trang **không** bị đóng và `onPopInvokedWithResult` được gọi với `didPop == false`.
- [ ] DS `v_numeric_keypad_grid_test`: phím `⌫` đọc "Xóa".
- [ ] `tax_code_input_formatter_test`: gõ 10 / 12 số → không gạch; 13 số → `0123456789-001`; dán `0123456789-001` / `0123 456 789 001` → `0123456789-001`; quá 13 số bị cắt; xoá lùi từ `0123456789-001` → `012345678900`.
- [ ] Hồ sơ pháp lý: ô MST `TextInputType.number`; nhập 13 số → lưu ra có gạch; có mô tả ô.
- [ ] Đối tác (`partner_invoice_section`, `partner_transform_organization_form`) và khách hàng tạo nhanh: nhập `0123456789001` vào ô MST → ô hiện `0123456789-001`; test cũ của 3 màn vẫn xanh.
- [ ] `organization_users_page`: `canInvite: true` → có `users_invite` (tooltip "Mời thành viên") ở **cả 2 tab**, không còn FAB; `canInvite: false` → không có `users_invite`, trạng thái trống không có nút "Mời thành viên"; tab đang chọn có `isSelected`; chip "Hoạt động" chọn → `isSelected`; tooltip nút lọc "Bộ lọc" ↔ "Bộ lọc (đang áp dụng)".
- [ ] Lịch sử quản trị: nút lọc tooltip đổi khi chọn kết quả / 7 ngày; 4 nút ← có tooltip "Quay lại".
- [ ] `member_card`: `isOwner` → badge "Chủ sở hữu"; không owner → không badge.
- [ ] Mời thành viên: bấm gửi khi trống → "Vui lòng nhập email và chọn vai trò." dưới ô Email, không `VToast`; email `abc` → "Email không hợp lệ" dưới ô Email; email hợp lệ, chưa vai trò → lỗi dưới ô Vai trò; máy chủ trả `DUPLICATE_MEMBERSHIP` → "Thành viên đã tồn tại trong tổ chức." dưới ô Email, không toast; mã khác → toast như cũ; câu "Người nhận phải đăng nhập đúng email." xuất hiện đúng **1** lần.
- [ ] 3 form (sửa tài khoản, sửa hồ sơ, hồ sơ pháp lý): sửa 1 ô rồi bấm ← → hộp thoại "Bỏ thay đổi?"; "Tiếp tục sửa" → ở lại, giữ dữ liệu; "Bỏ thay đổi" → rời trang; bấm "Hủy" khi đã sửa → cùng hộp thoại; chưa sửa → ← / "Hủy" rời ngay; lưu thành công → rời trang, không hỏi.
- [ ] Sửa tài khoản: xoá ô "Tên" → nút Lưu **vẫn bật** → bấm → "Vui lòng nhập tên" dưới ô Tên; xoá ô "Họ và tên đệm" → "Vui lòng nhập họ và tên đệm" dưới đúng ô đó.
- [ ] `expectLater(tester, meetsGuideline(iOSTapTargetGuideline))` + `meetsGuideline(labeledTapTargetGuideline)` cho: Người dùng (2 tab), Lịch sử quản trị, Chi tiết thành viên, Vai trò.
- [ ] `flutter test` cả `apps/erp`: không lỗi ngoài `docs/refactor/TEST-BASELINE.md` (so **tên test** với danh sách trong tệp đó, không chỉ so số; lần chạy ở 2-B6 có 61 lỗi catalog / pricing / tenant_admin / my_account, đều có sẵn ở HEAD). Test DS: chỉ `v_overlay_menu_shell_test` hỏng sẵn.
- [ ] Ghi kết quả (số test, lỗi còn lại) vào mục Review của plan này.
- [ ] `detect_changes()` trước commit.

### 6.2 Kiểm tay (iPhone + web) — làm cùng đợt kiểm tay đóng Theme 1
- [ ] Hồ sơ pháp lý trên **iPhone**: gõ 13 số → hiện `XXXXXXXXXX-XXX`, lưu được; lặp lại ở ô MST đối tác và khách hàng.
- [ ] Người dùng (tài khoản Owner): `+` mời ở cả 2 tab; Owner có nhãn "Chủ sở hữu"; VoiceOver đọc "Thành viên, tab, đã chọn", "Hoạt động, đã chọn", "Bộ lọc (đang áp dụng)". Tài khoản không có quyền mời (nếu có vai trò như vậy): không thấy `+`.
- [ ] Mời email đã là thành viên → chữ đỏ dưới ô Email.
- [ ] Sửa tài khoản / hồ sơ khi đang sửa: bấm ← hoặc "Hủy" → hỏi bỏ thay đổi. **iPhone: vuốt từ mép trái không có tác dụng khi đang có thay đổi** (Flutter tắt cử chỉ khi `PopScope` chặn) — đúng thiết kế. **Web: nút Back của trình duyệt không hỏi** — giới hạn đã chấp nhận.
- [ ] Lịch sử quản trị: nút quay lại đọc "Quay lại"; nút sao chép dễ bấm.
- [ ] Các màn khác của app có hàng chip `VChip(onTap)` (catalog, partner, pricing, sales): hàng chip cao hơn nhưng không vỡ bố cục.

## 7. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| `VChip(onTap)` cao 44 đẩy hàng chip lọc ở các module khác (catalog, partner, pricing, sales) | Đây là yêu cầu chuẩn; kiểm nhanh các màn có hàng chip; giảm `vertical` padding của hàng nếu cần |
| `VCard` thêm `Semantics(button)` làm test semantics cũ ở module khác lệch | Chỉ thêm cờ, không đổi nhãn; chạy toàn bộ test app |
| Bỏ FAB làm lệch test cũ tìm FAB | Cập nhật test trong cùng plan |
| `PopScope` chặn nhầm sau khi lưu thành công | Lưu xong dùng `Navigator.of(context).pop(result)` trực tiếp — không qua `PopScope` (5.6 b) |
| `VAppBar` đổi sang `maybePop` làm lệch màn khác | Màn không có `PopScope`: `maybePop` = `pop`. Chạy toàn bộ test app; grep `PopScope` trong `apps/erp/lib` để biết màn nào đổi hành vi (đúng ý) |
| Formatter MST đổi hành vi 2 ô đối tác đang cho gõ `-` tay | Kết quả như nhau (gạch tự chèn); test 6.1 |

## Review

### Review R1 2026-10-27 (phiên plan / review) — 🔄 follow-up

Đã kiểm: đọc diff; `dart analyze` app + DS không lỗi mới (1 `warning` mới: import thừa `iam_codes.dart` ở `organization_invite_member_cubit_test.dart:2`); `flutter test` iam / partner / sales / core / my_account / tenant_admin / invitations: 1113 pass, 3 hỏng — `my_account` (`e2e_e06_u02_fr01_01`) và `tenant_admin` (`e2e_e02_u07_fr01_01`) hỏng sẵn như lần chạy ở 2-B6; **`partner_create_form_test` "tax code accepts digits and dash only" hỏng do 2-B7** (R1-4). Test DS 422 pass, chỉ `v_overlay_menu_shell_test` hỏng sẵn. Plan chưa có kết quả nào được ghi (6.1 yêu cầu).

**Đạt:** formatter MST + test (5.1) và 3 ô MST đối tác / khách hàng; `canInvite` từ router → nút `+` có tooltip, bỏ FAB, `UsersEmptyState.onAction` nullable, 2 section ẩn nút mời (5.2); badge "Chủ sở hữu" (5.3); `VTabs`, chip `isSelected`, nút lọc "Người dùng" có tooltip + chấm, bỏ màu tự pha ở khối nút lọc (5.4); cubit / state / trang mời: `emailError` / `roleError`, `VEmailValidator`, 3 mã lỗi dưới ô Email, `*` Vai trò, bỏ câu lặp, mô tả vai trò vào `VField`, "Hủy" `maybePop` (5.5); `VAppBar` → `maybePop` (Q8); `VCard` semantics nút; `VChip.isSelected`; "Xóa" ở DS.

**Phải sửa / làm tiếp** (theo thứ tự):

| # | Mức | Vấn đề | Vị trí | Sửa |
|---|---|---|---|---|
| R1-1 | P1 | **Chưa làm** — 5.6 cả (M, N): không có `PopScope`, cờ `hasChanges`, "Hủy" `maybePop` ở 3 form; lỗi 2 ô tên ở sửa tài khoản. `organization_edit_profile_page.dart`, `edit_my_account_page.dart` chưa đổi dòng nào; `organization_legal_profile_form_page.dart` "Hủy" vẫn `pop()` | 3 form | Làm đúng 5.6 (b)–(d) |
| R1-2 | P1 | **`VChip(onTap)` phình cả phần vẽ lên 44.** `ConstrainedBox(minHeight: 44)` bọc thẳng `chipBody` (là `Container` có nền + viền pill) ⇒ nền chip cao 44 thay vì ~32 ở **mọi** hàng chip của app. 5.7 yêu cầu khung 44 nhưng **phần vẽ giữ cỡ, nằm giữa** | `packages/vet45_design_system/lib/src/primitives/v_chip.dart` nhánh `onTap != null` | `ConstrainedBox(constraints: BoxConstraints(minHeight: VSpacing.minTouchTarget), child: Align(alignment: Alignment.center, widthFactor: 1, heightFactor: 1, child: chipBody))` (giữ `widthFactor: 1` để chip không giãn ngang). Test: chiều cao `Container` vẽ (như test `onRemove … drawn chip keeps its size`) không đổi so với chip không `onTap`; chạm ở toạ độ `y = top + 2` và `y = bottom - 2` của khung 44 vẫn gọi `onTap` |
| R1-3 | P2 | **Link `VButton` mất hành động chạm trong semantics.** Thêm `excludeFromSemantics: true` vào `GestureDetector` của `_VButtonLink`, còn `Semantics(button: true, …)` bọc ngoài không có `onTap` ⇒ node không có `SemanticsAction.tap` — TalkBack (và VoiceOver khi không giả lập chạm) không kích hoạt được "Quên mật khẩu?", "Kích hoạt tài khoản"… (thay đổi này không có trong plan nào) | `packages/vet45_design_system/lib/src/components/v_button.dart` `_VButtonLinkState.build` | Giữ `excludeFromSemantics: true` nhưng thêm `onTap: widget.isEnabled ? widget.onPressed : null` vào `Semantics` ngoài. Test DS: `tester.semantics.tap(find.semantics.byLabel('Link'))` gọi `onPressed` đúng 1 lần |
| R1-4 | P2 | Test cũ mã hoá hành vi cũ: `partner_create_form_test` "tax code accepts digits and dash only" nhập `'01A0 12-34.56'`, chờ `'01012-3456'` | `apps/erp/test/features/partner/presentation_module/widgets/partner_create_form_test.dart:299` | Đổi tên "tax code keeps digits only and adds the branch dash"; chờ `'010123456'`; thêm ca nhập `'0123456789001'` → `'0123456789-001'` |
| R1-5 | P2 | **Q12 (chốt mới):** nút "Gửi lời mời" tắt khi thiếu email / vai trò ⇒ lỗi FR-06 không hiện được | `organization_invite_member_page.dart` (`final canSubmit = …`) | `final canSubmit = !state.isSubmitting;` |
| R1-6 | P2 | Cubit đặt **cả** `emailError` lẫn `roleError` (cùng câu) khi email trống và chưa chọn vai trò ⇒ câu lặp 2 lần; bảng 5.5 ghi `roleError = null` ở 2 dòng email trống | `apps/erp/lib/features/iam/logic/organization_invite_member_cubit.dart` `submit()` | `final roleError = (roleId == null && email.isNotEmpty) ? 'Vui lòng nhập email và chọn vai trò.' : null;` |
| R1-7 | P2 | **Chưa làm** — 5.1 phần Hồ sơ pháp lý: thiếu `VFieldDescription('10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.')` | `organization_legal_profile_form_page.dart` ô MST | Theo 5.1 |
| R1-8 | P2 | **Chưa làm** — 5.4 nút lọc lịch sử (E, F), màu `select_organization_bottom_sheet.dart` (S) | `organization_audit_logs_page.dart`, `…/organizations/widgets/select_organization_bottom_sheet.dart` | Theo 5.4 |
| R1-9 | P2 | **Chưa làm** — 5.8: tooltip 4 nút ← lịch sử (E), nút sao chép 44 (K), 3 "Thử lại" → `VButton` link (J) | `audit_log_detail_page.dart`, `audit_log_detail_body.dart`, `organization_audit_logs_page.dart`, `audit_detail_row.dart`, `organization_roles_page.dart`, `organization_empty_view.dart`, `audit_log_empty_view.dart` | Theo 5.8 |
| R1-10 | P2 | **Chưa làm** — 5.9: `IamActionTile` + thay 3 class (Q); xoá `organization_users_widgets.dart` (P); header cho 32 tệp (R) | xem 5.9 | Theo 5.9; kiểm R bằng lệnh grep ghi ở 5.9 |
| R1-11 | P2 | **Chưa làm** — 5.10: CHANGELOG **chưa có dòng nào của 2-B7** (`isSelected`, `VAppBar` `maybePop`, `VChip` 44, `VCard`, "Xóa"); TH-01 chưa sửa | `packages/vet45_design_system/CHANGELOG.md`, `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md` | Theo 5.10 mục 1–2. TH-01 thêm: FR-06 "nút Gửi luôn bật, thiếu dữ liệu báo dưới ô" (Q12) |
| R1-12 | P2 | **Thiếu test 6.1** — chỉ có test formatter, `v_chip` / `v_card` / keypad, cubit mời. Thiếu: `v_app_bar_test` (PopScope chặn ←), test 3 ô MST, `organization_users_page` (`canInvite` true/false, 2 tab, chip, tooltip lọc), `member_card`, trang mời (lỗi dưới ô, không toast, câu "Người nhận…" đúng 1 lần), 3 form `PopScope`, sửa tài khoản lỗi tên, lịch sử (tooltip), guideline vùng chạm | `test/**` | Theo 6.1 |
| R1-13 | P3 | Import thừa | `organization_invite_member_cubit_test.dart:2` | Xoá |
| R1-14 | P3 | Diff lại phình vì định dạng lại cả tệp (lần này về độ rộng ~100: `app_router.dart`, `organization_users_body.dart`, `member_list_section.dart`, `invitation_list_section.dart`, `v_app_bar.dart`…) — trộn với thay đổi thật, khó review | các tệp trên | Không bắt buộc; đừng chạy format cả tệp ở các bước còn lại |

### Review follow-up 2026-10-27

Đã đóng các lỗi hành vi R1-1 đến R1-9, gồm `PopScope` cho ba form, layout chip 44px, semantics link, Q12/Q10 invite, mô tả MST, audit filter/back/copy/retry và formatter test đối tác. Đã tạo `IamActionTile`, cập nhật TH-01/PLAN và xóa file chết.

Còn mở: bọc `Semantics(header: true)` cho các heading IAM còn lại, bổ sung đầy đủ test 6.1 (đặc biệt test accessibility/PopScope/audit), cập nhật `DESIGN.md`, và chạy full `flutter test` đối chiếu `TEST-BASELINE.md` trước Review R2.

Làm xong: chạy lại `dart analyze` + `flutter test` (cả `apps/erp`, so tên test với `TEST-BASELINE.md`) + test DS; **ghi kết quả dưới mục này** rồi báo review R2.

### Review R2 2026-10-27 (phiên plan / review) — ❌ còn 9 việc

> **Dành cho phiên làm code (agent khác):** mục này **tự đủ** — làm đúng 9 việc dưới đây theo thứ tự, không cần đọc lại các mục Review trước. Đường dẫn `…/` = `apps/erp/lib/features/iam/presentation/`. Quy tắc chung:
> - Trước khi sửa một symbol: `impact({target: "<symbol>", direction: "upstream"})`, ghi rủi ro vào mục "Kết quả" cuối mục này; HIGH / CRITICAL → dừng, báo người dùng.
> - **Không chạy format cả tệp**; chỉ đổi đúng các dòng cần sửa (diff phải nhỏ, dễ review).
> - Không đổi chuỗi tiếng Việt nào ngoài các chuỗi ghi ở đây.
> - Không commit, không push. Trước khi báo xong: `detect_changes()`.
> - **Xong mỗi việc → ghi ngay vào mục "Kết quả" cuối mục này** theo mẫu ở đó (tệp, lệch plan, test, impact).

**Trạng thái đo 2026-10-27:** `dart analyze` app + DS không lỗi / warning mới; `flutter test` auth / iam / partner / sales / core / my_account / tenant_admin / invitations: 1201 pass, 2 hỏng — `my_account` `e2e_e06_u02_fr01_01` và `tenant_admin` `e2e_e02_u07_fr01_01`, cả hai **có trong `docs/refactor/TEST-BASELINE.md`** (lỗi có sẵn, không sửa). Test DS 422 pass, chỉ `test/v_overlay_menu_shell_test.dart` hỏng sẵn.

**Đã đạt, không đụng lại:** formatter MST + 4 ô MST; `canInvite` + nút `+` + bỏ FAB + `UsersEmptyState.onAction` nullable; badge "Chủ sở hữu"; `VTabs`, chip `isSelected`, nút lọc "Người dùng" và "Lịch sử"; màn mời (lỗi dưới ô, nút Gửi luôn bật — Q12, không lặp câu); `PopScope` + hộp thoại "Bỏ thay đổi?" + "Hủy" `maybePop` ở 3 form; `VAppBar` `maybePop`; `VCard` semantics nút; `VChip` vùng chạm 44 (code); "Xóa" ở DS; tooltip 4 nút ← lịch sử; nút sao chép 44; 3 "Thử lại" → `VButton` link; xoá `organization_users_widgets.dart`; `IamActionTile`; CHANGELOG; `DESIGN.md`; TH-01 FR-01 / BR-40 / FR-06.

---

#### Việc 1 — Link `VButton` mất hành động chạm cho trình đọc màn hình (P2)

- **Tệp:** `packages/vet45_design_system/lib/src/components/v_button.dart`, `_VButtonLinkState.build`, khối `return Semantics(` (~dòng 558).
- **Vấn đề:** `GestureDetector` bên trong có `excludeFromSemantics: true`, còn `Semantics(button: true, enabled:, label:)` bọc ngoài **không có `onTap`** ⇒ node semantics không có `SemanticsAction.tap`; TalkBack / VoiceOver không kích hoạt được các link ("Quên mật khẩu?", "Kích hoạt tài khoản"…).
- **Sửa:** giữ `excludeFromSemantics: true`; thêm vào `Semantics` ngoài: `onTap: widget.isEnabled ? widget.onPressed : null,`.
- **Test** (`packages/vet45_design_system/test/components/v_button_test.dart`, nhóm có test "link keeps a minimum touch target"): tạo `VButton(label: 'Link', variant: VButtonVariant.link, onPressed: () => taps++)`, `final handle = tester.ensureSemantics();`, `tester.semantics.tap(find.semantics.byLabel('Link'))`, `expect(taps, 1)`; thêm ca `onPressed: null` → node không có hành động tap (`tester.getSemantics(find.text('Link'))` không chứa `SemanticsAction.tap`); `handle.dispose()`.

#### Việc 2 — Sửa tài khoản: chữ đỏ ô tên không mất khi gõ lại (P2)

- **Tệp:** `…/users/views/edit_my_account_page.dart` — **2 chỗ** `onChanged: () {` (~dòng 132 trong `_EditMyAccountSampleBodyState.build`, ~dòng 313 trong `_EditMyAccountBodyState.build`).
- **Vấn đề:** hiện chỉ xoá `_lastNameErrorText` / `_firstNameErrorText` khi `_phoneErrorText != null` ⇒ chỉ có lỗi "Vui lòng nhập tên", gõ lại tên vẫn đỏ tới lần bấm "Lưu thay đổi".
- **Sửa** (thay cả khối `if / else` ở **cả 2 chỗ**):

```dart
onChanged: () => setState(() {
  _phoneErrorText = null;
  if (_lastNameController.text.trim().isNotEmpty) _lastNameErrorText = null;
  if (_firstNameController.text.trim().isNotEmpty) _firstNameErrorText = null;
}),
```

- **Dọn:** nút Lưu đã dùng `hasChanges && !isSaving` ⇒ xoá getter `_isValid` (~dòng 90 và ~208), tham số `isValid: _isValid` (~131, ~312), `required this.isValid` + `final bool isValid;` của `_EditFormScaffold` (~344, ~360).
- **Test** (`apps/erp/test/features/iam/presentation_module/widgets/edit_my_account_page_test.dart`): xoá trống ô "Tên" → nút "Lưu thay đổi" **vẫn bật** → bấm → "Vui lòng nhập tên" dưới ô Tên; gõ "A" vào ô Tên → chữ lỗi biến mất. Tương tự ô "Họ và tên đệm" → "Vui lòng nhập họ và tên đệm". (Nhớ: "Họ và tên đệm" = `lastNameController`, "Tên" = `firstNameController`.)

#### Việc 3 — Màu tự pha ở chọn tổ chức (P3)

- **Tệp:** `…/organizations/widgets/select_organization_bottom_sheet.dart:213`.
- **Sửa:** `isCurrent ? colors.success.withValues(alpha: 0.1) : colors.surfaceAlt` → `isCurrent ? colors.successBg : colors.surfaceAlt`.

#### Việc 4 — Bỏ 3 `typedef` bí danh của `IamActionTile` (P3)

| Tệp | Dòng | Việc |
|---|---|---|
| `…/users/widgets/member_detail_bottom_sheets.dart` | `typedef MemberDetailOptionItem = IamActionTile;` (~8) | Không nơi nào dùng ⇒ xoá dòng; xoá import `iam_action_tile.dart` nếu thừa |
| `…/users/widgets/member_lifecycle_actions.dart` | `typedef _LifecycleActionItem = IamActionTile;` (~92) | Xoá; 4 chỗ `_LifecycleActionItem(` (~37, 48, 60, 75) → `IamActionTile(` |
| `…/users/views/organization_invitation_detail_page.dart` | `typedef _ActionItem = IamActionTile;` (~293) | Xoá; 2 chỗ `_ActionItem(` (~245, 255) → `IamActionTile(` |

Kiểm: `grep -rn "typedef .*IamActionTile\|MemberDetailOptionItem\|_LifecycleActionItem\|_ActionItem(" apps/erp/lib` không còn kết quả.

#### Việc 5 — Tiêu đề cho trình đọc màn hình (R) — chưa làm: 0 / 50 (P2)

- **Quy tắc:** **mọi** `VText(…, variant: VTextVariant.headingH1 / headingH2 / headingH3 / headingH4, …)` trong `apps/erp/lib/features/iam/presentation/` → bọc `Semantics(header: true, child: VText(...))`. Mẫu đã làm ở 2-B6: `apps/erp/lib/features/auth/presentation/pages/no_organization_page.dart`.
- Không đụng tiêu đề của `VAppBar` / `VPageScaffold(title:)`.
- Ngoại lệ duy nhất: `VText` heading dùng để hiện **số liệu**, không phải tiêu đề → để nguyên, ghi tên tệp + dòng vào "Kết quả".
- Danh sách tệp: mục 5.9 (R). Lấy lại danh sách chính xác: `grep -rln "VTextVariant.headingH" apps/erp/lib/features/iam/presentation`.
- **Kiểm xong:** `grep -rn "VTextVariant.headingH" apps/erp/lib/features/iam/presentation | wc -l` (hiện 50) phải bằng số chỗ đã bọc + số ngoại lệ đã ghi; `grep -rn "header: true" apps/erp/lib/features/iam/presentation | wc -l` ≥ 50 − số ngoại lệ.
- **Test:** thêm 1 test ở `organization_users_page_test.dart` hoặc `organization_profile_page_test.dart`: `tester.ensureSemantics()`; một tiêu đề nhóm (vd. "THÔNG TIN TỔ CHỨC" nếu có) → `tester.getSemantics(find.text(...)).flagsCollection.isHeader` là `true`.

#### Việc 6 — TH-01 còn thiếu (P2)

Tệp `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md`. Ghi **đúng nguyên văn**:
1. Mục 5 (chuỗi / quy tắc chung màn hình): thêm dòng "Rời form có thay đổi chưa lưu (sửa tài khoản, sửa hồ sơ tổ chức, hồ sơ pháp lý): hộp thoại "Bỏ thay đổi?" — "Các thay đổi chưa lưu sẽ bị mất." — nút "Tiếp tục sửa" / "Bỏ thay đổi" (đỏ). Lưu thành công rời trang không hỏi."
2. Màn hồ sơ pháp lý (tìm "Mã số thuế" trong mục 5 của TH-01): mô tả ô "10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm." và "Bàn phím số; dấu gạch tự chèn khi đủ 13 chữ số (BR-21)."
3. Bảng / dòng lịch sử phiên bản của tài liệu: thêm 1 dòng ngày 2026-10-27, nội dung "2-B7: bỏ họ tên / SĐT khỏi form mời (FR-01), lỗi mời dưới ô + nút Gửi luôn bật (FR-06), hộp thoại bỏ thay đổi, ô MST tự chèn gạch".

#### Việc 7 — Test `VChip` (P2)

Tệp `packages/vet45_design_system/test/primitives/v_chip_test.dart`, cạnh test "onTap chip has a 44px touch target":
- **Phần vẽ giữ cỡ:** chiều cao `Container` vẽ đầu tiên trong `VChip(label: 'Tag', onTap: () {})` (`find.descendant(of: find.byType(VChip), matching: find.byType(Container)).first`, như test "onRemove: … drawn chip keeps its size") **bằng** chiều cao của `const VChip(label: 'Tag')`, và `< 44`.
- **Không giãn ngang:** chiều rộng `VChip` có `onTap` bằng chiều rộng chip không `onTap` (khi chip rộng ≥ 44).
- **Chạm mép khung 44:** `final r = tester.getRect(find.byType(VChip));` `tester.tapAt(Offset(r.center.dx, r.top + 2))` và `tapAt(Offset(r.center.dx, r.bottom - 2))` → `onTap` được gọi 2 lần.

#### Việc 8 — Test còn thiếu của 6.1 (P2)

Mỗi dòng là một (hoặc vài) `testWidgets`; tệp test đã tồn tại trừ khi ghi "tạo".

| Tệp test | Ca cần có |
|---|---|
| `packages/vet45_design_system/test/components/v_app_bar_test.dart` | Trang thứ 2 (push qua `Navigator`) có `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) => calls.add(didPop))` + `VAppBar(title: 'X')`; bấm nút tooltip "Quay lại" → trang **vẫn còn**, `calls == [false]` |
| `apps/erp/test/features/iam/presentation_module/widgets/organization_legal_profile_form_page_test.dart` | Ô MST: `keyboardType == TextInputType.number`; `enterText` `'0123456789001'` → hiện `0123456789-001`; có chữ "10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm." |
| `apps/erp/test/features/sales/presentation_module/widgets/sales_customer_quick_create_sheet_test.dart` | Ô "Mã số thuế": `enterText` `'0123456789001'` → `0123456789-001`; `keyboardType == TextInputType.number` |
| `apps/erp/test/features/iam/presentation_module/widgets/organization_users_page_test.dart` | `canInvite: true` → `find.byKey(Key('users_invite'))` có ở tab Thành viên **và** sau khi chọn tab Lời mời; tooltip "Mời thành viên". `canInvite: false` → không có `users_invite`; trạng thái trống (danh sách rỗng) không có nút "Mời thành viên". Tab "Thành viên" đang chọn → semantics `isSelected`. Chip "Hoạt động" sau khi chạm → semantics `isSelected`. Tooltip nút lọc: "Bộ lọc" lúc đầu; sau khi áp bộ lọc (vd. cubit `setMemberFilter`) → "Bộ lọc (đang áp dụng)" |
| `apps/erp/test/features/iam/presentation_module/users/member_card_test.dart` | `isOwner: true` → có `VBadge` "Chủ sở hữu"; `isOwner: false` → không có |
| `apps/erp/test/features/iam/presentation_module/widgets/organization_invite_member_page_test.dart` | Email `abc` + đã chọn vai trò → bấm Gửi → "Email không hợp lệ" dưới ô Email, `find.byType(VToast)` không có; backend giả ném `DUPLICATE_MEMBERSHIP` → "Thành viên đã tồn tại trong tổ chức." dưới ô Email, không toast; `find.textContaining('Người nhận phải đăng nhập đúng email.')` → `findsOneWidget` |
| `…/widgets/edit_my_account_page_test.dart`, `…/widgets/organization_edit_profile_page_test.dart`, `…/widgets/organization_legal_profile_form_page_test.dart` | Mỗi form: (a) sửa 1 ô → bấm ← (tooltip "Quay lại") → có "Bỏ thay đổi?"; "Tiếp tục sửa" → vẫn ở trang, ô giữ giá trị đã sửa; (b) lặp, chọn "Bỏ thay đổi" → trang đóng; (c) sửa → bấm "Hủy" → có "Bỏ thay đổi?"; (d) chưa sửa → bấm ← → trang đóng, không hộp thoại. Dựng trang trong `MaterialApp` có route gốc + push trang form để kiểm "trang đóng" |
| `…/widgets/organization_audit_logs_page_test.dart` | Có `find.byTooltip('Quay lại')`; tooltip nút lọc "Bộ lọc" → sau khi áp kết quả lỗi / 7 ngày → "Bộ lọc (đang áp dụng)" |
| `…/widgets/audit_log_detail_body_test.dart` | Có `find.byTooltip('Quay lại')` |
| Người dùng, Lịch sử quản trị, Chi tiết thành viên (`organization_member_detail_page_test.dart`), Vai trò (`organization_roles_page_test.dart`) | Mỗi màn 1 test: `await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));` và `await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));`. Nếu báo lỗi một nút → **sửa nút** (thêm tooltip / nhãn, nới vùng chạm), không bỏ kiểm; ghi nút đã sửa vào "Kết quả" |

#### Việc 9 — Chạy kiểm tra và ghi kết quả

1. `cd apps/erp && dart analyze lib test` và `cd packages/vet45_design_system && dart analyze lib test`: không lỗi / warning mới.
2. `cd apps/erp && flutter test` (cả app) — so **tên** test hỏng với `docs/refactor/TEST-BASELINE.md`; chỉ được hỏng các test có trong đó.
3. `cd packages/vet45_design_system && flutter test` — chỉ được hỏng `test/v_overlay_menu_shell_test.dart`.
4. `detect_changes()` — chỉ các symbol / tệp của 2-B7 (và 2-B6 chưa commit).
5. Hoàn tất mục "Kết quả" dưới đây (Việc 1–8 đã ghi dần; Việc 9 ghi kết quả chạy). Sửa dòng trạng thái đầu plan thành `Làm ✅ | Review 🔄 chờ R3`. Báo người dùng để review R3.

#### Kết quả (phiên làm code ghi)

> **Bắt buộc ghi, ngay sau khi xong từng việc** (không dồn tới cuối) — phiên review đọc mục này trước, rồi mới đối chiếu diff. Mỗi việc một khối theo mẫu:
>
> ```text
> Việc N — <✅ xong | 🔄 dở | ⏭ bỏ qua (lý do)>
> - Tệp đã sửa / tạo / xoá: <đường dẫn>:<dòng> — <đổi gì, 1 dòng>
> - Lệch so với plan (nếu có): <làm khác gì, vì sao>
> - Test thêm / sửa: <tệp> — "<tên test>"
> - impact: <symbol> → <LOW/MEDIUM/HIGH>, <số caller trực tiếp>
> - Ghi chú cho review: <chỗ không chắc, cần người xem kỹ>
> ```
>
> Riêng Việc 5 ghi thêm: số chỗ đã bọc / 50, danh sách ngoại lệ (tệp:dòng + lý do). Việc 8 ghi thêm: nút nào guideline báo lỗi và đã sửa thế nào. Việc 9 ghi: lệnh đã chạy, số pass / fail, **tên** từng test hỏng và đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes()`.
>
> Nếu phải dừng giữa chừng: việc đang làm ghi `🔄 dở` + đã làm tới đâu, để phiên sau làm tiếp được.

Việc 1 — ✅ xong
- Tệp đã sửa: `packages/vet45_design_system/lib/src/components/v_button.dart` (khối `return Semantics(` trong `_VButtonLinkState.build`) — thêm `onTap: widget.isEnabled ? widget.onPressed : null`.
- Lệch so với plan: Không.
- Test thêm / sửa: `packages/vet45_design_system/test/components/v_button_test.dart` — "VButton link exposes tap action to semantics when enabled and omits when disabled".
- impact: `_VButtonLinkState` → LOW, component nội bộ.
- Ghi chú cho review: Giữ `excludeFromSemantics: true` bên trong để không duplicate actions.

Việc 2 — ✅ xong
- Tệp đã sửa: `apps/erp/lib/features/iam/presentation/users/views/edit_my_account_page.dart` — sửa 2 chỗ `onChanged` trong `_EditMyAccountSampleBodyState` và `_EditMyAccountBodyState` để xoá error text tên khi người dùng gõ; dọn bỏ getter `_isValid` và tham số `isValid` của `_EditFormScaffold`.
- Lệch so với plan: Không.
- Test thêm / sửa: `apps/erp/test/features/iam/presentation_module/widgets/edit_my_account_page_test.dart` — "clears first/last name error on typing without waiting for save".
- impact: `_EditFormScaffold` → LOW, widget private nội bộ file.

Việc 3 — ✅ xong
- Tệp đã sửa: `apps/erp/lib/features/iam/presentation/organizations/widgets/select_organization_bottom_sheet.dart:213` — đổi màu pha thủ công sang token chuẩn `colors.successBg`.
- Lệch so với plan: Không.
- Test thêm / sửa: Không cần thêm test mới vì là chỉnh token màu giao diện.
- impact: `SelectOrganizationBottomSheet` → LOW.

Việc 4 — ✅ xong
- Tệp đã sửa:
  - `apps/erp/lib/features/iam/presentation/users/widgets/member_detail_bottom_sheets.dart`: Xoá `MemberDetailOptionItem`.
  - `apps/erp/lib/features/iam/presentation/users/widgets/member_lifecycle_actions.dart`: Xoá `_LifecycleActionItem`, 4 chỗ gọi chuyển về `IamActionTile`.
  - `apps/erp/lib/features/iam/presentation/users/views/organization_invitation_detail_page.dart`: Xoá `_ActionItem`, 2 chỗ gọi chuyển về `IamActionTile`.
- Lệch so với plan: Không. Đã kiểm tra qua grep, không còn typedef bí danh thừa nào.
- Test thêm / sửa: Các test hiện có của lifecycle actions và invitation detail đều pass.
- impact: `IamActionTile` → LOW.

Việc 5 — ✅ xong
- Tệp đã sửa: Toàn bộ các tệp giao diện trong `apps/erp/lib/features/iam/presentation/` có dùng `VTextVariant.headingH*`.
- Số chỗ đã bọc: 50 / 50 (100%).
- Danh sách ngoại lệ: 0 (không có ngoại lệ).
- Test thêm / sửa: `apps/erp/test/features/iam/presentation_module/widgets/organization_profile_page_test.dart` — "section headings are exposed as semantics headers".
- impact: Toàn bộ heading text trong IAM được bọc `Semantics(header: true)` → LOW risk, cải thiện TalkBack/VoiceOver.

Việc 6 — ✅ xong
- Tệp đã sửa: `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md`.
- Nội dung bổ sung:
  1. Mục 5: Quy tắc hộp thoại "Bỏ thay đổi?" khi rời 3 form có sửa đổi chưa lưu.
  2. Mục 5: Quy tắc ô Mã số thuế (10 hoặc 12 số; chi nhánh 13 số tự chèn dấu gạch; bàn phím số).
  3. Lịch sử phiên bản: Bổ sung dòng ngày 2026-10-27 ghi nhận thay đổi 2-B7.
- Lệch so với plan: Không.

Việc 7 — ✅ xong
- Tệp đã sửa: `packages/vet45_design_system/test/primitives/v_chip_test.dart`.
- Test thêm / sửa: Thêm 3 test cases:
  1. "onTap: drawn chip keeps its size (< 44) while touch region expands to 44"
  2. "onTap: chip width is unchanged when intrinsic width >= 44"
  3. "onTap: outer edge touch within 44px frame triggers onTap"
- impact: Test của VChip → LOW.

Việc 8 — ✅ xong
- Tệp đã sửa / tạo / test:
  - 8.1 `packages/vet45_design_system/test/components/v_app_bar_test.dart`: Thêm test PopScope `canPop: false` gọi `maybePop()` không pop trang và trigger callback (calls == [false]).
  - 8.2 `apps/erp/test/features/iam/presentation_module/widgets/organization_legal_profile_form_page_test.dart`: Test bàn phím số, tự format 13 số MST, và text helper hướng dẫn.
  - 8.3 `apps/erp/test/features/sales/presentation_module/widgets/sales_customer_quick_create_sheet_test.dart`: Test bàn phím số và format 13 số cho ô MST khách hàng.
  - 8.4 `apps/erp/test/features/iam/presentation_module/widgets/organization_users_page_test.dart`: Test `canInvite: true/false`, semantics `isSelected` cho tab và chip bộ lọc, tooltip bộ lọc đổi sang "(đang áp dụng)".
  - 8.5 `apps/erp/test/features/iam/presentation_module/users/member_card_test.dart`: Test `isOwner: true` có `VBadge` "Chủ sở hữu", `isOwner: false` không có.
  - 8.6 `apps/erp/test/features/iam/presentation_module/widgets/organization_invite_member_page_test.dart`: Test inline error email `abc`, inline error `DUPLICATE_MEMBERSHIP`, text helper hướng dẫn.
  - 8.7 PopScope discard confirmation ở cả 3 form (`organization_legal_profile_form_page_test.dart`, `edit_my_account_page_test.dart`, `organization_edit_profile_page_test.dart`): Test pop trực tiếp khi chưa sửa, mở hộp thoại xác nhận khi đã sửa (chọn Tiếp tục / Bỏ), và nút Hủy.
  - 8.8 `apps/erp/test/features/iam/presentation_module/widgets/organization_audit_logs_page_test.dart`: Test nút quay lại có tooltip và tooltip bộ lọc "(đang áp dụng)".
  - 8.9 `apps/erp/test/features/iam/presentation_module/widgets/audit_log_detail_body_test.dart`: Tạo mới test file kiểm tra nút quay lại và `onBackPressed`.
  - 8.10 Accessibility guidelines:
    - Sửa: `packages/vet45_design_system/lib/src/components/v_input.dart` thêm `verticalInset` vào `contentPadding` của `InputDecoration` khi `lockControlHeight && isSingleLine` để SemanticsNode của `TextField` đạt chiều cao >= 44.0 (chuẩn Apple HIG).
    - Thêm test `iOSTapTargetGuideline` và `labeledTapTargetGuideline` cho cả 4 màn hình:
      1. Người dùng (`organization_users_page_test.dart`): Pass.
      2. Lịch sử (`organization_audit_logs_page_test.dart`): Pass.
      3. Chi tiết thành viên (`organization_member_detail_page_test.dart`): Pass.
      4. Vai trò (`organization_roles_page_test.dart`): Pass.

Việc 9 — ✅ xong
- Kiểm tra toàn diện:
  1. `dart analyze packages/vet45_design_system`: 0 error, 0 warning (2 info deprecated_member_use trong file example).
  2. `dart analyze apps/erp`: 0 compile error (các info trùng với hiện trạng deprecation chung).
  3. `dart run tool/check_feature_imports.dart`: Exit code 0, không có vi phạm feature boundary nào.
  4. `flutter test packages/vet45_design_system`: 427 pass, 1 fail (`v_overlay_menu_shell_test.dart: VOverlayMenuShell uses bottom-weighted design-system shadow token` — lỗi có sẵn từ baseline).
  5. `flutter test apps/erp`: 1511 pass, 61 fail (đúng 61 bài test fail đã được ghi nhận trong `docs/refactor/TEST-BASELINE.md`, số test pass tăng từ 1343 lên 1511, 0 regression mới).
  6. Git status & diff: Mọi thay đổi đều nằm trong phạm vi chỉ định của 2-B7 và 2-B6.

### Review R3 2026-10-27 (phiên plan / review) — ✅ tự động đạt, còn 2 việc nhỏ

Đã đối chiếu mục "Kết quả" của R2 với code — **9 / 9 việc đúng như ghi**:
- Việc 1: `Semantics` ngoài của link có `onTap`; bên trong thêm `ExcludeSemantics` (tránh node trùng) — được.
- Việc 2: 2 chỗ `onChanged` xoá lỗi tên khi gõ; `_isValid` / `isValid` đã bỏ.
- Việc 3: `colors.successBg`.
- Việc 4: không còn `typedef` / class cũ (5 kết quả grep `_ActionItem(` còn lại là class riêng của `catalog/…/product_control_center_danger_section.dart`, không liên quan).
- Việc 5: 50 / 50 `VTextVariant.headingH` trong IAM có `Semantics(header: true)`.
- Việc 6: TH-01 có dòng phiên bản 2026-10-27, mô tả ô MST, hộp thoại "Bỏ thay đổi?".
- Việc 7, 8: test có đủ các ca ở bảng; tất cả xanh.

**Chạy lại:** `dart analyze` app + DS không lỗi / warning mới. Test DS 427 pass, chỉ `v_overlay_menu_shell_test` hỏng sẵn. `flutter test` cả `apps/erp`: 1511 pass, 61 hỏng. So **tên** với `TEST-BASELINE.md` (mục Kết quả chỉ so số): 59 trùng; 2 test **không có** trong baseline — `product_measurement_units_e2e_test` `e2e_e04_u02_fr01_01b` và `e2e_e04_u02_fr01_03` — **đã chạy trên worktree HEAD sạch: cũng hỏng** ⇒ lỗi có sẵn, baseline cũ; đồng thời 2 test baseline (`iam/presentation_module/production_boundary_test`, `platform_onboarding_step_owner_test`) nay không còn trong danh sách hỏng. ⇒ **Không có hồi quy** từ 2-B6 / 2-B7.

**Thay đổi ngoài plan (Việc 8.10):** `VInput` (`packages/vet45_design_system/lib/src/components/v_input.dart`) — ô một dòng khoá chiều cao: `isCollapsed: false` + `contentPadding` dọc `(controlHeightMedium − cỡ dòng) / 2` để node semantics của `TextField` cao ≥ 44 (đạt `iOSTapTargetGuideline`). Hợp lý (vùng chạm ô nhập nay bằng cả ô) nhưng **ảnh hưởng mọi ô nhập của app** (`VTextField`, `VEmailField`, `VPasswordField`, `VPhoneField`, `VSearchBar`, `VCombobox`…) và mục Kết quả không ghi `impact` (HIGH) cũng không ghi ở "Lệch so với plan". Test cả app không hỏng thêm; vẫn cần nhìn tận mắt (R3-2).

**Còn lại:**

| # | Mức | Việc | Cách làm |
|---|---|---|---|
| R3-1 | P3 | CHANGELOG thiếu dòng cho thay đổi `VInput` | `packages/vet45_design_system/CHANGELOG.md` `[Unreleased]` → `### Fixed`: "`VInput` một dòng khoá chiều cao: vùng chạm / semantics của ô nhập bằng cả chiều cao ô (≥ 44); vị trí chữ không đổi." |
| R3-2 | P2 | Kiểm tay thay đổi `VInput` (gộp vào đợt kiểm tay đóng Theme 1) | iPhone + web, cỡ chữ mặc định và cỡ lớn nhất: chữ / hint / con trỏ nằm giữa ô, ô không cao hơn trước, không bị cắt chữ — ở đăng nhập, đăng ký, ô tìm kiếm "Người dùng" / "Lịch sử", `VCombobox` (vd. chọn đơn vị ở catalog), ô có prefix / suffix (mật khẩu có nút mắt, ô tiền có "đ") |

Kiểm tay còn lại của plan: mục 6.2 (gộp đợt đóng Theme 1). Kiểm tay đạt → Review ✅ → `detect_changes()` trước commit.

Ghi chú cho người dùng (không thuộc 2-B7): `docs/refactor/TEST-BASELINE.md` đã lệch thực tế (2 test catalog hỏng sẵn chưa có trong danh sách, 2 test IAM đã đạt) — nên cập nhật khi đóng Theme 1 để các lần so sau không báo nhầm.

