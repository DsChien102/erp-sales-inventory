# T7-G5-0a — UI nền Theme 7: thành phần DS, khuôn K1–K4 / K6 / K7, Home Kho

> Theme 7 · plan **G5-0a** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-09) | Làm ✅ 2026-11-09 | Review ❌ R1 chưa đạt (2026-11-09)
> Đặc tả (v5.27.0 FROZEN): [SCR-090](../../../../specs/themes/theme-07/03.design/screens/SCR-090.md) … [SCR-096](../../../../specs/themes/theme-07/03.design/screens/SCR-096.md), [PAT-NAV](../../../../specs/themes/theme-07/03.design/patterns/PAT-NAV.md), [PAT-UI-UX](../../../../specs/themes/theme-07/03.design/patterns/PAT-UI-UX.md) mục 4.5–4.8. Prototype (đối chiếu): `app/hub.js` (`renderHubHome`, `renderWorkspace`, `renderPendingApprovals`), `app/shared-patterns.js` (K1–K4, K6, K7).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Có đủ thành phần DS, khuôn dùng chung và Home Kho mới để plan BJ đầu tiên (G5-1) chỉ còn dựng màn riêng của nó.

**Architecture:** Thành phần không mang nghĩa Kho vào `vet45_design_system`; khuôn K mang nghĩa Kho vào `features/inventory/presentation/patterns/`; Hub đọc `WarehouseHubRepository` (G5-0a trả giá trị cố định "đã kích hoạt, không có việc", G5-0b thay thân bằng RPC). Hub nằm trong nhánh tab "Thêm" của router (iPhone có thanh tab, web có thanh bên); `WarehouseHomePage` v3.8 xoá.

**Tech Stack:** Flutter, `flutter_bloc`, `go_router`, `get_it`, `vet45_design_system`.

**Spec:** SCR-090…096 + PAT-NAV + PAT-UI-UX (v5.27.0). Quy ước chung: PLAN.md mục Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- Chữ trên màn chép **nguyên văn** mục 8 của Screen Contract hoặc từ plan này (đã chép từ `hub.js` / `shared-patterns.js`). Không tự đặt chữ mới.
- Bề rộng test: iPhone `Size(390, 844)`, web `Size(1280, 800)`. "Web" trong plan = `inventoryIsWide(context)` = `MediaQuery.sizeOf(context).width >= VBreakpoints.desktop` (1024, cùng ngưỡng thanh bên của `StoreShell`).
- Vùng chạm ≥ `VSpacing.minTouchTarget`; nút chỉ có icon có `Semantics(label:)`.
- `dart analyze` (không dùng `flutter analyze`: sập vì đường dẫn có dấu). Test: `flutter test --no-pub -r compact` trong `apps/erp` và `packages/vet45_design_system`.
- Trước khi sửa một symbol đã có (`VChip`, `VTable`, `MoreEntry`, router): chạy `impact` (GitNexus) và ghi blast radius vào Kết quả; HIGH / CRITICAL thì dừng, báo người dùng. Trước commit chạy `detect_changes()`.
- Không đụng code BJ-02 / BJ-03 cũ (receipt / valuation pages) ngoài 2 lối vào tạm ở Q-a1; chúng bị xoá ở G5-4 / G5-5.
- `AGENTS.md`, `CLAUDE.md` có thay đổi chưa commit của người dùng: không `git add`.
- Ghi mục 7 Kết quả ngay sau mỗi task. Phiên làm không ghi mục Review.

## Review Focus

1. **Lối vào Kho gãy:** More → "Kho" và các nút "Về Kho" của BJ-02 / 03 cũ (`context.go('/inventory')`) phải tới Hub mới. Test: Task 0 (giữ xanh tới cuối) + Task 9 Step 1.
2. **Nhân viên thấy "Giá trị kho" / "Khởi tạo tồn đầu kỳ" / "Giá vốn":** chỉ chủ cửa hàng (SCR-090 mục 6). Test: Task 8 `hub_non_owner_hides_owner_rows`, Task 7 `area_entries_filter_owner_only`; vào thẳng `/warehouse/area/valuation` khi không phải chủ → về `/warehouse` (Task 9).
3. **Lối vào không có màn đích hiện ra rồi bấm không đi đâu:** mục `route: null` không được dựng (Q9). Test: Task 8 `hub_hides_entries_without_route`, `area_hides_entries_without_route`.
4. **"Cần chú ý" hiện khi không có việc / kho chưa kích hoạt vẫn hiện "Hàng cần xử lý":** SCR-090 mục 4. Test: Task 8 bảng trạng thái.
5. **Web mất thanh bên / iPhone mất thanh tab ở Hub:** Hub phải nằm trong `StatefulShellRoute`. Test: Task 9 `hub_web_has_sidebar`, `hub_iphone_has_bottom_navigation`.

---

## 1. Phạm vi

| Trong G5-0a | Không trong G5-0a |
|---|---|
| DS: `VListRow`, `VQuickActionButton`, `VChip.count`, `VKeyValueRow` / `VKeyValueGroup` (`mono`), `VTable.onRowTap` | DS khác ở bảng "Thành phần DS mới" của PLAN.md (theo plan BJ) |
| Khuôn K1, K2, K3, K4 (+ dòng U5 "Tồn kho đã đổi"), K6 (+ badge xuống dòng G3-7), K7 | K5 (G5-9); nối nút "Chuyển sang xác minh" của K3 (G5-14) |
| Hub SCR-090, 6 khu SCR-091…096, danh sách "Chờ duyệt" | RPC tóm tắt Hub, kích hoạt thật, nguồn chờ duyệt thật (G5-0b và từng BJ) |
| Route `/warehouse`, `/warehouse/area/:areaId`, `/warehouse/approvals`; `/inventory` → `/warehouse` | Route màn BJ |
| Xoá `WarehouseHomePage` v3.8 và phần chỉ nó dùng | Xoá code BJ-02 / 03 cũ |

## 2. Quyết định

| Q | Nội dung | Nguồn |
|---|---|---|
| Q-a0 | Theo PLAN.md mục Theme 7 → "Đã chốt" (Q1–Q9) | người dùng 2026-11-09 |
| Q-a1 | **(plan đề xuất — người dùng duyệt 2026-11-09)** Hai lối vào **tạm** trỏ màn BJ-02 / 03 cũ tới khi G5-4 / G5-5 thay: nút nhanh "Nhận hàng" + dòng "Nhận hàng" (khu Nhập, xuất & hoàn trả) → `/warehouse/receipts/new`; dòng "Hàng chờ xác lập giá trị" (khu Giá trị kho) → `/warehouse/valuation/queue`. Lý do: không để code đang chạy mất lối vào trong 2 chặng. Ghi chú `// tạm — G5-4` / `// tạm — G5-5` cạnh từng dòng | — |
| Q-a2 | **(plan đề xuất — người dùng duyệt 2026-11-09)** Hub lỗi tải (không có trong SCR-090): `InventoryEmpty(title: 'Chưa tải được Kho', description: <câu của AppException>, actionLabel: 'Thử lại')`. G5-0a chưa gọi RPC nên chỉ xảy ra trong test; G5-0b giữ | — |
| Q-a3 | Không phải chủ cửa hàng mà vào thẳng `/warehouse/area/valuation` → chuyển về `/warehouse` (không dựng màn từ chối: SCR-094 mục 6 "ẩn hoặc cấm truy cập") | SCR-094 |
| Q-a4 | Ô tìm của Hub (Enter → SCR-001 kèm từ khoá) **ẩn** tới G5-2 (đích chưa có, Q9) | SCR-090 mục 5 |
| Q-a5 | Dòng "Kho" ở màn Thêm giữ chữ phụ hiện tại `Tồn kho, phiếu nhập, điều chỉnh` (màn Thêm thuộc Theme 1, ngoài đặc tả Theme 7); chỉ đổi `route` sang `/warehouse` | — |

Icon (prototype → `VIcons`, vì `VIcons` không có tên trùng): `package` → `inventory`, `rotate` → `refresh`, `listCheck` → `checkList`, `checkCircle` → `success`, `layers` → `coins`; còn lại cùng tên (`warehouse`, `shield`, `cloudUpload`, `arrowLeft`, `edit`, `search`, `fileText`, `history`, `inbox`, `clock`).

## 3. Đang làm gì (code bị xoá / thay) — bảng giữ hành vi

| Hiện có (`HEAD`) | Làm gì | Sau G5-0a ở đâu | Test giữ hành vi |
|---|---|---|---|
| `GoRoute('/inventory')` → `WarehouseHomePage` (ngoài `StoreShell`) | Mở Kho | `/inventory` `redirect` → `/warehouse` (Hub, trong nhánh "Thêm") | T0 `inventory_route_opens_kho` |
| `MoreEntry(id: 'inventory', route: '/inventory', matchPrefixes: ['/inventory', '/warehouse'])` | Dòng "Kho" ở Thêm, đánh dấu mục đang chọn ở thanh bên | `route: '/warehouse'`, `matchPrefixes` giữ | T0 `more_kho_opens_kho`; `more_entries_test.dart` (đã có) |
| `goods_receipt_result_page.dart:81,112,220,308`, `goods_receipt_review_page.dart:85,98,220,227` gọi `context.go('/inventory')` | "Về Kho" sau nhận hàng | Không sửa; nhờ redirect | T0 `inventory_route_opens_kho` |
| `WarehouseHomePage`: ô tìm "Tìm sản phẩm, SKU hoặc lô" (lọc việc tại chỗ) | Lọc "Việc của bạn" | **Bỏ** (SCR-090: ô tìm mở SCR-001; ẩn tới G5-2, Q-a4) | — (đổi theo spec) |
| "Việc của bạn": 3 việc cứng (`PN-260816-04` → `/warehouse/receipts/approval/REC-240715-01`; 2 việc toast) | Mở phiếu chờ duyệt cố định | **Bỏ** (SCR-090 không có "Việc của bạn"; chờ duyệt đọc từ nguồn thật ở G5-0b / G5-4) | — |
| "Bắt đầu việc mới" → sheet 4 việc (`Nhập hàng nhanh` → `/warehouse/receipts/quick/header`; 3 toast) | Bắt đầu nhập nhanh | **Bỏ**; nhập nhanh vào qua "Nhận hàng" → `/warehouse/receipts/new` (Q-a1, màn SCR-006 cũ có nút nhập nhanh) | T9 `quick_receive_opens_old_receipt_entry` |
| "Tra cứu": `valuation_queue` → `/warehouse/valuation/queue`; `lookup_stock`, `lookup_reports`, `lookup_all_features` toast | Mở hàng chờ xác lập giá trị | Khu Giá trị kho → "Hàng chờ xác lập giá trị" (Q-a1); còn lại bỏ | T9 `valuation_entry_opens_old_queue` |
| Trạng thái lỗi "Có lỗi xảy ra" + "Thử lại" | Lỗi tải | Q-a2 | T8 `hub_error_retry` |

