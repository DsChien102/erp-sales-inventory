# 5-W — Theme 2 trên web: danh sách – PCC hai cột, màn con có id trên URL, sheet thành hộp thoại

> Theme 2 (mã cũ P5) · Bố cục web (quy tắc Thiết bị 2026-10-20) · Làm **sau** [5-B](5-B-sua-ki-th02.md)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ⬜ | Review ⬜
> Dùng lại của W-2: `VListDetailLayout`, `VListDetailLayout.isSplitOf`, `VCard.isSelected`, `showVAdaptiveSheet`, `VAppBar.popNearest`. Mẫu: plan [4-W](../P4/4-W-partner-web.md) (cùng cách làm, cùng lý do thứ tự route), `apps/erp/lib/features/iam/presentation/users/users_area_shell.dart`.
> Đường dẫn tệp là đường **sau 5-A3 / 5-B** (cubit ở `features/catalog/logic/`). Số dòng "≈" đo trên code trước 5-A, chỉ để tìm chỗ.

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
| Q2 | Màn con của PCC | **Người dùng chốt 2026-11-01:** đổi đường sang có id: `/products/items/pcc/<x>` → `/products/items/:productId/<x>` (giữ nguyên đoạn `<x>` và tên route), route gốc toàn màn khai báo **trước** `ShellRoute(StoreShell)`. Thiếu `extra` (mở thẳng URL / tải lại trang) → `go('/products/items/:productId')` |
| Q3 | Cài đặt sản phẩm (nhóm / trường bổ sung, khung giá cửa hàng + lịch sử) | **Người dùng chốt 2026-11-01:** toàn màn cột 720, giữ route hiện có; chỉ đổi sheet → hộp thoại |
| Q4 | PCC mở bằng URL không có `extra` (không có `ProductListItemModel` từ danh sách) | **Đề xuất, duyệt plan là chốt:** PCC tải theo id; `extra` chỉ để hiện tên sớm. Sau khi tải xong, `product` truyền xuống thân / màn con dựng từ PCC (`CatalogUiMapper.listItemFromControlCenter`, mục 3.3). Lý do: màn ghi chú gửi lại `name / tradeName / sku / barcode` của `product` khi lưu (`product_note_edit_page.dart` `_submit`), nên `product` thiếu dữ liệu sẽ **xoá mất** các trường đó |
| Q5 | Lối "Mở sản phẩm trùng" từ màn tạo (route gốc) | **Đề xuất, duyệt plan là chốt:** thêm route gốc toàn màn `/products/items/:productId/view` (tên `products.items.view`) dựng **cùng** `ProductControlCenterPage`, khai báo trước `ShellRoute`. Màn tạo `push` route này nên "Quay lại" về đúng form đang nhập. Không `push` vào route trong tab từ route gốc (trang tab sẽ nằm **dưới** màn tạo, không thấy) |
| Q6 | Bảng (`VTable`) cho danh sách sản phẩm | **Đề xuất:** không. Cột trái hẹp; dùng thẻ như iPhone (giống 4-W Q3) |
| Q7 | Chuỗi mới | **Đề xuất (nguyên văn):** ô chi tiết trống "Chọn một sản phẩm để xem chi tiết." Không có chuỗi mới khác |

## 3. Thiết kế

### 3.1 Cây route (`apps/erp/lib/core/router/app_router.dart`)

**Hiện tại:** tab Sản phẩm = `GoRoute('/products/items', name: 'products.items', builder: ProductCatalogTabPage)` (≈ dòng 226–232). `/products/items/new`, `/products/items/pcc` và 11 route `/products/items/pcc/<x>` ở cấp gốc, **sau** `ShellRoute(StoreShell)` (≈ dòng 949–1060).

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
      └─ ShellRoute builder: ProductAreaShell
         └─ GoRoute /products/items        (products.items)     → ProductListRoute
            └─ GoRoute :productId          (products.items.pcc) → ProductControlCenterPage(key: ValueKey(productId), …)
