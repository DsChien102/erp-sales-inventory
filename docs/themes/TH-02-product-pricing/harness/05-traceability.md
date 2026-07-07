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

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-03-US-01 | application | `InitializeCustomFieldTemplateCommand`, `UpsertCustomFieldGroupCommand`, `ReorderCustomFieldGroupsCommand`, `UpsertCustomFieldCommand`, `ConfigureCustomFieldAttributesCommand`, `ReorderCustomFieldsCommand`, `ListCustomFieldConfigQuery`, DTOs, `ICatalogCustomFieldConfigGateway`, `FakeCatalogModule` | scn_contract_e03_u01_* | done |
| FR-01 | BE | §EPIC-03-US-01 | application | `InitializeCustomFieldTemplateCommandHandler`, gateway, draft RPC | scn_e03_u01_fr01_01 (`custom_field_config_command_handlers_test.dart`) | done |
| FR-02 | BE | §EPIC-03-US-01 | application | Upsert group handler + gateway | scn_e03_u01_fr02_01 | done |
| FR-03 | BE | §EPIC-03-US-01 | application | Reorder groups handler + gateway | scn_e03_u01_fr03_01 | done |
| FR-04 | BE | §EPIC-03-US-01 | application | Upsert field handler + gateway | scn_e03_u01_fr04_01 | done |
| FR-05 | BE | §EPIC-03-US-01 | application | Configure attributes handler + gateway | scn_e03_u01_fr05_01 | done |
| FR-06 | BE | §EPIC-03-US-01 | application | Reorder fields handler + gateway | scn_e03_u01_fr06_01 | done |
| FR-01..06 | FE | §EPIC-03-US-01 | presentation | `custom_field_groups_page.dart`, `upsert_custom_field_group_page.dart`, `custom_field_group_detail_page.dart`, `upsert_custom_field_page.dart`, `custom_field_config_cubit.dart` | wgt_e03_u01_fr01_01 | done |
| FR-01..06 | E2E | §EPIC-03-US-01 | integration | Custom field settings integration flow via ERP DI real module (`buildCustomFieldSettingsRouter`) | e2e_e03_u01_fr01_01, e2e_e03_u01_fr02_01, e2e_e03_u01_fr03_01, e2e_e03_u01_fr04_02, e2e_e03_u01_fr05_01, e2e_e03_u01_fr06_01 (`product_custom_field_config_e2e_test.dart`) | done |

---

## EPIC-03 / US-02 — Giá trị thông tin bổ sung trên SP (slice #17)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §EPIC-03-US-02 | application | `GetProductCustomFieldValuesQuery`, `UpsertCustomFieldValuesCommand`, value DTOs, `ICatalogCustomFieldValueGateway`, `FakeCatalogModule` | scn_contract_e03_u02_* | done |
| FR-01 | CONTRACT | §EPIC-03-US-02 | application | `ProductCustomFieldValuesDto` group/card projection sorted by config | scn_contract_e03_u02_fr01_01 | done |
| FR-02 | CONTRACT | §EPIC-03-US-02 | application | `ProductCustomFieldValueInput`, typed values, field-level validation exception, PCC display value | scn_contract_e03_u02_fr02_01..02 | done |
| FR-03 | CONTRACT | §EPIC-03-US-02 | application | Required field validation + readiness refresh via `UpsertCustomFieldValuesResult.readinessSummary` | scn_contract_e03_u02_fr03_01..02 | done |
| FR-04 | CONTRACT | §EPIC-03-US-02 | application | Preserve inactive group/field values; hide from active query unless `includeInactiveValues=true` | scn_contract_e03_u02_fr04_01 | done |
| FR-01..04 | FE | §EPIC-03-US-02 | presentation | `product_custom_field_group_edit_page.dart`, `product_custom_field_group_edit_cubit.dart`, `product_custom_field_input_widget.dart`, `app_router.dart` | wgt_e03_u02_fr01_01 | done |
| FR-01 | E2E | §EPIC-03-US-02 | integration | PCC custom field group cards via ERP DI (`product_custom_field_values_e2e_test.dart`) | e2e_e03_u02_fr01_01 | done |
| FR-02 | E2E | §EPIC-03-US-02 | integration | Save text value + invalid number field validation | e2e_e03_u02_fr02_01, e2e_e03_u02_fr02_02 | done |
| FR-03 | E2E | §EPIC-03-US-02 | integration | Required field validation + readiness refresh | e2e_e03_u02_fr03_01, e2e_e03_u02_fr03_02 | done |
| FR-04 | E2E | §EPIC-03-US-02 | integration | Preserve inactive values (contract only) | — | n/a |

