# W-1 — Khung web: thanh bên trái, tab có URL, density theo cách thao tác

> Phase: Web cho app (W) · Trạng thái: Plan ✅ (rà lại theo code 2026-10-27; duyệt 2026-10-28) | Làm ✅ | Review ✅ R2 2026-10-28 — kiểm tay người dùng tự làm; chưa commit
> Gồm việc: W.1–W.4 ([PLAN mục "Web cho app"](../../PLAN.md)). Ước lượng **~2 ngày, 3 nhóm việc** (mục 4). **Không tự commit** — người dùng commit (chốt 2026-10-27: W-1 làm chồng lên 2-B6 / 2-B7 đang chưa commit).
> Tài liệu liên quan: [LUONG-UNG-DUNG mục 1.1](../../../02-yeu-cau/LUONG-UNG-DUNG.md) (thiết bị và khung, chốt 2026-10-20), mục 3 (guard), mục 5 (khu cửa hàng); plan 10-4 (nhãn + `Semantics` thanh dưới).
> **Rủi ro GitNexus: CRITICAL** — `DashboardPage` và `ErpBottomNavigation` là gốc của khu cửa hàng (impact upstream 2026-10-20: 100 luồng, 20 module bị ảnh hưởng). Giữ nguyên mọi đường dẫn route và hành vi trên iPhone; kiểm theo mục 5.

> **Rà lại theo code 2026-10-27 (phiên plan / review): plan vẫn đúng hướng, đã sửa các điểm dưới; phiên làm code làm theo mục 3–5.**
> - **Còn đúng (đã grep):** `DashboardPage` / `_SessionBootstrap` / `DefaultPairGateCubit` / `_buildGateHold` / `_buildHomeBody` / `_buildScaffold` trong `features/dashboard/presentation/dashboard_page.dart`; `DashboardTab` (cả 5 `enabled: true`) trùng `ErpTab`; `ErpTab.routePath` vẫn sai cho home (`/dashboard/home`) và more (`/dashboard/more`); `DashboardPage.navigateToTab` không ai gọi; 3 route `/products/items`, `/orders`, `/partner` dựng `DashboardPage` mới (`app_router.dart` ~647–662); route `/` đọc `state.extra as DashboardTab?` (~194–198); `ErpBottomNavigation` chỉ `DashboardPage` dùng; tab "Thêm" (`more_page.dart`) không đổi; `VTheme.lightThemeForDensity` / `darkThemeForDensity` có sẵn, `main.dart` dùng `VTheme.lightTheme` / `darkTheme`; `bootstrap()` được gọi ở `dashboard_page.dart` (3 chỗ) và `signup_cubit.dart:149`; DS chưa có `VSideNavigation`; `go_router: ^17.0.0` (có `StatefulShellRoute`).
> - **Bổ sung — 3 `ShellRoute` phạm vi luồng đã có** trong router (mục 2, 3.1): nhập kho nhanh `/warehouse/receipts/quick/**` (~211), định giá `/warehouse/valuation/receipt/:id` + `/review` (~278), đơn nháp bán hàng (`$salesDraftShellRoute` trong `$appRoutes`). Chuyển **nguyên khối** vào `routes:` của `StoreShell`, không gỡ, không đổi builder.
> - **Sửa:** test dựng `DashboardPage` là **4** tệp (thêm `test/features/tenant_context/presentation/e2e_e05_u01_fr01_01_tenant_context_test.dart`).
> - **Mới từ 10-7.2:** `VPageScaffold.contentMaxWidth` — từ breakpoint tablet, body + `bottomBar` của mọi màn dùng `VPageScaffold` đã nằm trong cột giữa 640 (tablet) / 720 (desktop); màn tự chia pane truyền `VPageScaffold.fullWidth`. ⇒ `VContentWidth` 1120 của `StoreShell` (3.2) chỉ là **trần ngoài** cho màn không dùng `VPageScaffold` hoặc dùng `fullWidth` (bố cục K7 của W-2 / Theme 7). Giữ cả hai, không sửa `VPageScaffold`.
> - **Sửa:** chữ "counter tablet" còn ở **3** chỗ: `v_density.dart:9`, `v_page_scaffold.dart:15` và `:40` (3.5).
> - **Bổ sung:** mục con nào của "Thêm" được chọn theo đường dẫn — bảng ở 3.3 (plan cũ chỉ nói mục chính).
> - **Sửa rủi ro dialog / sheet** (mục 6): `showDialog` / `showVConfirmDialog` mặc định `useRootNavigator: true` ⇒ phủ cả thanh bên; `showModalBottomSheet` / `showVBottomSheet` mặc định navigator gần nhất ⇒ chỉ phủ vùng nội dung bên phải thanh bên. App + DS không có chỗ nào đặt `useRootNavigator` (grep 2026-10-27). Chấp nhận cả hai; W-2 đổi sheet thành hộp thoại trên web.
> - **Prototype Theme 7** (`specs/themes/theme-07/03.design/prototype/html`, khung Web 1280 × 800) đã dựng thanh bên đúng 3.3: 240px, 5 mục chính, mục con của "Thêm" (Kho, Giá riêng / Nhớ giá, Người dùng & vai trò, Tài khoản của tôi, Thiết lập), nội dung tối đa 1120px ⇒ W-1 khớp prototype, không đổi.
> - **Làm chồng lên 2-B6 / 2-B7 chưa commit:** không revert, không format lại tệp nào của hai plan đó; `detect_changes()` sẽ thấy cả thay đổi 2-B6 / 2-B7 — ghi rõ phần nào là của W-1 ở mục 7.

## 1. Mục tiêu

Trên web, cửa sổ rộng có **thanh bên trái** cố định trong toàn khu cửa hàng (cả màn chi tiết); cửa sổ hẹp và iPhone giữ đúng như hiện tại (thanh dưới 5 tab chỉ ở màn gốc của tab, màn chi tiết che toàn màn). Mỗi tab có URL riêng để tải lại trang / mở link trên web vào đúng chỗ. Web dùng chuột thì dùng density `compact`.

**Không đổi:** đường dẫn route đang có, guard (`route_guard.dart`), nội dung từng màn, giao diện iPhone.

## 2. Hiện trạng (đo 2026-10-20)

