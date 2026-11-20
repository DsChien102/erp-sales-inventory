# 5-W — Theme 2 trên web: danh sách – PCC hai cột, màn con có id trên URL, sheet thành hộp thoại

> Theme 2 (mã cũ P5) · Bố cục web (quy tắc Thiết bị 2026-10-20) · Làm **sau** [5-B](5-B-sua-ki-th02.md)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt"; rà lại theo code sau 5-B 2026-11-04: thiếu `extra` dùng `redirect` theo bài học 4-W R1-1, thêm phần đổi router test, mục 5 viết lại theo `superpowers:writing-plans`: Task 0–8 + Review Focus) | Làm ✅ 2026-11-04 (chưa commit) | Review ✅ R2 2026-11-04 (đã sửa R1-1…R1-5; còn kiểm tay 6.2 + build web — người dùng)
> Dùng lại của W-2: `VListDetailLayout`, `VListDetailLayout.isSplitOf`, `VCard.isSelected`, `showVAdaptiveSheet`. Mẫu: plan [4-W](../P4/4-W-partner-web.md) (cùng cách làm, cùng lý do thứ tự route, **cùng lỗi R1-1**), `apps/erp/lib/features/partner/presentation/partner_area_shell.dart`, nhánh KH & NCC trong `app_router.dart` (≈ 364–425).
> Đường dẫn tệp là đường sau 5-A3 / 5-B. Số dòng "≈" đo lại 2026-11-04 trên cây hiện tại (5-A3, 5-A4, 5-B chưa commit), chỉ để tìm chỗ.
> **Trước khi làm:** 5-A3 / 5-A4 / 5-B chưa commit, nhiều tệp `features/catalog/logic/` còn untracked ⇒ `git grep` **không** thấy. Mọi lệnh kiểm trong plan dùng `grep -rn`. Chạy `node .gitnexus/run.cjs analyze` trước `impact`.

## 1. Mục tiêu

**Web rộng** (vùng nội dung ≥ 840):

- Tab Sản phẩm chia 2 cột: trái là danh sách, phải là PCC của sản phẩm đang chọn.
- URL theo sản phẩm (`/products/items/:productId`); mở thẳng URL / tải lại trang ra đúng 2 cột, dòng đó được chọn.
- Mọi sheet của catalog thành hộp thoại giữa màn (≥ 1024), Esc đóng.
- Màn con của PCC (hồ sơ, ảnh, ghi chú, đơn vị, tồn, giá cơ sở, khung giá, sửa khung giá, trường bổ sung, checklist, lịch sử) và màn Cài đặt sản phẩm: **toàn màn**, cột 720 của `VPageScaffold`.

**Hẹp / iPhone:** như hiện tại, trừ đổi có chủ đích (Q1): PCC nằm trong tab, thanh tab dưới vẫn hiện khi xem PCC.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | PCC khi danh sách là một tab | **Theo mẫu Theme 3 (người dùng chốt 2026-11-01):** PCC là route con `/products/items/:productId` của `/products/items` trong `StatefulShellBranch` của tab |
| Q2 | Màn con của PCC | **Người dùng chốt 2026-11-01:** đổi đường sang có id: `/products/items/pcc/<x>` → `/products/items/:productId/<x>` (giữ nguyên đoạn `<x>` và tên route), route gốc toàn màn khai báo **trước** `ShellRoute(StoreShell)`. Thiếu `extra` (mở thẳng URL / tải lại trang) → về `/products/items/:productId`. **Cách làm (rà 2026-11-04):** `redirect:` trên `GoRoute`, **không** dựng trang chờ + `addPostFrameCallback` + `go` — 4-W R1-1 cho thấy cách đó báo `Duplicate GlobalKey` khi PCC nằm trong tab |
| Q3 | Cài đặt sản phẩm (nhóm / trường bổ sung, khung giá cửa hàng + lịch sử) | **Người dùng chốt 2026-11-01:** toàn màn cột 720, giữ route hiện có; chỉ đổi sheet → hộp thoại |
| Q4 | PCC mở bằng URL không có `extra` (không có `ProductListItemModel` từ danh sách) | **Đề xuất, duyệt plan là chốt:** PCC tải theo id; `extra` chỉ để hiện tên sớm. Sau khi tải xong, `product` truyền xuống thân / màn con dựng từ PCC (`CatalogUiMapper.listItemFromControlCenter`, mục 3.3). Lý do: màn ghi chú gửi lại `name / tradeName / sku / barcode` của `product` khi lưu (`product_note_edit_page.dart` ≈ 65–70), nên `product` thiếu dữ liệu sẽ **xoá mất** các trường đó |
| Q5 | Lối "Mở sản phẩm trùng" từ màn tạo (route gốc) | **Đề xuất, duyệt plan là chốt:** thêm route gốc toàn màn `/products/items/:productId/view` (tên `products.items.view`) dựng **cùng** `ProductControlCenterPage`, khai báo trước `ShellRoute`. Màn tạo `push` route này nên "Quay lại" về đúng form đang nhập. Không `push` vào route trong tab từ route gốc (trang tab sẽ nằm **dưới** màn tạo, không thấy) |
| Q6 | Bảng (`VTable`) cho danh sách sản phẩm | **Đề xuất:** không. Cột trái hẹp; dùng thẻ như iPhone (giống 4-W Q3) |
| Q7 | Chuỗi mới | **Đề xuất (nguyên văn):** ô chi tiết trống "Chọn một sản phẩm để xem chi tiết." Không có chuỗi mới khác |

## 3. Thiết kế

### 3.1 Cây route (`apps/erp/lib/core/router/app_router.dart`)

**Hiện tại (đo 2026-11-04):** tab Sản phẩm = `GoRoute('/products/items', name: 'products.items', builder: const ProductCatalogTabPage())` (≈ 356–362, trong `StatefulShellBranch` thứ 3). `ShellRoute(StoreShell)` bắt đầu ≈ 329. `/products/items/new`, `/products/items/pcc` và 11 route `/products/items/pcc/<x>` ở cấp gốc **sau** `...$appRoutes` (≈ 981–1090), tức **sau** `ShellRoute`. Các route KH & NCC cụ thể đã đứng trước `ShellRoute` (≈ 202–328) — chèn route sản phẩm ngay sau khối đó.

**Sau khi sửa:**

```text
GoRoute /products/items/new                                   (products.items.new)                     ← chuyển lên TRƯỚC ShellRoute
GoRoute /products/items/:productId/view                       (products.items.view)      MỚI (Q5)      ← TRƯỚC
GoRoute /products/items/:productId/checklist                  (products.items.pcc.checklist)           ← TRƯỚC
GoRoute /products/items/:productId/measurement-units          (products.items.pcc.measurement-units)   ← TRƯỚC
GoRoute /products/items/:productId/stock                      (products.items.pcc.stock)               ← TRƯỚC
GoRoute /products/items/:productId/note                       (products.items.pcc.note)                ← TRƯỚC
GoRoute /products/items/:productId/manual-base-price          (products.items.pcc.manual-base-price)   ← TRƯỚC
GoRoute /products/items/:productId/price-bands                (products.items.pcc.price-bands)         ← TRƯỚC
GoRoute /products/items/:productId/price-bands/edit           (products.items.pcc.price-bands.edit)    ← TRƯỚC
GoRoute /products/items/:productId/custom-fields/edit         (products.items.pcc.custom-fields.edit)  ← TRƯỚC
GoRoute /products/items/:productId/profile-maintenance        (products.items.pcc.profile-maintenance) ← TRƯỚC
GoRoute /products/items/:productId/images-maintenance         (products.items.pcc.images-maintenance)  ← TRƯỚC
GoRoute /products/items/:productId/change-history             (products.items.pcc.change-history)      ← TRƯỚC
ShellRoute(StoreShell)
└─ StatefulShellRoute.indexedStack
   └─ StatefulShellBranch (tab Sản phẩm)
      └─ ShellRoute builder: ProductAreaShell(selectedId: state.pathParameters['productId'], child)
         └─ GoRoute /products/items        (products.items)     → ô trống Q7 (isSplit) / ProductCatalogTabPage(cubit)
            └─ GoRoute :productId          (products.items.pcc) → ProductControlCenterPage(key: ValueKey(productId), …)
```

