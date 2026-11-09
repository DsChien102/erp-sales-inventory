/// Product Control Center read models and DTOs.
library;

import 'catalog_enums.dart';
import 'custom_field_filter_option.dart';
import 'product_change_history.dart';
import 'product_readiness.dart';

final class ProductImageDto {
  const ProductImageDto({
    required this.imageId,
    required this.storageKey,
    this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  final String imageId;
  final String storageKey;
  final String? url;
  final bool isPrimary;
  final int sortOrder;

  factory ProductImageDto.fromJson(Map<String, dynamic> row) {
    return ProductImageDto(
      imageId: row['image_id'] as String,
      storageKey: row['storage_key'] as String,
      url: row['url'] as String?,
      isPrimary: row['is_primary'] as bool? ?? false,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

final class ProductConversionUnitDto {
  const ProductConversionUnitDto({
    required this.name,
    required this.conversionRate,
    this.isActive = true,
  });

  final String name;
  final double conversionRate;
  final bool isActive;

  factory ProductConversionUnitDto.fromJson(Map<String, dynamic> row) {
    return ProductConversionUnitDto(
      name: row['name'] as String,
      conversionRate: (row['conversion_rate'] as num).toDouble(),
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

final class ProductProfileSummaryDto {
  const ProductProfileSummaryDto({
    required this.productId,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    required this.businessStatus,
    this.primaryImageUrl,
    this.images = const [],
    this.description,
    this.note,
    this.trackingMode = ProductTrackingMode.none,
    this.expiryRequired = false,
    this.hasInventoryMovements = false,
  });

  final String productId;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final ProductBusinessStatus businessStatus;
  final String? primaryImageUrl;
  final List<String> images;
  final String? description;
  final String? note;
  final ProductTrackingMode trackingMode;
  final bool expiryRequired;
  final bool hasInventoryMovements;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;
}

final class ProductUnitsCardDto {
  const ProductUnitsCardDto({
    this.baseUnitName,
    this.conversionUnits = const [],
    this.isMissing = false,
    this.missingMessage,
  });

  final String? baseUnitName;
  final List<ProductConversionUnitDto> conversionUnits;
  final bool isMissing;
  final String? missingMessage;
}

final class ProductStockCardDto {
  const ProductStockCardDto({
    required this.mode,
    required this.source,
    required this.sourceLabel,
    this.quantity,
    this.unitName,
    this.isConfigured = false,
    this.isOutOfStock = false,
    this.canAdjust = false,
    this.currentVersion,
    this.isPendingExternal = false,
    this.isMissing = false,
    this.missingMessage,
  });

  final StockMode mode;
  final StockDataSource source;
  final String sourceLabel;
  final int? quantity;
  final String? unitName;
  final bool isConfigured;
  final bool isOutOfStock;
  final bool canAdjust;
  final int? currentVersion;
  final bool isPendingExternal;
  final bool isMissing;
  final String? missingMessage;
}

final class ProductBasePriceCardDto {
  const ProductBasePriceCardDto({
    required this.mode,
    required this.sourceLabel,
    this.amount,
    this.currency = 'VND',
    this.baseUnitName,
    this.canEdit = false,
    this.isPendingExternal = false,
    this.isMissing = false,
    this.missingMessage,
  });

  final BasePriceMode mode;
  final String sourceLabel;
  final double? amount;
  final String currency;
  final String? baseUnitName;
  final bool canEdit;
  final bool isPendingExternal;
  final bool isMissing;
  final String? missingMessage;

  static String sourceLabelFor(BasePriceMode mode) => switch (mode) {
    BasePriceMode.manual => 'Nhập thủ công',
    BasePriceMode.costingModule => 'Từ module Giá vốn',
  };
}

final class ProductPriceBandCardDto {
  const ProductPriceBandCardDto({
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
    this.unitName,
    this.isMissing = false,
    this.isPendingCalculation = false,
    this.missingMessage,
    this.sourceType,
    this.storePriceRuleName,
    this.isCustomOverride = false,
  });

  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final String? unitName;
  final bool isMissing;
  final bool isPendingCalculation;
  final String? missingMessage;
  final PriceBandSourceType? sourceType;
  final String? storePriceRuleName;
  final bool isCustomOverride;
}

final class CustomFieldCardFieldDto {
  const CustomFieldCardFieldDto({
    required this.fieldId,
    required this.name,
    required this.fieldType,
    this.displayValue,
    this.isRequired = false,
    this.isMissing = false,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String fieldId;
  final String name;
  final String fieldType;
  final String? displayValue;
  final bool isRequired;
  final bool isMissing;
  final int sortOrder;
  final bool isActive;

  factory CustomFieldCardFieldDto.fromJson(Map<String, dynamic> row) {
    return CustomFieldCardFieldDto(
      fieldId: row['field_id'] as String,
      name: row['name'] as String,
      fieldType: row['field_type'] as String,
      displayValue: row['display_value'] as String?,
      isRequired: row['is_required'] as bool? ?? false,
      isMissing: row['is_missing'] as bool? ?? false,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

final class CustomFieldGroupCardDto {
  const CustomFieldGroupCardDto({
    required this.groupId,
    required this.name,
    this.iconKey,
    this.sortOrder = 0,
    this.fields = const [],
    this.hasRequiredMissing = false,
  });

  final String groupId;
  final String name;
  final String? iconKey;
  final int sortOrder;
  final List<CustomFieldCardFieldDto> fields;
  final bool hasRequiredMissing;

  factory CustomFieldGroupCardDto.fromJson(Map<String, dynamic> row) {
    final fieldsRaw = row['fields'];
    final fields = fieldsRaw is List
        ? fieldsRaw
            .whereType<Map>()
            .map((item) => CustomFieldCardFieldDto.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <CustomFieldCardFieldDto>[];

    return CustomFieldGroupCardDto(
      groupId: row['group_id'] as String,
      name: customFieldGroupDisplayName(row['name'] as String),
      iconKey: row['icon_key'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      fields: fields,
      hasRequiredMissing: row['has_required_missing'] as bool? ?? false,
    );
  }
}

final class ProductControlCenterDto {
  const ProductControlCenterDto({
    required this.profile,
    required this.units,
    required this.stock,
    required this.basePrice,
    required this.priceBand,
    this.customFieldGroupCards = const [],
    required this.readinessSummary,
    this.checklist = const [],
    this.contextualActions = const [],
    this.changeHistoryPreview = const [],
    this.primaryActionId,
  });

  final ProductProfileSummaryDto profile;
  final ProductUnitsCardDto units;
  final ProductStockCardDto stock;
  final ProductBasePriceCardDto basePrice;
  final ProductPriceBandCardDto priceBand;
  final List<CustomFieldGroupCardDto> customFieldGroupCards;
  final ReadinessSummaryDto readinessSummary;
  final List<ReadinessChecklistItemDto> checklist;
  final List<ContextualActionDto> contextualActions;
  final List<ProductChangeHistoryEntryDto> changeHistoryPreview;
  final String? primaryActionId;
}

final class ProductControlCenterReadModel {
  const ProductControlCenterReadModel({
    required this.productId,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    this.description,
    this.note,
    required this.businessStatus,
    this.primaryImageUrl,
    this.images = const [],
    this.baseUnitName,
    this.conversionUnits = const [],
    required this.facts,
    this.stockQuantity,
    this.stockVersion,
    this.basePriceAmount,
    this.basePriceCurrency = 'VND',
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.priceBandEffectiveFrom,
    this.priceBandEffectiveTo,
    this.priceBandStatus,
    this.priceBandSourceType,
    this.storePriceRuleName,
    this.isCustomOverride = false,
    this.customFieldGroupCards = const [],
    this.changeHistoryPreview = const [],
    this.trackingMode = ProductTrackingMode.none,
    this.expiryRequired = false,
    this.hasInventoryMovements = false,
  });

  final String productId;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? description;
  final String? note;
  final ProductBusinessStatus businessStatus;
  final String? primaryImageUrl;
  final List<String> images;
  final String? baseUnitName;
  final List<ProductConversionUnitDto> conversionUnits;
  final ProductReadinessFacts facts;
  final int? stockQuantity;
  final int? stockVersion;
  final double? basePriceAmount;
  final String basePriceCurrency;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? priceBandEffectiveFrom;
  final DateTime? priceBandEffectiveTo;
  final ProductPriceBandStatus? priceBandStatus;
  final PriceBandSourceType? priceBandSourceType;
  final String? storePriceRuleName;
  final bool isCustomOverride;
  final List<CustomFieldGroupCardDto> customFieldGroupCards;
  final List<ProductChangeHistoryEntryDto> changeHistoryPreview;
  final ProductTrackingMode trackingMode;
  final bool expiryRequired;
  final bool hasInventoryMovements;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;

  factory ProductControlCenterReadModel.fromJson(Map<String, dynamic> json) {
    final productId = json['product_id'] as String;
    final productName = json['name'] as String;

    final facts = ProductReadinessFacts.fromRow(json);

    final images = (json['images'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);

    final conversionUnits = (json['conversion_units'] as List<dynamic>? ?? const [])
        .map((item) => ProductConversionUnitDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);

    final history = (json['change_history_preview'] as List<dynamic>? ?? const [])
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProductChangeHistoryEntryDto(
            id: map['id'] as String,
            occurredAt: DateTime.parse(map['occurred_at'] as String),
            actorDisplayName: map['actor_display_name'] as String,
            changeType: ProductChangeHistoryAction.tryParse(map['change_type'] as String?),
            summary: map['summary'] as String,
            valueBefore: map['value_before'] as String?,
            valueAfter: map['value_after'] as String?,
          );
        })
        .toList(growable: false);

    final isSoftDeleted = json['is_soft_deleted'] as bool?;
    final businessStatus = isSoftDeleted == true
        ? ProductBusinessStatus.softDeleted
        : switch (json['business_status'] as String?) {
            'inactive' => ProductBusinessStatus.inactive,
            'soft_deleted' => ProductBusinessStatus.softDeleted,
            _ => ProductBusinessStatus.active,
          };

    final customFieldGroupCardsRaw = json['custom_field_group_cards'] as List<dynamic>? ?? const [];
    final customFieldGroupCards = customFieldGroupCardsRaw
        .whereType<Map>()
        .map((item) => CustomFieldGroupCardDto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    final trackingMode = ProductTrackingMode.fromWire(json['tracking_mode'] as String?);
    final expiryRequired = json['expiry_required'] as bool? ?? false;
    final hasInventoryMovements = json['has_inventory_movements'] as bool? ?? false;

    return ProductControlCenterReadModel(
      productId: productId,
      name: productName,
      tradeName: json['trade_name'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      note: json['note'] as String?,
      businessStatus: businessStatus,
      primaryImageUrl: json['primary_image_url'] as String?,
      images: images,
      baseUnitName: json['base_unit_name'] as String?,
      conversionUnits: conversionUnits,
      facts: facts,
      stockQuantity: _toInt(json['stock_qty']),
      stockVersion: _toInt(json['stock_version']),
      basePriceAmount: _toDouble(json['base_price_after_vat']) ?? _toDouble(json['base_price_amount']),
      basePriceCurrency: json['base_price_currency'] as String? ?? 'VND',
      listBeforeVat: _toInt(json['list_price_before_vat']) ?? _toInt(json['list_price']),
      floorBeforeVat: _toInt(json['floor_price_before_vat']) ?? _toInt(json['floor_price']),
      listAfterVat: _toInt(json['list_price_after_vat']),
      floorAfterVat: _toInt(json['floor_price_after_vat']),
      priceBandSourceType: switch (json['price_band_source_type'] as String?) {
        'ruleBased' => PriceBandSourceType.ruleBased,
        'customConfig' => PriceBandSourceType.customConfig,
        'manual' => PriceBandSourceType.manual,
        _ => null,
      },
      storePriceRuleName: json['store_price_rule_name'] as String?,
      isCustomOverride: json['is_custom_override'] as bool? ?? false,
      customFieldGroupCards: customFieldGroupCards,
      changeHistoryPreview: history,
      trackingMode: trackingMode,
      expiryRequired: expiryRequired,
      hasInventoryMovements: hasInventoryMovements,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}

