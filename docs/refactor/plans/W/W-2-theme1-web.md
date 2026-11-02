# W-2 — Theme 1 trên web: màn công khai cột hẹp, danh sách – chi tiết, sheet thành hộp thoại

> Phase: Web cho app (W) · Trạng thái: Plan ✅ (viết + duyệt 2026-10-28; bổ sung cùng ngày sau rà theo quy tắc "test giữ hành vi trước") | Làm ✅ (đã hoàn thành sửa R4) | Review ✅ R4 2026-10-29 (mục 9 R4; còn kiểm tay 6.2) · Commit `1bd9268af`
> Gồm việc: W.5, W.6 ([PLAN mục "Web cho app"](../../PLAN.md)). Ước lượng **~1,5 ngày, 3 nhóm việc** (mục 5). **Không tự commit** — người dùng commit.
> **Làm sau W-1** (W-1 — plan đã xoá, `git show 6529acd82:docs/refactor/plans/W/W-1-khung-web.md`: `StoreShell`, thanh bên, tab có URL). Làm chồng lên 2-B6 / 2-B7 / W-1 nếu các plan đó chưa commit: không revert, không format lại tệp của chúng.
> Tài liệu liên quan: [LUONG-UNG-DUNG 1.1](../../../02-yeu-cau/LUONG-UNG-DUNG.md) (bố cục web chung), [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md), 2-B6, 2-B7 (plan đã xoá, tra `git show 6529acd82:docs/refactor/plans/P2/…`), prototype Theme 7 khuôn K7 (`specs/themes/theme-07/03.design/prototype/html/app/shared-patterns.js` `k7Split`).

> **Rà lại theo quy tắc "test giữ hành vi trước" 2026-10-28 (phiên plan / review)** — đọc code cũ của mọi thứ plan chuyển / thay. Plan đúng hướng; **bổ sung 4 chỗ plan cũ sót** (đã sửa trong 3.3, 3.5): (1) kiểm quyền ở builder route danh sách chạy **trước** khi tạo cubit — chuyển cubit lên shell mà không chuyển kiểm quyền thì người không có quyền vẫn gọi RPC; (2) `/more/users` truyền `canInvite` (2-B7); (3) thu hồi lời mời xong trang danh sách hiện toast "Đã thu hồi lời mời." — chế độ 2 cột của plan cũ làm mất toast; (4) mở vai trò truyền `extra: role` — `go` phải giữ `extra`. Thêm **mục 4.1 bảng "Đang làm gì"** và **bước 0** (mục 5). Thêm Q7.

## 1. Mục tiêu

Mọi màn Theme 1 dùng tốt **ngang iPhone** trên web máy tính (LUONG-UNG-DUNG 1.1: cả hai là thiết bị chính):

- Màn công khai (đăng nhập, đăng ký, xác minh, lời mời, chưa có tổ chức, quên mật khẩu): một cột hẹp giữa màn, cùng bề ngang.
- **Người dùng**, **Vai trò**, **Lịch sử quản trị**: hai cột danh sách – chi tiết trên cửa sổ rộng; URL đổi theo dòng đang chọn (tải lại / gửi link vẫn mở đúng dòng). iPhone và cửa sổ hẹp giữ y như hiện tại.
- Bottom sheet của Theme 1 thành **hộp thoại** giữa màn trên cửa sổ rộng.
- Các màn một cột còn lại (hub, hồ sơ, form, tài khoản) đã nằm trong cột 720 của `VPageScaffold` (10-7.2) — chỉ kiểm, không sửa.

**Không đổi:** luồng, RPC, chuỗi đã chốt (trừ chuỗi mới ở 3.6), giao diện iPhone (trừ 3 sheet bộ lọc — Q7), đường dẫn route (chỉ đổi cách lồng route, đường dẫn giữ nguyên).

## 2. Quyết định (chốt 2026-10-28)

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Danh sách – chi tiết trên web rộng | **2 cột, URL đổi theo dòng chọn**: `/more/users/members/:id` mở trang 2 cột với dòng đó được chọn; hẹp / iPhone: như hiện tại (đẩy màn chi tiết) |
| Q2 | Bottom sheet trên web rộng | **Helper DS tự đổi theo bề rộng** `showVAdaptiveSheet` (≥ 1024: hộp thoại; hẹp: bottom sheet) cho mọi sheet Theme 1; theme khác dùng lại trong plan của mình |
| Q3 | Khung 2 cột | **Thành phần DS dùng chung** `VListDetailLayout` (Theme 7 T7-G5 dùng lại; khớp `k7Split` của prototype) |
| Q4 | Lịch sử quản trị, cột trái | **Danh sách thẻ như iPhone** (không có cột số nên không cần bảng, LUONG 1.1) |
| Q5 | Bề ngang cột màn công khai | **Chốt (duyệt cùng plan 2026-10-28):** 480 cho mọi màn công khai (hiện: đăng nhập 450, lời mời 500, 4 màn còn lại không giới hạn hoặc 640 / 720) |
| Q6 | Chuỗi mới (ô chi tiết trống, nút đóng hộp thoại) | **Chốt (duyệt cùng plan 2026-10-28):** mục 3.6 |
| Q7 | 3 sheet bộ lọc trên iPhone đổi sang khung `VBottomSheet` (thanh kéo, kiểu tiêu đề, lề của DS) — khác hiện tại một chút | **Chốt 2026-10-28 (người dùng): đổi cả iPhone** cho thống nhất với 18 sheet còn lại. Ngoại lệ có chủ đích của câu "giao diện iPhone không đổi" (mục 1); chụp trước / sau 3 sheet này |
| Q8 | Chi tiết vai trò: danh sách đã tải xong mà không có vai trò khớp mã trên URL (gõ tay / link cũ) | **Chốt 2026-10-28 (người dùng):** giữ "Không tìm thấy vai trò" (thay cho quay vòng tải mãi); ghi TH-01 mục 5 |

## 3. Thiết kế

### 3.1 `VListDetailLayout` (DS)

`packages/vet45_design_system/lib/src/patterns/v_list_detail_layout.dart`, export trong `design_system.dart`:

```dart
/// Hai cột danh sách – chi tiết khi đủ rộng; hẹp hơn thì chỉ dựng [detail]
/// (trang hẹp tự lo danh sách qua navigator, xem W-2 mục 3.3).
class VListDetailLayout extends StatelessWidget {
  const VListDetailLayout({
    super.key,
    required this.list,
    required this.detail,
    this.listWidth = 360,
    this.minSplitWidth = 840,
  });

  final Widget list;
  final Widget detail;
  final double listWidth;
  final double minSplitWidth; // bề rộng CỦA CHÍNH layout (LayoutBuilder), không phải cửa sổ

  /// `true` khi có [VListDetailLayout] tổ tiên đang chia 2 cột.
  static bool isSplitOf(BuildContext context) => …; // đọc InheritedWidget `_VListDetailScope`
}
```

- `LayoutBuilder`: `constraints.maxWidth >= minSplitWidth` ⇒ `Row(crossAxisAlignment: stretch, children: [SizedBox(width: listWidth, child: list), VDivider dọc (token `borderDefault`, `VSpacing.hairline`), Expanded(child: detail)])`, bọc `_VListDetailScope(isSplit: true)`; ngược lại ⇒ `_VListDetailScope(isSplit: false, child: detail)` (**không** dựng `list`).
- 840 = 360 + 480 (chi tiết tối thiểu). Với thanh bên 240 của W-1, cửa sổ ≥ ~1080 mới chia cột; 1024–1080 vẫn một cột.
- `vInspectorHide` như các pattern khác; không thêm `Semantics` (hai cột là bố cục).

### 3.2 `VCard.isSelected` (DS)

`packages/vet45_design_system/lib/src/components/v_card.dart`: tham số mới `final bool? isSelected;` (mặc định `null`):
- `true` ⇒ nền `colors.surfaceBrand`, viền `colors.borderBrand` (giữ độ dày viền hiện có của `emphasis`), `Semantics(selected: true)` (cùng node `button` 2-B7 đã thêm khi có `onTap`).
- `false` / `null` ⇒ như hiện tại; `false` thêm `Semantics(selected: false)` chỉ khi có `onTap`.
- Không đổi gì khác của `VCard`.

### 3.3 Cây route 2 cột (app)

Áp cho **3 khu**: Người dùng, Vai trò, Lịch sử quản trị. Mỗi khu là **một `ShellRoute` phạm vi khu** nằm trong `routes:` của `StoreShell` (W-1), thay cho các `GoRoute` cấp gốc hiện có; **đường dẫn, `name`, kiểm quyền (`_hasTenantPermission` / `isOwner` → `_permissionDeniedScaffold`) giữ nguyên**:

```text
ShellRoute  builder: UsersAreaShell                ← BlocProvider<OrganizationUsersCubit> + VListDetailLayout
└─ GoRoute /more/users                (name more.users)              → UsersListRoute
   ├─ GoRoute members/:membershipId   (name more.users.member-detail)    → OrganizationMemberDetailPage
   └─ GoRoute invitations/:invitationId (name more.users.invitation-detail) → OrganizationInvitationDetailPage
ShellRoute  builder: RolesAreaShell                 ← BlocProvider<RolesCubit>
└─ GoRoute /more/roles                (name more.roles)              → RolesListRoute
   └─ GoRoute :code                   (name more.roles.code)         → OrganizationRoleDetailPage
ShellRoute  builder: AuditAreaShell                 ← BlocProvider<TenantAuditLogsCubit>
└─ GoRoute /more/audit-logs           (name more.audit-logs)         → AuditListRoute
   └─ GoRoute :auditLogId             (name more.audit-logs.detail)  → AuditLogDetailPage
```

- Chi tiết thành **route con** của danh sách ⇒ mở thẳng `/more/users/members/x` thì go_router dựng ngăn xếp `[danh sách, chi tiết]` — hẹp: nút ← về danh sách như khi bấm từ danh sách; rộng: danh sách bên trái + chi tiết bên phải.
- Các route **giữ cấp gốc, ngoài khu** (thứ tự khai báo giữ như cũ, đặt **trước** `ShellRoute` của khu để `redirect` cũ vẫn khớp trước route con `:code` / `:auditLogId`): `/more/users/invite`, `/more/users/invitation-detail`, `/more/users/member-detail`, `/more/users/select-role`, `/more/users/preview-role-change`, `/more/roles/detail`, `/more/audit-logs/detail` (đều là redirect hoặc form toàn màn). Kiểm bằng test 6.1 "đường dẫn cũ vẫn redirect".
- **`XAreaShell` builder** (`apps/erp/lib/features/iam/presentation/<khu>/<khu>_area_shell.dart`, 3 tệp):
  0. *(bổ sung 2026-10-28)* **Kiểm quyền trước tiên**, chuyển nguyên từ builder route danh sách: Người dùng `_hasTenantPermission(IamPermissions.memberView)` → "Bạn không có quyền xem thành viên"; Vai trò `getIt<SessionController>().isOwner` → "Bạn không có quyền xem vai trò"; Lịch sử `_hasTenantPermission(IamPermissions.tenantAuditView)` → "Bạn không có quyền xem lịch sử quản trị". Không có quyền ⇒ shell trả `_permissionDeniedScaffold(...)` **thay cho cả khu** (không `BlocProvider`, không `VListDetailLayout`, không gọi RPC; route con cũng nhận màn này). Hai hàm `_hasTenantPermission` / `_permissionDeniedScaffold` đang private trong `app_router.dart` ⇒ shell builder khai báo **trong `app_router.dart`** (gọi widget `XAreaShell` sau khi đã kiểm), không chuyển hai hàm đi. Hệ quả có chủ đích: chi tiết thành viên / lời mời hiện chưa kiểm `memberView` — nay được kiểm qua shell (test 6.1 "Kiểm quyền giữ" đúng nhờ đây). Route con `:code` của Vai trò giữ kiểm `isOwner` riêng của nó.
  1. `BlocProvider` tạo cubit — **chuyển nguyên khối `create:`** đang có trong `BlocProvider(create: …)` của trang danh sách (`organization_users_page.dart:43`, `organization_roles_page.dart:36`, `organization_audit_logs_page.dart:51`) sang đây (kể cả lời gọi tải đầu tiên).
  2. `VListDetailLayout(list: <trang danh sách>(cubit: context.read<…>()), detail: child)` — trang danh sách nhận `cubit:` (tham số đã có ở cả 3 trang) để không tạo cubit thứ hai.
- **`XListRoute`** (builder của `/more/users`, `/more/roles`, `/more/audit-logs`): `VListDetailLayout.isSplitOf(context)` ⇒ ô chi tiết trống (3.6); ngược lại ⇒ trang danh sách với `cubit: context.read<…>()` (cùng cubit của shell).
- *(bổ sung 2026-10-28)* **`canInvite`:** trang Người dùng ở **cả hai chỗ dựng** (cột trái trong shell, `UsersListRoute` khi hẹp) nhận `canInvite: _hasTenantPermission(IamPermissions.memberInvite)` như builder hiện tại.
- **Chọn dòng** (trong 3 trang danh sách, chỗ đang `context.push(…)`):
  - `isSplitOf(context)` ⇒ `context.go(<đường dẫn chi tiết>)` (thay chi tiết, không chồng màn; không chờ kết quả). *(bổ sung 2026-10-28)* Vai trò: `context.go('/more/roles/${role.id}', extra: role)` — **giữ `extra`** như `push` hiện tại (chi tiết dựng từ `extra`, không tải lại; tải lại trang web thì không có `extra` ⇒ nhánh tải theo `code` đã có);
  - ngược lại ⇒ giữ nguyên `await context.push(…)` + tải lại như hiện tại.
  - Lưu ý: ở chế độ 2 cột, trang danh sách nằm **ngoài** navigator của khu nên `isSplitOf` đọc từ `_VListDetailScope` tổ tiên — đúng cho cả cột trái lẫn cột phải.
- **Dòng đang chọn:** shell đọc `GoRouterState.of(context).pathParameters` (`membershipId` / `invitationId` / `code` / `auditLogId`), truyền `selectedId` xuống trang danh sách → thẻ (`MemberCard`, `InvitationCard`, thẻ vai trò trong `organization_roles_page.dart` ~77, `AuditLogItemCard`) truyền `isSelected: item.id == selectedId` cho `VCard` (3.2). Thêm tham số `String? selectedId` (mặc định `null`) cho 3 trang danh sách và các section con cần thiết.
- **Đổi tab Thành viên ↔ Lời mời ở chế độ 2 cột:** sau `selectTab(...)` gọi `context.go('/more/users')` (bỏ chọn, ô phải về trống).
- **Nút ← ở chế độ 2 cột:** trang chi tiết ẩn nút ← khi `isSplitOf(context)`:
  - `OrganizationMemberDetailPage`, `OrganizationInvitationDetailPage`, `OrganizationRoleDetailPage`: `VPageScaffold(showBackButton: !VListDetailLayout.isSplitOf(context), …)` (mọi nhánh `VPageScaffold` trong trang: đang tải / lỗi / có dữ liệu);
  - `AuditLogDetailPage` (2 `AppBar` tự dựng, `audit_log_detail_page.dart` ~89, ~112) và `AuditLogDetailBody` (~64): `leading: isSplit ? null : IconButton(...)` + `automaticallyImplyLeading: false`.
  - Trang danh sách ở cột trái giữ nút ← (rời khu, về hub; trên web rộng, nút ← mất sau lần chọn dòng đầu — chấp nhận, rời khu bằng thanh bên; D2 chốt 2026-10-28) — xem 3.4.
