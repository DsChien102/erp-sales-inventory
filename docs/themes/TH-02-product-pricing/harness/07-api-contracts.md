# TH-02 — API contracts (FE ↔ BE) — v3

Source of truth giữa presentation và application layer. Types live in `modules/catalog/application/`. RPC mapping: [03-architecture-and-flows.md](03-architecture-and-flows.md).

Facade: `ICatalogModule` (`modules/catalog/application/lib/src/contracts/i_catalog_module.dart`).

**Access control:** `@RequiresPermission(CatalogPermissions.*)` + `@RequiresTenant()`; codegen emit `catalog_access_metadata.g.dart` — mirror [modules/partner/README.md](../../../../modules/partner/README.md).

**Quy tắc:** FE fake theo contract này — không fake RPC trực tiếp. Scenarios trong `FakeCatalogModule` (`package:vet45_catalog_application/testing.dart`).

> **Migration note (2026-07):** Spec v3; contracts theo [04-slice-roadmap.md](04-slice-roadmap.md). Bổ sung section khi từng slice vào CONTRACT lane. FR/US `pending` / `out_of_scope` không implement.

---

## EPIC-02 / US-01 — Guided create (slice #1)

**Status:** CONTRACT `done` · BE `done`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RequestProductImageUploadCommand` | tenantId, actorId, fileName, contentType, byteSize | `ProductImageUploadSlotDto` | `ValidationException`, PermissionDenied |
| `CreateProductCommand` | tenantId, actorId, productName, commercialName?, sku?, barcode?, description?, note?, images[] (`ProductImageInput`), baseUnitName? | `CreateProductResult` (productId, readinessSummary) | `ValidationException`, PermissionDenied (`ApplicationException`), `DuplicateSkuException`, `DuplicateBarcodeException` |
| `CheckDuplicateProductCodeQuery` | tenantId, sku?, barcode?, excludeProductId? | `List<ProductDuplicateMatchDto>` | PermissionDenied |

Package: `vet45_catalog_application` — `guided_create/`, `check_duplicate/`, `readiness/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `ProductImageUploadSlotDto` | slotId, storageKey, signedUploadUrl, expiresAt |
| `ProductImageInput` | storageKey, slotId?, url?, isPrimary, sortOrder |
| `ReadinessSummaryDto` | status (`ReadinessStatus`), blockers (`ReadinessBlockerDto[]`) |
| `ReadinessBlockerDto` | code, message, group? |
| `ProductDuplicateMatchDto` | field (`ProductDuplicateField`), productId, productName, matchedValue |

`baseUnitName` optional (FR-03): thiếu → readiness blocker `missing_base_unit`, không fail create.

Permissions: `@RequiresPermission(CatalogPermissions.create)` (`catalog.product.create`) + `@RequiresTenant()`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Reserve image upload slot | `catalog.request_product_image_upload` |
| Create (minimal) | `catalog.create_product` |
| Dup check | `catalog.check_duplicate_product_code` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `guided_create_ok` | CreateProductCommand valid + baseUnit | `CreateProductResult` + readiness blockers (vd. `missing_price`) |
| `guided_create_dup_sku` | sku trùng tenant | `DuplicateSkuException` |
| `guided_create_dup_barcode` | barcode trùng tenant | `DuplicateBarcodeException` |
| `guided_create_missing_name` | thiếu tên | `ValidationException` |
| `guided_create_no_images` | no images | success + optional `missing_image` blocker |
| `guided_create_upload_slot_ok` | RequestProductImageUploadCommand valid | `ProductImageUploadSlotDto` |
| `guided_create_upload_invalid_type` | unsupported content type | `ValidationException` |
| `guided_create_permission_denied` | no catalog.product.create | `ApplicationException` (Permission denied) |

`FakeCatalogModule` — `package:vet45_catalog_application/testing.dart`.

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: —

---

## EPIC-02 / US-02 — Dữ liệu vận hành ban đầu (slice #2)

**Status:** CONTRACT `done` · BE `todo`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SetInitialStockCommand` | tenantId, productId, quantity (`double`, basic mode) | `SetInitialStockResult` (productId, quantity, unitName?, readinessSummary) | Validation, NotBasicStockMode, MissingBaseUnit |
| `SetManualBasePriceCommand` | tenantId, productId, basePrice, currency | `SetManualBasePriceResult` | Validation, NotManualBasePriceMode, MissingBaseUnit |
| `SetInitialPriceBandCommand` | tenantId, productId, listPrice?, floorPrice?, useStoreRule? | void | Validation, MissingBasePrice |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `initial_stock_ok` | SetInitialStockCommand | success, readiness updated |
| `initial_stock_skip` | skip step | blocker remains |
| `manual_base_price_ok` | SetManualBasePriceCommand | success |
| `price_band_from_store_rule` | useStoreRule=true | suggested list/floor |

---

## EPIC-02 / US-03 — Hoàn tất create + readiness summary (slice #3)

**Status:** CONTRACT `done` · BE `done` · FE `done`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetProductReadinessQuery` | tenantId, productId | `ProductReadinessViewDto` | PermissionDenied, NotFound |

Package: `vet45_catalog_application` — `readiness/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `ReadinessSummaryDto` | status, blockers[] (reuse US-01) |
| `ReadinessBlockerDto` | code, message, group? |
| `ReadinessChecklistItemDto` | group, label, status, kind, blockerCode?, description? |
| `ContextualActionDto` | actionId, label, priority, enabled, requiredPermission?, targetModule? |
| `ProductReadinessViewDto` | productId, productName, readinessSummary, checklist[], suggestedActions[], primaryActionId? |

Enums: `ReadinessChecklistItemStatus`, `ReadinessChecklistGroup`, `ReadinessItemKind`, `ContextualActionPriority`, `ContextualActionId`.

`CreateProductResult.readinessSummary` — dùng ngay sau create; `GetProductReadinessQuery` — refresh sau mutation (FR-04) hoặc mở lại sản phẩm.

Permissions: `@RequiresPermission(CatalogPermissions.viewDetail)` + `@RequiresTenant()`.

### Blocker → action matrix

| Blocker code | Checklist group | Action id | Permission | Mode |
| ------------ | --------------- | --------- | ---------- | ---- |
| `missing_base_unit` | units | `set_base_unit` | `catalog.product.manage_units` | Foundation |
| `missing_image` | images | — | — | recommended only |
| `missing_price` | basePrice | `set_manual_base_price` | `catalog.product.manage_pricing` | manual base price |
| `pending_base_price_from_costing` | basePrice | `open_costing` | `catalog.product.view_detail` | costing module (**pending**) |
| `missing_stock` | stock | `set_initial_stock` | `catalog.product.manage_stock` | basic stock |
| `pending_stock_from_inventory` | stock | `open_inventory` | `catalog.product.view_detail` | advanced stock (**pending**) |
| `missing_price_band` | priceBand | `set_price_band` | `catalog.product.manage_pricing` | |
| `missing_required_custom_fields` | customFields | `fill_custom_fields` | `catalog.product.update` | EPIC-03 |
| (ready to sell) | — | `create_another_product` | `catalog.product.create` | |

Priority: base unit → stock/base price (tenant mode) → price band → custom fields.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Readiness view | `catalog.get_product_readiness` |

**Params:** `p_tenant_id uuid`, `p_product_id uuid`

**Response (facts row):** `product_id`, `product_name`, `has_base_unit`, `has_images`, `has_stock`, `has_base_price`, `has_price_band`, `has_required_custom_fields`, `stock_mode` (`basic` \| `advanced`), `base_price_mode` (`manual` \| `costing_module`)

**Foundation MVP (US-03 BE):** RPC hardcodes `stock_mode = basic`, `base_price_mode = manual`; `has_stock`, `has_base_price`, `has_price_band` = `false` until EPIC-05/US-02 and EPIC-06 slices extend joins. Domain `ProductReadinessEvaluator` + application `ProductReadinessViewAssembler` compute blockers/checklist/actions from facts.

**Permission:** `iam.has_permission(p_tenant_id, 'catalog.product.view_detail')` — mirror US-01 read paths.

**Not found:** empty result → gateway maps `ApplicationException('Product not found')`.

Draft: `supabase/migrations/_drafts/catalog_product_readiness.sql`

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `readiness_many_blockers` | GetProductReadinessQuery after minimal create | incomplete + many checklist `missing` |
| `readiness_ready_to_sell` | create with full data + query | `readyToSell`, primary `create_another_product` |
| `readiness_advanced_stock_pending` | advanced stock mode product | stock `pendingExternal`, no `set_initial_stock` |
| `readiness_costing_base_price_pending` | costing base price mode | basePrice `pendingExternal` |
| `readiness_missing_custom_fields` | missing required custom fields | blocker `missing_required_custom_fields` |
| `readiness_no_price_permission` | missing price band, no pricing perm | blocker visible, `set_price_band` disabled |
| `readiness_refresh_after_unit` | product with unit + base price | unit complete, price band still missing |
| `readiness_permission_denied` | no view_detail | PermissionDenied |

`FakeCatalogModule` — `package:vet45_catalog_application/testing.dart`.

### E2E scenarios (ERP integration)

File: `apps/erp/test/features/catalog/presentation/pages/product_readiness_e2e_test.dart` — shared harness: `apps/erp/test/features/catalog/catalog_e2e_harness.dart`.

| test_id | FakeCatalogScenario | Assert |
| ------- | ------------------- | ------ |
| `e2e_e02_u03_fr01_01` | `guided_create_ok` | PCC banner + checklist sections (blockers) |
| `e2e_e02_u03_fr02_04` | `guided_create_ok` | Success → PCC; validation fail → stay on create |
| `e2e_e02_u03_fr03_01` | `readiness_many_blockers` | Checklist page: missing base unit + CTA |
| `e2e_e02_u03_fr04_01` | `readiness_refresh_after_unit` | Base unit complete; price band still missing |
| `e2e_e02_u03_fr01_05` | `readiness_ready_to_sell` | Badge `Sẵn sàng bán`; no required blockers |

Pattern: `initDependencies` → override `ICatalogModule` with `FakeCatalogModule` (mirror US-01 E2E). No live Supabase for slice #3.

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01

---

## EPIC-01 / US-01 — Tra cứu danh mục (slice #4)

**Status:** CONTRACT `done` · BE `done` · FE `done`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SearchProductsQuery` | tenantId, `ProductSearchCriteria`, limit, offset | `ProductSearchResultDto` | PermissionDenied |
| `ScanBarcodeQuery` | tenantId, barcode | `ProductListItemDto?` | PermissionDenied |

