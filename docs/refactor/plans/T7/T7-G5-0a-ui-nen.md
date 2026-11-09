# T7-G5-0a — UI nền Theme 7: thành phần DS, khuôn K1–K4 / K6 / K7, Home Kho

> Theme 7 · plan **G5-0a** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-09) | Làm ⬜ | Review ⬜
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

- [ ] **Step 1: Viết test** (cả hai phải xanh **trên code cũ**):
  - `inventory_route_opens_kho`: `pumpInventoryApp(location: '/inventory')` → `find.descendant(of: find.byType(VAppBar), matching: find.text('Kho'))` findsOneWidget.
  - `more_kho_opens_kho`: location `/more` → tap `find.text('Kho')` → `pumpAndSettle` → như trên.
- [ ] **Step 2:** `cd apps/erp && flutter test --no-pub test/features/inventory/presentation/hub/warehouse_entry_parity_test.dart` → PASS (2).
- [ ] **Step 3:** Commit `test(inventory): T7-G5-0a bước 0 — lối vào Kho`.

### Task 1: `VListRow`, `VQuickActionButton`

**Files:** Create `v_list_row.dart`, `v_quick_action_button.dart` + test; Modify `design_system.dart`.

**Interfaces — Produces:**
- `enum VListRowType { navigation, selection, plain }`
- `VListRow({Key? key, required String title, String? subtitle, VIcons? leading, Widget? trailing, VListRowType type = VListRowType.navigation, bool selected = false, bool enabled = true, VoidCallback? onTap, String? semanticLabel})`. `leading` dựng trong `VIconBox`; `navigation` thêm `VIcon(VIcons.chevronRight)` sau `trailing`; `plain` không có chevron; chiều cao tối thiểu `VSpacing.minTouchTarget`; `Semantics(button: onTap != null, enabled: enabled, selected: selected, label: semanticLabel ?? title)`.
- `VQuickActionButton({Key? key, required VIcons icon, required String label, VoidCallback? onPressed, String? semanticLabel})` — `onPressed == null` = tắt (mờ theo `vDisabledOpacity`, `Semantics(enabled: false)`); icon trên, nhãn dưới, vùng chạm ≥ 44.

- [ ] **Step 1: Test** `v_list_row_test.dart`: `navigation_shows_chevron` (tìm `VIcons.chevronRight`); `plain_has_no_chevron`; `tap_calls_onTap`; `disabled_ignores_tap` (`enabled: false` → callback 0 lần, `tester.getSemantics` không có `hasEnabledState && isEnabled`); `shows_subtitle_and_trailing`; `min_height_44` (`tester.getSize(...).height >= 44`).
  `v_quick_action_button_test.dart`: `tap_calls`; `null_onPressed_is_disabled` (không gọi, semantics disabled); `size_at_least_44`.
- [ ] **Step 2:** chạy → FAIL (chưa có lớp).
- [ ] **Step 3:** Dựng hai lớp, export.
- [ ] **Step 4:** `cd packages/vet45_design_system && flutter test --no-pub test/components/v_list_row_test.dart test/components/v_quick_action_button_test.dart` → PASS.
- [ ] **Step 5:** Commit `feat(ds): VListRow, VQuickActionButton (T7-G5-0a)`.

### Task 2: `VChip.count`, `VKeyValueRow` / `VKeyValueGroup`, `VTable.onRowTap`

**Files:** Modify `primitives/v_chip.dart`, `components/v_table.dart`; Create `components/v_key_value_row.dart` + 3 test.

**Interfaces — Produces:**
- `VChip(..., int? count)`: sau nhãn dựng `' $count'` kiểu `VTypography.bodySmall`; `count == 0` dùng `colors.textSecondary` (vẫn bấm được); semantics label `'$label $count'`.
- `VKeyValueRow({required String label, required String value, bool emphasized = false, bool mono = false, Widget? trailing})` — nhãn trái, giá trị phải; `mono: true` dùng `VTypography.monoNumeric` (số tiền / số liệu, G3-7).
- `VKeyValueGroup({String? title, required List<Widget> rows})` — một bề mặt chung (nền `surface`, viền `border`, bo `VRadius.card`) cho ≥ 2 dòng (PAT-UI-UX 4.7); `title` là tiêu đề nhóm.
- `VTable(..., ValueChanged<int>? onRowTap)`: mọi ô của dòng bấm được (`InkWell`), ô đầu bọc `Semantics(button: true)`; `null` = như cũ.

