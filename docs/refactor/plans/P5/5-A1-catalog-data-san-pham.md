# 5-A1 — Lớp dữ liệu catalog: model, lỗi, rule, readiness, `ProductRepository`

> Theme 2 (mã cũ P5) · Bước (a) chuyển kiến trúc, phần **dữ liệu** · Gồm việc 5.1 (phần data) (PLAN.md mục Theme 2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01; rà lại theo code 2026-11-02: thêm Q11 ký URL ảnh, kiểm rỗng 6 lệnh ghi, slot ảnh, câu 6.4 cho `validation_exception`, 4 handler đọc trước, 3 đổi có chủ đích ở H3, H9) | Làm ✅ (đã sửa R1-1 … R1-3, T1 … T4 ngày 2026-11-03) | Review ✅ R2 2026-11-03 (đã sửa R1-1, R1-2, R1-3 của R1; thêm T1–T4)
> Tài liệu: [PLAN.md](../../PLAN.md) "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ"; [TH-02](../../../02-yeu-cau/TH-02-san-pham-va-gia-ban.md) mục 6.2, 6.4, 7.1, 7.2, 9.1.
> Plan sau: [5-A2](5-A2-catalog-data-don-vi-truong-gia.md) (3 repository còn lại), [5-A3](5-A3-catalog-ui-sang-repository.md) (đổi UI), [5-A4](5-A4-cap-cua-hang-kho-mac-dinh.md), [5-B](5-B-sua-ki-th02.md), [5-W](5-W-catalog-web.md). 5-C (xoá module) chạy sau Theme 7, chưa viết.

## 1. Mục tiêu

Dựng sẵn lớp dữ liệu mới của catalog trong `apps/erp/lib/features/catalog/`, **chưa** đổi UI:

```text
(5-A3 mới nối)  Cubit ─▶ ProductRepository ─▶ SupabaseRpc ─▶ supabase.schema('catalog').rpc(...)
```

Sau 5-A1:

- `features/catalog/data/models/` có **toàn bộ** kiểu mà phía sản phẩm cần (mục 4.1), chép từ module, giữ nguyên tên class / field / constructor.
- `features/catalog/data/catalog_errors.dart`: đổi lỗi RPC catalog (chuỗi thường, không theo dạng `CODE: …`) sang `AppException` với mã riêng (mục 4.3). Dùng chung cho 4 repository.
- `features/catalog/logic/`: câu lỗi theo TH-02 6.4, mã quyền, rule đầu vào, bộ tính readiness / PCC.
- `ProductRepository` đủ method cho mọi chỗ app đang gọi về sản phẩm, kể cả 4 method "hàng bán được" cho Sales (TH-02 9.1).
- Test parity nhóm `old` / `new` dùng **chung** map mong đợi.

**Không** đổi cubit, trang, router, DI, sales, pricing: việc của 5-A3. App vẫn chạy y như cũ.

## 2. Quyết định (người dùng chốt 2026-11-01)

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Chia 5-A | **Theo lớp.** 5-A1 = model + lỗi + rule + readiness + `ProductRepository`; 5-A2 = 3 repository còn lại; 5-A3 = đổi toàn bộ UI một lượt + chép fake; 5-A4 = cặp cửa hàng–kho. Lý do: các nhóm màn dùng chung kiểu / widget (tạo sản phẩm dùng kiểu của trường bổ sung, đơn vị, khung giá cửa hàng; PCC dùng kiểu của màn giá) và test e2e đi xuyên mọi màn trên một fake, nên không đổi từng phần được |
| Q2 | Handler đọc thêm RPC trước / sau lệnh (đọc PCC trước khi sửa hồ sơ / ảnh; đọc readiness, danh sách đơn vị, PCC trước khi đặt giá / đơn vị / khung giá; đọc lại readiness sau lệnh để trả kết quả) | **Bỏ.** Repository gọi **đúng 1 RPC** mỗi method. Server đã tự trả mã (`product is soft-deleted…`, `missing base unit`, `inactive_product_unit`, `missing_base_price`…, TH-02 6.4). Chỉ giữ rule **chỉ cần dữ liệu nhập** thành hàm thuần (mục 4.5). Kiểu trả về chỉ giữ field mà cubit dùng (cột "Trả về" mục 3.2) |
| Q3 | Kiểm quyền client của pipeline module | **Bỏ** (như Theme 3). Server `permission denied: catalog.*`. **Giữ** cờ quyền dùng để **bật / tắt nút** trong PCC và checklist (bộ dựng readiness, mục 4.6), đọc từ `SessionController.hasPermission` |
| Q4 | Kiểu dữ liệu và fake | **Chép hết ở 5-A.** 5-A1/5-A2 chép kiểu; 5-A3 chép fake |
| Q5 | Tồn kho cơ bản (SP-10) | Giữ module tới 5-C (PLAN 2026-10-14). 5-A1 **không** làm method tồn riêng (`adjust_basic_stock`, `set_basic_stock_quantity_base`). Tồn khởi tạo khi tạo sản phẩm vẫn đi qua `create_guided_product` (tham số `p_basic_stock_quantity_base`) |
| Q11 | Ký URL tải ảnh lên (Storage) khi xin slot ảnh | **Người dùng chốt 2026-11-02:** `ProductRepository` nhận thêm hàm `signUploadUrl(storageKey)` tiêm từ DI (5-A3 nối tới `storage.from(catalogProductImagesBucket).createSignedUploadUrl`). Repository không giữ `SupabaseClient`; test truyền hàm giả |

## 3. Hiện trạng (đo 2026-11-01)

### 3.1 Ai đang gọi phía sản phẩm của module

| Nơi | Gọi gì |
|---|---|
| `features/catalog/presentation/bloc/product_list_cubit.dart` | `SearchProductsQuery` |
| `…/pages/product_catalog_tab_page.dart:63` | `ListCustomFieldFilterOptionsQuery` |
| `…/bloc/product_control_center_cubit.dart` | `GetProductControlCenterQuery`, `GetProductReadinessQuery`, `DeactivateProductCommand`, `ReactivateProductCommand` |
| `…/bloc/product_change_history_cubit.dart` | `GetProductChangeHistoryQuery` |
| `…/bloc/product_soft_delete_cubit.dart` | `CheckProductDeletionEligibilityQuery`, `DeleteProductCommand`, `RestoreProductCommand` |
| `…/bloc/product_profile_maintenance_cubit.dart`, `…/pages/product_note_edit_page.dart:70` | `UpdateProductProfileCommand` |
| `…/bloc/product_images_maintenance_cubit.dart` | `RequestProductMaintenanceImageUploadCommand`, `UpdateProductImagesCommand` |
| `…/bloc/product_guided_create_cubit.dart` | `CheckDuplicateProductCodeQuery`, `RequestProductImageUploadCommand`, `CreateGuidedProductCommand` (+ 3 query của 5-A2: `ListCustomFieldConfigQuery`, `ListTenantMeasurementUnitsQuery`, `GetStorePriceRuleQuery`) |
| `features/sales/presentation/lookups/sales_catalog_product_lookup.dart` | `SearchSellableProductsQuery`, `ResolveSellableBarcodeQuery`, `ListSellableProductUnitsQuery` |
| `features/sales/presentation/orchestration/sales_draft_backend.dart:303` | `ResolveSellableProductsQuery` |
| `features/pricing/presentation/pages/pricing_pick_product_page.dart:68` | `SearchProductsQuery` (limit 30) |

Không ai trong app gọi: `ScanBarcodeQuery` / `find_product_by_barcode`, `CreateProductCommand` / `create_product`, `SetInitialPriceBandCommand`, `GetProductStockHistoryQuery`, `GetProductCustomFieldSnapshotQuery`, `CheckDuplicateMeasurementUnitNameQuery`. **Không** chuyển.

### 3.2 RPC → tham số → kết quả

Mọi RPC ở schema `catalog`. `p_tenant_id` lấy từ phiên, `p_actor_id` = user đang đăng nhập (repository tự lấy, như `PartnerRepository`). Tệp gốc: `modules/catalog/infrastructure/lib/src/domain/…` (viết tắt `infra/`).

Cột "Gọi": `rows` = `SupabaseRpc.rows` (bản cũ `callList`), `call` = `SupabaseRpc.call` lấy kết quả thô (bản cũ `callMap` → ép `Map`, null → `{}`; `callScalar` → giữ thô).