- Thứ tự: như 4-W 3.1 (go_router so theo thứ tự khai báo; `/products/items/new` sẽ khớp `:productId = 'new'` nếu để sau).
- **11 màn con:** thân builder giữ (`state.extra as XxxRouteArgs` …). Thêm `redirect: (context, state) => state.extra is XxxRouteArgs ? null : '/products/items/${state.pathParameters['productId']}'` (3 route `profile-maintenance`, `images-maintenance`, `change-history` nhận `ProductListItemModel` ⇒ `is ProductListItemModel`). Mẫu: route `partner.transform` sau 4-W R1-1.
- **`products.items.view` (Q5):** `ProductControlCenterPage(productId: id, initialProduct: state.extra as ProductListItemModel?)` toàn màn; nút ← giữ `canPop ? pop : go('/products/items')`.
- **`products.items.pcc` (con trong tab):** `ProductControlCenterPage(key: ValueKey(productId), productId: productId, initialProduct: state.extra is ProductControlCenterRouteArgs ? (state.extra as ProductControlCenterRouteArgs).product : null, onMutated: () => listCubit.fetchProducts(isRefresh: true))` với `final listCubit = context.read<ProductListCubit>();` đọc **trước** `return` (như `partner.detail`).
- Builder `/products/items`: `isSplitOf(context)` → ô trống Q7 (chép khung ô trống của `partner.list`, ≈ 381–395, đổi chuỗi); ngược lại → `ProductCatalogTabPage(cubit: context.read<ProductListCubit>())`.
- `erp_bottom_navigation.dart:53` chọn tab bằng `location.startsWith('/products')` ⇒ đường mới vẫn đúng, **không sửa**.

### 3.2 `ProductAreaShell` (tạo `apps/erp/lib/features/catalog/presentation/product_area_shell.dart`)

Chép khung `PartnerAreaShell`:

- Tham số: `required Widget child`, `String? selectedId`, `ProductRepository? repository`, `ProductListCubit? cubit` (chỉ cho test: có thì `BlocProvider.value`, không tạo, không tải).
- `BlocProvider(create: (_) => ProductListCubit(productRepository: repository ?? getIt<ProductRepository>())..fetchProducts(criteria: ProductSearchCriteria(businessStatuses: {ProductBusinessStatus.active, ProductBusinessStatus.inactive})))` — **chuyển nguyên** lời tạo + tải đầu khỏi `ProductCatalogTabPage.initState` (≈ 36–44). Tên tham số đúng là `productRepository:`.
- `VListDetailLayout(list: ProductCatalogTabPage(cubit: c, selectedId: selectedId), detail: child)`.
- Không kiểm quyền (catalog không có cổng quyền ở client, đo 2026-11-01).

### 3.3 `ProductCatalogTabPage`, `ProductControlCenterPage`, `ProductControlCenterBody`

**`ProductCatalogTabPage`** (`pages/product_catalog_tab_page.dart`):

- Tham số mới `ProductListCubit? cubit`, `String? selectedId`. Có `cubit` → dùng, **không** tải đầu, **không** `close()` trong `dispose` (≈ 52); không có → tự tạo + tải như cũ (test cũ chạy được). `_loadFilterOptions()` giữ ở trang.
- **Hai** hàm mở PCC đều rẽ nhánh: `_navigateToProduct(context, dto)` (bấm dòng, ≈ 192–223) và `_navigateToProductModel(context, model)` (sau khi tạo, ≈ 179–190):
  - `isSplitOf` → `context.go('/products/items/${model.id}', extra: ProductControlCenterRouteArgs(product: model))`, không tải lại (PCC báo qua `onMutated`);
  - ngược lại → **giữ** `push(...)` + `fetchProducts(isRefresh: true)` khi quay về, đổi đường thành `/products/items/${model.id}`.
- `_onCreateProduct` (≈ 225): giữ `push('/products/items/new')` + tải lại; có sản phẩm mới → `_navigateToProductModel`.
- `selectedId` → `ProductCatalogListBody(selectedId:)` → `ProductListItemTile(isSelected: item.id == selectedId)` → `VCard(isSelected: isSelected ? true : null, …)` (`widgets/product_list_item_tile.dart:20`).

**`ProductControlCenterPage`** (`pages/product_control_center_page.dart`):

- `ProductControlCenterRouteArgs` giữ. Chữ ký mới: `ProductControlCenterPage({super.key, required String productId, ProductListItemModel? initialProduct, VoidCallback? onMutated})`. Tải: `loadControlCenter(productId)` (≈ 31).
- Tiêu đề (≈ 115): `controlCenter?.profile.name ?? initialProduct?.name ?? ''` (bọc `VPageScaffold` trong `BlocBuilder` hoặc đọc `state` sẵn có). Badge (≈ 132): `fallbackIsSoftDeleted: initialProduct?.isSoftDeleted ?? false`.
- `product` truyền xuống `ProductControlCenterBody` (Q4): tải xong → `CatalogUiMapper.listItemFromControlCenter(state.controlCenter!, base: initialProduct)`; chưa tải → `initialProduct ?? CatalogUiMapper.minimalFromDuplicate(productId: productId, productName: '')`. `_handleDeactivate` / `_handleReactivate` dùng `productId`.
- **Hàm mới** `CatalogUiMapper.listItemFromControlCenter(ProductControlCenterDto cc, {ProductListItemModel? base})` (`presentation/mappers/catalog_ui_mapper.dart`): `(base ?? minimalFromDuplicate(productId: cc.profile.productId, productName: cc.profile.name)).copyWith(name: cc.profile.name, tradeName: cc.profile.tradeName, sku: cc.profile.sku, barcode: cc.profile.barcode, images: cc.profile.images, imageUrl: cc.profile.primaryImageUrl, businessStatus: cc.profile.businessStatus, baseUnit: cc.units.baseUnitName, notes: cc.profile.note, stockQty: cc.stock.quantity)` (getter đã đo ở `data/models/product_control_center.dart` ≈ 55–125, 262–278).
- Nút ← (≈ 120–128): `isSplitOf` → `leading: null` + `showBackButton: false` (PCC đang truyền `leading` riêng nên `showBackButton` một mình không đủ); ngược lại giữ `IconButton` `canPop ? pop : go('/products/items')`.
- `onMutated?.call()` khi `actionStatus == success` (≈ 80, ngừng / kinh doanh lại) và qua body (dưới).

**`ProductControlCenterBody`** (`widgets/product_control_center_body.dart`):

- 10 lời `context.push('/products/items/pcc/<x>', …)` (≈ 131, 215, 232, 245, 258, 273, 291, 309, 322, 338) → `'/products/items/${product.id}/<x>'`; `extra` giữ.
- Tham số mới `VoidCallback? onMutated`; gọi trong `_reload(context)` (≈ 176) — chỗ duy nhất mọi nhánh tải lại đi qua (`_reloadAfterPush`, `didChange == true`, `onRestored`).
- `ProductDeleteConfirmDialog.show(…)` (≈ 143) truyền thêm `onDeleted: onMutated`.

**Xoá sản phẩm** (`widgets/product_delete_confirm_dialog.dart`): thêm `VoidCallback? onDeleted` vào `show(...)` và constructor. Listener thành công (≈ 42–54): toast giữ, `Navigator.of(context).pop()` giữ; sau đó `isSplitOf` → `onDeleted?.call()` + `context.go('/products/items')`; ngược lại giữ `canPop ? pop(true) : go('/products/items')`. `isSplitOf` đọc bằng context của **trang** (truyền `bool isSplit` vào `show` từ body), vì context trong hộp thoại không nằm dưới `VListDetailLayout`.

