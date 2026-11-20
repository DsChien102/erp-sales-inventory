# 4-W — Theme 3 trên web: danh sách – hồ sơ hai cột, sheet thành hộp thoại

> Theme 3 (mã cũ P4) · Bố cục web (quy tắc Thiết bị 2026-10-20, TH-03 mục 5.9) · Làm **sau** [4-B](4-B-sua-ki-th03.md)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ✅ (2026-11-01, chưa commit) | Review ✅ R2 (2026-11-02; đã sửa R1-1, R1-2 của R1) · còn: kiểm tay 6.2 (người dùng), `analyze` + `detect_changes()` rồi commit
> Dùng lại của W-2 (đã có trong DS): `VListDetailLayout`, `VListDetailLayout.isSplitOf`, `VCard.isSelected`, `showVAdaptiveSheet`, `VAppBar.popNearest`. Mẫu app: `apps/erp/lib/features/iam/presentation/users/users_area_shell.dart` và khối `ShellRoute` của `/more/users` trong `app_router.dart`.
> Đường dẫn tệp là đường **sau 4-A / 4-B** (cubit ở `features/partner/logic/`). Số dòng ghi "≈" đo trên code trước 4-A, chỉ để tìm chỗ.

## 1. Mục tiêu

**Web rộng** (bề rộng vùng nội dung ≥ 840, tức cửa sổ ≥ ~1080 khi có thanh bên):

- Tab KH & NCC chia 2 cột: trái là danh sách, phải là hồ sơ đang chọn.
- URL đổi theo dòng chọn (`/partner/:id`); mở thẳng URL thì ra đúng 2 cột với dòng đó được chọn.
- Mọi sheet của partner thành hộp thoại giữa màn (≥ 1024), đóng bằng Esc.

**Hẹp / iPhone:** như hiện tại, trừ một đổi có chủ đích (Q1): hồ sơ nay nằm trong tab, nên thanh tab dưới vẫn hiện khi xem hồ sơ.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Dựng route 2 cột thế nào khi danh sách là một tab | **Người dùng chốt 2026-11-01: hồ sơ nằm trong tab.** `/partner/:partnerId` thành route con của `/partner` trong `StatefulShellBranch` của tab. iPhone: xem hồ sơ vẫn thấy thanh tab dưới |
| Q2 | Các màn con (sửa / tạo, người liên hệ, form người liên hệ, chọn cá nhân, chuyển đổi, lịch sử thao tác) | **Đề xuất, duyệt plan là chốt:** giữ route gốc **toàn màn** như hiện tại, trên web nằm trong cột 720 của `VPageScaffold` (giống form của Theme 1, W-2 mục 3.7). Không đổi bố cục |
| Q3 | Bảng (`VTable`) cho danh sách / người liên hệ / lịch sử | **Đề xuất:** không. Không có cột số; dùng danh sách thẻ như iPhone (W-2 Q4, LUONG 1.1) |
| Q4 | Chuỗi mới | **Đề xuất (nguyên văn):** ô chi tiết trống "Chọn một KH & NCC để xem chi tiết." Không có chuỗi mới nào khác |

## 3. Thiết kế

### 3.1 Cây route (`apps/erp/lib/core/router/app_router.dart`)

**Hiện tại:**

- Tab KH & NCC: `StatefulShellBranch(routes: [GoRoute('/partner', name: 'partner.list', builder: PartnerListPage)])` (≈ dòng 234–241).
- 9 route `/partner/...` cấp gốc, khai báo **sau** `ShellRoute(StoreShell)` (≈ dòng 797–949).

**Sau khi sửa:**

```text
GoRoute /partner/new                               (name partner.new)              ← chuyển lên TRƯỚC ShellRoute(StoreShell)
GoRoute /partner/:partnerId/edit                   (partner.edit)                  ← chuyển lên TRƯỚC
GoRoute /partner/:partnerId/transform              (partner.transform)             ← chuyển lên TRƯỚC
GoRoute /partner/:partnerId/history                (partner.history)               ← chuyển lên TRƯỚC
GoRoute /partner/:partnerId/contacts               (partner.contacts)              ← chuyển lên TRƯỚC
GoRoute /partner/:partnerId/contacts/new           (partner.contacts.new)          ← chuyển lên TRƯỚC
GoRoute /partner/:partnerId/contacts/select        (partner.contacts.select)       ← chuyển lên TRƯỚC
GoRoute /partner/:partnerId/contacts/:contactId/edit (partner.contacts.edit)       ← chuyển lên TRƯỚC
ShellRoute(StoreShell)
└─ StatefulShellRoute.indexedStack
   └─ StatefulShellBranch (tab KH & NCC)
      └─ ShellRoute  builder: PartnerAreaShell          ← kiểm quyền + BlocProvider<PartnerListCubit> + VListDetailLayout
         └─ GoRoute /partner           (partner.list)   → PartnerListRoute
            └─ GoRoute :partnerId      (partner.detail) → PartnerDetailPage(key: ValueKey(partnerId), …)
```

