# W-1 — Khung web: thanh bên trái, tab có URL, density theo cách thao tác

> Phase: Web cho app (W) · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Gồm việc: W.1–W.4 ([PLAN mục "Web cho app"](../../PLAN.md)). Ước lượng **~2 ngày, 3 commit**.
> Tài liệu liên quan: [LUONG-UNG-DUNG mục 1.1](../../../02-yeu-cau/LUONG-UNG-DUNG.md) (thiết bị và khung, chốt 2026-10-20), mục 3 (guard), mục 5 (khu cửa hàng); plan 10-4 (nhãn + `Semantics` thanh dưới).
> **Rủi ro GitNexus: CRITICAL** — `DashboardPage` và `ErpBottomNavigation` là gốc của khu cửa hàng (impact upstream 2026-10-20: 100 luồng, 20 module bị ảnh hưởng). Giữ nguyên mọi đường dẫn route và hành vi trên iPhone; kiểm theo mục 5.

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
| Test dựng `DashboardPage` trực tiếp | `test/features/auth/e2e_th01_s0_session_test.dart:57`, `test/features/dashboard/presentation/default_pair_gate_test.dart:110`, `test/features/tenant_context/presentation/wgt_e05_tenant_context_test.dart:51, 389` |
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

Mục được chọn suy ra từ đường dẫn hiện tại (`ErpTab.fromLocation`, mục 3.4). Bấm mục chính → `context.go(tab.routePath)`; bấm mục con → `context.go(route)` (thay ngăn xếp, không chồng màn).

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

Theo cách thao tác, **không** theo bề rộng (đúng chú thích `VDensity`). Sửa chú thích `VDensity`: bỏ "and the counter tablet" (không làm iPad, LUONG-UNG-DUNG 1.1).

### 3.6 Không làm trong W-1

- Bố cục web của từng màn (danh sách – chi tiết, bảng, sheet → hộp thoại): W-2 cho Theme 1, các theme khác trong plan của mình.
- `UrlStrategy` dạng đường dẫn (`usePathUrlStrategy`): cần cấu hình máy chủ trả `index.html` cho mọi đường dẫn; làm khi chọn nơi host web. W-1 giữ hash.
- Màn "Tồn kho cơ bản" / Kho Theme 7: chỉ chuyển route vào shell, không sửa màn.

## 4. Các bước

### Commit 1 — DS: `VSideNavigation`

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

### Commit 2 — App: shell, tab có URL, thanh bên

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
13. **Test cũ** dựng `DashboardPage` (mục 2): đổi sang `StoreShell` bọc `HomeTabPage` trong `GoRouter` của test, giữ nguyên điều kiện kiểm.
14. **Test mới** `apps/erp/test/features/dashboard/presentation/store_shell_test.dart` (router thật hoặc router test với vài route khu cửa hàng):
    - rộng 1280: có `VSideNavigation`, không có `VBottomNavigationBar`; bấm "Sản phẩm" → `/products/items`; mở `/more/my-account` → vẫn có thanh bên, mục "Thêm" được chọn;
    - hẹp 390: có thanh dưới ở `/`, không thanh bên; `push('/more/my-account')` → không còn thanh dưới (như hiện tại);
    - đổi tab không gọi lại `bootstrap()` (đếm lời gọi trên repository giả);
    - `ErpTab.fromLocation`: bảng mục 3.4 (unit test).

### Commit 3 — Density + chú thích

15. `erpDensityMode` (mục 3.5) trong `apps/erp/lib/core/config/density.dart`; `main.dart` dùng cho `theme` và `darkTheme`. Test bảng: (web, macOS) → compact; (web, windows) → compact; (web, iOS) → comfortable; (không web, iOS) → comfortable; (không web, android) → comfortable.
16. Sửa chú thích `VDensity` (mục 3.5).

## 5. Kiểm tra

