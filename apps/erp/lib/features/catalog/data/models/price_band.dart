/// Price band models for units, snapshots, and suggestions (TH-02).
library;

import 'catalog_enums.dart';

int? _readOptionalPrice(
  Map<String, dynamic> row,
  List<String> keys,
) {
  for (final key in keys) {
    final value = row[key];
    if (value is num) {
      return value.round();
    }
  }
  return null;
}

double? _readOptionalDouble(
  Map<String, dynamic> row,
  List<String> keys,
) {
  for (final key in keys) {
    final value = row[key];
    if (value is num) {
      return value.toDouble();
    }
  }
  return null;
}

bool? _readOptionalBool(
  Map<String, dynamic> row,
  List<String> keys,
) {
  for (final key in keys) {
    final value = row[key];
    if (value is bool) {
      return value;
    }
  }
  return null;
}

DateTime? _readOptionalDateTime(Map<String, dynamic> row, String key) {
  final raw = row[key];
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toUtc();
  }
  return null;
}

double? _basePricePerBaseUnitFromRows(List<Map<String, dynamic>> rows) {
  for (final row in rows) {
    if (row['is_base_unit'] == true) {
      return _readOptionalDouble(row, const [
        'base_price_per_base_unit',
        'base_price',
        'base_price_after_vat',
        'base_price_amount',
      ]);
    }
  }
  return _readOptionalDouble(rows.first, const [
    'base_price',
    'base_price_after_vat',
    'base_price_amount',
  ]);
}

ProductBusinessStatus _productStatusFromRpc(String? value) {
  return switch (value) {
    'inactive' => ProductBusinessStatus.inactive,
    'soft_deleted' => ProductBusinessStatus.softDeleted,
    _ => ProductBusinessStatus.active,
  };
}

final class ProductUnitPriceBandsDto {
  const ProductUnitPriceBandsDto({
    required this.productId,
    required this.baseUnitName,
    required this.rows,
    this.currency = 'VND',
    this.basePrice,
  });

  final String productId;
  final String baseUnitName;
  final String currency;
  final double? basePrice;
  final List<ProductUnitPriceBandRowDto> rows;

  factory ProductUnitPriceBandsDto.fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      throw ArgumentError('Price band list returned no rows.');
    }
    final first = rows.first;
    final productId = first['product_id'] as String;
    final baseUnitName = first['base_unit_name'] as String? ?? '';
    final currency = first['currency'] as String? ?? 'VND';
    final basePricePerBaseUnit =
        _readOptionalDouble(first, const [
          'base_price_per_base_unit',
          'base_price_amount',
        ]) ??
        _basePricePerBaseUnitFromRows(rows);

    return ProductUnitPriceBandsDto(
      productId: productId,
      baseUnitName: baseUnitName,
      currency: currency,
      basePrice: basePricePerBaseUnit,
      rows: rows.map(ProductUnitPriceBandRowDto.fromRow).toList(growable: false),
    );
  }
}

final class ProductUnitPriceBandRowDto {
  const ProductUnitPriceBandRowDto({
    required this.productUnitId,
    required this.unitName,
    required this.isBaseUnit,
    required this.isActive,
    required this.isMissing,
    this.basePrice,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
    this.sourceType,
    this.storePriceRuleName,
    this.listMarkupRatio,
    this.floorMarkupRatio,
    this.isCustomOverride = false,
  });

  final String productUnitId;
  final String unitName;
  final bool isBaseUnit;
  final bool isActive;

  /// Base cost for this selling unit (= per-base-unit × conversion_rate_to_base).
  final double? basePrice;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final bool isMissing;
  final PriceBandSourceType? sourceType;
  final String? storePriceRuleName;
  final double? listMarkupRatio;
  final double? floorMarkupRatio;

  @Deprecated('Use sourceType == PriceBandSourceType.customConfig instead.')
  final bool isCustomOverride;