- **Vì sao chuyển 8 route lên trước:** go_router so route theo thứ tự khai báo. Để `/partner/:partnerId` lồng trong tab mà nằm trước thì `/partner/new` sẽ khớp `:partnerId = 'new'`; các đường `/partner/x/edit` cũng có thể bị nhánh tab giữ. Đặt 8 route cụ thể **trước** `ShellRoute(StoreShell)` là chúng khớp trước. **Thân builder giữ nguyên** (tham số, `extra`, redirect của `/transform` khi thiếu `extra`).
- `GoRoute /partner/:partnerId` cấp gốc cũ: **xoá** (thay bằng route con). Builder con giữ nguyên việc đọc `?created=1` / `?transformed=1` và truyền `repository`. Thêm:
  - `key: ValueKey(partnerId)`: ở chế độ 2 cột, `go` từ hồ sơ A sang B dựng lại trang, không giữ `State` của A;
  - `onMutated: () => context.read<PartnerListCubit>().fetchPartners(isRefresh: true)` (mục 3.4).
- **`PartnerAreaShell` builder** (khai báo trong `app_router.dart`, gọi widget):
  - Không có quyền `PartnerPermissions.view` (`getIt<SessionController>().hasPermission`) → trả `PartnerNoPermissionView()` cho cả khu. Không `BlocProvider`, không gọi RPC.
  - Còn lại → `PartnerAreaShell(selectedId: state.pathParameters['partnerId'], child: child)`.
- **`PartnerListRoute`** (builder của `/partner`):
  - `VListDetailLayout.isSplitOf(context)` → ô trống (Q4): `Scaffold(backgroundColor: context.vColors.surfaceAlt, body: Center(child: VEmptyState(child: VEmptyHeader(children: [VEmptyMedia(icon: VIcons.info), VEmptyTitle('Chọn một KH & NCC để xem chi tiết.')]))))`, chép khung của `/more/users`;
  - ngược lại → `PartnerListPage(cubit: context.read<PartnerListCubit>())`.
- `erp_bottom_navigation.dart` (`location.startsWith('/partner')`): không đổi. Route gốc `/partner/x/edit` vẫn bắt đầu bằng `/partner`.

### 3.2 `PartnerAreaShell` (tạo `apps/erp/lib/features/partner/presentation/partner_area_shell.dart`)

Chép khung `UsersAreaShell`:

- Tham số: `child`, `selectedId`, `repository` (mặc định `getIt<PartnerRepository>()`), `cubit` (cho test).
- `BlocProvider(create: (_) => PartnerListCubit(repository: …)..fetchPartners())`. **Chuyển nguyên** lời tạo cubit và lời gọi tải đầu tiên khỏi `PartnerListPage.initState`.
- `VListDetailLayout(list: PartnerListPage(cubit: c, selectedId: selectedId), detail: child)`.

### 3.3 `PartnerListPage` (`presentation/pages/partner_list_page.dart`)

- Tham số mới: `final PartnerListCubit? cubit;`, `final String? selectedId;`.
  - Có `cubit` → dùng nó, **không** `close()` trong `dispose`.
  - Không có → tự tạo như cũ. Test cũ và trang hẹp khi dựng ngoài shell vẫn chạy.
- Nhánh không có quyền (`!canView`, ≈ dòng 121–150): tách thân `VPageScaffold` đó thành widget public `PartnerNoPermissionView` (cùng tệp hoặc `widgets/partner_no_permission_view.dart`). Giữ key `wgt_e01_u02_fr01_02` và chữ. Trang vẫn gọi nó khi `!canView`; shell cũng gọi (3.1).
- `_openPartnerDetail(id)`:
  - `isSplitOf(context)` → `context.go('/partner/$id')`, không chờ, không tải lại (hồ sơ tự báo qua `onMutated`);
  - ngược lại → **giữ nguyên** `await context.push<bool>('/partner/$id')` + tải lại + toast xoá.
- `_openCreateFlow`: phần mở form và tải lại giữ. Khi có `createdPartnerId`:
  - `isSplitOf` → `context.go('/partner/$createdPartnerId?created=1')`;
  - ngược lại → giữ `await context.push(...)` + tải lại.
- Truyền `selectedId` xuống `PartnerListBody` → `PartnerListItemTile(isSelected: item.partnerId == selectedId)` → `VCard(isSelected: isSelected ? true : null, …)`.

### 3.4 `PartnerDetailPage` (`presentation/pages/partner_detail_page.dart`)

- Tham số mới `final VoidCallback? onMutated;`.
- `VPageScaffold(showBackButton: !VListDetailLayout.isSplitOf(context), …)`.
- Gọi `widget.onMutated?.call()` sau mỗi thao tác đổi dữ liệu đang hiện ở danh sách:
  - sửa thành công (`updated == true`, ≈ dòng 69–74);
  - chuyển đổi thành công (`transformed == true`, ≈ dòng 171);
  - ngừng hoạt động / kích hoạt lại thành công (listener `_onStatusSubmitChanged`, ≈ dòng 231–235).