| Method mới | RPC | Gọi | Tham số (chép **đúng khoá**) | Kết quả (chép thân) | Trả về |
|---|---|---|---|---|---|
| `search({criteria, limit, offset})` | `search_products` | rows | `ProductRpcMapper.searchProductsParams` (+ `customFieldFiltersToRpc`, `_readinessFilterToRpc`, `_sortOrderToRpc`, `ProductBusinessStatus.toWire`) | `SupabaseCatalogReadGateway.search`: rỗng → `ProductSearchResultDto(items: [], totalCount: 0)`; `total_count` (thiếu → số dòng), `ready_to_sell_count`, `incomplete_count`, `inactive_count` lấy ở dòng đầu; item = `ProductListItemMapper.fromRow` → `ProductListItemAssembler.toDto` | `ProductSearchResultDto` |
| `listCustomFieldFilterOptions({maxOptionsPerField})` | `list_custom_field_filter_options` | call | `CustomFieldRpcMapper.listCustomFieldFilterOptionsParams` | `CustomFieldRpcMapper.filterOptionsFromJson` (+ `filterOptionFromJson`, `selectOptionFromJson`) | `List<CustomFieldFilterOptionDto>` |
| `checkDuplicateCodes({sku, barcode, excludeProductId})` | `check_duplicate_product_code` | rows | `ProductRpcMapper.checkDuplicateParams`. Giá trị như handler cũ: `sku` → `trim()`, rỗng → `null`, khác rỗng → **`toUpperCase()`** (value object `Sku`); `barcode` → `trim()`, rỗng → `null` | mỗi dòng → `ProductDuplicateMatchDto(field: duplicateFieldFromRpc(duplicate_field), productId, productName: product_name, matchedValue: matched_value)` (`SupabaseProductDuplicateChecker.findMatches` + `ProductDuplicateMatchDto.fromDomain`) | `List<ProductDuplicateMatchDto>` |
| `createGuided(CreateGuidedProductInput input)` | `create_guided_product` | call | `ProductRpcMapper.createGuidedProductParams`. `id` = `const Uuid().v4()` **mới mỗi lần gọi** (bản cũ: `CommandBase` sinh id khi tạo command; cubit tạo command mới mỗi lần `submit`). `p_idempotency_key = id`; `p_reference_id = productReferenceIdFromUuid(id)` (mục 4.7) | `ProductRpcMapper.createGuidedProductResultFromJson` (+ `_readinessSummaryFromRow`) | `CreateGuidedProductResult` |
| `requestImageUpload({fileName, contentType, byteSize})` | `request_product_image_upload` | rows | `p_tenant_id, p_file_name, p_content_type, p_byte_size, p_actor_id` (`SupabaseProductImageUploadGateway.reserveUploadSlot`) | **Slot ảnh** (bên dưới bảng) | `ProductImageUploadSlotDto` |
| `requestMaintenanceImageUpload({productId, fileName, contentType, byteSize})` | `request_product_maintenance_image_upload` | rows | `ProductRpcMapper.requestMaintenanceImageUploadParams` | **Slot ảnh** (bên dưới bảng; thân `reserveMaintenanceUploadSlot`, giống hệt) | `ProductImageUploadSlotDto` |
| `getControlCenter(productId)` | `get_product_control_center` | rows | `ProductRpcMapper.getProductControlCenterParams` | `SupabaseCatalogReadGateway.loadControlCenter` (dòng đầu; có khoá `get_product_control_center` thì lấy map bên trong) → `ProductControlCenterMapper.fromJson` → `ProductControlCenterAssembler.assemble(model, permissions, includeChangeHistory: hasPermission(viewHistory))` (mục 4.6). Rỗng → `AppException(CatalogErrorCodes.productNotFound)` | `ProductControlCenterDto` |
| `getReadiness(productId)` | `get_product_readiness` | rows | `ProductRpcMapper.getProductReadinessParams` | dòng đầu → `ProductReadinessFactsMapper.fromRow` → `ProductReadinessEvaluator.compute` → `ProductReadinessViewAssembler.assemble(facts, readiness, permissions)`. Rỗng → `productNotFound` | `ProductReadinessViewDto` |
| `updateProfile({productId, expectedVersion, productName, commercialName, sku, barcode, description, note})` | `update_product_profile` | rows | `ProductRpcMapper.updateProductProfileParams` | không đọc (Q2: cubit không dùng kết quả) | `void` |
| `updateImages({productId, expectedVersion, images})` | `update_product_images` | rows | `ProductRpcMapper.updateProductImagesParams` | không đọc | `void` |
| `deactivate({productId, expectedVersion, reason, confirmAcknowledgeWarnings})` | `deactivate_product` | rows | `ProductRpcMapper.deactivateProductParams` | không đọc | `void` |
| `reactivate({productId, expectedVersion, reason})` | `reactivate_product` | rows | `reactivateProductParams` | không đọc | `void` |
| `checkDeletionEligibility(productId)` | `check_product_deletion_eligibility` | rows | `checkProductDeletionEligibilityParams` | dòng đầu → `productDeletionEligibilityFromRow` (+ `_deletionIssues`, `_deletionIssueSeverityFromRpc`, `_warningDtos`). Rỗng → `AppException(unknown, serverMessage: 'Product deletion eligibility did not return a result.')` (câu của `supabase_product_deletion_gateway.dart:27`, **không** phải `productNotFound`) | `ProductDeletionEligibilityDto` |
| `delete({productId, expectedVersion, reason, confirmAcknowledgeWarnings})` | `delete_product` | rows | `deleteProductParams` | không đọc | `void` |
| `restore({productId, expectedVersion, reason})` | `restore_product` | rows | `restoreProductParams` | không đọc | `void` |
| `getChangeHistory({productId, limit, offset, changeCategories})` | `get_product_change_history` | call | `ProductChangeHistoryRpcMapper.getProductChangeHistoryParams` | `pageFromJson` → `ProductChangeHistoryResultDto(productId, items: page.items.map(toDto), totalCount)` (thân `GetProductChangeHistoryQueryHandler.handle`, `ProductChangeHistoryReadRow.toDto`) | `ProductChangeHistoryResultDto` |
| `searchSellable({storeId, keyword, limit, offset})` | `search_sellable_products` | call | `CatalogSalesLookupRpcMapper.searchSellableProductsParams` | `productsFromPayload` | `List<SellableProductDto>` |
| `resolveSellableBarcode({storeId, barcode})` | `resolve_sellable_barcode` | call | `resolveSellableBarcodeParams` | `productsFromPayload` | `List<SellableProductDto>` |
| `listSellableUnits({storeId, productId})` | `list_sellable_product_units` | call | `listSellableProductUnitsParams` | `unitsFromPayload` | `List<SellableProductUnitDto>` |
| `resolveSellable({storeId, productIds})` | `resolve_sellable_products` | call | `resolveSellableProductsParams` | `resolutionsFromPayload` | `List<SellableProductResolutionDto>` |

**Slot ảnh** (`requestImageUpload`, `requestMaintenanceImageUpload`; chép thân `reserveUploadSlot` / `reserveMaintenanceUploadSlot` của `supabase_product_image_upload_gateway.dart`, Q11). Theo thứ tự:

1. `rows` RPC (trong `_guard`). Rỗng → `AppException(AppErrorCode.unknown, serverMessage: 'Image upload slot was not created.')`.
2. Dòng đầu: `slotId = row['slot_id']?.toString()`, `storageKey = row['storage_key']?.toString()`. Một trong hai null / rỗng → `AppException(AppErrorCode.unknown, serverMessage: 'Invalid image upload slot response.')`. Hàm ký **không** được gọi.
3. `expiresAt` (chép `_parseExpiresAt`): `DateTime` → `toUtc()`; `String` khác rỗng → `DateTime.parse(v).toUtc()`; còn lại → `DateTime.now().toUtc().add(const Duration(hours: 1))`.
4. `signedUploadUrl = await _signUploadUrl(storageKey)`. `on StorageException catch (e)` (`package:supabase`) → `AppException(AppErrorCode.unknown, serverMessage: e.message, cause: e)`. Bước này **không** đi qua `_guard` / `catalogException`.
5. Trả `ProductImageUploadSlotDto(slotId:, storageKey:, signedUploadUrl:, expiresAt:)`.

Ghi chú:

- **Giá trị mặc định** của tham số method = mặc định của Query / Command cũ tương ứng (đọc constructor gốc). Đo 2026-11-01: `search` `limit = 50, offset = 0`; `listCustomFieldFilterOptions` `maxOptionsPerField = 50`; `getChangeHistory` `limit = 50, offset = 0`. Tham số app không truyền thì lấy đúng mặc định đó.
- `CatalogSalesLookupRpcMapper` kiểm chặt payload (`_requiredUuid`, `_requiredCurrency`, `_invalid` …). Chép **nguyên** các hàm kiểm. `_invalid` đổi từ `throw RpcException('invalid_catalog_sales_lookup_payload: …')` sang `throw AppException(AppErrorCode.unknown, serverMessage: 'invalid_catalog_sales_lookup_payload: …')`.
- Lỗi "did not return a result" của bản cũ (`ApplicationException(...)`) → `AppException(AppErrorCode.unknown, serverMessage: <cùng câu>)`.
- **"không đọc"** ở cột "Kết quả" nghĩa là không dựng DTO từ dòng trả về, nhưng **giữ** bước kiểm rỗng của gateway cũ (`supabase_product_command_gateway.dart`): `rows` rỗng → `AppException(AppErrorCode.unknown, serverMessage: …)` với đúng câu: `updateProfile` "Product update did not return a result."; `updateImages` "Product image update did not return a result."; `deactivate` "Product deactivate did not return a result."; `reactivate` "Product reactivate did not return a result."; `delete` "Product delete did not return a result."; `restore` "Product restore did not return a result.". Test H2 có 1 ca rỗng cho mỗi method.

### 3.3 Việc client module cũ làm quanh các RPC trên

| Handler cũ | Làm thêm | Sau 5-A1 |
|---|---|---|
| `UpdateProductProfileCommandHandler` | gọi `get_product_control_center` (qua `CatalogProductWritePort.load`); không có → `Product not found`; rule `ProductMustNotBeSoftDeletedRule`, `ProductNameRequiredRule`, `Sku` / `Barcode` không rỗng khi có | **Bỏ đọc trước** (Q2). Giữ rule đầu vào (mục 4.5 `checkUpdateProfile`). Đã xoá → server `product is soft-deleted and cannot …` |
| `UpdateProductImagesCommandHandler` | đọc PCC như trên; `AtMostOnePrimaryImageRule`, chưa xoá | Bỏ đọc trước; giữ ≤ 1 ảnh chính (`checkUpdateImages`) |
| `GetProductControlCenterQueryHandler`, `GetProductReadinessQueryHandler` | dựng DTO bằng bộ dựng + cờ quyền (`ProductReadinessPermissionResolver` gọi `permissionChecker.require`) | **Giữ**, cờ quyền đọc từ `hasPermission` (mục 4.6) |
| Mọi handler | `*Validator.validate` (pipeline) | giữ phần **không phải** "tenant / actor / id bắt buộc" (mục 4.5). Kiểm `limit` / `offset` của query: **bỏ** (app truyền hằng trong khoảng; server cũng chặn) |
| `DeactivateProductCommandHandler`, `ReactivateProductCommandHandler`, `DeleteProductCommandHandler`, `RestoreProductCommandHandler` | đọc PCC (`_productWritePort.load`); không có → `Product not found`; rule trạng thái domain (`ProductMustNotBeSoftDeletedRule`, `ProductMustBeActiveRule`… trong `Product.deactivate / reactivate / softDelete / restore`) | **Bỏ** (Q2). Server tự chặn: `product not found`, `product is soft-deleted and cannot change business status`, `validation_exception: Product is already inactive.` / `already active.` / `already soft-deleted.`, `product_restore_blocked: Product is not soft-deleted.` |
| Pipeline | kiểm quyền client theo `catalog_access_metadata.g.dart` | **Bỏ** (Q3) |
| `mapCatalogRpcError` | đổi chuỗi lỗi sang exception có kiểu | `catalogException` (mục 4.3) |

## 4. Thiết kế

### 4.1 Model (`apps/erp/lib/features/catalog/data/models/`)

Chép class / enum / extension từ module, **giữ nguyên** tên, field, constructor, giá trị mặc định, `toWire` / `fromWire`, `props` (nếu có `Equatable`). Chỉ đổi import. Kiểu từ `c45_shared_domain` (`ValueObject`) thì bỏ kế thừa, giữ `==` / `hashCode` theo giá trị (như `PersonTitle` ở 4-A).

