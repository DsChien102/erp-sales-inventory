/// Product search models and row parsers.
library;

import 'catalog_enums.dart';
import 'custom_field_filter_option.dart';
import 'product_readiness.dart';

final class SearchKeywordNormalizer {
  const SearchKeywordNormalizer._();

  static String? normalizeKeyword(String? keyword) {
    if (keyword == null) {
      return null;
    }
    final value = keyword.trim();
    return value.isEmpty ? null : value;
  }
}

final class CustomFieldFilterCriteria {
  const CustomFieldFilterCriteria({
    required this.fieldId,
    this.optionId,
    this.booleanValue,
  });

  final String fieldId;
  final String? optionId;
  final bool? booleanValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFieldFilterCriteria &&
          other.fieldId == fieldId &&
          other.optionId == optionId &&
          other.booleanValue == booleanValue);

  @override
  int get hashCode => Object.hash(fieldId, optionId, booleanValue);
}

final class ProductSearchCriteria {
  ProductSearchCriteria({
    String? keyword,
    Set<ProductBusinessStatus>? businessStatuses,
    List<CustomFieldFilterCriteria>? customFieldFilters,
    this.readinessFilter,
    this.includeSoftDeleted = false,
    this.sortOrder = ProductSortOrder.updatedAtDesc,
  }) : keyword = SearchKeywordNormalizer.normalizeKeyword(keyword),
       businessStatuses = businessStatuses == null || businessStatuses.isEmpty
           ? {ProductBusinessStatus.active}
           : Set.unmodifiable(businessStatuses),
       customFieldFilters = List.unmodifiable(customFieldFilters ?? const []);

  final String? keyword;
  final Set<ProductBusinessStatus> businessStatuses;
  final List<CustomFieldFilterCriteria> customFieldFilters;
  final ProductReadinessFilter? readinessFilter;
  final bool includeSoftDeleted;
  final ProductSortOrder sortOrder;

  bool get activeOnly =>
      businessStatuses.length == 1 &&
      businessStatuses.contains(ProductBusinessStatus.active);
}

final class CustomFieldListValueDto {
  const CustomFieldListValueDto({
    required this.fieldId,
    required this.groupId,
    required this.groupName,
    required this.fieldName,
    required this.fieldType,
    required this.displayValue,
    required this.sortOrder,
  });

  final String fieldId;
  final String groupId;
  final String groupName;
  final String fieldName;
  final String fieldType;
  final String displayValue;
  final int sortOrder;

  factory CustomFieldListValueDto.fromJson(Map<String, dynamic> row) {
    return CustomFieldListValueDto(
      fieldId: row['field_id'] as String,
      groupId: row['group_id'] as String,
      groupName: customFieldGroupDisplayName(row['group_name'] as String),
      fieldName: row['field_name'] as String,
      fieldType: row['field_type'] as String,
      displayValue: row['display_value'] as String? ?? '',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static List<CustomFieldListValueDto> listFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((e) => CustomFieldListValueDto.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}

final class ProductListItemDto {
  const ProductListItemDto({
    required this.id,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    this.primaryImageUrl,
    required this.businessStatus,
    required this.readinessSummary,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.baseUnit,
    this.stockQuantity,
    this.stockLabel,
    this.customFieldValues = const [],
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? primaryImageUrl;
  final ProductBusinessStatus businessStatus;
  final ReadinessSummaryDto readinessSummary;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final String? baseUnit;
  final int? stockQuantity;
  final String? stockLabel;
  final List<CustomFieldListValueDto> customFieldValues;
  final DateTime updatedAt;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;
}

final class ProductSearchResultDto {
  const ProductSearchResultDto({
    required this.items,
    required this.totalCount,
    this.readyToSellCount,
    this.incompleteCount,
    this.inactiveCount,
  });

  final List<ProductListItemDto> items;
  final int totalCount;
  final int? readyToSellCount;
  final int? incompleteCount;
  final int? inactiveCount;
}

final class ProductListItemReadRow {
  const ProductListItemReadRow({
    required this.id,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    this.primaryImageUrl,
    required this.businessStatus,
    required this.facts,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.baseUnit,
    this.stockQuantity,
    this.customFieldValues = const [],
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? primaryImageUrl;
  final ProductBusinessStatus businessStatus;
  final ProductReadinessFacts facts;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final String? baseUnit;
  final int? stockQuantity;
  final List<CustomFieldListValueDto> customFieldValues;
  final DateTime updatedAt;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;

  static ProductListItemReadRow fromRow(Map<String, dynamic> row) {
    final productId = row['product_id'] as String;
    final productName = row['name'] as String;

    final facts = ProductReadinessFacts.fromRow(row);

    final isSoftDeleted = row['is_soft_deleted'] as bool?;
    final businessStatus = isSoftDeleted == true
        ? ProductBusinessStatus.softDeleted
        : switch (row['business_status'] as String?) {
            'inactive' => ProductBusinessStatus.inactive,
            'soft_deleted' => ProductBusinessStatus.softDeleted,
            _ => ProductBusinessStatus.active,
          };

    return ProductListItemReadRow(
      id: productId,
      name: productName,
      tradeName: row['trade_name'] as String?,
      sku: row['sku'] as String?,
      barcode: row['barcode'] as String?,
      primaryImageUrl: row['primary_image_url'] as String?,
      businessStatus: businessStatus,
      facts: facts,
      listBeforeVat: _toInt(row['list_price_before_vat']) ?? _toInt(row['list_price']),
      floorBeforeVat: _toInt(row['floor_price_before_vat']) ?? _toInt(row['floor_price']),
      listAfterVat: _toInt(row['list_price_after_vat']),
      floorAfterVat: _toInt(row['floor_price_after_vat']),
      baseUnit: row['base_unit_name'] as String?,
      stockQuantity: _toInt(row['stock_qty']),
      customFieldValues: CustomFieldListValueDto.listFromJson(
        row['custom_field_values'],
      ),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}