- [ ] `flutter analyze` (app + DS) không lỗi mới; `flutter test` app + DS đạt (so với TEST-BASELINE: không thêm lỗi).
- [ ] `flutter build web` chạy được.
- [ ] **iPhone không đổi:** chụp trước khi làm (simulator iPhone 15/16) 6 màn: Trang chủ, Đơn hàng, Sản phẩm, Đối tác, Thêm, một màn chi tiết (`/more/my-account`); chụp lại sau — giống nhau (trừ khác biệt do dữ liệu). Bấm 5 tab qua lại, quay lại từ màn chi tiết về đúng tab.
- [ ] **Web Chrome rộng (≥ 1280):** thanh bên ở mọi màn khu cửa hàng; chọn đúng mục theo đường dẫn; tải lại trang ở `/#/partner`, `/#/more`, `/#/more/users` vào đúng màn (phiên được khởi tạo); nút quay lại trình duyệt đúng.
- [ ] **Web Chrome hẹp (< 1024):** như iPhone (thanh dưới); kéo cửa sổ qua lại ngưỡng không mất màn đang mở.
- [ ] **Bàn phím trên web:** Tab đi qua các mục thanh bên, Enter mở; Esc đóng hộp thoại / bottom sheet đang có (ghi lại chỗ nào không đóng — sửa ở W-2 / theme tương ứng, không sửa ở W-1).
- [ ] Màn công khai (`/login`…) và `/no-organization` không có thanh bên.
- [ ] Web dùng `compact` (ô nhập thấp hơn iPhone); iPhone vẫn `comfortable`.
- [ ] `DESIGN.md` mục Navigation thêm **Thanh bên** (đo từ `VSideNavigation` đã dựng: bề rộng, nền, viền, mục chọn, mục con, focus) và token `side-nav` / `side-nav-active` ở frontmatter như `bottom-nav`; tạo lại `.impeccable/design.json` (lệnh `/impeccable document` hoặc agent `impeccable-documenter`) để sidecar khớp.
- [ ] `detect_changes` (GitNexus) trước mỗi commit: chỉ đụng router, dashboard, more, DS navigation, `main.dart`, test.

## 6. Rủi ro / lưu ý

| Rủi ro | Cách xử lý |
|---|---|
| CRITICAL theo GitNexus: mọi luồng khu cửa hàng đi qua shell | Không đổi đường dẫn / tên route; chụp so sánh iPhone; test mới mục 4 bước 14 |
| Chuyển ~90 route vào `ShellRoute` làm lệch `pop` / quay lại (route đang dựa vào navigator gốc) | Hiện không có `parentNavigatorKey` / `useRootNavigator` (`grep` 2026-10-20). Dialog / sheet mở bằng navigator gốc sẽ phủ cả thanh bên — chấp nhận |
| Bootstrap chuyển lên `StoreShell` làm đổi thời điểm khởi tạo | Cùng thời điểm như cũ với luồng đăng nhập (`go('/')` → shell dựng); khác duy nhất: mở thẳng màn chi tiết nay **có** bootstrap (sửa lỗi web). `signup_cubit` tự gọi `bootstrap()` — có thể gọi hai lần liền: kiểm `bootstrap()` chịu được (đang `emit loading` lại) |
| `StatefulShellRoute` giữ state tab (cuộn, bộ lọc) — khác hiện tại (đổi tab dựng lại màn) | Là cải thiện; ghi CHANGELOG app. Nếu màn nào phụ thuộc việc dựng lại khi quay tab (tải lại dữ liệu), ghi vào ghi chú mục 7 |
| Màn chưa sửa bố cục web bị kéo giãn | `VContentWidth` giới hạn 1120 cho mọi màn ở chế độ rộng; bố cục riêng làm ở W-2 / từng theme |

## 7. Ghi chú khi làm

(Bạn ghi lệch plan, vấn đề phát sinh.)

## 8. Review

(Phiên review điền sau khi bạn báo xong.)