- **Xoá thành công** (≈ dòng 221–228, đang `canPop ? pop(true) : toast + go('/partner')`):
  - `isSplitOf` → `showPartnerSoftDeleteSuccessToast(context); widget.onMutated?.call(); context.go('/partner');`;
  - ngược lại giữ như cũ.
- **Mở tổ chức** từ sheet chặn (≈ dòng 196, 211, `await context.push('/partner/$organizationId')`):
  - `isSplitOf` → `context.go('/partner/$organizationId')`;
  - ngược lại giữ `push`.
- Nút "Quay lại" ở trạng thái lỗi (≈ dòng 280, 295, `context.pop()`): `isSplitOf` → `context.go('/partner')`; ngược lại giữ.
- Thanh "Thao tác" dính đáy: giữ nguyên. Ở 2 cột nó nằm đáy cột phải.

### 3.5 Sheet → hộp thoại

`showVBottomSheet` và `showVAdaptiveSheet` cùng chữ ký (`context, title, child, tone, semanticLabel, isDismissible, enableDrag`). Đổi **tên hàm**, giữ nguyên tham số, ở **đúng 18 chỗ** (grep 2026-11-01, `apps/erp/lib/features/partner/presentation/widgets/`):

`partner_reactivate_confirmation_sheet.dart:6`, `partner_create_action_sheet.dart:6`, `partner_contact_remove_dialog.dart:5`, `partner_contact_add_method_sheet.dart:9`, `partner_detail_action_sheet.dart:12`, `partner_duplicate_sheet.dart:14`, `partner_administrative_unit_picker_sheet.dart:19`, `partner_leave_form_dialog.dart:8`, `partner_contact_action_sheet.dart:12`, `partner_transform_primary_contact_blocked_sheet.dart:10`, `partner_contact_change_primary_dialog.dart:9`, `partner_deactivate_confirmation_sheet.dart:10`, `partner_soft_delete_confirmation_sheet.dart:7`, `partner_delete_primary_contact_blocked_sheet.dart:10`, `partner_delete_blocked_sheet.dart:20`, `partner_filter_bottom_sheet.dart:28`, `partner_sort_bottom_sheet.dart:18`, cùng mọi chỗ khác do grep `showVBottomSheet(` trong `features/partner` tìm ra lúc làm. Ghi số chỗ thực tế vào Kết quả.

- `partner_operation_feedback_state.dart:165` đang `showDialog`: giữ.
- Nội dung sheet tự `Navigator.of(context).pop(...)`: giữ (hộp thoại cũng là route).

### 3.6 Bàn phím

- Thẻ danh sách (`VCard` có `onTap`) nhận Tab / Enter sẵn có: kiểm, không sửa nếu đã đạt.
- Hộp thoại đóng bằng Esc (mặc định của `showDialog` khi `isDismissible`).
- Ô tìm kiếm danh sách: Tab vào được.

## 4. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| W1 | `PartnerListPage.initState` tạo `PartnerListCubit` và `fetchPartners()`; `dispose` đóng cubit | `PartnerAreaShell` tạo + tải (3.2). Trang chỉ tự tạo khi không được truyền `cubit` | widget test: dựng qua router `/partner` → `search` gọi **1** lần; rời tab rồi quay lại không tạo cubit thứ hai (`calls` của `FakePartnerRepository`) |
| W2 | Không có quyền `partner.view` → `VPageScaffold` key `wgt_e01_u02_fr01_02` | shell trả `PartnerNoPermissionView` (cùng key, cùng chữ). Thêm: `/partner/:id` cũng bị chặn | widget test: không quyền → thấy key; mở `/partner/p-1` → thấy key, **không** gọi `getDetail` |
| W3 | Chọn dòng → `push` → quay về → tải lại; `pop(true)` → toast xoá | hẹp: giữ. Rộng: `go` | bước 0 (code cũ): chọn dòng, xoá hồ sơ → quay về danh sách, toast "…xóa…", danh sách tải lại. Sau sửa, chạy ở bề rộng 390 (hẹp) phải xanh y hệt |
| W4 | Tạo xong → `push('/partner/:id?created=1')` → toast tạo | hẹp: giữ. Rộng: `go` | bước 0: tạo cá nhân → thấy hồ sơ mới + toast tạo (390) |
| W5 | Hồ sơ: sửa / chuyển đổi xong thì tải lại hồ sơ + toast; ngừng / kích hoạt thì toast | giữ + gọi `onMutated` | bước 0: ngừng hoạt động → toast; sửa → toast (390). Sau sửa thêm ở 1280: `onMutated` → danh sách tải lại |
| W6 | Xoá xong: `canPop ? pop(true) : toast + go('/partner')` | hẹp giữ; rộng: toast + `onMutated` + `go('/partner')` | bước 0: mở thẳng `/partner/p-1`, xoá → toast + về `/partner` (390). Sau sửa thêm ở 1280: ô phải về trống, danh sách tải lại |
| W7 | Sheet chặn → "Xem tổ chức" → `push('/partner/<org>')` | hẹp giữ; rộng `go` | bước 0: người là liên hệ chính → chặn chuyển đổi → "Xem tổ chức" → thấy hồ sơ tổ chức (390) |
| W8 | 8 route con cấp gốc: tham số, `extra`, `/transform` thiếu `extra` → `go('/partner/:id')` | chuyển chỗ khai báo, thân giữ nguyên | bước 0: mỗi đường dẫn mở đúng trang (8 ca), `/partner/p-1/transform` không `extra` → về hồ sơ. Sau sửa phải xanh |
| W9 | 18 sheet = bottom sheet ở mọi bề rộng | ≥ 1024: hộp thoại; hẹp: y như cũ | bước 0: ở 390, mở sheet lọc + sheet thao tác → thấy `BottomSheet`. Sau sửa: 390 vẫn `BottomSheet`; 1280 thấy `VSheetDialog`, Esc đóng |
| W10 | Hồ sơ là route gốc toàn màn (che thanh tab trên iPhone) | **Đổi (Q1):** nằm trong tab | test 390: mở hồ sơ → `ErpTabScaffold` / thanh tab vẫn hiện; nút ← về danh sách |