- [ ] **Step 1: Test:** `chip_count_renders_and_zero_is_muted` (text `'3'` có; với `count: 0` màu text = `textSecondary`); `chip_without_count_unchanged` (golden không cần: kiểm không có Text thứ hai). `key_value_mono_uses_mono_style`; `group_renders_title_and_rows`. `table_row_tap_reports_index` (bấm ô cột 2 dòng 1 → `onRowTap(1)`); `table_first_cell_is_button_semantics`; `table_without_onRowTap_unchanged` (không có `InkWell`).
- [ ] **Step 2:** FAIL. **Step 3:** cài đặt (chạy `impact` cho `VChip`, `VTable` trước, ghi Kết quả). **Step 4:** `flutter test --no-pub` cả package `vet45_design_system` → không thêm lỗi so với `TEST-BASELINE.md` (mốc package: 2 lỗi có sẵn).
- [ ] **Step 5:** Commit `feat(ds): VChip.count, VKeyValueRow, VTable.onRowTap (T7-G5-0a)`.

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

- [ ] **Step 1: Test:** `denied_has_title_next_and_exit` (`'Bạn chưa có quyền nhận hàng'`, bấm `'Về Kho'` gọi `onExit`); `stale_banner_and_action` (`'Tải lại'`); `locked_has_no_button`; `empty_action_optional`; `k7_split_row_on_web_column_on_iphone`; `k7_split_aside_web_only_hidden_on_iphone`; `k7_table_web_is_vtable_iphone_is_list`; `k7_filter_chips_single_line` (một `SingleChildScrollView` ngang, không `Wrap`); `footer_two_short_labels_row`; `footer_long_label_stacks_on_iphone_primary_first` (nhãn `'Chuyển sang xác minh'` 20 ký tự); `footer_long_label_stays_row_on_web`; `reason_footer_shows_reason_when_disabled_note_when_enabled`.
- [ ] **Step 2:** FAIL. **Step 3:** cài đặt. **Step 4:** `cd apps/erp && flutter test --no-pub test/features/inventory/presentation/patterns/k1_k7_footer_test.dart` → PASS.
- [ ] **Step 5:** Commit `feat(inventory): khuôn K1, K7, chân màn (T7-G5-0a)`.

### Task 4: K2 lập → duyệt

**Files:** Create `patterns/k2_approval.dart` + `test/.../patterns/k2_approval_test.dart`.

**Interfaces — Consumes:** `VKeyValueGroup`, `VKeyValueRow` (Task 2). **Produces:**
- `K2Pending({required String approver, required String sentAt, List<VKeyValueRow> facts = const [], String subject = ''})` — `VBanner(info, title: 'Đang chờ duyệt', description: 'Chờ $approver duyệt${subject.isEmpty ? '' : ' $subject'} · gửi $sentAt')`; nếu có `facts`: `VKeyValueGroup(title: 'Yêu cầu')`; dòng chú thích `'Dữ liệu đã khoá. Tồn kho chưa thay đổi.'`.
- `enum K2AttentionTone { warning, info }`; `K2AttentionItem({required String label, required String value, K2AttentionTone tone = warning})`; `K2Attention({required List<K2AttentionItem> items, String title = 'Cần chú ý'})` — rỗng → `SizedBox.shrink()`; nhãn bỏ dấu `:` cuối; icon `warning` / `info` theo tone; `title == ''` thì không tiêu đề.
- `K2Decision({required String question, required String maker, required String sentAt, List<K2AttentionItem> attention = const [], List<VKeyValueRow> facts = const [], Widget? detail})` — thứ tự cố định: tiêu đề `'Cần quyết'` → `question` → `'$maker gửi $sentAt'` → `K2Attention` → `VKeyValueGroup(rows: facts)` → `detail`.
- `Future<String?> showK2ReasonSheet(BuildContext context, {required String title, String description = '', String reasonLabel = 'Lý do từ chối', String placeholder = 'Nhập nội dung người lập cần sửa', String closeLabel = 'Hủy', String confirmLabel = 'Xác nhận từ chối', bool withReason = true, bool danger = false})` — qua `showVAdaptiveSheet` (iPhone sheet, web hộp thoại); trả lý do đã `trim()` (hoặc `''` khi `withReason: false`) khi xác nhận, `null` khi huỷ; nút xác nhận tắt khi `withReason` và lý do rỗng.