Package: `vet45_catalog_application` — `product_search/`. Criteria: `vet45_catalog_domain` — `search/product_search_criteria.dart`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `ProductSearchCriteria` | keyword?, businessStatuses (`Set<ProductStatus>`, default `{active}`), readinessFilter?, includeSoftDeleted (default false), sortOrder |
| `ProductReadinessFilter` | `readyToSell`, `incomplete` |
| `ProductSortOrder` | `updatedAtDesc` |
| `ProductListItemDto` | id, name, tradeName?, sku?, barcode?, primaryImageUrl?, businessStatus, isSoftDeleted, readinessSummary, listPrice?, floorPrice?, baseUnit?, stockQuantity?, stockLabel?, updatedAt |
| `ProductSearchResultDto` | items[], totalCount |

Readiness chip trên list: FE derive từ `readinessSummary.status` + `blockers.first` (FR-03).

Permissions: `@RequiresPermission(CatalogPermissions.view)` + `@RequiresTenant()`.

Port: `ICatalogReadGateway.search`, `ICatalogReadGateway.findByBarcode`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Search list | `catalog.search_products` |
| Barcode scan | `catalog.find_product_by_barcode` (hoặc search với exact barcode match) |

**`catalog.search_products` params:** `p_tenant_id`, `p_keyword`, `p_business_statuses text[]`, `p_readiness_filter text`, `p_include_soft_deleted boolean`, `p_limit int`, `p_offset int`

**Response row:** list item fields + `readiness_status`, `top_blocker_code`, `top_blocker_message` (hoặc join `catalog.v_product_list`).

Draft view: `catalog.v_product_list` — xem [03-architecture-and-flows.md](03-architecture-and-flows.md).

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `search_empty` | SearchProductsQuery | `items: []`, `totalCount: 0` |
| `search_with_readiness` | SearchProductsQuery default | seed products với readiness đa dạng (ready + incomplete) |
| `barcode_exact_match` | ScanBarcodeQuery known barcode | single `ProductListItemDto` |
| `barcode_not_found` | ScanBarcodeQuery unknown | `null` |

`FakeCatalogModule` — `package:vet45_catalog_application/testing.dart`.

Tests: `scn_contract_e01_u01_*` trong `fake_catalog_module_test.dart`.

### E2E (integration)

| test_id | scenario | harness | asserts |
| ------- | -------- | ------- | ------- |
| `e2e_e01_u01_fr01_01` | `search_with_readiness` | `buildCatalogDiscoveryRouter()` + `setUpErpCatalogE2E` | list load, keyword filter via `input_product_search` |

Widget keys: `wgt_e01_u01_fr01_01` (list page), `input_product_search` (search field).

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data)

---

## EPIC-01 / US-02 — Product Control Center (slice #5)

**Status:** CONTRACT `done` · BE `done` · FE `done`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetProductControlCenterQuery` | tenantId, productId | `ProductControlCenterDto` | PermissionDenied, NotFound |

Package: `vet45_catalog_application` — `control_center/`.

`ProductControlCenterDto`:

| Field | Type | FR | Ghi chú Foundation |
| ----- | ---- | -- | ------------------ |
| `profile` | `ProductProfileSummaryDto` | FR-01 | name, tradeName, sku, barcode, businessStatus, images |
| `units` | `ProductUnitsCardDto` | FR-02 | baseUnitName, conversionUnits[] |
| `stock` | `ProductStockCardDto` | FR-02 | mode, quantity, pendingExternal |
| `basePrice` | `ProductBasePriceCardDto` | FR-02 | mode, sourceLabel, amount, currency, baseUnitName, canEdit |
| `priceBand` | `ProductPriceBandCardDto` | FR-02 | listPrice, floorPrice, unitName |
| `customFieldGroupCards` | `CustomFieldGroupCardDto[]` | FR-03 | **empty** đến EPIC-03 |
| `readinessSummary` | `ReadinessSummaryDto` | early | reuse US-03 |
| `checklist` | `ReadinessChecklistItemDto[]` | FR-04 | **pending** — luôn `[]` |
| `contextualActions` | `ContextualActionDto[]` | FR-05 | reuse US-03 assembler |
| `changeHistoryPreview` | `ProductChangeHistoryEntryDto[]` | FR-06 | 1–3 entries preview |
| `primaryActionId` | `String?` | FR-05 | top blocker action |

Card DTOs: `ProductProfileSummaryDto`, `ProductUnitsCardDto`, `ProductConversionUnitDto`, `ProductStockCardDto`, `ProductBasePriceCardDto`, `ProductPriceBandCardDto`, `CustomFieldGroupCardDto`, `CustomFieldCardFieldDto`, `ProductChangeHistoryEntryDto`.

**Quan hệ queries:** PCC load `GetProductControlCenterQuery`; checklist sub-page vẫn có thể dùng `GetProductReadinessQuery` (US-03). Không gộp hai query.

Permissions: `@RequiresPermission(CatalogPermissions.viewDetail)` + `@RequiresTenant()`. Change history preview: `catalog.product.view_history`.

Port: `ICatalogReadGateway.getControlCenter`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Control center aggregate | `catalog.get_product_control_center` |

**Params:** `p_tenant_id uuid`, `p_product_id uuid`

**Response:** JSON aggregate hoặc composite row — profile, operational cards, readiness facts, change history preview (join `catalog.product_change_history`).

Foundation: `stock_mode = basic`, `base_price_mode = manual`; custom field cards `[]` until EPIC-03.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `pcc_incomplete` | product-4 thiếu price band | readinessSummary blockers + `set_price_band` action |
| `pcc_ready_to_sell` | product-1 đủ dữ liệu | readiness `readyToSell` |
| `pcc_inactive` | product-5 inactive | profile.businessStatus = inactive |
| `pcc_custom_field_cards` | stub group card | 1 group "Thông tin thuốc" (layout test; data thật EPIC-03) |

`FakeCatalogModule` — `package:vet45_catalog_application/testing.dart`.

Tests: `scn_contract_e01_u02_*` trong `fake_catalog_module_test.dart`.

### E2E (integration)

| test_id | scenario | harness | asserts |
| ------- | -------- | ------- | ------- |
| `e2e_e01_u02_fr01_01` | `pcc_incomplete` | `buildCatalogDiscoveryRouter()` + list→tap→PCC | `GetProductControlCenterQuery` operational cards (Đơn vị, Tồn kho, Khung giá), readiness badge |

Widget keys: `wgt_e01_u02_fr01_01` (PCC), `btn_readiness_checklist_banner` (checklist CTA — loads `GetProductReadinessQuery` on tap).

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01; FR-04 checklist **pending**

---

## EPIC-04 / US-01 — Đơn vị cơ sở (slice #6)

**Status:** CONTRACT `done` · BE `todo` · FE `todo`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SetProductBaseUnitCommand` | tenantId, productId, `BaseUnitSelection` | `SetProductBaseUnitResult` | PermissionDenied, NotFound, `DuplicateMeasurementUnitNameException`, ValidationException |
| `ListTenantMeasurementUnitsQuery` | tenantId, keyword?, limit | `List<TenantMeasurementUnitDto>` | PermissionDenied |
| `CheckDuplicateMeasurementUnitNameQuery` | tenantId, name | `bool isDuplicate` | PermissionDenied |