---

## EPIC-03 / US-03 — Search / filter / display on list (slice #18)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §EPIC-03-US-03 | application | `SearchProductsQuery`, `ListCustomFieldFilterOptionsQuery`, `GetProductCustomFieldSnapshotQuery`, custom field list/filter/snapshot DTOs, `FakeCatalogModule` | scn_contract_e03_u03_* | done |
| FR-01 | CONTRACT | §EPIC-03-US-03 | application | `ProductListItemDto.customFieldValues` ordered by group/field sort | scn_contract_e03_u03_fr01_01 | done |
| FR-02 | CONTRACT | §EPIC-03-US-03 | application | `ProductSearchCriteria.keyword` matches active searchable custom fields | scn_contract_e03_u03_fr02_01 | done |
| FR-03 | CONTRACT | §EPIC-03-US-03 | application | `CustomFieldFilterCriteria` + `ListCustomFieldFilterOptionsQuery` for active filterable fields | scn_contract_e03_u03_fr03_01..02 | done |
| FR-04 | CONTRACT | §EPIC-03-US-03 | application | `GetProductCustomFieldSnapshotQuery` current values for other modules | scn_contract_e03_u03_fr04_01 | done |
| FR-01 | BE | §EPIC-03-US-03 | application + infrastructure | `SearchProductsQuery` + extended `search_products` RPC + `ProductListItemMapper.customFieldValues` | scn_e03_u03_fr01_01 | done |
| FR-02 | BE | §EPIC-03-US-03 | application + infrastructure | Keyword search via searchable custom fields in `search_products` | scn_e03_u03_fr02_01 | done |
| FR-03 | BE | §EPIC-03-US-03 | application + infrastructure | `ListCustomFieldFilterOptionsQuery`, `CustomFieldFilterCriteria`, `list_custom_field_filter_options` RPC | scn_e03_u03_fr03_01..02 | done |
| FR-04 | BE | §EPIC-03-US-03 | application + infrastructure | `GetProductCustomFieldSnapshotQuery`, `ICatalogCustomFieldReadGateway`, `get_product_custom_field_snapshot` RPC | scn_e03_u03_fr04_01 | done |
| FR-01..03 | FE | §EPIC-03-US-03 | presentation | (Không có giao diện UI) | — | n/a |
| FR-02 | E2E | §EPIC-03-US-03 | erp | E2E custom fields keyword search | e2e_e03_u03_fr02_01 | done |

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
| FR-04 | CONTRACT | §EPIC-06-US-02 | application | `ProductPriceBandCardDto` override fields; manual band via §EPIC-06-US-03 | scn_contract_e06_u02_fr04_01 | done |
| FR-01 | BE | §EPIC-06-US-02 | application + infrastructure | `GetStorePriceRuleQueryHandler`, `SetStorePriceRuleCommandHandler`, `SupabaseStorePriceRuleGateway`, draft RPC | scn_e06_u02_fr01_01 | done |
| FR-02 | BE | §EPIC-06-US-02 | application + infrastructure | `SuggestProductUnitPriceQueryHandler`, `suggest_product_unit_price` RPC | scn_e06_u02_fr02_01 | done |
| FR-03 | BE | §EPIC-06-US-02 | application + infrastructure | `ApplyStorePriceRuleCommandHandler`, `apply_store_price_rule` RPC | scn_e06_u02_fr03_01 | done |
| FR-04 | BE | §EPIC-06-US-02 | application + infrastructure | PCC price band metadata projection | scn_e06_u02_fr04_01 | done |
| FR-02 | FE | §EPIC-06-US-02 | presentation | `edit_product_unit_price_band_page.dart`, `price_band_calculation_type_selector.dart` | wgt_e06_u02_fr02_01 | done |
| FR-03 | FE | §EPIC-06-US-02 | presentation | Overwrite dialog + cubit apply flow | dlg_price_band_overwrite | done |
| FR-04 | FE | §EPIC-06-US-02 | presentation | PCC price band `Giá riêng` / rule label | wgt_e01_u02_fr01_01 | done |
| FR-01 | E2E | §EPIC-06-US-02 | erp | Tenant rule settings page | — | **deferred** |
| FR-02 | E2E | §EPIC-06-US-02 | erp | Suggestion in price band editor | e2e_e06_u02_fr02_* | done |
| FR-03 | E2E | §EPIC-06-US-02 | erp | Apply rule + overwrite confirm | e2e_e06_u02_fr03_01..02 | done |
| FR-04 | E2E | §EPIC-06-US-02 | erp | PCC custom override label | e2e_e06_u02_fr04_01 | done |