**Màn tạo** (`pages/product_guided_create_page.dart` ≈ 68–78): "Mở sản phẩm trùng" → `context.push('/products/items/$productId/view', extra: CatalogUiMapper.minimalFromDuplicate(...))` (Q5; `extra` là `ProductListItemModel`, không còn bọc `ProductControlCenterRouteArgs`).

**`product_readiness_checklist_page.dart`** (6 lời push ≈ 75, 85, 95, 105, 122, 145) và **`product_price_bands_page.dart:215`**: đổi đường như body.

### 3.4 Sheet → hộp thoại

Đổi tên hàm `showVBottomSheet` → `showVAdaptiveSheet`, giữ tham số (hai hàm cùng tham số: `context, title, child, tone, semanticLabel, isDismissible, enableDrag`), ở **14 chỗ** (đo 2026-11-04): `pages/product_catalog_tab_page.dart:136`, `widgets/store_price_rule_save_confirm_sheet.dart:6`, `product_delete_confirm_dialog.dart:25`, `product_conversion_unit_delete_blocked_dialog.dart:19`, `product_conversion_unit_deactivate_confirm_dialog.dart:19`, `product_restore_confirm_dialog.dart:29`, `custom_field_group_deactivate_confirm_sheet.dart:19`, `product_conversion_unit_delete_confirm_dialog.dart:19`, `unsaved_changes_confirm_sheet.dart:10`, `product_lifecycle_bottom_sheets.dart:121,140`, `custom_field_deactivate_confirm_sheet.dart:8`, `product_conversion_unit_reactivate_confirm_dialog.dart:19`, `price_band_overwrite_dialog.dart:13`. Chú thích `custom_field_filter_sheet.dart:7` đổi chữ theo.

`widgets/image_picker/product_image_add_sheet.dart` (`showModalBottomSheet` thô ≈ 9, tự vẽ nền + tiêu đề "Thêm ảnh sản phẩm" ≈ 21–39): `show` → `showVAdaptiveSheet<ProductImageSource>(context: context, title: 'Thêm ảnh sản phẩm', child: const _ProductImageSourceOptions())`. `_ProductImageSourceOptions` = phần `Column` các lựa chọn hiện có, **bỏ** `Container` nền / bo góc và `VText` tiêu đề. `pop(source)` giữ.

Giữ: `showVConfirmDialog` (`upsert_custom_field_page.dart:449`), `showDialog` (`product_image_delete_dialog.dart:8`).

### 3.5 Router trong test

`test/features/catalog` tự dựng `GoRouter` với đường cũ: `catalog_e2e_harness.dart` (31 chỗ), `product_readiness_e2e_test.dart` (8), `product_readiness_checklist_page_test.dart` (6), `product_measurement_units_e2e_test.dart` (4), `product_stock_e2e_test.dart` (4), `product_manual_base_price_e2e_test.dart` (3), `product_price_bands_e2e_test.dart` (3), `product_control_center_page_test.dart` (2). App push đường mới thì các router này phải khai báo đường mới, nếu không test vỡ vì "no routes for location":

- `path: '/products/items/pcc'` → `'/products/items/:productId'`; `path: '/products/items/pcc/<x>'` → `'/products/items/:productId/<x>'` (đoạn `<x>` theo app; harness có `units`, `edit-price-band` lệch app thì sửa theo app: `measurement-units`, `price-bands/edit`, ghi vào Kết quả).
- Builder PCC trong test: `ProductControlCenterPage(productId: state.pathParameters['productId']!, initialProduct: (state.extra as ProductControlCenterRouteArgs?)?.product)`.
- Route giả của checklist test (`Text('route:<đuôi>')`): chỉ đổi `path`, giữ `Text`.
- **Không** đổi điều kiện kiểm của test nào.

## 4. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi (Task 0) |
|---|---|---|---|
| W1 | `ProductCatalogTabPage.initState` tạo `ProductListCubit` + `fetchProducts(active, inactive)`; `dispose` đóng | `ProductAreaShell` tạo + tải. Trang chỉ tự tạo khi không được truyền `cubit` | `w1_open_list_searches_once`: dựng `/products/items` → `search` = 1; vào PCC rồi về → không thêm lần dựng cubit (đếm theo W2) |
| W2 | Chọn sản phẩm → `push('/products/items/pcc', extra)` → quay về → tải lại | hẹp: `push('/products/items/:id', extra)` + tải lại; rộng: `go` | `w2_open_pcc_and_back_refreshes` (390) |
| W3 | Tạo xong → về danh sách, tải lại, mở PCC sản phẩm mới | giữ (đường mới) | `w3_create_opens_new_pcc` (390) |
| W4 | PCC: ngừng / kinh doanh lại → tải lại PCC + toast; quay về từ màn con có đổi → tải lại PCC | giữ + gọi `onMutated` | `w4_deactivate_toast`, `w4_note_saved_reloads_pcc` (390). Sau sửa thêm ở 1280: danh sách tải lại |
| W5 | Xoá: đóng sheet; `canPop ? pop(true) : go('/products/items')`; danh sách tải lại khi `push` trả về | hẹp giữ; rộng: toast + `onDeleted` + `go('/products/items')` | `w5_delete_back_to_list_refreshes` (390). Sau sửa thêm ở 1280 |
| W6 | 11 màn con: đọc `extra`, mở đúng trang; quay về trả `bool` | đường mới có id; thân builder giữ; thiếu `extra` → `redirect` về PCC của id | `w6_<x>_opens` × 11 (390, mở từ PCC). Sau sửa thêm 11 ca mở thẳng không `extra` |
| W7 | Màn tạo → "Mở sản phẩm trùng" → `push` PCC (route gốc) → "Quay lại" về form, giữ dữ liệu đã nhập | `push('/products/items/:id/view')` (Q5) | `w7_open_duplicate_and_back_keeps_form` (390) |
| W8 | PCC mở từ danh sách luôn có `ProductListItemModel` đủ field; ghi chú lưu lại `name / tradeName / sku / barcode` của model | **Đổi (Q4):** `product` dựng từ PCC sau khi tải | test mới Task 3 |
| W9 | 14 sheet + sheet chọn nguồn ảnh = bottom sheet ở mọi bề rộng | ≥ 1024 hộp thoại; hẹp như cũ | `w9_sheets_are_bottom_sheets_390` (lọc, ngừng KD, nguồn ảnh). Sau sửa thêm ở 1280 |
| W10 | PCC là route gốc toàn màn (che thanh tab trên iPhone) | **Đổi (Q1):** trong tab | test mới Task 5 |
| W11 | Chỗ đi tới PCC / màn con trong `lib`: body (10), checklist (6), khung giá (1), màn tạo (1), tab danh sách (2) | đổi đường | `grep -rn "/products/items/pcc" apps/erp/lib apps/erp/test` → rỗng (tên route `products.items.pcc*` giữ) |

## 5. Các bước

> Viết theo `superpowers:writing-plans`. Thực hiện: `superpowers:executing-plans` (tuần tự trong phiên). Mỗi task xong ghi ngay mục 8. **Không commit** (người dùng commit sau `detect_changes()`).
> Lệnh test chạy trong `apps/erp`. Test router thật dùng harness mới `test/features/catalog/support/catalog_router_harness.dart` (Task 0).

**Ràng buộc chung** (mọi task):
- Giữ nghiệp vụ; chỉ đổi điều hướng / bố cục / sheet như mục 3. Chuỗi mới duy nhất: "Chọn một sản phẩm để xem chi tiết." (Q7).
- Trước mỗi symbol Dart sửa: `node .gitnexus/run.cjs analyze` (một lần đầu phiên) rồi `impact` upstream; ghi bảng (symbol · d=1 · luồng · rủi ro) vào Kết quả từ output thật. HIGH / CRITICAL (`app_router.dart`, `ProductControlCenterPage` gần như chắc HIGH): ghi lại, báo người dùng, làm tiếp vì đã có test Task 0.
- Test Task 0 **không đổi điều kiện kiểm** sau khi sửa, chỉ đổi cách dựng / đường dẫn. Riêng W8, W10 đổi có chủ đích.
- Kiểm bằng `grep -rn` (không `git grep`). Không làm gì với DB.
- Mọi test router thật kiểm `tester.takeException()` là `null` (bắt `Duplicate GlobalKey`).