Package: `vet45_catalog_application` — `units/`.

**`BaseUnitSelection`:**

| Variant | Fields | Use |
| ------- | ------ | --- |
| `ExistingTenantUnit` | `unitId` | Chọn từ danh sách tenant (FR-01) |
| `NewTenantUnit` | `name` | Tạo nhanh đơn vị mới (FR-01, BR-05/BR-06) |

**`SetProductBaseUnitResult`:** `productId`, `baseUnitName`, `readinessSummary` — FR-03 refresh ngay sau set.

**`TenantMeasurementUnitDto`:** `id`, `name`, `isActive`.

Permissions: `@RequiresPermission(CatalogPermissions.manageUnits)` + `@RequiresTenant()`.

Port: `ICatalogUnitGateway.listTenantUnits`, `isDuplicateUnitName`, `setProductBaseUnit`.

**Scope:** chỉ gán đơn vị cơ sở khi sản phẩm **chưa có** base unit hợp lệ — đổi base unit (US-03) **out_of_scope**.

### FR-02 dependency gating (document only)

Không thêm query gates — FE derive từ `readinessSummary` / `hasBaseUnit`. Các command phụ thuộc đơn vị throw `MissingBaseUnitException` (domain):

| Command | Requires base unit |
| ------- | ------------------ |
| `SetInitialStockCommand` | yes |
| `SetManualBasePriceCommand` | yes |
| `SetInitialPriceBandCommand` | yes |
| Slice #7 conversion unit commands | yes (lane sau) |

### RPC mapping (BE — draft, lane sau)

| Use case | RPC |
| -------- | --- |
| List picker | `catalog.list_tenant_measurement_units` |
| Dup-check name | `catalog.check_duplicate_measurement_unit_name` |
| Set base unit | `catalog.set_product_base_unit` |

**Tenant unit master (BE design note):** `catalog.tenant_measurement_units` (`tenant_id`, `name`, `name_normalized`, `is_active`) — draft `05_catalog_units.sql`; CONTRACT không promote migration.

**`catalog.set_product_base_unit` params:** `p_tenant_id`, `p_product_id`, `p_tenant_unit_id uuid` (nullable), `p_new_unit_name text` (nullable) — exactly one of id/name.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `list_tenant_units` | `ListTenantMeasurementUnitsQuery` | seed `Lọ`, `Hộp`, `Vỉ` |
| `set_base_unit_existing` | `SetProductBaseUnitCommand(ExistingTenantUnit)` | `product-6` → `Lọ`; readiness bỏ `missing_base_unit` |
| `set_base_unit_create_new` | `SetProductBaseUnitCommand(NewTenantUnit)` | thêm unit tenant + gán product |
| `set_base_unit_duplicate` | `NewTenantUnit("Lọ")` | `DuplicateMeasurementUnitNameException` |
| `set_base_unit_inactive_unit` | `ExistingTenantUnit` inactive | `ValidationException` |
| `unit_dependencies_locked` | `GetProductReadinessQuery` / stock without unit | blocker + `set_base_unit` action; stock → `MissingBaseUnitException` |

`FakeCatalogModule` — `package:vet45_catalog_application/testing.dart`.

Tests: `scn_contract_e04_u01_*` trong `fake_catalog_module_test.dart`.

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data)

---

## EPIC-04 / US-02 — Đơn vị quy đổi (slice #7)

**Status:** CONTRACT `done` · BE `done` · FE `todo`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `ListProductUnitsQuery` | tenantId, productId, includeInactive=false | `ProductUnitsDto` | PermissionDenied, NotFound |
| `AddProductConversionUnitCommand` | tenantId, productId, unitName, conversionRateToBase | `ProductUnitMutationResult` | PermissionDenied, NotFound, `MissingBaseUnitException`, `DuplicateMeasurementUnitNameException`, `ValidationException` |
| `DeactivateProductConversionUnitCommand` | tenantId, productId, productUnitId | `ProductUnitMutationResult` | PermissionDenied, NotFound, `ValidationException` |
| `ReactivateProductConversionUnitCommand` | tenantId, productId, productUnitId | `ProductUnitMutationResult` | PermissionDenied, NotFound, `DuplicateMeasurementUnitNameException`, `ValidationException` |

Package: `vet45_catalog_application` — `units/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `ProductUnitDto` | id, name, conversionRateToBase, isBaseUnit, isActive |
| `ProductUnitsDto` | productId, baseUnitName, units (`ProductUnitDto[]`) |
| `ProductUnitMutationResult` | productId, unit (`ProductUnitDto`) |

Permissions: `@RequiresPermission(CatalogPermissions.manageUnits)` + `@RequiresTenant()`.

Port: `ICatalogUnitGateway.listProductUnits`, `addConversionUnit`, `deactivateConversionUnit`, `reactivateConversionUnit`.

**Scope / rules:**

- FR-01 add conversion unit, FR-03 deactivate conversion unit, FR-04 reactivate conversion unit are in contract.
- FR-02 unit roles is **pending**; no role fields, role toggles, default sale/import/display flags, or role validation appear in this contract.
- Adding conversion units requires an existing valid base unit; missing base unit throws `MissingBaseUnitException`.
- Base unit cannot be deactivated through this slice. US-03 change base unit remains **out_of_scope**.
- `conversionRateToBase` is `double` and must be `> 0`; precision policy is deferred to BE.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| List product units | `catalog.list_product_units` |
| Add conversion unit | `catalog.add_product_conversion_unit` |
| Deactivate conversion unit | `catalog.deactivate_product_conversion_unit` |
| Reactivate conversion unit | `catalog.reactivate_product_conversion_unit` |

Draft: `supabase/migrations/_drafts/05_catalog_units.sql` — handlers via `SupabaseCatalogUnitGateway` + `ProductRpcMapper`.

**BE tests:** `set_product_base_unit_command_handler_test.dart` (group `Product conversion unit handlers`), `product_rpc_mapper_test.dart` (EPIC-04/US-02 conversion units).

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e04_u02_fr01_01` | add conversion unit to `product-1` | new active `ProductUnitDto`; list returns base `Hộp` |
| `scn_contract_e04_u02_fr01_02` | add conversion unit to `product-6` | `MissingBaseUnitException` |
| `scn_contract_e04_u02_fr01_03` | zero/negative rate | `ValidationException` |
| `scn_contract_e04_u02_fr01_04` | duplicate active unit or duplicate base unit name | `DuplicateMeasurementUnitNameException` |
| `scn_contract_e04_u02_fr03_01` | deactivate `product-1-unit-vi` | list with inactive shows `isActive=false` |
| `scn_contract_e04_u02_fr03_02` | deactivate `product-1-base` | `ValidationException` |
| `scn_contract_e04_u02_fr04_01` | reactivate `product-1-unit-thung` | `isActive=true` |
| `scn_contract_e04_u02_fr04_02` | reactivate while active duplicate exists | `DuplicateMeasurementUnitNameException` |