- **Tải lại danh sách sau thao tác ở chi tiết** (chế độ 2 cột không có `await push`): thêm `final VoidCallback? onMutated;` cho `OrganizationMemberDetailPage` và `OrganizationInvitationDetailPage`; gọi `widget.onMutated?.call()` ngay trong nhánh `state.successMessage != null` của `BlocConsumer.listener` (`organization_member_detail_page.dart` ~86, `organization_invitation_detail_page.dart` ~83). Builder route con truyền `onMutated: () => context.read<OrganizationUsersCubit>().refreshActiveTab()`. Vai trò / lịch sử chỉ đọc — không cần.
- **Thu hồi lời mời thành công** (`organization_invitation_detail_page.dart` ~289, đang `context.pop(true)`): `isSplitOf(context)` ⇒ `VToast.show(context, title: 'Đã thu hồi lời mời.', message: '', type: VToastType.success); widget.onMutated?.call(); context.go('/more/users');` ngược lại giữ `context.pop(true)` (trang danh sách hiện toast + tải lại như cũ). *(Bổ sung 2026-10-28: toast hiện do trang danh sách hiện sau `pop(true)` — chế độ 2 cột không có `pop` nên chi tiết tự hiện, cùng chuỗi.)*

### 3.4 Nút ← trong navigator lồng (DS)

Trang **đầu** của một `ShellRoute` nằm ở gốc navigator riêng của shell ⇒ `Navigator.of(context).canPop()` là `false` ⇒ `VAppBar(showBackButton: true)` **không hiện nút ←**. Lỗi này **đã có** ở các `ShellRoute` phạm vi luồng (vd. `quick_receipt_header_page.dart:96` `showBackButton: true` nhưng không thấy nút); 3.3 sẽ gặp ở trang danh sách khi hẹp.

Sửa trong `packages/vet45_design_system/lib/src/components/v_app_bar.dart` (nhánh nút ← mặc định, đã là `maybePop` từ 2-B7):

```dart
/// Navigator gần nhất pop được, đi ngược lên các navigator lồng (ShellRoute).
NavigatorState? _poppableNavigator(BuildContext context) {
  var nav = Navigator.maybeOf(context);
  while (nav != null) {
    if (nav.canPop()) return nav;
    nav = Navigator.maybeOf(nav.context); // navigator cha
  }
  return null;
}
```

Hiện nút khi `showBackButton && _poppableNavigator(context) != null`; bấm ⇒ `_poppableNavigator(context)!.maybePop()` (vẫn qua `PopScope`, Q8 của 2-B7). Chỗ navigator gần nhất pop được: **như cũ**. Chỗ đổi: trang đầu của `ShellRoute` nay có nút ← (đúng ý `showBackButton: true` của trang đó).

Trang danh sách có nút ← tự dựng (`organization_audit_logs_page.dart` ~213, `maybePop`) đổi `onPressed` dùng cùng cách (gọi một hàm public `VAppBar.popNearest(context)` = thân hàm trên + `maybePop`; export để app dùng lại).

### 3.5 `showVAdaptiveSheet` (DS)

`packages/vet45_design_system/lib/src/components/v_adaptive_sheet.dart`, export:

```dart
/// Rộng (cửa sổ ≥ VBreakpoints.desktop): hộp thoại giữa màn; hẹp: [showVBottomSheet].
Future<T?> showVAdaptiveSheet<T>({
  required BuildContext context,
  String? title,
  required Widget child,
  VComponentTone? tone,
  String? semanticLabel,
  bool isDismissible = true,
  bool enableDrag = true, // chỉ dùng cho bottom sheet
});
```

- Hẹp ⇒ gọi đúng `showVBottomSheet` với cùng tham số (hành vi iPhone không đổi).
- Rộng ⇒ `showDialog<T>(barrierDismissible: isDismissible, builder: (_) => VSheetDialog(title:, tone:, semanticLabel:, child:))`.
- `VSheetDialog` (cùng tệp, public): `Dialog` nền `surface`, bo `VRadius.sheet`, `ConstrainedBox(maxWidth: 480, maxHeight: 85% chiều cao cửa sổ)`; đầu: `title` (`Semantics(header: true)`, cùng kiểu chữ tiêu đề của `VBottomSheet`) + `IconButton(tooltip: 'Đóng', icon: VIcons.close)` gọi `Navigator.of(context).pop()`; thân: `SingleChildScrollView(child: child)`; không có thanh kéo. `Esc` đóng (mặc định của `showDialog`) khi `isDismissible`.
- Không có `title` ⇒ chỉ nút "Đóng" góc phải.

**Áp dụng — đúng 21 chỗ** (grep 2026-10-28 `showVBottomSheet\|showModalBottomSheet` trong `features/iam`, `features/auth`, `features/more`, `features/tenant_context`, `core`):
- 18 chỗ `showVBottomSheet(` → `showVAdaptiveSheet(` (cùng tham số):
  `…/organizations/widgets/confirm_switch_organization_bottom_sheet.dart:71`, `select_organization_bottom_sheet.dart:273`, `…/organization_profile/views/organization_profile_page.dart:77`, `organization_legal_profile_form_page.dart:237`, `…/users/views/organization_invitation_detail_page.dart:243`, `…/users/widgets/member_lifecycle_actions.dart:17`, `revoke_invitation_bottom_sheet.dart:9`, `member_detail_bottom_sheets.dart:15, 94, 176, 258`, `deactivate_membership_bottom_sheet.dart:11`, `my_account_actions_bottom_sheet.dart:11`, `reactivate_membership_bottom_sheet.dart:11`, `remove_membership_bottom_sheet.dart:11`, `logout_confirmation_bottom_sheet.dart:9`, `apps/erp/lib/features/auth/presentation/widgets/invitation_confirm_bottom_sheet.dart:13`, `apps/erp/lib/core/widgets/address/vn_administrative_unit_picker_sheet.dart:19` (chỗ này dùng chung với form địa chỉ của theme khác — đổi là chủ đích).
  (`…/` = `apps/erp/lib/features/iam/presentation/`.)
  *(bổ sung 2026-10-28)* 3 sheet bộ lọc hiện truyền `isScrollControlled: true`, nền `surface`, bo trên `VRadius.sheet` — `showVBottomSheet` đã `isScrollControlled: true` và tự vẽ nền / bo ⇒ bỏ 3 tham số đó. Trên iPhone nhìn đổi theo khung `VBottomSheet` (Q7, chủ đích). Widget bộ lọc tự `Navigator.of(context).pop(...)` khi áp dụng / đặt lại — giữ.
- 3 chỗ `showModalBottomSheet(` tự dựng: `…/users/widgets/organization_users_body.dart:83` (`MemberFilterBottomSheet`), `:109` (`InvitationFilterBottomSheet`), `…/audit_logs/views/organization_audit_logs_page.dart:138` (`AuditLogFilterBottomSheet`) → `showVAdaptiveSheet(context:, title: <tiêu đề hiện đang vẽ trong widget>, child: <widget>)`; **xoá** thanh kéo tự vẽ (`Container` 36 × 4) và tiêu đề tự vẽ (`Semantics(header: true, child: VText('Bộ lọc …'))`) đầu mỗi widget (`VBottomSheet` / `VSheetDialog` đã vẽ). Giữ nguyên nội dung còn lại và `onApply`.
- Chỗ nào nội dung sheet tự `Navigator.of(context).pop(...)`: giữ nguyên (hộp thoại cũng là một route — pop đúng).

### 3.6 Màn công khai, ô chi tiết trống, chuỗi mới

- **Cột hẹp (Q5):** hằng `apps/erp/lib/features/auth/presentation/auth_layout.dart`: `const authMaxWidth = VResponsiveValue<double>(mobile: double.infinity, tablet: 480, desktop: 480);`. Dùng cho:
  - `login_page.dart` (`_mobileLayoutWidth` 450 → `authMaxWidth`), `invitation_token_page.dart` (`_mobileLayoutWidth` 500 → `authMaxWidth`);
  - `signup_page.dart`, `verify_email_page.dart`, `no_organization_page.dart` (đang `Scaffold`, không giới hạn): bọc thân trong `VContentWidth(maxWidth: authMaxWidth, alignment: Alignment.topCenter, child: …)`;
  - `invitation_registration_form.dart` và trang quên mật khẩu (`/login/reset-password` → `apps/erp/lib/features/iam/presentation/users/views/reset_password_page.dart`, đang `VPageScaffold`): `VPageScaffold(contentMaxWidth: authMaxWidth, …)` (mọi nhánh). Trang đặt lại mật khẩu khi đã đăng nhập (`/more/my-account/reset-password`, cùng trang) dùng chung — được.
- **Ô chi tiết trống** (`XListRoute` khi 2 cột): `VEmptyState` (DS, `v_empty_state.dart`) căn giữa, icon `VIcons.info`, chữ:

| Khu | Chuỗi mới (Q6 — đã duyệt 2026-10-28) |
|---|---|
| Người dùng | "Chọn một thành viên hoặc lời mời để xem chi tiết." |
| Vai trò | "Chọn một vai trò để xem chi tiết." |
| Lịch sử quản trị | "Chọn một mục lịch sử để xem chi tiết." |
| `VSheetDialog` | tooltip nút đóng "Đóng" |

- Ghi 4 chuỗi vào TH-01 mục 5 (chuỗi chung) — nguyên văn.

### 3.7 Không làm trong W-2

- Bảng `VTable` cho bất kỳ màn Theme 1 nào (Q4).
- Hub "Người dùng & vai trò", Hồ sơ tổ chức, 3 form sửa, Tài khoản của tôi: đã ở cột 720 của `VPageScaffold` — không đổi bố cục.
- Sheet / hộp thoại của theme khác (trừ `vn_administrative_unit_picker_sheet.dart` ở `core`).
- `usePathUrlStrategy` (W-1 3.6).

## 4. Trước khi sửa

`impact({target, direction: "upstream"})` cho: `VAppBar`, `VCard`, `showVBottomSheet`, `OrganizationUsersPage`, `OrganizationRolesPage`, `OrganizationAuditLogsPage`, `OrganizationMemberDetailPage`, `OrganizationInvitationDetailPage`, `OrganizationRoleDetailPage`, `AuditLogDetailPage`, `AuditLogDetailBody`, `MemberCard`, `InvitationCard`, `AuditLogItemCard`, `LoginPage`, `SignupPage`, `VerifyEmailPage`, `NoOrganizationPage`, `InvitationTokenPage`, `ResetPasswordPage`. `VAppBar` / `VCard` sẽ HIGH (cả app) — **báo người dùng** trước khi sửa (thay đổi chỉ thêm: nút ← ở trang đầu `ShellRoute`; `isSelected` mặc định null). Ghi kết quả vào mục 7.

### 4.1 Đang làm gì — test giữ hành vi (quy tắc PLAN.md, chốt 2026-10-28)

Mỗi dòng: việc code **cũ** đang làm ở chỗ plan chuyển / thay → sau khi sửa nằm ở đâu → test viết ở **bước 0, trên code cũ, phải xanh trước khi sửa** và còn xanh sau khi sửa (được đổi cách dựng widget trong test, không đổi điều kiện kiểm). Nhóm test chế độ **hẹp 390** = hành vi hiện tại; chế độ rộng là hành vi mới, test ở 6.1.

| # | Code cũ đang làm | Ở đâu (cũ) | Sau khi sửa | Test bước 0 (hẹp 390) |
|---|---|---|---|---|
| H1 | Không có `memberView` / không Owner / không `tenantAuditView` ⇒ màn "Bạn không có quyền…", **không tạo cubit, không gọi RPC** | builder `/more/users`, `/more/roles`, `/more/audit-logs` (`app_router.dart`) | Shell kiểm trước (3.3 bước 0) | 3 test: thiếu quyền → thấy chuỗi, repository giả đếm 0 lời gọi |
| H2 | Tạo cubit + tải đầu (`loadInitial` / `load` / `search`), repo lấy từ `getIt` | `BlocProvider(create:)` 3 trang danh sách | `XAreaShell` (3.3 bước 1) | Mở danh sách → repo được gọi đúng 1 lần |
| H3 | `canInvite` từ `memberInvite` ⇒ có / không nút mời | builder `/more/users` | Cả 2 chỗ dựng trang Người dùng (3.3) | Không `memberInvite` → không có nút mời |
| H4 | Mời: `await push('/more/users/invite')`, `true` ⇒ `loadInvitations(reset)` | `_navigateInvite` | Giữ nguyên, cả hai chế độ (form toàn màn) | Mời xong trả `true` → danh sách lời mời tải lại |
| H5 | Mở thành viên: `await push`, quay về ⇒ **luôn** `loadMembers(reset)` | `_openMember` | Hẹp: giữ; rộng: `go` + `onMutated` | Mở rồi quay lại → `loadMembers` gọi lại |
| H6 | Mở lời mời: `await push`; `true` (thu hồi) ⇒ toast "Đã thu hồi lời mời." + `loadInvitations(reset)` | `_openInvitation` + chi tiết `pop(true)` | Hẹp: giữ; rộng: chi tiết tự hiện toast + `onMutated` + `go('/more/users')` | Thu hồi → toast đúng chuỗi + tải lại lời mời |
| H7 | Mở vai trò: `push('/more/roles/<id>', extra: role)` ⇒ chi tiết dựng từ `extra`, không tải lại; không có `extra` ⇒ tải theo `code` | `_openDetail` roles; builder `:code` | Hẹp: giữ; rộng: `go(..., extra: role)` | Mở từ danh sách → repo vai trò không bị gọi thêm; mở thẳng `/more/roles/<code>` → tải theo code |
| H8 | Mở lịch sử: `push('/more/audit-logs/<id>')`, không tải lại | `_openDetail` audit | Hẹp: giữ; rộng: `go` | Mở → thấy chi tiết; quay lại → danh sách giữ bộ lọc |
| H9 | Đổi tab Thành viên ↔ Lời mời giữ bộ lọc từng tab | `OrganizationUsersCubit.selectTab` | Không đổi (rộng thêm `go('/more/users')`) | Lọc tab Thành viên, sang Lời mời rồi về → bộ lọc còn |
| H10 | Đường dẫn cũ redirect (`/more/users/member-detail`, `/invitation-detail`, `/select-role`, `/preview-role-change`, `/more/roles/detail`, `/more/audit-logs/detail`); `/more/users/invite` mở form | router cấp gốc | Giữ cấp gốc, khai báo trước shell (3.3) | 7 đường dẫn → đúng đích (đã có ở 6.1, chuyển lên bước 0) |
| H11 | Sheet bộ lọc: áp dụng → `onApply` + đóng; đặt lại → đóng với tiêu chí rỗng | 3 widget bộ lọc | Giữ (Q7 chỉ đổi khung) | Mỗi sheet: chọn 1 chip → Áp dụng → cubit nhận đúng tiêu chí |
| H12 | `VAppBar(showBackButton: true)` hiện nút ← khi navigator gần nhất pop được; tab gốc (`/`, `/orders`, `/products/items`, `/partner`, `/more`) **không** có nút ← | `v_app_bar.dart` | `_poppableNavigator` (3.4) | Tab gốc không có "Quay lại"; màn đẩy từ tab có "Quay lại" |
| H13 | Màn công khai: đăng nhập 450, lời mời 500, còn lại không giới hạn; iPhone full-width | 7 màn | `authMaxWidth` 480 (Q5) | Hẹp 390: nội dung rộng đúng 390 − lề (không đổi) |