**Bước 0** viết W3–W9 trên code **sau 4-B, trước 4-W**, dựng qua `appRouter` thật + `FakePartnerRepository` (mẫu `test/features/iam/presentation_module/w2_behavior_preservation_test.dart`), bề rộng 390 × 844. Chạy xanh, ghi tên test.

## 5. Các bước

Trước mỗi symbol sửa: `gitnexus impact` (upstream), ghi vào Kết quả; HIGH / CRITICAL thì dừng, ghi lại. `app_router.dart` gần như chắc chắn HIGH (mọi màn đi qua): ghi blast radius, làm tiếp vì đã có test W3–W10.

0. Bước 0 (mục 4).
1. `PartnerNoPermissionView` (3.3), `PartnerAreaShell` (3.2).
2. `PartnerListPage`: `cubit`, `selectedId`, chọn dòng, tạo xong (3.3). `PartnerListBody` / `PartnerListItemTile`: `selectedId` / `isSelected`.
3. `PartnerDetailPage` (3.4).
4. Router (3.1).
5. 18 sheet (3.5).
6. Test mới ở 1280 × 800: 2 cột; chọn dòng đổi URL + `isSelected`; mở thẳng `/partner/p-1` thấy 2 cột với dòng p-1 được chọn; đổi A → B hiện đúng B (W-key); ô trống khi ở `/partner`; nút ← ẩn ở hồ sơ; W5, W6 ở 1280; W9 ở 1280.
7. Kiểm mục 6, ghi Kết quả, `detect_changes()`.

## 6. Kiểm tra

### 6.1 Tự động

- [ ] Mọi test bước 0 xanh, **không đổi điều kiện kiểm** (chỉ được đổi cách dựng). Riêng W10 là đổi có chủ đích.
- [ ] Test mới bước 6 xanh.
- [ ] `git grep -n "showVBottomSheet(" -- apps/erp/lib/features/partner` rỗng.
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi mới. `flutter test`: không fail mới so với sau 4-B.
- [ ] `cd apps/erp && flutter build web` chạy qua.

### 6.2 Kiểm tay (người dùng)

- [ ] Chrome 1440 × 900 và 1280 × 800: 2 cột; chọn dòng; tạo; sửa; ngừng / kích hoạt; xoá; chuyển đổi; mở tổ chức từ sheet chặn; tải lại trang ở `/partner/<id>` vẫn đúng.
- [ ] Chrome hẹp (~900): một cột như iPhone.
- [ ] Bàn phím: Tab qua ô tìm → thẻ → Enter mở hồ sơ; Esc đóng hộp thoại.
- [ ] iPhone simulator: như cũ, trừ thanh tab vẫn hiện khi xem hồ sơ (Q1).

## 7. Rủi ro / lưu ý

- **Thứ tự route** là chỗ dễ vỡ nhất. W8 và W2 (mở thẳng URL) chạy qua router thật là để bắt lỗi này.
- `ValueKey(partnerId)` thiếu thì đổi hồ sơ ở 2 cột vẫn hiện hồ sơ cũ (`State` được giữ). Test "A → B" ở bước 6 bắt lỗi này.
- `PartnerDetailPage` nằm trong navigator của tab: các `push` sang route gốc (sửa, người liên hệ, chuyển đổi, lịch sử) vẫn đẩy lên navigator gốc như cũ, `await` kết quả vẫn chạy (go_router).
- `order_einvoice_section.dart:275` (`push('/partner/$partnerId/edit')`) dùng route gốc `edit`: chuyển chỗ khai báo không làm đổi đường dẫn. Test có sẵn `order_einvoice_section_test.dart` phải xanh.

## 8. Kết quả (phiên làm code ghi)

**Trạng thái: ✅ xong các bước 0–7.** Chưa làm kiểm tay 6.2 (việc của người dùng).