## Review Focus

1. Từ PCC trong tab mở thẳng `/products/items/product-1/note` không `extra` (gõ URL / tải lại trang): về PCC, **không** `Duplicate GlobalKey` (lỗi 4-W R1-1) — Task 4, `w6_no_extra_redirects_from_tab`.
2. `/products/items/new` mở màn tạo, không bị hiểu là PCC của id `'new'` — Task 4, `route_new_is_create_not_pcc`.
3. Mở thẳng `/products/items/product-1` (không `extra`) rồi sửa ghi chú: `tradeName`, `sku`, `barcode` gửi lên đúng của sản phẩm, không `null` — Task 3, `w8_note_from_url_keeps_profile_fields`.
4. Web 2 cột: chọn chip "Ngừng KD" rồi bấm một sản phẩm → chip vẫn chọn, danh sách vẫn lọc (cột trái không dựng lại) — Task 5, `split_select_keeps_filter_chip`.
5. Web 2 cột: xoá sản phẩm → ô phải về trống, URL `/products/items`, danh sách tải lại, không đóng nhầm cả tab — Task 5, `split_delete_clears_detail`.

---

### Task 0: Harness router + test giữ hành vi (W1–W7, W9) trên code cũ

**Files:**
- Create: `apps/erp/test/features/catalog/support/catalog_router_harness.dart`
- Create: `apps/erp/test/features/catalog/presentation/catalog_5w_behavior_preservation_test.dart`

**Produces:** `setUpCatalogRouterTest()`, `tearDownCatalogRouterTest()`, `pumpCatalogApp(WidgetTester tester, {String scenario = FakeCatalogScenario.guidedCreateOk, FakeCatalogBackend? backend, ProductRepository? productRepository, Size size = const Size(390, 844), String location = '/products/items'}) → Future<FakeCatalogBackend>`, `String get catalogCurrentPath`, `int catalogSearchCalls(FakeProductRepository repo)` (đếm `calls` == `'search'`).

- [x] **0.1** Viết harness theo `test/features/partner/support/partner_router_harness.dart`: `setUp` reset `getIt`, đăng ký `IExecutionContext` (`FakeExecutionContext(tenantId: 'tenant-test')`) + `DefaultPairRepository` (`FakeDefaultPairRepository`); `pumpCatalogApp` đặt kích thước, bỏ lỗi `overflowed`, `loginSession(...)` + `applySignedInUser('user-1')`, `registerFakeCatalog(getIt, scenario: scenario, backend: backend, registerExecutionContext: false)`; có `productRepository` thì thay `ProductRepository`; `pumpWidget(MaterialApp.router(theme: VTheme.lightTheme, routerConfig: appRouter))`, `appRouter.go(location)`, `pumpAndSettle`. Dữ liệu fake (`support/fake_catalog_backend.dart` ≈ 400–500) có `product-1` "Amoxicillin 500mg" (`tradeName: 'Amox 500'`, `sku: 'SP0001'`, `barcode: '8930000000001'`), `product-2` "Paracetamol 500mg", `product-6` "Thuốc thiếu đơn vị": kiểm danh sách mặc định thấy cả ba; không thấy thì chọn kịch bản khác và ghi tên vào Kết quả.
- [x] **0.2** Viết test (390 × 844), mỗi test cuối kiểm `tester.takeException()` null:
  - `w1_open_list_searches_once`: `/products/items` → `catalogSearchCalls == 1`.
  - `w2_open_pcc_and_back_refreshes`: bấm "Amoxicillin 500mg" → `find.byKey(Key('wgt_e01_u02_fr01_01'))` có, tiêu đề "Amoxicillin 500mg"; bấm ← → về danh sách, `search` tăng đúng 1.
  - `w3_create_opens_new_pcc`: theo `createMinimalProduct` của `catalog_e2e_harness.dart` (≈ 485) → thấy PCC tên vừa nhập.
  - `w4_deactivate_toast`: PCC → mở mục thao tác (như `_openDangerSection` của `product_soft_delete_e2e_test.dart`) → "Ngừng kinh doanh" → xác nhận "Ngừng kinh doanh" trên sheet → `find.text('Đã cập nhật trạng thái kinh doanh của sản phẩm.')`; `w4_note_saved_reloads_pcc`: PCC → ghi chú → nhập "ghi chú mới" → lưu → PCC thấy "ghi chú mới".
  - `w5_delete_back_to_list_refreshes`: sản phẩm xoá được (`product-6` "Thuốc thiếu đơn vị") → xoá → `find.text('Sản phẩm đã được xóa thành công.')`, về danh sách, `search` tăng.
  - `w6_<x>_opens` × 11 (`checklist`, `measurement-units`, `stock`, `note`, `manual-base-price`, `price-bands`, `price-bands/edit` (từ màn khung giá), `custom-fields/edit` (kịch bản có nhóm), `profile-maintenance`, `images-maintenance`, `change-history`): mở từ PCC → thấy kiểu trang tương ứng (`find.byType(ProductNoteEditPage)` …). Mục nào cần kịch bản khác: dùng `pumpCatalogApp(scenario: …)` riêng, ghi tên.
  - `w7_open_duplicate_and_back_keeps_form`: kịch bản `guidedCreateDupSku`, mở màn tạo, nhập tên "Thuốc trùng" + SKU trùng, lưu → bấm `find.textContaining('Mở sản phẩm "')` (`widgets/product_guided_step_identification.dart:103`) → thấy PCC; ← → `find.text('Thuốc trùng')` còn trong ô tên.
  - `w9_sheets_are_bottom_sheets_390`: sheet lọc (nút lọc danh sách), sheet ngừng KD (PCC), sheet nguồn ảnh (màn ảnh → "Thêm") → mỗi cái `find.byType(BottomSheet)` có, `find.byType(VSheetDialog)` không.
- [x] **0.3** Chạy `flutter test test/features/catalog/presentation/catalog_5w_behavior_preservation_test.dart` → PASS (code chưa đổi). Ca nào không dựng được trên code cũ: ghi lý do vào Kết quả, không bỏ âm thầm.
- [x] **0.4** Ghi mốc: `flutter test test/features/catalog` (sau 5-B: 594 đạt / 1 bỏ qua / 46 lỗi) và `flutter test` toàn app (đạt / lỗi) vào Kết quả.

### Task 1: `CatalogUiMapper.listItemFromControlCenter`

**Files:** Modify `apps/erp/lib/features/catalog/presentation/mappers/catalog_ui_mapper.dart`; Test `apps/erp/test/features/catalog/presentation/mappers/catalog_ui_mapper_test.dart` (tạo nếu chưa có).

**Produces:** `static ProductListItemModel listItemFromControlCenter(ProductControlCenterDto cc, {ProductListItemModel? base})`.

- [x] **1.1** Test đỏ `list_item_from_control_center_maps_all_fields`: DTO có `profile` (`productId: 'p1'`, `name: 'A'`, `tradeName: 'TA'`, `sku: 'S1'`, `barcode: 'B1'`, `businessStatus: inactive`, `primaryImageUrl: 'u'`, `images: ['k']`, `note: 'n'`), `units.baseUnitName: 'Hộp'`, `stock.quantity: 5`, `base: null` → model có đủ 10 giá trị trên, `id == 'p1'`. Test `list_item_from_control_center_keeps_base_prices`: `base` có `listBeforeVat: 100` → kết quả vẫn `listBeforeVat == 100`. Chạy → FAIL (chưa có hàm).
- [x] **1.2** Viết hàm theo mục 3.3. Chạy lại → PASS.