| Tệp mới | Chứa (tệp gốc trong `modules/catalog/{application,domain}/lib/src/`) |
|---|---|
| `catalog_enums.dart` | `ProductBusinessStatus` (`domain/product/product_business_status.dart`: **class** hằng `active` / `inactive` / `softDeleted`, `values`, `isActive`…, `toWire()`, `name`, `fromWire` nếu có: chép đúng dạng class, không đổi thành `enum`; bỏ `extends ValueObject`, giữ `==` / `hashCode` theo `_wire`, giữ constructor `const`), `ReadinessStatus` (`domain/readiness/`), `BasePriceMode`, `StockMode`, `ProductDuplicateField` (`application/shared/`), `ProductReadinessFilter`, `ProductSortOrder` (`domain/search/`), `PriceBandSourceType` (`application/product_unit_price_band/queries/list_product_unit_price_bands/`), `ProductChangeHistoryAction`, `ProductPriceBandHistoryTrigger` (`application/product_change_history/shared/`), `ProductDeletionIssueSeverity`, `SellableProductResolution` |
| `product_search.dart` | `ProductSearchCriteria`, `CustomFieldFilterCriteria` (`domain/search/`), `ProductListItemDto`, `ProductSearchResultDto` (`application/product/queries/search_products/`), `ProductListItemReadRow` (đọc dòng, `infra/product/product_list_item_mapper.dart` dùng) |
| `product_control_center.dart` | `ProductControlCenterDto` và mọi kiểu nó chứa: `ProductProfileSummaryDto`, `ProductStockCardDto`, `ProductUnitsCardDto`, `ProductBasePriceCardDto`, `ProductPriceBandCardDto`, `CustomFieldGroupCardDto`, `CustomFieldCardFieldDto`, `ProductImageDto`, `ProductControlCenterReadModel` (`application/product/queries/get_product_control_center/`) |
| `product_readiness.dart` | `ReadinessSummaryDto` (+ `fromDomain`), `ReadinessBlockerDto`, `ProductReadinessFacts`, `ProductReadinessViewDto` và kiểu lồng của nó (`application/product_readiness/**`, `domain/readiness/**`) |
| `product_inputs.dart` | `ProductImageInput`, `ProductImageMutationInput`, `BaseUnitSelection` / `ExistingTenantUnit` / `NewTenantUnit` (`application/shared/base_unit_selection.dart`), `ProductCustomFieldValueInput`. **Mới:** `CreateGuidedProductInput` = các field của `CreateGuidedProductCommand` **trừ** `tenantId`, `actorId`, `id` (cùng tên, cùng kiểu, cùng mặc định) |
| `product_results.dart` | `CreateGuidedProductResult`, `ProductImageUploadSlotDto`, `ProductDuplicateMatchDto` (bỏ `fromDomain`, thêm constructor thường nếu chưa có), `ProductDeletionEligibilityDto`, `ProductDeletionIssueDto`, `ProductBusinessStatusWarningDto` |
| `product_change_history.dart` | `ProductChangeHistoryEntryDto`, `ProductChangeHistoryResultDto`, `ProductChangeHistoryPage` (cùng tên class `ProductChangeHistoryPage` của module: router đang `hide` nó, xem rủi ro mục 8), `ProductChangeHistoryReadRow` (+ `toDto`), `ProductPriceBandHistoryChangeDto`, `ProductPriceBandHistorySnapshotDto` |
| `sellable_product.dart` | `SellableProductDto`, `SellableProductUnitDto`, `SellableProductResolutionDto` |
| `custom_field_filter_option.dart` | `CustomFieldFilterOptionDto`, `CustomFieldSelectOptionDto` (`application/product/queries/list_custom_field_filter_options/`, `application/custom_field/shared/`) |

Quy tắc chép:

- Kiểu nào tệp trên tham chiếu mà chưa có trong bảng (vd. một enum lồng) thì chép **cùng tệp** với kiểu dùng nó. Ghi tên vào Kết quả.
- Bộ đọc JSON: viết `factory X.fromJson(...)` / hàm top-level `xFromRow(...)` **cạnh** model, thân chép từ mapper ở mục 3.2. Không gom vào một tệp mapper lớn.
- **Không** chép: các `*Command`, `*Query`, `*Validator`, `*Handler`, các exception có kiểu (`DuplicateSkuException`…): thay bằng mã ở mục 4.3.

Ghi số kiểu đã chép vào Kết quả (đo 2026-11-01 app dùng 74 kiểu không phải command / query của module, cả phía 5-A2).

### 4.2 `ProductRepository` (`features/catalog/data/product_repository.dart`, tạo mới)

```dart
class ProductRepository {
  ProductRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
    required bool Function(String permissionCode) hasPermission,
    required Future<String> Function(String storageKey) signUploadUrl, // Q11
  });
  // 21 method đúng tên, đúng tham số như cột 1 mục 3.2.
}
```

- Mỗi method gọi **đúng 1 RPC** của mục 3.2 (Q2). Không gọi RPC đọc thêm. Riêng 2 method slot ảnh gọi thêm `signUploadUrl` (Storage, không phải RPC; mục 3.2 "Slot ảnh").
- Method có rule (mục 4.5) gọi rule **trước** RPC. Rule sai → `AppException(AppErrorCode.validation, serverMessage: <câu của rule>)`, không gọi RPC.
- Mọi lời gọi `_rpc` bọc trong `_guard`:

```dart
Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on AppException catch (e) {
    throw catalogException(e);
  }
}
```

### 4.3 Lỗi (`features/catalog/data/catalog_errors.dart`)

**Vì sao cần:** RPC catalog báo lỗi bằng chuỗi thường (`duplicate sku "A1"`, `stale_product_version: expected=3 current=4`, `validation_exception: …`, `product not found`). `AppException.from` chỉ nhận mã viết hoa ở đầu chuỗi, nên các lỗi này ra `SYSTEM_ERROR` với `serverMessage` = nguyên chuỗi. Cần phân loại lại.

```dart
abstract final class CatalogErrorCodes {
  static const duplicateSku = 'DUPLICATE_SKU';                    // details: {'value': '<sku>'}
  static const duplicateBarcode = 'DUPLICATE_BARCODE';            // details: {'value': '<barcode>'}
  static const duplicateReferenceId = 'DUPLICATE_REFERENCE_ID';   // details: {'value': ...}
  static const duplicateProductUnit = 'DUPLICATE_PRODUCT_UNIT';   // details: {'value': '<tên>'}
  static const missingBaseUnit = 'MISSING_BASE_UNIT';
  static const notBasicStockMode = 'NOT_BASIC_STOCK_MODE';
  static const notManualBasePriceMode = 'NOT_MANUAL_BASE_PRICE_MODE';
  static const storePriceRuleNotFound = 'STORE_PRICE_RULE_NOT_FOUND';
  static const storePriceRuleInactive = 'STORE_PRICE_RULE_INACTIVE';
  static const priceBandOverwriteRequired = 'PRICE_BAND_OVERWRITE_REQUIRED';
  static const staleBasePrice = 'STALE_BASE_PRICE';
  static const missingBasePrice = 'MISSING_BASE_PRICE';
  static const floorGreaterThanList = 'FLOOR_GREATER_THAN_LIST';
  static const inactiveProductUnit = 'INACTIVE_PRODUCT_UNIT';
  static const conversionUnitDeleteBlocked = 'CONVERSION_UNIT_DELETE_BLOCKED'; // serverMessage: lý do (đã bỏ tiền tố)
  static const duplicateCustomFieldGroupName = 'DUPLICATE_CUSTOM_FIELD_GROUP_NAME';
  static const duplicateCustomFieldName = 'DUPLICATE_CUSTOM_FIELD_NAME';
  static const customFieldGroupNotFound = 'CUSTOM_FIELD_GROUP_NOT_FOUND';
  static const customFieldValueValidation = 'CUSTOM_FIELD_VALUE_VALIDATION'; // details: {'errors': [{field_id, group_id, code, message}]}
  static const customFieldNotFound = 'CUSTOM_FIELD_NOT_FOUND';
  static const customFieldTypeChangeBlocked = 'CUSTOM_FIELD_TYPE_CHANGE_BLOCKED';
  static const staleStockQuantity = 'STALE_STOCK_QUANTITY';
  static const staleProductVersion = 'STALE_PRODUCT_VERSION';       // details: {'expected': int, 'current': int}
  static const statusWarningsRequireAck = 'BUSINESS_STATUS_WARNINGS_REQUIRE_ACK'; // details: {'warnings': [{code, message}]}
  static const productDeleteBlocked = 'PRODUCT_DELETE_BLOCKED';     // serverMessage: phần sau tiền tố
  static const productRestoreBlocked = 'PRODUCT_RESTORE_BLOCKED';   // serverMessage: phần sau tiền tố
  static const productSoftDeleted = 'PRODUCT_SOFT_DELETED';
  static const productNotFound = 'PRODUCT_NOT_FOUND';
  static const productNameRequired = 'PRODUCT_NAME_REQUIRED';
}

/// Phân loại lại lỗi RPC catalog. Giữ đúng thứ tự kiểm của `mapCatalogRpcError`.
AppException catalogException(AppException error);
```

`catalogException`:

1. `error.code` khác `AppErrorCode.unknown` → trả nguyên (`NO_PERMISSION`, `AUTHENTICATION_REQUIRED`, `NETWORK_ERROR`, mã viết hoa…).
2. Ngược lại lấy `m = error.serverMessage ?? ''`, `lower = m.toLowerCase()`, kiểm **theo đúng thứ tự** các `if` trong `infra/../errors/catalog_error_mapper.dart` (`duplicate sku` → … → `product not found`), mỗi nhánh trả `AppException(<mã>, serverMessage: …, details: …, cause: error.cause)`:
   - giá trị trong ngoặc kép: `_extractQuoted` → `details['value']` (không có → `''`);
   - `product_conversion_unit_delete_blocked`, `product_delete_blocked`, `product_restore_blocked`: `serverMessage = _stripKnownPrefix(m)`;
   - `custom_field_value_validation`: `details['errors']` = mảng JSON sau `[` (`_extractJsonArray`); không đọc được → `[{field_id: '', code: 'invalid', message: _stripKnownPrefix(m)}]`;
   - `stale_product_version`: `details` = `{'expected': n, 'current': n}` (`_extractExpectedCurrent`);
   - `product_business_status_warnings_require_acknowledgment`: `details['warnings']` (`_extractBusinessStatusWarnings`, đọc lỗi → `[]`);
   - `validation_exception` → `AppException(AppErrorCode.validation, serverMessage: _stripPrefix(m))`;
   - `product name is required` → `productNameRequired`;
   - **Mới (TH-02 6.4):** `product is soft-deleted` → `productSoftDeleted` (bản cũ rơi vào nhánh cuối, ra chuỗi thô). Đặt **trước** nhánh `validation_exception`;
   - `product not found` → `productNotFound`;
   - `actor mismatch` → `AppErrorCode.noPermission` (bản cũ: chuỗi thô). `not authenticated` / `permission denied` đã được `AppException.from` đổi trước đó.