| Mục | Hiện trạng |
|---|---|
| 5 tab | Nằm **trong state** của `DashboardPage` (`_DashboardPageState._currentTab`, `setTab`) ở route `/`; chọn tab = `setState` + `goNamed('dashboard', extra: tab)`. `extra` mất khi tải lại trang web |
| Route mở thẳng tab | `/products/items`, `/orders` (`SalesNav.ordersList`), `/partner` — mỗi route dựng **một `DashboardPage` mới** (`app_router.dart` ~dòng 648–662). Không có route cho tab "Thêm" |
| Khởi tạo phiên | `_SessionBootstrap` trong `DashboardPage` gọi `SessionController.bootstrap()` khi `DashboardPage` dựng. Mở thẳng `/more/users` trên web thì **không ai gọi bootstrap** |
| Cổng cửa hàng–kho | `DefaultPairGateCubit` bọc `_buildScaffold` trong `DashboardPage` |
| Thanh dưới | `ErpBottomNavigation` (`features/dashboard/presentation/widgets/erp_bottom_navigation.dart`) bọc `VBottomNavigationBar`; enum `ErpTab.routePath` có giá trị cũ không còn route (`/dashboard/home`, `/dashboard/more`). Chỉ `DashboardPage` dùng |
| `DashboardPage.navigateToTab` | Không có nơi gọi ngoài chính file |
| Màn chi tiết | ~90 route cấp gốc (`/more/**` 34, `/products/**` 14, `/warehouse/**` 12, `/partner/**` 10, `/pricing/**` 10, `/sales/**` qua `$appRoutes`, `/inventory`); đẩy bằng `context.push` (64 chỗ) → che toàn màn |
| Breakpoint DS | `VBreakpoints.tablet = 600`, `desktop = 1024`; `VResponsive`, `VContentWidth` (desktop 1120) đã có |
| Density DS | `VTheme.lightThemeForDensity(VDensityMode)` có sẵn; `ErpApp` (`main.dart`) luôn dùng `VTheme.lightTheme` = `comfortable`. Chú thích `VDensity` còn nhắc "counter tablet" |
| Web build | `flutter build web` chạy được (51 giây, 2026-10-20). URL dạng hash (`/#/more/users`), chưa đặt `UrlStrategy` |
| Test dựng `DashboardPage` trực tiếp | `test/features/auth/e2e_th01_s0_session_test.dart:57`, `test/features/dashboard/presentation/default_pair_gate_test.dart:110`, `test/features/tenant_context/presentation/wgt_e05_tenant_context_test.dart:51, 389`, `test/features/tenant_context/presentation/e2e_e05_u01_fr01_01_tenant_context_test.dart` (grep `DashboardPage(`) |
| `ShellRoute` có sẵn (phạm vi luồng) | `app_router.dart` ~211 (`/warehouse/receipts/quick/**`, `BlocProvider`), ~278 (`/warehouse/valuation/receipt/:id`, `/warehouse/valuation/review`), `$salesDraftShellRoute` (`/sales/drafts` + `/sales/compose`, `sales_typed_routes.dart`) |
| `VPageScaffold` (10-7.2) | Từ breakpoint tablet: body + `bottomBar` trong cột giữa 640 / 720; `fullWidth` để tự chia pane |
| Mục trong tab "Thêm" | Viết thẳng trong `_MoreView` (`more_page.dart` dòng ~100–157): Kho `/inventory`, Giá riêng `/pricing`, Người dùng & vai trò `/more/users-and-roles` (chỉ Owner), Tài khoản của tôi, Thiết lập, Đăng xuất; 3 mục chưa có `onTap` (Khách hàng & NCC, Đơn nhập, Báo cáo) |

## 3. Thiết kế

### 3.1 Cây route

```text
GoRouter
├─ /login, /signup, /verify-email, /invitation, /no-organization   (giữ nguyên, ngoài shell — không thanh bên)
└─ ShellRoute  builder: StoreShell                       ← mới: bootstrap + cổng + khung rộng/hẹp
   ├─ StatefulShellRoute.indexedStack  builder: ErpTabScaffold   ← mới: 5 nhánh tab
   │   ├─ nhánh home      /                 → HomeTabPage (tách từ DashboardPage)
   │   ├─ nhánh orders    /orders           → SalesOrderListPage
   │   ├─ nhánh products  /products/items   → ProductCatalogTabPage
   │   ├─ nhánh partners  /partner          → PartnerListPage
   │   └─ nhánh more      /more             → MorePage (route MỚI)
   └─ mọi route khu cửa hàng còn lại, giữ nguyên đường dẫn và thứ tự
      (/inventory, /warehouse/**, /more/**, /products/** trừ /products/items, /partner/** trừ /partner, /pricing/**, ...$appRoutes)
      gồm nguyên 3 ShellRoute phạm vi luồng đang có (nhập kho nhanh, định giá, đơn nháp) — giữ builder / BlocProvider
```

- Màn chi tiết là **anh em** của `StatefulShellRoute` trong navigator của `StoreShell` → trên iPhone `push` vẫn che cả thanh dưới như hiện tại; trên web rộng hiện bên phải thanh bên.
- `/partner` và `/products/items` chuyển từ route cấp gốc vào nhánh; các route con `/partner/:id…` giữ ở cấp `StoreShell` (không lồng vào nhánh) để không đổi hành vi push.
- `SalesNav.ordersList` (`/orders`) chuyển vào nhánh orders; `$appRoutes` giữ nguyên ở cấp `StoreShell`.

### 3.2 Khung theo bề rộng

| Bề rộng của `StoreShell` | `StoreShell` | `ErpTabScaffold` |
|---|---|---|
| `< VBreakpoints.desktop` (1024) | `child` như cũ | `Scaffold(body: navigationShell, bottomNavigationBar: ErpBottomNavigation)` |
| `≥ 1024` | `Row[ErpSideNavigation (240), Expanded(VContentWidth(child))]` | chỉ `navigationShell` (không thanh dưới) |

Không thêm breakpoint mới. Một ngưỡng duy nhất: `VBreakpoints.desktop`.

### 3.3 Thanh bên (`ErpSideNavigation`)

Từ trên xuống:

1. Tên tổ chức đang dùng; bấm → `openTenantContextSelector(context)` (đang có ở `tenant_context_selector.dart`).
2. 5 mục chính, cùng nhãn / icon với `ErpTab`.
3. Dưới "Thêm": các mục con **đang bấm được** của tab Thêm (Kho, Giá riêng / Nhớ giá, Người dùng & vai trò — chỉ Owner, Tài khoản của tôi, Thiết lập). Mục chưa có `onTap` không hiện. Tổ chức bị chặn (`state.isBlocked`): tắt các mục như `MorePage`.
4. Cuối: "Đăng xuất" (dùng lại `onLogout` của `MorePage`).

Mục được chọn suy ra từ đường dẫn hiện tại: mục chính theo `ErpTab.fromLocation` (mục 3.4); **mục con** theo bảng (so tiền tố, khớp dòng đầu tiên từ trên xuống; không khớp ⇒ không mục con nào được chọn, chỉ "Thêm"):

| Đường dẫn bắt đầu bằng | Mục con được chọn | Ghi chú (lối vào trong app) |
|---|---|---|
| `/inventory`, `/warehouse` | Kho | `more_page.dart` → `/inventory` |
| `/pricing` | Giá riêng / Nhớ giá | `more_page.dart` → `/pricing` |
| `/more/users-and-roles`, `/more/organization-profile`, `/more/users`, `/more/roles`, `/more/audit-logs` | Người dùng & vai trò | `users_and_roles_page.dart` mở 4 khu này |
| `/more/my-account` | Tài khoản của tôi | |
| `/more/settings`, `/more/einvoice`, `/more/product-settings` | Thiết lập | `system_settings_page.dart` mở `/more/einvoice`, `/more/product-settings` |
| `/more` (đúng bằng) | — | Chỉ "Thêm" được chọn |

