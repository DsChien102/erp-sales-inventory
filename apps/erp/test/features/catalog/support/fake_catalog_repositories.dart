import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'fake_catalog_backend.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

final _unusedRpc = SupabaseRpc(_UnusedClient());

class FakeProductRepository extends ProductRepository {
  FakeProductRepository({
    required this.backend,
    Future<String> Function()? tenantId,
    Future<String> Function()? actorId,
    bool Function(String permissionCode)? hasPermission,
    Future<String> Function(String storageKey)? signUploadUrl,
  }) : super(
          rpc: _unusedRpc,
          tenantId: tenantId ?? (() async => 'tenant-1'),
          actorId: actorId ?? (() async => 'user-1'),
          hasPermission: hasPermission ?? ((_) => true),
          signUploadUrl: signUploadUrl ?? ((key) async => 'https://fake-upload/$key'),
        );

  final FakeCatalogBackend backend;
  final List<String> calls = <String>[];

  @override
  Future<ProductSearchResultDto> search({
    ProductSearchCriteria? criteria,
    int limit = 50,
    int offset = 0,
  }) {
    calls.add('search');
    return backend.handleSearch(
      criteria: criteria,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    int maxOptionsPerField = 50,
  }) {
    calls.add('listCustomFieldFilterOptions');
    return backend.handleListCustomFieldFilterOptions(
      maxOptionsPerField: maxOptionsPerField,
    );
  }

  @override
  Future<List<ProductDuplicateMatchDto>> checkDuplicateCodes({
    String? sku,
    String? barcode,
    String? excludeProductId,
  }) {
    calls.add('checkDuplicateCodes');
    return backend.handleCheckDuplicateCodes(
      sku: sku,
      barcode: barcode,
      excludeProductId: excludeProductId,
    );
  }

  @override
  Future<CreateGuidedProductResult> createGuided(CreateGuidedProductInput input) {
    calls.add('createGuided');
    return backend.handleCreateGuided(input);
  }

  @override
  Future<ProductImageUploadSlotDto> requestImageUpload({
    required String fileName,
    required String contentType,
    required int byteSize,
  }) {
    calls.add('requestImageUpload');
    return backend.handleRequestImageUpload(
      fileName: fileName,
      contentType: contentType,
      byteSize: byteSize,
    );
  }

  @override
  Future<ProductImageUploadSlotDto> requestMaintenanceImageUpload({
    required String productId,
    required String fileName,
    required String contentType,
    required int byteSize,
  }) {
    calls.add('requestMaintenanceImageUpload');
    return backend.handleRequestMaintenanceImageUpload(
      productId: productId,
      fileName: fileName,
      contentType: contentType,
      byteSize: byteSize,
    );
  }

  @override
  Future<ProductControlCenterDto> getControlCenter(String productId) {
    calls.add('getControlCenter');
    return backend.handleGetControlCenter(productId);
  }

  @override
  Future<ProductReadinessViewDto> getReadiness(String productId) {
    calls.add('getReadiness');
    return backend.handleGetReadiness(productId);
  }

  @override
  Future<void> updateProfile({
    required String productId,
    int? expectedVersion,
    required String productName,
    String? commercialName,
    String? sku,
    String? barcode,
    String? description,
    String? note,
    ProductTrackingMode? trackingMode,
    bool? expiryRequired,
  }) {
    calls.add('updateProfile');
    return backend.handleUpdateProfile(
      productId: productId,
      expectedVersion: expectedVersion,
      productName: productName,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
      trackingMode: trackingMode,
      expiryRequired: expiryRequired,
    );
  }

  @override
  Future<void> updateImages({
    required String productId,
    int? expectedVersion,
    required List<ProductImageMutationInput> images,
  }) {
    calls.add('updateImages');
    return backend.handleUpdateImages(
      productId: productId,
      expectedVersion: expectedVersion,
      images: images,
    );
  }

