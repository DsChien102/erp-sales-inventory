# TH-02 — API contracts (FE ↔ BE) — v3

Source of truth giữa presentation và application layer. Types live in `modules/catalog/application/`. RPC mapping: [03-architecture-and-flows.md](03-architecture-and-flows.md).

Facade: `ICatalogModule` (`modules/catalog/application/lib/src/contracts/i_catalog_module.dart`).

**Access control:** `@RequiresPermission(CatalogPermissions.*)` + `@RequiresTenant()`; codegen emit `catalog_access_metadata.g.dart` — mirror [modules/partner/README.md](../../../../modules/partner/README.md).

**Quy tắc:** FE fake theo contract này — không fake RPC trực tiếp. Scenarios trong `FakeCatalogModule` (`package:vet45_catalog_application/testing.dart`).

> **Migration note (2026-07):** Spec v3 thay cấu trúc Epic cũ (EPIC-01-product / EPIC-02-pricing). Contracts dưới đây theo slice roadmap mới; bổ sung section khi từng slice vào CONTRACT lane.

---

## EPIC-02 / US-01 — Guided create (slice #1)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `CreateProductCommand` | tenantId, actorId, productName, commercialName?, sku?, barcode?, description?, note?, images[], baseUnitName | `CreateProductResult` (productId, readinessSummary) | Validation, PermissionDenied, DuplicateSku, DuplicateBarcode |
| `CheckDuplicateProductCodeQuery` | tenantId, sku?, barcode?, excludeProductId? | `List<ProductDuplicateMatchDto>` | PermissionDenied |

Package: `vet45_catalog_application` — `guided_create/`, `check_duplicate/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Create (minimal) | `catalog.create_product` |
| Dup check | `catalog.check_duplicate_product_code` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `guided_create_ok` | CreateProductCommand valid + baseUnit | `CreateProductResult` + readiness blockers |
| `guided_create_dup_sku` | sku trùng tenant | DuplicateSku |
| `guided_create_dup_barcode` | barcode trùng tenant | DuplicateBarcode |
| `guided_create_missing_name` | thiếu tên | validation error |
| `guided_create_no_images` | no images | success, optional image blocker |
| `guided_create_permission_denied` | no catalog.product.create | PermissionDenied |

### Parallel notes

- FE có thể fake: **yes** (sau CONTRACT)
- E2E prerequisite: —

---

## EPIC-02 / US-02 — Dữ liệu vận hành ban đầu (slice #2)

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

`ProductControlCenterDto` gồm: profile summary, units, stock source, base price source, price bands, readiness checklist, contextual actions[], change history preview.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `pcc_incomplete` | product missing price | checklist + "Thiết lập giá" action |
| `pcc_ready_to_sell` | all blockers cleared | readiness = Sẵn sàng bán |
| `pcc_inactive` | inactive product | limited actions |

---

## Sections TODO (theo slice roadmap)

| Slice | Contract section | Status |
| ----- | ---------------- | ------ |
| EPIC-04 US-01..03 | UOM commands/queries | todo |
| EPIC-05 US-02 | Basic stock adjust | todo |
| EPIC-06 US-01..03 | Base price, store rule, price band | todo |
| EPIC-07 US-01..04 | Lifecycle, change history | todo |
| EPIC-03 US-01..03 | Custom fields | todo |
| Growth | Advanced stock read, costing base price read | blocked |

Chi tiết FR: [EPIC index](../README.md).