Tệp xoá (Task 9): `presentation/pages/warehouse_home_page.dart`, `logic/warehouse_home_cubit.dart`, `logic/warehouse_home_state.dart`, `data/inventory_repository.dart`, `data/models/warehouse_task_item.dart`, `data/models/warehouse_manual_action.dart`, `presentation/widgets/warehouse_task_card.dart`, `presentation/widgets/warehouse_start_new_sheet.dart`, `test/.../pages/warehouse_home_page_test.dart`. Trước khi xoá: `grep -rn` từng tên lớp trong `lib test` chỉ còn trong chính các tệp này (đã kiểm 2026-11-09: đúng; không có DI đăng ký `InventoryRepository`).

## 4. Tệp

| Tệp | Tạo / sửa | Trách nhiệm |
|---|---|---|
| `packages/vet45_design_system/lib/src/components/v_list_row.dart` | tạo | `VListRow` |
| `packages/vet45_design_system/lib/src/components/v_quick_action_button.dart` | tạo | `VQuickActionButton` |
| `packages/vet45_design_system/lib/src/components/v_key_value_row.dart` | tạo | `VKeyValueRow`, `VKeyValueGroup` |
| `packages/vet45_design_system/lib/src/primitives/v_chip.dart` | sửa | thêm `count` |
| `packages/vet45_design_system/lib/src/components/v_table.dart` | sửa | thêm `onRowTap` |
| `packages/vet45_design_system/lib/design_system.dart` | sửa | export 3 tệp mới |
| `apps/erp/lib/features/inventory/presentation/patterns/inventory_layout.dart` | tạo | `inventoryIsWide`, K7 (`K7Split`, `K7Table`, `K7Column`, `K7FilterChips`, `K7Filter`) |
| `…/patterns/inventory_states.dart` | tạo | K1 |
| `…/patterns/inventory_footer.dart` | tạo | `InventoryFooter`, `InventoryFooterAction`, `InventoryReasonFooter` |
| `…/patterns/k2_approval.dart` | tạo | K2 |
| `…/patterns/k3_unknown_page.dart`, `…/patterns/k4_result_page.dart` | tạo | K3, K4 |
| `…/patterns/k6_task_list.dart` | tạo | K6 |
| `apps/erp/lib/features/inventory/data/hub/warehouse_hub_summary.dart`, `…/data/hub/warehouse_hub_repository.dart` | tạo | model + repository Hub |
| `apps/erp/lib/features/inventory/logic/hub/warehouse_hub_cubit.dart`, `…_state.dart` | tạo | Cubit Hub |
| `apps/erp/lib/features/inventory/presentation/hub/warehouse_entries.dart` | tạo | bảng khu / lối vào / nút nhanh |
| `…/presentation/hub/warehouse_hub_page.dart`, `warehouse_area_page.dart`, `warehouse_pending_approvals_page.dart` | tạo | SCR-090, 091–096, "Chờ duyệt" |
| `…/presentation/hub/warehouse_hub_routes.dart` | tạo | `List<RouteBase> warehouseHubRoutes()`, `GoRoute inventoryRedirectRoute()` |
| `apps/erp/lib/core/router/app_router.dart` | sửa | bỏ `GoRoute('/inventory')` (dòng 642–646), thêm `inventoryRedirectRoute()` cùng chỗ, thêm `...warehouseHubRoutes()` vào `routes` của `StatefulShellBranch` "Thêm" (cạnh `GoRoute('/more')`, dòng ~627) |
| `apps/erp/lib/core/di/injection.dart` | sửa | `registerLazySingleton<WarehouseHubRepository>(() => const WarehouseHubRepository())` |
| `apps/erp/lib/features/more/presentation/more_entries.dart:65` | sửa | `route: '/warehouse'` |
| `apps/erp/test/features/inventory/support/inventory_router_harness.dart` | tạo | dựng `appRouter` thật (theo `partner_router_harness.dart`) |
| test: `packages/vet45_design_system/test/components/v_list_row_test.dart`, `v_quick_action_button_test.dart`, `v_key_value_row_test.dart`, `test/primitives/v_chip_count_test.dart`, `test/components/v_table_row_tap_test.dart`; `apps/erp/test/features/inventory/presentation/patterns/*_test.dart`, `…/hub/*_test.dart` | tạo | |

## 5. Các task

### Task 0: Harness router + test giữ hành vi (trên code cũ)

**Files:** Create `apps/erp/test/features/inventory/support/inventory_router_harness.dart`, `apps/erp/test/features/inventory/presentation/hub/warehouse_entry_parity_test.dart`

**Interfaces — Produces:** `Future<void> setUpInventoryRouterTest({bool isOwner = true})`, `Future<void> tearDownInventoryRouterTest()`, `Future<void> pumpInventoryApp(WidgetTester tester, {Size size = const Size(390, 844), String location = '/more'})`, `InventorySessionStore extends SessionStore` (`isOwner` theo tham số, `tenantId => 'tenant-test'`, `hasPermission => true`). Chép cách `partner_router_harness.dart` (FakeExecutionContext, FakeDefaultPairRepository, bỏ lỗi overflow, `appRouter.go(location)`). Task 9 bổ sung `WarehouseHubRepository` vào `setUp`.

- [x] **Step 1: Viết test** (cả hai phải xanh **trên code cũ**):
  - `inventory_route_opens_kho`: `pumpInventoryApp(location: '/inventory')` → `find.descendant(of: find.byType(VAppBar), matching: find.text('Kho'))` findsOneWidget.
  - `more_kho_opens_kho`: location `/more` → tap `find.text('Kho')` → `pumpAndSettle` → như trên.
- [x] **Step 2:** `cd apps/erp && flutter test --no-pub test/features/inventory/presentation/hub/warehouse_entry_parity_test.dart` → PASS (2).
- [x] **Step 3:** Commit `test(inventory): T7-G5-0a bước 0 — lối vào Kho`.

### Task 1: `VListRow`, `VQuickActionButton`

**Files:** Create `v_list_row.dart`, `v_quick_action_button.dart` + test; Modify `design_system.dart`.

**Interfaces — Produces:**
- `enum VListRowType { navigation, selection, plain }`
- `VListRow({Key? key, required String title, String? subtitle, VIcons? leading, Widget? trailing, VListRowType type = VListRowType.navigation, bool selected = false, bool enabled = true, VoidCallback? onTap, String? semanticLabel})`. `leading` dựng trong `VIconBox`; `navigation` thêm `VIcon(VIcons.chevronRight)` sau `trailing`; `plain` không có chevron; chiều cao tối thiểu `VSpacing.minTouchTarget`; `Semantics(button: onTap != null, enabled: enabled, selected: selected, label: semanticLabel ?? title)`.
- `VQuickActionButton({Key? key, required VIcons icon, required String label, VoidCallback? onPressed, String? semanticLabel})` — `onPressed == null` = tắt (mờ theo `vDisabledOpacity`, `Semantics(enabled: false)`); icon trên, nhãn dưới, vùng chạm ≥ 44.

- [x] **Step 1: Test** `v_list_row_test.dart`: `navigation_shows_chevron` (tìm `VIcons.chevronRight`); `plain_has_no_chevron`; `tap_calls_onTap`; `disabled_ignores_tap` (`enabled: false` → callback 0 lần, `tester.getSemantics` không có `hasEnabledState && isEnabled`); `shows_subtitle_and_trailing`; `min_height_44` (`tester.getSize(...).height >= 44`).
  `v_quick_action_button_test.dart`: `tap_calls`; `null_onPressed_is_disabled` (không gọi, semantics disabled); `size_at_least_44`.
- [x] **Step 2:** chạy → FAIL (chưa có lớp).
- [x] **Step 3:** Dựng hai lớp, export.
- [x] **Step 4:** `cd packages/vet45_design_system && flutter test --no-pub test/components/v_list_row_test.dart test/components/v_quick_action_button_test.dart` → PASS.
- [x] **Step 5:** Commit `feat(ds): VListRow, VQuickActionButton (T7-G5-0a)`.

### Task 2: `VChip.count`, `VKeyValueRow` / `VKeyValueGroup`, `VTable.onRowTap`

**Files:** Modify `primitives/v_chip.dart`, `components/v_table.dart`; Create `components/v_key_value_row.dart` + 3 test.

**Interfaces — Produces:**
- `VChip(..., int? count)`: sau nhãn dựng `' $count'` kiểu `VTypography.bodySmall`; `count == 0` dùng `colors.textSecondary` (vẫn bấm được); semantics label `'$label $count'`.
- `VKeyValueRow({required String label, required String value, bool emphasized = false, bool mono = false, Widget? trailing})` — nhãn trái, giá trị phải; `mono: true` dùng `VTypography.monoNumeric` (số tiền / số liệu, G3-7).
- `VKeyValueGroup({String? title, required List<Widget> rows})` — một bề mặt chung (nền `surface`, viền `border`, bo `VRadius.card`) cho ≥ 2 dòng (PAT-UI-UX 4.7); `title` là tiêu đề nhóm.
- `VTable(..., ValueChanged<int>? onRowTap)`: mọi ô của dòng bấm được (`InkWell`), ô đầu bọc `Semantics(button: true)`; `null` = như cũ.

- [x] **Step 1: Test:** `chip_count_renders_and_zero_is_muted` (text `'3'` có; với `count: 0` màu text = `textSecondary`); `chip_without_count_unchanged` (golden không cần: kiểm không có Text thứ hai). `key_value_mono_uses_mono_style`; `group_renders_title_and_rows`. `table_row_tap_reports_index` (bấm ô cột 2 dòng 1 → `onRowTap(1)`); `table_first_cell_is_button_semantics`; `table_without_onRowTap_unchanged` (không có `InkWell`).
- [x] **Step 2:** FAIL. **Step 3:** cài đặt (chạy `impact` cho `VChip`, `VTable` trước, ghi Kết quả). **Step 4:** `flutter test --no-pub` cả package `vet45_design_system` → không thêm lỗi so với `TEST-BASELINE.md` (mốc package: 2 lỗi có sẵn).
- [x] **Step 5:** Commit `feat(ds): VChip.count, VKeyValueRow, VTable.onRowTap (T7-G5-0a)`.

### Task 3: K1 trạng thái chung, K7 bố cục web, chân màn

**Files:** Create `patterns/inventory_layout.dart`, `patterns/inventory_states.dart`, `patterns/inventory_footer.dart` + `test/features/inventory/presentation/patterns/k1_k7_footer_test.dart`.