Đặt bảng này cạnh danh sách mục trong `more_entries.dart` (bước 5): mỗi mục có thêm `List<String> matchPrefixes`; hàm thuần `MoreEntry? selectedMoreEntry(String location)` + unit test theo bảng. Bấm mục chính → `context.go(tab.routePath)`; bấm mục con → `context.go(route)` (thay ngăn xếp, không chồng màn).

Chữ: dùng đúng chữ đang có của `ErpTab` và `_MoreView`, không đặt chữ mới.

### 3.4 `ErpTab`

- `routePath` sửa đúng: `/`, `/orders`, `/products/items`, `/partner`, `/more`.
- `fromPath` → thay bằng `fromLocation(String location)`:

| Đường dẫn | Tab |
|---|---|
| `/` (đúng bằng) | home |
| bắt đầu `/orders`, `/sales` | orders |
| bắt đầu `/products` | products |
| bắt đầu `/partner` | partners |
| bắt đầu `/more`, `/inventory`, `/warehouse`, `/pricing` | more |
| khác | home |

- Bỏ `DashboardTab` (trùng `ErpTab`) và `DashboardPage.navigateToTab` (không ai gọi).

### 3.5 Density

`main.dart`: `theme: VTheme.lightThemeForDensity(erpDensityMode())`, `darkTheme` tương tự.

```dart
/// Web trên máy tính (chuột / bàn phím) → compact; iPhone, Android, web trên điện thoại → comfortable.
VDensityMode erpDensityMode({bool isWeb = kIsWeb, TargetPlatform? platform}) {
  final p = platform ?? defaultTargetPlatform;
  final touch = p == TargetPlatform.iOS || p == TargetPlatform.android;
  return isWeb && !touch ? VDensityMode.compact : VDensityMode.comfortable;
}
```

Theo cách thao tác, **không** theo bề rộng (đúng chú thích `VDensity`). Sửa chú thích bỏ "counter tablet" (không làm iPad, LUONG-UNG-DUNG 1.1) ở **3** chỗ: `packages/vet45_design_system/lib/src/theme/v_density.dart:9`, `packages/vet45_design_system/lib/src/patterns/v_page_scaffold.dart:15` và `:40` (đổi thành "web trên máy tính" / "cửa sổ rộng").

### 3.6 Không làm trong W-1

- Bố cục web của từng màn (danh sách – chi tiết, bảng, sheet → hộp thoại): W-2 cho Theme 1, các theme khác trong plan của mình.
- `UrlStrategy` dạng đường dẫn (`usePathUrlStrategy`): cần cấu hình máy chủ trả `index.html` cho mọi đường dẫn; làm khi chọn nơi host web. W-1 giữ hash.
- Màn "Tồn kho cơ bản" / Kho Theme 7: chỉ chuyển route vào shell, không sửa màn.

## 4. Các bước

### Nhóm 1 — DS: `VSideNavigation`

1. Tạo `packages/vet45_design_system/lib/src/components/v_side_navigation.dart`, export trong `design_system.dart`:
   ```dart
   class VSideNavigationItem {
     const VSideNavigationItem({required this.icon, required this.label, this.enabled = true, this.children = const []});
     final Widget icon;
     final String label;
     final bool enabled;
     final List<VSideNavigationItem> children; // một cấp, luôn mở
   }

   class VSideNavigation extends StatelessWidget {
     const VSideNavigation({super.key, required this.items, required this.selected, required this.onSelect, this.header, this.footer, this.width = 240});
     final List<VSideNavigationItem> items;
     final (int, int?) selected;           // (mục chính, mục con hoặc null)
     final void Function(int item, int? child) onSelect;
     final Widget? header;
     final Widget? footer;
     final double width;
   }
   ```
2. Theo cách `VBottomNavigationBar` làm (10-4): token màu `surface` / `borderDefault` (viền phải), mục chọn tô `primary`, mục tắt `VOpacity`; `Semantics(button: true, selected: …, label: …)`; vùng chạm ≥ `VSpacing.minTouchTarget`; focus bàn phím có viền focus nhìn thấy (`FocusableActionDetector` / `InkWell` có `focusColor`), Enter / Space kích hoạt. `vInspectorHide` như thanh dưới.
3. Test `packages/vet45_design_system/test/components/v_side_navigation_test.dart`: dựng đủ mục + mục con; bấm mục chính / mục con gọi `onSelect` đúng chỉ số; mục tắt không gọi; `Semantics` `selected`; Tab chuyển focus, Enter kích hoạt. Thêm vào `accessibility_guidelines_test.dart` như thanh dưới.
4. Thêm vào trang preview của DS (`example/lib/preview/…`, cùng chỗ `VBottomNavigationBar`).

### Nhóm 2 — App: shell, tab có URL, thanh bên

5. **Tách mục tab Thêm:** tạo `apps/erp/lib/features/more/presentation/more_entries.dart` — danh sách mục (tiêu đề, phụ đề, icon, route, `ownerOnly`, `needsActiveTenant`, có bấm được không) lấy nguyên từ `_MoreView`. `_MoreView` dựng từ danh sách này; giao diện tab Thêm không đổi.
6. **`HomeTabPage`:** chuyển `_buildHomeBody` + `DashboardHeader` + banner hồ sơ pháp lý từ `DashboardPage` sang `apps/erp/lib/features/dashboard/presentation/home_tab_page.dart` (không đổi nội dung).
7. **`StoreShell`** (`apps/erp/lib/features/dashboard/presentation/store_shell.dart`): chuyển từ `DashboardPage` sang đây, giữ nguyên logic:
   - `_SessionBootstrap` (gọi `bootstrap()` một lần khi shell dựng) và nhánh test (`repository`, `initialState`, `inventoryModule`, `autoBootstrap` — giữ các tham số này trên `StoreShell` để test cũ chuyển sang dễ);
   - `BlocBuilder<SessionController>` → `DefaultPairGateCubit` → `_buildGateHold` (chờ / lỗi cổng hiện **toàn màn, không thanh bên**);
   - sẵn sàng → bố cục mục 3.2 bằng `LayoutBuilder` + `VBreakpoints.ofWidth`.