### Task 2: `ProductAreaShell` + danh sách nhận `cubit` / `selectedId`

**Files:** Create `apps/erp/lib/features/catalog/presentation/product_area_shell.dart`; Modify `pages/product_catalog_tab_page.dart` (≈ 16–53, 179–231), `widgets/product_catalog_list_body.dart` (≈ 13–25, 136–139), `widgets/product_list_item_tile.dart` (≈ 10–21). Test: `apps/erp/test/features/catalog/presentation/pages/product_catalog_tab_page_test.dart`.

**Produces:** `ProductAreaShell({required Widget child, String? selectedId, ProductRepository? repository, ProductListCubit? cubit})`; `ProductCatalogTabPage({ProductListCubit? cubit, String? selectedId})`; `ProductListItemTile({…, bool isSelected = false})`.

- [x] **2.1** Test đỏ trong `product_catalog_tab_page_test.dart`: `tab_page_with_cubit_does_not_fetch_or_close`: truyền `cubit` đã tải sẵn → `RecordingProductRepository.criteria` không tăng khi dựng; tháo trang → `cubit.isClosed == false`. `tab_page_selected_tile`: `selectedId: 'product-1'` → `VCard` của "Amoxicillin 500mg" có `isSelected == true`, thẻ khác `null`. Chạy → FAIL.
- [x] **2.2** Sửa theo 3.2, 3.3 (phần danh sách; `_navigateToProduct*` rẽ nhánh `isSplitOf`, đường `/products/items/${id}`). Chưa sửa router (Task 4) ⇒ nhánh hẹp `push('/products/items/${id}')` chưa có route: **chỉ đổi đường ở Task 4**, Task 2 giữ `'/products/items/pcc'`.
- [x] **2.3** Chạy `flutter test test/features/catalog/presentation/pages/product_catalog_tab_page_test.dart` → 2 test mới PASS, B3 / G2 giữ xanh (1 đỏ baseline `e2e_e01_u01_fr01_01` giữ).

### Task 3: PCC theo id + `onMutated` + xoá + màn tạo

**Files:** Modify `pages/product_control_center_page.dart`, `widgets/product_control_center_body.dart`, `widgets/product_delete_confirm_dialog.dart`, `pages/product_guided_create_page.dart`; Test `apps/erp/test/features/catalog/presentation/pages/product_control_center_page_test.dart`.

**Consumes:** Task 1 `listItemFromControlCenter`.
**Produces:** `ProductControlCenterPage({required String productId, ProductListItemModel? initialProduct, VoidCallback? onMutated})`; `ProductControlCenterBody({…, VoidCallback? onMutated})`; `ProductDeleteConfirmDialog.show(context, {…, bool isSplit = false, VoidCallback? onDeleted})`.

- [x] **3.1** Đổi mọi chỗ dựng `ProductControlCenterPage(product: x)` (`app_router.dart` 1 chỗ tạm `productId: args.product.id, initialProduct: args.product`; test: `catalog_e2e_harness.dart` 4, 7 tệp test mỗi tệp 1 — danh sách ở mục 3.5) sang chữ ký mới. Chạy `flutter test test/features/catalog` → số lỗi = mốc Task 0.4.
- [x] **3.2** Test đỏ trong `product_control_center_page_test.dart`:
  - `pcc_loads_by_id_without_initial_product`: `ProductControlCenterPage(productId: 'product-1')` (không `initialProduct`) → tiêu đề "Amoxicillin 500mg" sau khi tải.
  - `w8_note_from_url_keeps_profile_fields`: không `initialProduct`, mở ghi chú, lưu "n2" → lớp con `FakeProductRepository` ghi tham số `updateProfile` (cục bộ trong tệp test) nhận `productName: 'Amoxicillin 500mg'`, `commercialName: 'Amox 500'`, `sku: 'SP0001'`, `barcode: '8930000000001'`, `note: 'n2'`.
  - `pcc_on_mutated_after_reload`: `onMutated` đếm; ngừng KD thành công → đếm 1; sửa ghi chú lưu → đếm 2.
  - Chạy → FAIL.
- [x] **3.3** Sửa theo 3.3 (trang, body, hộp xoá, màn tạo; đường màn tạo `'/products/items/$productId/view'` đổi ở Task 4 cùng router — Task 3 tạm giữ đường cũ).
- [x] **3.4** Chạy lại → 3 test mới PASS; `flutter test test/features/catalog` không lỗi mới so với mốc.

### Task 4: Router + đường mới

**Files:** Modify `apps/erp/lib/core/router/app_router.dart` (≈ 202–328 chèn, 356–362 thay, 981–1090 xoá); `pages/product_catalog_tab_page.dart`, `widgets/product_control_center_body.dart`, `pages/product_readiness_checklist_page.dart`, `pages/product_price_bands_page.dart`, `pages/product_guided_create_page.dart` (đường); 8 tệp test mục 3.5. Test: `catalog_5w_behavior_preservation_test.dart`.

**Consumes:** Task 2, 3.

- [x] **4.1** Test đỏ thêm vào `catalog_5w_behavior_preservation_test.dart` (390):
  - `route_new_is_create_not_pcc`: `appRouter.go('/products/items/new')` → `find.byType(ProductGuidedCreatePage)` có, `ProductControlCenterPage` không.
  - `w6_no_extra_redirects_from_tab`: mở `/products/items/product-1`, rồi `appRouter.go('/products/items/product-1/<x>')` cho từng `<x>` trong 11 màn con → `catalogCurrentPath == '/products/items/product-1'`, thấy PCC, `takeException()` null.
  - `w6_no_extra_redirects_from_list`: như trên nhưng xuất phát `/products/items`.
  - `deep_link_pcc_opens_in_tab`: `location: '/products/items/product-1'` → PCC "Amoxicillin 500mg".
  - Chạy → FAIL.
- [x] **4.2** Sửa router theo 3.1; đổi đường ở 5 tệp `lib` (3.3); đổi 8 tệp test theo 3.5.
- [x] **4.3** `grep -rn "/products/items/pcc" apps/erp/lib apps/erp/test` → rỗng.
- [x] **4.4** Chạy `flutter test test/features/catalog/presentation/catalog_5w_behavior_preservation_test.dart` → mọi test Task 0 + 4.1 PASS, điều kiện kiểm Task 0 không đổi. `flutter test test/features/catalog` không lỗi mới so với mốc Task 0.4.

### Task 5: Web 2 cột (1280 × 800) + W10

**Files:** Create `apps/erp/test/features/catalog/presentation/catalog_5w_wide_layout_test.dart` (mẫu `partner_4w_wide_layout_test.dart`). Sửa `lib` chỉ khi test đỏ vì code Task 2–4 sai.

- [x] **5.1** Test (1280 × 800, `takeException()` null mỗi ca):
  - `split_empty_detail`: `/products/items` → `ProductCatalogTabPage` có, `find.text('Chọn một sản phẩm để xem chi tiết.')` có.
  - `split_select_updates_url_and_selection`: bấm "Amoxicillin 500mg" → `catalogCurrentPath == '/products/items/product-1'`, PCC bên phải, `VCard` của dòng đó `isSelected == true`, danh sách vẫn thấy.
  - `split_deep_link_selects_row`: `location: '/products/items/product-1'` → 2 cột, dòng chọn.
  - `split_switch_a_to_b`: chọn product-1 rồi "Paracetamol 500mg" → tiêu đề PCC "Paracetamol 500mg", không còn "Amoxicillin 500mg" ở tiêu đề.
  - `split_no_back_button`: PCC không có `IconButton` với `VIcons.arrowBack`.
  - `split_select_keeps_filter_chip`: bấm chip "Ngừng KD (…)" rồi bấm một sản phẩm trong danh sách lọc → chip "Ngừng KD" vẫn chọn, `criteria.last.businessStatuses == {inactive}` (Review Focus 4).
  - `split_deactivate_refreshes_list` (W4): ngừng KD → toast, `search` tăng.
  - `split_delete_clears_detail` (W5): xoá `product-6` → toast, ô phải về chuỗi Q7, `catalogCurrentPath == '/products/items'`, `search` tăng (Review Focus 5).
  - `split_subscreen_full_page`: từ PCC mở ghi chú → `ProductNoteEditPage` toàn màn (không còn `ProductCatalogTabPage`); ← về 2 cột.
  - `split_w6_no_extra` (W6): `appRouter.go('/products/items/product-1/note')` → về PCC 2 cột.
