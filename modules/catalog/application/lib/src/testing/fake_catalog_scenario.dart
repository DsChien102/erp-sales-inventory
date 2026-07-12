/// Scenario ids aligned with `docs/themes/TH-02-product-pricing/harness/07-api-contracts.md`.
abstract final class FakeCatalogScenario {
  static const guidedCreateOk = 'guided_create_ok';
  static const guidedCreateDupReference = 'guided_create_dup_reference';
  static const guidedCreateExplicitReference = 'guided_create_explicit_reference';
  static const guidedCreateDupSku = 'guided_create_dup_sku';
  static const guidedCreateDupBarcode = 'guided_create_dup_barcode';
  static const guidedCreateMissingName = 'guided_create_missing_name';
  static const guidedCreateNoImages = 'guided_create_no_images';
  static const guidedCreateUploadSlotOk = 'guided_create_upload_slot_ok';
  static const guidedCreateUploadInvalidType = 'guided_create_upload_invalid_type';
  static const guidedCreatePermissionDenied = 'guided_create_permission_denied';
  static const basicStockQuantityBaseOk = 'basic_stock_quantity_base_ok';
  static const basicStockQuantityBaseSkip = 'basic_stock_quantity_base_skip';
  static const manualBasePriceOk = 'manual_base_price_ok';
  static const priceBandFromStoreRule = 'price_band_from_store_rule';

  static const readinessManyBlockers = 'readiness_many_blockers';
  static const readinessReadyToSell = 'readiness_ready_to_sell';
  static const readinessAdvancedStockPending = 'readiness_advanced_stock_pending';
  static const readinessCostingBasePricePending = 'readiness_costing_base_price_pending';
  static const readinessMissingCustomFields = 'readiness_missing_custom_fields';
  static const readinessNoPricePermission = 'readiness_no_price_permission';
  static const readinessRefreshAfterUnit = 'readiness_refresh_after_unit';
  static const readinessPermissionDenied = 'readiness_permission_denied';

  static const searchEmpty = 'search_empty';
  static const searchWithReadiness = 'search_with_readiness';
  static const searchRelevanceSort = 'search_relevance_sort';
  static const searchUnaccentVietnamese = 'search_unaccent_vietnamese';
  static const barcodeExactMatch = 'barcode_exact_match';
  static const barcodeNotFound = 'barcode_not_found';

  static const pccIncomplete = 'pcc_incomplete';
  static const pccReadyToSell = 'pcc_ready_to_sell';
  static const pccInactive = 'pcc_inactive';
  static const pccCustomFieldCards = 'pcc_custom_field_cards';
  static const pccProfileMaintenanceImages = 'pcc_profile_maintenance_images';

  static const listTenantUnits = 'list_tenant_units';
  static const setBaseUnitExisting = 'set_base_unit_existing';
  static const setBaseUnitCreateNew = 'set_base_unit_create_new';
  static const setBaseUnitDuplicate = 'set_base_unit_duplicate';
  static const setBaseUnitInactiveUnit = 'set_base_unit_inactive_unit';
  static const unitDependenciesLocked = 'unit_dependencies_locked';

  static const scnContractE05U01Fr01_01 = 'scn_contract_e05_u01_fr01_01';
  static const scnContractE05U01Fr02_01 = 'scn_contract_e05_u01_fr02_01';
  static const scnContractE05U01Fr03_01 = 'scn_contract_e05_u01_fr03_01';
  static const scnContractE05U02Fr01_01 = 'scn_contract_e05_u02_fr01_01';
  static const scnContractE05U02Fr01_02 = 'scn_contract_e05_u02_fr01_02';
  static const scnContractE05U02Fr02_01 = 'scn_contract_e05_u02_fr02_01';
  static const scnContractE05U02Fr02_02 = 'scn_contract_e05_u02_fr02_02';
  static const scnContractE05U02Fr02_03 = 'scn_contract_e05_u02_fr02_03';
  static const scnContractE05U02Fr03_01 = 'scn_contract_e05_u02_fr03_01';
  static const scnContractE05U02Fr04_01 = 'scn_contract_e05_u02_fr04_01';

  static const scnContractE06U01Fr01_01 = 'scn_contract_e06_u01_fr01_01';
  static const scnContractE06U01Fr01_02 = 'scn_contract_e06_u01_fr01_02';
  static const scnContractE06U01Fr01_03 = 'scn_contract_e06_u01_fr01_03';
  static const scnContractE06U01Fr02_01 = 'scn_contract_e06_u01_fr02_01';
  static const scnContractE06U01Fr02_02 = 'scn_contract_e06_u01_fr02_02';
  static const scnContractE06U01Fr02_03 = 'scn_contract_e06_u01_fr02_03';
  static const scnContractE06U01Fr04_01 = 'scn_contract_e06_u01_fr04_01';