Seed data in `FakeCatalogModule`: `product-1` base `Hộp`, active conversion `Vỉ` rate `10`, inactive conversion `Thùng` rate `100`; `product-6` has no base unit.

Tests: `scn_contract_e04_u02_*` trong `fake_catalog_module_test.dart`.

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data), US-01 base unit readiness

---

## EPIC-05 / US-01 + US-02 — Stock profile + basic stock (slice #8)

**Status:** CONTRACT `done` · BE `done` · FE `done`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `AdjustBasicStockCommand` | tenantId, productId, newQuantity (`double`), reason?, expectedQuantity? | `AdjustBasicStockResult` (productId, previousQuantity, newQuantity, unitName?, readinessSummary) | Validation, `MissingBaseUnitException`, `NotBasicStockModeException`, `StaleStockQuantityException` |
| `GetProductStockHistoryQuery` | tenantId, productId, limit=50 | `ProductStockHistoryDto` | PermissionDenied, NotFound |

`SetInitialStockCommand` updated from `void` to `SetInitialStockResult` and now accepts `double quantity`.

### Stock card contract (US-01 read-side)

`ProductStockCardDto` (trong `GetProductControlCenterQuery` response):

| Field | Type | Notes |
| ----- | ---- | ----- |
| `mode` | `StockMode` | `basic` \| `advanced` |
| `source` | `StockDataSource` | `basicProfile` \| `inventoryModule` |
| `sourceLabel` | `String` | "Tồn kho cơ bản" hoặc "Tồn kho từ module Kho" |
| `quantity` | `int?` | read quantity for card |
| `isConfigured` | `bool` | có nguồn tồn hợp lệ (qty=0 vẫn true) |
| `isOutOfStock` | `bool` | `isConfigured && quantity == 0` |
| `canAdjust` | `bool` | chỉ `basic` + có base unit |
| `currentVersion` | `int?` | optimistic concurrency hint |

### Supporting types

| Type | Fields |
| ---- | ------ |
| `SetInitialStockResult` | productId, quantity, unitName?, readinessSummary |
| `AdjustBasicStockResult` | productId, previousQuantity, newQuantity, unitName?, readinessSummary |
| `ProductStockMovementDto` | id, occurredAt, actorDisplayName, movementType (`initial` \| `adjust`), quantityBefore, quantityAfter, delta, reason? |
| `ProductStockHistoryDto` | productId, unitName?, isHistoricalBasicOnly, movements[] |

### RPC mapping (BE — later lane)

| Use case | RPC |
| -------- | --- |
| Set initial stock | `catalog.set_initial_stock` |
| Adjust basic stock | `catalog.adjust_basic_stock` |
| Read stock history | `catalog.get_product_stock_history` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e05_u01_fr01_01` | PCC `product-1` | stock mode basic + source `Tồn kho cơ bản` |
| `scn_contract_e05_u01_fr02_01` | advanced stock product | source inventory + read-only (`canAdjust=false`) |
| `scn_contract_e05_u01_fr03_01` | quantity = 0 | `isOutOfStock=true`, không tạo blocker `missing_stock` |
| `scn_contract_e05_u02_fr01_01` | `SetInitialStockCommand` valid | `SetInitialStockResult` + readiness refresh |
| `scn_contract_e05_u02_fr01_02` | set stock khi thiếu base unit | `MissingBaseUnitException` |
| `scn_contract_e05_u02_fr02_01` | `AdjustBasicStockCommand` valid | `AdjustBasicStockResult` |
| `scn_contract_e05_u02_fr02_02` | adjust âm | `ValidationException` |
| `scn_contract_e05_u02_fr02_03` | expectedQuantity stale | `StaleStockQuantityException` |
| `scn_contract_e05_u02_fr03_01` | `GetProductStockHistoryQuery` | history movements (`initial`, `adjust`) |
| `scn_contract_e05_u02_fr04_01` | set/adjust stock | readiness bỏ blocker `missing_stock` |

### E2E (integration)

| test_id | scenario | harness | asserts |
| ------- | -------- | ------- | ------- |
| `e2e_e05_u01_fr01_01` | `pcc_ready_to_sell` | `buildCatalogDiscoveryRouter()` → PCC | stock card `150 Hộp`, **Sửa** visible |
| `e2e_e05_u01_fr02_01` | `readiness_advanced_stock_pending` | `buildCatalogPostCreateRouter()` + create | tap **Sửa** tồn kho không mở stock page |
| `e2e_e05_u01_fr03_01` | default (`product-3`) | discovery → PCC | `0 Lọ`, không `Thiếu tồn kho` |
| `e2e_e05_u02_fr01_01` | `guided_create_ok` + `createMinimalProduct` | PCC → stock page | initial set `30` → PCC refresh |
| `e2e_e05_u02_fr02_01` | `pcc_ready_to_sell` (`product-1`) | local PCC router | adjust `150`→`25` + reason chip |
| `e2e_e05_u02_fr04_01` | `guided_create_ok` + base unit | PCC → set stock | card bỏ `Thiếu tồn kho` |
| FR-03 history | — | — | **n/a** (no history UI) |

Widget keys: `wgt_e05_u01_fr01_01` (stock page), `input_stock_quantity`, `btn_stock_save`.

File: `apps/erp/test/features/catalog/presentation/pages/product_stock_e2e_test.dart`.

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data)

---

## EPIC-06 / US-01 — Manual base price (slice #9)

**Status:** CONTRACT `done` · BE `done` · FE `done` · E2E `done`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SetManualBasePriceCommand` | tenantId, productId, basePrice (`double`, `>= 0`), currency (`VND` default), mode=`manual` | `SetManualBasePriceResult` | Validation, `MissingBaseUnitException`, `NotManualBasePriceModeException` |

Package: `vet45_catalog_application` — `pricing/`.

Read path (PCC): `GetProductControlCenterQuery` → `ProductBasePriceCardDto`.

### `SetManualBasePriceResult`

| Field | Type | Notes |
| ----- | ---- | ----- |
| `productId` | `String` | |
| `basePrice` | `double` | amount per base unit |
| `currency` | `String` | default `VND` |
| `unitName` | `String?` | base unit label |
| `readinessSummary` | `ReadinessSummaryDto` | refresh after mutation (FR-04) |

### `ProductBasePriceCardDto` (read-side)

| Field | Type | Notes |
| ----- | ---- | ----- |
| `mode` | `BasePriceMode` | `manual` \| `costingModule` |
| `sourceLabel` | `String` | `"Nhập thủ công"` \| `"Từ module Giá vốn"` |
| `amount` | `double?` | manual amount when configured |
| `currency` | `String` | default `VND` |
| `baseUnitName` | `String?` | FR-02 UI — giá theo đơn vị cơ sở |
| `canEdit` | `bool` | manual mode + có base unit |
| `isPendingExternal` | `bool` | costing module mode |
| `isMissing` | `bool` | manual mode chưa có giá |
| `missingMessage` | `String?` | `"Thiếu Giá cơ sở định giá"` |

**Scope / rules:**

- FR-01 mode display + FR-02 manual entry contract in scope.
- FR-03 costing-module **read gateway** (`ICostingModuleGateway`) = **pending** slice #23 — card chỉ projection `isPendingExternal` + blocker `pending_base_price_from_costing`.
- Nhập giá yêu cầu đơn vị cơ sở (`MissingBaseUnitException`).
- Giá `>= 0` (giá `0` hợp lệ theo tenant policy Foundation MVP).
- Port write: `IProductCommandGateway.setManualBasePrice` (existing).

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Set manual base price | `catalog.set_manual_base_price` |

**Params:** `p_tenant_id uuid`, `p_product_id uuid`, `p_mode text` (`manual`), `p_base_price numeric`, `p_currency text` (default `VND`)

**Permission:** `iam.has_permission(p_tenant_id, 'catalog.product.manage_pricing')`

**Guards:** `_ensure_product_has_base_unit`; `not_manual_base_price_mode` if mode ≠ manual; negative price → `validation_exception`

**Side effects:** upsert `catalog.product_base_price_profiles`; `product_change_history` action `set_manual_base_price`

**Create product seed (FR-01):** `create_product` inserts default `product_base_price_profiles` row (`mode = manual`, `base_price_amount = null`)