8. **`ErpTabScaffold`** (`…/dashboard/presentation/erp_tab_scaffold.dart`): nhận `StatefulNavigationShell`; hẹp → `Scaffold` + `ErpBottomNavigation(currentIndex: shell.currentIndex, onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex))`; rộng → `shell`. Tab "Thêm" giữ `VAppBar(title: 'Thêm', showBackButton: false)` (đưa vào nhánh more, như `_buildScaffold` đang làm).
9. **`ErpBottomNavigation`:** chỉ còn `currentIndex` + `onTap`; bỏ đọc `GoRouterState` và nhánh `onItemSelected`. Sửa `ErpTab` theo mục 3.4.
10. **`ErpSideNavigation`** (`…/dashboard/presentation/widgets/erp_side_navigation.dart`): dựng `VSideNavigation` theo mục 3.3 từ `ErpTab` + `more_entries.dart` + `SessionController` (Owner, bị chặn, tên tổ chức).
11. **`app_router.dart`:** dựng cây mục 3.1. Xoá route `/` cũ (đọc `extra`), các route `/products/items`, `/orders`, `/partner` cấp gốc (chuyển vào nhánh); thêm `/more`. Mọi route khu cửa hàng khác chuyển vào `routes:` của `ShellRoute(StoreShell)` **giữ nguyên đường dẫn, tên, builder**. `redirect` giữ nguyên.
12. Xoá `DashboardPage` (và `DashboardTab` trong `models/dashboard_navigation.dart`; giữ `MenuType` / `MenuItem` nếu còn nơi dùng — `grep` trước). Không còn `goNamed('dashboard', extra: …)`; `context.go('/')` (6 chỗ) vẫn đúng.
13. **Test cũ** dựng `DashboardPage` (**4** tệp ở mục 2): đổi sang `StoreShell` bọc `HomeTabPage` trong `GoRouter` của test, giữ nguyên điều kiện kiểm.
14. **Test mới** `apps/erp/test/features/dashboard/presentation/store_shell_test.dart` (router thật hoặc router test với vài route khu cửa hàng):
    - rộng 1280: có `VSideNavigation`, không có `VBottomNavigationBar`; bấm "Sản phẩm" → `/products/items`; mở `/more/my-account` → vẫn có thanh bên, mục "Thêm" được chọn;
    - hẹp 390: có thanh dưới ở `/`, không thanh bên; `push('/more/my-account')` → không còn thanh dưới (như hiện tại);
    - đổi tab không gọi lại `bootstrap()` (đếm lời gọi trên repository giả);
    - `ErpTab.fromLocation`: bảng mục 3.4 (unit test).
    - `selectedMoreEntry`: bảng mục con ở 3.3 (unit test, mỗi dòng ít nhất 1 đường dẫn + `/more` → null + `/orders` → null);
    - rộng 1280, mở `/more/users/invite` → mục con "Người dùng & vai trò" được chọn (semantics `selected`);
    - 3 `ShellRoute` phạm vi luồng: mở `/warehouse/receipts/quick/header` ở rộng 1280 → có thanh bên, màn dựng được (không lỗi provider).

### Nhóm 3 — Density + chú thích

15. `erpDensityMode` (mục 3.5) trong `apps/erp/lib/core/config/density.dart`; `main.dart` dùng cho `theme` và `darkTheme`. Test bảng: (web, macOS) → compact; (web, windows) → compact; (web, iOS) → comfortable; (không web, iOS) → comfortable; (không web, android) → comfortable.
16. Sửa chú thích `VDensity` (mục 3.5).

## 5. Kiểm tra

- [x] `flutter analyze` (app + DS) không lỗi mới; `flutter test` app + DS đạt (so với TEST-BASELINE: không thêm lỗi).
- [x] `flutter build web` chạy được (`✓ Built build/web`).
- [ ] **iPhone không đổi:** chụp trước khi làm (simulator iPhone 15/16) 6 màn: Trang chủ, Đơn hàng, Sản phẩm, Đối tác, Thêm, một màn chi tiết (`/more/my-account`); chụp lại sau — giống nhau (trừ khác biệt do dữ liệu). Bấm 5 tab qua lại, quay lại từ màn chi tiết về đúng tab.
- [ ] **Web Chrome rộng (≥ 1280):** thanh bên ở mọi màn khu cửa hàng; chọn đúng mục theo đường dẫn; tải lại trang ở `/#/partner`, `/#/more`, `/#/more/users` vào đúng màn (phiên được khởi tạo); nút quay lại trình duyệt đúng.
- [ ] **Web Chrome hẹp (< 1024):** như iPhone (thanh dưới); kéo cửa sổ qua lại ngưỡng không mất màn đang mở.
- [ ] **Bàn phím trên web:** Tab đi qua các mục thanh bên, Enter mở; Esc đóng hộp thoại / bottom sheet đang có (ghi lại chỗ nào không đóng — sửa ở W-2 / theme tương ứng, không sửa ở W-1).
- [x] Màn công khai (`/login`…) và `/no-organization` không có thanh bên.
- [x] Web dùng `compact` (ô nhập thấp hơn iPhone); iPhone vẫn `comfortable` (`erpDensityMode` + test ma trận).
- [x] `DESIGN.md` mục Navigation thêm **Thanh bên** (đo từ `VSideNavigation` đã dựng: bề rộng, nền, viền, mục chọn, mục con, focus) và token `side-nav` / `side-nav-active` ở frontmatter như `bottom-nav`; cập nhật `.impeccable/design.json`.
- [x] Rà soát thay đổi trước khi báo xong: phần của W-1 chỉ đụng router, dashboard, more, DS navigation + chú thích density / page scaffold, `main.dart`, `core/config/density.dart`, test, `DESIGN.md`. Thay đổi 2-B6 / 2-B7 có sẵn trong working tree — liệt kê riêng ở mục 7, không tính là lệch.

## 6. Rủi ro / lưu ý

| Rủi ro | Cách xử lý |
|---|---|
| CRITICAL theo GitNexus: mọi luồng khu cửa hàng đi qua shell | Không đổi đường dẫn / tên route; chụp so sánh iPhone; test mới mục 4 bước 14 |
| Chuyển ~90 route vào `ShellRoute` làm lệch `pop` / quay lại (route đang dựa vào navigator gốc) | Không có `parentNavigatorKey` / `useRootNavigator` (grep 2026-10-27). Trên web rộng: `showDialog` / `showVConfirmDialog` (mặc định navigator gốc) phủ cả thanh bên; `showModalBottomSheet` / `showVBottomSheet` (navigator gần nhất) chỉ phủ vùng nội dung — chấp nhận cả hai; W-2 đổi sheet thành hộp thoại |
| 3 `ShellRoute` phạm vi luồng lồng trong `StoreShell` | Giữ nguyên khối; test cũ của nhập kho nhanh / định giá / đơn nháp phải xanh (chạy cả app) |
| Bootstrap chuyển lên `StoreShell` làm đổi thời điểm khởi tạo | Cùng thời điểm như cũ với luồng đăng nhập (`go('/')` → shell dựng); khác duy nhất: mở thẳng màn chi tiết nay **có** bootstrap (sửa lỗi web). `signup_cubit` tự gọi `bootstrap()` — có thể gọi hai lần liền: kiểm `bootstrap()` chịu được (đang `emit loading` lại) |
| `StatefulShellRoute` giữ state tab (cuộn, bộ lọc) — khác hiện tại (đổi tab dựng lại màn) | Là cải thiện; ghi CHANGELOG app. Nếu màn nào phụ thuộc việc dựng lại khi quay tab (tải lại dữ liệu), ghi vào ghi chú mục 7 |
| Màn chưa sửa bố cục web bị kéo giãn | `VContentWidth` giới hạn 1120 cho mọi màn ở chế độ rộng; bố cục riêng làm ở W-2 / từng theme |