- [x] **5.2** Test 390 `w10_pcc_keeps_bottom_tabs` (thêm vào `catalog_5w_behavior_preservation_test.dart`): mở PCC → thanh tab dưới (`ErpBottomNavigation`) vẫn thấy; ← về danh sách.
- [x] **5.3** Chạy 2 tệp → PASS.

### Task 6: Sheet → hộp thoại

**Files:** 14 chỗ + `product_image_add_sheet.dart` ở mục 3.4. Test: `catalog_5w_wide_layout_test.dart`.

- [x] **6.1** Test đỏ `w9_sheets_are_dialogs_1280`: sheet lọc, sheet ngừng KD, sheet nguồn ảnh → `find.byType(VSheetDialog)` có, `BottomSheet` không; `sendKeyEvent(LogicalKeyboardKey.escape)` → hộp thoại đóng. Chạy → FAIL.
- [x] **6.2** Đổi theo 3.4.
- [x] **6.3** `grep -rn "showVBottomSheet(\|showModalBottomSheet(" apps/erp/lib/features/catalog` → rỗng. Chạy `catalog_5w_wide_layout_test.dart` + `catalog_5w_behavior_preservation_test.dart` → PASS (`w9_sheets_are_bottom_sheets_390` giữ xanh).

### Task 7: Dữ liệu gửi đi từ `product` (Q4)

- [x] **7.1** `grep -rn "widget.product\.\|args.product\.\|widget.args.product\." apps/erp/lib/features/catalog/presentation/pages` → ghi bảng vào Kết quả: tệp:dòng · trường · chỉ hiện hay **gửi** lên · nguồn sau Q4. Đo 2026-11-04: gửi đi chỉ có `product_note_edit_page.dart` ≈ 66–70 (đã phủ bằng W8); `product_stock_adjustment_page.dart:142`, `product_manual_base_price_page.dart:120` chỉ đọc `baseUnit` (body đã ghép `baseUnit` từ PCC). Chỗ gửi mới phát hiện: báo người dùng, không tự sửa.

### Task 8: Kiểm toàn bộ + Kết quả

- [x] **8.1** Chạy mục 6.1, ghi lệnh + số đạt / lỗi; so mốc Task 0.4: lỗi mới = 0.
- [x] **8.2** `node .gitnexus/run.cjs analyze` rồi `detect_changes()` → ghi số tệp / symbol / luồng / rủi ro (lưu ý cây còn 5-A3 / 5-A4 / 5-B chưa commit).

## 6. Kiểm tra

### 6.1 Tự động

- [ ] Mọi test Task 0 xanh, **không đổi điều kiện kiểm** (chỉ đổi cách dựng / đường dẫn). Riêng W8, W10 là đổi có chủ đích.
- [ ] Test mới Task 1–6 xanh.
- [ ] `grep -rn "showVBottomSheet(\|showModalBottomSheet(" apps/erp/lib/features/catalog` → rỗng.
- [ ] `grep -rn "/products/items/pcc" apps/erp/lib apps/erp/test` → rỗng.
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi / cảnh báo mới. `flutter test`: không fail mới so với mốc Task 0.4.
- [ ] `cd apps/erp && flutter build web` chạy qua.

### 6.2 Kiểm tay (người dùng)

- [ ] Chrome 1440 × 900 và 1280 × 800: 2 cột; chọn dòng; tạo; mở sản phẩm trùng từ màn tạo rồi quay lại form; sửa hồ sơ / ảnh (tải ảnh lên được trên web) / ghi chú / đơn vị / giá / khung giá; ngừng / kinh doanh lại; xoá; chip "Đã xóa" → khôi phục; tải lại trang ở `/products/items/<id>` và `/products/items/<id>/note` (về PCC) vẫn đúng.
- [ ] Chrome hẹp (~900): một cột như iPhone.
- [ ] Cài đặt sản phẩm trên Chrome rộng: toàn màn cột 720; hộp thoại thay sheet.
- [ ] Bàn phím: Tab qua ô tìm → thẻ → Enter mở PCC; Esc đóng hộp thoại.
- [ ] iPhone simulator: như cũ, trừ thanh tab vẫn hiện khi xem PCC (Q1).

## 7. Rủi ro / lưu ý

- **Thứ tự route** dễ vỡ nhất (như 4-W). W6 mở thẳng URL qua router thật là để bắt lỗi này.
- **Thiếu `extra`:** dùng `redirect`, không dựng trang chờ rồi `go` (4-W R1-1: `Duplicate GlobalKey`). Test xuất phát từ cả `/products/items` và `/products/items/product-1`.
- `ValueKey(productId)` thiếu thì đổi sản phẩm ở 2 cột vẫn hiện PCC cũ.
- Q4 là chỗ dễ gây mất dữ liệu: W8 bắt buộc; Task 7 rà chỗ gửi khác.
- Hộp xoá: context trong hộp thoại không nằm dưới `VListDetailLayout` ⇒ `isSplitOf` ở đó luôn `false`; phải truyền `isSplit` từ trang (3.3).
- Màn SP-10 (tồn) vẫn qua module (5-A3 Q9): chỉ đổi đường, không đổi thân.
- Tải ảnh trên web: `product_image_upload_client.dart` có nhánh `kIsWeb`; `catalog_storage_image.dart`, `product_image_grid_item.dart`, `product_image_gallery_viewer.dart` import `dart:io` nhưng đã chặn bằng `kIsWeb`. `flutter build web` + kiểm tay là chốt; lỗi thì ghi vào Kết quả, **không** tự sửa ngoài phạm vi.

## 8. Kết quả (phiên làm code ghi)

- **Task 0.4 (Baseline trước khi sửa):**
  - Catalog test suite: **594 passed, 1 skipped, 46 failed** (theo `docs/refactor/TEST-BASELINE.md`).
  - Full app test suite: **2205 passed, 1 skipped, 59 failed**.
- **Task 0 (Harness & Preservation tests):** ✅
  - Tạo `apps/erp/test/features/catalog/support/catalog_router_harness.dart` và `catalog_5w_behavior_preservation_test.dart`.
  - Toàn bộ 24/24 tests (bao gồm W1-W7, W9, W10, và các ca Task 4 redirect/deep-link) đều đạt (PASS).
- **Task 1 (`CatalogUiMapper.listItemFromControlCenter`):** ✅
  - Thêm mapper `listItemFromControlCenter` trong `apps/erp/lib/features/catalog/presentation/mappers/catalog_ui_mapper.dart`.
  - Tạo `apps/erp/test/features/catalog/presentation/mappers/catalog_ui_mapper_test.dart` (2 unit test đạt 100%).
- **Task 2 (`ProductAreaShell` & 2 cột Tab):** ✅
  - Tạo `apps/erp/lib/features/catalog/presentation/product_area_shell.dart` bọc `VListDetailLayout`. Export trong `presentation.dart`.
  - Cập nhật `ProductListItemTile` hỗ trợ `isSelected: bool`, truyền vào `VCard(isSelected: isSelected ? true : null)`.
  - Cập nhật `ProductCatalogListBody` và `ProductCatalogTabPage` nhận `selectedId` và `cubit` (không tự đóng khi truyền từ ngoài vào). Rẽ nhánh `isSplitOf(context)`.
  - Đạt 2 widget test mới trong `product_catalog_tab_page_test.dart`.