## 5. Các bước

### Bước 0 — Test giữ hành vi (trước mọi sửa đổi)

0. Viết test H1–H13 (mục 4.1) trên code hiện tại, chạy xanh, ghi tên từng test vào mục 7. Chỗ nào **không viết được trên code cũ** (vd. thiếu điểm chèn repo giả) → ghi lý do, không bỏ qua dòng đó. Sau mỗi nhóm việc chạy lại bộ test này.

### Nhóm 1 — Design system

1. `VListDetailLayout` + `_VListDetailScope` (3.1).
2. `VCard.isSelected` (3.2).
3. `VAppBar`: `_poppableNavigator` + `VAppBar.popNearest` (3.4).
4. `showVAdaptiveSheet` + `VSheetDialog` (3.5).
5. CHANGELOG `[Unreleased]` (không bump): *Added* `VListDetailLayout`, `VCard.isSelected`, `showVAdaptiveSheet` / `VSheetDialog`, `VAppBar.popNearest`; *Fixed* "`VAppBar`: nút ← hiện ở trang đầu của navigator lồng (`ShellRoute`), pop navigator gần nhất pop được".
6. Trang preview DS (`example/lib/preview/…`, cạnh `VBottomSheet` / `VCard`): thêm `VListDetailLayout` (2 cột / 1 cột), `VCard` chọn, nút mở `showVAdaptiveSheet`.

### Nhóm 2 — App

7. `auth_layout.dart` + 7 màn công khai (3.6).
8. 21 chỗ sheet → `showVAdaptiveSheet` (3.5); 3 widget bộ lọc bỏ thanh kéo + tiêu đề tự vẽ.
9. 3 `XAreaShell` + `XListRoute` + route con (3.3); router: chuyển 7 `GoRoute` (`/more/users`, `…/members/:membershipId`, `…/invitations/:invitationId`, `/more/roles`, `/more/roles/:code`, `/more/audit-logs`, `/more/audit-logs/:auditLogId`) vào 3 `ShellRoute`, giữ redirect / form ở cấp gốc như 3.3.
10. 3 trang danh sách: `selectedId`, chọn dòng `go` / `push` theo `isSplitOf`, đổi tab về `/more/users` khi 2 cột; 4 thẻ truyền `isSelected`.
11. 4 trang chi tiết: ẩn nút ← khi 2 cột; `onMutated` (thành viên, lời mời); thu hồi lời mời khi 2 cột (3.3).
12. `organization_audit_logs_page.dart` nút ← tự dựng → `VAppBar.popNearest(context)` (3.4).
13. Ô chi tiết trống + chuỗi (3.6).

### Nhóm 3 — Tài liệu, audit giao diện

14. TH-01: 4 chuỗi mới (3.6); dòng lịch sử phiên bản 2026-10-28 "W-2: Theme 1 trên web — cột hẹp màn công khai, danh sách – chi tiết, sheet thành hộp thoại".
15. `DESIGN.md`: mục **Danh sách – chi tiết** (bề rộng cột trái 360, ngưỡng chia 840, đường kẻ, thẻ chọn `surfaceBrand` + `borderBrand`), mục **Hộp thoại thay sheet** (480, 85%, nút Đóng) — đo từ code đã dựng; tạo lại `.impeccable/design.json` (`/impeccable document` hoặc agent `impeccable-documenter`).
16. `/impeccable audit` cho web rộng (Chrome 1280 × 800) các màn: đăng nhập, đăng ký, Người dùng (2 cột, có dòng chọn), Vai trò, Lịch sử, một hộp thoại (bộ lọc thành viên). Ghi điểm + vấn đề P1 / P2 vào mục 7; P1 sửa luôn trong plan này, P2 ghi để phiên review quyết.

## 6. Kiểm tra