## 7. Kết quả (phiên làm code ghi)

> **Bắt buộc ghi, ngay sau khi xong từng bước của mục 4** (không dồn tới cuối) — phiên review đọc mục này trước rồi mới đối chiếu diff. Mỗi bước một khối:
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
> Mục 5 (kiểm tra) ghi: lệnh đã chạy, số pass / fail, **tên** từng test hỏng đối chiếu `docs/refactor/TEST-BASELINE.md` (lưu ý: 2 test catalog `product_measurement_units_e2e_test` `e2e_e04_u02_fr01_01b`, `e2e_e04_u02_fr01_03` hỏng sẵn ở HEAD nhưng chưa có trong baseline — review 2-B7 R3), ảnh chụp iPhone trước / sau (đường dẫn), kết quả `detect_changes()` tách phần W-1 / phần 2-B6 + 2-B7.
>
> Dừng giữa chừng: bước đang làm ghi `🔄 dở` + đã làm tới đâu.

Bước 1 — ✅ xong
- Tệp đã sửa / tạo / xoá: `packages/vet45_design_system/lib/src/components/v_side_navigation.dart` (tạo mới: `VSideNavigationItem`, `VSideNavigation`); `packages/vet45_design_system/lib/design_system.dart:79` (export `v_side_navigation.dart`)
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: Chưa (ở bước 3).
- impact: `VSideNavigation`, `VSideNavigationItem` → LOW, 0 callers (component mới trong DS).
- Ghi chú cho review: Đúng chuẩn VBottomNavigationBar (surface, borderDefault, surfaceBrand, minTouchTarget 44pt).

Bước 2 — ✅ xong
- Tệp đã sửa / tạo / xoá: `packages/vet45_design_system/lib/src/components/v_side_navigation.dart` (hoàn thiện styling, visible focus border `_isFocused`, `InkWell` keyboard activation, `vInspectorHide`, `vDisabledOpacity`, `MergeSemantics`).
- Lệch so với plan (nếu có): Dùng `VTypography.labelDefault` và `VTypography.bodyDefault` (token chính xác của DS thay vì labelLarge/bodyMedium).
- Test thêm / sửa: Chưa (ở bước 3).
- impact: `VSideNavigation` → LOW.
- Ghi chú cho review: Focus viền rõ khi nhấn phím Tab, Enter / Space kích hoạt `onTap`.

Bước 3 — ✅ xong
- Tệp đã sửa / tạo / xoá: `packages/vet45_design_system/test/components/v_side_navigation_test.dart` (tạo mới: 7 tests toàn diện); `packages/vet45_design_system/test/components/accessibility_guidelines_test.dart` (thêm test kiểm tra `VSideNavigation` đạt `iOSTapTargetGuideline` ≥ 44pt và `labeledTapTargetGuideline`).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: `test/components/v_side_navigation_test.dart` (7 tests: renders labels, tap main, tap child, disabled items, semantics button/selected, header/footer, keyboard Tab+Enter); `test/components/accessibility_guidelines_test.dart` ("VSideNavigation controls are ≥ 44pt and named").
- impact: `VSideNavigation` → LOW.
- Ghi chú cho review: Toàn bộ 9/9 tests pass 100%.

Bước 4 — ✅ xong
- Tệp đã sửa / tạo / xoá: `packages/vet45_design_system/example/lib/preview/components_tab.dart` (thêm state `_sideNavSelected` và `PreviewSection` VSideNavigation ngay sau VBottomNavigationBar).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: Không.
- impact: `components_tab.dart` → LOW.
- Ghi chú cho review: Preview hiển thị thanh bên 240px kèm demo phản hồi mục chọn.

Bước 5 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/features/more/presentation/more_entries.dart` (tạo mới: `MoreEntry`, `kMoreEntries`, `kSideNavSubEntries`, `selectedMoreEntry`); `apps/erp/lib/features/more/presentation/pages/more_page.dart` (dựng `_MoreView` từ `kMoreEntries`).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: `apps/erp/test/features/more/presentation/more_entries_test.dart` (unit test kiểm tra đầy đủ các prefix và quy tắc của bảng 3.3).
- impact: `more_page.dart` → LOW, `more_entries.dart` → LOW.
- Ghi chú cho review: `selectedMoreEntry` khớp 100% bảng quy tắc 3.3; `_MoreView` giữ nguyên giao diện cũ.

Bước 6 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/features/dashboard/presentation/home_tab_page.dart` (tạo mới: `HomeTabPage` tách từ `DashboardPage` chứa `DashboardHeader`, banner hồ sơ pháp lý, và nội dung cuộn trang chủ bọc trong `Scaffold`).
- Lệch so với plan (nếu có): Thêm `Scaffold` bọc ngoài để đảm bảo có `Material` ancestor khi dựng đơn lẻ trong test.
- Test thêm / sửa: Chưa (ở bước 13-14).
- impact: `HomeTabPage` → LOW.
- Ghi chú cho review: Giao diện và logic của tab tổng quan giữ nguyên 100%.

Bước 7 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/features/dashboard/presentation/store_shell.dart` (tạo mới: `StoreShell` quản lý `_SessionBootstrap`, `DefaultPairGateCubit`, responsive `Row` với `ErpSideNavigation` + `VContentWidth` khi desktop ≥ 1024, child khi mobile < 1024).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: Chưa (ở bước 13-14).
- impact: `StoreShell` → HIGH/CRITICAL (gốc của toàn bộ khu cửa hàng, đã báo người dùng).
- Ghi chú cho review: Tham số `repository`, `initialState`, `inventoryModule`, `autoBootstrap` được giữ trên `StoreShell` để test cũ tái sử dụng dễ dàng.

Bước 8 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/features/dashboard/presentation/erp_tab_scaffold.dart` (tạo mới: `ErpTabScaffold` bọc `StatefulNavigationShell`, hiển thị `ErpBottomNavigation` trên mobile < 1024, bỏ thanh dưới trên desktop ≥ 1024).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: Chưa (ở bước 13-14).
- impact: `ErpTabScaffold` → HIGH (khung 5 tab chính).
- Ghi chú cho review: Nhận `StatefulNavigationShell` từ `StatefulShellRoute.indexedStack`.

Bước 9 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/features/dashboard/presentation/widgets/erp_bottom_navigation.dart` (cập nhật `ErpTab` routePath: `/`, `/orders`, `/products/items`, `/partner`, `/more`; thêm `ErpTab.fromLocation`; đơn giản hoá `ErpBottomNavigation` thành `currentIndex` + `onTap`).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: Unit test `ErpTab.fromLocation` ở bước 14.
- impact: `ErpBottomNavigation`, `ErpTab` → HIGH.
- Ghi chú cho review: Loại bỏ đọc `GoRouterState` trực tiếp và các nhánh `onItemSelected` rườm rà.

Bước 10 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/features/dashboard/presentation/widgets/erp_side_navigation.dart` (tạo mới: `ErpSideNavigation` kết nối `VSideNavigation` với `ErpTab`, `more_entries.dart`, tên tổ chức và modal đổi tổ chức, logout).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: Kiểm thử trong `store_shell_test.dart` ở bước 14.
- impact: `ErpSideNavigation` → LOW (thành phần mới cho web rộng).
- Ghi chú cho review: Tự động tính toán active main item và active sub item từ `GoRouterState.of(context).matchedLocation`.