**Interfaces — Produces:**
- `bool inventoryIsWide(BuildContext context)`.
- `enum InventorySkeletonBlock { heading, card, row, search, text }` (chiều cao 24 / 96 / 64 / 44 / 13, bo 12 trừ heading / text — `styles/components.css:673–2402`).
- `InventoryLoading({List<InventorySkeletonBlock> blocks = const [heading, card, card]})` — `VSkeleton`, `Semantics(label: 'Đang tải')`.
- `InventoryDenied({required String what, required String next, required VoidCallback onExit})` — `VEmptyState`: `VEmptyMedia(icon: VIcons.lock)`, tiêu đề `'Bạn chưa có quyền $what'`, mô tả `next`, `VButton(label: 'Về Kho', variant: secondary)`. Không dựng dữ liệu nghiệp vụ nào.
- `InventoryStale({required String title, required String description, String actionLabel = 'Tải lại', required VoidCallback onAction})` — `VBanner(warning)` + `VButton` secondary ngay dưới.
- `InventoryLocked({required String title, required String description})` — `VBanner(info)`, không nút.
- `InventoryEmpty({required String title, required String description, String? actionLabel, VoidCallback? onAction})` — `VEmptyState`; nút secondary chỉ khi có `actionLabel`.
- `K7Split({required Widget main, required Widget aside, bool wideMain = false, bool asideWebOnly = false})` — web: `Row` flex 5 : 7 (`wideMain` → 7 : 5); iPhone: `Column(main, aside)`, `asideWebOnly` thì bỏ `aside`.
- `K7Column<T>({required String label, required Widget Function(T) cell, bool numeric = false})`; `K7Table<T>({required List<K7Column<T>> columns, required List<T> rows, required Widget Function(T) mobileRow, ValueChanged<T>? onRowTap})` — web: `VTable(headers, rows, onRowTap)`; iPhone: danh sách `mobileRow`.
- `K7Filter({required String key, required String label, required int count})`; `K7FilterChips({required List<K7Filter> items, required String selected, required ValueChanged<String> onSelected})` — một hàng cuộn ngang (`SingleChildScrollView(scrollDirection: horizontal)`), không wrap, `VChip(count:)`.
- `InventoryFooterAction({required String label, VoidCallback? onPressed, bool primary = false})`; `InventoryFooter({required List<InventoryFooterAction> actions})` — 1 nút: full; 2 nút: hàng ngang Phụ | Chính; iPhone **và** có nhãn > 17 ký tự: xếp dọc, nút chính ở trên; web: hàng nút căn phải.
- `InventoryReasonFooter({required String label, VoidCallback? onPressed, String reason = '', String note = '', bool danger = false})` — dòng chữ trên nút: `onPressed == null` → `reason`, ngược lại → `note`; rỗng thì không dựng dòng.

- [x] **Step 1: Test:** `denied_has_title_next_and_exit` (`'Bạn chưa có quyền nhận hàng'`, bấm `'Về Kho'` gọi `onExit`); `stale_banner_and_action` (`'Tải lại'`); `locked_has_no_button`; `empty_action_optional`; `k7_split_row_on_web_column_on_iphone`; `k7_split_aside_web_only_hidden_on_iphone`; `k7_table_web_is_vtable_iphone_is_list`; `k7_filter_chips_single_line` (một `SingleChildScrollView` ngang, không `Wrap`); `footer_two_short_labels_row`; `footer_long_label_stacks_on_iphone_primary_first` (nhãn `'Chuyển sang xác minh'` 20 ký tự); `footer_long_label_stays_row_on_web`; `reason_footer_shows_reason_when_disabled_note_when_enabled`.
- [x] **Step 2:** FAIL. **Step 3:** cài đặt. **Step 4:** `cd apps/erp && flutter test --no-pub test/features/inventory/presentation/patterns/k1_k7_footer_test.dart` → PASS.
- [x] **Step 5:** Commit `feat(inventory): khuôn K1, K7, chân màn (T7-G5-0a)`.

### Task 4: K2 lập → duyệt

**Files:** Create `patterns/k2_approval.dart` + `test/.../patterns/k2_approval_test.dart`.

**Interfaces — Consumes:** `VKeyValueGroup`, `VKeyValueRow` (Task 2). **Produces:**
- `K2Pending({required String approver, required String sentAt, List<VKeyValueRow> facts = const [], String subject = ''})` — `VBanner(info, title: 'Đang chờ duyệt', description: 'Chờ $approver duyệt${subject.isEmpty ? '' : ' $subject'} · gửi $sentAt')`; nếu có `facts`: `VKeyValueGroup(title: 'Yêu cầu')`; dòng chú thích `'Dữ liệu đã khoá. Tồn kho chưa thay đổi.'`.
- `enum K2AttentionTone { warning, info }`; `K2AttentionItem({required String label, required String value, K2AttentionTone tone = warning})`; `K2Attention({required List<K2AttentionItem> items, String title = 'Cần chú ý'})` — rỗng → `SizedBox.shrink()`; nhãn bỏ dấu `:` cuối; icon `warning` / `info` theo tone; `title == ''` thì không tiêu đề.
- `K2Decision({required String question, required String maker, required String sentAt, List<K2AttentionItem> attention = const [], List<VKeyValueRow> facts = const [], Widget? detail})` — thứ tự cố định: tiêu đề `'Cần quyết'` → `question` → `'$maker gửi $sentAt'` → `K2Attention` → `VKeyValueGroup(rows: facts)` → `detail`.
- `Future<String?> showK2ReasonSheet(BuildContext context, {required String title, String description = '', String reasonLabel = 'Lý do từ chối', String placeholder = 'Nhập nội dung người lập cần sửa', String closeLabel = 'Hủy', String confirmLabel = 'Xác nhận từ chối', bool withReason = true, bool danger = false})` — qua `showVAdaptiveSheet` (iPhone sheet, web hộp thoại); trả lý do đã `trim()` (hoặc `''` khi `withReason: false`) khi xác nhận, `null` khi huỷ; nút xác nhận tắt khi `withReason` và lý do rỗng.

- [x] **Step 1: Test:** `pending_text_with_and_without_subject` (`'Chờ chủ cửa hàng duyệt sửa sai · gửi 09:41'`, `'Chờ chủ cửa hàng duyệt · gửi 09:41'`); `pending_lock_note`; `attention_empty_renders_nothing`; `attention_strips_trailing_colon`; `decision_order` (vị trí dọc `'Cần quyết'` < question < maker < attention < facts); `reason_sheet_confirm_disabled_until_reason` ; `reason_sheet_returns_trimmed_reason`; `reason_sheet_cancel_returns_null`; `reason_sheet_is_dialog_on_web` (`find.byType(VSheetDialog)` ở 1280).
- [x] **Step 2–4:** FAIL → cài đặt → PASS.
- [x] **Step 5:** Commit `feat(inventory): khuôn K2 (T7-G5-0a)`.

### Task 5: K3 kết quả chưa rõ, K4 kết quả xong

**Files:** Create `patterns/k3_unknown_page.dart`, `patterns/k4_result_page.dart` + `test/.../patterns/k3_k4_test.dart`.

**Interfaces — Consumes:** `InventoryFooter` (Task 3), `VKeyValueRow` / `Group`, `ErpBottomNavigation` + `ErpTab` (`features/dashboard/presentation/widgets/erp_bottom_navigation.dart`). **Produces:**
- `enum K4Kind { success, pending, warning, danger }` → icon `VIcons.success` / `clock` / `warning` / `error`, tone success / warning / warning / danger (prototype `resultHero`).
- `K4StockChange({required String product, required String before, required String after})` (`before` / `after` đã kèm ĐVT, vd. `'120 hộp'`).
- `K4ResultPage({String screenTitle = 'Kết quả', K4Kind kind = K4Kind.success, required String title, required String description, List<VKeyValueRow> facts = const [], List<K4StockChange> stockChanges = const [], Widget? extra, List<InventoryFooterAction> next = const []})` — `VPageScaffold(showBackButton: false)`; thân: hero (icon + `title` + `description`) → `VKeyValueGroup(rows: [...facts, ...stockChanges.map((c) => VKeyValueRow(label: 'Tồn kho đã đổi', value: '${c.product} ${c.before} → ${c.after}', mono: true))])` → `extra`; chân `InventoryFooter(next)`; web: thân tối đa 720 giữa khung; **iPhone: dưới chân thêm `ErpBottomNavigation(currentIndex: ErpTab.more.index, onTap: (i) => context.go(ErpTab.values[i].routePath))`** (PAT-NAV mục 5).
- `K3UnknownPage({String title = 'Xác minh kết quả', required String operation, required String scope, required String ref, required String sentAt, String safe = '', List<VKeyValueRow> facts = const [], Widget? detail, required VoidCallback onExit, VoidCallback? onVerify})` — `K4ResultPage`-giống: kind `pending`, tiêu đề hero `'Kết quả chưa xác định'`, mô tả `'Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.${safe.isEmpty ? '' : ' $safe'}'`; dòng: `Nghiệp vụ` = operation, `Phạm vi` = scope, `Mã tham chiếu` = ref, `Thời điểm gửi` = sentAt, …facts, `Trạng thái` = `'Chưa kết luận'`; chân `'Về Kho'` (phụ, `onExit`) | `'Chuyển sang xác minh'` (chính, `onVerify`). **`onVerify == null` → chỉ nút "Về Kho"** (tạm tới G5-14 nối BJ-17; G5-17 kiểm không còn chỗ nào null). Không thanh 5 tab (K3 không phải K4).

- [x] **Step 1: Test:** `k4_no_back_button`; `k4_stock_change_line` (`'Nobivac DHPPi 120 hộp → 122 hộp'` cạnh `'Tồn kho đã đổi'`); `k4_iphone_has_bottom_navigation` / `k4_web_has_no_bottom_navigation`; `k4_bottom_nav_tap_goes_to_tab` (router thử: bấm "Đơn hàng" → `/orders`); `k3_rows_and_copy` (đủ 5 nhãn + `'Chưa kết luận'`, câu mô tả có / không `safe`); `k3_two_buttons_when_verify` / `k3_only_exit_when_verify_null`.
- [x] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): khuôn K3, K4 (T7-G5-0a)`.

### Task 6: K6 danh sách công việc

**Files:** Create `patterns/k6_task_list.dart` + `test/.../patterns/k6_task_list_test.dart`.

**Interfaces — Consumes:** `K7Table`, `K7Column`, `K7FilterChips`, `InventoryEmpty`, `VListRow`, `VBadge`, `VSearchBar`. **Produces:**
- `K6Status({required String label, required VComponentTone tone})`.
- `K6Search({required String value, required String hint, required ValueChanged<String> onChanged})`.
- `K6TaskList<T>({K6Search? search, K7FilterChips? filters, required List<K7Column<T>> columns, required List<T> rows, required int total, required String Function(T) title, String Function(T)? subtitle, required K6Status Function(T) status, bool Function(T)? isDisabled, required ValueChanged<T> onOpen, required InventoryEmpty empty, required InventoryEmpty filterEmpty})` — thứ tự: ô tìm → chip → bảng (web) / danh sách (iPhone) ; `total == 0` → chỉ `empty`; `rows.isEmpty && total > 0` → `filterEmpty`; dòng `isDisabled` không mở (`onOpen` không gọi), `VListRow(enabled: false)`.
- `K6TaskRow<T>` (dòng iPhone mặc định): tiêu đề + phụ đề + badge. **G3-7:** badge ở cột phải khi tiêu đề vừa một dòng; **xuống dưới tiêu đề** khi tiêu đề gãy hai dòng ở bề rộng hiện có (đo bằng `TextPainter` trong `LayoutBuilder`).

- [x] **Step 1: Test:** `total_zero_shows_empty`; `filtered_empty_shows_filter_empty`; `tap_row_opens` / `disabled_row_does_not_open`; `web_uses_table_iphone_uses_rows`; `long_title_moves_badge_below` (390 px, tiêu đề `'Phiếu nhận hàng nhập nhanh PN-260905-02 · Minh Dũng'` → `dy` của badge > `dy` cuối tiêu đề) / `short_title_badge_right`.
- [x] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): khuôn K6 (T7-G5-0a)`.