---

## EPIC-06 / US-03 — Product Unit Price Band (slice #11)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §EPIC-06-US-03 | application | Price band command/query, DTOs, `FakeCatalogModule`, `IProductPriceBandGateway` | scn_contract_e06_u03_* | done |
| FR-01 | CONTRACT | §EPIC-06-US-03 | application | `SetProductUnitPriceBandCommand`, `ListProductUnitPriceBandsQuery`, per-unit rows | scn_contract_e06_u03_fr01_* | done |
| FR-02 | CONTRACT | §EPIC-06-US-03 | application | `PriceBandValidationWarningDto`, `confirmAcknowledgeWarnings` warn-only | scn_contract_e06_u03_fr02_* | done |
| FR-03 | CONTRACT | §EPIC-06-US-03 | application | `readinessSummary` on result; multi-unit partial blocker | scn_contract_e06_u03_fr03_* | done |
| FR-04 | CONTRACT | §EPIC-06-US-03 | application | Change history via BE RPC spec; read `changeHistoryPreview` | — | done (doc) |
| FR-01 | BE | §EPIC-06-US-03 | application + infrastructure | `SetProductUnitPriceBandCommandHandler`, `ListProductUnitPriceBandsQueryHandler`, `SupabaseProductPriceBandGateway`, draft RPC | scn_e06_u03_fr01_* | done |
| FR-02 | BE | §EPIC-06-US-03 | application | `PriceBandWarningCalculator` + handler warn-only gate | scn_e06_u03_fr02_* | done |
| FR-03 | BE | §EPIC-06-US-03 | application + infrastructure | `_product_operational_facts` multi-unit `has_price_band` + readiness result | scn_e06_u03_fr03_* | done |
| FR-04 | BE | §EPIC-06-US-03 | infrastructure | Change history in `set_product_unit_price_band` RPC | — | done |
| FR-01..03 | FE | §EPIC-06-US-03 | presentation | `ProductPriceBandsPage`, `EditProductUnitPriceBandPage`, `PriceBandCalculationTypeSelector`, cubits | wgt_e06_u03_fr01_01 | done |
| FR-01..03 | E2E | §EPIC-06-US-03 | erp | E2E test cho price bands `product_price_bands_e2e_test.dart` | e2e_e06_u03_fr01_01 | done |
| US-04 | CONTRACT | §EPIC-06-US-04 | application | `GetProductPriceBandSnapshotQuery`, snapshot DTOs, `FakeCatalogModule`, `IProductPriceBandGateway` | scn_contract_e06_u04_* | done |
| FR-01 | CONTRACT | §EPIC-06-US-04 | application | `listPrice` + `listPriceMissing` per product/unit | scn_contract_e06_u04_fr01_* | done |
| FR-02 | CONTRACT | §EPIC-06-US-04 | application | `floorPrice` + `floorPriceMissing` + `floorPriceHidden` | scn_contract_e06_u04_fr02_* | done |
| FR-03 | CONTRACT | §EPIC-06-US-04 | application | Consumer boundary — no promo/final price fields | — | done (doc) |
| FR-04 | CONTRACT | §EPIC-06-US-04 | application | `capturedAt` on snapshot items for Sales copy | scn_contract_e06_u04_fr04_01 | done |
| FR-01 | BE | §EPIC-06-US-04 | application + infrastructure | `GetProductPriceBandSnapshotQueryHandler`, `get_product_price_band_snapshot` RPC | scn_e06_u04_fr01_* | done |
| FR-02 | BE | §EPIC-06-US-04 | application + infrastructure | Floor mask via `manage_pricing` in RPC | scn_e06_u04_fr02_* | done |
| FR-04 | BE | §EPIC-06-US-04 | application | Handler sets `capturedAt` after gateway read | scn_e06_u04_fr04_01 | done |
| US-04 | E2E | §EPIC-06-US-04 | erp | Integration test via mediator | — | todo |