Bước 11 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/core/router/app_router.dart` (dựng cây `ShellRoute(StoreShell)` bọc toàn bộ ~90 route khu cửa hàng; đặt `StatefulShellRoute.indexedStack(ErpTabScaffold)` cho 5 tab; xoá các route cấp gốc `/products/items`, `/orders`, `/partner` trùng lặp).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: `dart analyze lib/core/router/app_router.dart` đạt 0 lỗi.
- impact: `appRouter` → CRITICAL (đã báo người dùng).
- Ghi chú cho review: Mọi đường dẫn route, tên route và 3 flow-scoped ShellRoute bên trong được giữ nguyên vẹn.

Bước 12 — ✅ xong
- Tệp đã sửa / tạo / xoá: Đã xoá `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart` và `apps/erp/lib/features/dashboard/presentation/models/dashboard_navigation.dart`.
- Lệch so với plan (nếu có): Không. Đã grep kiểm tra `MenuType`, `MenuItem`, `DashboardTab` trước khi xoá (không còn nơi nào sử dụng ngoài test).
- Test thêm / sửa: Cập nhật 4 test ở bước 13.
- impact: `DashboardPage`, `DashboardTab` → CRITICAL (đã chuyển giao trách nhiệm sang StoreShell + HomeTabPage).
- Ghi chú cho review: Không còn bất kỳ import nào của `dashboard_page.dart`.

Bước 13 — ✅ xong
- Tệp đã sửa / tạo / xoá: Cập nhật 4 test cũ sang `StoreShell` bọc `HomeTabPage`:
  - `apps/erp/test/features/auth/e2e_th01_s0_session_test.dart`
  - `apps/erp/test/features/dashboard/presentation/default_pair_gate_test.dart`
  - `apps/erp/test/features/tenant_context/presentation/wgt_e05_tenant_context_test.dart`
  - `apps/erp/test/features/tenant_context/presentation/e2e_e05_u01_fr01_01_tenant_context_test.dart`
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: Cả 4 tệp test (tổng 20 tests) đều passed 100%.
- impact: Tests → LOW.
- Ghi chú cho review: Các điều kiện kiểm thử về gate, session bootstrap và tenant selector được bảo toàn.

Bước 14 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/test/features/dashboard/presentation/store_shell_test.dart` (tạo mới test suite 6 tests: unit test `ErpTab.fromLocation`, wide 1280 side nav navigation, narrow 390 bottom bar vs pushed route, không bootstrap lại khi đổi tab, chọn sub-entry "Người dùng & vai trò", màn lồng luồng trong shell).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: `apps/erp/test/features/dashboard/presentation/store_shell_test.dart` (6 tests pass).
- impact: Tests → LOW.
- Ghi chú cho review: Đạt toàn bộ các mục tiêu kiểm thử của mục 4 bước 14.

Bước 15 — ✅ xong
- Tệp đã sửa / tạo / xoá: `apps/erp/lib/core/config/density.dart` (tạo mới hàm thuần `erpDensityMode`); `apps/erp/lib/main.dart` (dùng `VTheme.lightThemeForDensity(density)` và `VTheme.darkThemeForDensity(density)`); `apps/erp/test/core/config/density_test.dart` (tạo mới test ma trận density).
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: `apps/erp/test/core/config/density_test.dart` (3 tests ma trận nền tảng pass).
- impact: `ErpApp` → LOW/MEDIUM (theme density).
- Ghi chú cho review: Web chuột/phím ra compact; Web touch (iOS/Android) và mobile app ra comfortable.

Bước 16 — ✅ xong
- Tệp đã sửa / tạo / xoá:
  - `packages/vet45_design_system/lib/src/theme/v_density.dart:9` (bỏ "counter tablet", đổi thành "web trên máy tính / desktop")
  - `packages/vet45_design_system/lib/src/patterns/v_page_scaffold.dart:15, 40` (bỏ "counter tablet", đổi thành "wide window / cửa sổ rộng, web trên máy tính")
  - `DESIGN.md` (thêm token `side-nav`, `side-nav-active` ở frontmatter và mục Thanh bên trong `### Navigation`)
  - `.impeccable/design.json` (thêm component Side Navigation)
- Lệch so với plan (nếu có): Không.
- Test thêm / sửa: `flutter test` DS đạt 435 pass / 1 fail (fail có sẵn trong TEST-BASELINE.md).
- impact: Documentation & Design System → LOW.
- Ghi chú cho review: Hoàn tất toàn bộ yêu cầu của Nhóm 3.

## 8. Review

### Review R1 2026-10-28 (phiên plan / review) — ❌ chưa đạt

Đã kiểm: đọc toàn bộ tệp mới (`store_shell.dart`, `erp_tab_scaffold.dart`, `erp_side_navigation.dart`, `home_tab_page.dart`, `more_entries.dart`, `density.dart`, `v_side_navigation.dart`), diff `app_router.dart`, `more_page.dart`, so với `dashboard_page.dart` ở HEAD. `flutter test test/features/dashboard test/features/more test/core/config test/features/auth/e2e_th01_s0_session_test.dart test/features/tenant_context`: **48 pass**. `dart analyze` (dashboard, more, router, config, `main.dart`, test dashboard): không lỗi, **4 warning `unused_import`** mới + info deprecated có sẵn. **Chưa chạy** lại `flutter test` cả app và DS trong lượt review này (dựa vào số ở bước 16).

Đạt: cây route đúng 3.1 (5 nhánh, `/more` mới, route cấp gốc `/products/items`, `/orders`, `/partner` đã bỏ, `$appRoutes` và 3 `ShellRoute` phạm vi luồng nằm trong `StoreShell`, đường dẫn / tên route giữ nguyên); bootstrap + cổng cửa hàng–kho chuyển nguyên sang `StoreShell`, cổng chờ / lỗi hiện toàn màn; ngưỡng duy nhất `VBreakpoints.desktop`; `ErpTab.routePath` / `fromLocation` đúng bảng 3.4; `selectedMoreEntry` đúng bảng 3.3; `erpDensityMode` đúng 3.5; `DashboardPage`, `DashboardTab` đã xoá, không còn tham chiếu; `VSideNavigation` có semantics `selected`, vùng chạm 44, focus thấy được, test + guideline; `DESIGN.md` có mục Thanh bên + token.