**Bước 0 ✅** `apps/erp/test/features/partner/presentation/partner_4w_behavior_preservation_test.dart`: 17 test W3–W9 (W3, W4, W5a, W5b, W6, W7, 10 ca W8, W9) chạy qua `appRouter` thật, 390 × 844, xanh trên code cũ trước khi sửa. Helper dùng chung: `test/features/partner/support/partner_router_harness.dart`. Bỏ riêng lỗi `overflowed` vì font Ahem làm `PartnerListHeaderRow` tràn 1 px ở 390 (test kiểm điều hướng, không kiểm bố cục).

**Bước 1 ✅** `presentation/widgets/partner_no_permission_view.dart` (mới, giữ key `wgt_e01_u02_fr01_02` + chữ); `presentation/partner_area_shell.dart` (mới).
**Bước 2 ✅** `partner_list_page.dart`: `cubit`, `selectedId`, `_ownsCubit` (không đóng cubit của shell), `_openPartnerDetail` / `_openCreateFlow` rẽ nhánh `isSplitOf`. `partner_list_body.dart`: `selectedId`. `partner_list_item_tile.dart`: `isSelected` → `VCard.isSelected`.
**Bước 3 ✅** `partner_detail_page.dart`: `onMutated`, `showBackButton: !isSplitOf`, `_openOrganization`, `_goBackToList`.
**Bước 4 ✅** `app_router.dart`: 8 route chuyển lên trước `ShellRoute(StoreShell)`; route `/partner/:partnerId` cấp gốc xoá, thay bằng `ShellRoute(PartnerAreaShell)` > `/partner` > `:partnerId` trong nhánh tab, `key: ValueKey(partnerId)`.
**Bước 5 ✅** 17 chỗ `showVBottomSheet<` → `showVAdaptiveSheet<` (plan ghi 18; grep thực tế ra 17, `git grep showVBottomSheet` trong `features/partner` rỗng).
**Bước 6 ✅** `partner_4w_wide_layout_test.dart`: 16 test (12 ở web rộng, W9 ×2, W1, W2 ×2, W10). Viewport rộng dùng **1280 × 1100** thay vì 800 (Ahem làm thẻ cao hơn, ListView lười chỉ dựng 1 thẻ ở 800).
**Bước 7 ✅** xem dưới.

### Lệch plan (cần review)

1. **Xoá hồ sơ ở bề rộng hẹp (3.4 / W6).** Plan giữ `canPop ? pop(true) : toast + go`. Theo Q1, hồ sơ nằm trong tab nên mở thẳng `/partner/p-1` vẫn có danh sách bên dưới → `canPop()` luôn true, `pop(true)` không còn ai chờ để hiện toast (test W6 đỏ). Đã sửa: hồ sơ tự `showPartnerSoftDeleteSuccessToast` + `onMutated` rồi `pop()` (hẹp, còn đường lùi) hoặc `go('/partner')`. Kéo theo: `_openPartnerDetail` ở hẹp không còn `await` + tải lại + toast (hồ sơ báo qua `onMutated`, tránh tải lại hai lần). `onMutated` truyền vô điều kiện ở router (hẹp lẫn rộng). Hành vi nhìn thấy không đổi (W3, W6 xanh).
2. **W8 `/transform` thiếu `extra`:** ~~test đổi điểm xuất phát sang route gốc để tránh lỗi~~ — **sai, đã sửa ở R1-1.** Lỗi `Duplicate GlobalKey` là thật (hồ sơ nằm trong tab nên đường tab → route gốc → tab dựng hai bản nhánh tab). Đã sửa bằng `redirect` trên route; test xuất phát lại từ trang tab như điều kiện bước 0.
3. Điều kiện kiểm của bước 0 không đổi; chỉ đổi cách dựng (helper, điểm xuất phát W8 trên).

### Impact / kiểm tra

- `gitnexus impact` (upstream, repo `erp-sales-inventory`): `PartnerListPage` LOW (1 trực tiếp: `app_router.dart`), `PartnerDetailPage` LOW (như trên), `PartnerListBody` LOW (2 trực tiếp, 1 process `build`), `PartnerListItemTile` LOW (3 trực tiếp), `appRouter` LOW (0). Không HIGH/CRITICAL.
- `detect-changes`: 102 tệp / 87 symbol (gồm cả thay đổi 4-A/4-B chưa commit), 0 process bị ảnh hưởng, risk low.
- `dart analyze lib test`: không lỗi mới (1 warning có sẵn `order_einvoice_section_test.dart:32`); thư mục partner + router sạch.
- `flutter test` toàn `apps/erp`: 1726 đạt / **61 lỗi**, mọi tệp lỗi đều có trong `TEST-BASELINE.md`, không lỗi mới. `order_einvoice_section_test.dart` xanh.
- `flutter build web`: qua (50 s).
- `git grep -n "showVBottomSheet(" -- apps/erp/lib/features/partner`: rỗng.

### R1 — sửa (2026-11-01, chưa commit)