Draft: `supabase/migrations/_drafts/07_catalog_manual_base_price.sql`

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e06_u01_fr01_01` | PCC `product-1` | manual mode + source `"Nhập thủ công"` + amount |
| `scn_contract_e06_u01_fr01_02` | PCC `product-8` | costing mode + `isPendingExternal` |
| `scn_contract_e06_u01_fr01_03` | PCC `product-7` | manual + `isMissing` |
| `scn_contract_e06_u01_fr02_01` | `SetManualBasePriceCommand` on `product-7` | `SetManualBasePriceResult` |
| `scn_contract_e06_u01_fr02_02` | set on `product-6` | `MissingBaseUnitException` |
| `scn_contract_e06_u01_fr02_03` | negative price | `ValidationException` |
| `scn_contract_e06_u01_fr04_01` | set price on `product-7` | readiness bỏ blocker `missing_price` |

Fake seed: `product-7` (manual, có base unit, thiếu giá), `product-8` (costing mode).

### E2E (integration)

File: `apps/erp/test/features/catalog/presentation/pages/product_manual_base_price_e2e_test.dart` — shared harness: `apps/erp/test/features/catalog/catalog_e2e_harness.dart`.

| test_id | scenario | harness | asserts |
| ------- | -------- | ------- | ------- |
| `e2e_e06_u01_fr01_01` | `pccReadyToSell` | `buildCatalogDiscoveryRouter()` → PCC | card `Giá cơ sở` + `80.000 đ`, **Sửa** visible |
| `e2e_e06_u01_fr01_02` | default (`product-8`) | local PCC router | tap **Sửa** không mở manual base price page |
| `e2e_e06_u01_fr01_03` | default (`product-7`) | local PCC router | `Thiếu Giá cơ sở định giá` |
| `e2e_e06_u01_fr02_01` | `scnContractE06U01Fr02_01` | local PCC router → edit page | set `45000` → PCC refresh `45.000 đ` |
| `e2e_e06_u01_fr02_02` | default (`product-6`) | local PCC router | **Sửa** disabled (thiếu đơn vị) |
| `e2e_e06_u01_fr04_01` | `guided_create_ok` + `createMinimalProduct` | post-create → set price | card bỏ `Thiếu Giá cơ sở định giá` |

Widget keys: `wgt_e06_u01_fr01_01` (manual base price page), `input_base_price_amount`, `btn_manual_base_price_save`.

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data)

---

## EPIC-06 / US-02 — Store Price Rule (slice #10)

**Status:** CONTRACT `done` · BE `done` · FE `done` · E2E `done`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetStorePriceRuleQuery` | tenantId | `StorePriceRuleDto?` | PermissionDenied |
| `SetStorePriceRuleCommand` | tenantId, name, listMarkupRatio, floorMarkupRatio, status? | `SetStorePriceRuleResult` | Validation, PermissionDenied |
| `SuggestProductUnitPriceQuery` | tenantId, productId, productUnitId? | `ProductUnitPriceSuggestionDto` | PermissionDenied, NotFound, `MissingBaseUnitException` |
| `ApplyStorePriceRuleCommand` | tenantId, productId, productUnitId?, storePriceRuleId?, confirmOverwrite?, basePriceVersion? | `ApplyStorePriceRuleResult` | Validation, `MissingBaseUnitException`, `MissingBasePriceException`, `StorePriceRuleNotFoundException`, `StorePriceRuleInactiveException`, `PriceBandOverwriteRequiredException`, `StaleBasePriceException` |

Package: `vet45_catalog_application` — `pricing/store_rule/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `StorePriceRuleDto` | id, tenantId, name, status, calculationType, listMarkupRatio, floorMarkupRatio, updatedAt? |
| `StorePriceRuleStatus` | `active` \| `inactive` |
| `StorePriceCalculationType` | `markup` (Foundation; `margin` deferred) |
| `ProductUnitPriceSuggestionDto` | productId, productUnitId?, unitName?, basePrice, currency, suggestedListPrice?, suggestedFloorPrice?, storePriceRuleId?, storePriceRuleName?, basePriceVersion?, canSuggest, unavailableReason? |
| `ApplyStorePriceRuleResult` | productId, productUnitId?, listPrice, floorPrice, storePriceRuleId, sourceType, readinessSummary |
| `PriceBandSourceType` | `ruleBased` \| `manual` — shared with §EPIC-06/US-03 |

Read path (PCC): `GetProductControlCenterQuery` → `ProductPriceBandCardDto` extended with `sourceType`, `storePriceRuleName`, `isCustomOverride`.

**Scope / rules:**

- Foundation MVP: **1 Store Price Rule per tenant** (`GetStorePriceRuleQuery` returns `null` or single rule). Multi-rule list + EC-04 deferred.
- Formula (markup): `suggestedListPrice = round(basePrice × (1 + listMarkupRatio))`, `suggestedFloorPrice = round(basePrice × (1 + floorMarkupRatio))`; `floor ≤ list`.
- Suggestion is **preview only** (FR-02 BR-02); persist via `ApplyStorePriceRuleCommand` or manual `SetProductUnitPriceBandCommand` (§EPIC-06/US-03).
- `SetInitialPriceBandCommand.useStoreRule` is **deprecated** — use `SuggestProductUnitPriceQuery` + `ApplyStorePriceRuleCommand` instead.
- Multi-UOM suggestion per conversion unit: see `SuggestProductUnitPriceQuery` with `productUnitId`; manual persist per unit via §EPIC-06/US-03.
- Port: `IStorePriceRuleGateway` (contract interface; BE implements in infrastructure).

Permissions:

- `GetStorePriceRuleQuery`, `SetStorePriceRuleCommand` → `@RequiresPermission(CatalogPermissions.manageStorePriceRule)` (`catalog.pricing.manage_store_rule`)
- `SuggestProductUnitPriceQuery`, `ApplyStorePriceRuleCommand` → `@RequiresPermission(CatalogPermissions.managePricing)`

### RPC mapping (BE)

| Use case | RPC / view | Params (summary) | Notes |
| -------- | ---------- | ---------------- | ----- |
| Upsert store rule | `catalog.set_store_price_rule` | `p_tenant_id`, `p_name`, `p_list_markup_ratio`, `p_floor_markup_ratio`, `p_status` | Returns rule row |
| Read store rule | `catalog.get_store_price_rule` | `p_tenant_id` | 0–1 row |
| Suggest unit price | `catalog.suggest_product_unit_price` | `p_tenant_id`, `p_product_id`, `p_product_unit_id?` | Soft-fail via `can_suggest=false` |
| Apply rule to product | `catalog.apply_store_price_rule` | `p_tenant_id`, `p_product_id`, `p_product_unit_id?`, `p_store_price_rule_id?`, `p_confirm_overwrite`, `p_base_price_version?` | Returns applied list/floor |
| PCC price band metadata | `catalog.get_product_control_center` | existing | Adds `price_band_source_type`, `store_price_rule_name`, `is_custom_override` |

**`base_price_version`:** `floor(extract(epoch from product_base_price_profiles.updated_at) * 1000)::bigint`

**Guards:** `store_price_rule_not_found`, `store_price_rule_inactive`, `price_band_overwrite_required`, `stale_base_price`, `missing_base_price`, `missing base unit`

**Change history:** `apply_store_price_rule` action on apply

Draft: [`supabase/migrations/_drafts/08_catalog_store_price_rule.sql`](../../../../supabase/migrations/_drafts/08_catalog_store_price_rule.sql)

**BE tests:** `store_price_rule_handlers_test.dart` (`scn_e06_u02_*`), `store_price_rule_rpc_mapper_test.dart`

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e06_u02_fr01_01` | `SetStorePriceRuleCommand` valid on new tenant | `SetStorePriceRuleResult` active rule |
| `scn_contract_e06_u02_fr01_02` | negative listMarkupRatio | `ValidationException` |
| `scn_contract_e06_u02_fr01_03` | `GetStorePriceRuleQuery` on `tenant-no-rule` | `null` |
| `scn_contract_e06_u02_fr01_04` | `SetStorePriceRuleCommand` status `inactive` | inactive rule |
| `scn_contract_e06_u02_fr02_01` | `SuggestProductUnitPriceQuery` `product-4` | list/floor from rule + base 25k |
| `scn_contract_e06_u02_fr02_02` | suggest `product-7` (no base price) | `canSuggest=false` |
| `scn_contract_e06_u02_fr02_03` | inactive rule scenario | `canSuggest=false` |
| `scn_contract_e06_u02_fr03_01` | `ApplyStorePriceRuleCommand` `product-4` | price band + `ruleBased` |
| `scn_contract_e06_u02_fr03_02` | apply `product-1` without confirm | `PriceBandOverwriteRequiredException` |
| `scn_contract_e06_u02_fr03_03` | stale `basePriceVersion` | `StaleBasePriceException` |
| `scn_contract_e06_u02_fr04_01` | PCC `product-2` | `isCustomOverride=true`, `sourceType=manual` |