  factory ProductUnitPriceBandRowDto.fromRow(Map<String, dynamic> row) {
    final listBeforeVat = _readOptionalPrice(row, const [
      'list_price_before_vat',
      'list_price',
      'list_price_amount',
    ]);
    final floorBeforeVat = _readOptionalPrice(row, const [
      'floor_price_before_vat',
      'floor_price',
      'floor_price_amount',
    ]);
    final listAfterVat = _readOptionalPrice(row, const [
      'list_price_after_vat',
      'list_after_vat',
    ]);
    final floorAfterVat = _readOptionalPrice(row, const [
      'floor_price_after_vat',
      'floor_after_vat',
    ]);
    final isMissing = listBeforeVat == null || listAfterVat == null;
    final statusRaw = row['status'] as String? ?? row['price_band_status'] as String?;
    final basePrice = _readOptionalDouble(row, const [
      'base_price',
      'base_price_after_vat',
      'base_price_amount',
    ]);

    return ProductUnitPriceBandRowDto(
      productUnitId: row['product_unit_id'] as String,
      unitName: row['unit_name'] as String,
      isBaseUnit: row['is_base_unit'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? true,
      basePrice: basePrice,
      listBeforeVat: listBeforeVat,
      floorBeforeVat: floorBeforeVat,
      listAfterVat: listAfterVat,
      floorAfterVat: floorAfterVat,
      effectiveFrom: _readOptionalDateTime(row, 'effective_from'),
      effectiveTo: _readOptionalDateTime(row, 'effective_to'),
      status: statusRaw == null ? null : ProductPriceBandStatus.tryFromWire(statusRaw),
      isMissing: isMissing,
      sourceType: switch (row['source_type'] as String?) {
        'ruleBased' => PriceBandSourceType.ruleBased,
        'customConfig' => PriceBandSourceType.customConfig,
        'manual' => PriceBandSourceType.manual,
        _ => null,
      },
      storePriceRuleName: row['store_price_rule_name'] as String?,
      listMarkupRatio: _readOptionalDouble(row, const ['list_markup_ratio']),
      floorMarkupRatio: _readOptionalDouble(row, const ['floor_markup_ratio']),
      isCustomOverride: row['is_custom_override'] as bool? ?? false,
    );
  }
}

final class ProductPriceBandSnapshotDto {
  const ProductPriceBandSnapshotDto({required this.items});

  final List<ProductPriceBandSnapshotItemDto> items;

  factory ProductPriceBandSnapshotDto.fromJson(
    Map<String, dynamic> json, {
    required DateTime capturedAt,
  }) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      return const ProductPriceBandSnapshotDto(items: []);
    }

    return ProductPriceBandSnapshotDto(
      items: rawItems
          .whereType<Map>()
          .map((item) => ProductPriceBandSnapshotItemDto.fromJson(
                item.cast<String, dynamic>(),
                capturedAt: capturedAt,
              ))
          .toList(growable: false),
    );
  }
}

final class ProductPriceBandSnapshotItemDto {
  const ProductPriceBandSnapshotItemDto({
    required this.productId,
    required this.productUnitId,
    required this.unitName,
    required this.currency,
    required this.listBeforeVatMissing,
    required this.floorBeforeVatMissing,
    required this.floorBeforeVatHidden,
    required this.isUnitActive,
    required this.productBusinessStatus,
    required this.capturedAt,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
  });

  final String productId;
  final String productUnitId;
  final String unitName;
  final String currency;
  final int? listBeforeVat;
  final bool listBeforeVatMissing;
  final int? floorBeforeVat;
  final bool floorBeforeVatMissing;
  final bool floorBeforeVatHidden;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final bool isUnitActive;
  final ProductBusinessStatus productBusinessStatus;
  final DateTime capturedAt;

