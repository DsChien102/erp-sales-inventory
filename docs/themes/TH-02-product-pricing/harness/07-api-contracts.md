# TH-02 — API contracts (FE ↔ BE)

Source of truth giữa presentation và application layer. Types live in `modules/catalog/application/`. RPC mapping: [03-architecture-and-flows.md](03-architecture-and-flows.md).

Facade: `ICatalogModule` (`modules/catalog/application/lib/src/contracts/i_catalog_module.dart`).

**Access control:** commands/queries dùng `@RequiresPermission(CatalogPermissions.*)` + `@RequiresTenant()`; codegen emit `catalog_access_metadata.g.dart` — mirror [modules/partner/README.md](../../../../modules/partner/README.md).

**Quy tắc:** FE fake theo contract này — không fake RPC trực tiếp. Scenario ids dùng trong `FakeCatalogModule` (`modules/catalog/application/lib/src/testing/fake_catalog_module.dart`, import `package:vet45_catalog_application/testing.dart`).

---

## Epic-01 / US-01 — Ghi nhận hồ sơ sản phẩm mới

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `CreateProductCommand` | tenantId, actorId, internalName, commercialName?, sku?, barcode?, baseUnitName, initialStock?, images[], medicalInfo?, description? | `CreateProductResult` (productId) | Validation, PermissionDenied, DuplicateSku, DuplicateBarcode |
| `CheckDuplicateProductCodeQuery` | tenantId, sku?, barcode?, excludeProductId? | `List<ProductDuplicateMatchDto>` | PermissionDenied |

Package: `vet45_catalog_application` — `create_product/`, `check_duplicate/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Create | `catalog.create_product` |
| Dup check | `catalog.check_duplicate` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `create_save_ok` | CreateProductCommand valid | `CreateProductResult(productId: 'product-new-1')` |
| `create_dup_sku` | sku trùng tenant | DuplicateSku |
| `create_dup_barcode` | barcode trùng tenant | DuplicateBarcode |
| `create_validation_error` | thiếu tên hoặc base unit | throws validation error |
| `create_permission_denied` | no catalog.product.create | PermissionDenied |
| `create_with_stock` | initialStock=-5 | success, stock=-5 |
| `create_no_images` | no images | success, no images |

### Parallel notes

- FE có thể fake: **yes** (sau CONTRACT)
- E2E prerequisite: —

---

## Epic-01 / US-02 — Tra cứu và xem hồ sơ sản phẩm

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SearchProductsQuery` | tenantId, ProductSearchCriteria (keyword, status, stockStatus), limit, offset | `ProductSearchResultDto` (items, totalCount) | PermissionDenied |
| `GetProductDetailQuery` | tenantId, productId | `ProductDetailDto?` | PermissionDenied, NotFound (null) |

Package: `vet45_catalog_application` — `search_products/`, `get_product_detail/`.

### RPC mapping (BE)

| Use case | RPC / view |
| -------- | ---------- |
| Search | `catalog.search_products` / `catalog.v_product_list` |
| Detail | `catalog.get_product_detail` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `search_empty` | SearchProductsQuery | empty items |
| `search_results` | SearchProductsQuery | list of `ProductListItemDto` |
| `search_filtered_active` | status=ACTIVE | filtered subset |
| `search_stock_negative` | stockStatus=negative | items with negative stock |
| `detail_active` | GetProductDetailQuery | `ProductDetailDto` status=active |
| `detail_inactive` | GetProductDetailQuery | `ProductDetailDto` status=inactive |
| `detail_not_found` | GetProductDetailQuery | null |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data) — **chỉ lane E2E**

---