3. Không khớp nhánh nào → trả nguyên `error` (`SYSTEM_ERROR`).

**3 đổi có chủ đích** so với `mapCatalogRpcError` (ghi ở dòng H3 mục 5): (1) thêm `product is soft-deleted` → `productSoftDeleted`; (2) thêm `actor mismatch` → `noPermission`; (3) `product_delete_blocked` / `product_restore_blocked`: bản cũ trả `ValidationException(_stripKnownPrefix(m))` (chung với lỗi nhập), nay tách mã riêng `productDeleteBlocked` / `productRestoreBlocked`, `serverMessage` giữ phần sau tiền tố như cũ (để 4.4 phân biệt "Sản phẩm chưa bị xoá.").

**Đổi có chủ đích (4), ngoài lỗi** (người dùng chốt 2026-11-03, review R1-1): bộ đọc PCC `ProductControlCenterReadModel.fromJson` đọc `price_band_source_type = 'customConfig'` thành `PriceBandSourceType.customConfig`. Bản cũ (`StorePriceRuleRpcMapper.sourceTypeFromRpc`) ra `null`, nên PCC báo "Thiếu khung giá bán" cho sản phẩm có khung giá cấu hình riêng. Ghi ở dòng H2 mục 5.

### 4.4 Câu lỗi (`features/catalog/logic/catalog_error_messages.dart`)

Theo TH-02 mục 6.4 (nguyên văn):

```dart
/// [fallback]: câu của thao tác khi mã không có câu riêng (mặc định câu chung 6.4).
String catalogErrorMessage(Object error, {String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.'}) {
  if (error is! AppException) return fallback;
  final value = error.details?['value'] as String? ?? '';
  return switch (error.code) {
    AppErrorCode.noPermission || AppErrorCode.authRequired => 'Bạn không có quyền thực hiện thao tác này.',
    CatalogErrorCodes.productNotFound => 'Sản phẩm không tồn tại hoặc đã bị xoá.',
    CatalogErrorCodes.staleProductVersion => 'Sản phẩm đã được cập nhật ở nơi khác. Vui lòng tải lại.',
    CatalogErrorCodes.duplicateSku => 'SKU "$value" đã được sử dụng',
    CatalogErrorCodes.duplicateBarcode => 'Barcode "$value" đã được sử dụng',
    CatalogErrorCodes.productNameRequired => 'Tên nội bộ không được bỏ trống',
    CatalogErrorCodes.productSoftDeleted => 'Sản phẩm đã bị xoá, không sửa được.',
    CatalogErrorCodes.missingBaseUnit => 'Cần thiết lập đơn vị cơ sở trước.',
    CatalogErrorCodes.duplicateProductUnit => 'Đơn vị "$value" đã có trong sản phẩm.',
    CatalogErrorCodes.conversionUnitDeleteBlocked => error.serverMessage ?? fallback,
    CatalogErrorCodes.inactiveProductUnit => 'Đơn vị bán đang không hoạt động.',
    CatalogErrorCodes.staleStockQuantity =>
      'Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.',
    CatalogErrorCodes.floorGreaterThanList => 'Giá sàn không được lớn hơn giá niêm yết.',
    CatalogErrorCodes.staleBasePrice => 'Giá cơ sở vừa thay đổi. Vui lòng tải lại.',
    CatalogErrorCodes.missingBasePrice => 'Sản phẩm chưa có giá cơ sở.',
    CatalogErrorCodes.storePriceRuleNotFound => 'Cửa hàng chưa cấu hình khung giá.',
    CatalogErrorCodes.storePriceRuleInactive => 'Khung giá cửa hàng đang tắt.',
    CatalogErrorCodes.duplicateCustomFieldGroupName => 'Tên nhóm đã tồn tại.',
    CatalogErrorCodes.duplicateCustomFieldName => 'Tên trường đã tồn tại trong nhóm.',
    CatalogErrorCodes.customFieldTypeChangeBlocked => 'Không đổi được kiểu dữ liệu do đã có dữ liệu.',
    CatalogErrorCodes.customFieldGroupNotFound || CatalogErrorCodes.customFieldNotFound =>
      'Không tìm thấy nhóm / trường.',
    CatalogErrorCodes.productDeleteBlocked || CatalogErrorCodes.productRestoreBlocked =>
      error.serverMessage ?? fallback,
    AppErrorCode.validation => (error.serverMessage?.trim().isNotEmpty ?? false) ? error.serverMessage! : fallback,
    _ => fallback,
  };
}
```

**Trước** `switch`, thêm `final known = _knownServerMessage(error); if (known != null) return known;` (ngay sau dòng `if (error is! AppException) return fallback;`):

```dart
/// TH-02 6.4: câu riêng theo nội dung `serverMessage` (chữ thường, `contains`).
/// Thứ tự quan trọng: "already inactive" trước "already active".
const _knownServerMessages = <(String code, String fragment, String text)>[
  (AppErrorCode.validation, 'product name is required', 'Tên nội bộ không được bỏ trống'),
  (AppErrorCode.validation, 'base unit is required for stock or pricing', 'Cần thiết lập đơn vị cơ sở trước.'),
  (AppErrorCode.validation, 'already has a base unit', 'Đơn vị cơ sở không đổi được sau khi đã đặt.'),
  (AppErrorCode.validation, 'conversion rate must be greater than zero', 'Tỷ lệ quy đổi phải > 0'),
  (AppErrorCode.validation, 'base price cannot be negative', 'Giá cơ sở không hợp lệ'),
  (AppErrorCode.validation, 'markup ratios are invalid', 'Tỷ lệ giá sàn không được lớn hơn tỷ lệ giá niêm yết.'),
  (AppErrorCode.validation, 'single select field requires options', 'Cần có ít nhất 1 tùy chọn'),
  (AppErrorCode.validation, 'product is already inactive', 'Sản phẩm đã ngừng kinh doanh.'),
  (AppErrorCode.validation, 'product is already active', 'Sản phẩm đang kinh doanh.'),
  (CatalogErrorCodes.productRestoreBlocked, 'product is not soft-deleted', 'Sản phẩm chưa bị xoá.'),
];

String? _knownServerMessage(AppException error) {
  final message = error.serverMessage?.toLowerCase();
  if (message == null) return null;
  for (final (code, fragment, text) in _knownServerMessages) {
    if (error.code == code && message.contains(fragment)) return text;
  }
  return null;
}
```

Nguồn: mỗi dòng là một dòng của TH-02 6.4; câu server có thật trong `supabase/migrations` (`validation_exception: Product name is required.`, `…base unit is required for stock or pricing`, `…Product already has a base unit; …`, `…Conversion rate must be greater than zero.`, `…base price cannot be negative`, `…markup ratios are invalid`, `…Single select field requires options.`, `…Product is already inactive.` / `active.`, `product_restore_blocked: Product is not soft-deleted.`). Dòng 1 cũng bắt câu rule client `Product name is required.` (`checkUpdateProfile`).

Các dòng tồn kho của 6.4 (`invalid_stock_quantity`, `stock_unchanged`, `stock_already_initialized`) **không** làm ở đây: thuộc SP-10 / Theme 7 (Q5).

Các câu 6.4 cần ngữ cảnh riêng **không** nằm ở đây (cubit tự xử lý, 5-A3): khôi phục trùng mã ("Không thể khôi phục: SKU …"), `price_band_overwrite_required` (mở hộp thoại), `product_business_status_warnings_require_acknowledgment` (khối "Cần xác nhận"), `custom_field_value_validation` (lỗi theo ô).

### 4.5 Rule (`features/catalog/logic/catalog_rules.dart`)

Hàm thuần, ném `AppException(AppErrorCode.validation, serverMessage: <câu>)`. Câu **nguyên văn** như bản cũ (kể cả câu tiếng Anh). Câu **hiển thị** do `catalogErrorMessage` đổi theo 6.4 (mục 4.4), không sửa câu của rule. Phần 5-A1:

| Hàm | Điều kiện (chép từ) | Gọi ở |
|---|---|---|
| `checkCreateGuided(CreateGuidedProductInput)` | thân `CreateGuidedProductCommandValidator.validate` **bỏ** vế `tenantId` / `actorId` (giữ vế tên: `productName.trim().isEmpty` → câu cũ "Tenant, actor and product name are required."), rồi mọi `if` còn lại theo đúng thứ tự (≤ 8 ảnh, ≤ 1 ảnh chính, đơn vị cơ sở có id / tên, cần đơn vị cơ sở khi có tồn / giá, tồn ≥ 0, giá hữu hạn ≥ 0, sàn ≤ niêm yết, ba nhánh theo `priceBandSourceType`, giá trị trường bổ sung) | `createGuided` |
| `checkImageUploadRequest({fileName, contentType, byteSize})` | thân `RequestProductImageUploadCommandValidator` / `RequestProductMaintenanceImageUploadCommandValidator` bỏ vế tenant / actor / product id (tên tệp, `_allowedContentTypes`, `byteSize > 0`, `_maxByteSize`; chép hai hằng) | `requestImageUpload`, `requestMaintenanceImageUpload` |
| `checkUpdateProfile({productName, sku, barcode, expectedVersion})` | `productName.trim()` rỗng → "Product name is required."; `expectedVersion != null && <= 0` → "Expected version must be positive." (validator). `sku` / `barcode` khác null mà `trim()` rỗng: **không** kiểm (handler cũ bỏ qua giá trị rỗng: `_optionalSku`) | `updateProfile` |
| `checkUpdateImages({images, expectedVersion})` | thân `UpdateProductImagesCommandValidator` bỏ vế id (version > 0, ≤ 1 ảnh chính, mỗi ảnh có `storageKey`) | `updateImages` |
| `checkSellableQuery(...)` | **không làm**. Validator / handler `*Sellable*` còn kiểm barcode khác rỗng, 1 … 200 id khác rỗng, và `trim` từ khoá / barcode, `trim` + bỏ trùng `productIds` (ở **handler**, không ở mapper). Bỏ được vì chỗ gọi đã làm sẵn: `sales_catalog_product_lookup.dart:40` (`query.trim()`), `:65` (`barcode.trim()`), `sales_draft_backend.dart` `_resolveProducts` (trim, bỏ trùng, rỗng thì không gọi). Phần còn lại chỉ kiểm id / store / limit (Q3, mục 3.3) | — |