  static const scnContractE06U02Fr01_01 = 'scn_contract_e06_u02_fr01_01';
  static const scnContractE06U02Fr01_02 = 'scn_contract_e06_u02_fr01_02';
  static const scnContractE06U02Fr01_03 = 'scn_contract_e06_u02_fr01_03';
  static const scnContractE06U02Fr01_04 = 'scn_contract_e06_u02_fr01_04';
  static const scnContractE06U02Fr02_01 = 'scn_contract_e06_u02_fr02_01';
  static const scnContractE06U02Fr02_02 = 'scn_contract_e06_u02_fr02_02';
  static const scnContractE06U02Fr02_03 = 'scn_contract_e06_u02_fr02_03';
  static const scnContractE06U02Fr03_01 = 'scn_contract_e06_u02_fr03_01';
  static const scnContractE06U02Fr03_02 = 'scn_contract_e06_u02_fr03_02';
  static const scnContractE06U02Fr03_03 = 'scn_contract_e06_u02_fr03_03';
  static const scnContractE06U02Fr04_01 = 'scn_contract_e06_u02_fr04_01';

  static const scnContractE06U03Fr01_01 = 'scn_contract_e06_u03_fr01_01';
  static const scnContractE06U03Fr01_02 = 'scn_contract_e06_u03_fr01_02';
  static const scnContractE06U03Fr01_03 = 'scn_contract_e06_u03_fr01_03';
  static const scnContractE06U03Fr01_04 = 'scn_contract_e06_u03_fr01_04';
  static const scnContractE06U03Fr02_01 = 'scn_contract_e06_u03_fr02_01';
  static const scnContractE06U03Fr02_02 = 'scn_contract_e06_u03_fr02_02';
  static const scnContractE06U03Fr02_03 = 'scn_contract_e06_u03_fr02_03';
  static const scnContractE06U03Fr03_01 = 'scn_contract_e06_u03_fr03_01';
  static const scnContractE06U03Fr03_02 = 'scn_contract_e06_u03_fr03_02';

  static const scnContractE06U04Fr01_01 = 'scn_contract_e06_u04_fr01_01';
  static const scnContractE06U04Fr01_02 = 'scn_contract_e06_u04_fr01_02';
  static const scnContractE06U04Fr01_03 = 'scn_contract_e06_u04_fr01_03';
  static const scnContractE06U04Fr02_01 = 'scn_contract_e06_u04_fr02_01';
  static const scnContractE06U04Fr02_03 = 'scn_contract_e06_u04_fr02_03';
  static const scnContractE06U04Fr04_01 = 'scn_contract_e06_u04_fr04_01';
  static const scnContractE06U04PermissionDenied = 'scn_contract_e06_u04_permission_denied';
  static const scnContractE06U04Validation = 'scn_contract_e06_u04_validation';