Fake seed: `tenant-1` rule `"Mặc định bán lẻ"` (listMarkup `0.5`, floorMarkup `0.25`); `product-4` has base price, no band; `product-2` manual override band.

Tests: `scn_contract_e06_u02_*` in `fake_catalog_module_test.dart` (group `EPIC-06 / US-02 contract`).

### E2E scenarios (ERP)

| test_id | FR | trigger | assert |
| ------- | -- | ------- | ------ |
| `e2e_e06_u02_fr02_01` | FR-02 | PCC `product-4` → editor | suggested 37.500 / 31.250 đ; rule name |
| `e2e_e06_u02_fr02_02` | FR-02 | PCC `product-7` (no base price) | unavailable reason; save disabled |
| `e2e_e06_u02_fr02_03` | FR-02 | inactive rule scenario | unavailable reason; save disabled |
| `e2e_e06_u02_fr03_01` | FR-03 | apply rule `product-4` | band saved; PCC refreshed |
| `e2e_e06_u02_fr03_02` | FR-03 | apply on `product-1` | overwrite dialog; cancel / confirm |
| `e2e_e06_u02_fr04_01` | FR-04 | PCC `product-2` | subtitle `Giá riêng` |

**FR-01 E2E:** deferred (no tenant Store Price Rule settings page in Foundation MVP).