**R1-1 ✅ Route `/transform` thiếu `extra`**
- `apps/erp/lib/core/router/app_router.dart` (route `partner.transform`, ≈ dòng 247–262): thêm `redirect: (context, state) => state.extra is PartnerDetailDto ? null : '/partner/${state.pathParameters['partnerId']}'`; bỏ nhánh `partner == null` + `addPostFrameCallback` + `go`; builder còn `state.extra as PartnerDetailDto` rồi `PartnerTransformPage(...)` như cũ. Bỏ biến `partnerId` thừa trong builder.
- Test: `partner_4w_behavior_preservation_test.dart` — ca W8 "thiếu extra" thành 2 ca: xuất phát từ `/partner` và từ `/partner/p-person-1` (đã bỏ chú thích "xuất phát từ route gốc…"); `partner_4w_wide_layout_test.dart` — ca 1280 "R1-1". Cả 3 kiểm: không còn `PartnerTransformPage`, thấy hồ sơ, đường dẫn `/partner/p-person-1`, `tester.takeException()` null (không `Duplicate GlobalKey`).
- Lệch plan: không.

**R1-2 ✅ Danh sách làm mới sau thao tác người liên hệ**
- `apps/erp/lib/features/partner/presentation/pages/partner_detail_page.dart`: `_openContacts` (≈ dòng 86–91) gọi `widget.onMutated?.call()` sau `if (!mounted) return;` và trước `loadDetail`; `_showAddMethodSheet` (≈ dòng 108–118) truyền `onReload: () { widget.onMutated?.call(); return _cubit.loadDetail(widget.partnerId); }`. Không sửa `partner_list_page.dart`.
- Test (390 trong `partner_4w_behavior_preservation_test.dart`, 1280 trong `partner_4w_wide_layout_test.dart`): "vào Người liên hệ rồi quay lại → `search` tăng 1" và "thêm người có sẵn → `addContact` được gọi, `search` tăng 1". Thêm `OrganizationDetailMixedSearchRepository` vào `test/features/partner/support/partner_router_harness.dart` (chi tiết là tổ chức có người liên hệ, `search` trả danh sách hỗn hợp, vì scenario `detailOrganizationWithContacts` trả `search` rỗng nên trang chọn cá nhân không có dòng).
- Lệch plan / lưu ý: thẻ "Người liên hệ" mặc định thu gọn nên test bấm tiêu đề để mở. Ở 390 font Ahem làm hàng "Thêm / Xem tất cả" tràn ngang (nút ở x≈408 > 390) nên 2 ca 390 gọi `onTap` của `InkWell` thay vì tap theo toạ độ; ca 1280 tap bình thường.

**Kiểm tra**
- Bỏ riêng 2 bản sửa thì 7 ca mới đỏ (R1-2: 4 ca; R1-1: 3 ca), khôi phục thì xanh.
- `flutter test test/features/partner` + `order_einvoice_section_test.dart`: 337 đạt, 0 lỗi. `dart analyze lib/core/router lib/features/partner test/features/partner`: không lỗi. Chưa chạy lại toàn `apps/erp` và `flutter build web` (để R2).
- `gitnexus impact` (upstream, repo `erp-sales-inventory`): `_openContacts` LOW (1 trực tiếp, process `build`), `_showAddMethodSheet` LOW (1 trực tiếp), `runPartnerDetailAddContactFlow` LOW (không sửa, chỉ kiểm), `appRouter` LOW (0).
- `detect-changes`: 106 tệp / 119 symbol (gồm cả thay đổi 4-A/4-B/4-W chưa commit), 5 process (đều `build`), risk medium.

## 9. Review

### R1 — 2026-11-01 — ❌ CHƯA ĐẠT (1 P1, 1 P2, 3 P3)

**Kết luận: CHƯA ĐẠT.** Vì sao:

- (1) Đưa hồ sơ vào tab làm app **báo lỗi "Duplicate GlobalKey"** khi đi từ trang trong tab tới `/partner/:id/transform` không có `extra`. Code cũ không bị. Test W8 đã đổi điểm xuất phát nên che mất lỗi, trái 6.1 "không đổi điều kiện kiểm".
- (2) Lệch plan số 1 (bỏ tải lại danh sách khi quay về từ hồ sơ trên iPhone) làm mất một hành vi cũ: thao tác người liên hệ không còn làm mới danh sách.

| Hạng mục | Kết quả |
|---|---|
| Cây route, shell, 2 cột, `isSelected`, ô trống, ẩn ←, `ValueKey`, quyền (W1, W2, W10) | Đạt |
| 17 chỗ sheet → `showVAdaptiveSheet`, grep rỗng | Đạt |
| Test / analyze / `flutter build web` | Xanh; 61 lỗi đều có sẵn (so theo tên); build qua |
| **Bắt buộc sửa** | **R1-1 (P1), R1-2 (P2)**: xem mục "R1 — việc cần sửa" bên dưới |
| Tuỳ chọn sửa | Không có |
| Chỉ ghi nhận | P3-1 … P3-3 |
| Cần người dùng chốt | Không có |
| Còn lại sau khi sửa | Review R2 (lượt hai); kiểm tay 6.2 (người dùng); `node .gitnexus/run.cjs analyze` + `detect_changes()` trước khi commit |

#### P3 (không chặn)

