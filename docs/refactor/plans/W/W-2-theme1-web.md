# W-2 — Theme 1 trên web: màn công khai cột hẹp, danh sách – chi tiết, sheet thành hộp thoại

> Phase: Web cho app (W) · Trạng thái: Plan ✅ (viết + duyệt 2026-10-28; bổ sung cùng ngày sau rà theo quy tắc "test giữ hành vi trước") | Làm ⬜ | Review ⬜
> Gồm việc: W.5, W.6 ([PLAN mục "Web cho app"](../../PLAN.md)). Ước lượng **~1,5 ngày, 3 nhóm việc** (mục 5). **Không tự commit** — người dùng commit.
> **Làm sau W-1** ([W-1](W-1-khung-web.md): `StoreShell`, thanh bên, tab có URL). Làm chồng lên 2-B6 / 2-B7 / W-1 nếu các plan đó chưa commit: không revert, không format lại tệp của chúng.
> Tài liệu liên quan: [LUONG-UNG-DUNG 1.1](../../../02-yeu-cau/LUONG-UNG-DUNG.md) (bố cục web chung), [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md), [2-B6](../P2/2-B6-ui-ux-auth.md), [2-B7](../P2/2-B7-ui-ux-iam.md), prototype Theme 7 khuôn K7 (`specs/themes/theme-07/03.design/prototype/html/app/shared-patterns.js` `k7Split`).

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
  - Trang danh sách ở cột trái giữ nút ← (rời khu, về hub) — xem 3.4.
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
- [ ] `dart analyze lib test` (app + DS): không lỗi / warning mới.
- [ ] DS `v_list_detail_layout_test` (tạo): rộng 1000 → có `list` và `detail`, `isSplitOf` = true trong cả hai; rộng 800 → chỉ `detail`, `list` không dựng, `isSplitOf` = false; đổi bề rộng qua ngưỡng không mất state của `detail` (dùng `StatefulWidget` đếm).
- [ ] DS `v_card_test`: `isSelected: true` → nền `surfaceBrand`, viền `borderBrand`, semantics `isSelected`; `null` → như cũ.
- [ ] DS `v_app_bar_test`: navigator lồng (một `Navigator` con trong trang thứ 2 của navigator cha): trang gốc của navigator con có `VAppBar(showBackButton: true)` → có nút "Quay lại"; bấm → navigator cha pop. Navigator gần nhất pop được → pop navigator đó (như cũ). Không navigator nào pop được → không có nút.
- [ ] DS `v_adaptive_sheet_test` (tạo): cửa sổ 1280 → `Dialog` + `VSheetDialog`, có tooltip "Đóng", giá trị `pop(x)` trả về `x`, `Esc` đóng khi `isDismissible`; cửa sổ 390 → `VBottomSheet` như `showVBottomSheet`.
- [ ] App router: rộng 1280 mở `/more/users/members/m1` → có danh sách **và** chi tiết, thẻ `m1` `isSelected`; hẹp 390 mở cùng đường dẫn → chỉ chi tiết, bấm "Quay lại" → danh sách. Tương tự `/more/roles/<code>`, `/more/audit-logs/<id>`. Rộng 1280 mở `/more/users` → ô trống "Chọn một thành viên hoặc lời mời để xem chi tiết.".
- [ ] Rộng: bấm thẻ thành viên → đường dẫn đổi (`GoRouter.of(context).routerDelegate.currentConfiguration.uri`), danh sách **không** tải lại (đếm lời gọi repository giả), chi tiết không có nút "Quay lại". Hẹp: bấm thẻ → chi tiết che danh sách như cũ.
- [ ] Rộng: thao tác thành công ở chi tiết thành viên (vd. tạm ngừng) → `refreshActiveTab` được gọi; thu hồi lời mời → về `/more/users` + danh sách tải lại.
- [ ] Đường dẫn cũ vẫn redirect: `/more/users/member-detail` → `/more/users`, `/more/roles/detail` → `/more/roles`, `/more/audit-logs/detail` → `/more/audit-logs`; `/more/users/invite` mở form mời.
- [ ] Kiểm quyền giữ: không có `memberView` → `/more/users/members/x` hiện "Bạn không có quyền xem thành viên".
- [ ] Trang đầu `ShellRoute` có sẵn: `/warehouse/receipts/quick/header` (hẹp) có nút "Quay lại".
- [ ] Sheet: rộng 1280, mở bộ lọc thành viên → `VSheetDialog` có tiêu đề "Bộ lọc thành viên" **một lần** (không trùng), áp dụng → đóng + lọc; hẹp → bottom sheet như cũ. Một sheet xác nhận (tạm ngừng) ở rộng → hộp thoại.
- [ ] Màn công khai: rộng 1280, đăng nhập / đăng ký / xác minh / nhập mã lời mời / chưa có tổ chức / quên mật khẩu → nội dung rộng ≤ 480, căn giữa.
- [ ] `meetsGuideline(iOSTapTargetGuideline)` + `labeledTapTargetGuideline` cho Người dùng ở rộng 1280 (2 cột).
- [ ] `flutter test` cả `apps/erp` + DS: chỉ hỏng các test có sẵn (so **tên** với `docs/refactor/TEST-BASELINE.md`; 2 test catalog `product_measurement_units_e2e_test` `e2e_e04_u02_fr01_01b` / `e2e_e04_u02_fr01_03` hỏng sẵn, chưa có trong baseline; DS chỉ `v_overlay_menu_shell_test`).
- [ ] `detect_changes()` — tách phần W-2 với phần 2-B6 / 2-B7 / W-1 chưa commit.

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

_(chưa có)_

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

(Phiên review điền sau khi bạn báo xong.)