**E2E file:** `apps/erp/test/features/catalog/presentation/pages/product_store_price_rule_e2e_test.dart`

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data); manual base price (slice #9) for suggest/apply happy paths

---

## EPIC-06 / US-03 — Product Unit Price Band (slice #11)

**Status:** CONTRACT `done` · BE `done` · FE `todo` · E2E `todo`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SetProductUnitPriceBandCommand` | tenantId, productId, listPrice, floorPrice, productUnitId?, sourceType?, storePriceRuleId?, confirmAcknowledgeWarnings? | `SetProductUnitPriceBandResult` | Validation, `MissingBaseUnitException`, `InactiveProductUnitException`, `FloorPriceGreaterThanListPriceException`, `PriceBandWarningsRequireAcknowledgmentException` |
| `ListProductUnitPriceBandsQuery` | tenantId, productId | `ProductUnitPriceBandsDto` | PermissionDenied, NotFound, `MissingBaseUnitException` |

Package: `vet45_catalog_application` — `pricing/price_band/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `SetProductUnitPriceBandResult` | productId, productUnitId?, listPrice, floorPrice, sourceType, storePriceRuleId?, warnings[], readinessSummary |
| `ProductUnitPriceBandsDto` | productId, baseUnitName, currency, rows[] |
| `ProductUnitPriceBandRowDto` | productUnitId, unitName, isBaseUnit, isActive, listPrice?, floorPrice?, isMissing, sourceType?, storePriceRuleName?, isCustomOverride |
| `PriceBandValidationWarningDto` | code, severity, message, field, comparedBasePrice?, baseUnitName? |
| `PriceBandValidationWarningSeverity` | `warning` \| `strongWarning` |
| `PriceBandValidationField` | `listPrice` \| `floorPrice` |
| `PriceBandSourceType` | `ruleBased` \| `manual` (shared with US-02) |

Read path (PCC summary): `GetProductControlCenterQuery` → `ProductPriceBandCardDto` (base unit summary).

**Scope / rules:**

- FR-01: Giá niêm yết + Giá sàn theo từng **đơn vị đang active**; `productUnitId` omit → base unit.
- FR-02 Foundation MVP: **warn-only** so với Giá cơ sở — `confirmAcknowledgeWarnings=true` để lưu khi có warnings; block policy deferred.
- Warning codes: `list_price_below_base_price`, `floor_price_below_base_price`, `cannot_compare_base_price` (thiếu tỷ lệ quy đổi).
- FR-03: `readinessSummary` refresh; `missing_price_band` chỉ clear khi **mọi** đơn vị active có band hợp lệ.
- FR-04: change history qua BE RPC `set_product_unit_price_band`; read qua PCC `changeHistoryPreview` (không thêm query mới ở contract).
- Unit sales roles (EPIC-04/FR-02) **pending** — Foundation coi mọi đơn vị active cần band.
- `SetInitialPriceBandCommand` (guided create slice #2) giữ nguyên — không deprecate.
- Port: `IProductPriceBandGateway` (BE lane implement).

Permissions:

- `SetProductUnitPriceBandCommand` → `@RequiresPermission(CatalogPermissions.managePricing)`
- `ListProductUnitPriceBandsQuery` → `@RequiresPermission(CatalogPermissions.viewDetail)`

### RPC mapping (BE)

| Use case | RPC / view | Params (summary) | Notes |
| -------- | ---------- | ---------------- | ----- |
| Set price band | `catalog.set_product_unit_price_band` | `p_tenant_id`, `p_product_id`, `p_list_price`, `p_floor_price`, `p_product_unit_id?`, `p_source_type?`, `p_store_price_rule_id?` | Upsert per unit; `is_custom_override=true` when `source_type=manual` |
| List bands per unit | `catalog.list_product_unit_price_bands` | `p_tenant_id`, `p_product_id` | Rows for active `product_units`; left join bands + store rule name |
| Readiness facts | `catalog._product_operational_facts` (redefined) | existing | `has_price_band` true when **all** active units have valid band |

**Guards:** `inactive_product_unit`, `floor_price_greater_than_list_price`, `validation_exception` (negative prices), `missing base unit`, `product not found`

**Change history:** `set_product_unit_price_band` action with `product_unit_id`, list/floor, previous values, `source_type`, `store_price_rule_id`

Draft: [`supabase/migrations/_drafts/09_catalog_product_unit_price_band.sql`](../../../../supabase/migrations/_drafts/09_catalog_product_unit_price_band.sql)

**BE tests:** `product_unit_price_band_handlers_test.dart` (`scn_e06_u03_*`), `product_price_band_rpc_mapper_test.dart`

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e06_u03_fr01_01` | `SetProductUnitPriceBandCommand` `product-4` | band saved + readiness updated |
| `scn_contract_e06_u03_fr01_02` | floor > list | `FloorPriceGreaterThanListPriceException` |
| `scn_contract_e06_u03_fr01_03` | `ListProductUnitPriceBandsQuery` `product-9` | 2 rows Lọ/Hộp, both missing |
| `scn_contract_e06_u03_fr01_04` | set on inactive unit `product-1-unit-thung` | `InactiveProductUnitException` |
| `scn_contract_e06_u03_fr02_01` | list < base on `product-11`, no confirm | `PriceBandWarningsRequireAcknowledgmentException` |
| `scn_contract_e06_u03_fr02_02` | same with `confirmAcknowledgeWarnings=true` | success + warnings |
| `scn_contract_e06_u03_fr02_03` | conversion unit `product-11-hop` unknown rate | `cannot_compare_base_price` warning |
| `scn_contract_e06_u03_fr03_01` | set band `product-4` | readiness bỏ `missing_price_band` |
| `scn_contract_e06_u03_fr03_02` | set base only on `product-9` | blocker còn (Hộp thiếu) |

Fake seed: `product-9` (multi-UOM, no band), `product-10` (Lọ có band, Hộp thiếu), `product-11` (base 100k, warn path).

Tests: `scn_contract_e06_u03_*` in `fake_catalog_module_test.dart` (group `EPIC-06 / US-03 contract`).

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data), UOM (slice #6–7)

---

## EPIC-07 / US-01 — Bảo trì hồ sơ (slice #12)

**Status:** CONTRACT `done` · BE `done` · FE `todo`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `UpdateProductProfileCommand` | tenantId, actorId, productId, productName, commercialName?, sku?, barcode?, description?, note?, expectedVersion? | `UpdateProductProfileResult` | `ValidationException`, `DuplicateSkuException`, `DuplicateBarcodeException`, `StaleProductVersionException`, PermissionDenied, NotFound, soft-deleted lock |
| `UpdateProductImagesCommand` | tenantId, actorId, productId, images[], expectedVersion? | `UpdateProductImagesResult` | `ValidationException`, `StaleProductVersionException`, PermissionDenied, NotFound, soft-deleted lock |
| `RequestProductMaintenanceImageUploadCommand` | tenantId, actorId, productId, fileName, contentType, byteSize | `ProductImageUploadSlotDto` | `ValidationException`, PermissionDenied, NotFound, soft-deleted lock |

Package: `vet45_catalog_application` — `lifecycle/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `ProductImageMutationInput` | imageId?, storageKey, slotId?, url?, isPrimary, sortOrder |
| `ProductImageDto` | imageId, storageKey, url?, isPrimary, sortOrder |
| `UpdateProductProfileResult` | productId, profile (`ProductProfileSummaryDto`), readinessSummary, version |
| `UpdateProductImagesResult` | productId, images[], primaryImageUrl?, readinessSummary, version |
| `StaleProductVersionException` | expectedVersion, currentVersion |

Permissions:

- `UpdateProductProfileCommand` → `@RequiresPermission(CatalogPermissions.update)` + `@RequiresTenant()`
- `UpdateProductImagesCommand` → `@RequiresPermission(CatalogPermissions.update)` + `@RequiresTenant()`
- `RequestProductMaintenanceImageUploadCommand` → `@RequiresPermission(CatalogPermissions.update)` + `@RequiresTenant()`

### Contract rules

- Profile maintenance edits only identification/profile fields: name, commercial name, SKU, barcode, description, note. It does not change operational modes, UOM, stock, base price, price band, status, or soft-delete state.
- Product name is required after trim. Empty optional profile fields are persisted as absent values.
- SKU/barcode uniqueness is tenant-scoped and includes inactive / soft-deleted products until BE policy changes explicitly.
- Image maintenance uses snapshot semantics: submitted `images[]` replaces the current visible gallery. If images are present but none is primary, the first sorted image is promoted to primary.
- Deleting all images is allowed; the result returns `images=[]`, `primaryImageUrl=null`, and refreshed readiness may include `missing_image`.
- `expectedVersion` is optional optimistic concurrency. If provided and stale, return `StaleProductVersionException`.
- Soft-deleted product profile/image maintenance is locked in this contract. Restore flow belongs to EPIC-07/US-03.
- FR-03 open transaction warning is **deferred** until TH-04/Sales or another operational module exposes a lookup contract. Slice #12 adds no warning flag, no lookup port, and no cross-module dependency.

### RPC mapping (BE — later lane)

| Use case | RPC | Notes |
| -------- | --- | ----- |
| Update profile | `catalog.update_product_profile` | Update profile fields, duplicate checks, version check, change history, readiness refresh |
| Update image snapshot | `catalog.update_product_images` | Replace visible gallery, normalize primary image, change history, readiness refresh |
| Request maintenance upload | reuse upload-slot RPC or maintenance wrapper | Must use `catalog.product.update`, not `catalog.product.create` |

No SQL draft is created in CONTRACT lane.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e07_u01_fr01_01` | valid `UpdateProductProfileCommand` | updated `ProductProfileSummaryDto`, readiness, version increment |
| `scn_contract_e07_u01_fr01_02` | blank product name | `ValidationException` |
| `scn_contract_e07_u01_fr01_03` | duplicate SKU | `DuplicateSkuException` |
| `scn_contract_e07_u01_fr03_01` | duplicate barcode on inactive product | `DuplicateBarcodeException` |
| `scn_contract_e07_u01_fr01_04` | update soft-deleted product | `ApplicationException` lock |
| `scn_contract_e07_u01_fr01_05` | stale `expectedVersion` | `StaleProductVersionException` |
| `scn_contract_e07_u01_fr02_01` | replace gallery + explicit primary | images sorted, primary preserved |
| `scn_contract_e07_u01_fr02_02` | remove current primary, one image remains | first remaining image promoted |
| `scn_contract_e07_u01_fr02_03` | submit empty gallery | no primary + `missing_image` readiness blocker |
| `scn_contract_e07_u01_fr02_04` | invalid upload content type | `ValidationException` |
| `scn_contract_e07_u01_fr04_01` | profile/image update on incomplete product | refreshed readiness returned |

Tests: `scn_contract_e07_u01_*` in `fake_catalog_module_test.dart` (group `EPIC-07 / US-01 product profile maintenance contract`).

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data)

---

## EPIC-07 / US-02 — Ngừng KD / KD lại (slice #13)

**Status:** CONTRACT `done` · BE `todo` · FE `todo` · E2E `todo`

### Commands

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `DeactivateProductCommand` | tenantId, actorId, productId, reason?, expectedVersion?, confirmAcknowledgeWarnings | `ChangeProductBusinessStatusResult` (`currentStatus=inactive`) | PermissionDenied, NotFound, Validation, `StaleProductVersionException`, `ProductBusinessStatusWarningsRequireAcknowledgmentException` |
| `ReactivateProductCommand` | tenantId, actorId, productId, reason?, expectedVersion? | `ChangeProductBusinessStatusResult` (`currentStatus=active`, readinessSummary refreshed) | PermissionDenied, NotFound, Validation, `StaleProductVersionException` |

Package: `vet45_catalog_application` — `lifecycle/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `ChangeProductBusinessStatusResult` | productId, previousStatus, currentStatus, readinessSummary, version, reason?, warnings[], historyEntry? |
| `ProductBusinessStatusWarningDto` | code, message |
| `ProductBusinessStatusWarningCode` | `has_stock`, `open_transaction`, `active_promotion` |
| `ProductBusinessStatusWarningsRequireAcknowledgmentException` | warnings[] |

Permissions: `@RequiresPermission(CatalogPermissions.manageStatus)` + `@RequiresTenant()`.

### Contract rules

- Business status uses existing `ProductStatus.active` / `ProductStatus.inactive`; soft delete remains separate (`isSoftDeleted`).
- Deactivate preserves profile, UOM, stock, pricing, custom fields, readiness, and history; it only changes business status and records history.
- Deactivate may return warnings that require explicit acknowledgment. CONTRACT fake covers `has_stock`; open transactions and promotions are documented for BE/FE but require downstream module contracts.
- Reactivation is allowed even when readiness blockers remain. Result returns refreshed `readinessSummary`; UI must show blockers instead of claiming ready-to-sell.
- Soft-deleted products cannot be deactivated/reactivated in this slice. Restore belongs to EPIC-07/US-03.
- Default product selection/search for new transactions excludes inactive products by using `ProductSearchCriteria.businessStatuses` default `{active}`. Admin/history views may opt into inactive with explicit criteria.
- Sales/Promotions enforcement is downstream behavior. Catalog does not create sales-order or promotion guards in this CONTRACT lane.

### RPC mapping (BE — later lane)

| Use case | RPC | Notes |
| -------- | --- | ----- |
| Deactivate product | `catalog.deactivate_product` | Status update, warning checks, version check, change history, readiness refresh |
| Reactivate product | `catalog.reactivate_product` | Status update, soft-delete guard, version check, change history, readiness refresh |

No SQL draft is created in CONTRACT lane.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e07_u02_fr01_01` | deactivate active `product-4` | status `inactive`, version increment, PCC status updates |
| `scn_contract_e07_u02_fr01_02` | deactivate stocked `product-1` without confirm | `ProductBusinessStatusWarningsRequireAcknowledgmentException` (`has_stock`); succeeds with confirm |
| `scn_contract_e07_u02_fr01_03` | missing manage-status permission | `ApplicationException('Permission denied')` |
| `scn_contract_e07_u02_fr01_04` | deactivate already inactive product | `ValidationException` |
| `scn_contract_e07_u02_fr02_01` | reactivate inactive ready product | status `active`, readiness `readyToSell` |
| `scn_contract_e07_u02_fr02_02` | reactivate inactive incomplete product | status `active`, readiness remains incomplete with blockers |
| `scn_contract_e07_u02_fr02_03` | reactivate soft-deleted product | `ApplicationException` lock |
| `scn_contract_e07_u02_fr03_01` | search inactive product | default search excludes; explicit active+inactive returns inactive row |
| `scn_contract_e07_u02_fr04_01` | status change with reason | result includes historyEntry before/after status + actor/time summary |

Tests: `scn_contract_e07_u02_*` in `fake_catalog_module_test.dart` (group `EPIC-07 / US-02 product business status contract`).

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data)

---

## EPIC-07 / US-03 — Xóa mềm / khôi phục (slice #14)

**Status:** CONTRACT `done` · BE `todo` · FE `todo` · E2E `todo`

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `CheckProductDeletionEligibilityQuery` | tenantId, productId | `ProductDeletionEligibilityDto` | PermissionDenied, NotFound |
| `DeleteProductCommand` | tenantId, actorId, productId, reason?, expectedVersion?, confirmAcknowledgeWarnings | `ChangeProductSoftDeleteResult` (`isSoftDeleted=true`) | PermissionDenied, NotFound, Validation, `StaleProductVersionException` |
| `RestoreProductCommand` | tenantId, actorId, productId, reason?, expectedVersion? | `ChangeProductSoftDeleteResult` (`isSoftDeleted=false`, `businessStatus=inactive`, readiness refreshed) | PermissionDenied, NotFound, Validation, `StaleProductVersionException`, `DuplicateSkuException`, `DuplicateBarcodeException` |

Package: `vet45_catalog_application` — `lifecycle/`.

Supporting types:

| Type | Fields |
| ---- | ------ |
| `ProductDeletionEligibilityDto` | productId, canDelete, issues[], suggestedActionId? |
| `ProductDeletionIssueDto` | code, message, severity |
| `ProductDeletionIssueCode` | `has_historical_transactions`, `has_stock`, `open_transaction`, `active_promotion` |
| `ProductDeletionIssueSeverity` | `warning`, `blocker`, `recommendation` |
| `ChangeProductSoftDeleteResult` | productId, isSoftDeleted, businessStatus, readinessSummary, version, reason?, issues[], historyEntry? |

Permissions: `@RequiresPermission(CatalogPermissions.delete)` + `@RequiresTenant()`.

### Contract rules

- Soft delete remains a separate `isSoftDeleted` flag; do not add `ProductStatus.deleted`.
- `DeleteProductCommand` preserves profile, UOM, images, stock, pricing, custom fields, business status, readiness inputs, and change history. It only marks `isSoftDeleted=true`, increments version, and records history.
- Eligibility blockers such as `open_transaction` prevent delete even when warnings are acknowledged. Warnings can suggest `deactivate_product` instead.
- Default product search excludes soft-deleted products through `ProductSearchCriteria.includeSoftDeleted=false`; admin/history views must opt in explicitly.
- Restore is allowed only for soft-deleted products. Restore checks SKU/barcode conflicts against non-deleted products.
- Restored products return to `ProductStatus.inactive` and must show refreshed readiness blockers instead of claiming ready-to-sell.
- Soft-deleted products remain read-only for normal maintenance; profile/image maintenance remains locked until restored.
- Sales/Promotions dependency checks are contract fakes only in this lane; BE can connect module facts later.

### RPC mapping (BE — later lane)

| Use case | RPC | Notes |
| -------- | --- | ----- |
| Check delete eligibility | `catalog.check_product_deletion_eligibility` | Dependency facts, warning/blocker issue list, suggested deactivate action |
| Soft delete product | `catalog.delete_product` | Version check, dependency guard, soft-delete flag, change history |
| Restore product | `catalog.restore_product` | Version check, duplicate SKU/barcode guard, restore as inactive, readiness refresh, change history |

No SQL draft is created in CONTRACT lane.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `scn_contract_e07_u03_fr01_01` | eligibility for `product-6` | `canDelete=true`, no issues |
| `scn_contract_e07_u03_fr01_02` | eligibility/delete for `product-4` with open transaction | blocker `open_transaction`; delete throws `ValidationException` |
| `scn_contract_e07_u03_fr01_03` | historical data on `product-1` | warning `has_historical_transactions`, suggested `deactivate_product` |
| `scn_contract_e07_u03_fr02_01` | delete `product-6` | `isSoftDeleted=true`, version increment, history entry |
| `scn_contract_e07_u03_fr02_02` | stale `expectedVersion` | `StaleProductVersionException` |
| `scn_contract_e07_u03_fr02_03` | search after delete | default excludes; `includeSoftDeleted=true` includes deleted row |
| `scn_contract_e07_u03_fr03_01` | restore deleted `product-7` | `isSoftDeleted=false`, `businessStatus=inactive`, readiness blockers returned |
| `scn_contract_e07_u03_fr03_02` | restore duplicate SKU | `DuplicateSkuException` |
| `scn_contract_e07_u03_fr03_03` | restore duplicate barcode | `DuplicateBarcodeException` |
| `scn_contract_e07_u03_fr04_01` | PCC after delete | preserved units, stock, base price, price band, history |

Tests: `scn_contract_e07_u03_*` in `fake_catalog_module_test.dart` (group `EPIC-07 / US-03 product soft delete contract`).

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01 (data)

---

## EPIC-03 / US-01 — Cấu hình nhóm & trường (slice #16)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `InitializeCustomFieldTemplateCommand` | tenantId, templateId? | groups/fields created | PermissionDenied |
| `UpsertCustomFieldGroupCommand` | tenantId, groupId?, name, icon?, active | group | Validation, PermissionDenied |
| `ReorderCustomFieldGroupsCommand` | tenantId, orderedGroupIds[] | void | Validation |
| `UpsertCustomFieldCommand` | tenantId, groupId, fieldId?, name, fieldType, options? | field | Validation |
| `ConfigureCustomFieldAttributesCommand` | tenantId, fieldId, required, searchable, filterable, displayOnList | field | Validation |
| `ReorderCustomFieldsCommand` | tenantId, groupId, orderedFieldIds[] | void | Validation |
| `ListCustomFieldConfigQuery` | tenantId | groups + fields | PermissionDenied |

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Init template | `catalog.initialize_custom_field_template` |
| Upsert group / field | `catalog.upsert_custom_field_group` / `catalog.upsert_custom_field` |
| Reorder | `catalog.reorder_custom_field_groups` / `catalog.reorder_custom_fields` |
| Attributes | `catalog.configure_custom_field_attributes` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `cf_template_seed_ok` | InitializeCustomFieldTemplateCommand | default groups |
| `cf_group_upsert_ok` | UpsertCustomFieldGroupCommand | group active |
| `cf_field_required_on` | ConfigureCustomFieldAttributesCommand required=true | warning + field updated |
| `cf_permission_denied` | no catalog.custom_fields.manage | PermissionDenied |

### Parallel notes

- FE có thể fake: **yes** (admin UI cấu hình)
- E2E prerequisite: onboarding template optional

---

## Sections TODO (theo slice roadmap)

| Slice | Contract section | Status |
| ----- | ---------------- | ------ |
| EPIC-04 US-01 | Base unit set + tenant unit picker | done |
| EPIC-04 US-02 | UOM conversion (không US-03; FR-02 roles **pending**) | done |
| EPIC-05 US-01..02 | Stock profile + basic stock adjust | done |
| EPIC-06 US-01 | Manual base price (FR-03 costing read **pending**) | done |
| EPIC-06 US-02 | Store Price Rule | done |
| EPIC-06 US-03 | Product Unit Price Band | done |
| EPIC-06 US-04 | ProductPriceBandSnapshot consumers | todo |
| EPIC-07 US-01 | Product profile maintenance | done |
| EPIC-07 US-02 | Lifecycle business status | done |
| EPIC-07 US-03 | Soft delete / restore | done |
| EPIC-07 US-04 | Change history | todo |
| EPIC-03 US-02 | UpsertCustomFieldValuesCommand | todo |
| EPIC-03 US-03 | Search/filter/display on list | todo |
| EPIC-04 US-03 | Change base unit | **out_of_scope** |
| Growth (EPIC-05 US-03/04, costing read, EPIC-04 US-04) | Advanced stock / costing / UOM export | **pending** (module ngoài) |

Chi tiết FR: [EPIC index](../README.md).
