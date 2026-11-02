# 5-A3 — Đổi toàn bộ UI catalog (+ sales, pricing) sang repository, câu lỗi theo TH-02 6.4, chép fake

> Theme 2 (mã cũ P5) · Bước (a) chuyển kiến trúc, phần **nối UI** · Gồm việc 5.1–5.4 (phần UI) (PLAN.md mục Theme 2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ⬜ | Review ⬜
> Làm **sau** [5-A1](5-A1-catalog-data-san-pham.md) và [5-A2](5-A2-catalog-data-don-vi-truong-gia.md): dùng 4 repository, model, `catalogErrorMessage`, `CatalogErrorCodes` đã có.
> Tài liệu: [PLAN.md](../../PLAN.md) "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ"; [TH-02](../../../02-yeu-cau/TH-02-san-pham-va-gia-ban.md) mục 6.4, KI-07, KI-16.

## 1. Mục tiêu

```text
Page ─▶ Cubit (features/catalog/logic) ─▶ ProductRepository / MeasurementUnitRepository /
                                          CustomFieldRepository / ProductPriceRepository ─▶ SupabaseRpc
```

Sau 5-A3:

- `apps/erp/lib` chỉ còn **một** chỗ gọi module catalog: màn điều chỉnh tồn SP-10 (`product_stock_adjustment_page.dart`) và đăng ký `ICatalogModule` trong DI cho nó (5-C xoá sau Theme 7). Mọi tệp khác hết `import 'package:vet45_catalog_…'`, kể cả sales, pricing, router.
- 15 cubit + state chuyển `presentation/bloc/` → `logic/`.
- Chuỗi lỗi kỹ thuật (`e.toString()`, `error.message` thô, câu tiếng Anh của module) đổi sang `catalogErrorMessage` (KI-07 phần catalog). Mã đã có câu riêng giữ nguyên câu.
- Bỏ sheet "Xác nhận cảnh báo giá" (KI-16 phần sheet, Q6 của 5-A2).
- Test dùng `FakeCatalogBackend` + 4 fake repository (chép từ `FakeCatalogModule`), màn SP-10 dùng `FakeStockCatalogModule` chung dữ liệu.

Giao diện iPhone không đổi, **trừ** câu lỗi (mục 5) và bỏ sheet cảnh báo giá.

## 2. Quyết định

5-A1 mục 2 (Q1–Q5, Q11), 5-A2 mục 2 (Q6, Q7). Thêm:

| # | Câu hỏi | Chốt |
|---|---|---|
| Q8 | Câu mặc định khi mã lỗi không có câu riêng | Chỗ cũ đã có câu cố định cho nhánh "lỗi khác" → dùng câu đó làm `fallback`. Chỗ cũ hiện `e.toString()` → `fallback` mặc định của `catalogErrorMessage`: "Đã xảy ra lỗi. Vui lòng thử lại." (TH-02 6.4 dòng cuối). **Đề xuất của plan; duyệt plan là chốt** |
| Q9 | SP-10 (`product_stock_adjustment_page.dart`) | **Không đổi gì** trong tệp (PLAN 2026-10-14, chốt Q5 của 5-A1). Nó vẫn `GetIt.instance<ICatalogModule>()`; câu lỗi thô của nó (KI-07 phần tồn) để Theme 7 thay |
| Q10 | Preview `apps/erp/example` | Không có preview catalog (đo 2026-11-01: `example/lib/` chỉ có `dashboard`, `partner`, `sales`). Không làm gì |

## 3. Hiện trạng (đo 2026-11-01)

- 80 tệp trong `apps/erp/lib` import `vet45_catalog_*` / `vet45_inventory_*` (`git grep -l "package:vet45_\(catalog\|inventory\)" -- apps/erp/lib`). Trong đó 5-A3 lo **77** tệp catalog; 2 tệp `dashboard/` (inventory) là việc của 5-A4; `product_stock_adjustment_page.dart` giữ.
- 28 tệp `presentation/bloc/` (15 cubit, 13 state; `product_images_maintenance_cubit.dart`, `product_profile_maintenance_cubit.dart` để state cùng tệp cubit: giữ nguyên cấu trúc).
- Trang lấy module bằng `GetIt.instance<ICatalogModule>()` + `GetIt.instance<IExecutionContext>()` ngay trong trang (không qua router): `edit_product_unit_price_band_page.dart:40`, `product_catalog_tab_page.dart:41,60`, `product_change_history_page.dart:27`, `product_control_center_page.dart:31`, `product_custom_field_group_edit_page.dart:37`, `product_guided_create_page.dart:18`, `product_images_maintenance_page.dart:25`, `product_manual_base_price_page.dart:36`, `product_measurement_units_page.dart:32`, `product_note_edit_page.dart:65`, `product_price_bands_page.dart:36`, `product_profile_maintenance_page.dart:25`, `settings/custom_field_groups_page.dart:24`, `settings/edit_store_price_rule_page.dart:130`, `settings/store_price_rule_change_history_page.dart:19`, `settings/store_price_rule_settings_page.dart:17`, `widgets/product_control_center_body.dart:146,157`.
- `core/router/app_router.dart` chỉ import kiểu (`ProductChangeHistoryPage` bị `hide`, `StorePriceRuleDto` cho `extra`). `core/di/injection.dart:155–162`: `CatalogStartup.initialize` + `ICatalogModule`.
- Test: 28 tệp dùng `FakeCatalogModule` / `FakeCatalogScenario` / `ICatalogModule` (danh sách mục 7.3). Fake gốc `modules/catalog/application/lib/src/testing/fake_catalog_module.dart` (3.831 dòng) + `fake_catalog_custom_field_store.dart`, `fake_catalog_product_builder.dart`, `fake_catalog_scenario.dart` (149 kịch bản), `fake_product_readiness_builder.dart`.

## 4. Thiết kế

### 4.1 Cubit → `features/catalog/logic/`

`git mv` 28 tệp `features/catalog/presentation/bloc/*.dart` → `features/catalog/logic/` (giữ tên). Trong mỗi cubit:

- Constructor: bỏ `ICatalogModule` (tên tham số `catalogModule` / `moduleMediator` / `mediator`) và `IExecutionContext`; thêm repository cần dùng (bảng dưới), `required`.
- Bỏ mọi `requireTenantId()` / `requireUserId()`.
- `executeQueryAsync(X(...))` / `executeCommandAsync(X(...))` → method ở cột 3, **cùng giá trị tham số** (bỏ `tenantId` / `actorId`).
- Bắt lỗi theo bảng mục 5.

| Cubit | Repository | Lời gọi cũ → mới |
|---|---|---|
| `ProductListCubit` | `ProductRepository` | `SearchProductsQuery` → `search` |
| `ProductControlCenterCubit` | `ProductRepository` | `GetProductControlCenterQuery` → `getControlCenter`; `GetProductReadinessQuery` → `getReadiness`; `Deactivate/ReactivateProductCommand` → `deactivate` / `reactivate` |
| `ProductChangeHistoryCubit` | `ProductRepository` | → `getChangeHistory` |
| `ProductSoftDeleteCubit` | `ProductRepository` | → `checkDeletionEligibility`, `delete`, `restore` |
| `ProductProfileMaintenanceCubit` | `ProductRepository` | → `updateProfile` |
| `ProductImagesMaintenanceCubit` | `ProductRepository` | → `requestMaintenanceImageUpload`, `updateImages` |
| `ProductGuidedCreateCubit` | `ProductRepository`, `CustomFieldRepository`, `MeasurementUnitRepository`, `ProductPriceRepository` | `ListCustomFieldConfigQuery` → `customFields.listConfig`; `ListTenantMeasurementUnitsQuery(limit: 50)` → `units.listTenantUnits(limit: 50)`; `CheckDuplicateProductCodeQuery` → `products.checkDuplicateCodes`; `RequestProductImageUploadCommand` → `products.requestImageUpload`; `GetStorePriceRuleQuery` → `prices.getStorePriceRule`; `CreateGuidedProductCommand(...)` → `products.createGuided(CreateGuidedProductInput(...))` cùng field |
| `ProductMeasurementUnitsCubit` | `MeasurementUnitRepository` | 7 lời gọi → 7 method cùng tên ý nghĩa (5-A2 mục 3.2) |
| `CustomFieldConfigCubit` | `CustomFieldRepository` | 7 lời gọi → 7 method; `result.fieldId` → `(await upsertField(...)).fieldId` |
| `ProductCustomFieldGroupEditCubit` | `CustomFieldRepository` | → `getProductValues`, `upsertProductValues` |
| `ProductManualBasePriceCubit` | `ProductPriceRepository` | → `setManualBasePrice` |
| `ProductPriceBandsCubit` | `ProductPriceRepository` | → `listUnitPriceBands` |
| `EditProductUnitPriceBandCubit` | `ProductPriceRepository` | → `suggestUnitPrice`, `applyStorePriceRule`, `setUnitPriceBand`. **Bỏ** tham số `confirmAcknowledgeWarnings` của `submit` (Q6) |
| `StorePriceRuleSettingsCubit` | `ProductPriceRepository` | → `getStorePriceRule`; `SetStorePriceRuleCommand` → `setStorePriceRule` (trả thẳng `StorePriceRuleDto`; `result.rule` → kết quả) |
| `StorePriceRuleChangeHistoryCubit` | `ProductPriceRepository` | → `getStorePriceRuleHistory` |

### 4.2 Trang, widget, mapper

- Mọi chỗ ở mục 3 (đoạn 3) tạo cubit bằng `GetIt.instance<XRepository>()` thay module + context. Hai trang tự gọi module:
  - `product_catalog_tab_page.dart` `_loadFilterOptions`: → `GetIt.instance<ProductRepository>().listCustomFieldFilterOptions()`; `catch (_)` bỏ qua: **giữ**.
  - `product_note_edit_page.dart` `_submit`: → `GetIt.instance<ProductRepository>().updateProfile(productId:, expectedVersion: null, productName: product.name, commercialName: product.tradeName, sku: product.sku, barcode: product.barcode, note: …)` (cùng giá trị như command cũ). Bắt lỗi theo H8.
- Mọi tệp chỉ import module để lấy kiểu → đổi sang `features/catalog/data/models/…`, `logic/catalog_permissions.dart`, `logic/store_price_suggestion.dart`. Danh sách: `git grep -l "package:vet45_catalog" -- apps/erp/lib ':!apps/erp/lib/features/catalog/presentation/pages/product_stock_adjustment_page.dart'`. Ghi số tệp thực tế vào Kết quả.
- `presentation.dart`: sửa đường export của 15 cubit / state sang `logic/`.
- `presentation/models/product_business_status.dart` đang `export 'package:vet45_catalog_domain/domain.dart' show ProductBusinessStatus;` và gắn extension `label` lên kiểu module: đổi `import` / `export` sang `data/models/catalog_enums.dart`, giữ extension. (Ở 5-A1, `ProductBusinessStatus` là **class** có hằng `active` / `inactive` / `softDeleted`, getter `isActive` …, `toWire`: chép đúng dạng class, không đổi thành `enum`.)
- **Bỏ (Q6):** `widgets/price_band_warning_ack_sheet.dart` (xoá tệp), export của nó, nhánh `if (state.error == 'WARNING_REQUIRE_ACK')` ở `edit_product_unit_price_band_page.dart:74` (≈ khối gọi `showPriceBandWarningAckSheet` và `submit(confirmAcknowledgeWarnings: true)`), tham số `confirmAcknowledgeWarnings` ở lời gọi `submit` của trang.
- `ProductChangeHistoryPage` trùng tên giữa model và trang: ở tệp dùng cả hai, import model với `as models` hoặc `hide` (giống `app_router.dart:6` hiện `hide` bản module).

### 4.3 Sales, pricing

| Tệp | Đổi |
|---|---|
| `sales/presentation/lookups/sales_catalog_product_lookup.dart` | `di<ICatalogModule>().executeQueryAsync(SearchSellableProductsQuery(...))` → `di<ProductRepository>().searchSellable(storeId:, keyword: query.trim(), limit: limit, offset: 0)`; tương tự `resolveSellableBarcode`, `listSellableUnits`. `_scope` chỉ còn lấy `storeId` (`di<SessionController>().requireActiveStoreId()`); bỏ `IExecutionContext`. `_searchFailureMessage(error)` → `catalogErrorMessage(error, fallback: 'Không thể tải sản phẩm. Vui lòng thử lại.')` (H18). Hai câu cố định của barcode / đơn vị: giữ |
| `sales/presentation/orchestration/sales_draft_backend.dart:303` | → `di<ProductRepository>().resolveSellable(storeId:, productIds: requested)`; `on Object` → `failed: true`: giữ. `tenantId` của hàm vẫn dùng cho phần sales khác: **không** đụng |
| `sales/presentation/support/sales_external_lookups.dart:52` | chú thích `[ICatalogModule]` → `ProductRepository` |
| `pricing/presentation/pages/pricing_pick_product_page.dart:65–70` | → `GetIt.instance<ProductRepository>().search(criteria: ProductSearchCriteria(keyword: …), limit: 30)`; bỏ `IExecutionContext`. Câu lỗi giữ |
| `pricing/presentation/pages/pricing_pick_unit_page.dart:50–80` | → `GetIt.instance<MeasurementUnitRepository>().listProductUnits(productId)` + `GetIt.instance<ProductPriceRepository>().getPriceBandSnapshot([...])`. Câu lỗi giữ |

### 4.4 DI (`core/di/injection.dart`)

Đăng ký cạnh `PartnerRepository` (sau khi có `sessionStore`):

```dart
..registerLazySingleton<ProductRepository>(() => ProductRepository(
      rpc: getIt<SupabaseRpc>(),
      tenantId: <cùng hàm tenantId của PartnerRepository>,
      actorId: () async => sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      hasPermission: (code) => getIt<SessionController>().hasPermission(code),
      // 5-A1 Q11: ký URL tải ảnh. `supabaseModule` là tham số của `initDependencies` (`injection.dart:37`, đang dùng ở `:58`);
      // `catalogProductImagesBucket` ở `features/catalog/presentation/services/product_image_display_resolver.dart:4`.
      signUploadUrl: (key) async => (await supabaseModule.client.storage
              .from(catalogProductImagesBucket)
              .createSignedUploadUrl(key))
          .signedUrl,
    ))
..registerLazySingleton<MeasurementUnitRepository>(...)
..registerLazySingleton<CustomFieldRepository>(...)
..registerLazySingleton<ProductPriceRepository>(...)
```

`hasPermission` gọi `getIt<SessionController>()` **lúc chạy** (lambda), không lúc đăng ký. **Giữ** `CatalogStartup.initialize` + `registerSingleton<ICatalogModule>` (SP-10, Q9). Thêm chú thích một dòng: `// Chỉ màn điều chỉnh tồn SP-10 còn dùng; 5-C xoá sau Theme 7.`

### 4.5 Router

`app_router.dart`: chỉ đổi import (`StorePriceRuleDto` từ `data/models/store_price_rule.dart`; bỏ `import 'package:vet45_catalog_application/…' hide ProductChangeHistoryPage`). Không đổi route (5-W đổi).

### 4.6 Fake (`apps/erp/test/features/catalog/support/`)

| Tệp mới | Chép từ | Ghi chú |
|---|---|---|
| `fake_catalog_scenario.dart` | `fake_catalog_scenario.dart` | cùng tên lớp `FakeCatalogScenario`, cùng 149 hằng, cùng chuỗi |
| `fake_catalog_backend.dart` | `fake_catalog_module.dart` + `fake_catalog_custom_field_store.dart` + `fake_catalog_product_builder.dart` + `fake_product_readiness_builder.dart` | `class FakeCatalogBackend` giữ **toàn bộ** trạng thái (`_TenantUnit`, `_ProductUnit`, `_StoredProduct`, …) và dữ liệu mẫu. Mỗi nhánh `if (command is X)` / `if (query is X)` thành một method public `handleX(...)` nhận đúng tham số của method repository tương ứng, trả kiểu app. `throw XxxException(...)` của module → `throw AppException(<mã CatalogErrorCodes tương ứng>, serverMessage:…, details:…)` theo **cùng** bảng tương ứng của test H3 ở 5-A1. `ValidationException(m)` → `AppException(AppErrorCode.validation, serverMessage: m)`; `ApplicationException(m)` → qua `catalogException(AppException(AppErrorCode.unknown, serverMessage: m))` (để `'Product not found'` ra `PRODUCT_NOT_FOUND` như đường thật) |
| `fake_catalog_repositories.dart` | — | `FakeProductRepository extends ProductRepository`, `FakeMeasurementUnitRepository`, `FakeCustomFieldRepository`, `FakeProductPriceRepository`: override **mọi** method public, gọi `backend.handleX`. Constructor `({required FakeCatalogBackend backend})`, `super(rpc: _unusedRpc, tenantId: () async => 'tenant-1', actorId: () async => 'user-1', hasPermission: backend.hasPermission)`. Mỗi fake có `final calls = <String>[]` |
| `fake_stock_catalog_module.dart` | 2 nhánh `SetBasicStockQuantityBaseCommand`, `AdjustBasicStockCommand` của `FakeCatalogModule` | `class FakeStockCatalogModule implements ICatalogModule` trên **cùng** `FakeCatalogBackend` (sửa tồn trong `_StoredProduct` của backend). Giữ kiểu exception **của module** mà nhánh gốc ném (màn SP-10 chưa đổi, vẫn bắt kiểu module). Mọi command / query khác → `throw UnimplementedError('${x.runtimeType}: dùng fake repository')` |
| `catalog_test_registry.dart` | — | `void registerFakeCatalog(GetIt getIt, {String scenario = FakeCatalogScenario.guidedCreateOk, Set<String>? permissions})`: tạo một `FakeCatalogBackend`, đăng ký 4 fake repository + `FakeStockCatalogModule` (là `ICatalogModule`). Thay mọi chỗ test đang `registerSingleton<ICatalogModule>(FakeCatalogModule(...))` |

Cờ quyền: `FakeCatalogModule` nhận `IPermissionChecker?`; bản mới nhận `Set<String>? permissions` (null = đủ quyền) và `backend.hasPermission(code)`. Test đang truyền permission checker giả → đổi sang tập mã tương ứng.

`FakeCatalogModule` gốc **không** sửa, không xoá (5-C xoá cùng module). Sau 5-A3 không test nào của app còn dùng nó.

## 5. Đang làm gì — test giữ hành vi

Dòng "**Đổi (Q8)**" / "**Đổi (Q6)**": bước 0 ghi hành vi cũ, sửa kỳ vọng cùng commit đổi code, ghi rõ trong Kết quả.

| # | Cơ chế cũ đang làm gì (tệp) | Sau khi sửa | Test giữ hành vi |
|---|---|---|---|
| H1 | `ProductListCubit`: phân trang, đếm theo nhóm khi danh sách không lọc (`isUnfilteredCatalogList`), đếm còn / hết hàng ở client trên các trang đã tải, giữ tiêu chí; lỗi → `ProductListError(e.toString())` | giữ; **Đổi (Q8):** lỗi → `ProductListError(catalogErrorMessage(e))` | `test/features/catalog/logic/product_list_cubit_test.dart` (mới ở bước 0): trang 1 + trang 2, số đếm khi không lọc, lọc trạng thái gửi đúng `businessStatuses`, lỗi `PermissionDenied` → câu thiếu quyền |
| H2 | `ProductCatalogTabPage._loadFilterOptions`: lỗi bỏ qua; mở sheet lọc trường bổ sung | giữ | `product_catalog_tab_page_test.dart` hiện có; bước 0 thêm: lỗi tải bộ lọc → trang vẫn hiện danh sách |
| H3 | `ProductControlCenterCubit.loadControlCenter`: lỗi → `failure` + `errorMessage: e.toString()`. `loadReadiness`: lỗi → `errorMessage: e.toString()`. `deactivateProduct`: `ProductBusinessStatusWarningsRequireAcknowledgmentException` → `actionStatus: warning`, `actionWarnings: e.warnings`; lỗi khác → `failure` + `e.toString()`; thành công → tải lại PCC. `reactivateProduct` tương tự (không có nhánh cảnh báo) | `BUSINESS_STATUS_WARNINGS_REQUIRE_ACK` → `actionWarnings` = `details['warnings']` đổi sang `ProductBusinessStatusWarningDto(code, message)`. **Đổi (Q8):** mọi `e.toString()` → `catalogErrorMessage(e)` | `test/features/catalog/logic/product_control_center_cubit_test.dart` (chuyển từ `presentation_module/`): thêm ca cảnh báo (2 cảnh báo đúng code / message), ca `stale_product_version` → "Sản phẩm đã được cập nhật ở nơi khác. Vui lòng tải lại.", ca tải lỗi `product not found` → "Sản phẩm không tồn tại hoặc đã bị xoá." |
| H4 | `ProductChangeHistoryCubit`: `ApplicationException` → `e.message`; khác → "Đã xảy ra lỗi không xác định"; nối trang, `hasReachedMax = items.length < _limit` | giữ phân trang. **Đổi (Q8):** `AppException` → `catalogErrorMessage(e, fallback: 'Đã xảy ra lỗi không xác định')`; khác → câu đó | `product_change_history_page_test.dart` hiện có + bước 0 thêm cubit test: 2 trang, lỗi |
| H5 | `ProductSoftDeleteCubit`: kiểm điều kiện lỗi → "Không thể kiểm tra điều kiện xóa sản phẩm."; xoá lỗi → "Không thể xóa sản phẩm."; khôi phục: `DuplicateSkuException` → "SKU đã được sử dụng bởi sản phẩm khác.", `DuplicateBarcodeException` → "Mã vạch đã được sử dụng bởi sản phẩm khác.", khác → "Không thể khôi phục sản phẩm." | giữ nguyên **mọi** câu; điều kiện theo `code` (`DUPLICATE_SKU`, `DUPLICATE_BARCODE`) | `product_soft_delete_e2e_test.dart` hiện có; bước 0 thêm cubit test 5 ca trên |
| H6 | `ProductProfileMaintenanceCubit.submit`: `DuplicateSku` → `skuError: 'Mã SKU đã được sử dụng'`; `DuplicateBarcode` → `barcodeError: 'Mã vạch đã được sử dụng'`; `ValidationException` / `ApplicationException` → `errorMessage: e.message`; khác → "Đã xảy ra lỗi không xác định. Vui lòng thử lại." | 2 mã trùng giữ câu. **Đổi (Q8):** `AppException` khác → `catalogErrorMessage(e, fallback: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.')` (`VALIDATION_ERROR` vẫn ra `serverMessage` như cũ) | `product_profile_maintenance_e2e_test.dart` + bước 0 thêm: trùng SKU, trùng barcode, `stale_product_version`, `product is soft-deleted …` |
| H7 | `ProductImagesMaintenanceCubit`: chọn ảnh lỗi → "Không mở được trình chọn ảnh."; xin slot / tải lên: `Validation` / `ApplicationException` → `e.message`, khác → "Lỗi tải ảnh"; lưu: `Validation` / `Application` → `e.message`, khác → "Đã xảy ra lỗi không xác định. Vui lòng thử lại." | câu chọn ảnh giữ. **Đổi (Q8):** xin slot → `catalogErrorMessage(e, fallback: 'Lỗi tải ảnh')`; lưu → `catalogErrorMessage(e, fallback: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.')` | bước 0 cubit test: slot lỗi validation (câu server), tải lên lỗi mạng (`Lỗi tải ảnh`), lưu 2 ảnh chính → câu rule |
| H8 | `ProductNoteEditPage._submit`: lỗi → toast "Lỗi" + `e.toString()`; thành công → toast "Đã lưu ghi chú sản phẩm" + `pop(true)` | **Đổi (Q8):** toast `catalogErrorMessage(e)` | widget test mới ở bước 0: lưu thành công (toast + pop true), lỗi (toast) |
| H9 | `ProductGuidedCreateCubit`: tải nhóm trường / đơn vị lỗi → tắt cờ đang tải, im lặng; `checkDuplicateCodes` lỗi → im lặng; xin slot ảnh: `Validation` / `Application` → ảnh `failed` + `e.message`, khác → "Upload ảnh thất bại."; `loadStorePriceRule` lỗi → `storePriceRuleUnavailableReason: e.toString()`; `submit`: 7 bước kiểm client (tên, tồn, giá, ảnh đang tải, trùng mã, khung giá, trường bắt buộc) rồi tạo; `DuplicateSku` → bước 0, `skuError: 'SKU "<sku>" đã được sử dụng'`, `duplicateProductId/Name` từ exception; `DuplicateBarcode` tương tự; `ValidationException` → bước 0 + `showValidationErrors` + `e.message`; `ApplicationException` → `e.message`; khác → "Lỗi hệ thống khi tạo sản phẩm."; thành công → `createdProduct` dựng từ `readinessSummary` | 7 bước kiểm giữ nguyên. `DUPLICATE_SKU` / `DUPLICATE_BARCODE` → cùng câu, giá trị lấy `details['value']`, `duplicateProductId/Name` lấy `details['existing_product_id']` / `['existing_product_name']` (đường thật không có → `null`, như cũ; fake có thể đặt). `VALIDATION_ERROR` → nhánh cũ của `ValidationException` (`serverMessage`). **Đổi (Q8):** xin slot → `catalogErrorMessage(e, fallback: 'Upload ảnh thất bại.')`; `loadStorePriceRule` → `catalogErrorMessage(e)`; `AppException` khác khi tạo → `catalogErrorMessage(e, fallback: 'Lỗi hệ thống khi tạo sản phẩm.')` | `product_guided_create_e2e_test.dart`, `product_guided_create_page_test.dart` hiện có; bước 0 thêm cubit test: trùng SKU từ server (bước 0, câu, id trùng), validation server, lỗi lạ |
| H10 | `ProductMeasurementUnitsCubit`: tải đơn vị tổ chức lỗi → `e.toString()`; tải đơn vị sản phẩm lỗi → im lặng; đặt cơ sở / thêm / tắt → `e.toString()`; bật lại → `ApplicationException ? message : toString`; xoá: `ProductConversionUnitDeleteBlockedException` → `failure` + `e.message` + `deleteBlockedUnitId`; khác như bật lại | `CONVERSION_UNIT_DELETE_BLOCKED` → `errorMessage: e.serverMessage` + `deleteBlockedUnitId`. **Đổi (Q8):** các chỗ còn lại → `catalogErrorMessage(e)` | `product_measurement_units_e2e_test.dart` hiện có; bước 0 thêm cubit test: xoá bị chặn (lý do server, `deleteBlockedUnitId`), thêm trùng tên → `Đơn vị "hộp" đã có trong sản phẩm.` sau đổi |
| H11 | `CustomFieldConfigCubit`: mọi lỗi → `error: e.toString()`; `upsertField` xong → `configureAttributes(fieldId ?? result.fieldId)` → tải lại | giữ luồng. **Đổi (Q8):** `catalogErrorMessage(e)` | `product_custom_field_config_e2e_test.dart` hiện có; bước 0 thêm: tạo trường mới → `configureAttributes` nhận id mới; trùng tên nhóm → câu |
| H12 | `ProductCustomFieldGroupEditCubit`: tải lỗi → `Loaded` với nhóm rỗng; lưu: `CustomFieldValueValidationException` → `fieldErrors {fieldId: message}`; `ApplicationException` → `e.message`; khác → "Đã có lỗi xảy ra. Vui lòng thử lại." | `CUSTOM_FIELD_VALUE_VALIDATION` → `fieldErrors` từ `details['errors']` (`field_id` → `message`). **Đổi (Q8):** `AppException` khác → `catalogErrorMessage(e, fallback: 'Đã có lỗi xảy ra. Vui lòng thử lại.')` | `product_custom_field_values_e2e_test.dart`; bước 0 thêm cubit test lỗi theo ô (2 ô) |
| H13 | `ProductManualBasePriceCubit`: lỗi → `e.toString()` | **Đổi (Q8):** `catalogErrorMessage(e)` | `product_manual_base_price_e2e_test.dart`; bước 0 thêm: giá âm → câu rule; thiếu đơn vị cơ sở |
| H14 | `ProductPriceBandsCubit`: `MissingBaseUnitException` → `ProductPriceBandsMissingBaseUnit`; khác → `Failure(e.toString())` | `MISSING_BASE_UNIT` → `MissingBaseUnit`. **Đổi (Q8):** khác → `catalogErrorMessage(e)` | `product_price_bands_e2e_test.dart`; bước 0 thêm ca thiếu đơn vị cơ sở |
| H15 | `EditProductUnitPriceBandCubit`: tải gợi ý lỗi → gợi ý rỗng "Không thể tải gợi ý giá."; lưu: `PriceBandOverwriteRequiredException` → `NeedsOverwriteConfirm(existingListAfterVat, existingFloorAfterVat)`; `PriceBandWarningsRequireAcknowledgmentException` → `error: 'WARNING_REQUIRE_ACK'` → trang mở sheet → `submit(confirmAcknowledgeWarnings: true)`; khác → `e.toString()` | `PRICE_BAND_OVERWRITE_REQUIRED` → `NeedsOverwriteConfirm` với `details['existing_list_after_vat']` / `['existing_floor_after_vat']` (đường thật `null` như cũ). **Đổi (Q6):** bỏ nhánh cảnh báo + sheet. **Đổi (Q8):** khác → `catalogErrorMessage(e)` | `edit_product_unit_price_band_e2e_test.dart`, `edit_product_unit_price_band_cubit_test.dart` hiện có. Bước 0 thêm: ghi đè → hộp ghi đè; ca cảnh báo (ghi hành vi cũ, **xoá** ca này cùng commit Q6 và ghi vào Kết quả) |
| H16 | `StorePriceRuleSettingsCubit`: tải / lưu lỗi → `StorePriceRuleSettingsError(message: e.toString())`; lưu xong → `Loaded(rule: result.rule)` | **Đổi (Q8):** `catalogErrorMessage(e)`; lưu xong → `Loaded(rule: <kết quả>)` | `product_store_price_rule_e2e_test.dart`; bước 0 thêm: tỷ lệ sàn > niêm yết → câu rule |
| H17 | `StorePriceRuleChangeHistoryCubit`: lỗi → `e.toString()`; tải thêm nối danh sách | **Đổi (Q8):** `catalogErrorMessage(e)` | `store_price_rule_change_history_wgt_test.dart`, `…_e2e_test.dart` |
| H18 | `SalesCatalogProductLookup`: `_search` lỗi → `SalesExternalOperationException(_searchFailureMessage(error))` (message thô / `toString`); barcode / đơn vị lỗi → 2 câu cố định; `currencyCode == null` → "Sản phẩm không có thông tin tiền tệ hợp lệ."; map VM | giữ. **Đổi (Q8):** `_search` → `catalogErrorMessage(error, fallback: 'Không thể tải sản phẩm. Vui lòng thử lại.')` | `sales_catalog_product_lookup_test.dart` hiện có (đổi cách dựng: `registerFakeCatalog`); bước 0 thêm: search lỗi thiếu quyền → câu |
| H19 | `sales_draft_backend` `_resolveCatalog`: id trống / trùng bỏ; lỗi → `failed: true` | giữ | `sales_draft_backend_test.dart` hiện có |
| H20 | `pricing_pick_product_page` / `pricing_pick_unit_page`: tải (limit 30; đơn vị đang hoạt động + snapshot); lỗi → 2 câu cố định | giữ | widget test mới ở bước 0: lời gọi đúng tham số; lỗi → câu |
| H21 | `injection.dart`: `ICatalogModule` | thêm 4 repository; giữ `ICatalogModule` (Q9) | `test/core/di/injection_test.dart`: 4 repository đăng ký; `ICatalogModule` **vẫn** đăng ký |
| H22 | `FakeCatalogModule` (3.831 dòng, 149 kịch bản) phục vụ mọi test catalog | `FakeCatalogBackend` + 4 fake repository + `FakeStockCatalogModule` (4.6) | mọi test ở mục 7.3 chạy lại xanh trên fake mới, **không đổi điều kiện kiểm** (chỉ đổi cách dựng), trừ các ca Q6 / Q8 đã ghi |
| H23 | SP-10 mở từ PCC, sửa tồn, quay về PCC thấy tồn mới (chung `FakeCatalogModule`) | SP-10 qua `FakeStockCatalogModule`, PCC qua `FakeProductRepository`, **chung** `FakeCatalogBackend` | `product_stock_e2e_test.dart` hiện có phải xanh |

**Bước 0:** viết các ca "bước 0 thêm" của H1–H20 trên code **cũ** với `FakeCatalogModule` (hoặc fake ném exception module). Chạy xanh, ghi tên test. Bước 4 (mục 6) đổi cách dựng sang fake mới, chạy lại.

## 6. Các bước

Trước mỗi symbol sửa: `gitnexus impact` (upstream), ghi vào Kết quả. `injection.dart`, `app_router.dart`, `ProductGuidedCreateCubit`, `ProductControlCenterCubit` dễ ra HIGH: ghi blast radius, làm tiếp vì đã có test bước 0 + e2e.

0. Bước 0 (mục 5).
1. Fake mới (4.6): `fake_catalog_scenario.dart`, `fake_catalog_backend.dart`, `fake_catalog_repositories.dart`, `fake_stock_catalog_module.dart`, `catalog_test_registry.dart`. Test riêng cho fake: mỗi `FakeXRepository` 1 ca thành công + 1 ca lỗi với kịch bản tương ứng.
2. `git mv` cubit (4.1), sửa import toàn `lib/` + `test/`. Đổi 15 cubit theo bảng 4.1 và mục 5.
3. Trang / widget / mapper (4.2), xoá sheet cảnh báo (Q6).
4. Sales, pricing (4.3), DI (4.4), router (4.5).
5. Đổi 28 tệp test (mục 7.3) sang `registerFakeCatalog` / fake repository; test `presentation_module/*` của catalog chuyển sang `test/features/catalog/logic/` (cubit) hoặc giữ chỗ (widget, util). Chạy lại test bước 0.
6. Kiểm mục 7, ghi Kết quả, `detect_changes()`.

## 7. Kiểm tra

### 7.1 Tự động

- [ ] `git grep -l "package:vet45_catalog" -- apps/erp/lib` → **đúng 2 tệp**: `product_stock_adjustment_page.dart`, `core/di/injection.dart`.
- [ ] `git grep -nE "ICatalogModule|IExecutionContext|executeQueryAsync|executeCommandAsync" -- apps/erp/lib/features/catalog apps/erp/lib/features/sales/presentation/lookups/sales_catalog_product_lookup.dart apps/erp/lib/features/pricing/presentation/pages/pricing_pick_product_page.dart apps/erp/lib/features/pricing/presentation/pages/pricing_pick_unit_page.dart` → chỉ còn ở `product_stock_adjustment_page.dart`.
- [ ] `git grep -n "WARNING_REQUIRE_ACK\|PriceBandWarning\|showPriceBandWarningAckSheet\|confirmAcknowledgeWarnings: true" -- apps/erp/lib/features/catalog/logic/edit_product_unit_price_band_cubit.dart apps/erp/lib/features/catalog/presentation/pages/edit_product_unit_price_band_page.dart apps/erp/lib/features/catalog/presentation/widgets` → rỗng. (`confirmAcknowledgeWarnings` của **ngừng kinh doanh / xoá sản phẩm** vẫn còn, đúng.)
- [ ] `git grep -n "\.toString()" -- apps/erp/lib/features/catalog/logic` → không còn `e.toString()` / `error.toString()` làm câu hiển thị (ghi các chỗ `toString` còn lại và lý do).
- [ ] `ls apps/erp/lib/features/catalog/presentation/bloc` → không tồn tại.
- [ ] `git grep -l "FakeCatalogModule\|vet45_catalog_application/testing" -- apps/erp/test` → rỗng.
- [ ] `cd apps/erp && dart analyze lib test`: không error / warning mới (ghi số trước / sau).
- [ ] `cd apps/erp && flutter test`: pass ≥ trước + test mới; fail trùng `TEST-BASELINE.md` + fail đã ghi ở W-2. Ghi tên fail mới nếu có.
- [ ] Mọi test bước 0 xanh (trừ ca Q6 đã xoá có ghi).

### 7.2 Kiểm tay (iPhone simulator + Chrome, Dev; người dùng)

- [ ] Danh sách: tìm, lọc trạng thái, lọc trường bổ sung, cuộn trang 2.
- [ ] Tạo sản phẩm đủ 7 bước (ảnh, đơn vị mới, tồn, giá cơ sở, khung giá tự động riêng, trường bổ sung) → mở PCC.
- [ ] Tạo trùng SKU → báo ở bước 1.
- [ ] PCC: sửa hồ sơ, ảnh, ghi chú, ngừng kinh doanh khi còn tồn (khối "Cần xác nhận"), kinh doanh lại, xoá, khôi phục.
- [ ] Đơn vị: đặt cơ sở, thêm, tắt, bật, xoá (bị chặn khi có khung giá).
- [ ] Giá: giá cơ sở, khung giá 3 cách, ghi đè khung có sẵn, khung giá cửa hàng + lịch sử.
- [ ] Cài đặt trường bổ sung: tạo nhóm / trường, sắp xếp, tạm tắt.
- [ ] Điều chỉnh tồn SP-10 vẫn chạy (đường module).
- [ ] Bán hàng: tìm sản phẩm, quét barcode, chọn đơn vị. Pricing: chọn sản phẩm, chọn đơn vị.

### 7.3 Test đang dùng `FakeCatalogModule` / `ICatalogModule` (đổi ở bước 5)

`test/core/di/injection_test.dart`; `test/features/catalog/catalog_e2e_harness.dart`; `test/features/catalog/presentation/pages/`: `edit_product_unit_price_band_e2e_test`, `product_catalog_tab_page_test`, `product_change_history_page_test`, `product_control_center_page_test`, `product_guided_create_e2e_test`, `product_guided_create_page_test`, `product_price_bands_e2e_test`, `product_profile_maintenance_e2e_test`, `product_readiness_e2e_test`, `product_soft_delete_e2e_test`, `store_price_rule_change_history_wgt_test` và mọi tệp dùng `catalog_e2e_harness.dart`; `test/features/catalog/presentation_module/product_control_center_cubit_test.dart`, `edit_product_unit_price_band_cubit_test.dart`; `test/features/catalog/product_price_band_snapshot_e2e_test.dart`; `test/features/sales/presentation/sales_catalog_product_lookup_test.dart`, `sales_checkout_page_test.dart`, `sales_draft_backend_test.dart`, `test/features/sales/sales_flow_pages_test.dart`. Ngoài ra các tệp chỉ đăng ký `ICatalogModule` để dựng shell (`auth/e2e_th01_s0_session_test.dart`, `iam/presentation_module/w2_*`, `tenant_context/presentation/*`, `dashboard/presentation/*`): đổi sang `registerFakeCatalog` nếu chúng dựng màn catalog, còn không thì giữ (ghi lại).

## 8. Rủi ro / lưu ý

- **Chép fake** là việc lớn nhất (≈ 3.800 dòng). Giữ nguyên dữ liệu và thứ tự nhánh; chỉ đổi kiểu và cách ném lỗi. Không "sửa" hành vi fake cho khớp code mới.
- `FakeCatalogModule` có kịch bản ném exception module kèm dữ liệu (`DuplicateSkuException(existingProductId:)`, `PriceBandOverwriteRequiredException(existingListAfterVat:)`). Fake mới đặt các giá trị đó vào `details` với **đúng khoá** cubit đọc ở H9 / H15.
- Kiểu enum / DTO cùng tên ở module và app: tệp test còn import module (chỉ nhóm `old` của 5-A1 / 5-A2 và `FakeStockCatalogModule`) phải import có `as` để không lẫn.
- `ProductReadinessChecklistPage` nhận `ProductReadinessViewDto` qua `extra` từ PCC: kiểu đổi sang app cùng lúc ở cả hai đầu (cùng PR), không lẫn.
- Màn SP-10 bắt lỗi bằng kiểu module. Đường thật vẫn qua module (đúng). Trong test, `FakeStockCatalogModule` phải ném **kiểu module**, không ném `AppException`.

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi bước** ghi ngay, không dồn cuối. Mẫu cho mỗi bước:
> - Trạng thái: ✅ / 🔄 dở (ghi tới đâu) / ⏭ (lý do)
> - Tệp:dòng đã đổi
> - Lệch so với plan + lý do
> - Test thêm / sửa (tên test); test đổi kỳ vọng do Q6 / Q8 (dòng H nào)
> - Impact (`gitnexus impact`): symbol, số caller, mức rủi ro
> - Ghi chú cho review
>
> Bước cuối: lệnh đã chạy, số pass / fail, tên test fail đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes()`.

## 10. Review

<!-- Phiên review ghi -->
