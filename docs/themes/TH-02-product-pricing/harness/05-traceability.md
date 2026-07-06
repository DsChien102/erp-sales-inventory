# TH-02 — Traceability (v3)

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e02/u01/fr01/SCN-01
Test id: scn_e02_u01_fr01_01 (BE), wgt_e02_u01_fr01_01 (FE), e2e_e02_u01_fr01_01 (E2E)
```

**Trạng thái:** Realign theo product docs (2026-07-04). Cập nhật row khi slice lane `in_progress` / `done`.

Contracts: [07-api-contracts.md](07-api-contracts.md) — ưu tiên slice EPIC-02/US-01.

Tổng product: **7 epic, 24 US, 98 FR** (xem [README.md](../README.md#epic-index)).

---

## Platform — Catalog codegen (infrastructure)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-02-PLATFORM | BE | — | infrastructure | `build.yaml`, `CatalogCommandPipeline`, `CatalogModuleDefinition` | — | done |
| TH-02-PLATFORM | BE | — | infrastructure | `registerGeneratedCatalogHandlers`, `catalog_access_metadata.g.dart` | catalog_access_metadata_registry_test | done |

Codegen ritual: mirror [modules/partner/README.md](../../../../modules/partner/README.md).

---

## EPIC-02 / US-01 — Guided create (slice #1)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-02-US-01 | application | `CreateProductCommand`, `RequestProductImageUploadCommand`, `CheckDuplicateProductCodeQuery`, DTOs, `FakeCatalogModule` (`package:vet45_catalog_application/testing.dart`) | fake_catalog_module_test | done |
| FR-01 | BE | §EPIC-02-US-01 | application | `CreateProductCommandHandler`, `Product.create` (nhận diện + ảnh) | scn_e02_u01_fr01_01 | done |
| FR-01 | BE | §EPIC-02-US-01 | application + infrastructure | `RequestProductImageUploadCommandHandler`, `IProductImageUploadPort`, draft RPC `request_product_image_upload`, Storage bucket | request_product_image_upload_command_handler_test | done |
| FR-02 | BE | §EPIC-02-US-01 | application | `CheckDuplicateProductCodeQueryHandler`, `IProductDuplicateChecker`, draft RPC | scn_e02_u01_fr02_01 | done |
| FR-03 | BE | §EPIC-02-US-01 | application | Base unit in create flow + readiness blocker | scn_e02_u01_fr03_01 | done |
| FR-04 | BE | §EPIC-02-US-01 | application | Initial status active + readiness seed + change history (RPC) | scn_e02_u01_fr04_01 | done |
| FR-01..04 | FE | §EPIC-02-US-01 | presentation | Guided create flow + image upload (`ProductImagePickerPanel`, `ProductImageUploadClient`, staging via command) | wgt_e02_u01_fr01_01 (`product_guided_create_page_test.dart`) | done |
| FR-01 | E2E | §EPIC-02-US-01 | integration | ERP via `ICatalogModule` (`CatalogStartup` + `product_guided_create_e2e_test.dart`) | e2e_e02_u01_fr01_01 | done |

---

## EPIC-02 / US-02 — Dữ liệu vận hành ban đầu (slice #2)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §EPIC-02-US-02 | application | `SetInitialStockCommand`, `SetManualBasePriceCommand`, DTOs, `FakeCatalogModule` | — | done |
| FR-01 | BE | §EPIC-02-US-02 | application | `SetInitialStockCommandHandler` | scn_e02_u02_fr01_01 | done |
| FR-02 | BE | §EPIC-02-US-02 | application | `SetManualBasePriceCommandHandler` | scn_e02_u02_fr02_01 | done |
| FR-01..03 | FE | §EPIC-02-US-02 | presentation | `product_guided_step_inventory.dart`, `product_guided_step_base_cost.dart`, `product_guided_step_price_bands.dart` | wgt_e02_u02_fr01_01 | done |
| FR-01..03 | E2E | §EPIC-02-US-02 | integration | ERP via `ICatalogModule` (`CatalogStartup` + `product_guided_create_e2e_test.dart`) | e2e_e02_u02_fr01_01 | done |

---

## EPIC-02 / US-03 — Hoàn tất create + readiness summary (slice #3)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §EPIC-02-US-03 | application | `GetProductReadinessQuery`, `ProductReadinessViewDto`, `ReadinessChecklistItemDto`, `ContextualActionDto`, `IProductReadinessReadPort`, `FakeCatalogModule` | fake_catalog_module_test | done |
| FR-01 | CONTRACT | §EPIC-02-US-03 | application | Checklist groups + item status enums | scn_e02_u03_fr01_01..05 | done |
| FR-02 | CONTRACT | §EPIC-02-US-03 | application | `productId` + readiness view for post-create navigation | scn_e02_u03_fr02_04 | done |
| FR-03 | CONTRACT | §EPIC-02-US-03 | application | `ContextualActionDto` + `primaryActionId` | scn_e02_u03_fr03_01, scn_e02_u03_fr03_03 | done |
| FR-04 | CONTRACT | §EPIC-02-US-03 | application | `GetProductReadinessQuery` refresh path | scn_e02_u03_fr04_01 | done |
| FR-01..04 | BE | §EPIC-02-US-03 | application + domain + infrastructure | `GetProductReadinessQueryHandler`, `ProductReadinessEvaluator`, `ProductReadinessViewAssembler`, `IProductReadinessReadPort`, `SupabaseProductReadinessReadGateway`, draft RPC `catalog.get_product_readiness` | scn_e02_u03_fr01_01, scn_e02_u03_fr03_03, scn_e02_u03_fr04_01 | done |
| FR-01..04 | FE | §EPIC-02-US-03 | presentation | Post-create result + readiness checklist UI | wgt_e02_u03_fr01_01 | done |
| FR-01 | E2E | §EPIC-02-US-03 | integration | Post-create PCC readiness blockers via `ICatalogModule` | e2e_e02_u03_fr01_01 | done |
| FR-01 | E2E | §EPIC-02-US-03 | integration | Ready-to-sell badge after full fake create | e2e_e02_u03_fr01_05 | done |
| FR-02 | E2E | §EPIC-02-US-03 | integration | Navigate to PCC on success; stay on form on failure | e2e_e02_u03_fr02_04 | done |
| FR-03 | E2E | §EPIC-02-US-03 | integration | Checklist blocker + CTA for missing base unit | e2e_e02_u03_fr03_01 | done |
| FR-04 | E2E | §EPIC-02-US-03 | integration | Refresh readiness on PCC load after base unit create | e2e_e02_u03_fr04_01 | done |

---

## EPIC-01 / US-01 — Tra cứu danh mục (slice #4)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-01-US-01 | application | `SearchProductsQuery`, `ScanBarcodeQuery`, `ProductListItemDto`, `ProductSearchCriteria`, `ICatalogReadGateway`, `FakeCatalogModule` | scn_contract_e01_u01_* | done |
| FR-01 | BE | §EPIC-01-US-01 | application | Search + barcode handler | scn_e01_u01_fr01_01 | done |
| FR-03 | BE | §EPIC-01-US-01 | application | Readiness chip in list DTO | scn_e01_u01_fr03_01 | done |
| FR-01..04 | FE | §EPIC-01-US-01 | presentation | Product list page + filters | wgt_e01_u01_fr01_01 | done |
| FR-01 | E2E | §EPIC-01-US-01 | integration | Search E2E | e2e_e01_u01_fr01_01 | done |

---

## EPIC-01 / US-02 — Product Control Center (slice #5)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §EPIC-01-US-02 | application | `GetProductControlCenterQuery`, `ProductControlCenterDto`, card DTOs, `ICatalogReadGateway`, `FakeCatalogModule` | scn_contract_e01_u02_* | done |
| FR-01 | BE | §EPIC-01-US-02 | application | Profile summary projection | scn_e01_u02_fr01_01 | done |
| FR-02 | BE | §EPIC-01-US-02 | application | Units / stock / base price / price band cards | scn_e01_u02_fr02_01 | done |
| FR-03 | BE | §EPIC-01-US-02 | application | Custom field group cards | scn_e01_u02_fr03_01 | done |
| FR-04 | BE | §EPIC-01-US-02 | application | Readiness checklist projection | — | **pending** |
| FR-04 | FE | §EPIC-01-US-02 | presentation | Checklist UI đầy đủ | — | **pending** |
| FR-05 | BE | §EPIC-01-US-02 | application | Contextual actions by permission/status | scn_e01_u02_fr05_01 | done |
| FR-06 | BE | §EPIC-01-US-02 | application | Change history preview | scn_e01_u02_fr06_01 | done |
| FR-01..03,05..06 | FE | §EPIC-01-US-02 | presentation | `product_control_center_page.dart` | wgt_e01_u02_fr01_01 | done |
| FR-01 | E2E | §EPIC-01-US-02 | integration | Detail E2E | e2e_e01_u02_fr01_01 | done |

Early: `readinessSummary` trên PCC (không thay FR-04 checklist đầy đủ).

---

## EPIC-03 / US-01 — Cấu hình nhóm & trường (slice #16)

Mở đầy đủ khi CONTRACT lane bắt đầu.

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-03-US-01 | application | Template init, upsert group/field, reorder, attributes | — | todo |
| FR-01 | BE | §EPIC-03-US-01 | application | `InitializeCustomFieldTemplateCommand` | scn_e03_u01_fr01_01 | todo |
| FR-02 | BE | §EPIC-03-US-01 | application | Upsert group | scn_e03_u01_fr02_01 | todo |
| FR-03 | BE | §EPIC-03-US-01 | application | Reorder groups | scn_e03_u01_fr03_01 | todo |
| FR-04 | BE | §EPIC-03-US-01 | application | Upsert field | scn_e03_u01_fr04_01 | todo |
| FR-05 | BE | §EPIC-03-US-01 | application | Configure attributes | scn_e03_u01_fr05_01 | todo |
| FR-06 | BE | §EPIC-03-US-01 | application | Reorder fields | scn_e03_u01_fr06_01 | todo |
| FR-01..06 | FE | §EPIC-03-US-01 | presentation | Admin cấu hình nhóm & trường | wgt_e03_u01_fr01_01 | todo |

---

## EPIC-04 / US-01 — Đơn vị cơ sở (slice #6)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-04-US-01 | application | `SetProductBaseUnitCommand`, `ListTenantMeasurementUnitsQuery`, `CheckDuplicateMeasurementUnitNameQuery`, DTOs, `ICatalogUnitGateway`, `FakeCatalogModule` | scn_contract_e04_u01_* | done |
| FR-01 | CONTRACT | §EPIC-04-US-01 | application | Chọn/tạo base unit types | scn_contract_e04_u01_fr01_* | done |
| FR-02 | CONTRACT | §EPIC-04-US-01 | application | Dependency gating documented + fake readiness | scn_contract_e04_u01_fr02_* | done |
| FR-03 | CONTRACT | §EPIC-04-US-01 | application | Readiness refresh via result / `GetProductReadinessQuery` | scn_contract_e04_u01_fr03_* | done |
| FR-01 | BE | §EPIC-04-US-01 | application | `SetProductBaseUnitCommandHandler`, gateway, draft RPC | scn_e04_u01_fr01_01 | done |
| FR-02 | BE | §EPIC-04-US-01 | application | Domain gating on dependent commands | scn_e04_u01_fr02_01 | done |
| FR-03 | BE | §EPIC-04-US-01 | application | Readiness refresh after set | scn_e04_u01_fr03_01 | done |
| FR-01..03 | FE | §EPIC-04-US-01 | presentation | `product_measurement_units_page.dart`, `product_measurement_units_cubit.dart` | wgt_e04_u01_fr01_01 | done |
| FR-01 | E2E | §EPIC-04-US-01 | integration | Set base unit E2E | e2e_e04_u01_fr01_01 | done |

---

## EPIC-04 / US-02 — Đơn vị quy đổi (slice #7)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §EPIC-04-US-02 | application | `ListProductUnitsQuery`, conversion unit commands, DTOs, `ICatalogUnitGateway`, `FakeCatalogModule` | scn_contract_e04_u02_* | done |
| FR-01 | CONTRACT | §EPIC-04-US-02 | application | Add conversion unit contract | scn_contract_e04_u02_fr01_* | done |
| FR-02 | CONTRACT | §EPIC-04-US-02 | application | Unit roles documented only; no role fields/toggles | — | **pending** |
| FR-03 | CONTRACT | §EPIC-04-US-02 | application | Deactivate conversion unit contract | scn_contract_e04_u02_fr03_* | done |
| FR-04 | CONTRACT | §EPIC-04-US-02 | application | Reactivate conversion unit contract | scn_contract_e04_u02_fr04_* | done |
| FR-01 | BE | §EPIC-04-US-02 | application + infrastructure | `ListProductUnitsQueryHandler`, `AddProductConversionUnitCommandHandler`, `SupabaseCatalogUnitGateway`, draft RPC `list_product_units` / `add_product_conversion_unit` | scn_e04_u02_fr01_01 | done |
| FR-02 | BE | §EPIC-04-US-02 | application | Unit roles (bán/nhập/hiển thị) | — | **pending** |
| FR-03 | BE | §EPIC-04-US-02 | application | Deactivate unit | scn_e04_u02_fr03_01 | todo |
| FR-04 | BE | §EPIC-04-US-02 | application | Reactivate unit | scn_e04_u02_fr04_01 | todo |
| FR-01..04 | FE | §EPIC-04-US-02 | presentation | `product_measurement_units_page.dart`, `product_measurement_units_cubit.dart` | wgt_e04_u01_fr01_01 | done |
| FR-01 | E2E | §EPIC-04-US-02 | integration | Add conversion unit E2E | e2e_e04_u02_fr01_01 | done |
| FR-01 EC-01 | E2E | §EPIC-04-US-02 | integration | Gating without base unit | e2e_e04_u02_fr01_02 | done |
| FR-01 EC-02 | E2E | §EPIC-04-US-02 | integration | Invalid rate validation | e2e_e04_u02_fr01_03 | done |
| FR-01 EC-03/04 | E2E | §EPIC-04-US-02 | integration | Duplicate conversion unit | e2e_e04_u02_fr01_04 | done |
| FR-03 | E2E | §EPIC-04-US-02 | integration | Deactivate conversion unit | e2e_e04_u02_fr03_01 | done |
| FR-04 | E2E | §EPIC-04-US-02 | integration | Reactivate conversion unit | e2e_e04_u02_fr04_01 | done |
| FR-03 | BE | §EPIC-04-US-02 | application + infrastructure | `DeactivateProductConversionUnitCommandHandler`, gateway, draft RPC `deactivate_product_conversion_unit` | scn_e04_u02_fr03_01 | done |
| FR-04 | BE | §EPIC-04-US-02 | application + infrastructure | `ReactivateProductConversionUnitCommandHandler`, gateway, draft RPC `reactivate_product_conversion_unit` | scn_e04_u02_fr04_01 | done |

---

## EPIC-05 / US-01..02 — Stock profile + basic stock (slice #8)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-05-US-01-US-02 | application | `ProductStockCardDto` mở rộng (`source`, `isConfigured`, `isOutOfStock`, `canAdjust`, `currentVersion`), `StockDataSource`, `FakeCatalogModule` | scn_contract_e05_u01_* | done |
| FR-01 | CONTRACT | §EPIC-05-US-01-US-02 | application | Stock profile card hiển thị mode/source | scn_contract_e05_u01_fr01_01 | done |
| FR-02 | CONTRACT | §EPIC-05-US-01-US-02 | application | Advanced source read-only contract | scn_contract_e05_u01_fr02_01 | done |
| FR-03 | CONTRACT | §EPIC-05-US-01-US-02 | application | Distinguish configured vs out-of-stock | scn_contract_e05_u01_fr03_01 | done |
| US-02 | CONTRACT | §EPIC-05-US-01-US-02 | application | `AdjustBasicStockCommand`, `GetProductStockHistoryQuery`, movement/history DTOs, stock ports, `SetInitialStockResult` | scn_contract_e05_u02_* | done |
| FR-01 | CONTRACT | §EPIC-05-US-01-US-02 | application | `SetInitialStockCommand` result + readiness refresh | scn_contract_e05_u02_fr01_* | done |
| FR-02 | CONTRACT | §EPIC-05-US-01-US-02 | application | `AdjustBasicStockCommand` + stale quantity error | scn_contract_e05_u02_fr02_* | done |
| FR-03 | CONTRACT | §EPIC-05-US-01-US-02 | application | `GetProductStockHistoryQuery` + movement projection | scn_contract_e05_u02_fr03_01 | done |
| FR-04 | CONTRACT | §EPIC-05-US-01-US-02 | application | readiness refresh after stock update | scn_contract_e05_u02_fr04_01 | done |
| FR-01 | BE | §EPIC-05-US-01-US-02 | application + infrastructure | PCC stock card (`ProductControlCenterAssembler`, `get_product_control_center` + `stock_version`) | scn_e05_u01_fr01_01 | done |
| FR-02 | BE | §EPIC-05-US-01-US-02 | application | Advanced stock read-only card projection | scn_e05_u01_fr02_01 | done |
| FR-03 | BE | §EPIC-05-US-01-US-02 | application | `isConfigured` / `isOutOfStock` distinction (qty=0) | scn_e05_u01_fr03_01 | done |
| FR-01 | BE | §EPIC-05-US-01-US-02 | application + infrastructure | `SetInitialStockCommandHandler` + draft RPC `set_initial_stock` (movements) | scn_e05_u02_fr01_01 | done |
| FR-02 | BE | §EPIC-05-US-01-US-02 | application + infrastructure | `AdjustBasicStockCommandHandler`, `SupabaseCatalogStockGateway`, draft RPC `adjust_basic_stock` | scn_e05_u02_fr02_01 | done |
| FR-03 | BE | §EPIC-05-US-01-US-02 | application + infrastructure | `GetProductStockHistoryQueryHandler`, `SupabaseProductStockReadGateway`, draft RPC `get_product_stock_history` | scn_e05_u02_fr03_01 | done |
| FR-04 | BE | §EPIC-05-US-01-US-02 | application | readiness refresh after set/adjust stock | scn_e05_u02_fr04_01 | done |
| FR-01..04 | FE | §EPIC-05-US-01-US-02 | presentation | `product_stock_adjustment_page.dart` | wgt_e05_u01_fr01_01 | done |
| FR-01 | E2E | §EPIC-05-US-01-US-02 | erp | PCC basic stock card | e2e_e05_u01_fr01_01 | done |
| FR-02 | E2E | §EPIC-05-US-01-US-02 | erp | Advanced stock read-only (no navigation) | e2e_e05_u01_fr02_01 | done |
| FR-03 | E2E | §EPIC-05-US-01-US-02 | erp | Zero qty configured, not missing | e2e_e05_u01_fr03_01 | done |
| FR-01 | E2E | §EPIC-05-US-01-US-02 | erp | Set initial stock from PCC | e2e_e05_u02_fr01_01 | done |
| FR-02 | E2E | §EPIC-05-US-01-US-02 | erp | Adjust stock with reason | e2e_e05_u02_fr02_01 | done |
| FR-03 | E2E | §EPIC-05-US-01-US-02 | erp | Stock history UI | — | n/a |
| FR-04 | E2E | §EPIC-05-US-01-US-02 | erp | Readiness refresh after set stock | e2e_e05_u02_fr04_01 | done |

---

## EPIC-06 / US-01 — Manual base price (slice #9)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-06-US-01 | application | `SetManualBasePriceCommand`, `SetManualBasePriceResult`, `ProductBasePriceCardDto`, `FakeCatalogModule` | scn_contract_e06_u01_* | done |
| FR-01 | CONTRACT | §EPIC-06-US-01 | application | Base price mode + source label on PCC card | scn_contract_e06_u01_fr01_* | done |
| FR-02 | CONTRACT | §EPIC-06-US-01 | application | Manual base price command + gating | scn_contract_e06_u01_fr02_* | done |
| FR-03 | CONTRACT | §EPIC-06-US-01 | application | Costing read gateway | — | **pending** (slice #23) |
| FR-04 | CONTRACT | §EPIC-06-US-01 | application | Readiness refresh via result | scn_contract_e06_u01_fr04_01 | done |
| FR-01 | BE | §EPIC-06-US-01 | application + infrastructure | `SetManualBasePriceCommandHandler`, gateway, draft RPC | scn_e06_u01_fr01_01 | done |
| FR-02 | BE | §EPIC-06-US-01 | application | Manual entry + base unit gating | scn_e06_u01_fr02_01 | done |
| FR-03 | BE | §EPIC-06-US-01 | application | Costing module read | — | **pending** |
| FR-04 | BE | §EPIC-06-US-01 | application | Readiness refresh after set | scn_e06_u01_fr04_01 | done |
| FR-01..04 | FE | §EPIC-06-US-01 | presentation | `apps/erp/lib/features/catalog/presentation/pages/product_manual_base_price_page.dart`, `apps/erp/lib/features/catalog/presentation/pages/product_control_center_page.dart`, `modules/catalog/presentation/lib/src/bloc/product_manual_base_price_cubit.dart` | wgt_e06_u01_fr01_01 | done |
| FR-01 | E2E | §EPIC-06-US-01 | erp | PCC base price card (manual / costing / missing) | e2e_e06_u01_fr01_01..03 | done |
| FR-02 | E2E | §EPIC-06-US-01 | erp | Manual base price entry + base unit gating | e2e_e06_u01_fr02_01..02 | done |
| FR-03 | E2E | §EPIC-06-US-01 | erp | Costing module read | — | **pending** (slice #23) |
| FR-04 | E2E | §EPIC-06-US-01 | erp | Readiness refresh after set price | e2e_e06_u01_fr04_01 | done |

---

## EPIC-06 / US-02 — Store Price Rule (slice #10)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §EPIC-06-US-02 | application | Store rule + suggestion + apply commands/queries, DTOs, `FakeCatalogModule` | scn_contract_e06_u02_* | done |
| FR-01 | CONTRACT | §EPIC-06-US-02 | application | `GetStorePriceRuleQuery`, `SetStorePriceRuleCommand`, `StorePriceRuleDto` | scn_contract_e06_u02_fr01_* | done |
| FR-02 | CONTRACT | §EPIC-06-US-02 | application | `SuggestProductUnitPriceQuery`, `ProductUnitPriceSuggestionDto` | scn_contract_e06_u02_fr02_* | done |
| FR-03 | CONTRACT | §EPIC-06-US-02 | application | `ApplyStorePriceRuleCommand`, `ApplyStorePriceRuleResult` | scn_contract_e06_u02_fr03_* | done |
| FR-04 | CONTRACT | §EPIC-06-US-02 | application | `ProductPriceBandCardDto` override fields; `SetProductUnitPriceBandCommand` stub (slice #11) | scn_contract_e06_u02_fr04_01 | done |
| FR-01 | BE | §EPIC-06-US-02 | application + infrastructure | `GetStorePriceRuleQueryHandler`, `SetStorePriceRuleCommandHandler`, `SupabaseStorePriceRuleGateway`, draft RPC | scn_e06_u02_fr01_01 | done |
| FR-02 | BE | §EPIC-06-US-02 | application + infrastructure | `SuggestProductUnitPriceQueryHandler`, `suggest_product_unit_price` RPC | scn_e06_u02_fr02_01 | done |
| FR-03 | BE | §EPIC-06-US-02 | application + infrastructure | `ApplyStorePriceRuleCommandHandler`, `apply_store_price_rule` RPC | scn_e06_u02_fr03_01 | done |
| FR-04 | BE | §EPIC-06-US-02 | application + infrastructure | PCC price band metadata projection | scn_e06_u02_fr04_01 | done |

---

## EPIC-04 / US-03 — Đổi đơn vị cơ sở

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | — | — | — | — | out_of_scope |
| FR-01..04 | BE | — | — | — | — | out_of_scope |
| FR-01..04 | FE | — | — | — | — | out_of_scope |
| FR-01..04 | E2E | — | — | — | — | out_of_scope |

---

## Các slice còn lại

Thêm row theo [04-slice-roadmap.md](04-slice-roadmap.md) khi bắt đầu CONTRACT lane.

Growth (EPIC-05/US-03, US-04; EPIC-06 costing read; EPIC-04/US-04): status **pending** — không assign BE/FE active.