- [ ] **Step 1: Test:** `pending_text_with_and_without_subject` (`'Chờ chủ cửa hàng duyệt sửa sai · gửi 09:41'`, `'Chờ chủ cửa hàng duyệt · gửi 09:41'`); `pending_lock_note`; `attention_empty_renders_nothing`; `attention_strips_trailing_colon`; `decision_order` (vị trí dọc `'Cần quyết'` < question < maker < attention < facts); `reason_sheet_confirm_disabled_until_reason` ; `reason_sheet_returns_trimmed_reason`; `reason_sheet_cancel_returns_null`; `reason_sheet_is_dialog_on_web` (`find.byType(VSheetDialog)` ở 1280).
- [ ] **Step 2–4:** FAIL → cài đặt → PASS.
- [ ] **Step 5:** Commit `feat(inventory): khuôn K2 (T7-G5-0a)`.

### Task 5: K3 kết quả chưa rõ, K4 kết quả xong

**Files:** Create `patterns/k3_unknown_page.dart`, `patterns/k4_result_page.dart` + `test/.../patterns/k3_k4_test.dart`.

**Interfaces — Consumes:** `InventoryFooter` (Task 3), `VKeyValueRow` / `Group`, `ErpBottomNavigation` + `ErpTab` (`features/dashboard/presentation/widgets/erp_bottom_navigation.dart`). **Produces:**
- `enum K4Kind { success, pending, warning, danger }` → icon `VIcons.success` / `clock` / `warning` / `error`, tone success / warning / warning / danger (prototype `resultHero`).
- `K4StockChange({required String product, required String before, required String after})` (`before` / `after` đã kèm ĐVT, vd. `'120 hộp'`).
- `K4ResultPage({String screenTitle = 'Kết quả', K4Kind kind = K4Kind.success, required String title, required String description, List<VKeyValueRow> facts = const [], List<K4StockChange> stockChanges = const [], Widget? extra, List<InventoryFooterAction> next = const []})` — `VPageScaffold(showBackButton: false)`; thân: hero (icon + `title` + `description`) → `VKeyValueGroup(rows: [...facts, ...stockChanges.map((c) => VKeyValueRow(label: 'Tồn kho đã đổi', value: '${c.product} ${c.before} → ${c.after}', mono: true))])` → `extra`; chân `InventoryFooter(next)`; web: thân tối đa 720 giữa khung; **iPhone: dưới chân thêm `ErpBottomNavigation(currentIndex: ErpTab.more.index, onTap: (i) => context.go(ErpTab.values[i].routePath))`** (PAT-NAV mục 5).
- `K3UnknownPage({String title = 'Xác minh kết quả', required String operation, required String scope, required String ref, required String sentAt, String safe = '', List<VKeyValueRow> facts = const [], Widget? detail, required VoidCallback onExit, VoidCallback? onVerify})` — `K4ResultPage`-giống: kind `pending`, tiêu đề hero `'Kết quả chưa xác định'`, mô tả `'Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.${safe.isEmpty ? '' : ' $safe'}'`; dòng: `Nghiệp vụ` = operation, `Phạm vi` = scope, `Mã tham chiếu` = ref, `Thời điểm gửi` = sentAt, …facts, `Trạng thái` = `'Chưa kết luận'`; chân `'Về Kho'` (phụ, `onExit`) | `'Chuyển sang xác minh'` (chính, `onVerify`). **`onVerify == null` → chỉ nút "Về Kho"** (tạm tới G5-14 nối BJ-17; G5-17 kiểm không còn chỗ nào null). Không thanh 5 tab (K3 không phải K4).