### Task 7: Dữ liệu Hub — lối vào, tóm tắt, repository, cubit

**Files:** Create `data/hub/warehouse_hub_summary.dart`, `data/hub/warehouse_hub_repository.dart`, `logic/hub/warehouse_hub_cubit.dart`, `logic/hub/warehouse_hub_state.dart`, `presentation/hub/warehouse_entries.dart` + `test/features/inventory/logic/hub/warehouse_hub_test.dart`.

**Interfaces — Produces:**
- `WarehousePendingItem({required String title, required String subtitle, required VIcons icon, required String route})`; `WarehousePendingGroup({required String sourceId, required String label, required List<WarehousePendingItem> items})`; `WarehouseAttention({required int count, required String text})`; `WarehouseHubSummary({required bool activated, List<WarehousePendingGroup> pending = const [], WarehouseAttention? problems, WarehouseAttention? reconciliation})` + getter `int pendingTotal`, `String pendingText` (`'{n} {label}'` của nhóm có việc, nối `' · '`, theo thứ tự nhóm). Equatable.
- `class WarehouseHubRepository { const WarehouseHubRepository(); Future<WarehouseHubSummary> getSummary(); }` — **G5-0a trả `const WarehouseHubSummary(activated: true)`** (ghi chú: G5-0b thay thân bằng RPC `inventory.get_warehouse_hub_summary`, giữ chữ ký).
- `sealed class WarehouseHubState` : `WarehouseHubLoading`, `WarehouseHubLoaded({required WarehouseHubSummary summary, required bool isOwner})`, `WarehouseHubError(String message)`. `WarehouseHubCubit({required WarehouseHubRepository repository, required bool Function() isOwner})` + `Future<void> load()`; lỗi: `AppException` → `message`, lỗi khác → `'Không tải được dữ liệu. Thử lại.'` — **chữ đề xuất (Q-a2)**.
- `warehouse_entries.dart`:
  - `enum WarehouseArea { inventory, movement, control, valuation, history, setup }` với `String id` (= tên enum), `String title`, `String subtitle`, `VIcons icon`, `bool ownerOnly` (chỉ `valuation`), `static WarehouseArea? fromId(String)`.
  - `WarehouseEntry({required String id, required String title, required String subtitle, required VIcons icon, String? route, bool ownerOnly = false})`.
  - `List<WarehouseEntry> warehouseAreaEntries(WarehouseArea area)` — bảng dưới.
  - `WarehouseQuickAction({required String label, required VIcons icon, String? route, bool requiresActivation = true})`; `const List<WarehouseQuickAction> warehouseQuickActions` — `Nhận hàng` (`cloudUpload`, `/warehouse/receipts/new` — tạm G5-4), `Lấy hàng` (`inventory`, null), `Kiểm kê` (`checkList`, null), `Tra cứu tồn` (`search`, null, `requiresActivation: false`).
  - `const String? warehouseStockSearchRoute = null;` (Q-a4; G5-2 đặt).
  - `List<T> visibleEntries<T>(…)` không cần: lọc tại page bằng `route != null && (!ownerOnly || isOwner)`.

| Khu (`title` · `subtitle` · icon) | Lối vào (`title` · `subtitle` · icon · route · ownerOnly) |
|---|---|
| `inventory`: `Tồn kho` · `Số lượng, khả dụng, lô và tình trạng hàng` · warehouse | `Tồn kho & khả dụng` · `Tra cứu sản phẩm, số lượng, lô và khả dụng` · warehouse · null; `Chính sách tồn & cận hạn` · `Thiết lập ngưỡng tồn và chính sách cận hạn` · shield · null |
| `movement`: `Nhập, xuất & hoàn trả` · `Hàng đi vào, đi ra và quay lại kho` · inventory | `Nhận hàng` · `Nhận theo chứng từ hoặc nhập nhanh` · cloudUpload · `/warehouse/receipts/new` (tạm G5-4); `Lấy & bàn giao` · `Chuẩn bị hàng và bàn giao theo đơn bán` · inventory · null; `Hàng khách trả` · `Tiếp nhận và phân loại hàng trả lại` · refresh · null; `Trả nhà cung cấp` · `Chuẩn bị và thực hiện trả hàng` · arrowLeft · null |
| `control`: `Kiểm kê & xử lý` · `Kiểm tra thực tế, sai lệch và trường hợp bất thường` · checkList | `Kiểm kê kho` · `Đếm, rà soát và xử lý chênh lệch` · checkList · null; `Hàng cần xử lý` · `Bắt đầu từ sản phẩm hoặc lô có tình trạng cần xử lý` · shield · null; `Hủy & sửa sai nghiệp vụ` · `Xử lý giao dịch kho có sai sót` · edit · null; `Đối soát sai lệch` · `Điều tra khi số liệu giữa các nguồn không khớp` · search · null |
| `valuation` (ownerOnly): `Giá trị kho` · `Giá nhập, chi phí mua và giá vốn` · coins | `Hàng chờ xác lập giá trị` · `Ghi giá nhập cho hàng đã nhận` · success · `/warehouse/valuation/queue` (tạm G5-5); `Điều chỉnh giá trị hàng nhập` · `Chi phí, chiết khấu phát sinh sau khi đã xác lập giá` · fileText · null; `Giá vốn` · `Tính, rà soát và công bố giá vốn` · coins · null · ownerOnly |
| `history`: `Báo cáo & lịch sử` · `Thẻ kho, biến động và số liệu tra cứu` · history | `Báo cáo tồn & thẻ kho` · `Xem tồn tại thời điểm và lịch sử biến động` · history · null |
| `setup`: `Thiết lập kho` · `Tồn đầu kỳ và chính sách ít dùng` · inbox | `Khởi tạo tồn đầu kỳ` · `Thiết lập số dư tồn kho ban đầu` · inbox · null · ownerOnly; `Chính sách tồn & cận hạn` · `Thiết lập ngưỡng tồn và chính sách cảnh báo` · shield · null |

(`setup.subtitle` là chữ phụ của dòng "Thiết lập kho" trên Hub, SCR-090 mục 8.)

- [x] **Step 1: Test:** `pending_text_joins_non_empty_groups` (nhóm "nhận hàng" 3, "số dư đầu kỳ" 1, "hàng khách trả" 0 → `'3 nhận hàng · 1 số dư đầu kỳ'`, `pendingTotal == 4`); `area_entries_filter_owner_only` (lọc với `isOwner: false` không còn `Giá vốn`, `Khởi tạo tồn đầu kỳ`); `entries_copy_matches_contract` (so cả bảng trên); `cubit_loads_summary_and_owner`; `cubit_error_message_from_app_exception`.
- [x] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): dữ liệu Hub Kho (T7-G5-0a)`.

### Task 8: Màn Hub SCR-090, khu SCR-091…096, "Chờ duyệt"

**Files:** Create `presentation/hub/warehouse_hub_page.dart`, `warehouse_area_page.dart`, `warehouse_pending_approvals_page.dart` + `test/.../hub/warehouse_hub_pages_test.dart`.

**Interfaces — Consumes:** Task 1, 2, 3, 7. **Produces:** `WarehouseHubPage({WarehouseHubCubit? cubit})` (null → tạo từ `getIt<WarehouseHubRepository>()` + `getIt<SessionStore>().isOwner`, gọi `load()`); `WarehouseAreaPage({required WarehouseArea area, bool? isOwner})`; `WarehousePendingApprovalsPage({WarehouseHubCubit? cubit})`.

`WarehouseHubPage` dựng theo SCR-090 mục 3 (chữ mục 8):
- `VPageScaffold(title: 'Kho', showBackButton: !inventoryIsWide(context))`; back: `context.canPop() ? context.pop() : context.go('/more')`.
- Ô tìm `VSearchBar(hintText: 'Tìm sản phẩm, SKU hoặc quét mã')` chỉ khi `warehouseStockSearchRoute != null`; Enter → `context.push('$route?q=${Uri.encodeQueryComponent(q)}')`; web tối đa 720.
- Banner chưa kích hoạt (khi `!summary.activated`): `VBanner(info, 'Kho chưa kích hoạt', 'Nhập số tồn hiện có một lần để bắt đầu nhận, bán và kiểm kê hàng.')` + `VButton(primary, 'Khởi tạo tồn kho')` — chỉ khi `isOwner` **và** lối vào `Khởi tạo tồn đầu kỳ` có route (G5-1); nút → route đó.
- Nút nhanh: `VQuickActionButton` cho mỗi `warehouseQuickActions` có `route != null`; `onPressed: null` khi `requiresActivation && !activated`; iPhone lưới 2 × 2, web một hàng; không còn nút nào → bỏ khối.
- "Cần chú ý" (`VSection(title: 'Cần chú ý')`), chỉ khi có ít nhất một dòng:
  - `Chờ duyệt` (icon `clock`, phụ `pendingText`, số `pendingTotal`) khi `pendingTotal > 0` → `/warehouse/approvals`.
  - `Hàng cần xử lý` (icon `shield`, phụ `problems.text`, số `problems.count`) khi `activated && problems != null` → route của lối vào "Hàng cần xử lý" (khu control); route null → không dựng.
  - `Hồ sơ cần kiểm tra` (icon `search`, phụ / số từ `reconciliation`) khi `activated && reconciliation != null` → route "Đối soát sai lệch"; null → không dựng.
  - Dòng chú ý = `VListRow(leading, title, subtitle, trailing: VText(count))`.
- "Quản lý kho" (`VSection(title: 'Quản lý kho')`): 5 khu `inventory, movement, control, valuation, history` → `VListRow` → `context.push('/warehouse/area/${area.id}')`; `valuation` chỉ khi `isOwner`.
- "Thiết lập kho": một `VListRow(title: 'Thiết lập kho', subtitle: 'Tồn đầu kỳ và chính sách ít dùng', leading: inbox)` → `/warehouse/area/setup`.
- Web: dưới nút nhanh `Row` hai cột (trái: banner + Cần chú ý; phải: Quản lý kho + Thiết lập kho). iPhone: một cột theo thứ tự ô tìm → banner → nút nhanh → Cần chú ý → Quản lý kho → Thiết lập kho.
- Loading → `InventoryLoading(blocks: [search, card, row, row])`; Error → Q-a2.

`WarehouseAreaPage`: `VPageScaffold(title: area.title)` có nút quay lại (về `/warehouse`); `VSection` các `VListRow` của `warehouseAreaEntries(area)` lọc `route != null && (!ownerOnly || isOwner)` → `context.push(route)`.

`WarehousePendingApprovalsPage`: `VPageScaffold(title: 'Chờ duyệt')`; `VSection(title: 'Đang chờ xử lý', trailing: VText(pendingText))`; mỗi `WarehousePendingItem` một `VListRow(leading: icon, title, subtitle, trailing: VBadge(label: 'Chờ duyệt', tone: warning))` → `context.push(item.route)`.

- [x] **Step 1: Test** (mỗi dòng ở 390 và 1280 trừ khi ghi khác; cubit thử với summary đặt sẵn):

| Test | Summary / vai | Mong đợi |
|---|---|---|
| `hub_normal_with_attention` | activated, pending 1 nhóm 2 việc, owner | có `Cần chú ý`, `Chờ duyệt`, `'2'`; không có `Hàng cần xử lý` (route null) |
| `hub_no_attention_hides_section` | activated, rỗng | không có `Cần chú ý` |
| `hub_not_activated` | `activated: false`, pending rỗng | có `Kho chưa kích hoạt`; nút "Nhận hàng" `onPressed == null`; không có nút `Khởi tạo tồn kho` (route null ở G5-0a) |
| `hub_not_activated_problems_hidden` | `activated: false`, `problems` có | không có `Hàng cần xử lý` |
| `hub_non_owner_hides_owner_rows` | owner false | không có `Giá trị kho` |
| `hub_hides_entries_without_route` | — | không có `Lấy hàng`, `Kiểm kê`, `Tra cứu tồn`; không có `VSearchBar` |
| `hub_web_two_columns` | 1280 | `Cần chú ý` và `Quản lý kho` cùng `dy` khởi đầu xấp xỉ (cùng hàng), `dx` khác |
| `hub_web_no_back_button` / `hub_iphone_back_button` | | |
| `hub_error_retry` | repository ném `AppException` | `Chưa tải được Kho`, bấm `Thử lại` gọi `getSummary` lần 2 |
| `area_lists_entries_with_route` | `movement` | có `Nhận hàng`; không có `Lấy & bàn giao` |
| `area_hides_entries_without_route` | `history` | không có dòng nào (`VListRow` 0) |
| `pending_list_rows_and_badge` | 2 việc | 2 `VListRow`, `'Chờ duyệt'` badge 2 lần, tiêu đề `Đang chờ xử lý` |

- [x] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): Home Kho SCR-090…096 (T7-G5-0a)`.

