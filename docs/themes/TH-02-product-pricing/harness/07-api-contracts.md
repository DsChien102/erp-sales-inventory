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
| `SetInitialStockCommand` | tenantId, productId, quantity (basic mode) | void | Validation, NotBasicStockMode |
| `SetManualBasePriceCommand` | tenantId, productId, basePrice, currency | void | Validation, NotManualBasePriceMode |
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
| `basePrice` | `ProductBasePriceCardDto` | FR-02 | mode, amount, currency |
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
| EPIC-04 US-02 | UOM conversion (không US-03; FR-02 roles **pending**) | todo |
| EPIC-05 US-01..02 | Stock profile + basic stock adjust | todo |
| EPIC-06 US-01..03 | Manual base price, store rule, price band | todo |
| EPIC-06 US-04 | ProductPriceBandSnapshot consumers | todo |
| EPIC-07 US-01..04 | Lifecycle, change history | todo |
| EPIC-03 US-02 | UpsertCustomFieldValuesCommand | todo |
| EPIC-03 US-03 | Search/filter/display on list | todo |
| EPIC-04 US-03 | Change base unit | **out_of_scope** |
| Growth (EPIC-05 US-03/04, costing read, EPIC-04 US-04) | Advanced stock / costing / UOM export | **pending** (module ngoài) |

Chi tiết FR: [EPIC index](../README.md).