---

## EPIC-07 / US-01 — Bảo trì hồ sơ (slice #12)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-07-US-01 | application | `UpdateProductProfileCommand`, `UpdateProductImagesCommand`, `RequestProductMaintenanceImageUploadCommand`, DTOs, `FakeCatalogModule` | scn_contract_e07_u01_* | done |
| FR-01 | CONTRACT | §EPIC-07-US-01 | application | Profile edit contract + duplicate SKU + version conflict | scn_contract_e07_u01_fr01_01..05 | done |
| FR-02 | CONTRACT | §EPIC-07-US-01 | application | Image snapshot replacement + maintenance upload slot | scn_contract_e07_u01_fr02_01..04 | done |
| FR-03 | CONTRACT | §EPIC-07-US-01 | application | Duplicate barcode including inactive products; open transaction warning deferred | scn_contract_e07_u01_fr03_01 | done |
| FR-04 | CONTRACT | §EPIC-07-US-01 | application | Mutation results include refreshed `readinessSummary` | scn_contract_e07_u01_fr04_01 | done |
| FR-01..04 | BE | §EPIC-07-US-01 | application + infrastructure | `UpdateProductProfileCommandHandler`, `UpdateProductImagesCommandHandler`, `RequestProductMaintenanceImageUploadCommandHandler`, gateways, generated access metadata, draft RPC `10_catalog_product_profile_maintenance.sql` | product_profile_maintenance_handlers_test, product_rpc_mapper_test, catalog_access_metadata_registry_test | done |
| FR-01..04 | FE | §EPIC-07-US-01 | presentation | `product_profile_maintenance_page.dart`, `product_images_maintenance_page.dart` | wgt_e07_u01_fr01_01, wgt_e07_u01_fr02_01 | done |
| FR-01 | E2E | §EPIC-07-US-01 | erp | Profile edit happy path + PCC refresh | e2e_e07_u01_fr01_01 | done |
| FR-01 | E2E | §EPIC-07-US-01 | erp | Blank name client validation | e2e_e07_u01_fr01_02 | done |
| FR-01 | E2E | §EPIC-07-US-01 | erp | Duplicate SKU field error | e2e_e07_u01_fr01_03 | done |
| FR-03 | E2E | §EPIC-07-US-01 | erp | Duplicate barcode (inactive product) | e2e_e07_u01_fr03_01 | done |
| FR-02 | E2E | §EPIC-07-US-01 | erp | PCC → images gallery | e2e_e07_u01_fr02_01 | done |
| FR-02 | E2E | §EPIC-07-US-01 | erp | Remove primary → promote remaining | e2e_e07_u01_fr02_02 | done |
| FR-02 | E2E | §EPIC-07-US-01 | erp | Delete all images → `0 ảnh` on PCC | e2e_e07_u01_fr02_03 | done |
| FR-04 | E2E | §EPIC-07-US-01 | erp | Delete images → readiness missing-image blocker | e2e_e07_u01_fr04_01 | done |

---