- [ ] **Step 1: Test:** `k4_no_back_button`; `k4_stock_change_line` (`'Nobivac DHPPi 120 hộp → 122 hộp'` cạnh `'Tồn kho đã đổi'`); `k4_iphone_has_bottom_navigation` / `k4_web_has_no_bottom_navigation`; `k4_bottom_nav_tap_goes_to_tab` (router thử: bấm "Đơn hàng" → `/orders`); `k3_rows_and_copy` (đủ 5 nhãn + `'Chưa kết luận'`, câu mô tả có / không `safe`); `k3_two_buttons_when_verify` / `k3_only_exit_when_verify_null`.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): khuôn K3, K4 (T7-G5-0a)`.

### Task 6: K6 danh sách công việc

**Files:** Create `patterns/k6_task_list.dart` + `test/.../patterns/k6_task_list_test.dart`.

**Interfaces — Consumes:** `K7Table`, `K7Column`, `K7FilterChips`, `InventoryEmpty`, `VListRow`, `VBadge`, `VSearchBar`. **Produces:**
- `K6Status({required String label, required VComponentTone tone})`.
- `K6Search({required String value, required String hint, required ValueChanged<String> onChanged})`.
- `K6TaskList<T>({K6Search? search, K7FilterChips? filters, required List<K7Column<T>> columns, required List<T> rows, required int total, required String Function(T) title, String Function(T)? subtitle, required K6Status Function(T) status, bool Function(T)? isDisabled, required ValueChanged<T> onOpen, required InventoryEmpty empty, required InventoryEmpty filterEmpty})` — thứ tự: ô tìm → chip → bảng (web) / danh sách (iPhone) ; `total == 0` → chỉ `empty`; `rows.isEmpty && total > 0` → `filterEmpty`; dòng `isDisabled` không mở (`onOpen` không gọi), `VListRow(enabled: false)`.
- `K6TaskRow<T>` (dòng iPhone mặc định): tiêu đề + phụ đề + badge. **G3-7:** badge ở cột phải khi tiêu đề vừa một dòng; **xuống dưới tiêu đề** khi tiêu đề gãy hai dòng ở bề rộng hiện có (đo bằng `TextPainter` trong `LayoutBuilder`).

- [ ] **Step 1: Test:** `total_zero_shows_empty`; `filtered_empty_shows_filter_empty`; `tap_row_opens` / `disabled_row_does_not_open`; `web_uses_table_iphone_uses_rows`; `long_title_moves_badge_below` (390 px, tiêu đề `'Phiếu nhận hàng nhập nhanh PN-260905-02 · Minh Dũng'` → `dy` của badge > `dy` cuối tiêu đề) / `short_title_badge_right`.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): khuôn K6 (T7-G5-0a)`.

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