```

- Thứ tự: như 4-W 3.1 (go_router so theo thứ tự khai báo; `/products/items/new` sẽ khớp `:productId = 'new'` nếu để sau).
- **Builder 11 màn con:** thân giữ nguyên (đọc `state.extra as XxxRouteArgs` …). Thêm ở **đầu** mỗi builder: `final extra = state.extra; if (extra is! XxxRouteArgs) return _RedirectTo('/products/items/${state.pathParameters['productId']}');` (với 3 route nhận `ProductListItemModel` thì `is! ProductListItemModel`). `_RedirectTo`: widget nhỏ khai báo cuối `app_router.dart`, chép khung redirect đang có ở `/more/product-settings/custom-fields/:groupId` (≈ dòng 1093–1101: `addPostFrameCallback` → `context.go(...)`, tạm hiện `CircularProgressIndicator`).
- **`products.items.view` (Q5):** `ProductControlCenterPage(productId: id, initialProduct: state.extra as ProductListItemModel?)` toàn màn; nút ← giữ `canPop ? pop : go('/products/items')`.
- **`products.items.pcc` (con trong tab):** `ProductControlCenterPage(key: ValueKey(productId), productId: productId, initialProduct: state.extra is ProductControlCenterRouteArgs ? (state.extra as ProductControlCenterRouteArgs).product : null, onMutated: () => context.read<ProductListCubit>().fetchProducts(isRefresh: true))`.
- `ProductListRoute` (builder `/products/items`): `isSplitOf(context)` → ô trống Q7 (chép khung ô trống của `/more/users`, như 4-W); ngược lại → `ProductCatalogTabPage(cubit: context.read<ProductListCubit>())`.
- `erp_bottom_navigation.dart`: kiểm điều kiện chọn tab Sản phẩm (`startsWith('/products')` hay khác) vẫn đúng với đường mới; không đúng thì sửa, ghi vào Kết quả.

### 3.2 `ProductAreaShell` (tạo `apps/erp/lib/features/catalog/presentation/product_area_shell.dart`)

Chép khung `PartnerAreaShell` (4-W 3.2) / `UsersAreaShell`:

- Tham số: `child`, `selectedId`, `repository` (mặc định `getIt<ProductRepository>()`), `cubit` (cho test).
- `BlocProvider(create: (_) => ProductListCubit(repository: …)..fetchProducts(criteria: ProductSearchCriteria(businessStatuses: {active, inactive})))`: **chuyển nguyên** lời tạo cubit + lời tải đầu khỏi `ProductCatalogTabPage.initState` (≈ dòng 38–46).
- `VListDetailLayout(list: ProductCatalogTabPage(cubit: c, selectedId: selectedId), detail: child)`.
- Không kiểm quyền (catalog không có cổng quyền ở client, đo 2026-11-01).

### 3.3 `ProductCatalogTabPage`, `ProductControlCenterPage`, `ProductControlCenterBody`

**`ProductCatalogTabPage`:**

- Tham số mới `ProductListCubit? cubit`, `String? selectedId`. Có `cubit` → dùng, **không** `close()` trong `dispose`; không có → tự tạo như cũ (test cũ chạy được).
- `_navigateToProductModel(model)`: `isSplitOf` → `context.go('/products/items/${model.id}', extra: ProductControlCenterRouteArgs(product: model))`; ngược lại → **giữ** `push(...)…then(fetchProducts(isRefresh: true))`, đổi đường thành `/products/items/${model.id}`.
- `_onCreateProduct`: giữ `push('/products/items/new')` + tải lại; có sản phẩm mới → `_navigateToProductModel` (đã rẽ nhánh ở trên).
- `selectedId` → `ProductCatalogListBody` → `ProductListItemTile(isSelected: item.id == selectedId)` → `VCard(isSelected: isSelected ? true : null, …)`.

**`ProductControlCenterPage`:**

- `ProductControlCenterRouteArgs` giữ. Trang đổi chữ ký: `ProductControlCenterPage({super.key, required String productId, ProductListItemModel? initialProduct, VoidCallback? onMutated})`. Mọi chỗ đang dựng `ProductControlCenterPage(product: x)` (router + test) đổi theo.
- Tải: `loadControlCenter(productId)` (thay `product.id`).
- Tiêu đề: `initialProduct?.name` khi chưa tải; tải xong → `controlCenter.profile.name`. Badge `fallbackIsSoftDeleted: initialProduct?.isSoftDeleted ?? false`.
- `product` truyền xuống `ProductControlCenterBody` (Q4): tải xong → `CatalogUiMapper.listItemFromControlCenter(controlCenter, base: initialProduct)`; chưa tải → `initialProduct ?? CatalogUiMapper.minimalFromDuplicate(productId: productId, productName: '')`.
  - **Hàm mới** `CatalogUiMapper.listItemFromControlCenter(ProductControlCenterDto cc, {ProductListItemModel? base})`: `(base ?? minimalFromDuplicate(productId: cc.profile.productId, productName: cc.profile.name)).copyWith(name, tradeName, sku, barcode, images, imageUrl, businessStatus, baseUnit: cc.units.baseUnitName, notes: cc.profile.note, stockQty: cc.stock.quantity)` (đúng như `_productFromProfile` của body + 4 trường cuối). Tên getter thật của DTO: đọc `ProductControlCenterDto` khi làm, ghi vào Kết quả.
- Nút ←: `isSplitOf` → **ẩn** (`leading: null`, `automaticallyImplyLeading: false` hoặc cách `VPageScaffold` hỗ trợ); ngược lại giữ `canPop ? pop : go('/products/items')`.
- `onMutated?.call()` sau: ngừng / kinh doanh lại thành công; quay về từ màn con trả `true` (`didChange == true` ở body: tồn, ghi chú, khung giá) và sau khi hồ sơ / ảnh / đơn vị / giá / trường đổi xong (mọi chỗ body đang `_reload(context)`); khôi phục (`onRestored`).

**`ProductControlCenterBody`** (`widgets/product_control_center_body.dart`): 11 lời `context.push('/products/items/pcc/<x>', extra: …)` → `context.push('/products/items/${product.id}/<x>', extra: …)`; `extra` giữ nguyên. Tham số `onMutated` truyền xuống từ trang, gọi cùng chỗ `_reload`.

**Xoá sản phẩm** (`product_delete_confirm_dialog.dart` ≈ dòng 45–54, đang `pop sheet; canPop ? pop(true) : go('/products/items')`): thêm tham số `VoidCallback? onDeleted` (PCC truyền `onMutated`). `isSplitOf` → toast giữ, `onDeleted?.call()`, `context.go('/products/items')`; ngược lại giữ như cũ.

**Màn tạo** (`product_guided_create_page.dart` ≈ dòng 64–73): "Mở sản phẩm trùng" → `context.push('/products/items/$productId/view', extra: CatalogUiMapper.minimalFromDuplicate(...))` (Q5).

**`readiness_checklist_page`** (6 lời push `/products/items/pcc/<x>`) và **`product_price_bands_page`** (`/products/items/pcc/price-bands/edit`): đổi đường như body (`/products/items/${product.id}/<x>`).

### 3.4 Sheet → hộp thoại

Đổi **tên hàm** `showVBottomSheet` → `showVAdaptiveSheet`, giữ tham số, ở **14 chỗ** (grep 2026-11-01 trừ `price_band_warning_ack_sheet.dart` đã xoá ở 5-A3): `pages/product_catalog_tab_page.dart:141`, `widgets/product_delete_confirm_dialog.dart:25`, `product_conversion_unit_deactivate_confirm_dialog.dart:19`, `product_conversion_unit_delete_blocked_dialog.dart:19`, `custom_field_group_deactivate_confirm_sheet.dart:19`, `product_restore_confirm_dialog.dart:29`, `unsaved_changes_confirm_sheet.dart:10`, `product_conversion_unit_delete_confirm_dialog.dart:19`, `store_price_rule_save_confirm_sheet.dart:6`, `product_lifecycle_bottom_sheets.dart:121,140`, `product_conversion_unit_reactivate_confirm_dialog.dart:19`, `custom_field_deactivate_confirm_sheet.dart:8`, `price_band_overwrite_dialog.dart:13`, cùng mọi chỗ khác `git grep "showVBottomSheet(" -- apps/erp/lib/features/catalog` tìm ra lúc làm. Ghi số chỗ thực tế vào Kết quả.

`widgets/image_picker/product_image_add_sheet.dart` (`showModalBottomSheet` thô, tự vẽ nền + tiêu đề "Thêm ảnh sản phẩm"): đổi `show` sang `showVAdaptiveSheet<ProductImageSource>(context: context, title: 'Thêm ảnh sản phẩm', child: const _ProductImageSourceOptions())`. `_ProductImageSourceOptions` = phần `Column` các lựa chọn hiện có, **bỏ** `Container` nền / bo góc và `VText` tiêu đề (sheet đã có). `pop(source)` giữ.

Giữ: `showVConfirmDialog` (`upsert_custom_field_page.dart:450`), `showDialog` (`product_image_delete_dialog.dart:8`): đã là hộp thoại.

### 3.5 Bàn phím

- Thẻ sản phẩm (`VCard` có `onTap`): Tab / Enter sẵn có, kiểm, không sửa nếu đạt.
- Hộp thoại: Esc đóng (mặc định khi `isDismissible`).
- Ô tìm kiếm danh sách: Tab vào được.

## 4. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| W1 | `ProductCatalogTabPage.initState` tạo `ProductListCubit` + `fetchProducts(active, inactive)`; `dispose` đóng | `ProductAreaShell` tạo + tải. Trang chỉ tự tạo khi không được truyền `cubit` | widget test: dựng qua router `/products/items` → `search` gọi **1** lần; rời tab rồi quay lại không gọi thêm lần dựng cubit (đếm `FakeProductRepository.calls`) |
| W2 | Chọn sản phẩm → `push('/products/items/pcc', extra)` → quay về → tải lại | hẹp: `push('/products/items/:id', extra)` + tải lại; rộng: `go` | bước 0 (390): chọn dòng → thấy PCC đúng tên; quay về → `search` gọi thêm 1 lần |
| W3 | Tạo xong → về danh sách, tải lại, mở PCC sản phẩm mới | giữ (đường mới) | bước 0 (390): tạo tối thiểu → thấy PCC sản phẩm mới |
| W4 | PCC: ngừng / kinh doanh lại → tải lại PCC + toast; quay về từ màn con có đổi → tải lại PCC | giữ + gọi `onMutated` | bước 0 (390): ngừng KD → toast; sửa ghi chú → PCC tải lại. Sau sửa thêm ở 1280: danh sách tải lại |
| W5 | Xoá: đóng sheet; `canPop ? pop(true) : go('/products/items')`; danh sách tải lại khi `push` trả về | hẹp giữ; rộng: toast + `onDeleted` + `go('/products/items')` | bước 0 (390): xoá → về danh sách, toast, danh sách tải lại. Sau sửa thêm ở 1280: ô phải về trống, danh sách tải lại |
| W6 | 11 màn con: đọc `extra`, mở đúng trang; quay về trả `bool` | đường mới có id; thân builder giữ; thiếu `extra` → về PCC của id | bước 0: mỗi màn con mở từ PCC đúng trang (11 ca). Sau sửa: thêm 11 ca mở thẳng `/products/items/p-1/<x>` không `extra` → thấy PCC `p-1` |
| W7 | Màn tạo → "Mở sản phẩm trùng" → `push` PCC (route gốc) → "Quay lại" về form, giữ dữ liệu đã nhập | `push('/products/items/:id/view')` (Q5) | bước 0 (390): nhập tên + SKU trùng → mở sản phẩm trùng → quay lại → ô tên còn chữ đã nhập |
| W8 | PCC mở từ danh sách luôn có `ProductListItemModel` đủ field; ghi chú lưu lại `name / tradeName / sku / barcode` của model | **Đổi (Q4):** `product` dựng từ PCC sau khi tải | test mới: mở thẳng `/products/items/p-1` (không `extra`) → sửa ghi chú → `updateProfile` nhận đúng `tradeName / sku / barcode` của p-1 (không `null`) |
| W9 | 14 sheet + sheet chọn nguồn ảnh = bottom sheet ở mọi bề rộng | ≥ 1024 hộp thoại; hẹp như cũ | bước 0 (390): mở sheet lọc trường bổ sung, sheet ngừng KD, sheet chọn nguồn ảnh → thấy `BottomSheet`. Sau sửa: 390 vẫn `BottomSheet`; 1280 thấy `VSheetDialog`, Esc đóng |
| W10 | PCC là route gốc toàn màn (che thanh tab trên iPhone) | **Đổi (Q1):** trong tab | test 390: mở PCC → thanh tab vẫn hiện; nút ← về danh sách |
| W11 | Chỗ khác đi tới PCC / màn con: `readiness_checklist_page` (6), `product_price_bands_page` (1), `product_control_center_body` (11), `product_guided_create_page` (1), `product_catalog_tab_page` (2) | đổi đường | `git grep -n "/products/items/pcc" -- apps/erp/lib apps/erp/test` → rỗng (route name `products.items.pcc*` giữ) |

**Bước 0** viết W2–W7, W9 trên code **sau 5-B, trước 5-W**, dựng qua `appRouter` thật + fake catalog (`registerFakeCatalog` của 5-A3; mẫu dựng router: `test/features/iam/presentation_module/w2_behavior_preservation_test.dart`), bề rộng 390 × 844. Chạy xanh, ghi tên test.

## 5. Các bước

Trước mỗi symbol sửa: `gitnexus impact` (upstream), ghi vào Kết quả; HIGH / CRITICAL thì dừng, ghi lại. `app_router.dart`, `ProductControlCenterPage` gần như chắc HIGH: ghi blast radius, làm tiếp vì đã có W2–W11.

0. Bước 0 (mục 4).
1. `CatalogUiMapper.listItemFromControlCenter` + test đơn vị (đủ field).
2. `ProductAreaShell` (3.2); `ProductCatalogTabPage` (3.3); `ProductCatalogListBody` / `ProductListItemTile`: `selectedId` / `isSelected`.
3. `ProductControlCenterPage`, `ProductControlCenterBody`, `product_delete_confirm_dialog.dart`, `product_guided_create_page.dart`, `product_readiness_checklist_page.dart`, `product_price_bands_page.dart` (3.3).
4. Router (3.1), kể cả `_RedirectTo` và `products.items.view`.
5. Sheet (3.4).
6. Test mới ở 1280 × 800: 2 cột; chọn dòng đổi URL + `isSelected`; mở thẳng `/products/items/p-1` thấy 2 cột, dòng p-1 chọn; đổi A → B hiện đúng B (`ValueKey`); ô trống ở `/products/items`; nút ← ẩn ở PCC; W4, W5, W9 ở 1280; W6 mở thẳng màn con; W8.
7. Kiểm mục 6, ghi Kết quả, `detect_changes()`.

## 6. Kiểm tra

### 6.1 Tự động

- [ ] Mọi test bước 0 xanh, **không đổi điều kiện kiểm** (chỉ đổi cách dựng / đường dẫn). Riêng W8, W10 là đổi có chủ đích.
- [ ] Test mới bước 6 xanh.
- [ ] `git grep -n "showVBottomSheet(\|showModalBottomSheet(" -- apps/erp/lib/features/catalog` → rỗng.
- [ ] `git grep -n "/products/items/pcc" -- apps/erp/lib apps/erp/test` → rỗng.
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi mới. `flutter test`: không fail mới so với sau 5-B.
- [ ] `cd apps/erp && flutter build web` chạy qua.

### 6.2 Kiểm tay (người dùng)

- [ ] Chrome 1440 × 900 và 1280 × 800: 2 cột; chọn dòng; tạo; mở sản phẩm trùng từ màn tạo rồi quay lại form; sửa hồ sơ / ảnh (tải ảnh lên được trên web) / ghi chú / đơn vị / giá / khung giá; ngừng / kinh doanh lại; xoá; chip "Đã xóa" → khôi phục; tải lại trang ở `/products/items/<id>` và `/products/items/<id>/note` (về PCC) vẫn đúng.
- [ ] Chrome hẹp (~900): một cột như iPhone.
- [ ] Cài đặt sản phẩm trên Chrome rộng: toàn màn cột 720; hộp thoại thay sheet.
- [ ] Bàn phím: Tab qua ô tìm → thẻ → Enter mở PCC; Esc đóng hộp thoại.
- [ ] iPhone simulator: như cũ, trừ thanh tab vẫn hiện khi xem PCC (Q1).

## 7. Rủi ro / lưu ý

- **Thứ tự route** dễ vỡ nhất (như 4-W). W6 mở thẳng URL qua router thật là để bắt lỗi này.
- `ValueKey(productId)` thiếu thì đổi sản phẩm ở 2 cột vẫn hiện PCC cũ.
- Q4 là chỗ dễ gây mất dữ liệu: W8 bắt buộc. Kiểm thêm các màn con khác dùng `product` để **gửi** dữ liệu (không chỉ hiện): grep `widget.product.` / `args.product.` trong `presentation/pages/` và ghi vào Kết quả từng chỗ, nguồn dữ liệu sau Q4.
- Màn SP-10 (tồn) vẫn qua module (5-A3 Q9): chỉ đổi đường, không đổi thân.
- Tải ảnh trên web: `product_image_upload_client.dart` có nhánh `kIsWeb`; `catalog_storage_image.dart`, `product_image_grid_item.dart`, `product_image_gallery_viewer.dart` import `dart:io` nhưng đã chặn bằng `kIsWeb`. `flutter build web` + kiểm tay là chốt; lỗi thì ghi vào Kết quả, **không** tự sửa ngoài phạm vi.

## 8. Kết quả (phiên làm code ghi)

> Xong **mỗi bước** ghi ngay. Mẫu: trạng thái ✅ / 🔄 dở / ⏭ (lý do) · tệp:dòng · lệch plan + lý do · test thêm / sửa · impact · ghi chú cho review. Bước cuối: lệnh, số pass / fail, fail đối chiếu `TEST-BASELINE.md`, `detect_changes()`.

## 9. Review

<!-- Phiên review ghi -->