  factory ProductPriceBandSnapshotItemDto.fromJson(
    Map<String, dynamic> item, {
    required DateTime capturedAt,
  }) {
    final listBeforeVat = _readOptionalPrice(item, const [
      'list_price_before_vat',
      'list_price',
      'list_price_amount',
    ]);
    final floorBeforeVat = _readOptionalPrice(item, const [
      'floor_price_before_vat',
      'floor_price',
      'floor_price_amount',
    ]);
    final listAfterVat = _readOptionalPrice(item, const [
      'list_price_after_vat',
    ]);
    final floorAfterVat = _readOptionalPrice(item, const [
      'floor_price_after_vat',
    ]);

    return ProductPriceBandSnapshotItemDto(
      productId: item['product_id'] as String,
      productUnitId: item['product_unit_id'] as String,
      unitName: item['unit_name'] as String? ?? '',
      currency: item['currency'] as String? ?? 'VND',
      listBeforeVat: listBeforeVat,
      listBeforeVatMissing:
          _readOptionalBool(
            item,
            const ['list_price_before_vat_missing', 'list_price_missing'],
          ) ??
          listBeforeVat == null,
      floorBeforeVat: floorBeforeVat,
      floorBeforeVatMissing:
          _readOptionalBool(
            item,
            const ['floor_price_before_vat_missing', 'floor_price_missing'],
          ) ??
          floorBeforeVat == null,
      floorBeforeVatHidden:
          _readOptionalBool(
            item,
            const ['floor_price_before_vat_hidden', 'floor_price_hidden'],
          ) ??
          false,
      listAfterVat: listAfterVat,
      floorAfterVat: floorAfterVat,
      isUnitActive: item['is_unit_active'] as bool? ?? false,
      productBusinessStatus: _productStatusFromRpc(
        item['product_business_status'] as String?,
      ),
      capturedAt: capturedAt,
    );
  }
}

final class ProductPriceBandSnapshotRequest {
  const ProductPriceBandSnapshotRequest({
    required this.productId,
    required this.productUnitId,
  });

  final String productId;
  final String productUnitId;
}

final class ProductUnitPriceSuggestionDto {
  const ProductUnitPriceSuggestionDto({
    required this.productId,
    required this.basePrice,
    required this.currency,
    required this.canSuggest,
    this.productUnitId,
    this.unitName,
    this.suggestedListBeforeVat,
    this.suggestedFloorBeforeVat,
    this.storePriceRuleId,
    this.storePriceRuleName,
    this.basePriceVersion,
    this.unavailableReason,
  });

  final String productId;
  final String? productUnitId;
  final String? unitName;
  final double basePrice;
  final String currency;
  final int? suggestedListBeforeVat;
  final int? suggestedFloorBeforeVat;
  final String? storePriceRuleId;
  final String? storePriceRuleName;
  final int? basePriceVersion;
  final bool canSuggest;
  final String? unavailableReason;

  factory ProductUnitPriceSuggestionDto.fromRow(Map<String, dynamic> row) {
    return ProductUnitPriceSuggestionDto(
      productId: row['product_id'] as String,
      productUnitId: row['product_unit_id'] as String?,
      unitName: row['unit_name'] as String?,
      basePrice: (row['base_price'] as num?)?.toDouble() ?? 0,
      currency: row['currency'] as String? ?? 'VND',
      suggestedListBeforeVat:
          (row['suggested_list_price_before_vat'] as num?)?.round() ??
              (row['suggested_list_price'] as num?)?.round(),
      suggestedFloorBeforeVat:
          (row['suggested_floor_price_before_vat'] as num?)?.round() ??
              (row['suggested_floor_price'] as num?)?.round(),
      storePriceRuleId: row['store_price_rule_id'] as String?,
      storePriceRuleName: row['store_price_rule_name'] as String?,
      basePriceVersion: (row['base_price_version'] as num?)?.toInt(),
      canSuggest: row['can_suggest'] as bool? ?? false,
      unavailableReason: row['unavailable_reason'] as String?,
    );
  }
}