- [ ] **Step 1: Test:** `pending_text_joins_non_empty_groups` (nhóm "nhận hàng" 3, "số dư đầu kỳ" 1, "hàng khách trả" 0 → `'3 nhận hàng · 1 số dư đầu kỳ'`, `pendingTotal == 4`); `area_entries_filter_owner_only` (lọc với `isOwner: false` không còn `Giá vốn`, `Khởi tạo tồn đầu kỳ`); `entries_copy_matches_contract` (so cả bảng trên); `cubit_loads_summary_and_owner`; `cubit_error_message_from_app_exception`.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): dữ liệu Hub Kho (T7-G5-0a)`.

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

- [ ] **Step 1: Test** (mỗi dòng ở 390 và 1280 trừ khi ghi khác; cubit thử với summary đặt sẵn):

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

- [ ] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Commit `feat(inventory): Home Kho SCR-090…096 (T7-G5-0a)`.

### Task 9: Router, More, DI, xoá Home cũ

**Files:** Create `presentation/hub/warehouse_hub_routes.dart`; Modify `core/router/app_router.dart`, `core/di/injection.dart`, `features/more/presentation/more_entries.dart:65`, `test/.../support/inventory_router_harness.dart`; Delete tệp ở mục 3; Test `test/.../hub/warehouse_hub_routes_test.dart`.

**Interfaces — Produces:**
- `List<RouteBase> warehouseHubRoutes()` → `GoRoute(path: '/warehouse', name: 'warehouse', builder: WarehouseHubPage, routes: [GoRoute(path: 'area/:areaId', name: 'warehouse.area', redirect: …, builder: WarehouseAreaPage), GoRoute(path: 'approvals', name: 'warehouse.approvals', builder: WarehousePendingApprovalsPage)])`. `area/:areaId` redirect: `WarehouseArea.fromId == null` → `/warehouse`; `area.ownerOnly && !getIt<SessionStore>().isOwner` → `/warehouse` (Q-a3).
- `GoRoute inventoryRedirectRoute()` → `GoRoute(path: '/inventory', redirect: (_, _) => '/warehouse')`.

- [ ] **Step 1: Test** `warehouse_hub_routes_test.dart` (harness, `setUp` thêm `getIt.registerSingleton<WarehouseHubRepository>(…)` vào `setUpInventoryRouterTest`):
  - `hub_iphone_has_bottom_navigation` (`/warehouse` 390 → `ErpBottomNavigation` có, `VAppBar` "Kho"); `hub_web_has_sidebar` (1280 → `ErpSideNavigation` có).
  - `area_route_opens_area` (`/warehouse/area/control` → "Kiểm kê & xử lý"); `unknown_area_redirects_hub` (`/warehouse/area/xyz`); `valuation_area_redirects_non_owner` (`isOwner: false`).
  - `quick_receive_opens_old_receipt_entry` (bấm "Nhận hàng" → `ReceiptEntryChoicePage`); `valuation_entry_opens_old_queue` (`/warehouse/area/valuation` → bấm "Hàng chờ xác lập giá trị" → `ValuationQueuePage`).
  - Task 0 vẫn xanh (`/inventory` và More → Hub "Kho").
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Chạy `impact` cho `appRouter`, `moreEntries` (ghi Kết quả). Tạo routes; sửa `app_router.dart` (bỏ `GoRoute('/inventory')` + import `warehouse_home_page.dart`, thêm `inventoryRedirectRoute()` cùng vị trí, thêm `...warehouseHubRoutes()` vào nhánh "Thêm"); DI; More `route: '/warehouse'`; xoá tệp mục 3 (trước khi xoá `grep -rn "WarehouseHome\|InventoryRepository\|WarehouseTaskItem\|WarehouseManualAction\|WarehouseTaskCard\|WarehouseStartNew" lib test` chỉ còn trong tệp sắp xoá).
- [ ] **Step 4:** `cd apps/erp && dart analyze lib/features/inventory lib/core/router lib/core/di lib/features/more test/features/inventory` → 0 lỗi; `flutter test --no-pub test/features/inventory test/features/more` → PASS.
- [ ] **Step 5:** Commit `feat(inventory): route Home Kho mới, xoá WarehouseHomePage v3.8 (T7-G5-0a)`.

### Task 10: Kiểm toàn bộ + cập nhật tài liệu

- [ ] **Step 1:** `cd apps/erp && flutter test --no-pub -r compact` → số lỗi không vượt mốc `TEST-BASELINE.md` ("Sau 7-C": 55 lỗi; ghi tên test hỏng mới nếu có). `cd packages/vet45_design_system && flutter test --no-pub -r compact` → ≤ 2 lỗi có sẵn.
- [ ] **Step 2:** `detect_changes({scope: "compare", base_ref: "main"})` (hoặc `node .gitnexus/run.cjs detect-changes`) — chỉ symbol của plan này; ghi Kết quả.
- [ ] **Step 3:** Đối chiếu prototype: `index.html?mode=theme&app=inventory&viewport=mobile` và `viewport=web`, `&activation=pending`, `&hubView=movement`, `&hubView=pending-approvals`; ghi lệch (ngoài các lối vào ẩn theo Q9) vào Kết quả.
- [ ] **Step 4:** PLAN.md mục Theme 7, bảng Plan, dòng G5-0a cột Làm: "✅ {ngày}".
- [ ] **Step 5:** Commit `docs(refactor): kết quả T7-G5-0a`.

## 6. Rủi ro / lưu ý

- `VTable` dùng `Table`: `TableRow` không nhận cử chỉ ⇒ bọc từng ô; kiểm không đổi bố cục bảng đang có ở màn khác (`impact` Task 2).
- `K4ResultPage` import `ErpBottomNavigation` từ `features/dashboard` — chấp nhận (cùng app); không đưa vào DS.
- Font Ahem của test rộng hơn font thật: test đo bố cục (Task 6 `long_title_moves_badge_below`, Task 8 `hub_web_two_columns`) dùng chuỗi đủ dài / so tương đối, không so số px tuyệt đối.
- Hub nằm trong nhánh "Thêm": `context.push` từ Thêm giữ ngăn xếp nhánh ⇒ quay lại từ Hub về Thêm; chuyển tab rồi quay lại giữ Hub (hành vi `StatefulShellRoute`, chấp nhận).

## 7. Kết quả (phiên làm code ghi)

Xong **mỗi task** ghi ngay theo mẫu (không dồn cuối); dừng giữa chừng ghi `🔄 dở` + tới bước nào.

```
### Task N (YYYY-MM-DD) — ✅ / 🔄 / ⏭
- Commit:
- Tệp:dòng đã đổi:
- Lệch plan + lý do:
- Test thêm / sửa (tên):
- Impact (symbol → mức, số caller):
- Ghi chú cho review:
```

Task 10 thêm: lệnh đã chạy, đạt / lỗi, tên test hỏng đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes`.

## 8. Review

(Phiên review ghi.)