  static const scnContractE07U01Fr01_01 = 'scn_contract_e07_u01_fr01_01';
  static const scnContractE07U01Fr01_02 = 'scn_contract_e07_u01_fr01_02';
  static const scnContractE07U01Fr01_03 = 'scn_contract_e07_u01_fr01_03';
  static const scnContractE07U01Fr01_04 = 'scn_contract_e07_u01_fr01_04';
  static const scnContractE07U01Fr01_05 = 'scn_contract_e07_u01_fr01_05';
  static const scnContractE07U01Fr02_01 = 'scn_contract_e07_u01_fr02_01';
  static const scnContractE07U01Fr02_02 = 'scn_contract_e07_u01_fr02_02';
  static const scnContractE07U01Fr02_03 = 'scn_contract_e07_u01_fr02_03';
  static const scnContractE07U01Fr02_04 = 'scn_contract_e07_u01_fr02_04';
  static const scnContractE07U01Fr03_01 = 'scn_contract_e07_u01_fr03_01';
  static const scnContractE07U01Fr04_01 = 'scn_contract_e07_u01_fr04_01';
  static const scnContractE07U02Fr01_01 = 'scn_contract_e07_u02_fr01_01';
  static const scnContractE07U02Fr01_02 = 'scn_contract_e07_u02_fr01_02';
  static const scnContractE07U02Fr01_03 = 'scn_contract_e07_u02_fr01_03';
  static const scnContractE07U02Fr01_04 = 'scn_contract_e07_u02_fr01_04';
  static const scnContractE07U02Fr02_01 = 'scn_contract_e07_u02_fr02_01';
  static const scnContractE07U02Fr02_02 = 'scn_contract_e07_u02_fr02_02';
  static const scnContractE07U02Fr02_03 = 'scn_contract_e07_u02_fr02_03';
  static const scnContractE07U02Fr03_01 = 'scn_contract_e07_u02_fr03_01';
  static const scnContractE07U02Fr04_01 = 'scn_contract_e07_u02_fr04_01';
  static const scnContractE07U03Fr01_01 = 'scn_contract_e07_u03_fr01_01';
  static const scnContractE07U03Fr01_02 = 'scn_contract_e07_u03_fr01_02';
  static const scnContractE07U03Fr01_03 = 'scn_contract_e07_u03_fr01_03';
  static const scnContractE07U03Fr02_01 = 'scn_contract_e07_u03_fr02_01';
  static const scnContractE07U03Fr02_02 = 'scn_contract_e07_u03_fr02_02';
  static const scnContractE07U03Fr02_03 = 'scn_contract_e07_u03_fr02_03';
  static const scnContractE07U03Fr03_01 = 'scn_contract_e07_u03_fr03_01';
  static const scnContractE07U03Fr03_02 = 'scn_contract_e07_u03_fr03_02';
  static const scnContractE07U03Fr03_03 = 'scn_contract_e07_u03_fr03_03';
  static const scnContractE07U03Fr04_01 = 'scn_contract_e07_u03_fr04_01';

  static const scnContractE07U04Fr02_01 = 'scn_contract_e07_u04_fr02_01';
  static const scnContractE07U04Fr02_02 = 'scn_contract_e07_u04_fr02_02';
  static const scnContractE07U04Fr02_03 = 'scn_contract_e07_u04_fr02_03';
  static const scnContractE07U04Fr03_01 = 'scn_contract_e07_u04_fr03_01';
  static const scnContractE07U04Fr03_02 = 'scn_contract_e07_u04_fr03_02';
  static const scnContractE07U04PermissionDenied = 'scn_contract_e07_u04_permission_denied';
  static const scnContractE07U04Validation = 'scn_contract_e07_u04_validation';

  static const cfTemplateSeedOk = 'cf_template_seed_ok';
  static const cfTemplateReinitNoOverwrite = 'cf_template_reinit_no_overwrite';
  static const cfGroupUpsertOk = 'cf_group_upsert_ok';
  static const cfGroupDuplicateName = 'cf_group_duplicate_name';
  static const cfGroupDeactivateOk = 'cf_group_deactivate_ok';
  static const cfReorderGroupsOk = 'cf_reorder_groups_ok';
  static const cfFieldUpsertText = 'cf_field_upsert_text';
  static const cfFieldSingleSelectNoOptions = 'cf_field_single_select_no_options';
  static const cfFieldRequiredOn = 'cf_field_required_on';
  static const cfReorderFieldsOk = 'cf_reorder_fields_ok';
  static const cfPermissionDenied = 'cf_permission_denied';

  static const scnContractE03U02Fr01_01 = 'scn_contract_e03_u02_fr01_01';
  static const scnContractE03U02Fr02_01 = 'scn_contract_e03_u02_fr02_01';
  static const scnContractE03U02Fr02_02 = 'scn_contract_e03_u02_fr02_02';
  static const scnContractE03U02Fr03_01 = 'scn_contract_e03_u02_fr03_01';
  static const scnContractE03U02Fr03_02 = 'scn_contract_e03_u02_fr03_02';
  static const scnContractE03U02Fr04_01 = 'scn_contract_e03_u02_fr04_01';

  static const e2eCfValuesOk = 'e2e_cf_values_ok';
  static const e2eCfValuesSaveOk = 'e2e_cf_values_save_ok';
  static const e2eCfValuesRequired = 'e2e_cf_values_required';
  static const customFieldSearchDisplay = 'custom_field_search_display';
  static const customFieldSearchable = 'custom_field_searchable';
  static const customFieldFilterable = 'custom_field_filterable';
  static const customFieldFilterInactive = 'custom_field_filter_inactive';
  static const customFieldSnapshot = 'custom_field_snapshot';
  static const customFieldSearchPermissionDenied = 'custom_field_search_permission_denied';
}