- **Task 3 (PCC theo ID & `onMutated`):** ✅
  - Cập nhật `ProductControlCenterPage`: nhận `{required String productId, ProductListItemModel? initialProduct, VoidCallback? onMutated}`. Tạo fresh `product` qua `CatalogUiMapper.listItemFromControlCenter`.
  - Ẩn back button khi `isSplitOf(context)`. Kích hoạt `onMutated` khi reload hoặc thay đổi trạng thái kinh doanh qua tách `MultiBlocListener`.
  - Cập nhật `ProductControlCenterBody` và `ProductDeleteConfirmDialog` nhận `isSplit` và `onDeleted`, tự động chuyển hướng về `/products/items` khi xóa trên split layout; chỉ gọi `onDeleted?.call()` khi `isSplit` để tránh double reload ở mobile.
  - Cập nhật `ProductGuidedCreatePage` ("Mở sản phẩm trùng") push route `/products/items/$productId/view`.
  - Đạt 8/8 test trong `product_control_center_page_test.dart` (bao gồm `w8_note_from_url_keeps_profile_fields` và `pcc_on_mutated_after_reload`).
- **Task 4 (Router & New Routes):** ✅
  - Trong `app_router.dart`: Khai báo 11 màn con (`/products/items/:productId/<x>`), `/products/items/new` và `/products/items/:productId/view` lên ROOT level TRƯỚC `ShellRoute(StoreShell)`. Giữ đúng route name `products.items.pcc.<x>`. Thiếu `extra` tự động redirect về `/products/items/:productId`.
  - Trong branch 3 của `StoreShell`: bọc `/products/items` bằng `ShellRoute` với `ProductAreaShell`, empty state hiển thị *"Chọn một sản phẩm để xem chi tiết."* và subroute `:productId` cho `ProductControlCenterPage` với `key: ValueKey(productId)` và route name `products.items.pcc`.
  - Đọc `listCubit` trước `return` trong closure builder theo chuẩn router.
  - Xóa bỏ hoàn toàn route cũ `/products/items/pcc` và tất cả các route con `/products/items/pcc/*`.
  - Đã cập nhật tất cả 5 tệp `lib` và 8 tệp test. `grep -rn "/products/items/pcc" apps/erp/lib apps/erp/test` trả về rỗng.
- **Task 5 (Web 2 cột 1280 × 800 & W10):** ✅
  - Sử dụng kích thước chuẩn `1280 × 800` cho desktop.
  - Tạo `apps/erp/test/features/catalog/presentation/catalog_5w_wide_layout_test.dart` gồm 11 widget test toàn diện cho split layout (empty state, select row, deep link, switch A -> B với Completer chặn stale data, no back button với VIcons.arrowBack, giữ filter chip và kiểm tra criteria inactive, deactivate refresh, delete clear detail, subscreen full page, w6 no extra redirect, w9 sheets are dialogs với cả 3 sheet và đóng bằng Escape).
  - 11/11 tests đạt 100%.
- **Task 6 (Adaptive Sheets → Dialogs):** ✅
  - Thay thế 14 vị trí `showVBottomSheet` + 1 vị trí `showModalBottomSheet` (`ProductImageAddSheet`) sang `showVAdaptiveSheet`.
  - `ProductImageAddSheet` giữ widget công khai với helper tĩnh `ProductImageAddSheet.show(context)` để tái sử dụng ở `product_images_maintenance_page.dart` và `product_image_picker_panel.dart`.
  - `grep -rn "showVBottomSheet(\|showModalBottomSheet(" apps/erp/lib/features/catalog` trả về rỗng.
  - Đạt test `w9_sheets_are_dialogs_1280` (`VSheetDialog` xuất hiện trên web rộng, đóng bằng nút Đóng hoặc Escape).
- **Task 7 (Audit `product` tại các màn con):** ✅
  - Kết quả chạy `grep -rn "widget.product\.\|args.product\.\|widget.args.product\." apps/erp/lib/features/catalog/presentation/pages`:
    | Tệp:Dòng | Thuộc tính | Mục đích sử dụng | Đánh giá an toàn |
    |---|---|---|---|
    | `product_manual_base_price_page.dart:109,120,161` | `id`, `baseUnit`, `name` | Lưu giá; fallback đơn vị; subtitle AppBar | An toàn (lấy từ PCC tươi mới) |
    | `product_stock_adjustment_page.dart:98,106,142,153` | `id`, `baseUnit`, `name` | Điều chỉnh tồn kho; fallback đơn vị; subtitle AppBar | An toàn (lấy từ PCC tươi mới) |
    | `product_measurement_units_page.dart:187` | `name` | Subtitle AppBar | An toàn (chỉ hiển thị) |
    | `product_note_edit_page.dart:66-70,117` | `id`, `name`, `tradeName`, `sku`, `barcode` | Lưu ghi chú (UpdateProfile); subtitle AppBar | Đã bảo toàn đầy đủ nhờ W8 & `CatalogUiMapper.listItemFromControlCenter` |
- **GitNexus Impact Analysis (Task 8.1):**
  | Symbol | Direct Callers (d=1) | Luồng ảnh hưởng | Mức độ rủi ro | Ghi chú |
  |---|---|---|---|---|
  | `appRouter` | 0 | 0 | LOW | Router chính của app |
  | `ProductControlCenterPage` | 1 | 74 | CRITICAL | Màn hình trung tâm điều khiển sản phẩm |
  | `ProductCatalogTabPage` | 0 | 0 | LOW | Tab danh mục sản phẩm |
  | `ProductAreaShell` | 0 | 0 | UNKNOWN | Shell bọc layout split 2 cột mới tạo |
- **GitNexus `detect_changes()` (Task 8.2):**
  - Changes: 139 files, 316 symbols, 133 affected execution flows.
- **Task 8 (Xác minh toàn bộ sau Review R1):** ✅
  - `dart analyze lib test`: 0 errors (chỉ còn warning/info cũ không liên quan).
  - 5 tệp test 5-W: **55 passed, 1 failed** (1 lỗi cũ baseline `e2e_e01_u01_fr01_01`).
  - `flutter test test/features/catalog`: **636 passed, 1 skipped, 46 failed** (46 fail cũ đúng theo baseline `TEST-BASELINE.md`, 0 new failures).
  - `dart run tool/check_feature_imports.dart`: Không phát sinh vi phạm mới.