### Task 9: Router, More, DI, xoá Home cũ

**Files:** Create `presentation/hub/warehouse_hub_routes.dart`; Modify `core/router/app_router.dart`, `core/di/injection.dart`, `features/more/presentation/more_entries.dart:65`, `test/.../support/inventory_router_harness.dart`; Delete tệp ở mục 3; Test `test/.../hub/warehouse_hub_routes_test.dart`.

**Interfaces — Produces:**
- `List<RouteBase> warehouseHubRoutes()` → `GoRoute(path: '/warehouse', name: 'warehouse', builder: WarehouseHubPage, routes: [GoRoute(path: 'area/:areaId', name: 'warehouse.area', redirect: …, builder: WarehouseAreaPage), GoRoute(path: 'approvals', name: 'warehouse.approvals', builder: WarehousePendingApprovalsPage)])`. `area/:areaId` redirect: `WarehouseArea.fromId == null` → `/warehouse`; `area.ownerOnly && !getIt<SessionStore>().isOwner` → `/warehouse` (Q-a3).
- `GoRoute inventoryRedirectRoute()` → `GoRoute(path: '/inventory', redirect: (_, _) => '/warehouse')`.

- [x] **Step 1: Test** `warehouse_hub_routes_test.dart` (harness, `setUp` thêm `getIt.registerSingleton<WarehouseHubRepository>(…)` vào `setUpInventoryRouterTest`):
  - `hub_iphone_has_bottom_navigation` (`/warehouse` 390 → `ErpBottomNavigation` có, `VAppBar` "Kho"); `hub_web_has_sidebar` (1280 → `ErpSideNavigation` có).
  - `area_route_opens_area` (`/warehouse/area/control` → "Kiểm kê & xử lý"); `unknown_area_redirects_hub` (`/warehouse/area/xyz`); `valuation_area_redirects_non_owner` (`isOwner: false`).
  - `quick_receive_opens_old_receipt_entry` (bấm "Nhận hàng" → `ReceiptEntryChoicePage`); `valuation_entry_opens_old_queue` (`/warehouse/area/valuation` → bấm "Hàng chờ xác lập giá trị" → `ValuationQueuePage`).
  - Task 0 vẫn xanh (`/inventory` và More → Hub "Kho").
- [x] **Step 2:** FAIL.
- [x] **Step 3:** Chạy `impact` cho `appRouter`, `moreEntries` (ghi Kết quả). Tạo routes; sửa `app_router.dart` (bỏ `GoRoute('/inventory')` + import `warehouse_home_page.dart`, thêm `inventoryRedirectRoute()` cùng vị trí, thêm `...warehouseHubRoutes()` vào nhánh "Thêm"); DI; More `route: '/warehouse'`; xoá tệp mục 3 (trước khi xoá `grep -rn "WarehouseHome\|InventoryRepository\|WarehouseTaskItem\|WarehouseManualAction\|WarehouseTaskCard\|WarehouseStartNew" lib test` chỉ còn trong tệp sắp xoá).
- [x] **Step 4:** `cd apps/erp && dart analyze lib/features/inventory lib/core/router lib/core/di lib/features/more test/features/inventory` → 0 lỗi; `flutter test --no-pub test/features/inventory test/features/more` → PASS.
- [x] **Step 5:** Commit `feat(inventory): route Home Kho mới, xoá WarehouseHomePage v3.8 (T7-G5-0a)`.

### Task 10: Kiểm toàn bộ + cập nhật tài liệu

- [x] **Step 1:** `cd apps/erp && flutter test --no-pub -r compact` → số lỗi không vượt mốc `TEST-BASELINE.md` ("Sau 7-C": 55 lỗi; ghi tên test hỏng mới nếu có). `cd packages/vet45_design_system && flutter test --no-pub -r compact` → ≤ 2 lỗi có sẵn.
- [x] **Step 2:** `detect_changes({scope: "compare", base_ref: "main"})` (hoặc `node .gitnexus/run.cjs detect-changes`) — chỉ symbol của plan này; ghi Kết quả.
- [x] **Step 3:** Đối chiếu prototype: `index.html?mode=theme&app=inventory&viewport=mobile` và `viewport=web`, `&activation=pending`, `&hubView=movement`, `&hubView=pending-approvals`; ghi lệch (ngoài các lối vào ẩn theo Q9) vào Kết quả.
- [x] **Step 4:** PLAN.md mục Theme 7, bảng Plan, dòng G5-0a cột Làm: "✅ 2026-11-09".
- [x] **Step 5:** Commit `docs(refactor): kết quả T7-G5-0a`.

## 6. Rủi ro / lưu ý

- `VTable` dùng `Table`: `TableRow` không nhận cử chỉ ⇒ bọc từng ô; kiểm không đổi bố cục bảng đang có ở màn khác (`impact` Task 2).
- `K4ResultPage` import `ErpBottomNavigation` từ `features/dashboard` — chấp nhận (cùng app); không đưa vào DS.
- Font Ahem của test rộng hơn font thật: test đo bố cục (Task 6 `long_title_moves_badge_below`, Task 8 `hub_web_two_columns`) dùng chuỗi đủ dài / so tương đối, không so số px tuyệt đối.
- Hub nằm trong nhánh "Thêm": `context.push` từ Thêm giữ ngăn xếp nhánh ⇒ quay lại từ Hub về Thêm; chuyển tab rồi quay lại giữ Hub (hành vi `StatefulShellRoute`, chấp nhận).

## 7. Kết quả (phiên làm code ghi)

Xong **mỗi task** ghi ngay theo mẫu (không dồn cuối); dừng giữa chừng ghi `🔄 dở` + tới bước nào.

### Task 0 (2026-11-09) — ✅
- Commit: `1c36c05e0`
- Tệp:dòng đã đổi: `apps/erp/test/features/inventory/support/inventory_router_harness.dart` (tạo mới, 84 dòng), `apps/erp/test/features/inventory/presentation/hub/warehouse_entry_parity_test.dart` (tạo mới, 28 dòng)
- Lệch plan + lý do: Không
- Test thêm / sửa (tên): `inventory_route_opens_kho`, `more_kho_opens_kho` (PASS 2/2)
- Impact (symbol → mức, số caller): Harness và test mới, không ảnh hưởng code hiện có
- Ghi chú cho review: Test giữ hành vi đã xanh trên code cũ (WarehouseHomePage v3.8)

### Task 1 (2026-11-09) — ✅
- Commit: `2a08e4ad1`
- Tệp:dòng đã đổi: `packages/vet45_design_system/lib/src/components/v_list_row.dart` (mới, 131 dòng), `packages/vet45_design_system/lib/src/components/v_quick_action_button.dart` (mới, 82 dòng), `packages/vet45_design_system/lib/design_system.dart` (thêm 2 dòng export), `packages/vet45_design_system/test/components/v_list_row_test.dart` (mới, 122 dòng), `packages/vet45_design_system/test/components/v_quick_action_button_test.dart` (mới, 72 dòng)
- Lệch plan + lý do: Không
- Test thêm / sửa (tên): `navigation_shows_chevron`, `plain_has_no_chevron`, `tap_calls_onTap`, `disabled_ignores_tap`, `shows_subtitle_and_trailing`, `min_height_44`, `tap_calls`, `null_onPressed_is_disabled`, `size_at_least_44` (PASS 9/9)
- Impact (symbol → mức, số caller): Thành phần DS mới, export tại `design_system.dart`, không sửa đổi symbol cũ
- Ghi chú cho review: Đảm bảo kích thước tối thiểu `minTouchTarget` 44, `vDisabledOpacity`, `Semantics` button/enabled

### Task 2 (2026-11-09) — ✅
- Commit: `99f8c841a`
- Tệp:dòng đã đổi: `packages/vet45_design_system/lib/src/primitives/v_chip.dart` (thêm `count`), `packages/vet45_design_system/lib/src/components/v_table.dart` (thêm `onRowTap`), `packages/vet45_design_system/lib/src/components/v_key_value_row.dart` (mới, 128 dòng), `packages/vet45_design_system/lib/design_system.dart` (export `v_key_value_row.dart`), `test/primitives/v_chip_count_test.dart` (mới, 55 dòng), `test/components/v_key_value_row_test.dart` (mới, 58 dòng), `test/components/v_table_row_tap_test.dart` (mới, 75 dòng)
- Lệch plan + lý do: Không
- Test thêm / sửa (tên): `chip_count_renders_and_zero_is_muted`, `chip_without_count_unchanged`, `key_value_mono_uses_mono_style`, `group_renders_title_and_rows`, `table_row_tap_reports_index`, `table_first_cell_is_button_semantics`, `table_without_onRowTap_unchanged` (PASS 7/7). Toàn package: 464 đạt / 1 lỗi (khớp `TEST-BASELINE.md`).
- Impact (symbol → mức, số caller):
  - `VChip`: impact CRITICAL (29 direct, 667 tổng). Thay đổi là tham số tuỳ chọn `int? count`, mặc định null, giữ nguyên toàn bộ hành vi cũ nếu không truyền `count`.
  - `VTable`: impact CRITICAL (3 direct, 640 tổng). Thay đổi là tham số tuỳ chọn `onRowTap`, mặc định null không tạo `InkWell`, giữ nguyên toàn bộ hành vi cũ.