## Epic-01 / US-03 — Chỉnh sửa thông tin hồ sơ sản phẩm

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `UpdateProductProfileCommand` | tenantId, actorId, productId, expectedVersion, profile fields | `UpdateProductProfileResult` | Validation, ConcurrencyConflict, DuplicateSku/Barcode |
| `UpdateProductImagesCommand` | tenantId, actorId, productId, expectedVersion, images[] | `UpdateProductImagesResult` | Validation, ImageUploadFailed |
| `AdjustBasicStockCommand` | tenantId, actorId, productId, expectedVersion, newQuantity | `AdjustBasicStockResult` (delta) | Validation, ConcurrencyConflict, InvalidStock |
| `GetProductDetailQuery` | (load for edit) | `ProductDetailDto?` | — |

Package: `vet45_catalog_application` — `update_product_profile/`, `update_product_images/`, `adjust_basic_stock/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Update profile | `catalog.update_product_profile` |
| Update images | `catalog.update_product_images` |
| Adjust stock | `catalog.adjust_basic_stock` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `update_profile_ok` | UpdateProductProfileCommand valid | success |
| `update_profile_concurrency` | stale expectedVersion | ConcurrencyConflict |
| `update_images_ok` | UpdateProductImagesCommand | success |
| `update_images_upload_fail` | upload error | ImageUploadFailed |
| `stock_adjust_ok` | AdjustBasicStockCommand 20→25 | delta=+5 |
| `stock_adjust_negative` | newQuantity=-5 | success |
| `stock_adjust_invalid` | non-numeric | Validation |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (product id)

---

## Epic-01 / US-04 — Quản lý trạng thái kinh doanh

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `DeactivateProductCommand` | tenantId, actorId, productId, expectedVersion, currentStatus | `DeactivateProductResult` | Validation, NotFound, InvalidStatus, PendingTransaction, PermissionDenied |
| `ReactivateProductCommand` | tenantId, actorId, productId, expectedVersion, currentStatus | `ReactivateProductResult` | Validation, NotFound, InvalidStatus, InvalidProfile, PermissionDenied |
| `DeleteProductCommand` | tenantId, actorId, productId, expectedVersion, hasBusinessData | `DeleteProductResult` | Validation, NotFound, HasBusinessData, NonZeroStock, PermissionDenied |
| `GetProductDetailQuery` | (reload after mutation) | `ProductDetailDto?` | — |

Package: `vet45_catalog_application` — `deactivate_product/`, `reactivate_product/`, `delete_product/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Deactivate | `catalog.deactivate_product` |
| Reactivate | `catalog.reactivate_product` |
| Soft delete | `catalog.delete_product` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `deactivate_ok` | DeactivateProductCommand | success, status→inactive |
| `reactivate_ok` | ReactivateProductCommand | success, status→active |
| `deactivate_pending_tx` | product in pending order | PendingTransaction |
| `delete_ok` | DeleteProductCommand | success, status→deleted |
| `delete_blocked_has_data` | hasBusinessData=true | HasBusinessData |
| `delete_blocked_stock` | stock≠0 | NonZeroStock |
| `status_permission_denied` | either command | PermissionDenied |

### Parallel notes

- FE có thể fake: **yes** (sau CONTRACT)
- E2E prerequisite: US-02 detail context

---

## Epic-01 / US-05 — Quản lý đơn vị đo lường

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `AddProductUnitCommand` | tenantId, actorId, productId, unitName, referenceUnitId, conversionValue | `AddProductUnitResult` | Validation, DuplicateUnit, InvalidConversion |
| `DeactivateProductUnitCommand` | tenantId, actorId, productId, unitId | `DeactivateProductUnitResult` | Validation, NotFound |
| `ReactivateProductUnitCommand` | tenantId, actorId, productId, unitId | `ReactivateProductUnitResult` | Validation, NotFound |
| `DeleteProductUnitCommand` | tenantId, actorId, productId, unitId | `DeleteProductUnitResult` | Validation, HasUsage |
| `ChangeBaseUnitCommand` | tenantId, actorId, productId, newBaseUnitId, expectedVersion | `ChangeBaseUnitResult` (convertedStock) | Validation, PendingTransaction, InvalidConversion |