## EPIC-07 / US-02 — Ngừng KD / KD lại (slice #13)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §EPIC-07-US-02 | application | `DeactivateProductCommand`, `ReactivateProductCommand`, `ChangeProductBusinessStatusResult`, warning DTOs, `FakeCatalogModule` | scn_contract_e07_u02_* | done |
| FR-01 | CONTRACT | §EPIC-07-US-02 | application | Deactivate active product, warning acknowledgment, permission/invalid-state guards | scn_contract_e07_u02_fr01_01..04 | done |
| FR-02 | CONTRACT | §EPIC-07-US-02 | application | Reactivate inactive product; allow incomplete readiness with blockers; block soft-deleted product | scn_contract_e07_u02_fr02_01..03 | done |
| FR-03 | CONTRACT | §EPIC-07-US-02 | application | Default search excludes inactive; explicit admin criteria can include inactive | scn_contract_e07_u02_fr03_01 | done |
| FR-04 | CONTRACT | §EPIC-07-US-02 | application | Status change result includes before/after history preview data | scn_contract_e07_u02_fr04_01 | done |
| FR-01..04 | BE | §EPIC-07-US-02 | application + infrastructure | `DeactivateProductCommandHandler`, `ReactivateProductCommandHandler`, validators, gateway/RPC, draft SQL `11_catalog_product_business_status.sql`, generated access metadata | scn_e07_u02_* | done |
| FR-01..04 | FE | §EPIC-07-US-02 | presentation | PCC status actions + confirm dialogs | wgt_e07_u02_* | done |
| FR-01..04 | E2E | §EPIC-07-US-02 | erp | ERP via `ICatalogModule` | e2e_e07_u02_* | done |

---

## EPIC-07 / US-03 — Xóa mềm / khôi phục (slice #14)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §EPIC-07-US-03 | application | `CheckProductDeletionEligibilityQuery`, `DeleteProductCommand`, `RestoreProductCommand`, `ChangeProductSoftDeleteResult`, deletion issue DTOs, `FakeCatalogModule` | scn_contract_e07_u03_* | done |
| FR-01 | CONTRACT | §EPIC-07-US-03 | application | Delete eligibility, blockers, warnings, suggested `deactivate_product` action | scn_contract_e07_u03_fr01_01..03 | done |
| FR-02 | CONTRACT | §EPIC-07-US-03 | application | Soft delete flag, version guard, search exclusion, history entry | scn_contract_e07_u03_fr02_01..03 | done |
| FR-03 | CONTRACT | §EPIC-07-US-03 | application | Restore soft-deleted product as inactive; duplicate SKU/barcode guards; refreshed readiness | scn_contract_e07_u03_fr03_01..03 | done |
| FR-04 | CONTRACT | §EPIC-07-US-03 | application | Preserved PCC operational data and change history after soft delete | scn_contract_e07_u03_fr04_01 | done |
| FR-01..04 | BE | §EPIC-07-US-03 | application + infrastructure | `CheckProductDeletionEligibilityQueryHandler`, `DeleteProductCommandHandler`, `RestoreProductCommandHandler`, validators, `IProductDeletionGateway`, `SupabaseProductDeletionGateway`, `SupabaseProductCommandGateway` delete/restore, draft SQL `12_catalog_product_soft_delete.sql`, generated access metadata | product_soft_delete_handlers_test; product_rpc_mapper_test; catalog_error_mapper_test | done |
| FR-01..04 | FE | §EPIC-07-US-03 | presentation | `ProductSoftDeleteCubit`, `ProductLifecycleActionSheet`, `ProductDeleteConfirmDialog`, `ProductRestoreConfirmDialog`, deleted filter/read-only PCC | wgt_e07_u03_delete | done |
| FR-01..04 | E2E | §EPIC-07-US-03 | erp | ERP via `ICatalogModule` + `FakeCatalogModule` scenarios | e2e_e07_u03_fr01_01..03; e2e_e07_u03_fr02_01; e2e_e07_u03_fr02_03; e2e_e07_u03_fr03_01..03; e2e_e07_u03_fr04_01 | done |

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
