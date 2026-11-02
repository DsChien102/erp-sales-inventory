# 5-A1 — Lớp dữ liệu catalog: model, lỗi, rule, readiness, `ProductRepository`

> Theme 2 (mã cũ P5) · Bước (a) chuyển kiến trúc, phần **dữ liệu** · Gồm việc 5.1 (phần data) (PLAN.md mục Theme 2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01; rà lại theo code 2026-11-02: thêm Q11 ký URL ảnh, kiểm rỗng 6 lệnh ghi, slot ảnh, câu 6.4 cho `validation_exception`, 4 handler đọc trước, 3 đổi có chủ đích ở H3, H9) | Làm ⬜ | Review ⬜
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

Chép class / enum / extension từ module, **giữ nguyên** tên, field, constructor, giá trị mặc định, `toWire` / `fromWire`, `props` (nếu có `Equatable`). Chỉ đổi import. Kiểu từ `vet45_shared_domain` (`ValueObject`) thì bỏ kế thừa, giữ `==` / `hashCode` theo giá trị (như `PersonTitle` ở 4-A).

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
| H2 | Đọc kết quả (`fromRow` / `fromJson` các mapper, `search` lấy số đếm ở dòng đầu, PCC bóc khoá `get_product_control_center`) | `fromJson` / `xFromRow` cạnh model, thân method repository | cùng tệp H1: JSON mẫu → DTO, so từng field (PCC đủ 5 thẻ; search thiếu `total_count`; PCC bọc trong khoá) |
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

1. `product_rpc_parity_test.dart` nhóm `old` (H1, H2, H8). Import mapper cũ bằng `package:vet45_catalog_infrastructure/src/…` kèm `// ignore: implementation_imports`. Ca mẫu mỗi RPC ở mục 3.2; `search` có đủ `keyword`, 2 trạng thái, `readinessFilter`, 1 bộ lọc trường bổ sung `optionId` + 1 `booleanValue`, sort; `createGuided` có ảnh, `NewTenantUnit`, tồn, giá `customConfig`, 1 giá trị trường; `deactivate` có `reason` + xác nhận cảnh báo.
2. `catalog_errors_test.dart` nhóm `old` (H3); `catalog_rules_test.dart` nhóm `old` (H4); `product_readiness_test.dart` nhóm `old` (H6); H7.
3. Chạy xanh, ghi tên test + lệnh vào Kết quả.

### Bước 1: model (4.1) + bộ đọc JSON

### Bước 2: lỗi (4.3) + câu lỗi (4.4) + quyền + rule (4.5) + readiness (4.6) + mã tham chiếu (4.7)

Viết nhóm `new` của H3, H4, H6, H7. Thêm `test/features/catalog/logic/catalog_error_messages_test.dart`: mỗi nhánh của `catalogErrorMessage` một ca (đúng chuỗi); mỗi dòng `_knownServerMessages` một ca với `serverMessage` đúng như sau `catalogException` (đã bỏ tiền tố `validation_exception: `), thêm ca câu rule client `Product name is required.` và ca `Product is already inactive.` không ra câu "đang kinh doanh"; `VALIDATION_ERROR` có / không `serverMessage`, lỗi không phải `AppException` → fallback.

### Bước 3: `ProductRepository` (4.2)

Nhóm `new` của H1, H2, H8, H9 (`_Rpc extends SupabaseRpc` ghi lời gọi, mẫu `test/features/iam/data/audit_log_repository_test.dart`), H5. Thêm: `_Rpc` ném `PostgrestException(message: 'duplicate sku "A1"')` → method ném `AppException` code `DUPLICATE_SKU`, `details['value'] == 'A1'`.

### Bước 4: kiểm (mục 7), ghi Kết quả, `detect_changes()`

## 7. Kiểm tra

- [ ] `git diff --stat` chỉ có tệp **mới** dưới `apps/erp/lib/features/catalog/{data,logic}/` và `apps/erp/test/features/catalog/{data,logic}/`.
- [ ] `git grep -n "package:vet45_" -- apps/erp/lib/features/catalog/data apps/erp/lib/features/catalog/logic` **rỗng**.
- [ ] `cd apps/erp && dart analyze lib test`: không error / warning mới (ghi số trước / sau).
- [ ] `cd apps/erp && flutter test test/features/catalog`: mọi test bước 0 – 3 xanh, test cũ không đổi.
- [ ] `cd apps/erp && flutter test`: không fail mới so với `docs/refactor/TEST-BASELINE.md` + fail đã ghi ở W-2.

## 8. Rủi ro / lưu ý

- **Chép sai khoá JSON** là rủi ro lớn nhất. Không sửa map mong đợi cho khớp code mới.
- `ProductChangeHistoryPage` vừa là tên model của module vừa là tên trang của app (`router` đang `hide`). Trong `data/models/product_change_history.dart` giữ tên model, nhưng 5-A3 phải import có `as` hoặc `hide` ở chỗ dùng cả hai. Ghi lại để 5-A3 không vấp.
- `search` ở module tính `totalCount` = số dòng khi thiếu `total_count`. Giữ đúng, đừng "sửa" thành 0.
- `ProductReadinessViewAssembler` dài (337 dòng) và quyết định nút nào bật trong checklist. Test H6 là chốt chặn; chép nguyên, không tối ưu.
- Kiểu enum phải **cùng thứ tự giá trị** với bản cũ (có chỗ dùng `index` / `values`).

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi bước** ghi ngay, không dồn cuối. Mẫu cho mỗi bước:
> - Trạng thái: ✅ / 🔄 dở (ghi tới đâu) / ⏭ (lý do)
> - Tệp:dòng đã đổi
> - Lệch so với plan + lý do
> - Test thêm / sửa (tên test); test đổi kỳ vọng có chủ đích (dòng H nào)
> - Impact (`gitnexus impact`): symbol, số caller, mức rủi ro
> - Ghi chú cho review
>
> Bước cuối: lệnh đã chạy, số pass / fail, tên test fail đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes()`.

## 10. Review

<!-- Phiên review ghi -->