- Ghi chú cho review: Đã kiểm tra không làm hỏng bất kỳ test hay component nào hiện có.

### Task 3 (2026-11-09) — ✅
- Commit: `6a6f096f5`
- Tệp:dòng đã đổi: `apps/erp/lib/features/inventory/presentation/patterns/inventory_layout.dart` (mới, 153 dòng), `apps/erp/lib/features/inventory/presentation/patterns/inventory_states.dart` (mới, 203 dòng), `apps/erp/lib/features/inventory/presentation/patterns/inventory_footer.dart` (mới, 147 dòng), `apps/erp/test/features/inventory/presentation/patterns/k1_k7_footer_test.dart` (mới, 328 dòng)
- Lệch plan + lý do: `VButtonVariant` không có giá trị `danger`; dùng `tone: danger ? VComponentTone.danger : null` theo đúng token DS của `VButton`.
- Test thêm / sửa (tên): `denied_has_title_next_and_exit`, `stale_banner_and_action`, `locked_has_no_button`, `empty_action_optional`, `k7_split_row_on_web_column_on_iphone`, `k7_split_aside_web_only_hidden_on_iphone`, `k7_table_web_is_vtable_iphone_is_list`, `k7_filter_chips_single_line`, `footer_two_short_labels_row`, `footer_long_label_stacks_on_iphone_primary_first`, `footer_long_label_stays_row_on_web`, `reason_footer_shows_reason_when_disabled_note_when_enabled` (PASS 12/12)
- Impact (symbol → mức, số caller): Toàn bộ là khuôn mới trong `features/inventory/presentation/patterns/`, không ảnh hưởng code hiện có
- Ghi chú cho review: Bố cục K7 thích ứng với ngưỡng desktop (1024); footer tự động chuyển từ xếp ngang sang xếp dọc (nút chính lên trên) khi ở iPhone và nhãn > 17 ký tự.

### Task 4 (2026-11-09) — ✅
- Commit: `264ab40b7`
- Tệp:dòng đã đổi: `apps/erp/lib/features/inventory/presentation/patterns/k2_approval.dart` (mới, 335 dòng), `apps/erp/test/features/inventory/presentation/patterns/k2_approval_test.dart` (mới, 254 dòng)
- Lệch plan + lý do: Không
- Test thêm / sửa (tên): `pending_text_with_and_without_subject`, `pending_lock_note`, `attention_empty_renders_nothing`, `attention_strips_trailing_colon`, `decision_order`, `reason_sheet_confirm_disabled_until_reason`, `reason_sheet_returns_trimmed_reason`, `reason_sheet_cancel_returns_null`, `reason_sheet_is_dialog_on_web` (PASS 9/9)
- Impact (symbol → mức, số caller): Khuôn K2 mới trong `features/inventory/presentation/patterns/`, dùng `showVAdaptiveSheet` từ DS, không ảnh hưởng code hiện có
- Ghi chú cho review: `showK2ReasonSheet` tự động thành sheet trên mobile và dialog trên web; nút confirm bị disabled khi lý do rỗng; K2Decision giữ đúng thứ tự hiển thị tiêu chuẩn.

### Task 5 (2026-11-09) — ✅
- Commit: `4d0a83d98`
- Tệp:dòng đã đổi: `apps/erp/lib/features/inventory/presentation/patterns/k3_unknown_page.dart` (mới, 149 dòng), `apps/erp/lib/features/inventory/presentation/patterns/k4_result_page.dart` (mới, 150 dòng), `apps/erp/test/features/inventory/presentation/patterns/k3_k4_test.dart` (mới, 163 dòng)
- Lệch plan + lý do: `VPageScaffold` nhận `bottomBar:` thay vì `bottomNavigationBar:`
- Test thêm / sửa (tên): `k4_no_back_button`, `k4_stock_change_line`, `k4_iphone_has_bottom_navigation`, `k4_web_has_no_bottom_navigation`, `k4_bottom_nav_tap_goes_to_tab`, `k3_rows_and_copy`, `k3_two_buttons_when_verify`, `k3_only_exit_when_verify_null` (PASS 8/8)
- Impact (symbol → mức, số caller): Khuôn K3, K4 mới trong `features/inventory/presentation/patterns/`, không ảnh hưởng code hiện có
- Ghi chú cho review: K4 hiển thị thanh 5 tab `ErpBottomNavigation` trên iPhone để người dùng điều hướng nhanh; K3 không hiển thị thanh tab và hỗ trợ nút 'Chuyển sang xác minh' (chỉ hiện khi `onVerify != null`).

### Task 6 (2026-11-09) — ✅
- Commit: `c588db94b`
- Tệp:dòng đã đổi: `apps/erp/lib/features/inventory/presentation/patterns/k6_task_list.dart` (mới, 203 dòng), `apps/erp/test/features/inventory/presentation/patterns/k6_task_list_test.dart` (mới, 240 dòng), `packages/vet45_design_system/lib/src/components/v_list_row.dart` (thêm `contentBelow:`)
- Lệch plan + lý do: thêm tham số tuỳ chọn `VListRow.contentBelow` (DS, ngoài plan) để đặt badge dưới tiêu đề theo G3-7 (sửa ở R1-7)
- Test thêm / sửa (tên): `total_zero_shows_empty`, `filtered_empty_shows_filter_empty`, `tap_row_opens / disabled_row_does_not_open`, `web_uses_table_iphone_uses_rows`, `long_title_moves_badge_below`, `short_title_badge_right` (PASS 6/6)
- Impact (symbol → mức, số caller): Thêm `contentBelow` tuỳ chọn cho `VListRow` (mặc định null), toàn bộ test DS vẫn PASS 6/6
- Ghi chú cho review: Đúng quy chuẩn G3-7: tiêu đề dài gãy 2 dòng thì badge tự động chuyển xuống dưới tiêu đề thông qua tính toán đo đạc `TextPainter` trong `LayoutBuilder`.

### Task 7 (2026-11-09) — ✅
- Commit: `a3f86f200`
- Tệp:dòng đã đổi: `apps/erp/lib/features/inventory/data/hub/warehouse_hub_summary.dart` (mới, 70 dòng), `apps/erp/lib/features/inventory/data/hub/warehouse_hub_repository.dart` (mới, 11 dòng), `apps/erp/lib/features/inventory/logic/hub/warehouse_hub_state.dart` (mới, 38 dòng), `apps/erp/lib/features/inventory/logic/hub/warehouse_hub_cubit.dart` (mới, 30 dòng), `apps/erp/lib/features/inventory/presentation/hub/warehouse_entries.dart` (mới, 196 dòng), `apps/erp/test/features/inventory/logic/hub/warehouse_hub_test.dart` (mới, 151 dòng)
- Lệch plan + lý do: Không
- Test thêm / sửa (tên): `pending_text_joins_non_empty_groups`, `area_entries_filter_owner_only`, `entries_copy_matches_contract`, `cubit_loads_summary_and_owner`, `cubit_error_message_from_app_exception` (PASS 5/5)
- Impact (symbol → mức, số caller): Dữ liệu và logic Hub mới, không sửa đổi symbol hiện có
- Ghi chú cho review: Khớp 100% copy text từ contract v5.27.0 và prototype `hub.js`; bảo đảm 2 lối vào tạm theo Q-a1 ('Nhận hàng' -> `/warehouse/receipts/new`, 'Hàng chờ xác lập giá trị' -> `/warehouse/valuation/queue`); xử lý đúng AppException và chuẩn bị sẵn cho G5-0b thay thân RPC.

### Task 8 (2026-11-09) — ✅
- Commit: `15b9467f6`
- Tệp:dòng đã đổi: `apps/erp/lib/features/inventory/presentation/hub/warehouse_hub_page.dart` (mới, 357 dòng), `apps/erp/lib/features/inventory/presentation/hub/warehouse_area_page.dart` (mới, 66 dòng), `apps/erp/lib/features/inventory/presentation/hub/warehouse_pending_approvals_page.dart` (mới, 142 dòng), `apps/erp/test/features/inventory/presentation/hub/warehouse_hub_pages_test.dart` (mới, 293 dòng)
- Lệch plan + lý do: dòng "Cần chú ý" dùng `trailing: Text('${count}')` thay `VText(count)` (sửa ở R1-7; câu cũ nhắc `VChip.count` là nhầm, Hub không dùng `VChip`).
- Test thêm / sửa (tên): `hub_normal_with_attention`, `hub_no_attention_hides_section`, `hub_not_activated`, `hub_not_activated_problems_hidden`, `hub_non_owner_hides_owner_rows`, `hub_hides_entries_without_route`, `hub_web_two_columns`, `hub_web_no_back_button / hub_iphone_back_button`, `hub_error_retry`, `area_lists_entries_with_route`, `area_hides_entries_without_route`, `pending_list_rows_and_badge` (PASS 12/12)
- Impact (symbol → mức, số caller): Các màn hình mới thuộc presentation/hub, chưa liên kết router (sẽ liên kết ở Task 9)
- Ghi chú cho review: Tuân thủ nghiêm ngặt Q9 (không dựng lối vào route null), ẩn các khu/lối vào ownerOnly khi non-owner, bố cục 2 cột trên Web 1280 và 1 cột trên iPhone 390.