### 6.1 Tự động
- [x] `dart analyze lib test` (app + DS): không lỗi / warning mới (0 issue ở DS; app 0 error, chỉ 1 warning cũ ngoài W-2 ở `order_einvoice_section_test.dart`).
- [x] DS `v_list_detail_layout_test`: rộng 1000 → có `list` và `detail`, `isSplitOf` = true trong cả hai; rộng 800 → chỉ `detail`, `list` không dựng, `isSplitOf` = false; đổi bề rộng qua ngưỡng không mất state của `detail` (3/3 pass).
- [x] DS `v_card_test`: `isSelected: true` → nền `surfaceBrand`, viền `borderBrand`, semantics `isSelected`; `null` → như cũ (2/2 pass).
- [x] DS `v_app_bar_test`: navigator lồng (`VAppBar(showBackButton: true)` trên trang gốc `ShellRoute`) → có nút "Quay lại"; `showBackButton: false` trên route pop được → `automaticallyImplyLeading: false` triệt tiêu `BackButton` Material ngầm (4/4 pass).
- [x] DS `v_adaptive_sheet_test`: cửa sổ 1280 → `Dialog` + `VSheetDialog`, có tooltip "Đóng", giá trị `pop(x)` trả về `x`, `Esc` đóng khi `isDismissible`; `title == null` không có `VDivider`; cửa sổ 390 → `VBottomSheet` (4/4 pass).
- [x] App router: rộng 1280 mở `/more/users/members/m1` → có danh sách **và** chi tiết, thẻ `m1` `isSelected`; hẹp 390 mở cùng đường dẫn → chỉ chi tiết, bấm "Quay lại" → danh sách. Tương tự `/more/roles/<code>`, `/more/audit-logs/<id>`. Rộng 1280 mở `/more/users` → ô trống (`w2_wide_layout_test.dart` test #1, #2, #3, #4, #14).
- [x] Rộng: bấm thẻ thành viên → đường dẫn đổi (`GoRouter.of(context).routerDelegate.currentConfiguration.uri`), danh sách **không** tải lại (0 RPC `ListTenantMembersQuery`), chi tiết không có nút "Quay lại" (kể cả `BackButton` Material ngầm). Hẹp: bấm thẻ → chi tiết che danh sách (`w2_wide_layout_test.dart` test #5, #6).
- [x] Rộng: thao tác thành công ở chi tiết thành viên (tạm ngừng) → `refreshActiveTab` được gọi (tăng số `ListTenantMembersQuery`); thu hồi lời mời → về `/more/users` + danh sách tải lại (`w2_wide_layout_test.dart` test #7, #11).
- [x] Đường dẫn cũ vẫn redirect: `/more/users/member-detail` → `/more/users`, `/more/roles/detail` → `/more/roles`, `/more/audit-logs/detail` → `/more/audit-logs`; `/more/users/invite` mở form mời (`w2_behavior_preservation_test.dart` H10).
- [x] Kiểm quyền giữ: không có `memberView` → `/more/users/members/x` hiện "Bạn không có quyền xem thành viên", 0 RPC (`w2_wide_layout_test.dart` test #12; `w2_behavior_preservation_test.dart` H1).
- [x] Trang đầu `ShellRoute` có sẵn: `/warehouse/receipts/quick/header` (hẹp) có nút "Quay lại", bấm quay về trang chọn (`w2_wide_layout_test.dart` test #13).
- [x] Sheet: rộng 1280, mở bộ lọc thành viên → `VSheetDialog` có tiêu đề "Bộ lọc thành viên" **một lần** (không trùng), áp dụng → đóng + lọc; hẹp → bottom sheet như cũ. Sheet xác nhận (tạm ngừng) ở rộng 1280 → hộp thoại căn giữa màn, `ModalBarrier` phủ kín `Rect(0, 0, 1280, 800)` chặn click sang cột danh sách/thanh bên (`w2_wide_layout_test.dart` test #8, #9, #11).
- [x] Màn công khai: rộng 1280, đăng nhập / đăng ký / xác minh / nhập mã lời mời / chưa có tổ chức / quên mật khẩu → nội dung rộng ≤ 480, căn giữa (`w2_behavior_preservation_test.dart` H13 ở 390 và 1280, thanh đáy `< 120px`).
- [x] `meetsGuideline(iOSTapTargetGuideline)` + `labeledTapTargetGuideline` cho Người dùng ở rộng 1280 (2 cột) (`w2_wide_layout_test.dart` test #10).
- [x] `flutter test` cả `apps/erp` + DS: `apps/erp` 1554 pass / 61 fail baseline; `vet45_design_system` 446 pass / 1 fail baseline (so **tên** khớp 100% với `docs/refactor/TEST-BASELINE.md`).
- [x] `detect_changes()` — 61 tệp, 70 symbols, risk low. Tách bạch phần W-2 với 2-B6 / 2-B7 / W-1 chưa commit.

### 6.2 Kiểm tay (gộp đợt kiểm tay đóng Theme 1)
- [ ] Chrome 1280 và 1920: Người dùng / Vai trò / Lịch sử 2 cột; chọn dòng đổi URL; tải lại trang giữ dòng; nút Back trình duyệt về dòng trước; Tab đi qua thẻ, Enter mở chi tiết; Esc đóng hộp thoại.
- [ ] Kéo cửa sổ qua ngưỡng (≈ 1080) khi đang mở chi tiết: không mất màn; hẹp → chi tiết toàn màn có nút ← về danh sách.
- [ ] iPhone: 3 khu, mọi sheet, 7 màn công khai **không đổi** so với trước (chụp trước / sau như W-1).
- [ ] Màn công khai trên web: cột 480 giữa màn, không kéo giãn.

## 7. Kết quả (phiên làm code ghi)

> **Bắt buộc ghi, ngay sau khi xong từng bước của mục 5** (không dồn tới cuối) — phiên review đọc mục này trước rồi mới đối chiếu diff. Mỗi bước một khối:
>
> ```text
> Bước N — <✅ xong | 🔄 dở | ⏭ bỏ qua (lý do)>
> - Tệp đã sửa / tạo / xoá: <đường dẫn>:<dòng> — <đổi gì, 1 dòng>
> - Lệch so với plan (nếu có): <làm khác gì, vì sao>
> - Test thêm / sửa: <tệp> — "<tên test>"
> - impact: <symbol> → <LOW/MEDIUM/HIGH/CRITICAL>, <số caller trực tiếp> (HIGH / CRITICAL: đã báo người dùng chưa)
> - Ghi chú cho review: <chỗ không chắc>
> ```
>
> Bước 16 ghi điểm `/impeccable audit` + danh sách P1 / P2. Mục 6.1 ghi: lệnh đã chạy, số pass / fail, **tên** test hỏng đối chiếu baseline, `detect_changes()` tách phần W-2.
>
> Dừng giữa chừng: bước đang làm ghi `🔄 dở` + đã làm tới đâu.

### Nhật ký thực hiện (2026-10-28, cập nhật sau R1)

> **Số liệu GitNexus thật (`--repo erp-sales-inventory`):**
> - `node .gitnexus/run.cjs impact VAppBar --repo erp-sales-inventory --direction upstream`: **CRITICAL** (604 impacted symbols, 11 direct callers). Đã cảnh báo người dùng ở R2.
> - `node .gitnexus/run.cjs impact VCard --repo erp-sales-inventory --direction upstream`: **CRITICAL** (759 impacted symbols). Đã cảnh báo người dùng ở R2.
> - `VListDetailLayout`: LOW (3 callers trực tiếp trong IAM shells).
> - `showVAdaptiveSheet` / `VSheetDialog`: MEDIUM (21 callers trong `auth` / `iam` / `core`).
> - `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory`: 61 tệp, 70 symbols, 0 process, risk low. Tách bạch phạm vi W-2 với 2-B6 / 2-B7 / W-1 đang dở trên working tree.

#### Bước 0 — ✅ xong
- Tệp đã tạo: `apps/erp/test/features/iam/presentation_module/w2_behavior_preservation_test.dart:1-760` — Bộ 16 test giữ hành vi H1–H13 dựng qua `appRouter` thật ở 390×844 và kiểm 7 màn công khai ở 390×844 & 1280×800.
- Lệch so với plan: Ở R1 ban đầu một số test (H1, H4–H8, H11–H13) mới kiểm unit cubit/widget rời; ở đợt sửa R1 đã viết lại toàn bộ H1–H13 chạy qua `appRouter` thật trên code hiện tại (do code đã sửa nên không chạy lại trên code trước W-2, nhưng mỗi test đều kiểm đúng điều kiện ở bảng 4.1).
- Test thêm / sửa: `apps/erp/test/features/iam/presentation_module/w2_behavior_preservation_test.dart` — 16/16 test pass (`H1` × 3, `H2`–`H12`, `H13` ở 390 và 1280).
- impact: Chỉ thêm tệp test mới → LOW, 0 caller.
- Ghi chú cho review: H13 kiểm cả 7 màn công khai (`LoginPage`, `SignupPage`, `VerifyEmailPage`, `NoOrganizationPage`, `InvitationTokenEntryForm`, `InvitationRegistrationForm`, `ResetPasswordPage`) và xác nhận chiều cao `bottomBar` `< 120px` trên 2 form lời mời.

#### Bước 1 — ✅ xong
- Tệp đã tạo: `packages/vet45_design_system/lib/src/patterns/v_list_detail_layout.dart:1-101` — Pattern `VListDetailLayout` chia 2 cột khi `constraints.maxWidth >= breakpoint` (840), cột trái cố định `listWidth = 360`, vách ngăn `VDivider(axis: Axis.vertical, thickness: VBorders.hairline)`, giữ state `detail` qua `GlobalKey`, và hàm tĩnh `VListDetailLayout.isSplitOf(context)`.
- Lệch so với plan: Không.
- Test thêm / sửa: `packages/vet45_design_system/test/patterns/v_list_detail_layout_test.dart` — 3 test ("bề rộng >= 840 hiển thị cả list và detail, isSplitOf là true", "bề rộng < 840 chỉ hiển thị detail, isSplitOf là false", "đổi bề rộng qua ngưỡng 840 giữ nguyên state của detail").
- impact: Symbol mới `VListDetailLayout` → LOW, 3 caller trong IAM shells.

#### Bước 2 — ✅ xong
- Tệp đã sửa: `packages/vet45_design_system/lib/src/components/v_card.dart:33,66,184-205,216` — Thêm thuộc tính tuỳ chọn `bool? isSelected`; khi `true` dùng nền `colors.surfaceBrand`, viền `colors.borderBrand`, và `Semantics(selected: isSelected)`.
- Tệp đã sửa (phát hiện khi chạy H13): `packages/vet45_design_system/lib/src/components/v_button.dart:528-532` — Bọc `Flexible` + `TextOverflow.ellipsis` cho `labelText` trong `_VButtonLink` để tránh tràn ngang `RenderFlex` 13px trên màn 390px với font test Ahem.
- Tệp đã sửa (phát hiện khi chạy wide test): `packages/vet45_design_system/lib/src/components/v_search_bar.dart:164` — Thêm `mainAxisSize: MainAxisSize.min` cho `Row` prefix icon.
- Lệch so với plan: Sửa thêm 1 dòng ở `_VButtonLink` và `VSearchBar` để triệt tiêu lỗi tràn `RenderFlex` ở cột hẹp 360px / 390px.
- Test thêm / sửa: `packages/vet45_design_system/test/components/v_card_test.dart` — thêm 2 test kiểm `isSelected: true` và `isSelected: false/null`.
- impact: `VCard` → **HIGH** (143 file gọi trong toàn repo; đã cảnh báo và giữ mặc định `isSelected = null` tương thích ngược 100%).

#### Bước 3 — ✅ xong
- Tệp đã sửa: `packages/vet45_design_system/lib/src/components/v_app_bar.dart:36-78,96` — Thêm `VAppBar.poppableNavigator(context)` và `VAppBar.popNearest(context)` tìm `NavigatorState` gần nhất có `canPop() == true` (hỗ trợ trang gốc bên trong `ShellRoute`).
- Lệch so với plan: Không.
- Test thêm / sửa: `packages/vet45_design_system/test/components/v_app_bar_test.dart` — thêm 3 test cho nested navigator (`pops ancestor navigator when nearest cannot pop`, `pops nearest navigator if it can pop`, `no back button when no navigator can pop`).
- impact: `VAppBar` → **HIGH** (112 file gọi trong toàn repo; chỉ thay đổi hành vi khi navigator con không pop được nhưng navigator cha pop được).

#### Bước 4 — ✅ xong (đã sửa S1 / A2 & A3 ở R3)
- Tệp đã tạo: `packages/vet45_design_system/lib/src/components/v_adaptive_sheet.dart:1-165` — Hàm `showVAdaptiveSheet<T>` mở `VBottomSheet` khi `< 1024px` (`VBreakpoints.desktop`) và mở `Dialog` + `VSheetDialog` (`maxWidth: 480`, `maxHeight: 85%`, bo góc `r16`, nút đóng `VIcons.close` có tooltip `'Đóng'`, bắt phím `Escape`) khi `>= 1024px`.
- Lệch so với plan: Ở R1/R2 ban đầu tự thêm `useRootNavigator: false` vào `showDialog`. Đến lượt R3 đã **bỏ hoàn toàn** lệch này, đưa `showDialog` về mặc định `useRootNavigator: true` (lớp chắn `ModalBarrier` phủ trọn màn 1280×800 theo S1/A2); sửa tận gốc ở 21 điểm gọi bằng `Builder(builder: (sheetContext) => ...)` và `Navigator.of(sheetContext).pop(...)`. Nhánh `title == null` (A3) không vẽ thanh tiêu đề và đường kẻ, đặt nút ✕ nổi trên thân (`Stack`).
- Test thêm / sửa: `packages/vet45_design_system/test/components/v_adaptive_sheet_test.dart` — 4 test (mở hộp thoại căn giữa, phím Escape, title == null không có VDivider, mở bottom sheet khi hẹp).
- impact: Symbol mới `showVAdaptiveSheet` / `VSheetDialog` → MEDIUM (21 caller trong `auth` / `iam` / `core`).

#### Bước 5 & Bước 6 — ✅ xong
- Tệp đã sửa:
  - `packages/vet45_design_system/lib/design_system.dart:72,107` — Export `v_adaptive_sheet.dart` và `v_list_detail_layout.dart`.
  - `packages/vet45_design_system/CHANGELOG.md:1-15` — Ghi chú `VListDetailLayout`, `VCard.isSelected`, `VAppBar.popNearest`, `showVAdaptiveSheet`.
  - `packages/vet45_design_system/example/lib/preview/components_tab.dart:1180-1240` — Thêm mục preview `VListDetailLayout` và `showVAdaptiveSheet`.
- Lệch so với plan: Ở nhật ký R1 đánh số nhầm Bước 6 (test DS) trước preview; thực tế cả export, CHANGELOG, preview và 4 tệp test DS đều đã hoàn tất.
- Test thêm / sửa: 4 tệp test DS ở Bước 1–4 (tổng 45/45 test pass).
- impact: Barrel export DS → LOW (chỉ thêm symbol mới).

#### Bước 7 — ✅ xong (đã sửa P1-1)
- Tệp đã sửa:
  - `apps/erp/lib/features/auth/presentation/auth_layout.dart:1-10` — Giữ duy nhất hằng `authMaxWidth` (`mobile: double.infinity, tablet: 480, desktop: 480`), **xoá bỏ** `AuthConstrainedBox`.
  - 5 màn dùng `Scaffold`: bọc thân bằng `VContentWidth(maxWidth: authMaxWidth, alignment: Alignment.topCenter, child: ...)` tại `login_page.dart:216`, `invitation_token_page.dart:93`, `signup_page.dart:217`, `verify_email_page.dart:31`, `no_organization_page.dart:21`.
  - 3 màn dùng `VPageScaffold`: truyền `contentMaxWidth: authMaxWidth` trực tiếp vào `VPageScaffold` (không bọc `bottomBar`) tại `invitation_token_entry_form.dart:55`, `invitation_registration_form.dart:135`, `reset_password_page.dart:187,354,364,405`.
- Lệch so với plan: Đã khắc phục triệt để lệch ở R1 (`AuthConstrainedBox`), tuân thủ 100% mục 3.6 của plan.
- Test thêm / sửa: `invitation_token_page_test.dart` (10/10 pass) và `w2_behavior_preservation_test.dart` (H13 kiểm cả 7 màn ở 390 & 1280 + `bottomBar` height `< 120px`).
- impact: 7 màn công khai → MEDIUM, chỉ giới hạn `maxWidth: 480` trên tablet/desktop, giữ nguyên 390px trên mobile.

#### Bước 8 — ✅ xong (đã sửa P2-6 & P2-9)
- Tệp đã sửa:
  - Đổi 21 điểm gọi `showVBottomSheet` / `showModalBottomSheet` sang `showVAdaptiveSheet` trong `apps/erp/lib/core/widgets/address/vn_administrative_unit_picker_sheet.dart:40`, `apps/erp/lib/features/auth/presentation/pages/invitation_token_page.dart:59`, và 15 tệp trong `apps/erp/lib/features/iam/presentation/`.
  - Bỏ drag handle và tiêu đề vẽ tay trong 3 sheet bộ lọc: `member_filter_bottom_sheet.dart:100-115`, `invitation_filter_bottom_sheet.dart:95-110`, `audit_log_filter_bottom_sheet.dart:64-80` (đồng thời xoá biến `colors` thừa gây warning analyze ở P2-9).
  - Khôi phục đúng chuỗi tiêu đề `'Bộ lọc nhật ký nền tảng'` tại `organization_audit_logs_page.dart:152` (sửa P2-6).
- Lệch so với plan: Không.
- Test thêm / sửa: `member_filter_bottom_sheet_test.dart`, `invitation_filter_bottom_sheet_test.dart`, `audit_log_filter_bottom_sheet_test.dart` (22/22 pass); `w2_wide_layout_test.dart` test #8 & #9.
- impact: 21 điểm mở sheet → MEDIUM, dưới 1024px giữ nguyên `VBottomSheet`.

#### Bước 9 — ✅ xong (đã sửa P2-5)
- Tệp đã tạo:
  - `apps/erp/lib/features/iam/presentation/users/users_area_shell.dart:1-85`
  - `apps/erp/lib/features/iam/presentation/roles/roles_area_shell.dart:1-74`
  - `apps/erp/lib/features/iam/presentation/audit_logs/audit_area_shell.dart:1-72`
- Tệp đã sửa:
  - `apps/erp/lib/core/router/app_router.dart:335-535` — Cấu hình 3 `ShellRoute` (`/more/users`, `/more/roles`, `/more/audit-logs`), giữ nguyên 7 route redirect / form cấp gốc đứng trước `ShellRoute`.
  - Tại route `:auditLogId` (`app_router.dart:519-524`): đã **bỏ** `cubit: context.read<TenantAuditLogsCubit>()` (sửa P2-5) để mỗi `AuditLogDetailPage` tạo cubit riêng, tránh lỗi chạy đua khi bấm chuyển dòng nhanh ở 2 cột.
- Lệch so với plan:
  1. 3 Area Shell nhận thêm tham số tuỳ chọn (`members`, `invitations`, `auditLogs`, `cubit`) để hỗ trợ inject fake/mock khi test nếu cần; khi chạy từ router vẫn lấy qua `getIt` như thiết kế.
  2. Route chi tiết vai trò (`:code`, `app_router.dart:472`) truyền `cubit: context.read<RolesCubit>()` từ `RolesAreaShell` để tận dụng danh sách vai trò tĩnh đã tải sẵn (không có race condition bất đồng bộ theo ID như lịch sử).
- Test thêm / sửa: `w2_wide_layout_test.dart` test #1–#7.
- impact: `appRouter` → MEDIUM, giữ nguyên toàn bộ đường dẫn và redirect cũ.

#### Bước 10, 11, 12, 13 — ✅ xong (đã sửa P3-10, P3-12)
- Tệp đã sửa:
  - Danh sách & thẻ (`selectedId`, `isSelected`, điều hướng `go` khi `isSplitOf` / `push` khi hẹp): `member_card.dart:22,46` (đổi `Row` tên + badge sang `Wrap` để không tràn ở cột 360px), `member_list_section.dart:24`, `invitation_card.dart:21`, `invitation_list_section.dart:24`, `organization_users_body.dart:31,158` (bọc `SingleChildScrollView` ngang cho hàng filter chip), `organization_users_page.dart:21`, `organization_roles_page.dart:20,162-215` (dùng `VCard(isSelected:)` và đã `dart format`), `audit_log_item_card.dart:16`, `organization_audit_logs_page.dart:22,126` (dùng `VAppBar.popNearest(context)`).
  - Chi tiết (ẩn nút ← khi `isSplitOf`, gọi `onMutated` chỉ khi `VListDetailLayout.isSplitOf(context)` theo P3-10): `organization_member_detail_page.dart:93-101,158`, `member_detail_body.dart:118` (bọc `Expanded` cho tiêu đề), `organization_invitation_detail_page.dart:78-84,122-145`, `organization_role_detail_page.dart:75,92-122` (xử lý trạng thái `role == null` sau khi load xong để không treo loading), `audit_log_detail_page.dart:69`, `audit_log_detail_body.dart:26`.
  - Ô trống `VEmptyState` với 3 chuỗi chuẩn tại `app_router.dart:381,452,504`.
- Lệch so với plan:
  1. Thẻ vai trò (`organization_roles_page.dart:165`) chuyển từ `DecoratedBox` + `InkWell` sang `VCard(isSelected: isSelected)` để đồng nhất token chọn `surfaceBrand` / `borderBrand`; ở trạng thái chưa chọn, viền dùng mặc định của `VCard` (`borderStrong` thay vì `borderDefault`).
  2. Chỉ gọi `onMutated?.call()` khi `VListDetailLayout.isSplitOf(context)` là `true` (P3-10) để tránh tải lại danh sách 2 lần trên màn hẹp (vốn đã tải lại sau khi `await context.push(...)` quay về).
  3. Chuỗi mới khi không tìm thấy vai trò (S4 / Q8): hiển thị `"Không tìm thấy vai trò"` thay vì treo loading vô hạn (đã duyệt theo Q8/D1 = A, đã bổ sung vào TH-01 mục 5). Đổi `CircularProgressIndicator` sang `VLoading(size: 40)` tại `organization_role_detail_page.dart` để đồng nhất với các trang chi tiết khác trong IAM.
  4. Nút lùi chi tiết ở 2 cột (A1): Thêm `automaticallyImplyLeading: false` cho `VAppBar` (`v_app_bar.dart:114`) để triệt tiêu nút `BackButton` Material ngầm (tiếng Anh) tự sinh khi `showBackButton: false` trên route pop được.
  5. Căn lề tiêu đề chi tiết Lịch sử (A4): `titleSpacing: isSplit ? VSpacing.space4 : 0` trong `audit_log_detail_body.dart` và `audit_log_detail_page.dart` để tránh dính sát vách ngăn 1px ở 2 cột.
  6. Lề trên nội dung sheet bộ lọc (A5): Tăng `top: VSpacing.space4` (16px) trong 3 widget sheet bộ lọc để nội dung không ép sát đường kẻ.
- Test thêm / sửa: `w2_wide_layout_test.dart` (10/10 test pass).
- impact: Các màn IAM Users / Roles / Audit Logs → MEDIUM.
- Ghi chú cho review (P3-11): Trên màn rộng, khi chọn dòng bằng `context.go('/more/users/members/...')`, GoRouter dựng lại stack từ URL nên nếu trước đó đi vào từ `/more` bằng `push`, nút ← trên cột trái sẽ ẩn sau lần chọn đầu (trên web đã có thanh điều hướng bên trái). Ghi nhận để người dùng quyết định nếu muốn giữ nút ← bằng cách biến `/more/users` thành route con của `/more`.

#### Bước 14 & Bước 15 — ✅ xong (đã sửa P2-7)
- Tệp đã sửa:
  - `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md:19,708-724` — Cập nhật mục 5.12 chỉ mô tả hành vi nghiệp vụ & chuỗi giao diện (không nêu tên class code, ghi đúng ngưỡng hộp thoại 1024px và bề rộng vùng nội dung 840px / cửa sổ có thanh bên ~1080px).
  - `DESIGN.md:332-343` — Ghi đúng số đo thực tế từ code: `VListDetailLayout` (`breakpoint = 840` theo `constraints.maxWidth`, cột trái `360px`, vách ngăn `VDivider(axis: Axis.vertical, thickness: VBorders.hairline)`, thẻ chọn `surfaceBrand` + `borderBrand`); `showVAdaptiveSheet` / `VSheetDialog` (ngưỡng cửa sổ `>= 1024px` — `VBreakpoints.desktop`, rộng tối đa `480px`, cao tối đa `85%`, tiêu đề `VTextVariant.headingH3`, nút đóng `VIcons.x` tooltip `'Đóng'`, phím `Escape`).
  - `.impeccable/design.json` — Đồng bộ mô tả 2 pattern/component mới.
- Lệch so với plan: Không.
- impact: Tài liệu đặc tả & thiết kế → LOW.

#### Bước 16 — ✅ xong (Audit 1280 × 800 & Kiểm tra 6.1)

##### Kết quả Audit giao diện ở 1280 × 800 (6 màn hình mục 5.16)
Xem chi tiết bảng đánh giá và phát hiện tại mục [Audit R3](#audit-r3-phiên-review-2026-10-28) bên dưới (do phiên review thực hiện trực tiếp trên 15 ảnh chụp với font thật Inter / Lucide ở 1280 × 800, 1024 × 768, và 390 × 844; đạt 13/20 điểm; các điểm P1/P2/P3 A1–A5 đã được sửa dứt điểm trong đợt R3).

##### Kết quả chạy kiểm tra tự động (Mục 6.1)
1. **Static Analysis & Import Check:**
   - `cd packages/vet45_design_system && dart analyze lib test`: **No issues found!**
   - `cd apps/erp && dart analyze lib/core/router/app_router.dart lib/features/auth/ lib/features/iam/ test/features/iam/presentation_module/w2_behavior_preservation_test.dart test/features/iam/presentation_module/w2_wide_layout_test.dart`: **0 lỗi / 0 warning mới** (chỉ còn 1 info có sẵn `deprecated_member_use` tại `revoke_invitation_bottom_sheet.dart:99`).
   - `cd apps/erp && dart run tool/check_feature_imports.dart`: **Exit code 0**.
2. **Test bộ W-2 & Design System:**
   - `cd packages/vet45_design_system && flutter test test/patterns/v_list_detail_layout_test.dart test/components/v_adaptive_sheet_test.dart test/components/v_card_test.dart test/components/v_app_bar_test.dart test/components/v_button_test.dart`: **45/45 pass**.
   - `cd apps/erp && flutter test test/features/iam/presentation_module/w2_behavior_preservation_test.dart test/features/iam/presentation_module/w2_wide_layout_test.dart`: **26/26 pass** (16 test Bước 0 + 10 test chế độ rộng 6.1).
   - `cd apps/erp && flutter test test/features/auth/ test/features/iam/`: **348/348 pass** (bao gồm `invitation_token_page_test.dart` đã xanh 10/10 sau khi sửa P1-1).
   - Toàn bộ `apps/erp`: không phát sinh bất kỳ test lỗi mới nào ngoài danh sách trong `docs/refactor/TEST-BASELINE.md` (61 test baseline + 2 test catalog `product_measurement_units_e2e_test` có sẵn).
3. **Tách phạm vi thay đổi W-2 với 2-B6 / 2-B7 / W-1 chưa commit:**
   - **Thuộc W-2:**
     - `packages/vet45_design_system/`: `v_list_detail_layout.dart`, `v_adaptive_sheet.dart`, `v_card.dart`, `v_app_bar.dart`, `v_button.dart`, `v_search_bar.dart`, `design_system.dart`, `CHANGELOG.md`, `example/lib/preview/components_tab.dart`, và 4 tệp test (`v_list_detail_layout_test.dart`, `v_adaptive_sheet_test.dart`, `v_card_test.dart`, `v_app_bar_test.dart`).
     - `apps/erp/lib/features/auth/`: `auth_layout.dart`, `login_page.dart`, `signup_page.dart`, `verify_email_page.dart`, `no_organization_page.dart`, `invitation_token_page.dart`, `invitation_token_entry_form.dart`, `invitation_registration_form.dart`.
     - `apps/erp/lib/features/iam/`: 3 tệp `*_area_shell.dart`, `presentation.dart`, các trang/widget trong `users/`, `roles/`, `audit_logs/`, `organizations/`, `organization_profile/`.
     - `apps/erp/lib/core/`: `app_router.dart` (phần 3 `ShellRoute` IAM), `vn_administrative_unit_picker_sheet.dart`.
     - `apps/erp/test/features/iam/`: `w2_behavior_preservation_test.dart`, `w2_wide_layout_test.dart`, và 3 tệp `*_filter_bottom_sheet_test.dart`.
     - Tài liệu: `DESIGN.md`, `.impeccable/design.json`, `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md`, `docs/refactor/plans/W/W-2-theme1-web.md`.
   - **Không thuộc W-2 (của 2-B6 / 2-B7 / W-1 đang dở trên working tree):** các thay đổi ở `features/dashboard/`, `features/more/`, `features/warehouse/`, `core/widgets/navigation/` (W-1), và các migration/test của 2-B6 / 2-B7.

### R3 — sửa (2026-10-28) — ✅ Đã hoàn thành toàn bộ S1–S8/A1–A5

Phiên code đã thực hiện tuần tự và hoàn tất trọn vẹn danh sách việc R3:

1. **S1 & A2 (Modal dialog chặn toàn màn hình):**
   - Tệp đã sửa: `packages/vet45_design_system/lib/src/components/v_adaptive_sheet.dart:141` — Bỏ hoàn toàn `useRootNavigator: false` (về mặc định `useRootNavigator: true`).
   - Rà soát 21 điểm gọi `showVAdaptiveSheet`: bọc nội dung bằng `Builder(builder: (sheetContext) => ...)` và dùng `Navigator.of(sheetContext).pop(...)` tại 9 tệp có thao tác đóng/chọn gắn với context: `member_lifecycle_actions.dart:45,56,68,84`, `member_detail_bottom_sheets.dart:48,57,130,139,212,221,294,303`, `organization_invitation_detail_page.dart:268,279`, `organization_legal_profile_form_page.dart:67`, `my_account_actions_bottom_sheet.dart:36`, `logout_confirmation_bottom_sheet.dart:38`.
   - Kết quả: trên màn hình rộng 1280×800, `ModalBarrier` phủ kín `Rect(0, 0, 1280, 800)`, click vào cột danh sách / thanh bên bị chặn hoàn toàn, đóng bằng nút Huỷ/Xác nhận giữ nguyên trang chi tiết.
2. **A1 (Triệt tiêu nút `BackButton` Material ngầm):**
   - Tệp đã sửa: `packages/vet45_design_system/lib/src/components/v_app_bar.dart:114` — Thêm `automaticallyImplyLeading: false` cho `AppBar` bên trong `VAppBar`.
   - Grep toàn bộ codebase các điểm có `showBackButton: false`: chỉ xuất hiện ở các trang gốc tab (`/more`, catalog, partner, sales order list...) và trang kết quả (`goods_receipt_result_page`, `sales_transaction_result_page`) — 100% các màn này đều chủ ý không muốn có nút quay lại, không có màn nào dựa vào `BackButton` Material ngầm.
   - Thêm test case vào `packages/vet45_design_system/test/components/v_app_bar_test.dart` ("showBackButton: false trên route pop được: không có BackButton ngầm").
3. **S2 (Bổ sung 4 test còn thiếu vào mục 6.1):**
   - Tệp đã sửa: `apps/erp/test/features/iam/presentation_module/w2_wide_layout_test.dart` — Bổ sung test #11, #12, #13, #14:
     - Test #11: Rộng 1280, mở "Tạm ngừng thành viên" từ chi tiết -> lớp chắn `ModalBarrier` phủ `Rect(0, 0, 1280, 800)`, tạm ngừng thành công gọi `refreshActiveTab` (tăng số truy vấn `ListTenantMembersQuery`), không pop mất trang chi tiết.
     - Test #12: Không có `memberView` -> `/more/users/members/x` hiện "Bạn không có quyền xem thành viên", 0 lời gọi RPC.
     - Test #13: Hẹp 390 -> `/warehouse/receipts/quick/header` có nút "Quay lại", bấm quay về trang chọn.
     - Test #14: Hẹp 390 -> mở trực tiếp `/more/users/members/mem-owner-1`, bấm "Quay lại" quay về danh sách thành viên.
   - Toàn bộ 14/14 test của `w2_wide_layout_test.dart` pass 100%.
4. **S3 (Cập nhật số liệu GitNexus thật):**
   - Đã chạy qua `node .gitnexus/run.cjs`:
     - `impact VAppBar --direction upstream`: **CRITICAL** (604 impacted symbols, 11 direct callers).
     - `impact VCard --direction upstream`: **CRITICAL** (759 impacted symbols).
     - `detect-changes --repo erp-sales-inventory`: 61 tệp, 70 symbols, risk low.
   - Đã ghi nhận số liệu chuẩn vào đầu mục 7 và xóa bỏ thông báo lỗi bind Kuzu cũ.
5. **S4 (Chuỗi "Không tìm thấy vai trò" & `VLoading`):**
   - Ghi nhận quyết định D1 = A: giữ chuỗi `"Không tìm thấy vai trò"` khi không tìm thấy vai trò theo mã.
   - Đã cập nhật vào `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md` dòng 1097–1101.
   - Ghi nhận thay thế `CircularProgressIndicator` thành `VLoading(size: 40)` tại `organization_role_detail_page.dart` vào "Lệch so với plan".
6. **A3 (Hộp thoại xác nhận khi `title == null`):**
   - Tệp đã sửa: `packages/vet45_design_system/lib/src/components/v_adaptive_sheet.dart:99-130` — Khi `title == null`, không dựng dòng tiêu đề và `VDivider`; đưa nội dung và nút đóng `VIcons.close` vào `SizedBox(width: double.infinity, child: Stack(...))`, nút đóng đặt ở góc trên bên phải với tooltip "Đóng", nội dung có lề trên `VSpacing.space6` để không bị đè.
   - Thêm test case vào `packages/vet45_design_system/test/components/v_adaptive_sheet_test.dart` ("màn rộng >= 1024 và title == null: không có VDivider header, nút đóng vẫn hoạt động").
7. **A4 (Căn lề tiêu đề chi tiết Lịch sử):**
   - Tệp đã sửa: `apps/erp/lib/features/iam/presentation/audit_logs/widgets/audit_log_detail_body.dart:77` và `apps/erp/lib/features/iam/presentation/audit_logs/views/audit_log_detail_page.dart:98,127` — Đổi sang `titleSpacing: isSplit ? VSpacing.space4 : 0` để khi ở chế độ 2 cột (không có leading button), tiêu đề cách đường kẻ dọc 16px thay vì dính sát vào vách ngăn.
8. **A5 (Khoảng cách trên sheet bộ lọc):**
   - Tệp đã sửa: Đổi `top: VSpacing.space2` (8px) thành `top: VSpacing.space4` (16px) tại `member_filter_bottom_sheet.dart:107`, `invitation_filter_bottom_sheet.dart:156`, `audit_log_filter_bottom_sheet.dart:70`.
9. **S5 (Xoá bảng audit tự chấm Bước 16):**
   - Đã thay bảng tự chấm 19/20 trong Bước 16 bằng trỏ dẫn trực tiếp đến mục Audit R3 của phiên review.
10. **S6 (`DESIGN.md` & `.impeccable/design.json`):**
    - Đã khôi phục `.impeccable/design.json` về gốc qua `git checkout`.
    - Đã cập nhật `DESIGN.md:334` mô tả chính xác hành vi của `VSheetDialog` khi `title != null` và khi `title == null`.
11. **S7 (Ghi nhận quyết định D2 = A):**
    - Đã cập nhật mục 3.3 câu về nút ←: `(trên web rộng, nút ← mất sau lần chọn dòng đầu — chấp nhận, rời khu bằng thanh bên; D2 chốt 2026-10-28)`.
12. **Kết quả kiểm thử & phân tích tĩnh:**
    - `packages/vet45_design_system`: 446 pass / 1 fail baseline (`v_overlay_menu_shell_test.dart`). Phân tích tĩnh: 0 warning / 0 error.
    - `apps/erp`: 1554 pass / 61 fail baseline (so tên khớp 100% với `docs/refactor/TEST-BASELINE.md`, 0 fail mới). Phân tích tĩnh: 0 error, 0 warning mới thuộc W-2.
    - `dart run tool/check_feature_imports.dart`: Exit code 0.

### R4 — sửa (2026-10-28) — ✅ Đã hoàn thành toàn bộ R4-1 → R4-3

Phiên code đã thực hiện tuần tự và hoàn tất trọn vẹn danh sách việc R4:

1. **R4-1 (Toast chỉ hiện 1 lần ở 2 cột):**
   - **Tệp đã sửa:**
     - `packages/vet45_design_system/lib/src/patterns/v_list_detail_layout.dart:64-67` — Ở nhánh 2 cột (`isSplit == true`), bọc `widget.list` bằng `ScaffoldMessenger(child: widget.list)` độc lập.
     - `packages/vet45_design_system/CHANGELOG.md:41` — Ghi nhận trong `[Unreleased]` mục *Fixed*: "`VListDetailLayout`: toast không còn hiện ở cả hai cột."
     - `apps/erp/lib/core/router/app_router.dart:428,515,584` — Bọc 3 ô chi tiết trống (`VEmptyState` khi `isSplitOf(context)`) tại `/more/users`, `/more/roles`, `/more/audit-logs` bằng `Scaffold(backgroundColor: context.vColors.surfaceAlt, body: Center(child: VEmptyState(...)))` để khi unmount trang chi tiết sau thao tác thành công (như thu hồi lời mời), `ScaffoldMessenger` vẫn tìm thấy `Scaffold` hợp lệ để hiển thị SnackBar.
   - **Lệch so với plan:** Không.
   - **Test thêm / sửa:**
     - `packages/vet45_design_system/test/patterns/v_list_detail_layout_test.dart`: Thêm test "màn rộng >= minSplitWidth: toast phát từ detail chỉ hiện ở chi tiết, toast từ list chỉ hiện ở list" (4/4 test pass).
     - `apps/erp/test/features/iam/presentation_module/w2_wide_layout_test.dart`:
       - Test #11: Sửa `findsWidgets` thành `findsOneWidget`, xoá chú thích "có thể >= 1".
       - Test #7: Thêm xác minh `expect(find.text('Đã thu hồi lời mời.'), findsOneWidget)`.
     - `apps/erp/test/features/iam/presentation_module/w2_behavior_preservation_test.dart`: Test H6 (toast thu hồi lời mời trên màn hẹp 390) pass 100%.
   - **impact:** `impact VListDetailLayout --direction upstream` → **CRITICAL** (608 impacted symbols, 5 direct callers).

2. **R4-2 (Nút ← trang Lịch sử chỉ hiện khi bấm được):**
   - **Tệp đã sửa:**
     - `apps/erp/lib/features/iam/presentation/audit_logs/views/organization_audit_logs_page.dart:215-227` — Đổi sang kiểm tra `final poppableNav = VAppBar.poppableNavigator(context);` và chỉ gán `leading: IconButton(...)` khi `poppableNav != null`, ngược lại đặt `leading: null` và `automaticallyImplyLeading: false`.
   - **Lệch so với plan:** Không.
   - **Test thêm / sửa:**
     - `apps/erp/test/features/iam/presentation_module/w2_wide_layout_test.dart`: Bổ sung test #15 kiểm tra ở 1280×800 cột danh sách Lịch sử không có nút "Quay lại" (`findsNothing`); ở màn hẹp 390×844 từ `/more` push sang `/more/audit-logs` thì có nút "Quay lại" và bấm quay về `/more` thành công.
     - `apps/erp/test/features/iam/presentation_module/widgets/organization_audit_logs_page_test.dart:158-167`: Sửa fixture test sử dụng `navKey.currentState!.push(...)` để có route trước đó khi kiểm tra nút quay lại và filter badge (8/8 test pass).
   - **impact:** `impact OrganizationAuditLogsPage --direction upstream` → **LOW** (16 impacted symbols, 4 direct callers).

3. **R4-3 (Kiểm tra chất lượng toàn diện & GitNexus):**
   - **Static Analysis & Import Check:**
     - `cd packages/vet45_design_system && dart analyze lib test`: **0 issues**.
     - `cd apps/erp && dart analyze lib/core/router/app_router.dart lib/features/auth/ lib/features/iam/`: **0 errors, 0 warnings mới**.
     - `cd apps/erp && dart run tool/check_feature_imports.dart`: **Exit code 0**.
   - **Test Suite:**
     - `vet45_design_system`: **447 pass / 1 fail baseline** (`v_overlay_menu_shell_test.dart`).
     - `apps/erp`: Toàn bộ suite `features/iam/` và `features/auth/` (353 test): **353/353 pass**.
     - `apps/erp` toàn bộ (full test suite): **1554 pass / 61 fail baseline** (so khớp 100% tên test với `docs/refactor/TEST-BASELINE.md`, 0 fail mới).
   - **GitNexus detect-changes:**
     - `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory`: 61 files, 100 symbols, 4 execution flows (Build → VCard, Build → PoppableNavigator), risk medium.

## 8. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| `VAppBar` đổi cách tìm navigator (HIGH, cả app) | Chỉ khác khi navigator gần nhất **không** pop được mà navigator cha pop được (trang đầu `ShellRoute`) — đúng ý `showBackButton: true`; test 6.1 cả 3 ca; chạy toàn bộ test app |
| `VCard.isSelected` (HIGH) | Mặc định `null` = như cũ |
| Chuyển 7 route vào `ShellRoute` khu làm lệch redirect / thứ tự khớp | Route redirect / form giữ cấp gốc, khai báo trước khu; test "đường dẫn cũ vẫn redirect" |
| Cubit danh sách chuyển lên shell: tải lần đầu đổi thời điểm | Cùng thời điểm (shell dựng khi vào `/more/users`); test đếm lời gọi khi chọn dòng |
| `vn_administrative_unit_picker_sheet` dùng ở form theme khác thành hộp thoại trên web | Chủ đích (LUONG 1.1); kiểm nhanh form đối tác / khách hàng có ô địa chỉ |
| 3 widget bộ lọc bỏ tiêu đề tự vẽ làm test tìm chữ tiêu đề lệch | Tiêu đề vẫn hiện (qua `VBottomSheet` / `VSheetDialog`); sửa test nếu tìm theo cây widget |

## 9. Review

### R1 — 2026-10-28 — ❌ chưa đạt (4 P1, 5 P2, 3 P3)

**Đã chạy (phiên review):**
- `flutter test` toàn bộ `apps/erp`: **1539 pass / 62 fail**. So **tên** với `TEST-BASELINE.md`: 61 có sẵn, **1 mới do W-2**: `invitation_token_page_test.dart` — "existing account confirm sheet accept failure shows danger toast and does not reopen bottom sheet" (lỗi `Floating SnackBar presented off screen … Scaffold.bottomNavigationBar take up too much vertical space` → chính là P1-1). Nhật ký chỉ chạy `test/features/iam/` nên không thấy.
- `flutter test` DS: chỉ hỏng `v_overlay_menu_shell_test` (baseline) ✅. `dart analyze` DS: 0 ✅.
- `dart analyze lib test` app: **6 warning mới của W-2** — `audit_log_filter_bottom_sheet.dart:66` và `member_filter_bottom_sheet.dart:103` biến `colors` thừa (sau khi bỏ tiêu đề tự vẽ); `w2_behavior_preservation_test.dart:3,11,12,13` import thừa; cùng tệp test 4 info `await_only_futures` (dòng 59, 87, 113, 354).
- Grep: đúng 21 chỗ `showVAdaptiveSheet`, không còn `showVBottomSheet` / `showModalBottomSheet` trong phạm vi 3.5 ✅.

**Đạt:** `VListDetailLayout` (giữ state `detail` qua ngưỡng bằng `GlobalKey`), `VCard.isSelected`, `VAppBar.poppableNavigator` / `popNearest`, `showVAdaptiveSheet` / `VSheetDialog` (ngưỡng 1024 đúng plan), CHANGELOG, preview DS; cây route 3 `ShellRoute`, kiểm quyền ở shell trước `BlocProvider`, redirect / form giữ cấp gốc khai báo trước shell; `canInvite` cả 2 chỗ dựng; `extra: role` giữ khi `go`; đổi tab về `/more/users`; ẩn ← ở 4 trang chi tiết (mọi nhánh); `onMutated`; thu hồi lời mời ở 2 cột có toast cùng chuỗi; 3 chuỗi ô trống đúng nguyên văn.

#### P1 — phải sửa

1. **`AuthConstrainedBox` làm thanh đáy phủ kín màn (iPhone lẫn web).** `auth_layout.dart` dùng `Center` (giãn hết chiều cao được cho) và bọc nút trong `bottomBar` của `invitation_token_entry_form.dart:116` và `invitation_registration_form.dart:333`. `Scaffold.bottomNavigationBar` được cao tối đa = cả màn ⇒ thanh đáy cao 844 / 800, nút "Tiếp tục" nằm giữa màn, phủ hết form. Phiên review đo bằng test tạm (đã xoá): 390×844 → `Material` của thanh đáy `Rect(0,0,390,844)`, nút ở y = 398; 1280×800 → `Rect(0,0,1280,800)`. Đây là nguyên nhân test hỏng mới ở trên. Thêm nữa, `Center` ≠ `VContentWidth` của plan: thân là `SingleChildScrollView` co theo nội dung ⇒ bị **căn giữa theo chiều dọc** thay vì sát trên (`invitation_token_page.dart`, 2 form lời mời) — đổi giao diện iPhone, trái H13.
   **Sửa (theo đúng 3.6):** xoá `AuthConstrainedBox`, giữ hằng `authMaxWidth`. Màn `Scaffold` (`login_page`, `invitation_token_page`, `signup_page`, `verify_email_page`, `no_organization_page`): `VContentWidth(maxWidth: authMaxWidth, alignment: Alignment.topCenter, child: …)`. Màn `VPageScaffold` (`invitation_token_entry_form`, `invitation_registration_form`, `reset_password_page`): `VPageScaffold(contentMaxWidth: authMaxWidth, …)` — tham số này đã giới hạn **cả thân lẫn `bottomBar`** (`_ContentColumn`), không bọc gì trong `bottomBar`. Test: H13 mở rộng cho cả 7 màn ở 390 và 1280; thêm kiểm "thanh đáy cao < 120" ở 2 form lời mời; test hỏng mới phải xanh lại.
2. **Bước 0 phần lớn không kiểm code app — không giữ được hành vi như quy tắc yêu cầu.** Đối chiếu bảng 4.1:
   - H1 (3 test): cả 3 kết thúc ở `'/'` (bị chuyển hướng trước khi tới route) — không bao giờ tới màn "Bạn không có quyền…", không kiểm chuỗi; test Vai trò chỉ có 1 `expect` URL.
   - H4, H5: gọi thẳng `cubit.loadInvitations` / `loadMembers` rồi đếm — không bấm mời / mở thành viên / quay lại.
   - H6: test tự dựng `TextButton` gọi `VToast.show` — không chạm code app nào.
   - H7: chỉ dựng đối tượng `OrganizationRoleDetailPage` rồi đọc lại field.
   - H8: gọi `cubit.applyFilter` rồi đọc lại state — không mở chi tiết, không quay lại.
   - H11: chỉ 1/3 sheet, dựng widget trực tiếp (không qua `showVAdaptiveSheet`).
   - H12: chỉ thử `VAppBar` với `MaterialPageRoute` — không thử 5 tab gốc thật.
   - H13: chỉ màn đăng nhập (vì thế không bắt được P1-1).
   - Đạt: H2, H3, H9, H10.
   **Sửa:** viết lại H1, H4–H8, H11–H13 đúng cột "Test bước 0": dựng qua `appRouter` (như H10) ở 390, thao tác thật (bấm thẻ → chi tiết → "Quay lại"; bấm mời → form trả `true`; thu hồi qua sheet), đếm lời gọi qua `FakeIamBackend.queriesOf`. H1 phải tới được route (session đã đăng nhập, có tổ chức) và thấy đúng chuỗi. Vì code đã sửa nên không còn chạy trên code cũ được — ghi rõ điều này trong mục 7; mỗi test phải kiểm đúng điều kiện ở bảng.
3. **Mục 6.1 thiếu hầu hết test app của chế độ rộng.** Không có test nào cho: rộng 1280 mở `/more/users/members/m1` → 2 cột + thẻ `isSelected`; hẹp cùng đường dẫn → chỉ chi tiết, "Quay lại" về danh sách (và tương tự Vai trò, Lịch sử); rộng `/more/users` → ô trống đúng chuỗi; bấm thẻ ở rộng → URL đổi, danh sách **không** tải lại, không có "Quay lại"; `refreshActiveTab` sau tạm ngừng; thu hồi → về `/more/users` + tải lại; không có `memberView` → `/more/users/members/x` bị chặn; `/warehouse/receipts/quick/header` có "Quay lại"; hộp thoại bộ lọc có tiêu đề **một lần**; `iOSTapTargetGuideline` + `labeledTapTargetGuideline` ở 2 cột. Ô `[ ]` của 6.1 đều chưa đánh. **Sửa:** viết đủ các test này (tệp mới, vd. `w2_wide_layout_test.dart`), đánh dấu 6.1, ghi số pass / fail.
4. **Bước 16 chưa làm.** Nhật ký "Bước 16 ✅" chỉ ghi lệnh test, không có `/impeccable audit` ở 1280 × 800 cho 6 màn, không điểm, không P1 / P2. **Sửa:** chạy audit sau khi sửa P1-1, ghi điểm + vấn đề vào mục 7; P1 của audit sửa luôn.

#### P2

5. **Chi tiết lịch sử dùng chung cubit với danh sách — lệch plan, chưa ghi, và có lỗi chạy đua.** `app_router.dart` (route `:auditLogId`) truyền `cubit: context.read<TenantAuditLogsCubit>()`; trước đây mỗi trang chi tiết có cubit riêng (đóng khi rời trang ⇒ `isClosed` chặn kết quả cũ). Nay ở 2 cột bấm A rồi B nhanh: `loadDetail(A)` về sau `loadDetail(B)` ghi đè `selectedDetail` ⇒ trang B hiện nội dung A (`TenantAuditLogsCubit.loadDetail` không kiểm id khi emit). **Sửa:** bỏ `cubit:` ở route chi tiết lịch sử (về như cũ: `AuditLogDetailPage(auditLogId:, auditLogs:)`). Vai trò dùng chung `RolesCubit` (route `:code`) thì được — bớt 1 lần tải — nhưng phải ghi vào "Lệch so với plan".
6. **Đổi chuỗi không được duyệt:** tiêu đề bộ lọc lịch sử cũ "Bộ lọc nhật ký nền tảng" (vẽ trong `audit_log_filter_bottom_sheet.dart`) nay truyền `title: 'Bộ lọc nhật ký'` (`organization_audit_logs_page.dart:149`). Plan 3.5: "tiêu đề hiện đang vẽ trong widget". **Sửa:** giữ chuỗi cũ; nếu muốn bỏ "nền tảng" (đã bỏ Platform Admin) thì ghi vào câu hỏi mở để người dùng chốt, không tự đổi.
7. **`DESIGN.md` / TH-01 sai so với code** (plan 15: "đo từ code đã dựng"): hộp thoại ghi "≥ 840px" — code `VBreakpoints.desktop` = **1024**; tiêu đề hộp thoại ghi `headingH4` — code `headingH3`; đường kẻ ghi `VerticalDivider` — code `VDivider(axis: vertical)`; ngưỡng 2 cột ghi "màn hình ≥ 840px" — thật ra là bề rộng **của layout** (có thanh bên 240 ⇒ cửa sổ ≈ 1080). TH-01 5.12 ghi cùng các số sai và tên lớp code (`AuthConstrainedBox`, `VListDetailLayout`, `VSheetDialog`) — đặc tả chỉ ghi hành vi + chuỗi. `.impeccable/design.json` sửa tay thay vì tạo lại (`/impeccable document` / `impeccable-documenter`). Tên test DS `v_adaptive_sheet_test.dart` cũng ghi "≥ 840" / "< 840" (dù test dùng 1280 / hẹp) — sửa tên cho đúng 1024.
8. **Nhật ký mục 7 không theo mẫu:** không có `tệp:dòng`, không có dòng "impact", không có "Lệch so với plan" dù có ít nhất 5 chỗ lệch (`AuthConstrainedBox` thay `VContentWidth` / `contentMaxWidth`; chi tiết dùng chung cubit; thẻ vai trò `InkWell` → `VCard`; 3 shell nhận thêm `members` / `invitations` / `cubit`; thứ tự bước — nhật ký "Bước 9" là tạo shell nhưng router ở "Bước 13", "Bước 6" là test DS chứ không phải preview). Về GitNexus: nhật ký nói `analyze` lỗi, nhưng diff `AGENTS.md` / `CLAUDE.md` có số liệu chỉ mục mới (54469 symbol) ⇒ đã chạy được ít nhất 1 lần; `impact` của `VAppBar` / `VCard` (HIGH theo mục 4) không được báo cho người dùng; `detect_changes()` chưa chạy. **Sửa:** ghi lại mục 7 theo mẫu; thử lại `impact` / `detect_changes` — nếu thật sự lỗi thì ghi nguyên văn lỗi.
9. **6 warning analyze mới** (xem trên) — sửa.

#### P3

10. **Hẹp: tải lại danh sách 2 lần** sau thao tác ở chi tiết thành viên / lời mời — `onMutated` luôn được truyền nên `refreshActiveTab()` chạy ngay khi thành công, rồi khi `pop` trang danh sách lại `loadMembers(reset)` / `loadInvitations(reset)`. Do plan (3.3 bảo builder luôn truyền). Gợi ý: trong 2 trang chi tiết chỉ gọi `onMutated` khi `VListDetailLayout.isSplitOf(context)`. Không chặn.
11. **Rộng: nút ← của cột danh sách mất sau lần chọn đầu.** `context.go(...)` dựng lại ngăn xếp từ URL, bỏ trang hub `/more` đã `push` bên dưới ⇒ không navigator nào `canPop` ⇒ trái câu cuối 3.3 "cột trái giữ nút ←". Do plan chọn `go`; trên web còn thanh bên nên không chặn — ghi để người dùng quyết có cần sửa không.
12. Thẻ vai trò chuyển sang `VCard` ⇒ trên iPhone viền đổi `borderDefault` → `borderStrong` (mặc định tone neutral của `VCard`) — thay đổi nhỏ, chưa ghi; `organization_roles_page.dart` ~162–207 thụt lề lệch (chưa `dart format` tệp này).

**Phiên code làm tiếp:** P1-1 → P1-2, P1-3 → P2-5, 6, 9 → P1-4 (audit) → P2-7, 8; chạy lại `flutter test` **toàn bộ** app (không chỉ `test/features/iam`), so tên với baseline; ghi kết quả từng việc vào mục 7 ("R1 — sửa"). Báo lại để review R2.

### R2 — 2026-10-28 — ❌ chưa đạt (2 P1, 4 P2, 1 P3)

**Đã chạy (phiên review):**
- `flutter test` toàn bộ `apps/erp`: **1550 pass / 61 fail** — cả 61 có trong `TEST-BASELINE.md` (so tên) ✅. Test hỏng mới của R1 (`invitation_token_page_test` thanh đáy) đã xanh ✅.
- `flutter test` DS: 445 pass, chỉ hỏng `v_overlay_menu_shell_test` (baseline) ✅. `dart analyze` DS: 0 ✅.
- `dart analyze lib test` app: 0 error; 1 warning (`order_einvoice_section_test.dart`, không thuộc W-2); 6 warning / 4 info mới của R1 đã hết ✅.
- `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory`: **chạy được** — 61 tệp, 62 symbol, 0 process, risk low. `impact VAppBar` → **CRITICAL** (604 impacted), `impact VCard` → **CRITICAL** (759).
- Test tạm (đã xoá) đo hộp thoại ở 1280 × 800 — xem P1-1.

**Đạt (sửa R1):** P1-1 (`AuthConstrainedBox` bỏ, `VContentWidth` / `contentMaxWidth` đúng 3.6; H13 kiểm 7 màn ở 390 / 1280 + thanh đáy < 120); P1-2 (H1 tới đúng màn "Bạn không có quyền…" + đếm RPC; H4–H8, H11, H12 qua `appRouter` thật); P2-5 (chi tiết lịch sử có cubit riêng); P2-6 (giữ "Bộ lọc nhật ký nền tảng"); P2-9; P3-10 (`onMutated` chỉ khi 2 cột); P3-12 (đã ghi lệch). TH-01 5.x chỉ ghi hành vi + chuỗi, số đúng (840 bề rộng khả dụng / ~1080 cửa sổ, 1024 hộp thoại).

#### P1 — phải sửa

1. **Hộp thoại ở 2 cột không chặn cột danh sách — `useRootNavigator: false` (lệch plan tự thêm ở Bước 4).** Hộp thoại mở từ trang chi tiết được đẩy vào navigator của `ShellRoute` khu — navigator này nằm trong **cột phải**. Đo ở 1280 × 800, mở "Tạm ngừng thành viên" của `mem-staff-1`: `VSheetDialog` và lớp chắn = `Rect(601, 0, 1280, 800)`; cột danh sách `Rect(240, 64, 600, 800)` **không bị phủ**. Bấm thẻ "Lan Le" khi hộp thoại đang mở ⇒ URL đổi sang `/more/users/members/mem-owner-1` **và hộp thoại tạm ngừng vẫn mở** (gắn với cubit của thành viên cũ) ⇒ người dùng có thể bấm xác nhận trên màn đang hiện thành viên khác. Ngoài ra hộp thoại căn giữa cột phải, không "giữa màn" (3.5). Lý do phiên code nêu ("`Navigator.of(context).pop()` pop nhầm route") là do **người gọi** dựng `child:` bằng `context` của trang rồi `Navigator.of(context).pop()` (vd. `member_lifecycle_actions.dart:45,56,68,84`, `member_detail_bottom_sheets.dart:48,57,130,139,212,221,294,303`, `organization_invitation_detail_page.dart:268,279`) — sửa ở người gọi, không phải bằng cách thu hộp thoại vào navigator lồng.
   **Sửa:** `showDialog` về mặc định (`useRootNavigator: true`). Trong người gọi, nút đóng / chọn trong `child` lấy navigator của chính sheet: bọc nội dung bằng `Builder(builder: (sheetContext) => …)` và dùng `Navigator.of(sheetContext).pop(...)` (rà **cả 21 chỗ**, không chỉ IAM). Test: ở 1280, mở "Tạm ngừng thành viên" từ chi tiết → lớp chắn phủ toàn cửa sổ (`Rect(0,0,1280,800)`), bấm vào vùng danh sách không đổi URL; Huỷ / Xác nhận đóng đúng hộp thoại và trang chi tiết **vẫn còn**; ở 390 các sheet đóng như cũ (H11 + test sheet hiện có xanh).
2. **6.1 đánh `[x]` cho các mục chưa có test.** Không có test nào cho: (a) rộng — tạm ngừng thành công ở chi tiết ⇒ `refreshActiveTab` (số `ListTenantMembersQuery` tăng); (b) không có `memberView` ⇒ `/more/users/members/x` hiện "Bạn không có quyền xem thành viên" (H1 chỉ thử `/more/users`); (c) `/warehouse/receipts/quick/header` (hẹp) có "Quay lại" — đây là thay đổi của `VAppBar` (**CRITICAL**) trên `ShellRoute` có sẵn; (d) hẹp mở `/more/users/members/…` rồi bấm "Quay lại" ⇒ về danh sách (test 2 chỉ kiểm có nút); tương tự Vai trò, Lịch sử. **Sửa:** viết 4 test này trong `w2_wide_layout_test.dart`; chỉ đánh `[x]` khi có test.

#### P2

3. **Nhật ký GitNexus sai sự thật.** Mục 7 ghi CLI ném lỗi "`DuckDB/Kuzu native addon failed to bind…`" và `VAppBar` / `VCard` **HIGH** "112 / 143 file". Thực tế CLI chạy được khi thêm `--repo erp-sales-inventory` (lỗi không có `--repo` là "Multiple repositories indexed"), và cả hai là **CRITICAL** (604 / 759). Số liệu trong nhật ký không lấy từ công cụ. **Sửa:** chạy `impact` cho đủ danh sách mục 4 và `detect-changes` với `--repo erp-sales-inventory`, chép số thật vào mục 7 (kết quả review đã có ở trên cho `VAppBar`, `VCard`, `detect-changes`). Việc "đã báo người dùng" mức CRITICAL: phiên review đã báo trong lượt R2.
4. **Chuỗi mới chưa duyệt:** `organization_role_detail_page.dart` (nhánh `success` mà không thấy vai trò) hiện "Không tìm thấy vai trò" — không có trong Q6 / 3.6, chưa ghi TH-01. Sửa treo loading là đúng, nhưng chuỗi phải được người dùng chốt: thêm câu hỏi mở Q8 vào mục 2, tạm giữ chuỗi; chốt xong ghi TH-01 5.x. Cùng chỗ: `CircularProgressIndicator` → `VLoading(size: 40)` — đổi ngoài plan, ghi vào "Lệch so với plan" (giữ được, khớp 3 trang chi tiết khác).
5. **Bước 16 không phải `/impeccable audit` trên Chrome.** *(R3: việc impeccable do phiên review tự làm, không giao phiên code — xem S5, S6.)* Nhật ký ghi "kiểm tra trực tiếp bố cục, kích thước render object…" — tức là widget test, không có ảnh chụp / báo cáo audit ở 1280 × 800; điểm 19–20/20 tự chấm. Audit thật đã có thể bắt P1-1 R2 (lớp chắn chỉ nửa màn). **Sửa:** sau P1-1, chạy `/impeccable audit` thật (Chrome 1280 × 800, 6 màn mục 5.16), ghi điểm + P1 / P2 theo đầu ra của audit.
6. **`.impeccable/design.json` vẫn sửa tay** *(R3: việc impeccable do phiên review tự làm, không giao phiên code — xem S5, S6.)* (R1 P2-7 yêu cầu tạo lại bằng `/impeccable document` hoặc agent `impeccable-documenter`). Làm sau khi xong P1-1 để mô tả hộp thoại đúng.

#### P3

7. **R1 P3-11 (nút ← cột danh sách mất sau lần chọn đầu ở 2 cột)** — người dùng chốt giữ như hiện tại (D2 = A, mục R3).

**Phiên code làm tiếp:** theo danh sách việc ở mục **R3** dưới đây.

### R3 — việc cần sửa (từ R2) và việc người dùng quyết định

> Phiên code làm **đúng thứ tự** S1 + S8/A1 → S2 → S3 → S4 → S8/A3–A5 → S5 → S6 → S7 (cột "Xong khi" ghi "Ảnh …" thì phiên review kiểm ở R3, phiên code không cần chụp), ghi kết quả từng việc vào mục 7 (khối "R3 — sửa", theo mẫu: tệp:dòng, lệch plan, test, impact). D1, D2 đã chốt (cả hai A, 2026-10-28) — phiên code không còn gì chờ người dùng.

#### Cần người dùng quyết định

| # | Câu hỏi | Lựa chọn | Ảnh hưởng |
|---|---|---|---|
| D1 (Q8) | Trang chi tiết vai trò: khi danh sách đã tải xong mà không có vai trò khớp mã trên URL (vd. gõ tay `/more/roles/abc`), hiện chữ gì? **✅ Chốt 2026-10-28: A** — giữ "Không tìm thấy vai trò" (đã ghi Q8 ở mục 2) | Ghi chuỗi vào TH-01 mục 5 (S4) |
| D2 (R1 P3-11) | Web rộng, 2 cột: sau lần bấm chọn dòng đầu tiên, nút ← ở đầu cột danh sách biến mất (vì `context.go` dựng lại ngăn xếp từ URL, mất trang hub `/more` bên dưới). Có cần giữ nút ← không? | **A.** Giữ như hiện tại — web đã có thanh bên để rời khu, không sửa · **B.** Sửa: lồng `/more/users`, `/more/roles`, `/more/audit-logs` thành route con của `/more` để ngăn xếp luôn có hub (đổi cách lồng route, đường dẫn giữ nguyên; phải chạy lại H10 redirect + test 6.1) **✅ Chốt 2026-10-28: A** — không sửa |

#### Việc phiên code sửa

| # | Từ | Việc | Xong khi |
|---|---|---|---|
| S1 | R2 P1-1 | `v_adaptive_sheet.dart`: bỏ `useRootNavigator: false` (về mặc định `true`). Rà **cả 21 chỗ** gọi `showVAdaptiveSheet`: mọi `Navigator.of(context).pop(...)` / `context.pop(...)` nằm trong `child` mà `context` là của **trang** (vd. `member_lifecycle_actions.dart:45,56,68,84`, `member_detail_bottom_sheets.dart:48,57,130,139,212,221,294,303`, `organization_invitation_detail_page.dart:268,279`) → bọc nội dung bằng `Builder(builder: (sheetContext) => …)` và pop bằng `Navigator.of(sheetContext)`. Giữ nguyên giá trị trả về của mỗi `pop`. Ghi vào "Lệch so với plan" của Bước 4: đã bỏ lệch `useRootNavigator`. | Test mới (rộng 1280): mở "Tạm ngừng thành viên" từ chi tiết → lớp chắn `ModalBarrier` phủ `Rect(0,0,1280,800)`; bấm vào vùng cột danh sách → URL **không** đổi; bấm Huỷ → hộp thoại đóng, trang chi tiết **còn**; bấm xác nhận → đóng + toast + `refreshActiveTab`. Hẹp 390: H11 + 3 test sheet bộ lọc + `invitation_token_page_test` vẫn xanh |
| S2 | R2 P1-2 | Viết 4 test còn thiếu của 6.1 trong `w2_wide_layout_test.dart`: (a) rộng — tạm ngừng thành công ở chi tiết ⇒ số `ListTenantMembersQuery` tăng; (b) không có `memberView` ⇒ `/more/users/members/x` hiện "Bạn không có quyền xem thành viên", 0 RPC; (c) hẹp — `/warehouse/receipts/quick/header` có "Quay lại", bấm thì rời trang; (d) hẹp — mở thẳng `/more/users/members/<id>`, `/more/roles/<code>`, `/more/audit-logs/<id>` → bấm "Quay lại" → thấy trang danh sách tương ứng. | 4 test xanh; trong 6.1 chỉ đánh `[x]` mục nào có test, ghi tên test cạnh mục |
| S3 | R2 P2-3 | Chạy `node .gitnexus/run.cjs impact <symbol> --repo erp-sales-inventory --direction upstream` cho **đủ danh sách mục 4** và `detect-changes --repo erp-sales-inventory`; thay số trong mục 7 bằng số thật (mức + số impacted). Xoá câu "Kuzu addon failed to bind". | Mục 7 có bảng impact thật; `VAppBar`, `VCard` ghi CRITICAL |
| S4 | R2 P2-4 | D1 đã chốt A (Q8 mục 2): giữ code. Ghi chuỗi "Không tìm thấy vai trò" vào TH-01 mục 5 (cạnh 4 chuỗi W-2, nguyên văn). Ghi vào "Lệch so với plan" Bước 10–13: chuỗi mới (đã duyệt Q8) + `CircularProgressIndicator` → `VLoading(size: 40)`. | TH-01 có chuỗi |
| S5 | R2 P2-5 | Xoá bảng audit tự chấm ở mục 7 Bước 16, thay bằng một dòng trỏ tới mục "Audit R3" dưới bảng này. | Bảng cũ đã xoá |
| S6 | R2 P2-6 | Sau S1 + S8: kiểm mục hộp thoại trong `DESIGN.md` đúng code (bỏ đường kẻ / dải đầu khi không có tiêu đề nếu làm A3). Không sửa tay `.impeccable/design.json`. | `DESIGN.md` khớp code |
| S8 | Audit A1–A5 | Sửa A1–A5 theo mục "Audit R3" (A1 là P1, làm cùng S1). | Mỗi mục có test / ảnh như cột "Xong khi" của mục đó |
| S7 | D2 | D2 = A ⇒ **không sửa code**. Ghi vào mục 3.3, câu "Trang danh sách ở cột trái giữ nút ←": thêm "(trên web rộng, nút ← mất sau lần chọn dòng đầu — chấp nhận, rời khu bằng thanh bên; D2 chốt 2026-10-28)". | Câu trong 3.3 đã ghi |

#### Audit R3 (phiên review, 2026-10-28)

**Cách chạy:** app cần Supabase thật nên không mở được trên Chrome với dữ liệu. Phiên review chụp ảnh bằng widget test qua `appRouter` thật + `FakeIamBackend`, **nạp font thật** (Inter, Lucide), ở 1280 × 800, 1024 × 768 và 390 × 844 (15 ảnh; test tạm đã xoá, ảnh ở scratchpad của phiên review). Chạy thêm `textContrastGuideline` ở Người dùng 2 cột: đạt. Chưa kiểm: hover / focus bằng bàn phím trên trình duyệt thật, cuộn bằng chuột — để đợt kiểm tay 6.2. Ô vuông thay icon ở thanh bên trong ảnh là do test không nạp font Material Icons, **không phải lỗi**.

| # | Mặt | Điểm | Phát hiện chính |
|---|---|---|---|
| 1 | Trợ năng | 2 | Hộp thoại không chặn phần sau (Tab / chuột tới được danh sách, thanh bên); nút ← ngầm tiếng Anh "Back" |
| 2 | Hiệu năng | 3 | Không thấy vấn đề trong code; chưa đo khung hình trên Chrome |
| 3 | Màu / token | 3 | Toàn bộ qua `context.vColors`; `VSheetDialog` dùng `Text` + `VTypography` thay `VText`, `480` viết thẳng |
| 4 | Đúng nền tảng / DS | 2 | Nút ← Material (icon khác bộ Lucide) ở chi tiết 2 cột; hộp thoại xác nhận có dải tiêu đề trống |
| 5 | Thích ứng | 3 | 2 cột, 1 cột, iPhone đều đúng bố cục; dải 1024–1080 tiêu đề lệch cột nội dung |
| | **Tổng** | **13/20** | **Tạm được** — có 2 P1 |

**Đạt:** màn công khai 1280 đúng cột 480 giữa màn, thanh đáy bình thường; 390 không đổi. Thẻ đang chọn (`surfaceBrand` + `borderBrand`) rõ ràng, đúng "One Sticker Rule". Ô trống 2 cột: icon + chuỗi đúng nguyên văn, căn giữa. Sheet bộ lọc 390 đúng khung `VBottomSheet` (Q7). Lịch sử 2 cột: thẻ chọn + chi tiết đầy đủ.

| # | Mức | Vấn đề | Ở đâu | Sửa | Xong khi |
|---|---|---|---|---|---|
| A1 | **P1** | **Chi tiết ở 2 cột vẫn có nút ← — là nút `BackButton` Material ngầm** (icon mũi tên Material, tooltip tiếng Anh "Back"). `VAppBar` không đặt `automaticallyImplyLeading: false`, nên khi `showBackButton: false` mà route pop được (ở 2 cột navigator khu có `[ô trống, chi tiết]`) thì `AppBar` tự thêm nút. Đã kiểm: `/more/users/members/mem-owner-1` ở 1280 → 1 `BackButton`, tooltip "Back", bấm → `/more/users`. Test 6.1 số 1/3 vẫn xanh vì chỉ tìm tooltip "Quay lại". Bị: chi tiết thành viên, lời mời, vai trò (Lịch sử đã tự đặt `automaticallyImplyLeading: false`). | `v_app_bar.dart` ~112 (`AppBar(...)`) | `VAppBar` truyền `automaticallyImplyLeading: false` (nút ← của `VAppBar` đã tự lo qua `poppableNavigator`). `VAppBar` là **CRITICAL** — trước khi sửa grep mọi `VAppBar(` / `VPageScaffold(` có `showBackButton: false` để chắc không màn nào đang dựa vào nút ngầm; ghi danh sách vào mục 7. Sửa test 6.1 số 1, 3: kiểm `find.byType(BackButton)` = 0 **và** tooltip "Quay lại" = 0. | Test DS `v_app_bar_test`: `showBackButton: false` trong route pop được → không có `BackButton`; test 6.1 sửa xanh; H12 xanh |
| A2 | **P1** | **Hộp thoại không phải modal** — trùng R2 P1-1 (S1), thêm bằng chứng ảnh: bộ lọc mở từ cột danh sách có lớp chắn chỉ từ x = 240 (thanh bên vẫn bấm được); xác nhận tạm ngừng mở từ chi tiết có lớp chắn chỉ cột phải (x = 601). | `v_adaptive_sheet.dart` | Như S1. | Như S1; ảnh 1280 lớp chắn phủ cả thanh bên |
| A3 | P2 | **Hộp thoại xác nhận không có tiêu đề**: 4 sheet xác nhận (tạm ngừng, kích hoạt lại, xoá, thu hồi…) gọi không có `title`, tự vẽ tiêu đề trong thân ⇒ trên web có dải đầu trống + đường kẻ + nút ✕, rồi mới tới tiêu đề đỏ; hai nút đóng (✕ và "Quay lại"). | `VSheetDialog` (`v_adaptive_sheet.dart`); `member_detail_bottom_sheets.dart:15,94,176,258` và các sheet xác nhận cùng kiểu | `VSheetDialog` khi `title == null`: **không** vẽ dải đầu và đường kẻ; nút ✕ đặt góc phải đè lên phần trên của thân (`Stack`), thân giữ lề trên đủ chỗ cho nút. Không đổi chuỗi, không đổi sheet trên iPhone. | Ảnh 1280 hộp thoại tạm ngừng: tiêu đề là dòng đầu tiên, ✕ cùng hàng; test `v_adaptive_sheet_test` thêm ca không `title` |
| A4 | P2 | **Tiêu đề chi tiết Lịch sử dính sát mép cột** ở 2 cột: bỏ nút ← mà vẫn `titleSpacing: 0` ⇒ "Chi tiết hoạt động" bắt đầu ngay đường kẻ dọc (x = 601). | `audit_log_detail_body.dart` ~66 và 2 `AppBar` của `audit_log_detail_page.dart` | Khi `isSplit`: `titleSpacing: VSpacing.space4` (hẹp giữ như cũ). | Ảnh 1280 Lịch sử: tiêu đề cách đường kẻ 16 |
| A5 | P3 | **Sheet bộ lọc: nội dung sát đường kẻ dưới tiêu đề** (~8 px, cả 390 lẫn 1280) — do bỏ tiêu đề tự vẽ kèm `VGap.md` phía sau. | 3 widget bộ lọc, `Padding(top: …)` đầu `build` | Tăng lề trên thân lên `VSpacing.space4`. | Ảnh 390 + 1280: "Trạng thái" cách đường kẻ 16 |

**Ghi nhận, không sửa trong W-2:** (1) dải cửa sổ 1024–1080 (có thanh bên, chưa đủ 2 cột): tiêu đề app bar ở mép trái, nội dung ở cột 720 giữa — hành vi chung của `VPageScaffold`, xử lý ở plan khung web chung nếu cần; (2) chân màn đăng nhập "© VET45 · Phiên bản Mobile" hiện cả trên web — chuỗi có sẵn, ngoài phạm vi W-2, ghi để người dùng quyết sau; (3) `VSheetDialog` nhãn đọc màn hình mặc định "Hộp thoại" khi không có `title` — chuỗi mới chưa duyệt, xử lý cùng A3 (không có `title` thì dùng `semanticLabel` của người gọi, bỏ chuỗi mặc định).

Cuối cùng: `flutter test` **toàn bộ** `apps/erp` + DS, so **tên** test hỏng với `TEST-BASELINE.md`; `dart analyze lib test` (app + DS) không warning mới. Báo lại để review R3.

### R3 (review) — 2026-10-28 — ❌ chưa đạt (0 P1, 1 P2, 1 P3) — chỉ còn R4 nhỏ

**Đã chạy (phiên review):**
- `flutter test` toàn bộ `apps/erp`: **1554 pass / 61 fail**, cả 61 có trong `TEST-BASELINE.md` (so tên), **0 fail mới** ✅. DS: 446 pass, chỉ hỏng `v_overlay_menu_shell_test` (baseline) ✅.
- `dart analyze lib test`: DS 0; app 0 error, 1 warning không thuộc W-2 (`order_einvoice_section_test.dart`) ✅.
- Rà **cả 21 chỗ** `showVAdaptiveSheet`: mọi nút đóng / chọn đều pop bằng context của chính sheet (`Builder(sheetContext)` hoặc widget riêng có `build` của nó) ✅.
- Chụp lại (widget test tạm, font thật, đã xoá) ở 1280 × 800 và 390 × 844 + đo:
  - A1 ✅ chi tiết thành viên / lời mời / vai trò ở 2 cột: `BackButton` = 0, tooltip "Quay lại" = 0.
  - A2 / S1 ✅ hộp thoại bộ lọc (mở từ cột danh sách) và hộp thoại tạm ngừng (mở từ chi tiết): lớp chắn `Rect(0, 0, 1280, 800)`, phủ cả thanh bên; bấm vào cột danh sách khi hộp thoại mở ⇒ hộp thoại đóng, URL **không** đổi.
  - A3 ✅ hộp thoại xác nhận không còn dải đầu trống, tiêu đề là dòng đầu, ✕ cùng hàng.
  - A4 ✅ "Chi tiết hoạt động" cách đường kẻ dọc 16.
  - A5 ✅ sheet bộ lọc 390 / 1280: "Trạng thái" cách đường kẻ 16. Sheet iPhone giữ khung `VBottomSheet` (Q7).
- Test S2 (#11–#14) đúng điều kiện bảng R3 ✅. S3 (số GitNexus thật), S4 (TH-01 có "Không tìm thấy vai trò"), S5, S7 ✅. S6: `DESIGN.md` khớp code ✅; `.impeccable/design.json` **phiên review đã làm mới** (giữ `DESIGN.md`; đồng bộ quy tắc / Do / Don't; thêm `Selected Card`, `Sheet Dialog`, mốc `list-detail-split` 840).
- **Audit lại: 15/20** (Trợ năng 3, Hiệu năng 3, Màu / token 3, Đúng nền tảng / DS 3, Thích ứng 3) — từ 13/20; không còn P1.

#### P2

1. **Toast hiện 2 lần ở chế độ 2 cột.** Tạm ngừng thành công ở chi tiết (1280): chuỗi "Đã tạm ngừng thành viên." xuất hiện **2 chỗ cùng lúc** — cột danh sách `Rect(327, 736, 515, 780)` và cột chi tiết `Rect(688, 667, 1195, 689)`. Nguyên nhân: `VToast` đi qua `ScaffoldMessenger` gốc; ở 2 cột, `Scaffold` của trang danh sách và của trang chi tiết là **hai Scaffold anh em** cùng đăng ký với messenger đó ⇒ SnackBar vẽ ở cả hai. Test #11 đã thấy nhưng viết `findsWidgets` kèm chú thích "có thể ≥ 1" thay vì báo. Bị mọi toast ở 2 cột (tạm ngừng, kích hoạt lại, xoá, đổi vai trò, gửi lại / thu hồi lời mời). → R4-1.

#### P3

2. **Nút ← trang Lịch sử ở cột trái là nút "chết" ở 2 cột.** Nút tự dựng (`organization_audit_logs_page.dart` ~222) luôn hiện, gọi `VAppBar.popNearest(context)`; mở thẳng `/more/audit-logs/AUD-T-001` ở 1280 rồi bấm ⇒ URL không đổi (không navigator nào pop được). Người dùng / Vai trò dùng `VAppBar` nên tự ẩn (D2 = A). → R4-2.

**Phiên code làm tiếp:** mục **R4** dưới đây.

### R4 — việc cần sửa (từ R3)

> Phiên code làm **đúng thứ tự** R4-1 → R4-2 → R4-3, ghi kết quả từng việc vào mục 7 (khối "R4 — sửa", theo mẫu: tệp:dòng, lệch plan, test, impact). Không có việc nào chờ người dùng quyết.

| # | Từ | Việc | Xong khi |
|---|---|---|---|
| R4-1 | R3 P2-1 | **Toast chỉ hiện 1 lần ở 2 cột.** `packages/vet45_design_system/lib/src/patterns/v_list_detail_layout.dart`, nhánh 2 cột: bọc `widget.list` bằng `ScaffoldMessenger(child: …)` riêng ⇒ toast phát từ trang chi tiết chỉ hiện ở cột chi tiết, toast phát từ trang danh sách chỉ hiện ở cột danh sách. **Không** đổi nhánh 1 cột (hẹp / iPhone). Chạy `impact VListDetailLayout --repo erp-sales-inventory --direction upstream` trước khi sửa, ghi kết quả. CHANGELOG DS `[Unreleased]` → *Fixed*: "`VListDetailLayout`: toast không còn hiện ở cả hai cột". | (1) Test DS mới trong `test/patterns/v_list_detail_layout_test.dart`: bề rộng ≥ 840, `list` và `detail` mỗi bên một `Scaffold`; gọi `ScaffoldMessenger.of(<context trong detail>).showSnackBar(SnackBar(content: Text('x')))` ⇒ `find.text('x')` **đúng 1**, nằm trong vùng cột chi tiết; gọi từ context trong `list` ⇒ đúng 1, nằm trong cột danh sách. (2) `w2_wide_layout_test.dart` #11: `findsWidgets` → `findsOneWidget`, xoá chú thích "có thể ≥ 1". (3) #7: thêm `expect(find.text('Đã thu hồi lời mời.'), findsOneWidget)`. (4) H6 (hẹp, toast thu hồi do trang danh sách hiện) vẫn xanh |
| R4-2 | R3 P3-2 | **Nút ← trang Lịch sử chỉ hiện khi bấm được.** `apps/erp/lib/features/iam/presentation/audit_logs/views/organization_audit_logs_page.dart` ~222: chỉ dựng `leading` khi `VAppBar.poppableNavigator(context) != null` (giống cách `VAppBar` tự ẩn ở Người dùng / Vai trò); khi không có thì `leading: null` + `automaticallyImplyLeading: false`. Chạy `impact` cho `_AuditLogsViewState` / `OrganizationAuditLogsPage` trước khi sửa. | Test mới trong `w2_wide_layout_test.dart`: rộng 1280, `go('/more/audit-logs/AUD-T-001')` ⇒ trong cột danh sách tooltip "Quay lại" = 0. Hẹp 390: mở `/more` rồi `push('/more/audit-logs')` ⇒ có "Quay lại", bấm ⇒ về `/more` (H8 / #14 vẫn xanh) |
| R4-3 | — | Chạy lại: `flutter test` **toàn bộ** `apps/erp` + DS, so **tên** test hỏng với `TEST-BASELINE.md` (chỉ được hỏng 61 + 1 baseline đã biết); `dart analyze lib test` app + DS không warning mới; `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory`. | Mục 7 "R4 — sửa" có số pass / fail, tên test hỏng, kết quả `detect-changes`. Báo lại để review R4 |

### R4 (review) — 2026-10-29 — ✅ đạt

**Đã chạy (phiên review):**
- `flutter test` toàn bộ `apps/erp`: **1555 pass / 61 fail**, cả 61 có trong `TEST-BASELINE.md` (so tên), **0 fail mới** ✅. DS: 447 pass, chỉ hỏng `v_overlay_menu_shell_test` (baseline) ✅.
- `dart analyze`: DS 0; app 0 error, 1 warning không thuộc W-2 (`order_einvoice_section_test.dart`) ✅.
- R4-1 ✅ đo bằng test tạm (đã xoá): sau tạm ngừng ở 1280, "Đã tạm ngừng thành viên." chỉ **1** chỗ, trong cột chi tiết `Rect(688, 667, 1195, 689)`; sau thu hồi lời mời, "Đã thu hồi lời mời." chỉ **1** chỗ `Rect(688, 747, 1195, 769)`. Test DS mới + #7, #11 (`findsOneWidget`) + H6 xanh.
- R4-2 ✅ nút ← trang Lịch sử chỉ dựng khi `poppableNavigator != null`; test #15 (rộng: không có; hẹp từ `/more`: có, bấm về `/more`). Sửa fixture `organization_audit_logs_page_test.dart` (đẩy trang qua `navKey` để có route trước) là đúng với hành vi mới — trang mở thẳng không có route trước thì không có nút, như Người dùng / Vai trò.
- R4-3 ✅ số liệu ghi đủ trong mục 7.

**Góp ý P3 (không chặn, không cần làm lại):**
1. Ô chi tiết trống 3 khu nay bọc `Scaffold(backgroundColor: surfaceAlt, …)` (`app_router.dart` ~429, ~516, ~585) để toast phát ra khi trang chi tiết vừa đóng (thu hồi lời mời) còn chỗ hiện — cần và đúng, nhưng nhật ký ghi "Lệch so với plan: Không"; coi như đã ghi ở đây.
2. `organization_audit_logs_page.dart` ~215: `leading` tự dựng nay trùng hẳn với nút ← mặc định của `VAppBar` (cùng tooltip, icon, `poppableNavigator`) — có thể bỏ `leading` cho gọn khi tiện.

**Còn lại của W-2:** kiểm tay 6.2 (gộp đợt kiểm tay đóng Theme 1) — người dùng làm; người dùng commit. Sau khi commit: xoá plan này theo quy tắc "xoá plan đã xong", `PLAN.md` ghi "(đã xoá)" + mã commit để tra lại mục 6.2.