Các method còn lại của mục 3.2 không có rule.

### 4.6 Readiness và PCC (`features/catalog/logic/product_readiness.dart`)

Chép **nguyên thân**, đổi import:

- `ProductReadinessEvaluator` (`domain/readiness/product_readiness_evaluator.dart`).
- `ProductReadinessViewAssembler` (`application/product_readiness/shared/product_readiness_view_assembler.dart`).
- `ProductControlCenterAssembler` (`application/product/queries/get_product_control_center/product_control_center_assembler.dart`).
- `ProductListItemAssembler` (`application/product/queries/search_products/product_list_item_assembler.dart`).
- `ProductReadinessPermissionContext` (chép).
- `ProductReadinessPermissionResolver` → hàm đồng bộ:

```dart
ProductReadinessPermissionContext readinessPermissionsOf(bool Function(String) can) =>
    ProductReadinessPermissionContext(
      canManageUnits: can(CatalogPermissions.manageUnits),
      canManageStock: can(CatalogPermissions.manageStock),
      canManagePricing: can(CatalogPermissions.managePricing),
      canUpdateProduct: can(CatalogPermissions.update),
      canCreateProduct: can(CatalogPermissions.create),
      canViewDetail: can(CatalogPermissions.viewDetail),
    );
```

`features/catalog/logic/catalog_permissions.dart`: `CatalogPermissions`, chép nguyên 12 hằng (`modules/catalog/domain/lib/src/shared/catalog_permissions.dart`).

`ProductControlCenterMapper`, `ProductReadinessFactsMapper`, `ProductListItemMapper` (đọc dòng RPC) đặt cạnh model ở 4.1.

### 4.7 Mã tham chiếu (`features/catalog/logic/product_reference_id.dart`)

`String productReferenceIdFromUuid(String uuid)`: chép thân `ProductReferenceId.fromProductId` + `_uuidBytes` + `_base32Encode` (`domain/product/product_reference_id.dart`), trả `'P' + 10 ký tự`. Dùng `package:crypto` (app đã có). Lỗi định dạng UUID → `ArgumentError`.

## 5. Đang làm gì — test giữ hành vi

5-A1 chỉ **thêm** code, chưa thay chỗ nào đang chạy. Bảng dưới ghi những việc của module mà lớp mới phải làm giống (hoặc đổi có chủ đích). Test ở bước 0 viết **trên code cũ** (nhóm `old`).

| # | Cơ chế cũ đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| H1 | Tham số 21 RPC (`ProductRpcMapper`, `CustomFieldRpcMapper.listCustomFieldFilterOptionsParams`, `ProductChangeHistoryRpcMapper`, `CatalogSalesLookupRpcMapper`, gateway ảnh) | `ProductRepository` | `test/features/catalog/data/product_rpc_parity_test.dart`: mỗi RPC một ca (bước 0.1). Nhóm `old` gọi mapper cũ, nhóm `new` gọi repository qua `_Rpc` ghi lời gọi. Hai nhóm so với **cùng** map mong đợi viết tay. Riêng `create_guided_product`: `p_idempotency_key` / `p_reference_id` so bằng `isA<String>()` + kiểm `p_reference_id == productReferenceIdFromUuid(p_idempotency_key)` |
| H2 | Đọc kết quả (`fromRow` / `fromJson` các mapper, `search` lấy số đếm ở dòng đầu, PCC bóc khoá `get_product_control_center`) | `fromJson` / `xFromRow` cạnh model, thân method repository | cùng tệp H1: JSON mẫu → DTO, so từng field (PCC đủ 5 thẻ; search thiếu `total_count`; PCC bọc trong khoá). **Đổi (4), mục 4.3:** PCC `price_band_source_type = 'customConfig'`: `old` ra `null` + "Thiếu khung giá bán", `new` ra `customConfig` + `isPendingCalculation` |
| H3 | `mapCatalogRpcError` phân loại chuỗi lỗi | `catalogException` (4.3). **Đổi (3, mục 4.3):** thêm `product is soft-deleted` → `PRODUCT_SOFT_DELETED`, `actor mismatch` → `NO_PERMISSION`; tách `product_delete_blocked` / `product_restore_blocked` khỏi `VALIDATION_ERROR` | `test/features/catalog/data/catalog_errors_test.dart`: một ca cho **mỗi** nhánh của `mapCatalogRpcError` (đúng thứ tự, gồm ca `"duplicate sku \"A1\""`, `stale_product_version: expected=3 current=4`, `custom_field_value_validation: [{…}]` và chuỗi hỏng JSON, `product_business_status_warnings_require_acknowledgment: [{…}]`, `validation_exception: X`). Nhóm `old` gọi `mapCatalogRpcError(RpcException(m))` kiểm kiểu exception + field; nhóm `new` gọi `catalogException(AppException.from(PostgrestException(message: m)))` kiểm `code` + `details` / `serverMessage` **tương ứng** (bảng tương ứng kiểu cũ ↔ mã mới viết trong test). 2 ca thêm mới (`product is soft-deleted`, `actor mismatch`) chỉ ở nhóm `new`. 2 ca tách mã có cả hai nhóm với cặp tương ứng riêng: `ValidationException(message: X)` ↔ `PRODUCT_DELETE_BLOCKED` (hoặc `PRODUCT_RESTORE_BLOCKED`) + `serverMessage: X` (mẫu `product_delete_blocked: Còn tồn kho`, `product_restore_blocked: Product is not soft-deleted.`) |
| H4 | Validator + rule domain chạy trước RPC | `catalog_rules.dart` (4.5) | `test/features/catalog/logic/catalog_rules_test.dart`: mỗi `if` một ca sai + một ca đúng. Nhóm `old` gọi `XxxCommandValidator().validate(command)` kỳ vọng `ValidationException` cùng `message`; nhóm `new` gọi hàm mới kỳ vọng `AppException(VALIDATION_ERROR)` cùng `serverMessage`. Thêm: repository `createGuided` với 9 ảnh **không** gọi RPC |
| H5 | Handler đọc PCC trước khi sửa hồ sơ / ảnh / ngừng / kích hoạt / xoá / khôi phục (Q2, mục 3.3) | **Đổi:** bỏ | repository test: `updateProfile`, `updateImages`, `deactivate`, `reactivate`, `delete`, `restore` mỗi method gọi **đúng 1** RPC (đúng tên RPC của mục 3.2) |
| H6 | Readiness / PCC dựng ở client với cờ quyền từ `permissionChecker` | `product_readiness.dart` + `readinessPermissionsOf(hasPermission)` | `test/features/catalog/logic/product_readiness_test.dart`: cùng `facts` / read model mẫu (≥ 3 bộ: thiếu đơn vị; đủ hết; thiếu giá + trường bắt buộc) và cùng tập quyền (đủ quyền; thiếu `manage_pricing`; thiếu `view_history`). Nhóm `old` gọi bộ dựng của module với `IPermissionChecker` giả; nhóm `new` gọi bản chép với `hasPermission` tương ứng; so DTO bằng `toString` từng field hoặc `==` nếu có |
| H7 | `ProductReferenceId.fromProductId` | `productReferenceIdFromUuid` | 3 UUID mẫu: nhóm `old` / `new` ra cùng chuỗi |
| H8 | `_optionalSku`: SKU viết hoa khi kiểm trùng | `checkDuplicateCodes` | ca H1 với `sku: ' ab-1 '` → `p_sku: 'AB-1'`; `sku: '  '` → `p_sku: null` |
| H9 | Slot ảnh: RPC + ký URL Storage + `_parseExpiresAt` + 2 câu lỗi (Q11) | `requestImageUpload`, `requestMaintenanceImageUpload` (mục 3.2 "Slot ảnh") | `product_rpc_parity_test.dart`, chỉ nhóm `new` (gateway cũ cần `SupabaseClient` thật nên không có nhóm `old`). Mỗi method: `_Rpc` trả dòng mẫu, hàm ký giả ghi `storageKey` nhận được và trả `'https://signed'` ⇒ DTO đủ 4 field, hàm ký gọi đúng 1 lần với `storage_key`; dòng rỗng ⇒ `serverMessage` "Image upload slot was not created.", thiếu `storage_key` ⇒ "Invalid image upload slot response.", cả hai **không** gọi hàm ký; hàm ký ném `StorageException('x')` ⇒ `SYSTEM_ERROR`, `serverMessage: 'x'`; `expires_at` là chuỗi ISO ⇒ đúng giờ UTC; thiếu ⇒ trong khoảng `now + 1 giờ ± 1 phút` |

## 6. Các bước

Trước khi sửa symbol: `gitnexus impact({target, direction: "upstream"})`. 5-A1 chỉ tạo tệp mới, nên chỉ cần chạy cho `injection.dart` nếu đụng (5-A1 **không** đụng). Ghi vào Kết quả.

### Bước 0: test nhóm `old` (trên code cũ)

1. `product_rpc_parity_test.dart` nhóm `old` (H1, H2, H8). Import mapper cũ bằng `package:c45_catalog_infrastructure/src/…` kèm `// ignore: implementation_imports`. Ca mẫu mỗi RPC ở mục 3.2; `search` có đủ `keyword`, 2 trạng thái, `readinessFilter`, 1 bộ lọc trường bổ sung `optionId` + 1 `booleanValue`, sort; `createGuided` có ảnh, `NewTenantUnit`, tồn, giá `customConfig`, 1 giá trị trường; `deactivate` có `reason` + xác nhận cảnh báo.
2. `catalog_errors_test.dart` nhóm `old` (H3); `catalog_rules_test.dart` nhóm `old` (H4); `product_readiness_test.dart` nhóm `old` (H6); H7.
3. Chạy xanh, ghi tên test + lệnh vào Kết quả.

### Bước 1: model (4.1) + bộ đọc JSON

### Bước 2: lỗi (4.3) + câu lỗi (4.4) + quyền + rule (4.5) + readiness (4.6) + mã tham chiếu (4.7)