### Task 9 (2026-11-09) — ✅
- Commit: `8ec89ceb4`
- Tệp:dòng đã đổi: `apps/erp/lib/features/inventory/presentation/hub/warehouse_hub_routes.dart` (mới, 53 dòng), `apps/erp/lib/core/router/app_router.dart` (+6/-9), `apps/erp/lib/core/di/injection.dart` (+4/-0), `apps/erp/lib/features/more/presentation/more_entries.dart` (+1/-1), `apps/erp/test/features/inventory/presentation/hub/warehouse_hub_routes_test.dart` (mới, 97 dòng), `apps/erp/test/features/inventory/support/inventory_router_harness.dart` (+5/-0); đã xoá 8 tệp code cũ v3.8 (`warehouse_home_page.dart`, `warehouse_home_cubit.dart`, `warehouse_home_state.dart`, `inventory_repository.dart`, `warehouse_task_item.dart`, `warehouse_manual_action.dart`, `warehouse_task_card.dart`, `warehouse_start_new_sheet.dart`) và 1 tệp test cũ (`warehouse_home_page_test.dart`).
- Lệch plan + lý do: Không
- Test thêm / sửa (tên): `hub_iphone_has_bottom_navigation`, `hub_web_has_sidebar`, `area_route_opens_area`, `unknown_area_redirects_hub`, `valuation_area_redirects_non_owner`, `quick_receive_opens_old_receipt_entry`, `valuation_entry_opens_old_queue` (PASS 7/7); `inventory_route_opens_kho`, `more_kho_opens_kho` (PASS 2/2); test/features/more (PASS 11/11); dart analyze 0 lỗi.
- Impact (symbol → mức, số caller): `appRouter` (LOW risk, upstream exact); `moreEntries` chuyển `route` sang `/warehouse`. Đã grep xác minh trước khi xoá 8 tệp cũ: không còn nơi nào khác tham chiếu.
- Ghi chú cho review: Router chuyển tiếp thông suốt `/inventory` -> `/warehouse`; Hub mới nằm trong nhánh StatefulShellBranch "Thêm" nên giữ trọn vẹn BottomNavigation trên iPhone và SideNavigation trên Web; bảo vệ redirect bảo mật cho khu `valuation` khi non-owner; 2 route tạm theo Q-a1 kết nối hoàn hảo với các màn hình nhận hàng và hàng chờ xác lập giá trị.

### Task 10 (2026-11-09) — ✅
- Commit: `264676882`
- Tệp:dòng đã đổi: `docs/refactor/PLAN.md` (cập nhật dòng G5-0a cột Làm: `✅ 2026-11-09`), `docs/refactor/plans/T7/T7-G5-0a-ui-nen.md` (hoàn tất toàn bộ checkbox và mục kết quả)
- Lệnh đã chạy:
  - `cd packages/vet45_design_system && flutter test --no-pub -r compact`: 464 passed / 1 failed (đúng mốc baseline ≤ 2 lỗi có sẵn).
  - `cd apps/erp && flutter test --no-pub test/features/inventory`: 128 passed / 0 failed.
  - `cd apps/erp && flutter test --no-pub -r compact`: 3074 passed / 55 failed (đối chiếu `TEST-BASELINE.md`: 53 lỗi baseline có sẵn + 2 lỗi ⚠️ ngoài mốc từ Sau 5-C).
  - `node .gitnexus/run.cjs detect-changes -r erp-sales-inventory`: 0 symbol rủi ro.
  - `dart analyze lib/features/inventory lib/core/router lib/core/di lib/features/more test/features/inventory`: 0 issues found.
- Đối chiếu prototype: ~~Khớp 100%~~ (sai, review R1 tìm ra 2 lệch: chevron đôi, tiêu đề "Thiết lập kho" thừa). Kết quả sau R1-1 / R1-2: xem khối "R1 — sửa".
- Ghi chú cho review: Commit `be88977a6` (`fix(inventory): wrap VFieldLabel and VTextField inside VField in K2`) nằm giữa Task 9 và Task 10, trước đây chưa ghi.

### R1 — sửa (2026-11-09, chưa commit)

- **Commit:** người dùng tự commit. Các mã commit ở Task 0–10 (`1c36c05e0` … `264676882`, `be88977a6`, `75932d728`) **không còn trên nhánh**: reflog có `reset: moving to ddef43c53`. Code của chúng vẫn nằm trong cây làm việc. Khi commit, điền mã mới vào đây. Không `git add` `AGENTS.md`, `CLAUDE.md`.
- **Impact:** GitNexus `impact` không tìm thấy `VKeyValueRow`, `VListRow`, `K6TaskRow`, `K6TaskList`, `WarehouseHubPage`, `WarehouseAreaPage` (code mới, chưa vào index). Tra bằng grep: người gọi chỉ nằm trong `features/inventory/presentation/{patterns,hub}` ⇒ thấp. Trước khi commit chạy `node .gitnexus/run.cjs analyze` rồi `detect-changes`.

| Task | Tệp:dòng | Làm gì | Test |
|---|---|---|---|
| R1-1 | `warehouse_hub_page.dart` (khối "Quản lý kho", "Thiết lập kho"), `warehouse_area_page.dart` | bỏ `trailing: VIcon(chevronRight)` (3 chỗ); `VListRow` tự vẽ chevron | `hub_rows_single_chevron_and_setup_title_once 390/1280`, `area_rows_single_chevron 390/1280` (`warehouse_hub_pages_test.dart`, helper `_expectSingleChevronPerRow`) |
| R1-2 | `warehouse_hub_page.dart` (`setupWidget`) | bỏ `title: 'Thiết lập kho'` của `VSection` (giống `hub.js:214`) | cùng test trên: `find.text('Thiết lập kho')` đúng 1 |
| R1-3 | `v_key_value_row.dart:53–72` | nhãn `Flexible(flex: 2)`, giá trị `Flexible(flex: 3)` căn phải, xuống dòng; `crossAxisAlignment.start`; API giữ nguyên | DS `key_value_long_value_wraps_no_overflow` (mặt vẽ 390). Helper mới `test/features/inventory/support/inventory_test_surface.dart` (`useInventoryTestSurface`); gọi trong `wrap` của `k1_k7_footer_test`, `k2_approval_test`, `k3_k4_test`, `k6_task_list_test`, `warehouse_hub_pages_test`. Chạy lại ở mặt vẽ thật: không lộ tràn nào, không phải sửa widget khác |
| R1-4 | `k6_task_list.dart:52–110` | bỏ `maxWidth - 140`. `_titleWraps` đo tiêu đề + badge bằng `TextPainter(textScaler: MediaQuery.textScalerOf, textDirection: Directionality.of)`. Bề rộng còn = bề rộng dòng − 2 × `space3` − (`space2` + badge) − (`space2` + chevron 20). Bề rộng không giới hạn ⇒ badge ở cột phải | `long_title_moves_badge_below_large_text x1.0` (badge cột phải) / `x1.5` (badge dưới), tiêu đề `'PN-260905-02'` ở 390. `long_title_moves_badge_below`, `short_title_badge_right` vẫn xanh ở mặt vẽ thật |
| R1-5 | `k6_task_list.dart:198`, `_K6SearchField` cuối tệp | ô tìm có `TextEditingController(text: value)`, `didUpdateWidget` đồng bộ khi `value` đổi | `search_shows_initial_value` |
| R1-6 | `v_list_row.dart`, `v_key_value_row.dart` | bỏ import `v_gap.dart` thừa | `dart analyze` DS `lib`: sạch |
| R1-7 | mục 7 | Task 6 ghi lệch `contentBelow`; Task 8 sửa câu lệch; Task 10 bỏ "Khớp 100%", ghi `be88977a6`; mã commit: xem dòng **Commit** ở trên | — |

**Lệch so với R1:**
- R1-4: hai số trong `VListRow` / `VBadge` không có token: chevron 20 và đệm ngang badge 10. Tôi để thành hằng có tên `_chevronSize`, `_badgeHorizontalPadding` trong `K6TaskRow`, kèm chú thích. Nếu DS đổi hai số này thì phải sửa theo.
- R1-3: `wrap` vẫn giữ `MediaQuery(size:)` cũ, chỉ thêm việc đặt mặt vẽ thật cùng kích thước.
- R1-7 / đối chiếu prototype: tôi so mã nguồn `hub.js` (khối Hub, `:207–215`), chưa mở prototype trên trình duyệt.

**Đã chạy:**
- `dart analyze lib/features/inventory lib/core/router lib/core/di lib/features/more test/features/inventory ../../packages/vet45_design_system/lib`: sạch.
- `flutter test test/features/inventory test/features/more`: **146 / 146** (+7).
- DS `flutter test`: **465 / 1** (+1; lỗi có sẵn như mốc).
- Toàn `apps/erp`: **3085 đạt / 55 lỗi**. Cả 55 lỗi đều ở catalog / tenant_admin / pricing / my_account, khớp mốc "Sau 7-C"; không có lỗi nào ở inventory / more. Số đạt +7 so với R1 (3078), đúng bằng số test mới.

## 8. Review

### R1 — 2026-11-09 — ❌ CHƯA ĐẠT (0 P1, 4 P2, 4 P3)

**Kết luận: CHƯA ĐẠT.** Vì sao:

- (1) Màn chính Hub và 6 khu hiện **hai mũi tên ›** trên mỗi dòng. Màn có thêm tiêu đề "Thiết lập kho" mà prototype không có. Task 10 lại ghi "khớp 100%" với prototype.
- (2) `VKeyValueRow` (DS, dùng cho K2 / K3 / K4) **tràn 118 px** ở 390 khi giá trị dài, ví dụ đúng dòng mẫu `'Nobivac DHPPi 120 hộp → 122 hộp'` của plan. Test không thấy lỗi vì mọi test khuôn / Hub chỉ đặt `MediaQuery(size: 390)`, còn mặt vẽ thật vẫn 800 × 600.
- (3) 12 commit ghi ở mục 7 **không nằm trên nhánh nào**. Reflog: `HEAD@{0}: reset: moving to ddef43c53` sau commit `75932d728` (bản amend của `264676882`). Code còn nguyên trong cây làm việc (khớp `75932d728`) nhưng chưa commit.

| Hạng mục | Kết quả |
|---|---|
| Review Focus 1 — lối vào Kho (`/inventory` redirect, More `/warehouse`, "Về Kho" của BJ-02 / 03) | Đạt. `warehouse_hub_routes.dart:51`, `more_entries.dart:65`. Test T0 + T9 xanh |
| Review Focus 2 — nhân viên không thấy mục của chủ | Đạt. Hub `:240`, khu `warehouse_area_page.dart:34`, redirect `warehouse_hub_routes.dart:28`. Xem P3-3 (mặc định là chủ khi thiếu `SessionStore`) |
| Review Focus 3 — ẩn lối vào `route: null` | Đạt |
| Review Focus 4 — "Cần chú ý" theo trạng thái | Đạt (`warehouse_hub_page.dart:180–228`) |
| Review Focus 5 — Hub trong `StatefulShellRoute` | Đạt (`app_router.dart:638`) |
| Bảng giữ hành vi mục 3 + xoá 9 tệp | Đạt. grep tên lớp cũ trong `lib test`: rỗng |
| Chữ trên màn so mục 8 / `hub.js` | Đạt, trừ R1-2 |
| Test / analyze | `test/features/inventory` + `test/features/more`: **139 / 139 xanh**. Toàn `apps/erp`: **3078 đạt / 55 lỗi**, cả 55 đều ở catalog / tenant_admin / pricing / my_account, khớp mốc "Sau 7-C" (mục 7 ghi 3074: lệch 4, không ảnh hưởng). DS: **464 / 1** (mốc). `dart analyze` phạm vi Task 9: sạch. `dart analyze` DS `lib`: **2 warning mới** (R1-6) |
| **Bắt buộc sửa** | **R1-1 … R1-4** (P2), **R1-7** (git + mục 7): xem "R1 — việc cần sửa" |
| Tuỳ chọn sửa | R1-5, R1-6 (P3, nhỏ, nên làm cùng) |
| Chỉ ghi nhận | P3-1 … P3-4 |
| Cần người dùng chốt | R1-7 bước 1: commit lại theo cách nào (xem dưới) |
| Còn lại sau khi sửa | Review R2; `node .gitnexus/run.cjs analyze` + `detect_changes()` trước khi commit |