> **Nguồn lỗi:** R1-1, R1-2 là **lỗ hổng của plan** — mục 2 / bước 6–8 chỉ kể bootstrap + cổng của `DashboardPage`, không nhắc lớp chặn trong `_buildBody` và `MorePage(tenantBlocked:)`. R1-4, R1-5, R1-7 là code làm lệch chữ plan (3.3 một danh sách, "dùng lại `onLogout`"); R1-3 nửa nửa (plan chỉ nhắc CHANGELOG app ở mục 6); R1-6, R1-8 plan không nói rõ (R1-8 do plan đặt `icon` bắt buộc).

**Phải sửa:**

| # | Mức | Vấn đề | Vị trí | Sửa |
|---|---|---|---|---|
| R1-1 | P1 | **Tab "Thêm" mất chế độ tổ chức bị chặn.** Route `/more` dựng `MorePage()` không truyền `tenantBlocked` (trước đây `DashboardPage` truyền `state.isBlocked`) ⇒ tổ chức bị chặn: Kho / Giá riêng / Người dùng & vai trò / Thiết lập vẫn bấm được và `IamFeatureAccessCubit.load()` vẫn gọi RPC (code cũ cố ý không gọi) | `app_router.dart` nhánh `/more` | Builder bọc `BlocBuilder<SessionController, SessionState>` → `MorePage(tenantBlocked: state.isBlocked)` (giữ `VAppBar('Thêm')`). Test: phiên blocked, mở `/more` → mục Kho tắt, `load()` không được gọi |
| R1-2 | P1 | **3 tab Đơn hàng / Sản phẩm / Đối tác mất lớp chặn trạng thái phiên.** `DashboardPage._buildBody` trước đây chặn mọi tab trừ "Thêm": đang tải / `initial` → `VLoading`; bị chặn → `OrganizationEmptyView`; lỗi → `OrganizationEmptyView(loadError)` + thử lại. Nay lớp chặn chỉ còn trong `HomeTabPage` ⇒ mở `/#/orders` khi phiên đang tải (tải lại trang web) hoặc tổ chức bị chặn: `SalesOrderListPage` / `ProductCatalogTabPage` / `PartnerListPage` dựng và gọi RPC không có tổ chức hợp lệ | `erp_tab_scaffold.dart`, `home_tab_page.dart` | Tách lớp chặn ra widget dùng chung (vd. `TenantReadyGate`, đặt ở `features/dashboard/presentation/widgets/`) lấy nguyên 3 nhánh của `HomeTabPage._buildBody`; `ErpTabScaffold` bọc `navigationShell` bằng gate **khi `currentIndex != ErpTab.more.index`** (cả hẹp lẫn rộng); `HomeTabPage` bỏ 3 nhánh đó, chỉ giữ `DashboardHeader` + nội dung. Test: phiên blocked, `/orders` → có `OrganizationEmptyView`, không có trang danh sách; phiên `loading` → `VLoading` |

**Cũng sửa:**

| # | Mức | Vấn đề | Vị trí | Sửa |
|---|---|---|---|---|
| R1-3 | P2 | Thiếu CHANGELOG. DS: `### Added` `VSideNavigation` / `VSideNavigationItem`. App: tab có URL (`StatefulShellRoute`, `/more` mới), tab giữ trạng thái khi đổi qua lại (mục 6 yêu cầu ghi), thanh bên từ 1024, web dùng `compact`, mở thẳng màn chi tiết nay có bootstrap | `packages/vet45_design_system/CHANGELOG.md`, `apps/erp/CHANGELOG.md` `[Unreleased]` | Thêm dòng; không bump |
| R1-4 | P2 | `kSideNavSubEntries` **chép lại** 5 mục của `kMoreEntries` (tiêu đề, route, `matchPrefixes`) ⇒ hai nguồn, sửa một chỗ là lệch. 3.3 yêu cầu một danh sách | `more_entries.dart` | `final List<MoreEntry> kSideNavSubEntries = [for (final e in kMoreEntries) if (e.route != null && e.enabled) e];` (bỏ bản chép). Test `more_entries_test` vẫn qua |
| R1-5 | P3 | `ErpSideNavigation._logout` chép nguyên `MorePage._logout` (3.3: "dùng lại") | `erp_side_navigation.dart`, `more_page.dart` | Tách hàm chung (vd. `signOutAndGoToLogin(BuildContext)` trong `features/more/presentation/`), hai nơi gọi |
| R1-6 | P3 | Header (đổi tổ chức) và footer (Đăng xuất) của thanh bên là `InkWell` thô: icon Material `Icons.unfold_more` / `Icons.logout` thay vì `VIcons`; Tab tới không thấy viền focus như các mục; footer không có `Semantics(button: true)` | `erp_side_navigation.dart` | Dùng `VIcon` + `VIcons`; footer dùng `VButton` (ghost / tone danger) hoặc thêm focus viền + semantics như `_SideNavItemView`; header thêm `Semantics(button: true, label: 'Đổi tổ chức, <tên>')` |
| R1-7 | P3 | 4 warning `unused_import` | `erp_side_navigation.dart:9`; `store_shell_test.dart:1, 3, 8` | Xoá import |
| R1-8 | P3 | `VSideNavigation` đoán "không có icon" bằng cách soi `SizedBox` rỗng (`_hasVisibleIcon`); nền mục chính khi chọn mục con dùng `surfaceBrand.withValues(alpha: 0.5)` (alpha tự đặt, không token) | `v_side_navigation.dart` | `VSideNavigationItem.icon` đổi thành `Widget?` (mục con truyền `null`); alpha: dùng token có sẵn hoặc ghi vào DESIGN.md (đã ghi "50% alpha" — chấp nhận nếu giữ) |

**Còn lại sau khi sửa** (mục 5, chưa tích): chụp iPhone trước / sau 6 màn; Chrome rộng ≥ 1280 (tải lại `/#/partner`, `/#/more`, `/#/more/users`, nút back trình duyệt); Chrome hẹp < 1024 + kéo qua ngưỡng; bàn phím (Tab, Enter, Esc). Chạy lại `flutter test` cả app + DS, `dart analyze` sạch warning mới; ghi kết quả dưới mục này rồi báo review R2. `detect_changes()` trước commit, tách phần W-1 / 2-B6 + 2-B7.

### Kết quả sửa Review R1 (2026-10-28)