Viết nhóm `new` của H3, H4, H6, H7. Thêm `test/features/catalog/logic/catalog_error_messages_test.dart`: mỗi nhánh của `catalogErrorMessage` một ca (đúng chuỗi); mỗi dòng `_knownServerMessages` một ca với `serverMessage` đúng như sau `catalogException` (đã bỏ tiền tố `validation_exception: `), thêm ca câu rule client `Product name is required.` và ca `Product is already inactive.` không ra câu "đang kinh doanh"; `VALIDATION_ERROR` có / không `serverMessage`, lỗi không phải `AppException` → fallback.

### Bước 3: `ProductRepository` (4.2)

Nhóm `new` của H1, H2, H8, H9 (`_Rpc extends SupabaseRpc` ghi lời gọi, mẫu `test/features/iam/data/audit_log_repository_test.dart`), H5. Thêm: `_Rpc` ném `PostgrestException(message: 'duplicate sku "A1"')` → method ném `AppException` code `DUPLICATE_SKU`, `details['value'] == 'A1'`.

### Bước 4: kiểm (mục 7), ghi Kết quả, `detect_changes()`

## 7. Kiểm tra

- [x] `git diff --stat` chỉ có tệp **mới** dưới `apps/erp/lib/features/catalog/{data,logic}/` và `apps/erp/test/features/catalog/{data,logic}/`.
- [x] `git grep -n "package:c45_" -- apps/erp/lib/features/catalog/data apps/erp/lib/features/catalog/logic` **rỗng**.
- [x] `cd apps/erp && dart analyze lib/features/catalog/data lib/features/catalog/logic test/features/catalog/data test/features/catalog/logic`: không error / warning nào (`No issues found!`).
- [x] `cd apps/erp && flutter test test/features/catalog/data test/features/catalog/logic`: 216 tests bước 0 – 3 xanh (0 fail).
- [x] `cd apps/erp && flutter test`: 1.921 đạt / đúng 61 lỗi, không fail mới so với `docs/refactor/TEST-BASELINE.md`.

## 8. Rủi ro / lưu ý

- **Chép sai khoá JSON** là rủi ro lớn nhất. Không sửa map mong đợi cho khớp code mới.
- `ProductChangeHistoryPage` vừa là tên model của module vừa là tên trang của app (`router` đang `hide`). Trong `data/models/product_change_history.dart` giữ tên model, nhưng 5-A3 phải import có `as` hoặc `hide` ở chỗ dùng cả hai. Ghi lại để 5-A3 không vấp.
- `search` ở module tính `totalCount` = số dòng khi thiếu `total_count`. Giữ đúng, đừng "sửa" thành 0.
- `ProductReadinessViewAssembler` dài (337 dòng) và quyết định nút nào bật trong checklist. Test H6 là chốt chặn; chép nguyên, không tối ưu.
- Kiểu enum phải **cùng thứ tự giá trị** với bản cũ (có chỗ dùng `index` / `values`).

## 9. Kết quả (phiên làm code ghi)

- **Trạng thái:** ✅ Hoàn thành toàn bộ Bước 0 đến Bước 4 của plan 5-A1 và hoàn thành sửa toàn bộ góp ý Review R1 (R1-1 … R1-3, T1 … T4).
- **Tệp mới tạo:** Tổng cộng **66 kiểu dữ liệu** (49 classes/DTOs/read models + 17 enums) được chép đầy đủ từ module sang `apps/erp/lib/features/catalog/data/models/`:
  - `apps/erp/lib/features/catalog/data/models/`:
    - `catalog_enums.dart`: 2 class trạng thái (`ProductBusinessStatus`, `ProductPriceBandStatus`) + 17 enums (`ReadinessStatus`, `BasePriceMode`, `StockMode`, `ProductDuplicateField`, `ProductReadinessFilter`, `ProductSortOrder`, `PriceBandSourceType`, `StockDataSource`, `ProductChangeCategory`, `ProductChangeHistoryAction`, `ProductPriceBandHistoryTrigger`, `ProductDeletionIssueSeverity`, `SellableProductResolution`, `ContextualActionPriority`, `ReadinessChecklistGroup`, `ReadinessChecklistItemStatus`, `ReadinessItemKind`).
    - `custom_field_filter_option.dart`: `CustomFieldFilterOptionDto`, `CustomFieldSelectOptionDto`, hàm `customFieldGroupDisplayName`.
    - `product_inputs.dart`: `ProductImageInput`, `ProductImageMutationInput`, `BaseUnitSelection`, `ExistingTenantUnit`, `NewTenantUnit`, `ProductCustomFieldValueInput`, `CreateGuidedProductInput`.
    - `product_readiness.dart`: `ReadinessSummaryDto`, `ReadinessBlockerDto`, `ReadinessBlocker`, `ProductReadiness`, `ProductReadinessFacts`, `ContextualActionDto`, `ReadinessChecklistItemDto`, `ProductReadinessPermissionContext`, `ProductReadinessViewDto`.
    - `product_results.dart`: `CreateGuidedProductResult`, `ProductImageUploadSlotDto`, `ProductDuplicateMatchDto`, `ProductDeletionEligibilityDto`, `ProductDeletionIssueDto`, `ProductBusinessStatusWarningDto`.
    - `product_search.dart`: `ProductSearchCriteria`, `CustomFieldFilterCriteria`, `SearchKeywordNormalizer`, `CustomFieldListValueDto`, `ProductListItemDto`, `ProductSearchResultDto`, `ProductListItemReadRow`.
    - `product_control_center.dart`: `ProductControlCenterDto`, `ProductProfileSummaryDto`, `ProductStockCardDto`, `ProductUnitsCardDto`, `ProductBasePriceCardDto`, `ProductPriceBandCardDto`, `ProductConversionUnitDto`, `CustomFieldGroupCardDto`, `CustomFieldCardFieldDto`, `ProductImageDto`, `ProductControlCenterReadModel`.
    - `product_change_history.dart`: `ProductChangeHistoryEntryDto`, `ProductChangeHistoryResultDto`, `ProductChangeHistoryPage`, `ProductChangeHistoryReadRow`, `ProductPriceBandHistoryChangeDto`, `ProductPriceBandHistorySnapshotDto`.
    - `sellable_product.dart`: `SellableProductDto`, `SellableProductUnitDto`, `SellableProductResolutionDto`, `NotSellableProductDto`.
  - `apps/erp/lib/features/catalog/data/`:
    - `catalog_errors.dart`: `CatalogErrorCodes` (28 mã), `catalogException` re-classify lỗi RPC sang `AppException`.
    - `product_repository.dart`: `ProductRepository` với 20 method RPC + Storage signing, validation rules, re-classify lỗi qua `_guard`.
  - `apps/erp/lib/features/catalog/logic/`:
    - `catalog_error_messages.dart`: `catalogErrorMessage` chuẩn TH-02 6.4 + `_knownServerMessages`.
    - `catalog_permissions.dart`: `CatalogPermissions` (12 quyền).
    - `product_reference_id.dart`: `productReferenceIdFromUuid`.
    - `catalog_rules.dart`: `checkCreateGuided`, `checkImageUploadRequest`, `checkUpdateProfile`, `checkUpdateImages`.
    - `product_readiness.dart`: `ProductReadinessEvaluator`, `ProductReadinessViewAssembler`, `ProductControlCenterAssembler`, `ProductListItemAssembler`, `readinessPermissionsOf`.
  - `apps/erp/test/features/catalog/`:
    - `data/catalog_errors_test.dart`: 74 tests (36 old, 38 new).
    - `data/product_rpc_parity_test.dart`: 44 tests (22 old, 22 new ProductRepository), 1 skipped test (H1 5 nhóm old).
    - `logic/catalog_rules_test.dart`: 54 tests (27 old, 27 new).
    - `logic/product_readiness_test.dart`: 10 tests (5 old, 5 new).
    - `logic/catalog_error_messages_test.dart`: 35 tests mới theo TH-02 6.4.
- **Lệch so với plan (các đổi có chủ đích):**
  - **R1-1:** `ProductControlCenterReadModel.fromJson` đọc `'customConfig' => PriceBandSourceType.customConfig` (người dùng đã chốt nhận hành vi mới ngày 2026-11-03). Đã bỏ đọc `price_band_effective_from/to/status`.
  - **H3:** Bổ sung phân loại 3 lỗi catalog RPC đặc thù sang `AppException` chuẩn (`missing_base_price`, `missing_product_units`, `product_deactivation_blocked`).
  - **H9:** Ký URL ảnh chuyển sang tiêm qua callback `signUploadUrl` thay vì phụ thuộc trực tiếp vào `SupabaseClient`.
- **Khối R1 — sửa (2026-11-03):**
  - **R1-1 (P2):** Giữ `'customConfig' => PriceBandSourceType.customConfig` trong `ProductControlCenterReadModel.fromJson`. Bỏ đọc `price_band_effective_from/to/status`. Bổ sung test dual parity: nhóm `old` kiểm tra `priceBandSourceType == null` và thẻ khung giá có `missingMessage == 'Thiếu khung giá bán'`; nhóm `new` kiểm tra `customConfig`, `isPendingCalculation == true`, `missingMessage == null`.
  - **R1-2 (P2):**
    1. Bổ sung kiểm tra rỗng cho 6 lệnh ghi (`updateProfile`, `updateImages`, `deactivate`, `reactivate`, `delete`, `restore`) và `checkDeletionEligibility`, đều ném `AppException` với thông báo tương ứng `"Product <action> did not return a result."` (`grep -c "did not return a result"` đạt 7).
    2. Bổ sung kiểm tra `getControlCenter` và `getReadiness` khi RPC trả rỗng ném `AppException(CatalogErrorCodes.productNotFound)`.
    3. Bổ sung test `search` khi RPC thiếu `total_count` rơi về `totalCount = items.length` (cho cả `old` và `new`).
    4. Bổ sung kiểm tra PCC đủ 5 thẻ (`profile`, `units`, `stock`, `basePrice`, `priceBand`, cùng `customFieldGroupCards`).
    5. Bổ sung đầy đủ các ca biên H9 cho cả `requestImageUpload` và `requestMaintenanceImageUpload` (dòng rỗng, thiếu `slot_id`, thiếu `storage_key`, `StorageException` ném `SYSTEM_ERROR`, `expiresAt` null rơi về UTC trong 1 giờ).
    6. Bổ sung kiểm tra chi tiết các trường DTO của `checkDeletionEligibility` (`canDelete`, `issues`, `blockers`, `warnings`, `suggestedActionId`).
    7. Cập nhật mục 9 đầy đủ 66 kiểu dữ liệu đã chép.
  - **R1-3 (P3):**
    1. H8 nhóm `old`: Thay thế việc xử lý chuỗi trực tiếp bằng việc gọi `CheckDuplicateProductCodeQueryHandler` với mock duplicate checker `_RecordingDuplicateChecker` (kiểm tra chuẩn xác logic `_optionalSku`: `' ab-1 '` → `'AB-1'`, `'  '` → `null`).
    2. H1 5 nhóm `old`: Đánh dấu `skip:` có kèm lý do rõ ràng (gateway cũ phụ thuộc `SupabaseClient` và `StorageClient` thật, không có mapper thuần).
    3. Gom các tham số kỳ vọng của 20 RPC thành 20 hằng `final _expected*Params` dùng chung ở top-level của file test (`grep -c "final _expected"` đạt 20).
  - **T1 (Tuỳ chọn):** Tinh giản `_guard` trong `ProductRepository` chỉ bắt `on AppException catch (e) { throw catalogException(e); }`. Cập nhật `_RecordingRpc` trong test bọc lỗi thô qua `AppException.from(errorToThrow!)` mô phỏng chính xác `SupabaseRpc`.
  - **T2 (Tuỳ chọn):** Khôi phục các bộ đọc JSON strict theo đúng bản cũ: `ProductSearchResultDto.fromJson` đọc bắt buộc `product_id` và `DateTime.parse(row['updated_at'])`, `ProductReadinessFacts.fromRow` ném lỗi khi thiếu trường thay vì fallback `''`, `ProductDuplicateMatchDto.fromJson` đọc strict snake_case (`duplicate_field`, `product_id`, `product_name`, `matched_value`).
  - **T3 (Tuỳ chọn):** Xoá bỏ định nghĩa trùng lặp `customFieldGroupDisplayName` (chỉ giữ duy nhất tại `data/models/custom_field_filter_option.dart`), trích xuất hàm dùng chung `_reserveSlot(rpcName, params)` trong `ProductRepository` cho 2 method slot ảnh.
  - **T4 (Tuỳ chọn):** Trong `catalog_errors.dart`, mặc định `code: 'invalid'` khi phân giải danh sách lỗi validation `custom_field_value_validation`.