1. **[Không sửa — chỉ ghi nhận]** Mục 8 ghi `flutter test` 1726 đạt; phiên review đo lại được **1699 đạt / 61 lỗi** (cả 61 tên khớp baseline). Có lẽ do 4-C xoá nhóm `old` của test parity sau lúc đo. Ghi số mới khi chạy lại ở R2.
2. **[Không sửa — chỉ ghi nhận]** Test rộng dùng 1280 × 1100 thay 1280 × 800 (font Ahem). Chấp nhận, đã ghi lý do.
3. **[Không sửa — chỉ ghi nhận]** Lệch plan số 1 (hồ sơ tự hiện toast xoá rồi `pop()`) đúng và cần thiết khi hồ sơ nằm trong tab. Chỉ thiếu phần R1-2.

**Đã chạy (phiên review):** `flutter test` toàn `apps/erp` 1699 / 61 (tên khớp `TEST-BASELINE.md` + W-2); `flutter build web` qua (52,7 s); grep `showVBottomSheet(` trong `features/partner` rỗng; chuỗi Q4 đúng nguyên văn (`app_router.dart:392`); `order_einvoice_section_test` xanh. Code app không đổi sau review: router đã trả nguyên, test tạm đã xoá.

### R1 — việc cần sửa

> Phiên code làm **đúng thứ tự** R1-1 → R1-2. Ghi kết quả từng việc vào mục 8 (khối "R1 — sửa": tệp:dòng, lệch plan, test, impact) ngay sau khi xong. Không có việc nào chờ người dùng quyết. Xong thì báo để review **R2** (lượt review thứ hai), đối chiếu theo đúng mã task R1-x.

**R1-1 — Route `/transform` thiếu `extra` làm trùng GlobalKey** · P1 · bắt buộc

- **Hiện tại:** `app_router.dart:247–266` (`partner.transform`): builder trả `Scaffold` chờ, rồi `addPostFrameCallback` → `context.go('/partner/$partnerId')`. Hồ sơ nay nằm trong nhánh tab nên đường đi là trang tab → route gốc → trang tab trong lúc chuyển cảnh. Hai bản của nhánh tab cùng tồn tại, nên báo `Duplicate GlobalKey detected in widget tree`.
  - Phiên review tái hiện bằng test tạm (đã xoá): `pumpPartnerApp(location: '/partner/p-person-1' hoặc '/partner')` rồi `appRouter.go('/partner/p-person-1/transform')`. Cả 4 ca đều lỗi (2 điểm xuất phát × 390 / 1280).
  - Trên web, việc này xảy ra khi bấm Forward / Back của trình duyệt về trang chuyển đổi (go_router làm mất `extra` không mã hoá được).
- **Cần làm:**
  1. Bỏ nhánh `if (partner == null)` trong builder. Thêm vào `GoRoute` đó:
     ```dart
     redirect: (context, state) => state.extra is PartnerDetailDto
         ? null
         : '/partner/${state.pathParameters['partnerId']}',
     ```
     Builder chỉ còn `final partner = state.extra as PartnerDetailDto;` rồi `PartnerTransformPage(...)` như cũ. Kết quả người dùng thấy giữ nguyên (thiếu `extra` → về hồ sơ). Phiên review đã thử bản sửa này trên bản tạm: 75/75 test `test/features/partner/presentation/` xanh, 4 ca tái hiện hết lỗi.
  2. `partner_4w_behavior_preservation_test.dart:211` ("`/partner/:id/transform` thiếu extra → về hồ sơ"): xuất phát lại từ trang **tab** như điều kiện bước 0 (`location: '/partner'`), bỏ chú thích "xuất phát từ route gốc…". Thêm 1 ca xuất phát từ `/partner/p-person-1` và 1 ca ở 1280 (`partner_4w_wide_layout_test.dart`).
  3. Sửa "Lệch plan" mục 8 số 2 cho đúng: lỗi có thật, đã sửa bằng `redirect`.
- **Xong khi:** 3 ca trên xanh và không có `Duplicate GlobalKey` trong log; toàn bộ `test/features/partner` xanh.

**R1-2 — Danh sách không làm mới sau thao tác người liên hệ** · P2 · bắt buộc

- **Hiện tại:**
  - Code cũ (`partner_list_page.dart` ở `HEAD`, `_openPartnerDetail`): iPhone quay về từ hồ sơ thì **luôn** `fetchPartners(isRefresh: true)`.
  - Lệch plan số 1 bỏ việc này, giao cho `onMutated`. Nhưng `onMutated` chỉ được gọi ở sửa / chuyển đổi / ngừng / kích hoạt / xoá. Các thao tác người liên hệ (thêm có sẵn hoặc tạo mới, đổi người chính, gỡ, sửa hồ sơ người liên hệ) đều tăng `updated_at` của tổ chức (`20260714004`: `:849` `add_organization_contact`, `:995` `update_organization_contact` — kể cả đổi người chính, `:1050` `remove_organization_contact`), riêng sửa hồ sơ người liên hệ còn tăng `updated_at` của cá nhân (`:987`, cùng hàm `update_organization_contact`).
  - Hậu quả: danh sách sắp theo "Cập nhật gần nhất" bị cũ (tổ chức không nhảy lên đầu; tên / SĐT của cá nhân có vai trò không đổi) ở cả iPhone lẫn web 2 cột.
