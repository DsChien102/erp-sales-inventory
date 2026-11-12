/// Catalog product repository implementation (TH-02).
library;

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../logic/catalog_permissions.dart';
import '../logic/catalog_rules.dart';
import '../logic/product_readiness.dart';
import '../logic/product_reference_id.dart';
import 'catalog_errors.dart';
import 'models/catalog_enums.dart';
import 'models/custom_field_filter_option.dart';
import 'models/product_change_history.dart';
import 'models/product_control_center.dart';
import 'models/product_inputs.dart';
import 'models/product_readiness.dart';
import 'models/product_results.dart';
import 'models/product_search.dart';
import 'models/sellable_product.dart';

class ProductRepository {
  ProductRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
    required bool Function(String permissionCode) hasPermission,
    required Future<String> Function(String storageKey) signUploadUrl,
  })  : _rpc = rpc,
        _tenantId = tenantId,
        _actorId = actorId,
        _hasPermission = hasPermission,
        _signUploadUrl = signUploadUrl;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;
  final bool Function(String permissionCode) _hasPermission;
  final Future<String> Function(String storageKey) _signUploadUrl;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AppException catch (e) {
      throw catalogException(e);
    }
  }

  /// 1. Search products by criteria (TH-02 3.1).
  Future<ProductSearchResultDto> search({
    ProductSearchCriteria? criteria,
    int limit = 50,
    int offset = 0,
  }) async {
    final currentCriteria = criteria ?? ProductSearchCriteria();
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'search_products',
        params: {
          'p_tenant_id': tid,
          'p_keyword': currentCriteria.keyword,
          'p_business_statuses': currentCriteria.businessStatuses
              .map((status) => status.toWire())
              .toList(growable: false),
          'p_readiness_filter': switch (currentCriteria.readinessFilter) {
            ProductReadinessFilter.readyToSell => 'ready_to_sell',
            ProductReadinessFilter.incomplete => 'incomplete',
            null => null,
          },
          'p_include_soft_deleted': currentCriteria.includeSoftDeleted,
          'p_limit': limit,
          'p_offset': offset,
          'p_custom_field_filters': currentCriteria.customFieldFilters
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
              .toList(growable: false),
          'p_sort_order': switch (currentCriteria.sortOrder) {
            ProductSortOrder.relevanceDesc => 'relevance_desc',
            ProductSortOrder.updatedAtDesc => 'updated_at_desc',
          },
        },
      );

      if (rows.isEmpty) {
        return const ProductSearchResultDto(items: [], totalCount: 0);
      }

      final totalCount = (rows.first['total_count'] as num?)?.toInt() ?? rows.length;
      final readyToSellCount = (rows.first['ready_to_sell_count'] as num?)?.toInt();
      final incompleteCount = (rows.first['incomplete_count'] as num?)?.toInt();
      final inactiveCount = (rows.first['inactive_count'] as num?)?.toInt();

      final items = rows
          .map(ProductListItemReadRow.fromRow)
          .map(ProductListItemAssembler.toDto)
          .toList(growable: false);

      return ProductSearchResultDto(
        items: items,
        totalCount: totalCount,
        readyToSellCount: readyToSellCount,
        incompleteCount: incompleteCount,
        inactiveCount: inactiveCount,
      );
    });
  }

  /// 2. List custom field filter options.
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    int maxOptionsPerField = 50,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'list_custom_field_filter_options',
        params: {
          'p_tenant_id': tid,
          'p_max_options_per_field': maxOptionsPerField,
        },
      );
      return CustomFieldFilterOptionDto.listFromJson(result);
    });
  }

  /// 3. Check duplicate product codes (SKU, barcode).
  Future<List<ProductDuplicateMatchDto>> checkDuplicateCodes({
    String? sku,
    String? barcode,
    String? excludeProductId,
  }) async {
    final tid = await _tenantId();
    final trimmedSku = sku?.trim();
    final finalSku = (trimmedSku != null && trimmedSku.isNotEmpty) ? trimmedSku.toUpperCase() : null;
    final trimmedBarcode = barcode?.trim();
    final finalBarcode = (trimmedBarcode != null && trimmedBarcode.isNotEmpty) ? trimmedBarcode : null;

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'check_duplicate_product_code',
        params: {
          'p_tenant_id': tid,
          'p_sku': finalSku,
          'p_barcode': finalBarcode,
          'p_exclude_product_id': excludeProductId,
        },
      );

      return rows
          .map((row) => ProductDuplicateMatchDto.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    });
  }

  /// 4. Create product with guided wizard flow (TH-02 2.1).
  Future<CreateGuidedProductResult> createGuided(CreateGuidedProductInput input) async {
    checkCreateGuided(input);
    final tid = await _tenantId();
    final aid = await _actorId();
    final id = const Uuid().v4();
    final referenceId = productReferenceIdFromUuid(id);

    return _guard(() async {
      final row = await _rpc.call(
        'catalog',
        'create_guided_product',
        params: {
          'p_tenant_id': tid,
          'p_actor_id': aid,
          'p_name': input.productName.trim(),
          'p_reference_id': referenceId,
          'p_trade_name': _optionalText(input.commercialName),
          'p_sku': _optionalText(input.sku),
          'p_barcode': _optionalText(input.barcode),
          'p_note': _optionalText(input.note),
          'p_images': input.images
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
          'p_tenant_unit_id': switch (input.baseUnit) {
            ExistingTenantUnit(:final unitId) => unitId,
            _ => null,
          },
          'p_new_unit_name': switch (input.baseUnit) {
            NewTenantUnit(:final name) => name,
            _ => null,
          },
          'p_base_price_after_vat': input.basePrice,
          'p_list_price_before_vat': input.listBeforeVat,
          'p_floor_price_before_vat': input.floorBeforeVat,
          'p_use_store_price_rule': input.useStorePriceRule,
          'p_price_band_source_type': switch (input.priceBandSourceType) {
            PriceBandSourceType.ruleBased => 'ruleBased',
            PriceBandSourceType.customConfig => 'customConfig',
            PriceBandSourceType.manual => 'manual',
            null => null,
          },
          'p_list_markup_ratio': input.listMarkupRatio,
          'p_floor_markup_ratio': input.floorMarkupRatio,
          'p_tracking_mode': input.trackingMode.wire,
          'p_expiry_required': input.expiryRequired,
          'p_custom_field_values': input.customFieldValues
              .map(
                (value) => <String, dynamic>{
                  'field_id': value.fieldId,
                  'text_value': value.textValue,
                  'number_value': value.numberValue,
                  'date_value': value.dateValue?.toIso8601String(),
                  'boolean_value': value.booleanValue,
                  'option_id': value.optionId,
                },
              )
              .toList(growable: false),
          'p_idempotency_key': id,
        },
      );

      final map = row is Map<String, dynamic> ? row : Map<String, dynamic>.from(row as Map);
      return CreateGuidedProductResult.fromJson(map);
    });
  }

  /// 5. Request image upload slot for product creation.
  Future<ProductImageUploadSlotDto> requestImageUpload({
    required String fileName,
    required String contentType,
    required int byteSize,
  }) async {
    checkImageUploadRequest(
      fileName: fileName,
      contentType: contentType,
      byteSize: byteSize,
    );
    final tid = await _tenantId();
    final aid = await _actorId();

    return _reserveSlot(
      rpc: 'request_product_image_upload',
      params: {
        'p_tenant_id': tid,
        'p_file_name': fileName,
        'p_content_type': contentType,
        'p_byte_size': byteSize,
        'p_actor_id': aid,
      },
    );
  }

  /// 6. Request image upload slot for product maintenance.
  Future<ProductImageUploadSlotDto> requestMaintenanceImageUpload({
    required String productId,
    required String fileName,
    required String contentType,
    required int byteSize,
  }) async {
    checkImageUploadRequest(
      fileName: fileName,
      contentType: contentType,
      byteSize: byteSize,
    );
    final tid = await _tenantId();
    final aid = await _actorId();

    return _reserveSlot(
      rpc: 'request_product_maintenance_image_upload',
      params: {
        'p_tenant_id': tid,
        'p_product_id': productId,
        'p_file_name': fileName,
        'p_content_type': contentType,
        'p_byte_size': byteSize,
        'p_actor_id': aid,
      },
    );
  }

  Future<ProductImageUploadSlotDto> _reserveSlot({
    required String rpc,
    required Map<String, dynamic> params,
  }) async {
    final rows = await _guard(() => _rpc.rows('catalog', rpc, params: params));

    if (rows.isEmpty) {
      throw const AppException(
        AppErrorCode.unknown,
        serverMessage: 'Image upload slot was not created.',
      );
    }

    final row = rows.first;
    final slotId = row['slot_id']?.toString();
    final storageKey = row['storage_key']?.toString();
    final expiresRaw = row['expires_at'];

    if (slotId == null || slotId.isEmpty || storageKey == null || storageKey.isEmpty) {
      throw const AppException(
        AppErrorCode.unknown,
        serverMessage: 'Invalid image upload slot response.',
      );
    }

    final expiresAt = _parseExpiresAt(expiresRaw);
    final String signedUploadUrl;
    try {
      signedUploadUrl = await _signUploadUrl(storageKey);
    } on StorageException catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.message, cause: e);
    }

    return ProductImageUploadSlotDto(
      slotId: slotId,
      storageKey: storageKey,
      signedUploadUrl: signedUploadUrl,
      expiresAt: expiresAt,
    );
  }

  /// 7. Load Product Control Center (TH-02 2.2).
  Future<ProductControlCenterDto> getControlCenter(String productId) async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'get_product_control_center',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(CatalogErrorCodes.productNotFound);
      }

      final payload = rows.first;
      final json = payload.containsKey('get_product_control_center')
          ? Map<String, dynamic>.from(payload['get_product_control_center'] as Map)
          : Map<String, dynamic>.from(payload);

      final model = ProductControlCenterReadModel.fromJson(json);
      final perms = readinessPermissionsOf(_hasPermission);
      final includeHistory = _hasPermission(CatalogPermissions.viewHistory);

      return ProductControlCenterAssembler.assemble(
        model: model,
        permissions: perms,
        includeChangeHistory: includeHistory,
      );
    });
  }

  /// 8. Load Product Readiness view (TH-02 2.3).
  Future<ProductReadinessViewDto> getReadiness(String productId) async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'get_product_readiness',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(CatalogErrorCodes.productNotFound);
      }

      final facts = ProductReadinessFacts.fromRow(rows.first);
      final readiness = ProductReadinessEvaluator.compute(facts);
      final perms = readinessPermissionsOf(_hasPermission);

      return ProductReadinessViewAssembler.assemble(
        facts: facts,
        readiness: readiness,
        permissions: perms,
      );
    });
  }

  /// 9. Update basic product profile (TH-02 4.1).
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
  }) async {
    checkUpdateProfile(
      productName: productName,
      sku: sku,
      barcode: barcode,
      expectedVersion: expectedVersion,
    );
    final tid = await _tenantId();
    final aid = await _actorId();

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'update_product_profile',
        params: {
          'p_tenant_id': tid,
          'p_actor_id': aid,
          'p_product_id': productId,
          'p_name': productName.trim(),
          'p_trade_name': _optionalText(commercialName),
          'p_sku': _optionalText(sku),
          'p_barcode': _optionalText(barcode),
          'p_description': _optionalText(description),
          'p_note': _optionalText(note),
          'p_expected_version': expectedVersion,
          if (trackingMode != null) 'p_tracking_mode': trackingMode.wire,
          if (expiryRequired != null) 'p_expiry_required': expiryRequired,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product update did not return a result.',
        );
      }
    });
  }

  /// 10. Update product images (TH-02 4.2).
  Future<void> updateImages({
    required String productId,
    int? expectedVersion,
    required List<ProductImageMutationInput> images,
  }) async {
    checkUpdateImages(
      images: images,
      expectedVersion: expectedVersion,
    );
    final tid = await _tenantId();
    final aid = await _actorId();

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'update_product_images',
        params: {
          'p_tenant_id': tid,
          'p_actor_id': aid,
          'p_product_id': productId,
          'p_images': images
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
          'p_expected_version': expectedVersion,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product image update did not return a result.',
        );
      }
    });
  }

  /// 11. Deactivate product (TH-02 5.1).
  Future<void> deactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) async {
    final tid = await _tenantId();
    final aid = await _actorId();

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'deactivate_product',
        params: {
          'p_tenant_id': tid,
          'p_actor_id': aid,
          'p_product_id': productId,
          'p_reason': _optionalText(reason),
          'p_expected_version': expectedVersion,
          'p_confirm_acknowledge_warnings': confirmAcknowledgeWarnings,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product deactivate did not return a result.',
        );
      }
    });
  }

  /// 12. Reactivate product (TH-02 5.1).
  Future<void> reactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) async {
    final tid = await _tenantId();
    final aid = await _actorId();

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'reactivate_product',
        params: {
          'p_tenant_id': tid,
          'p_actor_id': aid,
          'p_product_id': productId,
          'p_reason': _optionalText(reason),
          'p_expected_version': expectedVersion,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product reactivate did not return a result.',
        );
      }
    });
  }

  /// 13. Check product deletion eligibility (TH-02 5.2).
  Future<ProductDeletionEligibilityDto> checkDeletionEligibility(String productId) async {
    final tid = await _tenantId();

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'check_product_deletion_eligibility',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product deletion eligibility did not return a result.',
        );
      }

      return ProductDeletionEligibilityDto.fromRow(rows.first);
    });
  }

  /// 14. Soft delete product (TH-02 5.2).
  Future<void> delete({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) async {
    final tid = await _tenantId();
    final aid = await _actorId();

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'delete_product',
        params: {
          'p_tenant_id': tid,
          'p_actor_id': aid,
          'p_product_id': productId,
          'p_reason': _optionalText(reason),
          'p_expected_version': expectedVersion,
          'p_confirm_acknowledge_warnings': confirmAcknowledgeWarnings,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product delete did not return a result.',
        );
      }
    });
  }

  /// 15. Restore soft-deleted product (TH-02 5.3).
  Future<void> restore({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) async {
    final tid = await _tenantId();
    final aid = await _actorId();

    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'restore_product',
        params: {
          'p_tenant_id': tid,
          'p_actor_id': aid,
          'p_product_id': productId,
          'p_reason': _optionalText(reason),
          'p_expected_version': expectedVersion,
        },
      );

      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product restore did not return a result.',
        );
      }
    });
  }

  /// 16. Get product change history (TH-02 5.4).
  Future<ProductChangeHistoryResultDto> getChangeHistory({
    required String productId,
    int limit = 50,
    int offset = 0,
    List<String>? changeCategories,
  }) async {
    final tid = await _tenantId();

    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'get_product_change_history',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_limit': limit,
          'p_offset': offset,
          'p_categories': (changeCategories == null || changeCategories.isEmpty)
              ? null
              : changeCategories,
        },
      );

      final map = result is Map<String, dynamic> ? result : Map<String, dynamic>.from(result as Map);
      final page = ProductChangeHistoryPage.fromJson(map);
      return ProductChangeHistoryResultDto(
        productId: productId,
        items: page.items.map((row) => row.toDto()).toList(growable: false),
        totalCount: page.totalCount,
      );
    });
  }

  /// 17. Search sellable products for sales lookup (TH-02 9.1).
  Future<List<SellableProductDto>> searchSellable({
    required String storeId,
    String? keyword,
    int limit = 50,
    int offset = 0,
  }) async {
    final tid = await _tenantId();

    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'search_sellable_products',
        params: {
          'p_tenant_id': tid,
          'p_store_id': storeId,
          'p_keyword': keyword ?? '',
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      return CatalogSalesLookupParser.productsFromPayload(result);
    });
  }

  /// 18. Resolve sellable product by barcode (TH-02 9.1).
  Future<List<SellableProductDto>> resolveSellableBarcode({
    required String storeId,
    required String barcode,
  }) async {
    final tid = await _tenantId();

    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'resolve_sellable_barcode',
        params: {
          'p_tenant_id': tid,
          'p_store_id': storeId,
          'p_barcode': barcode,
        },
      );

      return CatalogSalesLookupParser.productsFromPayload(result);
    });
  }

  /// 19. List sellable product units (TH-02 9.1).
  Future<List<SellableProductUnitDto>> listSellableUnits({
    required String storeId,
    required String productId,
  }) async {
    final tid = await _tenantId();

    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'list_sellable_product_units',
        params: {
          'p_tenant_id': tid,
          'p_store_id': storeId,
          'p_product_id': productId,
        },
      );

      return CatalogSalesLookupParser.unitsFromPayload(result);
    });
  }

  /// 20. Resolve multiple sellable products by ID (TH-02 9.1).
  Future<List<SellableProductResolutionDto>> resolveSellable({
    required String storeId,
    required List<String> productIds,
  }) async {
    final tid = await _tenantId();

    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'resolve_sellable_products',
        params: {
          'p_tenant_id': tid,
          'p_store_id': storeId,
          'p_product_ids': productIds,
        },
      );

      return CatalogSalesLookupParser.resolutionsFromPayload(result);
    });
  }
}

String? _optionalText(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime _parseExpiresAt(Object? value) {
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value).toUtc();
  }
  return DateTime.now().toUtc().add(const Duration(hours: 1));
}
