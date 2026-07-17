import 'package:vet45_catalog_application/application.dart';

abstract final class ProductChangeHistoryRpcMapper {
  static Map<String, dynamic> getProductChangeHistoryParams({
    required String tenantId,
    required String productId,
    required int limit,
    required int offset,
    List<ProductChangeCategory> changeCategories = const [],
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_limit': limit,
      'p_offset': offset,
      'p_categories': changeCategories.isEmpty
          ? null
          : changeCategories.map((category) => category.wireValue).toList(growable: false),
    };
  }

  static ProductChangeHistoryPage pageFromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => readRowFromJson(item.cast<String, dynamic>()))
              .toList(growable: false)
        : const <ProductChangeHistoryReadRow>[];

    return ProductChangeHistoryPage(
      items: items,
      totalCount: json['total_count'] as int? ?? items.length,
    );
  }

  static ProductChangeHistoryReadRow readRowFromJson(Map<String, dynamic> item) {
    final action = ProductChangeHistoryAction.tryParse(
      item['change_type'] as String?,
    );
    final category =
        ProductChangeCategoryCodec.tryParse(item['change_category'] as String?) ??
        action?.category ??
        ProductChangeCategory.other;
    final isSensitiveMasked = item['is_sensitive_masked'] as bool? ?? false;

    return ProductChangeHistoryReadRow(
      id: item['id'] as String,
      occurredAt: DateTime.parse(item['occurred_at'] as String),
      actorDisplayName: item['actor_display_name'] as String? ?? '',
      changeType: action,
      summary: item['summary'] as String? ?? '',
      changeCategory: category,
      source: item['source'] as String? ?? 'user',
      isSensitiveMasked: isSensitiveMasked,
      valueBefore: item['value_before'] as String?,
      valueAfter: item['value_after'] as String?,
      reason: item['reason'] as String?,
      priceBandChange: isSensitiveMasked
          ? null
          : _priceBandChangeFromJson(item['price_band_change']),
    );
  }

  static ProductPriceBandHistoryChangeDto? _priceBandChangeFromJson(
    Object? raw,
  ) {
    final json = _stringKeyedMap(raw);
    if (json == null) return null;

    final productUnitId = json['product_unit_id'];
    final unitName = json['unit_name'];
    final currency = json['currency'];
    final trigger = ProductPriceBandHistoryTrigger.tryParse(
      json['trigger'] as String?,
    );
    final after = _priceBandSnapshotFromJson(json['after']);
    if (productUnitId is! String ||
        productUnitId.isEmpty ||
        unitName is! String ||
        unitName.isEmpty ||
        currency is! String ||
        currency.isEmpty ||
        trigger == null ||
        after == null) {
      return null;
    }

    final rawBefore = json['before'];
    final before = rawBefore == null ? null : _priceBandSnapshotFromJson(rawBefore);
    if (rawBefore != null && before == null) return null;

    return ProductPriceBandHistoryChangeDto(
      productUnitId: productUnitId,
      unitName: unitName,
      currency: currency,
      trigger: trigger,
      before: before,
      after: after,
    );
  }

  static ProductPriceBandHistorySnapshotDto? _priceBandSnapshotFromJson(
    Object? raw,
  ) {
    final json = _stringKeyedMap(raw);
    if (json == null) return null;

    final sourceType = switch (json['source_type']) {
      'ruleBased' => PriceBandSourceType.ruleBased,
      'customConfig' => PriceBandSourceType.customConfig,
      'manual' => PriceBandSourceType.manual,
      _ => null,
    };
    final listPrice = json['list_price'];
    final floorPrice = json['floor_price'];
    if (sourceType == null || listPrice is! num || (floorPrice != null && floorPrice is! num)) {
      return null;
    }

    return ProductPriceBandHistorySnapshotDto(
      sourceType: sourceType,
      listPrice: listPrice.toInt(),
      floorPrice: floorPrice is num ? floorPrice.toInt() : null,
    );
  }

  static Map<String, dynamic>? _stringKeyedMap(Object? raw) {
    if (raw is! Map) return null;
    try {
      return Map<String, dynamic>.from(raw);
    } on TypeError {
      return null;
    }
  }
}