- **Cần làm** (`partner_detail_page.dart`):
  1. `_openContacts` (dòng 86): sau `await context.push(...)` và `if (!mounted) return;`, gọi `widget.onMutated?.call();` trước `loadDetail`.
  2. `runPartnerDetailAddContactFlow(... onReload: ...)` (dòng ~113): `onReload: () { widget.onMutated?.call(); return _cubit.loadDetail(widget.partnerId); }`.
  3. Không sửa `partner_list_page.dart` (giữ lệch plan số 1).
  4. Lưu ý: `onReload` cũng chạy khi người dùng huỷ ở nhánh "tạo mới" và khi thêm lỗi một phần (`partner_detail_add_contact_flow.dart`). Sau sửa, danh sách tải lại thêm một lần ở các ca đó: chấp nhận (lỗi một phần có thể đã ghi vào server). Không thêm điều kiện để chặn.
- **Xong khi:** thêm test ở 390 và 1280. Mở hồ sơ tổ chức → vào "Người liên hệ" → quay lại ⇒ số lời gọi `search` tăng 1. Thêm người có sẵn từ hồ sơ ⇒ số lời gọi `search` tăng 1. Chỉ khẳng định "tăng 1" ở hai đường thành công này, không khẳng định ở ca huỷ / lỗi một phần. W3–W7 vẫn xanh.

> **Xác nhận (2026-11-01, phiên review, đối chiếu code hiện tại):** R1-1 và R1-2 đúng với code. R1-1: `app_router.dart:246–266` còn nhánh `partner == null`, test `partner_4w_behavior_preservation_test.dart:211` xuất phát từ `/partner/new`, `partner_4w_wide_layout_test.dart` chưa có ca `transform`. R1-2: `partner_detail_page.dart:86–90` và `:113` chưa gọi `onMutated`; `runPartnerDetailAddContactFlow` chỉ có một nơi gọi (`:108`). Kết quả "4 ca lỗi, 75/75 xanh sau sửa" là của lượt review, chưa chạy lại ở lần xác nhận này.

### R2 — 2026-11-02 — ✅ ĐẠT (0 P1, 0 P2, 1 P3)

**Kết luận: ĐẠT.** Hai task R1 làm đúng như mô tả, có test kiểm đúng điều kiện "Xong khi", không có lỗi mới.

| Hạng mục | Kết quả |
|---|---|
| **R1-1** `/transform` thiếu `extra` | Đạt. `app_router.dart:253–255` có `redirect` đúng mẫu, không còn nhánh `partner == null` / `addPostFrameCallback`, builder chỉ `state.extra as PartnerDetailDto` (`:257`). Test 390 xuất phát từ `/partner` và `/partner/p-person-1` (`partner_4w_behavior_preservation_test.dart:213–227`), 1280 (`partner_4w_wide_layout_test.dart:311`); cả 3 kiểm `takeException()` null. Mục 8 "Lệch plan" số 2 đã sửa lại cho đúng |
| **R1-2** làm mới danh sách sau thao tác người liên hệ | Đạt. `partner_detail_page.dart:89` (`_openContacts`, sau `mounted`, trước `loadDetail`), `:114–117` (`onReload`). Đối chiếu: hồ sơ chỉ có 2 đường vào thao tác người liên hệ (`PartnerDetailContactsCard.onTapAdd` / `onTapViewAll`, `:403–411`), cả hai đã phủ. `partner_list_page.dart` không sửa. Test "tăng 1" ở 390 (`:283`) và 1280 (`:329`, `:349`), chỉ khẳng định ở đường thành công |
| Test / analyze / build | `flutter test` toàn `apps/erp`: **1705 đạt / 61 lỗi**, cả 61 tên khớp `TEST-BASELINE.md` (so từng tên). +6 so với R1 (1699) = số ca R1 thêm. `dart analyze lib test`: 0 error, 1 warning có sẵn (`order_einvoice_section_test.dart:32`); `lib/core/router lib/features/partner test/features/partner` sạch. `flutter build web` qua (65 s). 39/39 test 4-W xanh |
| Bắt buộc sửa / Tuỳ chọn sửa / Cần người dùng chốt | Không có |
| Chỉ ghi nhận | P3-1 |
| Còn lại | Kiểm tay 6.2 (người dùng); `node .gitnexus/run.cjs analyze` + `detect_changes()` trước khi commit; xoá plan sau khi commit (quy tắc xoá plan đã xong) |

#### P3 (không chặn)

1. **[Không sửa — chỉ ghi nhận]** `OrganizationDetailMixedSearchRepository.search` (`test/features/partner/support/partner_router_harness.dart:104`) không chuyển `requireBothRoles`, `requireAnyRole`, `updatedWithinDays` sang `_mixed.search`. Chỉ là fake cho test "thêm người có sẵn", trang chọn cá nhân không dùng các bộ lọc này; không ảnh hưởng kết quả.
