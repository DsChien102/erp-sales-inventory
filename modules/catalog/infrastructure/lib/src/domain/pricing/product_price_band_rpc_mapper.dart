import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

abstract final class ProductPriceBandRpcMapper {
  static Map<String, dynamic> setProductUnitPriceBandParams({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    required PriceBandSourceType sourceType,
    String? storePriceRuleId,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
    double? listMarkupRatio,
    double? floorMarkupRatio,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_product_unit_id': productUnitId,
      'p_list_price_before_vat': listBeforeVat,
      'p_floor_price_before_vat': ?floorBeforeVat,
      'p_list_price_after_vat': listAfterVat,
      'p_floor_price_after_vat': ?floorAfterVat,
      'p_effective_from': ?effectiveFrom?.toUtc().toIso8601String(),
      'p_effective_to': ?effectiveTo?.toUtc().toIso8601String(),
      'p_status': ?status?.toWire(),
      'p_source_type': sourceTypeToRpc(sourceType),
      'p_store_price_rule_id': storePriceRuleId,
      'p_list_markup_ratio': listMarkupRatio,
      'p_floor_markup_ratio': floorMarkupRatio,
    };
  }

  static Map<String, dynamic> listProductUnitPriceBandsParams({
    required String tenantId,
    required String productId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
    };
  }

  static Map<String, dynamic> getPriceBandSnapshotParams({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_items': items
          .map(
            (item) => <String, dynamic>{
              'product_id': item.productId,
              'product_unit_id': item.productUnitId,
            },
          )
          .toList(growable: false),
    };
  }

  static ProductPriceBandSnapshotDto snapshotFromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      return const ProductPriceBandSnapshotDto(items: []);
    }

    return ProductPriceBandSnapshotDto(
      items: rawItems
          .whereType<Map>()
          .map((item) => snapshotItemFromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  static ProductPriceBandSnapshotItemDto snapshotItemFromJson(
    Map<String, dynamic> item,
  ) {
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
      isUnitActive: item['is_unit_active'] as bool? ?? false,
      productBusinessStatus: _productStatusFromRpc(
        item['product_business_status'] as String?,
      ),
      capturedAt: DateTime.utc(1970),
    );
  }

  static ProductBusinessStatus _productStatusFromRpc(String? value) {
    return switch (value) {
      'inactive' => ProductBusinessStatus.inactive,
      'soft_deleted' => ProductBusinessStatus.softDeleted,
      _ => ProductBusinessStatus.active,
    };
  }

  static ProductUnitPriceBandsDto bandsFromRows(List<Map<String, dynamic>> rows) {
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
      rows: rows.map(rowFromListRpc).toList(growable: false),
    );
  }

  static double? _basePricePerBaseUnitFromRows(List<Map<String, dynamic>> rows) {
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

  static int? _readOptionalPrice(
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

  static double? _readOptionalDouble(
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

  static bool? _readOptionalBool(
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

  static DateTime? _readOptionalDateTime(Map<String, dynamic> row, String key) {
    final raw = row[key];
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }

  static ProductUnitPriceBandRowDto rowFromListRpc(Map<String, dynamic> row) {
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
      sourceType: sourceTypeFromRpc(row['source_type'] as String?),
      storePriceRuleName: row['store_price_rule_name'] as String?,
      listMarkupRatio: _readOptionalDouble(row, const ['list_markup_ratio']),
      floorMarkupRatio: _readOptionalDouble(row, const ['floor_markup_ratio']),
      isCustomOverride: row['is_custom_override'] as bool? ?? false,
    );
  }

  static String sourceTypeToRpc(PriceBandSourceType sourceType) {
    return switch (sourceType) {
      PriceBandSourceType.ruleBased => 'ruleBased',
      PriceBandSourceType.customConfig => 'customConfig',
      PriceBandSourceType.manual => 'manual',
    };
  }

  static PriceBandSourceType? sourceTypeFromRpc(String? value) {
    return switch (value) {
      'ruleBased' => PriceBandSourceType.ruleBased,
      'customConfig' => PriceBandSourceType.customConfig,
      'manual' => PriceBandSourceType.manual,
      _ => null,
    };
  }
}
