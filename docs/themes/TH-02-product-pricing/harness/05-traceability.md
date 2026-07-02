# TH-02 — Traceability

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e01/u01/fr01/SCN-01
Test id: scn_e01_u01_fr01_01 (BE), wgt_e01_u04_fr01_01 (FE), e2e_e01_u01_fr01_01 (E2E)
```

<!-- exemplar-complete: deferred -->

**Exemplar:** deferred — greenfield catalog module; cập nhật khi slice US-01 lane BE/FE/E2E done.

Contracts: [07-api-contracts.md](07-api-contracts.md)

---

## Platform — Catalog codegen (infrastructure)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-02-PLATFORM | BE | — | infrastructure | `build.yaml` (4 builders), `CatalogCommandPipeline`, `CatalogModuleDefinition` | — | todo |
| TH-02-PLATFORM | BE | — | infrastructure | `registerGeneratedCatalogHandlers` / `catalog_access_metadata.g.dart` | catalog_access_metadata_registry_test | todo |

Codegen ritual: mirror [modules/partner/README.md](../../../../modules/partner/README.md) khi bật catalog.

---

## Epic-01 / US-01 — Ghi nhận hồ sơ sản phẩm mới

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §US-01 | application | `CreateProductCommand`, `CheckDuplicateProductCodeQuery`, DTOs | — | todo |
| FR-01 | BE | §US-01 | application | `CreateProductCommandHandler` | scn_e01_u01_fr01_01 | todo |
| FR-01 | BE | §US-01 | infrastructure | `catalog.create_product` RPC | — | todo |
| FR-02 | BE | §US-01 | application | `UpdateProductImages` (within create) | scn_e01_u01_fr02_01 | todo |
| FR-03 | BE | §US-01 | application | initial stock in create handler | scn_e01_u01_fr03_01 | todo |
| FR-01..03 | FE | §US-01 | presentation | `product_create_page.dart`, cubit, form widgets | wgt_e01_u01_fr01_01 | todo |
| FR-01 | E2E | §US-01 | integration | ERP via `ICatalogModule` | e2e_e01_u01_fr01_01 | todo |

---

## Epic-01 / US-02 — Tra cứu và xem hồ sơ sản phẩm

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §US-02 | application | `SearchProductsQuery`, `ProductSearchResultDto` | — | todo |
| FR-01 | BE | §US-02 | application | `SearchProductsQueryHandler` (criteria) | scn_e01_u02_fr01_01 | todo |
| FR-02 | BE | §US-02 | application | list DTO + pagination | scn_e01_u02_fr02_01 | todo |
| FR-03 | BE | §US-02 | application | `GetProductDetailQueryHandler` | scn_e01_u02_fr03_01 | todo |
| FR-01..02 | FE | §US-02 | presentation | `product_list_page.dart`, search/filter widgets | wgt_e01_u02_fr01_01 | todo |
| FR-03 | FE | §US-02 | presentation | `product_detail_page.dart`, detail cubit/widgets | wgt_e01_u02_fr03_01 | todo |
| FR-01..03 | E2E | §US-02 | integration | list + detail with real data | e2e_e01_u02_fr01_01 | todo |

---

## Epic-01 / US-03 — Chỉnh sửa thông tin hồ sơ sản phẩm

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §US-03 | application | `UpdateProductProfileCommand`, `UpdateProductImagesCommand`, `AdjustBasicStockCommand` | — | todo |
| FR-01 | BE | §US-03 | application | `UpdateProductProfileCommandHandler` | scn_e01_u03_fr01_01 | todo |
| FR-02 | BE | §US-03 | application | `UpdateProductImagesCommandHandler` | scn_e01_u03_fr02_01 | todo |
| FR-03 | BE | §US-03 | application | `AdjustBasicStockCommandHandler` | scn_e01_u03_fr03_01 | todo |
| FR-01..03 | FE | §US-03 | presentation | `product_edit_page.dart`, edit cubit/widgets | wgt_e01_u03_fr01_01 | todo |
| FR-03 | E2E | §US-03 | integration | edit + stock adjust via real module | e2e_e01_u03_fr03_01 | todo |

---

## Epic-01 / US-04 — Quản lý trạng thái kinh doanh

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-04 | CONTRACT | §US-04 | application | `DeactivateProductCommand`, `ReactivateProductCommand`, `DeleteProductCommand` | — | todo |
| FR-01 | BE | §US-04 | application | `DeactivateProductCommandHandler` | scn_e01_u04_fr01_01 | todo |
| FR-02 | BE | §US-04 | application | `ReactivateProductCommandHandler` | scn_e01_u04_fr02_01 | todo |
| FR-03 | BE | §US-04 | application | `DeleteProductCommandHandler` | scn_e01_u04_fr03_01 | todo |
| FR-01 | FE | §US-04 | presentation | `deactivate_product_dialog.dart` | wgt_e01_u04_fr01_01 | todo |
| FR-02 | FE | §US-04 | presentation | `reactivate_product_dialog.dart` | wgt_e01_u04_fr02_01 | todo |
| FR-03 | FE | §US-04 | presentation | `delete_product_dialog.dart` | wgt_e01_u04_fr03_01 | todo |
| FR-01..03 | E2E | §US-04 | integration | status flows via real module | e2e_e01_u04_fr01_01 | todo |

---

## Epic-01 / US-05 — Quản lý đơn vị đo lường

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-05 | CONTRACT | §US-05 | application | UOM commands (`AddProductUnitCommand`, …, `ChangeBaseUnitCommand`) | — | todo |
| FR-01 | BE | §US-05 | application | `AddProductUnitCommandHandler` | scn_e01_u05_fr01_01 | todo |
| FR-02 | BE | §US-05 | application | `DeactivateProductUnitCommandHandler` | scn_e01_u05_fr02_01 | todo |
| FR-03 | BE | §US-05 | application | `ReactivateProductUnitCommandHandler` | scn_e01_u05_fr03_01 | todo |
| FR-04 | BE | §US-05 | application | `DeleteProductUnitCommandHandler` | scn_e01_u05_fr04_01 | todo |
| FR-05 | BE | §US-05 | application | `ChangeBaseUnitCommandHandler` | scn_e01_u05_fr05_01 | todo |
| FR-01..05 | FE | §US-05 | presentation | `product_units_section.dart`, UOM dialogs | wgt_e01_u05_fr01_01 | todo |
| FR-05 | E2E | §US-05 | integration | change base unit flow | e2e_e01_u05_fr05_01 | todo |

---

## Epic-02 / US-01 — Giá cấp cửa hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §US-01 | application | `SetStorePricingSettingCommand`, `UnsetStorePricingSettingCommand`, `GetStorePricingSettingQuery` | — | todo |
| FR-01 | BE | §US-01 | application | `SetStorePricingSettingCommandHandler` | scn_e02_u01_fr01_01 | todo |
| FR-02 | BE | §US-01 | application | `UnsetStorePricingSettingCommandHandler` | scn_e02_u01_fr02_01 | todo |
| FR-01..02 | FE | §US-01 | presentation | `store_pricing_setting_page.dart` | wgt_e02_u01_fr01_01 | todo |
| FR-01 | E2E | §US-01 | integration | store pricing via real module | e2e_e02_u01_fr01_01 | todo |

---

## Epic-02 / US-02 — Giá cấp sản phẩm & theo UOM

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §US-02 | application | `SetProductPriceModeCommand`, `SetProductPriceCommand`, `SetProductUnitPriceCommand`, `GetProductPriceHistoryQuery` | — | todo |
| FR-01 | BE | §US-02 | application | `SetProductPriceModeCommandHandler` | scn_e02_u02_fr01_01 | todo |
| FR-02 | BE | §US-02 | application | `SetProductPriceCommandHandler` | scn_e02_u02_fr02_01 | todo |
| FR-03 | BE | §US-02 | application | `SetProductUnitPriceCommandHandler` | scn_e02_u02_fr03_01 | todo |
| FR-01..03 | FE | §US-02 | presentation | `product_pricing_section.dart`, unit price widgets | wgt_e02_u02_fr01_01 | todo |
| FR-02 | E2E | §US-02 | integration | product pricing flow | e2e_e02_u02_fr02_01 | todo |