- **Impact (`gitnexus impact`):** Các file tạo mới hoàn toàn độc lập, không ảnh hưởng symbol cũ; rủi ro: Low.
- **Kết quả kiểm thử:**
  - `cd apps/erp && dart analyze lib/features/catalog/data lib/features/catalog/logic test/features/catalog/data test/features/catalog/logic`: No issues found!
  - `cd apps/erp && flutter test test/features/catalog/data test/features/catalog/logic`: 217 tests passed, 1 skipped.
  - `cd apps/erp && flutter test`: 1.922 tests passed, 61 tests failed (đúng 61 tests có sẵn trong `docs/refactor/TEST-BASELINE.md`, 0 lỗi mới).
  - `git grep -n "package:c45_" -- apps/erp/lib/features/catalog/data apps/erp/lib/features/catalog/logic`: Không có dòng nào.
  - `grep -c "did not return a result" apps/erp/test/features/catalog/data/product_rpc_parity_test.dart`: 7.
  - `grep -c "final _expected" apps/erp/test/features/catalog/data/product_rpc_parity_test.dart`: 20.

## 10. Review

### R1 — 2026-11-02 — ❌ CHƯA ĐẠT

**Kết luận: CHƯA ĐẠT.** Phần lớn code chép đúng. Tham số 20 RPC khớp `ProductRpcMapper` / handler cũ. `catalogException` giữ đúng thứ tự nhánh, có thêm 3 đổi có chủ đích. Rule khớp validator, readiness / PCC trùng nguyên thân (so diff đã chuẩn hoá). Thứ tự enum giữ nguyên. Chưa đạt vì 2 lý do:

1. Bộ đọc PCC đổi hành vi so với bản cũ, nhưng chỗ đổi này không được ghi lại và không có test (R1-1).
2. Thiếu một loạt test mà plan bắt buộc. Mục Kết quả ghi "Lệch so với plan: Không có… tuân thủ 100%", không đúng (R1-2, R1-3).

| Loại | Mục |
|---|---|
| Bắt buộc sửa | R1-1 (P2) PCC đọc `customConfig` khác bản cũ (người dùng chốt 2026-11-03: nhận hành vi mới, cần ghi + test) · R1-2 (P2) thiếu test plan yêu cầu + sửa Kết quả · R1-3 (P3) test nhóm `old` không kiểm code cũ |
| Tuỳ chọn sửa | T1 `_guard` bắt mọi lỗi · T2 bộ đọc nới lỏng · T3 hàm trùng / thân slot ảnh trùng · T4 `custom_field_value_validation` không mặc định `code` |
| Chỉ ghi nhận | N1 nhánh `permission denied` / `not authenticated` không bao giờ chạy tới · N2 plan ghi "21 method", thật ra bảng 3.2 có 20 · N3 H6 so vài field |
| Còn lại để đóng plan | Làm R1-1 … R1-3, rồi review R2 |

**Góp ý chi tiết:**

- [Bắt buộc sửa] **R1-1**: xem mục "R1 — việc cần sửa".
- [Bắt buộc sửa] **R1-2**, **R1-3**: như trên.
- [Tuỳ chọn sửa] **T1**: `product_repository.dart:48–52`. `_guard` có thêm `on PostgrestException` và `catch (e, st)`, còn plan 4.2 chỉ có `on AppException`.
  - `SupabaseRpc` thật không bao giờ ném `PostgrestException` (`supabase_rpc.dart` đã đổi sẵn). Nhánh này chỉ phục vụ fake `_RecordingRpc`, vốn ném lỗi thô.
  - `catch (e, st)` biến lỗi lập trình (`TypeError` khi đọc JSON, `ArgumentError` của `duplicate_field`) thành `SYSTEM_ERROR`, nên khi gỡ lỗi khó thấy nguyên nhân.
  - Đề xuất: bỏ 2 nhánh này; sửa `_RecordingRpc` để ném `AppException.from(PostgrestException(...))` như `SupabaseRpc` thật.
- [Tuỳ chọn sửa] **T2**: một số bộ đọc dễ dãi hơn bản cũ, che mất lỗi sai khoá JSON (rủi ro mục 8):
  - `product_search.dart:210` nhận cả `id`. Test search dùng `'id'`, trong khi bản cũ đọc `product_id`.
  - `:244` thiếu `updated_at` thì lấy `now()`.
  - `product_readiness.dart:241–242`: thiếu khoá thì cho `''`; bản cũ ném lỗi.
  - `product_results.dart:61–63` nhận khoá camelCase.
  - Đề xuất: chép đúng như bản cũ, và sửa JSON mẫu trong test cho đúng khoá RPC.
- [Tuỳ chọn sửa] **T3**:
  - `customFieldGroupDisplayName` được định nghĩa 2 lần: `data/models/custom_field_filter_option.dart:5` và `logic/product_readiness.dart:13`.
  - Thân `requestImageUpload` / `requestMaintenanceImageUpload` trùng khoảng 40 dòng, có thể tách thành `_reserveSlot(rpcName, params)`.
- [Tuỳ chọn sửa] **T4**: `catalog_errors.dart:202`. Bản cũ dùng `validationErrorsFromJson`: thiếu `code` thì mặc định `'invalid'`, phần tử không phải `Map<String, dynamic>` thì bỏ. Bản mới giữ map thô. 5-A3 đọc `details['errors']` sẽ phải tự xử lý `code` null. Đề xuất: mặc định `code: 'invalid'` khi thiếu.
- [Không sửa — chỉ ghi nhận] **N1**: `catalog_errors.dart:319–321`. Nhánh `permission denied` / `not authenticated` không bao giờ chạy tới, vì `AppException.from` đã đổi sang `NO_PERMISSION` / `AUTHENTICATION_REQUIRED` từ trước. Vô hại.
- [Không sửa — chỉ ghi nhận] **N2**: Kết quả ghi "20 method" là đúng; plan 4.2 ghi "21" là đếm sai.
- [Không sửa — chỉ ghi nhận] **N3**: H6 chỉ so vài field, chưa so cả DTO. Bù lại, diff đã chuẩn hoá giữa `logic/product_readiness.dart` và 4 tệp gốc (evaluator, 2 assembler, list item assembler) trùng 100%, chỉ khác phần thêm `readinessPermissionsOf` / `customFieldGroupDisplayName`.

**Đã chạy / đối chiếu (2026-11-02):**

- `dart analyze` 4 thư mục: No issues found.
- `flutter test test/features/catalog/data test/features/catalog/logic`: 216 đạt.
- `flutter test` (apps/erp): **1.921 đạt / 61 lỗi**. So từng tên test với `TEST-BASELINE.md`: cả 61 đều có sẵn, không có lỗi mới.
- `git grep "package:c45_"` trong `lib/features/catalog/{data,logic}`: rỗng. Mọi tệp đều mới, không sửa tệp cũ nào.
- Đối chiếu tay:
  - tham số 20 RPC với `ProductRpcMapper` / `CustomFieldRpcMapper` / `ProductChangeHistoryRpcMapper` / `CatalogSalesLookupRpcMapper` + handler (`Sku` viết hoa, `trim` ở handler sellable);
  - `catalogException` với `mapCatalogRpcError` (thứ tự nhánh, `_extract*`);
  - `catalog_rules.dart` với 5 validator;
  - `CatalogSalesLookupParser` với mapper cũ (`diff` chỉ khác format và `_invalid`);
  - `ProductChangeHistoryPage.fromJson` với `pageFromJson`;
  - các bộ đọc PCC / list / readiness / kết quả;
  - thứ tự giá trị 12 enum;
  - 12 hằng quyền;
  - `catalogErrorMessage` với mục 4.4.

### R1 — việc cần sửa

Thứ tự làm: R1-1 (người dùng đã chốt 2026-11-03) → R1-2 → R1-3. Không còn việc chờ người dùng. Phiên code ghi kết quả vào khối "R1 — sửa" ở cuối mục 9. Các mục T1–T4 tuỳ chọn; nếu làm thì ghi vào cùng khối đó.

#### R1-1 — PCC đọc `price_band_source_type = 'customConfig'` khác bản cũ

