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

**Status:** CONTRACT `done` · BE `todo`

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

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-01

---

## EPIC-01 / US-01 — Tra cứu danh mục (slice #4)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SearchProductsQuery` | tenantId, criteria (keyword, businessStatus, readinessStatus), limit, offset | `ProductSearchResultDto` | PermissionDenied |
| `ScanBarcodeQuery` | tenantId, barcode | `ProductListItemDto?` | PermissionDenied |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `search_empty` | SearchProductsQuery | empty + create CTA |
| `search_with_readiness` | filtered readiness | items with readiness chips |
| `barcode_exact_match` | ScanBarcodeQuery | single product |
| `barcode_not_found` | unknown barcode | empty + create CTA |

---

## EPIC-01 / US-02 — Product Control Center (slice #5)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetProductControlCenterQuery` | tenantId, productId | `ProductControlCenterDto` | PermissionDenied, NotFound |

`ProductControlCenterDto` gồm:

| Field | Ghi chú |
| ----- | ------- |
| profile summary | hồ sơ nhận diện, trạng thái KD |
| units, stock source, base price source, price bands | cards vận hành |
| `customFieldGroupCards[]` | group id, name, icon, sortOrder, fields[], values, requiredMissing |
| `readinessSummary` | early — status + top blockers (không thay FR-04) |
| `checklist[]` | **pending** (EPIC-01/US-02/FR-04) — không implement UI đầy đủ |
| `contextualActions[]` | reuse `ContextualActionDto` từ US-03 |
| change history preview | FR-06 |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `pcc_incomplete` | product missing price | readinessSummary blockers + "Thiết lập giá" action |
| `pcc_ready_to_sell` | all blockers cleared | readiness = Sẵn sàng bán |
| `pcc_inactive` | inactive product | limited actions |
| `pcc_custom_field_cards` | active groups | cards sau khung giá, trước ghi chú |

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
| EPIC-04 US-01..02 | UOM base + conversion (không US-03; FR-02 roles **pending**) | todo |
| EPIC-05 US-01..02 | Stock profile + basic stock adjust | todo |
| EPIC-06 US-01..03 | Manual base price, store rule, price band | todo |
| EPIC-06 US-04 | ProductPriceBandSnapshot consumers | todo |
| EPIC-07 US-01..04 | Lifecycle, change history | todo |
| EPIC-03 US-02 | UpsertCustomFieldValuesCommand | todo |
| EPIC-03 US-03 | Search/filter/display on list | todo |
| EPIC-04 US-03 | Change base unit | **out_of_scope** |
| Growth (EPIC-05 US-03/04, costing read, EPIC-04 US-04) | Advanced stock / costing / UOM export | **pending** (module ngoài) |

Chi tiết FR: [EPIC index](../README.md).
