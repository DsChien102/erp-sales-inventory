import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

abstract final class ProductRpcMapper {
  static Map<String, dynamic> createProductParams({
    required Product product,
    required String idempotencyKey,
  }) {
    return <String, dynamic>{
      'p_tenant_id': product.tenantId.value,
      'p_name': product.name.value,
      'p_actor_id': product.createdBy,
      'p_trade_name': product.commercialName?.value,
      'p_sku': product.sku?.value,
      'p_barcode': product.barcode?.value,
      'p_description': product.description,
      'p_note': product.note,
      'p_images': product.images
          .map(
            (image) => <String, dynamic>{
              'storage_key': image.storageKey,
              'slot_id': image.slotId,
              'url': image.url,
              'is_primary': image.isPrimary,
              'sort_order': image.sortOrder,
            },
          )
          .toList(growable: false),
      'p_base_unit_name': product.baseUnit?.name,
      'p_readiness_status': readinessStatusToRpc(product.readiness.status),
      'p_readiness_blockers': product.readiness.blockers
          .map(
            (blocker) => <String, dynamic>{
              'code': blocker.code,
              'message': blocker.message,
              'group': blocker.group,
            },
          )
          .toList(growable: false),
      'p_idempotency_key': idempotencyKey,
    };
  }

  static Map<String, dynamic> checkDuplicateParams({
    required String tenantId,
    String? sku,
    String? barcode,
    String? excludeProductId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_sku': sku,
      'p_barcode': barcode,
      'p_exclude_product_id': excludeProductId,
    };
  }

  static Map<String, dynamic> setInitialStockParams({
    required String productId,
    required String tenantId,
    required ProductStockProfile profile,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_mode': profile.mode.name,
      'p_initial_stock': profile.initialStock,
    };
  }

  static Map<String, dynamic> setManualBasePriceParams({
    required String productId,
    required String tenantId,
    required ProductBasePriceProfile profile,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_mode': profile.mode.name,
      'p_base_price': profile.basePrice?.amount,
      'p_currency': 'VND',
    };
  }

  static Map<String, dynamic> setInitialPriceBandParams({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      if (priceBand.productUnitId != null) 'p_product_unit_id': priceBand.productUnitId,
      'p_list_price': priceBand.listPrice?.amount,
      'p_floor_price': priceBand.floorPrice?.amount,
    };
  }

  static Map<String, dynamic> getProductReadinessParams({
    required String tenantId,
    required String productId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
    };
  }

  static Map<String, dynamic> searchProductsParams({
    required String tenantId,
    required ProductSearchCriteria criteria,
    required int limit,
    required int offset,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_keyword': criteria.keyword,
      'p_business_statuses': criteria.businessStatuses
          .map((status) => status.name)
          .toList(growable: false),
      'p_readiness_filter': _readinessFilterToRpc(criteria.readinessFilter),
      'p_include_soft_deleted': criteria.includeSoftDeleted,
      'p_limit': limit,
      'p_offset': offset,
    };
  }

  static Map<String, dynamic> findByBarcodeParams({
    required String tenantId,
    required String barcode,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_barcode': barcode,
    };
  }

  static Map<String, dynamic> getProductControlCenterParams({
    required String tenantId,
    required String productId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
    };
  }

  static Map<String, dynamic> listTenantUnitsParams({
    required String tenantId,
    String? keyword,
    required int limit,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_keyword': keyword,
      'p_limit': limit,
    };
  }

  static Map<String, dynamic> checkDuplicateUnitNameParams({
    required String tenantId,
    required String name,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_name': name,
    };
  }

  static Map<String, dynamic> setProductBaseUnitParams(
    SetProductBaseUnitCommand command,
  ) {
    final selection = command.selection;
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_tenant_unit_id': switch (selection) {
        ExistingTenantUnit(:final unitId) => unitId,
        NewTenantUnit() => null,
      },
      'p_new_unit_name': switch (selection) {
        ExistingTenantUnit() => null,
        NewTenantUnit(:final name) => name,
      },
    };
  }

  static Map<String, dynamic> listProductUnitsParams(
    ListProductUnitsQuery query,
  ) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_product_id': query.productId,
      'p_include_inactive': query.includeInactive,
    };
  }

  static Map<String, dynamic> addConversionUnitParams(
    AddProductConversionUnitCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_unit_name': command.unitName,
      'p_conversion_rate_to_base': command.conversionRateToBase,
    };
  }

  static Map<String, dynamic> deactivateConversionUnitParams(
    DeactivateProductConversionUnitCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_product_unit_id': command.productUnitId,
    };
  }

  static Map<String, dynamic> reactivateConversionUnitParams(
    ReactivateProductConversionUnitCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_product_unit_id': command.productUnitId,
    };
  }

  static Map<String, dynamic> adjustBasicStockParams(
    AdjustBasicStockCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_new_quantity': command.newQuantity,
      'p_reason': command.reason,
      'p_expected_quantity': command.expectedQuantity,
    };
  }

  static Map<String, dynamic> getProductStockHistoryParams({
    required String tenantId,
    required String productId,
    required int limit,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_limit': limit,
    };
  }

  static ProductUnitDto productUnitDtoFromRow(Map<String, dynamic> row) {
    return ProductUnitDto(
      id: row['id'] as String,
      name: row['name'] as String,
      conversionRateToBase: (row['conversion_rate_to_base'] as num).toDouble(),
      isBaseUnit: row['is_base_unit'] as bool,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static ProductUnitsDto productUnitsDtoFromRows({
    required String productId,
    required String baseUnitName,
    required List<Map<String, dynamic>> rows,
  }) {
    return ProductUnitsDto(
      productId: productId,
      baseUnitName: baseUnitName,
      units: rows.map(productUnitDtoFromRow).toList(growable: false),
    );
  }

  static ProductUnitMutationResult productUnitMutationResultFromRow(
    Map<String, dynamic> row,
  ) {
    final unitValue = row['unit'];
    return ProductUnitMutationResult(
      productId: row['product_id'] as String,
      unit: productUnitDtoFromRow(Map<String, dynamic>.from(unitValue as Map)),
    );
  }

  static String? _readinessFilterToRpc(ProductReadinessFilter? filter) {
    return switch (filter) {
      ProductReadinessFilter.readyToSell => 'ready_to_sell',
      ProductReadinessFilter.incomplete => 'incomplete',
      null => null,
    };
  }

  static String readinessStatusToRpc(ReadinessStatus status) {
    return switch (status) {
      ReadinessStatus.incomplete => 'incomplete',
      ReadinessStatus.readyToSell => 'ready_to_sell',
      ReadinessStatus.readyToReceive => 'ready_to_receive',
    };
  }

  static ReadinessStatus readinessStatusFromRpc(String? value) {
    return switch (value) {
      'ready_to_sell' => ReadinessStatus.readyToSell,
      'ready_to_receive' => ReadinessStatus.readyToReceive,
      _ => ReadinessStatus.incomplete,
    };
  }

  static ProductDuplicateField duplicateFieldFromRpc(String value) {
    return switch (value) {
      'sku' => ProductDuplicateField.sku,
      'barcode' => ProductDuplicateField.barcode,
      _ => throw ArgumentError('Unknown duplicate field: $value'),
    };
  }
}