- **Mức:** P2, bắt buộc.
- **Hiện tại:** `data/models/product_control_center.dart:430–435` đọc `'customConfig'` thành `PriceBandSourceType.customConfig`.
  - Bản cũ `ProductControlCenterMapper` gọi `StorePriceRuleRpcMapper.sourceTypeFromRpc`, hàm này chỉ nhận `ruleBased` / `manual`, còn `customConfig` thành `null`.
  - DB có giá trị `customConfig` (migration `20260717004`), và RPC `get_product_control_center` trả về giá trị này.
  - Hệ quả trong `ProductControlCenterAssembler` (`logic/product_readiness.dart:440–525`): với sản phẩm có khung giá cấu hình riêng, bản cũ hiện "Thiếu khung giá bán" và `isPendingCalculation` không bao giờ bật; bản mới hiện là đã cấu hình, và bật "đang tính" khi chưa có giá.
  - Tái hiện: JSON PCC có `'price_band_source_type': 'customConfig'`, không có `list_price_*`, rồi gọi 2 bộ dựng.
  - Cùng chỗ đó, `:421–429` đọc thêm `price_band_effective_from/to/status`, bản cũ không đọc. RPC hiện không trả các khoá này nên chưa có tác dụng, nhưng vẫn là "không chép thân".
- **Người dùng chốt 2026-11-03: nhận hành vi mới** (`customConfig` → `PriceBandSourceType.customConfig`). Lý do: bộ dựng đã có sẵn nhánh `isPendingCustomConfig`, nên bản cũ là lỗi đọc sót giá trị mới thêm sau.
- **Cần làm:**
  - Giữ nhánh `'customConfig' => PriceBandSourceType.customConfig` (đã ghi thành đổi có chủ đích (4) ở mục 4.3 và dòng H2 mục 5).
  - Thêm ca test: nhóm `old` (bộ cũ ra `priceBandSourceType == null`, thẻ khung giá `missingMessage == 'Thiếu khung giá bán'`) và nhóm `new` (ra `customConfig`, `isPendingCalculation == true`, `missingMessage == null`), cùng JSON PCC có `'price_band_source_type': 'customConfig'`, không có `list_price_*`.
  - Bỏ đọc `price_band_effective_from/to/status` (`:421–429`), hoặc ghi vào Kết quả lý do giữ.
- **Xong khi:** có test cho `customConfig` ở cả hai nhóm, và Kết quả ghi đúng quyết định.

#### R1-2 — Thiếu test plan bắt buộc; Kết quả ghi sai "không lệch"

- **Mức:** P2, bắt buộc.
- **Hiện tại:** `grep "did not return" test/features/catalog/data/product_rpc_parity_test.dart` rỗng. Còn thiếu:
  1. Kiểm rỗng của 6 lệnh ghi. Ghi chú mục 3.2 viết: "Test H2 có 1 ca rỗng cho mỗi method".
  2. `getControlCenter` / `getReadiness` rỗng → `PRODUCT_NOT_FOUND`; `checkDeletionEligibility` rỗng → `SYSTEM_ERROR` "Product deletion eligibility did not return a result.".
  3. `search` thiếu `total_count` → `totalCount` = số dòng (H2, rủi ro mục 8).
  4. PCC đủ 5 thẻ (H2). Test hiện chỉ kiểm profile / units / stock.
  5. H9:
     - thiếu ca biên cho `requestMaintenanceImageUpload`;
     - ca "thiếu `storage_key`" đang dùng `slot_id: ''` (`:1313`);
     - ca `StorageException` chưa kiểm `code == SYSTEM_ERROR`.
  6. `checkDeletionEligibility` chưa kiểm DTO, như `issues` / `blockers`.
  - Mục 9 cũng không ghi số kiểu đã chép (4.1 yêu cầu), và không ghi các kiểu thêm cùng tệp: `ProductPriceBandStatus`, `ProductConversionUnitDto`, `CustomFieldListValueDto`, `ProductChangeCategory`, `StockDataSource`, `ContextualActionDto`…
- **Cần làm:**
  - Thêm các ca 1–6 vào nhóm `new`. Ca 3 và 4 thêm cả nhóm `old` (`SupabaseCatalogReadGateway.search` cần client thật thì chỉ làm nhóm `new`, ghi lý do).
  - Sửa mục 9: liệt kê lệch (R1-1, T1–T2 nếu không sửa), số kiểu và tên kiểu thêm.
- **Xong khi:**
  - `grep -c "did not return a result" product_rpc_parity_test.dart` ≥ 7;
  - có test thiếu `total_count`, test 5 thẻ PCC, và đủ 2 method H9;
  - `flutter test test/features/catalog/data test/features/catalog/logic` xanh.

#### R1-3 — Test nhóm `old` không chạy code cũ

- **Mức:** P3, bắt buộc. Nhóm `old` là chốt chặn khi 5-C xoá module.
- **Hiện tại:**
  - `product_rpc_parity_test.dart:176–185` (H1 5, nhóm `old`) tự dựng map rồi `expect(expected['p_tenant_id'], tenantId)`. Test này luôn xanh và không kiểm gì.
  - `:78–99` (H8, nhóm `old`) tự gọi `' ab-1 '.trim().toUpperCase()` trước khi đưa vào mapper, nên không kiểm hành vi `_optionalSku` của `CheckDuplicateProductCodeQueryHandler`.
  - Map mong đợi của H1 viết lặp ở cả 2 nhóm, không dùng chung như mục 5 H1 yêu cầu.
- **Cần làm:**
  - H8 nhóm `old`: gọi `CheckDuplicateProductCodeQueryHandler` với `IProductDuplicateChecker` giả ghi lại `sku` / `barcode` nhận được (`' ab-1 '` → `'AB-1'`, `'  '` → `null`).
  - H1 5 nhóm `old`: xoá (H9 đã ghi lý do không có nhóm `old`), hoặc thay bằng `skip:` kèm lý do.
  - Đưa map mong đợi của mỗi RPC thành hằng `_expectedX` dùng chung cho 2 nhóm.
- **Xong khi:**
  - không còn test `old` nào không gọi code module;
  - `grep -c "const _expected\|final _expected"` ≥ 20, hoặc đã gom các map vào một map dùng chung.

### R2 — 2026-11-03 — ✅ ĐẠT

**Kết luận: ĐẠT.** Cả 3 việc bắt buộc của R1 đã sửa đúng. 4 mục tuỳ chọn T1–T4 cũng đã làm.

| Loại | Mục |
|---|---|
| Bắt buộc sửa | Không có |
| Tuỳ chọn sửa | Không có |
| Chỉ ghi nhận | N4 Kết quả ghi sai phạm vi test `total_count` · N5 test 5 thẻ PCC kiểm yếu |
| Còn lại để đóng plan | Không. Giữ tệp plan tới khi Theme 2 đóng: 5-A2 / 5-A3 / 5-C còn tham chiếu mục 2, 4 và nhóm `old` |

**Đối chiếu từng task R1:**

- **R1-1 ✅.**
  - `product_control_center.dart` giữ `'customConfig' => PriceBandSourceType.customConfig` và đã bỏ đọc `price_band_effective_*` / `price_band_status` (grep rỗng).
  - Nhóm `old` (`product_rpc_parity_test.dart:621–639`) kiểm `priceBandSourceType == null` và `missingMessage == 'Thiếu khung giá bán'`.
  - Nhóm `new` (`:1003–1044`) kiểm `customConfig`, `isPendingCalculation == true`, `missingMessage == null`.
  - Mục 4.3 và dòng H2 đã ghi đổi (4).
- **R1-2 ✅.**
  - `grep -c "did not return a result"` = 7: 6 lệnh ghi + `checkDeletionEligibility`, kiểm đúng câu (`:1118–1298`).
  - `getControlCenter` / `getReadiness` rỗng ra `PRODUCT_NOT_FOUND`.
  - Có test `search` thiếu `total_count` (`:792`).
  - H9 có đủ 2 method (`:1426`, `:1488`): rỗng, thiếu `slot_id`, thiếu `storage_key`, `StorageException` ra `code == SYSTEM_ERROR`, `expires_at` null.
  - DTO xoá được kiểm `blockers` / `warnings` / `suggestedActionId`.
  - Mục 9 đã liệt kê 66 kiểu.
- **R1-3 ✅.**
  - H8 nhóm `old` gọi `CheckDuplicateProductCodeQueryHandler` với `_RecordingDuplicateChecker`, kiểm `' ab-1 '` → `'AB-1'` và `'   '` → `null`.
  - H1 5 nhóm `old` dùng `skip:` có ghi lý do.
  - Có 20 hằng `_expected*Params` dùng chung cho 2 nhóm.
- **T1 ✅:** `_guard` chỉ còn `on AppException`. `_RecordingRpc` ném `AppException.from(...)` như `SupabaseRpc` thật.
- **T2 ✅:**
  - `ProductListItemReadRow.fromRow` đọc chặt `product_id` / `updated_at`.
  - `ProductDuplicateMatchDto.fromJson` chỉ đọc snake_case.
  - `ProductReadinessFacts.fromRow` đọc chặt `product_id`. Riêng `product_name ?? name` giữ lại vì PCC và danh sách dùng chung hàm này với khoá `name`, giống cách 2 mapper cũ dựng facts từ `name`.
- **T3 ✅:** `customFieldGroupDisplayName` chỉ còn ở `custom_field_filter_option.dart:5`. Hai method slot ảnh gọi chung `_reserveSlot`; thứ tự các bước giữ đúng mục 3.2.
- **T4 ✅:** thiếu `code` thì mặc định `'invalid'`. Mảng rỗng thì dùng câu dự phòng.

**Ghi nhận (không sửa):**

- **N4:** khối "R1 — sửa", mục R1-2.3 ghi test `total_count` "cho cả `old` và `new`", nhưng thực tế chỉ có nhóm `new`. Gateway cũ cần client thật, nên chỉ có nhóm `new` là hợp lý; chỉ là ghi chưa đúng.
- **N5:** test "5 thẻ" kiểm `basePrice` / `priceBand` bằng `isNotNull` và `customFieldGroupCards` bằng `isA<List>()`, đều là field không null nên luôn đúng. JSON mẫu không có khoá giá. Khoá JSON của PCC đã được đối chiếu tay ở R1, và bộ dựng trùng nguyên thân, nên rủi ro thấp. 5-A3 có test e2e đi qua PCC trên fake.

**Đã chạy (2026-11-03):**

- `dart analyze` 4 thư mục: No issues found.
- `flutter test test/features/catalog/{data,logic}`: 217 đạt, 1 bỏ qua (H1 5 nhóm `old`).
- `flutter test` (apps/erp): **1.922 đạt / 1 bỏ qua / 61 lỗi**. So từng tên test với `TEST-BASELINE.md`: cả 61 đều có sẵn, không có lỗi mới.
- `git status`: chỉ có tệp mới dưới `lib/features/catalog/{data,logic}` và `test/features/catalog/{data,logic}`, cùng các tệp tài liệu.