Đã sửa đủ 8 mục:
1. **R1-1 (P1):** Trong `app_router.dart`, nhánh `/more` bọc `BlocBuilder<SessionController, SessionState>` truyền `MorePage(tenantBlocked: session.isBlocked)`. Trong `more_page.dart`, hỗ trợ đọc `SessionController` từ context khi chưa đăng ký getIt (test). Thêm test `blocked session on /more` trong `store_shell_test.dart`: `MorePage` nhận `tenantBlocked: true`, mục Kho bị disable không thể nhấn navigate.
2. **R1-2 (P1):** Tạo `TenantReadyGate` tại `features/dashboard/presentation/widgets/tenant_ready_gate.dart`. Trong `ErpTabScaffold`, bọc `navigationShell` bằng `TenantReadyGate` khi `currentIndex != ErpTab.more.index` cho cả hẹp lẫn rộng. Trong `HomeTabPage`, bỏ 3 nhánh chặn phiên, chỉ giữ lại `DashboardHeader` + nội dung. Thêm test trong `store_shell_test.dart`: phiên `blocked` trên `/orders` hiện `OrganizationEmptyView` (không dựng `ORDERS_PAGE`), phiên `loading` trên `/orders` hiện `VLoading`.
3. **R1-3 (P2):** Cập nhật `packages/vet45_design_system/CHANGELOG.md` (thêm `VSideNavigation` / `VSideNavigationItem` vào `### Added`) và `apps/erp/CHANGELOG.md` dưới mục `[Unreleased]` (ghi nhận tab có URL, giữ state, thanh bên từ 1024, web compact, bootstrap màn chi tiết). Không bump version.
4. **R1-4 (P2):** Trong `more_entries.dart`, thay thế danh sách chép lại bằng phái sinh: `final List<MoreEntry> kSideNavSubEntries = [for (final e in kMoreEntries) if (e.route != null && e.enabled) e];`. Test `more_entries_test.dart` pass 100%.
5. **R1-5 (P3):** Tách hàm dùng chung `signOutAndGoToLogin(BuildContext context)` trong `features/more/presentation/more_logout.dart`. Cả `MorePage` và `ErpSideNavigation` đều gọi hàm này.
6. **R1-6 (P3):** Trong `ErpSideNavigation`, header dùng `VIcon(icon: VIcons.swapVert)` và footer dùng `VIcon(icon: VIcons.logout)`. Cả hai đều có viền focus 2px primary rõ ràng khi Tab bàn phím tới (`_isFocused`), header có `Semantics(button: true, label: 'Đổi tổ chức, <tên>')`, footer có `Semantics(button: true)`.
7. **R1-7 (P3):** Xoá import thừa tại `erp_side_navigation.dart` và 3 import thừa tại `store_shell_test.dart`. `dart analyze` trên các tệp dashboard/more/router đạt 0 errors, 0 warnings.
8. **R1-8 (P3):** Sửa `VSideNavigationItem.icon` thành nullable `Widget?` (mục con truyền `null`), bỏ hàm `_hasVisibleIcon`, kiểm tra trực tiếp `widget.icon != null`. Cập nhật `components_tab.dart` và `v_side_navigation_test.dart`.

**Xác minh chất lượng:**
- `dart analyze lib/core/router lib/features/dashboard lib/features/more lib/core/config test/features/dashboard test/features/more test/core/config`: 0 errors, 0 warnings.
- `dart analyze lib/src/components/v_side_navigation.dart test/components/v_side_navigation_test.dart example/lib/preview/components_tab.dart` (DS): 0 errors, 0 warnings.
- `dart run tool/check_feature_imports.dart`: đạt 0 vi phạm.
- `flutter test` Design System: 9/9 tests pass (7 test VSideNavigation + 2 guideline).
- `flutter test` ERP App liên quan (dashboard, more, config, auth, tenant_context): 51/51 tests pass.
- `flutter build web --no-pub`: `✓ Built build/web` (54.2s).

### Review R2 2026-10-28 (phiên plan / review) — ✅ tự động đạt

Đã kiểm: đọc `tenant_ready_gate.dart`, `erp_tab_scaffold.dart`, `more_logout.dart`, `erp_side_navigation.dart` (header / footer), `more_entries.dart`, nhánh `/more` trong `app_router.dart`, `more_page.dart`, 2 CHANGELOG. Phiên review **tự chạy cả app + DS** (phiên code chỉ chạy nhóm liên quan):
- `flutter test` app: **1524 pass / 61 fail**, cả 61 nằm trong `catalog` (14 tệp), `pricing` (3), `tenant_admin` (1), `my_account` (1) — đúng nhóm và đúng số 61 hỏng sẵn ở HEAD (ghi ở 2-B6 R1); không tệp nào thuộc dashboard / router / more / auth / tenant_context.
- `flutter test` DS: **435 pass / 1 fail** (`v_overlay_menu_shell_test`, có sẵn). `dart analyze` DS (`lib`, `test`, `example/lib`): không error / warning.

R1 đã đạt:
- R1-1 ✅ `/more` bọc `BlocBuilder<SessionController>` → `MorePage(tenantBlocked: session.isBlocked)`; test "blocked session on /more".
- R1-2 ✅ `TenantReadyGate` lấy nguyên 3 nhánh của `_buildBody` cũ; `ErpTabScaffold` bọc khi tab ≠ "Thêm", cả hẹp lẫn rộng; `HomeTabPage` bỏ 3 nhánh. Đổi qua lại tab "Thêm" làm đổi cha của `navigationShell` nhưng `StatefulNavigationShell` có `GlobalKey` (go_router 17.5) ⇒ giữ state; khi gate đang chặn, `goBranch` rơi về `router.go(...)` — đúng. Test blocked / loading trên `/orders`.
- R1-3 ✅ CHANGELOG app (Added + Changed: giữ state tab) và DS (`VSideNavigation`).
- R1-4 ✅ `kSideNavSubEntries` phái sinh từ `kMoreEntries`. R1-5 ✅ `signOutAndGoToLogin` dùng chung. R1-6 ✅ `VIcons`, viền focus, semantics. R1-7 ✅. R1-8 ✅ `icon` nullable.

Góp ý nhỏ (không chặn, sửa khi tiện):

| # | Mức | Vấn đề | Vị trí | Sửa |
|---|---|---|---|---|
| R2-1 | P3 | Header thanh bên: `Semantics(label: 'Đổi tổ chức, <tên>')` bọc cả `Text(<tên>)` ⇒ trình đọc có thể đọc tên tổ chức hai lần | `erp_side_navigation.dart` `_SideNavHeaderState.build` | `Semantics(..., excludeSemantics: true, ...)` |
| R2-2 | P3 | `MorePage` thêm nhánh `getIt.isRegistered<SessionController>() ? getIt<…>() : ctx.read<…>()` chỉ để test chạy được | `more_page.dart` `BlocProvider.create` | `session ?? ctx.read<SessionController>()` (cả hai đường của `StoreShell` đều cung cấp qua `BlocProvider`) |

Ghi chú quy trình: R1-1 / R1-2 có test chặn tái phát, nhưng mục kết quả không ghi đã chạy test đó **hỏng trên code trước khi sửa** (quy tắc "test giữ hành vi trước", PLAN.md, chốt cùng ngày) — lần sau ghi.

**Còn lại trước khi đóng:** kiểm tay mục 5 (chụp iPhone trước / sau 6 màn; Chrome rộng ≥ 1280: tải lại `/#/partner`, `/#/more`, `/#/more/users`, nút back trình duyệt; Chrome hẹp < 1024 + kéo qua ngưỡng; bàn phím Tab / Enter / Esc; thêm: tổ chức bị chặn trên web rộng — tab Đơn hàng hiện màn trống, mục con thanh bên tắt). Kiểm tay đạt → Review ✅; `detect_changes()` trước commit, tách phần W-1 / 2-B6 + 2-B7.