Package: `vet45_catalog_application` — `product_units/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Add unit | `catalog.add_product_unit` |
| Deactivate unit | `catalog.deactivate_product_unit` |
| Reactivate unit | `catalog.reactivate_product_unit` |
| Delete unit | `catalog.delete_product_unit` |
| Change base | `catalog.change_base_unit` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `add_unit_ok` | AddProductUnitCommand 1 hộp=10 lọ | success |
| `add_unit_dup` | trùng tên đơn vị | DuplicateUnit |
| `add_unit_invalid_rate` | conversionValue=0 | InvalidConversion |
| `deactivate_unit_ok` | DeactivateProductUnitCommand | success |
| `reactivate_unit_ok` | ReactivateProductUnitCommand | success |
| `delete_unit_blocked` | unit has usage | HasUsage |
| `change_base_unit_ok` | 20 lọ → 2 hộp | convertedStock=2 |
| `change_base_unit_pending` | pending transaction | PendingTransaction |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (product with units)

---

## Epic-02 / US-01 — Giá cấp cửa hàng

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SetStorePricingSettingCommand` | tenantId, actorId, listPriceRatio, floorPriceRatio, expectedVersion? | `SetStorePricingSettingResult` | Validation, InvalidRatioRelation, PermissionDenied |
| `UnsetStorePricingSettingCommand` | tenantId, actorId | `UnsetStorePricingSettingResult` | PermissionDenied |
| `GetStorePricingSettingQuery` | tenantId | `StorePricingSettingDto?` | PermissionDenied |

Package: `vet45_catalog_application` — `store_pricing/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Set / update | `catalog.set_store_pricing` |
| Unset | `catalog.unset_store_pricing` |
| Get | `catalog.get_store_pricing` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `store_pricing_ok` | SetStorePricingSettingCommand 30%/15% | success |
| `store_pricing_floor_gt_list` | floor>list | InvalidRatioRelation |
| `store_pricing_unset_ok` | UnsetStorePricingSettingCommand | success |
| `store_pricing_not_set` | GetStorePricingSettingQuery | null |
| `store_pricing_preview` | UI preview only | sample prices, no persist |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: —

---

## Epic-02 / US-02 — Giá cấp sản phẩm & theo UOM

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SetProductPriceModeCommand` | tenantId, actorId, productId, priceMode (STORE\|PRODUCT), expectedVersion | `SetProductPriceModeResult` | Validation, MissingProductPrice |
| `SetProductPriceCommand` | tenantId, actorId, productId, listPrice, floorPrice, expectedVersion | `SetProductPriceResult` | Validation, InvalidPriceRelation |
| `SetProductUnitPriceCommand` | tenantId, actorId, productId, unitId, listPrice?, floorPrice?, resetToAuto? | `SetProductUnitPriceResult` | Validation, PartialPrice |
| `GetProductPriceQuery` | tenantId, productId, unitId? | `ProductPriceDto` | PermissionDenied |
| `GetProductPriceHistoryQuery` | tenantId, productId, limit, offset | `ProductPriceHistoryResultDto` | PermissionDenied |

Package: `vet45_catalog_application` — `product_pricing/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Set mode | `catalog.set_product_price_mode` |
| Set product price | `catalog.set_product_price` |
| Set unit price | `catalog.set_product_unit_price` |
| Get price | `catalog.get_product_price` |
| History | `catalog.get_product_price_history` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `product_price_mode_store` | SetProductPriceModeCommand STORE | success |
| `product_price_mode_product` | SetProductPriceModeCommand PRODUCT + prices | success |
| `product_price_mode_missing` | PRODUCT without prices | MissingProductPrice |
| `product_price_set_ok` | SetProductPriceCommand | success |
| `product_price_invalid` | floor>list | InvalidPriceRelation |
| `unit_price_manual_ok` | SetProductUnitPriceCommand | success |
| `unit_price_reset_auto` | resetToAuto=true | auto computed prices |
| `unit_price_partial` | chỉ nhập listPrice | PartialPrice |
| `price_history_items` | GetProductPriceHistoryQuery | sample rows |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (product), US-05 (UOM for FR-03)