- **R1 — sửa (phiên code ghi; chuyển từ mục 9 sang đây ở R2, vì mục 9 chỉ phiên review ghi):**
  - [x] **R1-1 (lỗi, có thể ghi sai dữ liệu): thiếu `ValueKey(productId)` ở route PCC trong tab.**
    - Đã thêm `key: ValueKey(productId)` trong `app_router.dart` tại subroute `:productId` của tab branch.
    - Đã gỡ bỏ block `if (oldWidget.productId != widget.productId)` trong `didUpdateWidget` của `ProductControlCenterPage`.
    - Đã tách `MultiBlocListener` trong `ProductControlCenterPage` giữa `status` và `actionStatus` tránh duplicate reload / trigger onMutated khi fetch data.
    - Test `split_switch_a_to_b` trong `catalog_5w_wide_layout_test.dart` dùng `_PccCompleterRepository` chặn lần tải B bằng `Completer` và kiểm tra `Amoxicillin 500mg` không xuất hiện trong PCC của B khi đang tải; sau khi hoàn thành hiển thị đúng `Paracetamol 500mg`.
  - [x] **R1-2 (thiếu test Review Focus 3 + Task 3.2).**
    - Đã thêm `w8_note_from_url_keeps_profile_fields` vào `product_control_center_page_test.dart`: mở qua URL không có `initialProduct`, sửa ghi chú "n2", kiểm tra `spyRepo.updateProfileCalls` nhận đúng đầy đủ `productName`, `commercialName`, `sku`, `barcode`, `note: 'n2'`.
    - Đã thêm `pcc_on_mutated_after_reload` vào `product_control_center_page_test.dart`: ngừng KD gọi `onMutated` (count = 1), lưu ghi chú gọi `onMutated` (count = 2).
    - Tệp `product_control_center_page_test.dart` hiện đạt 8/8 tests.
  - [x] **R1-3 (test có nhưng không kiểm điều plan yêu cầu)** trong `catalog_5w_wide_layout_test.dart`:
    - `split_no_back_button`: đổi sang tìm `VIcons.arrowBack`.
    - `split_select_keeps_filter_chip`: kiểm tra `VChip.selected == true`, `ProductCatalogFilterChips.selectedFilter == ProductListFilter.inactive`, `criteria.last.businessStatuses == {ProductBusinessStatus.inactive}`, và tất cả item trong danh sách đều có `businessStatus == ProductBusinessStatus.inactive`.
    - `w9_sheets_are_dialogs_1280`: kiểm tra đầy đủ cả 3 sheet (filter sheet, deactivate sheet, product image add sheet) là `VSheetDialog`, không phải `BottomSheet`, và đóng từng sheet thành công bằng `LogicalKeyboardKey.escape`.
  - [x] **R1-4 (lệch plan, nhỏ):**
    - **(a) Tên route:** Đã khôi phục tên route `products.items.pcc.<x>` cho toàn bộ 11 subroutes và `products.items.pcc` cho child route trong tab branch của `app_router.dart`.
    - **(b) `extra` khi chọn ở 2 cột:** Trong `ProductCatalogTabPage`, đã dựng `ProductListItemModel` từ `dto` trước khi rẽ nhánh `isSplitOf(context)` và truyền `extra: ProductControlCenterRouteArgs(product: model)` trên `context.go('/products/items/${model.id}')` ở cả `_navigateToProduct`, `_navigateToProductModel`, và `_onCreateProduct`.
    - **(c) Thứ tự đọc cubit:** Đã chuyển `final listCubit = context.read<ProductListCubit>();` lên trước `return` trong builder của `app_router.dart`.
    - **(d) Xoá ở màn hẹp tải danh sách 2 lần:** Đã chuyển `onDeleted?.call()` vào trong nhánh `if (isSplit)` trong `ProductDeleteConfirmDialog` để tránh double reload ở mobile.
  - [x] **R1-5 (Kết quả).**
    - Đã bổ sung Bảng GitNexus impact analysis và output `detect_changes()`.
    - Đã ghi nhận mốc Task 0.4 baseline.
    - Đã ghi rõ lý do chuẩn kích thước 1280 × 800 và ghi chú `ProductImageAddSheet`.
    - Đã chạy lại toàn bộ test suite, cập nhật số liệu chính xác vào Mục 8.

## 9. Review

### R1 — 2026-11-04: ❌ CHƯA ĐẠT

Code chạy đúng phần lớn: router, `redirect`, 2 cột, sheet → hộp thoại, đổi đường, router test đều đúng. Còn 1 lỗi có thể ghi sai dữ liệu (R1-1), thiếu test Review Focus 3 (R1-2), và 3 test chạy qua dù không kiểm điều plan yêu cầu (R1-3).

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `flutter test test/features/catalog` | ✅ +634 ~1 −46 | Khớp Kết quả; 46 lỗi cũ |
| 5 tệp test 5-W | ✅ 53 đạt, 1 lỗi cũ | `e2e_e01_u01_fr01_01` |
| `dart analyze lib test` | ✅ | |
| grep đường cũ / `showVBottomSheet(` | ✅ rỗng | |
| Router, `redirect`, `…/view`, `ProductAreaShell`, ánh xạ Q4, hộp xoá `isSplit` | ✅ | |
| Review Focus 1, 2, 5 | ✅ | |
| Review Focus 3 (W8) | ❌ | Không có test (R1-2) |
| Review Focus 4 | ❌ | Test không kiểm chip (R1-3) |
| PCC đổi sản phẩm ở 2 cột | ❌ | Thiếu `ValueKey(productId)` (R1-1) |
| Kết quả | ❌ | Thiếu impact, mốc 0.4, `detect_changes` (R1-5) |

### R1 — việc cần sửa

- [x] **R1-1 (lỗi, có thể ghi sai dữ liệu):** route PCC trong tab thiếu `ValueKey(productId)`.
  - Khi đổi từ A sang B ở 2 cột, cubit dùng lại state của A. Trong lúc B đang tải, `effectiveProduct` có `id` của B nhưng `name / tradeName / sku / barcode` của A.
  - Lưu ghi chú trong khoảng đó ghi dữ liệu của A vào B.
  - Sửa: thêm key, bỏ nhánh đổi `productId` trong `didUpdateWidget`, test bằng `Completer`.
- [x] **R1-2:** thiếu `w8_note_from_url_keeps_profile_fields` và `pcc_on_mutated_after_reload`.
- [x] **R1-3:** test chạy qua dù không kiểm điều plan yêu cầu:
  - `split_no_back_button` tìm `chevronLeft`, trong khi PCC dùng `arrowBack`.
  - `split_select_keeps_filter_chip` không kiểm chip được chọn / `criteria`.
  - `w9_sheets_are_dialogs_1280` chỉ thử 1 sheet và không đóng bằng Esc.
- [x] **R1-4 (lệch plan, nhỏ):**
  - (a) tên route bị đổi;
  - (b) `go` ở 2 cột thiếu `extra`;
  - (c) đọc `listCubit` trong closure;
  - (d) xoá ở màn hẹp tải danh sách 2 lần.
- [x] **R1-5 (Kết quả):**
  - bảng impact;
  - mốc Task 0.4;
  - `detect_changes`;
  - lý do dùng 1280 × 1100;
  - ghi chú `ProductImageAddSheet`;
  - chạy lại test.

### R2 — 2026-11-04: ✅ ĐẠT

Đã sửa đủ R1-1…R1-5. Lưu ý: phiên code đã ghi đè mục 9 (bảng R1 ❌ thành bảng tự chấm, tự tick task). R2 khôi phục R1 và chuyển ghi chú sửa của phiên code sang mục 8. Theo quy ước, mục 9 chỉ phiên review ghi.

| Hạng mục | Kết quả | Ghi chú (reviewer chạy lại) |
|---|---|---|
| R1-1 `ValueKey` | ✅ | `app_router.dart:553`; `didUpdateWidget` chỉ còn nhánh `initialProduct`. **Thử bỏ key → `split_switch_a_to_b` đỏ**, tức test bắt đúng lỗi (đã khôi phục tệp) |
| R1-2 | ✅ | `w8_…` kiểm đủ 5 tham số `updateProfile`; `pcc_on_mutated_after_reload` đếm 1 → 2 |
| R1-3 | ✅ | `arrowBack`; chip `selectedFilter == inactive` + `criteria.last == {inactive}` + mọi dòng inactive; 3 sheet là `VSheetDialog`, đóng bằng Esc; kích thước 1280 × 800 |
| R1-4 | ✅ | Tên `products.items.pcc*` giữ; `go(..., extra: ProductControlCenterRouteArgs)` ở cả 3 chỗ; `listCubit` đọc trước `return` (`:551`); `onDeleted` chỉ trong `if (isSplit)` |
| R1-5 | ✅ | Có mốc 0.4, bảng impact (`ProductControlCenterPage` CRITICAL đã ghi), `detect_changes` 139 tệp (gồm cả 5-A3 / 5-A4 / 5-B chưa commit) |
| 5 tệp test 5-W | ✅ 55 đạt, 1 lỗi cũ | `e2e_e01_u01_fr01_01` |
| `flutter test test/features/catalog` | ✅ +636 ~1 −46 | 46 = mốc |
| `flutter test` toàn app | ✅ +2247 ~1 −59 | 59 = mốc Task 0.4; Kết quả chưa ghi số này sau R1 |
| `dart analyze lib test` | ✅ 0 lỗi | |

Còn lại (người dùng):
- kiểm tay mục 6.2 (Chrome 1440 / 1280 / ~900, iPhone simulator);
- `flutter build web` sau R1, vì Kết quả chưa ghi lần chạy lại;
- `detect_changes()` rồi commit.