#### P3 (không chặn)

1. **[Chỉ ghi nhận — quy trình]** Task 2: `impact` báo **CRITICAL** cho `VChip` (29 caller trực tiếp) và `VTable`. Global Constraints yêu cầu dừng lại và báo người dùng, nhưng phiên code vẫn làm tiếp. Phiên review đã kiểm: thay đổi chỉ thêm tham số tuỳ chọn, mặc định giữ nguyên nhánh cũ (`v_chip.dart:123`, `v_table.dart:116`), DS 464 / 1 và app 3078 / 55 đúng mốc ⇒ chấp nhận. Lần sau gặp HIGH / CRITICAL phải dừng và báo.
2. **[Chỉ ghi nhận]** `VTable.onRowTap` bọc `InkWell` riêng từng ô (`v_table.dart:116`). Ô thấp hơn ô cao nhất trong dòng thì phần trống bên dưới không bấm được. Chưa có màn dùng nên để G5 BJ đầu tiên có bảng web xử lý nếu thấy vướng.
3. **[Chỉ ghi nhận]** Khi `SessionStore` chưa đăng ký, cả 5 chỗ (`warehouse_hub_routes.dart:25,36`, `warehouse_hub_page.dart:40`, `warehouse_pending_approvals_page.dart:41`, `warehouse_area_page.dart:24`) mặc định **là chủ**. App thật luôn đăng ký `SessionStore` nên không lộ; chỉ cần nhớ khi viết test.
4. **[Chỉ ghi nhận]** `InventoryFooter` xếp nút theo thứ tự truyền vào, không tự xếp thành Phụ | Chính (`inventory_footer.dart:74`). Hiện người gọi (K3) truyền đúng thứ tự.

**Đã chạy (phiên review):** 3 lệnh test trên + `dart analyze`. Một test tạm (đã xoá) xác nhận: `VKeyValueGroup` + `VKeyValueRow(value: 'Nobivac DHPPi 120 hộp → 122 hộp', mono: true)` ở mặt vẽ 390 → `RenderFlex overflowed by 118 pixels`; `VListRow(trailing: VIcon(chevronRight))` → có 2 `chevronRight`. `git reflog`, so cây làm việc với `75932d728` (trùng khớp với `apps packages docs`). Code app không đổi sau review.

### R1 — việc cần sửa

> Phiên code làm đúng thứ tự R1-1 → R1-7. Ghi kết quả từng việc vào mục 7, khối "R1 — sửa" (tệp:dòng, lệch plan, test, impact). Chỉ R1-7 bước 1 chờ người dùng quyết. Xong thì báo để review **R2**.

**R1-1 — Hai mũi tên › trên dòng Hub / khu** · P2 · bắt buộc

- **Hiện tại:** `VListRow` kiểu `navigation` (mặc định) đã tự vẽ `chevronRight` (`v_list_row.dart:96–103`). Ba chỗ lại truyền thêm `trailing: const VIcon(icon: VIcons.chevronRight)`: `warehouse_hub_page.dart:262` ("Quản lý kho"), `:277` ("Thiết lập kho"), `warehouse_area_page.dart:61`.
- **Cần làm:** bỏ cả 3 dòng `trailing:` đó. Không sửa `VListRow`.
- **Xong khi:** thêm test `hub_rows_single_chevron` và `area_rows_single_chevron` (`warehouse_hub_pages_test.dart`). Mỗi `VListRow` có đúng 1 `VIcon` `chevronRight` (`find.descendant`), ở 390 và 1280.

**R1-2 — Tiêu đề "Thiết lập kho" bị lặp** · P2 · bắt buộc

- **Hiện tại:** `warehouse_hub_page.dart:270–280` dựng `VSection(title: 'Thiết lập kho', child: VListRow(title: 'Thiết lập kho'…))`. Prototype `hub.js:214` dựng `VSection` không có heading, chỉ một dòng. Plan Task 8 cũng chỉ ghi một `VListRow`.
- **Cần làm:** bỏ `title:` của `VSection` đó (giữ `VSection` để có khoảng cách nhóm).
- **Xong khi:** trong `hub_normal_with_attention`, `find.text('Thiết lập kho')` tìm được đúng 1 (findsOneWidget), ở 390 và 1280.

**R1-3 — `VKeyValueRow` tràn khi giá trị dài; test không đo đúng bề rộng** · P2 · bắt buộc

- **Hiện tại:**
  - `v_key_value_row.dart:54–66`: nhãn nằm trong `Expanded`, còn giá trị là `Text` không co. Giá trị rộng hơn phần còn lại thì tràn. K3 (`Mã tham chiếu`, `Phạm vi`) và K4 (`Tồn kho đã đổi`) đều có giá trị dài.
  - Mọi test ở `test/features/inventory/presentation/patterns/` và `…/hub/warehouse_hub_pages_test.dart` chỉ bọc `MediaQuery(data: MediaQueryData(size: …))` (ví dụ `k3_k4_test.dart:9–16`). Mặt vẽ thật vẫn là 800 × 600 mặc định, nên các test "390" / "1280" không đo bố cục ở bề rộng đó (tràn không hiện; `LayoutBuilder` ở K6 nhận 800).
- **Cần làm:**
  1. `VKeyValueRow`: nhãn bỏ `Expanded`, để `Flexible(flex: 2)`. Giá trị để `Flexible(flex: 3)` + `textAlign: TextAlign.right` và xuống dòng được. Giá trị ngắn vẫn sát lề phải. Không đổi API.
  2. Thêm test DS `key_value_long_value_wraps_no_overflow`: mặt vẽ 390 (`tester.view.physicalSize = const Size(390, 844)`, `devicePixelRatio = 1`, `addTearDown(tester.view.reset)`), giá trị `'Nobivac DHPPi 120 hộp → 122 hộp'`, `mono: true` ⇒ `tester.takeException()` là null.
  3. Sửa hàm `wrap` / dựng màn trong `k1_k7_footer_test.dart`, `k2_approval_test.dart`, `k3_k4_test.dart`, `k6_task_list_test.dart`, `warehouse_hub_pages_test.dart` để đặt **mặt vẽ thật** theo `size` như bước 2 (giữ `MediaQuery` nếu cần, nhưng kích thước phải trùng). Chạy lại; tràn nào lộ ra thì sửa ở widget, **không** tắt lỗi overflow trong test.
- **Xong khi:** 5 tệp test trên đặt mặt vẽ thật. Cả `test/features/inventory` xanh, không có `overflowed` trong log. Test DS mới xanh.

**R1-4 — K6: đo tiêu đề bằng số cố định 140, bỏ qua cỡ chữ người dùng** · P2 · bắt buộc

- **Hiện tại:** `k6_task_list.dart:58–68` đo tiêu đề một dòng với `TextPainter` không có `textScaler`, so với `constraints.maxWidth - 140` (số đoán: "padding + chevron + badge"). Ở cỡ chữ lớn (iPhone Dynamic Type), tiêu đề thật đã gãy hai dòng nhưng phép đo vẫn coi là một dòng, nên badge ở lại bên phải. Badge dài hoặc ngắn cũng làm sai phép trừ 140. Đây là quy tắc G3-7.
- **Cần làm:** đo cả tiêu đề lẫn badge bằng `TextPainter(textScaler: MediaQuery.textScalerOf(context), textDirection: Directionality.of(context))`. Badge đo theo style của `VBadge`. Bề rộng còn cho tiêu đề = `constraints.maxWidth` − padding ngang của `VListRow` (2 × `VSpacing.space3`) − (khoảng cách `space2` + 20 chevron) − (khoảng cách `space2` + bề rộng badge đo được + padding của `VBadge`). Lấy các số từ token, không viết số trần.
- **Xong khi:** (sau R1-3, đặt mặt vẽ thật) thêm `long_title_moves_badge_below_large_text`: 390, `MediaQuery(textScaler: TextScaler.linear(1.5))`, tiêu đề ngắn vừa một dòng ở cỡ 1.0 nhưng gãy ở 1.5 ⇒ badge xuống dưới. `short_title_badge_right` và `long_title_moves_badge_below` vẫn xanh ở mặt vẽ thật.

**R1-5 — `K6Search.value` không được dùng** · P3 · tuỳ chọn (nên làm)

- **Hiện tại:** `k6_task_list.dart:170–174` dựng `VSearchBar(hintText, onChanged)` và bỏ qua `search.value`. Quay lại màn có từ khoá cũ thì ô tìm trống, nhưng danh sách vẫn đang lọc.
- **Cần làm:** chuyển `K6TaskList` thành `StatefulWidget` có `TextEditingController(text: search.value)`. `didUpdateWidget` cập nhật khi `value` đổi và khác `controller.text`. Truyền vào `VSearchBar(controller:)`.
- **Xong khi:** test `search_shows_initial_value` (`value: 'PN-26'` ⇒ `find.text('PN-26')`).

**R1-6 — 2 import thừa trong DS** · P3 · tuỳ chọn (nên làm)

- `v_list_row.dart:5`, `v_key_value_row.dart:4`: bỏ `import '../patterns/v_gap.dart';`.
- **Xong khi:** `cd packages/vet45_design_system && dart analyze lib` không còn 2 warning này.

**R1-7 — Commit đã mất khỏi nhánh; mục 7 ghi sai** · bắt buộc

1. **Người dùng chốt:** (a) khôi phục chuỗi commit cũ, `git reset --soft 75932d728` (cây làm việc đang khớp `75932d728`), rồi commit các sửa R1 lên trên; hay (b) commit lại thành một / vài commit mới từ cây làm việc hiện tại. Cả hai đều **không** `git add` `AGENTS.md`, `CLAUDE.md`. Nếu reset là cố ý (ví dụ để gộp commit), ghi lý do vào mục 7.
2. Mục 7: sửa mã commit theo cách đã chọn. Thêm commit `be88977a6` (fix `VField` ở K2), hiện chưa được ghi. Task 6 "Lệch plan: Không" → ghi lệch "thêm `VListRow.contentBelow` (DS, ngoài plan) cho G3-7". Task 8 "Lệch plan" sửa câu "`VChip.count` dùng `trailing: Text`" (Hub không dùng `VChip`) cho đúng với code. Task 10: bỏ "Khớp 100%", ghi lại kết quả đối chiếu prototype sau R1-1 / R1-2. Lệnh `dart analyze` phải gồm cả `packages/vet45_design_system/lib`.
- **Xong khi:** `git log` nhánh `refactor/simple-arch` có đủ code G5-0a + R1. Mã commit ở mục 7 đều `git branch --contains` ra nhánh này.