  @override
  Future<void> deactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) {
    calls.add('deactivate');
    return backend.handleDeactivate(
      productId: productId,
      expectedVersion: expectedVersion,
      reason: reason,
      confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
    );
  }

  @override
  Future<void> reactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) {
    calls.add('reactivate');
    return backend.handleReactivate(
      productId: productId,
      expectedVersion: expectedVersion,
      reason: reason,
    );
  }

  @override
  Future<ProductDeletionEligibilityDto> checkDeletionEligibility(String productId) {
    calls.add('checkDeletionEligibility');
    return backend.handleCheckDeletionEligibility(productId);
  }

  @override
  Future<void> delete({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) {
    calls.add('delete');
    return backend.handleDelete(
      productId: productId,
      expectedVersion: expectedVersion,
      reason: reason,
      confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
    );
  }

  @override
  Future<void> restore({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) {
    calls.add('restore');
    return backend.handleRestore(
      productId: productId,
      expectedVersion: expectedVersion,
      reason: reason,
    );
  }

  @override
  Future<ProductChangeHistoryResultDto> getChangeHistory({
    required String productId,
    int limit = 50,
    int offset = 0,
    List<String>? changeCategories,
  }) {
    calls.add('getChangeHistory');
    return backend.handleGetChangeHistory(
      productId: productId,
      limit: limit,
      offset: offset,
      changeCategories: changeCategories,
    );
  }

  @override
  Future<List<SellableProductDto>> searchSellable({
    required String storeId,
    String? keyword,
    int limit = 50,
    int offset = 0,
  }) {
    calls.add('searchSellable');
    return backend.handleSearchSellable(
      storeId: storeId,
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<SellableProductDto>> resolveSellableBarcode({
    required String storeId,
    required String barcode,
  }) {
    calls.add('resolveSellableBarcode');
    return backend.handleResolveSellableBarcode(
      storeId: storeId,
      barcode: barcode,
    );
  }

  @override
  Future<List<SellableProductUnitDto>> listSellableUnits({
    required String storeId,
    required String productId,
  }) {
    calls.add('listSellableUnits');
    return backend.handleListSellableUnits(
      storeId: storeId,
      productId: productId,
    );
  }

  @override
  Future<List<SellableProductResolutionDto>> resolveSellable({
    required String storeId,
    required List<String> productIds,
  }) {
    calls.add('resolveSellable');
    return backend.handleResolveSellable(
      storeId: storeId,
      productIds: productIds,
    );
  }

  @override
  Future<void> setBasicStock({
    required String productId,
    required int quantity,
  }) {
    calls.add('setBasicStock');
    return backend.handleSetBasicStock(
      productId: productId,
      quantity: quantity,
    );
  }

  @override
  Future<void> adjustBasicStock({
    required String productId,
    required int newQuantity,
    String? reason,
    int? expectedQuantity,
  }) {
    calls.add('adjustBasicStock');
    return backend.handleAdjustBasicStock(
      productId: productId,
      newQuantity: newQuantity,
      reason: reason,
      expectedQuantity: expectedQuantity,
    );
  }
}

class FakeMeasurementUnitRepository extends MeasurementUnitRepository {
  FakeMeasurementUnitRepository({
    required this.backend,
    Future<String> Function()? tenantId,
  }) : super(
          rpc: _unusedRpc,
          tenantId: tenantId ?? (() async => 'tenant-1'),
        );

  final FakeCatalogBackend backend;
  final List<String> calls = <String>[];

  @override
  Future<List<TenantMeasurementUnitDto>> listTenantUnits({
    String? keyword,
    int limit = 50,
  }) {
    calls.add('listTenantUnits');
    return backend.handleListTenantUnits(
      keyword: keyword,
      limit: limit,
    );
  }

  @override
  Future<ProductUnitsDto> listProductUnits(
    String productId, {
    bool includeInactive = false,
  }) {
    calls.add('listProductUnits');
    return backend.handleListProductUnits(
      productId,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<void> setBaseUnit(
    String productId,
    BaseUnitSelection selection,
  ) {
    calls.add('setBaseUnit');
    return backend.handleSetBaseUnit(productId, selection);
  }

  @override
  Future<void> addConversionUnit({
    required String productId,
    required String unitName,
    required double conversionRateToBase,
  }) {
    calls.add('addConversionUnit');
    return backend.handleAddConversionUnit(
      productId: productId,
      unitName: unitName,
      conversionRateToBase: conversionRateToBase,
    );
  }

  @override
  Future<void> deactivateConversionUnit({
    required String productId,
    required String productUnitId,
  }) {
    calls.add('deactivateConversionUnit');
    return backend.handleDeactivateConversionUnit(
      productId: productId,
      productUnitId: productUnitId,
    );
  }

  @override
  Future<void> reactivateConversionUnit({
    required String productId,
    required String productUnitId,
  }) {
    calls.add('reactivateConversionUnit');
    return backend.handleReactivateConversionUnit(
      productId: productId,
      productUnitId: productUnitId,
    );
  }

  @override
  Future<void> deleteConversionUnit({
    required String productId,
    required String productUnitId,
  }) {
    calls.add('deleteConversionUnit');
    return backend.handleDeleteConversionUnit(
      productId: productId,
      productUnitId: productUnitId,
    );
  }
}

class FakeCustomFieldRepository extends CustomFieldRepository {
  FakeCustomFieldRepository({
    required this.backend,
    Future<String> Function()? tenantId,
  }) : super(
          rpc: _unusedRpc,
          tenantId: tenantId ?? (() async => 'tenant-1'),
        );

  final FakeCatalogBackend backend;
  final List<String> calls = <String>[];

  @override
  Future<CustomFieldConfigViewDto> listConfig() {
    calls.add('listConfig');
    return backend.handleListConfig();
  }

  @override
  Future<void> initializeTemplate({String? templateId}) {
    calls.add('initializeTemplate');
    return backend.handleInitializeTemplate(templateId: templateId);
  }

  @override
  Future<void> upsertGroup({
    String? groupId,
    required String name,
    String? iconKey,
    bool isActive = true,
  }) {
    calls.add('upsertGroup');
    return backend.handleUpsertGroup(
      groupId: groupId,
      name: name,
      iconKey: iconKey,
      isActive: isActive,
    );
  }

  @override
  Future<void> reorderGroups(List<String> orderedGroupIds) {
    calls.add('reorderGroups');
    return backend.handleReorderGroups(orderedGroupIds);
  }

  @override
  Future<CustomFieldDefinitionDto> upsertField({
    required String groupId,
    String? fieldId,
    required String name,
    required CustomFieldType fieldType,
    List<CustomFieldSelectOptionDto> options = const [],
    bool isActive = true,
  }) {
    calls.add('upsertField');
    return backend.handleUpsertField(
      groupId: groupId,
      fieldId: fieldId,
      name: name,
      fieldType: fieldType,
      options: options,
      isActive: isActive,
    );
  }

  @override
  Future<void> configureAttributes({
    required String fieldId,
    required bool isRequired,
    required bool isSearchable,
    required bool isFilterable,
    required bool displayOnList,
  }) {
    calls.add('configureAttributes');
    return backend.handleConfigureAttributes(
      fieldId: fieldId,
      isRequired: isRequired,
      isSearchable: isSearchable,
      isFilterable: isFilterable,
      displayOnList: displayOnList,
    );
  }

  @override
  Future<void> reorderFields({
    required String groupId,
    required List<String> orderedFieldIds,
  }) {
    calls.add('reorderFields');
    return backend.handleReorderFields(
      groupId: groupId,
      orderedFieldIds: orderedFieldIds,
    );
  }

  @override
  Future<ProductCustomFieldValuesDto> getProductValues(
    String productId, {
    bool includeInactiveValues = false,
  }) {
    calls.add('getProductValues');
    return backend.handleGetProductValues(
      productId,
      includeInactiveValues: includeInactiveValues,
    );
  }

  @override
  Future<void> upsertProductValues({
    required String productId,
    required List<ProductCustomFieldValueInput> values,
  }) {
    calls.add('upsertProductValues');
    return backend.handleUpsertProductValues(
      productId: productId,
      values: values,
    );
  }
}

class FakeProductPriceRepository extends ProductPriceRepository {
  FakeProductPriceRepository({
    required this.backend,
    Future<String> Function()? tenantId,
  }) : super(
          rpc: _unusedRpc,
          tenantId: tenantId ?? (() async => 'tenant-1'),
        );

  final FakeCatalogBackend backend;
  final List<String> calls = <String>[];

  @override
  Future<void> setManualBasePrice({
    required String productId,
    required double basePrice,
    String currency = 'VND',
  }) {
    calls.add('setManualBasePrice');
    return backend.handleSetManualBasePrice(
      productId: productId,
      basePrice: basePrice,
      currency: currency,
    );
  }

  @override
  Future<ProductUnitPriceBandsDto> listUnitPriceBands(String productId) {
    calls.add('listUnitPriceBands');
    return backend.handleListUnitPriceBands(productId);
  }

  @override
  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot(
    List<ProductPriceBandSnapshotRequest> items,
  ) {
    calls.add('getPriceBandSnapshot');
    return backend.handleGetPriceBandSnapshot(items);
  }

  @override
  Future<void> setUnitPriceBand({
    required String productId,
    String? productUnitId,
    PriceBandSourceType sourceType = PriceBandSourceType.manual,
    int? listBeforeVat,
    int? listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    double? listMarkupRatio,
    double? floorMarkupRatio,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
  }) {
    calls.add('setUnitPriceBand');
    return backend.handleSetUnitPriceBand(
      productId: productId,
      productUnitId: productUnitId,
      sourceType: sourceType,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      floorBeforeVat: floorBeforeVat,
      floorAfterVat: floorAfterVat,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      status: status,
    );
  }

  @override
  Future<ProductUnitPriceSuggestionDto> suggestUnitPrice({
    required String productId,
    String? productUnitId,
  }) {
    calls.add('suggestUnitPrice');
    return backend.handleSuggestUnitPrice(
      productId: productId,
      productUnitId: productUnitId,
    );
  }

  @override
  Future<void> applyStorePriceRule({
    required String productId,
    String? productUnitId,
    String? storePriceRuleId,
    int? basePriceVersion,
    bool confirmOverwrite = false,
  }) {
    calls.add('applyStorePriceRule');
    return backend.handleApplyStorePriceRule(
      productId: productId,
      productUnitId: productUnitId,
      storePriceRuleId: storePriceRuleId,
      basePriceVersion: basePriceVersion,
      confirmOverwrite: confirmOverwrite,
    );
  }

  @override
  Future<StorePriceRuleDto?> getStorePriceRule() {
    calls.add('getStorePriceRule');
    return backend.handleGetStorePriceRule();
  }

  @override
  Future<StorePriceRuleDto> setStorePriceRule({
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) {
    calls.add('setStorePriceRule');
    return backend.handleSetStorePriceRule(
      name: name,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      status: status,
    );
  }

  @override
  Future<StorePriceRuleChangeHistoryResultDto> getStorePriceRuleHistory({
    int limit = 50,
    int offset = 0,
  }) {
    calls.add('getStorePriceRuleHistory');
    return backend.handleGetStorePriceRuleHistory(
      limit: limit,
      offset: offset,
    );
  }
}
