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
      if (priceBand.productUnitId != null)
        'p_product_unit_id': priceBand.productUnitId,
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

  static ProductDuplicateField duplicateFieldFromRpc(String value) {
    return switch (value) {
      'sku' => ProductDuplicateField.sku,
      'barcode' => ProductDuplicateField.barcode,
      _ => throw ArgumentError('Unknown duplicate field: $value'),
    };
  }
}
