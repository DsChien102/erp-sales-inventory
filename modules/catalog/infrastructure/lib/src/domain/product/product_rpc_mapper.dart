import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

abstract final class ProductRpcMapper {
  static Map<String, dynamic> createGuidedProductParams(
    CreateGuidedProductCommand command,
  ) {
    final baseUnit = command.baseUnit;
    final referenceId = ProductReferenceId.fromProductId(ProductId(command.id));
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_name': command.productName.trim(),
      'p_reference_id': referenceId.value,
      'p_trade_name': _optionalText(command.commercialName),
      'p_sku': _optionalText(command.sku),
      'p_barcode': _optionalText(command.barcode),
      'p_images': command.images.map((image) => <String, dynamic>{
        'storage_key': image.storageKey,
        'slot_id': image.slotId,
        'url': image.url,
        'is_primary': image.isPrimary,
        'sort_order': image.sortOrder,
      }).toList(growable: false),
      'p_tenant_unit_id': switch (baseUnit) {
        ExistingTenantUnit(:final unitId) => unitId,
        _ => null,
      },
      'p_new_unit_name': switch (baseUnit) {
        NewTenantUnit(:final name) => name,
        _ => null,
      },
      'p_initial_stock': command.initialStock,
      'p_base_price': command.basePrice,
      'p_list_price': command.listPrice,
      'p_floor_price': command.floorPrice,
      'p_use_store_price_rule': command.useStorePriceRule,
      'p_custom_field_values': command.customFieldValues.map((value) => <String, dynamic>{
        'field_id': value.fieldId,
        'text_value': value.textValue,
        'number_value': value.numberValue,
        'date_value': value.dateValue?.toIso8601String(),
        'boolean_value': value.booleanValue,
        'option_id': value.optionId,
      }).toList(growable: false),
      'p_idempotency_key': command.id,
    };
  }

  static CreateGuidedProductResult createGuidedProductResultFromJson(
    Map<String, dynamic> row,
  ) {
    return CreateGuidedProductResult(
      productId: row['product_id'] as String,
      readinessSummary: _readinessSummaryFromRow(row),
    );
  }

  static Map<String, dynamic> createProductParams({
    required Product product,
    required String idempotencyKey,
  }) {
    return <String, dynamic>{
      'p_tenant_id': product.tenantId.value,
      'p_name': product.name.value,
      'p_reference_id': product.referenceId.value,
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
    String currency = 'VND',
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_mode': profile.mode.name,
      'p_base_price': profile.basePrice?.amount,
      'p_currency': currency,
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

  static Map<String, dynamic> updateProductProfileParams(
    UpdateProductProfileCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_product_id': command.productId,
      'p_name': command.productName.trim(),
      'p_trade_name': _optionalText(command.commercialName),
      'p_sku': _optionalText(command.sku),
      'p_barcode': _optionalText(command.barcode),
      'p_description': _optionalText(command.description),
      'p_note': _optionalText(command.note),
      'p_expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> updateProductImagesParams(
    UpdateProductImagesCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_product_id': command.productId,
      'p_images': command.images
          .map(
            (image) => <String, dynamic>{
              'image_id': image.imageId,
              'storage_key': image.storageKey,
              'slot_id': image.slotId,
              'url': image.url,
              'is_primary': image.isPrimary,
              'sort_order': image.sortOrder,
            },
          )
          .toList(growable: false),
      'p_expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> deactivateProductParams(
    DeactivateProductCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_product_id': command.productId,
      'p_reason': _optionalText(command.reason),
      'p_expected_version': command.expectedVersion,
      'p_confirm_acknowledge_warnings': command.confirmAcknowledgeWarnings,
    };
  }

  static Map<String, dynamic> reactivateProductParams(
    ReactivateProductCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_product_id': command.productId,
      'p_reason': _optionalText(command.reason),
      'p_expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> checkProductDeletionEligibilityParams(
    CheckProductDeletionEligibilityQuery query,
  ) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_product_id': query.productId,
    };
  }

  static Map<String, dynamic> deleteProductParams(
    DeleteProductCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_product_id': command.productId,
      'p_reason': _optionalText(command.reason),
      'p_expected_version': command.expectedVersion,
      'p_confirm_acknowledge_warnings': command.confirmAcknowledgeWarnings,
    };
  }

  static Map<String, dynamic> restoreProductParams(
    RestoreProductCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_product_id': command.productId,
      'p_reason': _optionalText(command.reason),
      'p_expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> requestMaintenanceImageUploadParams(
    RequestProductMaintenanceImageUploadCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_file_name': command.fileName,
      'p_content_type': command.contentType,
      'p_byte_size': command.byteSize,
      'p_actor_id': command.actorId,
    };
  }

  static UpdateProductProfileResult updateProductProfileResultFromRow(
    Map<String, dynamic> row,
  ) {
    final productId = row['product_id'] as String;
    return UpdateProductProfileResult(
      productId: productId,
      profile: ProductProfileSummaryDto(
        productId: productId,
        name: row['name'] as String,
        tradeName: row['trade_name'] as String?,
        sku: row['sku'] as String?,
        barcode: row['barcode'] as String?,
        businessStatus: _productStatusFromRpc(
          row['business_status'] as String?,
        ),
        isSoftDeleted: row['is_soft_deleted'] as bool? ?? false,
        primaryImageUrl: row['primary_image_url'] as String?,
        images: _stringList(row['images']),
        description: row['description'] as String?,
        note: row['note'] as String?,
      ),
      readinessSummary: _readinessSummaryFromRow(row),
      version: _intValue(row['version']) ?? 1,
    );
  }

  static UpdateProductImagesResult updateProductImagesResultFromRow(
    Map<String, dynamic> row,
  ) {
    return UpdateProductImagesResult(
      productId: row['product_id'] as String,
      images: _imageDtos(row['images']),
      primaryImageUrl: row['primary_image_url'] as String?,
      readinessSummary: _readinessSummaryFromRow(row),
      version: _intValue(row['version']) ?? 1,
    );
  }

  static ChangeProductBusinessStatusResult changeProductBusinessStatusResultFromRow(
    Map<String, dynamic> row,
  ) {
    return ChangeProductBusinessStatusResult(
      productId: row['product_id'] as String,
      previousStatus: _productStatusFromRpc(row['previous_status'] as String?),
      currentStatus: _productStatusFromRpc(row['current_status'] as String?),
      readinessSummary: _readinessSummaryFromRow(row),
      version: _intValue(row['version']) ?? 1,
      reason: row['reason'] as String?,
      warnings: _warningDtos(row['warnings']),
      historyEntry: _historyEntry(row['history_entry']),
    );
  }

  static ProductDeletionEligibilityDto productDeletionEligibilityFromRow(
    Map<String, dynamic> row,
  ) {
    return ProductDeletionEligibilityDto(
      productId: row['product_id'] as String,
      canDelete: row['can_delete'] as bool? ?? false,
      issues: _deletionIssues(row['issues']),
      suggestedActionId: row['suggested_action_id'] as String?,
    );
  }

  static ChangeProductSoftDeleteResult changeProductSoftDeleteResultFromRow(
    Map<String, dynamic> row,
  ) {
    return ChangeProductSoftDeleteResult(
      productId: row['product_id'] as String,
      isSoftDeleted: row['is_soft_deleted'] as bool? ?? false,
      businessStatus: _productStatusFromRpc(row['business_status'] as String?),
      readinessSummary: _readinessSummaryFromRow(row),
      version: _intValue(row['version']) ?? 1,
      reason: row['reason'] as String?,
      issues: _deletionIssues(row['issues']),
      historyEntry: _historyEntry(row['history_entry']),
    );
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
      'p_custom_field_filters': customFieldFiltersToRpc(criteria.customFieldFilters),
      'p_sort_order': _sortOrderToRpc(criteria.sortOrder),
    };
  }

  static List<Map<String, dynamic>> customFieldFiltersToRpc(
    List<CustomFieldFilterCriteria> filters,
  ) {
    return filters
        .map((filter) {
          final json = <String, dynamic>{'field_id': filter.fieldId};
          if (filter.optionId != null) {
            json['option_id'] = filter.optionId;
          }
          if (filter.booleanValue != null) {
            json['boolean_value'] = filter.booleanValue;
          }
          return json;
        })
        .toList(growable: false);
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

  static Map<String, dynamic> deleteConversionUnitParams(
    DeleteProductConversionUnitCommand command,
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

  static String _sortOrderToRpc(ProductSortOrder sortOrder) {
    return switch (sortOrder) {
      ProductSortOrder.relevanceDesc => 'relevance_desc',
      ProductSortOrder.updatedAtDesc => 'updated_at_desc',
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

  static String? _optionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static ProductStatus _productStatusFromRpc(String? value) {
    return switch (value) {
      'inactive' => ProductStatus.inactive,
      _ => ProductStatus.active,
    };
  }

  static ReadinessSummaryDto _readinessSummaryFromRow(Map<String, dynamic> row) {
    return ReadinessSummaryDto(
      status: readinessStatusFromRpc(row['readiness_status'] as String?),
      blockers: (row['readiness_blockers'] as List<dynamic>? ?? const [])
          .map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return ReadinessBlockerDto(
              code: map['code'] as String,
              message: map['message'] as String,
              group: map['group'] as String?,
            );
          })
          .toList(growable: false),
    );
  }

  static List<String> _stringList(Object? value) {
    return (value as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);
  }

  static List<ProductImageDto> _imageDtos(Object? value) {
    return (value as List<dynamic>? ?? const [])
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProductImageDto(
            imageId: map['image_id'] as String,
            storageKey: map['storage_key'] as String,
            url: map['url'] as String?,
            isPrimary: map['is_primary'] as bool? ?? false,
            sortOrder: _intValue(map['sort_order']) ?? 0,
          );
        })
        .toList(growable: false);
  }

  static List<ProductBusinessStatusWarningDto> _warningDtos(Object? value) {
    return (value as List<dynamic>? ?? const [])
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProductBusinessStatusWarningDto(
            code: map['code'] as String,
            message: map['message'] as String,
          );
        })
        .toList(growable: false);
  }

  static List<ProductDeletionIssueDto> _deletionIssues(Object? value) {
    return (value as List<dynamic>? ?? const [])
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProductDeletionIssueDto(
            code: map['code'] as String,
            message: map['message'] as String,
            severity: _deletionIssueSeverityFromRpc(map['severity'] as String?),
          );
        })
        .toList(growable: false);
  }

  static ProductDeletionIssueSeverity _deletionIssueSeverityFromRpc(
    String? value,
  ) {
    return switch (value) {
      'blocker' => ProductDeletionIssueSeverity.blocker,
      'recommendation' => ProductDeletionIssueSeverity.recommendation,
      _ => ProductDeletionIssueSeverity.warning,
    };
  }

  static ProductChangeHistoryEntryDto? _historyEntry(Object? value) {
    if (value == null) {
      return null;
    }

    final map = Map<String, dynamic>.from(value as Map);
    return ProductChangeHistoryEntryDto(
      id: map['id'] as String,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      actorDisplayName: map['actor_display_name'] as String,
      changeType: ProductChangeHistoryAction.tryParse(
        map['change_type'] as String?,
      ),
      summary: map['summary'] as String,
      valueBefore: map['value_before'] as String?,
      valueAfter: map['value_after'] as String?,
    );
  }

  static int? _intValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value.toString());
  }
}
