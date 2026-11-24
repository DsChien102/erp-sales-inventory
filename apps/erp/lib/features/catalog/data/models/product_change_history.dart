/// Product change history models and parsers.
library;

import 'catalog_enums.dart';

final class ProductPriceBandHistorySnapshotDto {
  const ProductPriceBandHistorySnapshotDto({
    required this.sourceType,
    required this.listPrice,
    this.floorPrice,
  });

  final PriceBandSourceType sourceType;
  final int listPrice;
  final int? floorPrice;
}

final class ProductPriceBandHistoryChangeDto {
  const ProductPriceBandHistoryChangeDto({
    required this.productUnitId,
    required this.unitName,
    required this.currency,
    required this.trigger,
    required this.after,
    this.before,
  });

  final String productUnitId;
  final String unitName;
  final String currency;
  final ProductPriceBandHistoryTrigger trigger;
  final ProductPriceBandHistorySnapshotDto? before;
  final ProductPriceBandHistorySnapshotDto after;
}

final class ProductChangeHistoryEntryDto {
  const ProductChangeHistoryEntryDto({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.changeType,
    required this.summary,
    this.valueBefore,
    this.valueAfter,
    this.changeCategory,
    this.source = 'user',
    this.isSensitiveMasked = false,
    this.reason,
    this.priceBandChange,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final ProductChangeHistoryAction? changeType;
  final String summary;
  final String? valueBefore;
  final String? valueAfter;
  final ProductChangeCategory? changeCategory;
  final String source;
  final bool isSensitiveMasked;
  final String? reason;
  final ProductPriceBandHistoryChangeDto? priceBandChange;
}

final class ProductChangeHistoryReadRow {
  const ProductChangeHistoryReadRow({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.changeType,
    required this.summary,
    required this.changeCategory,
    required this.source,
    required this.isSensitiveMasked,
    this.valueBefore,
    this.valueAfter,
    this.reason,
    this.priceBandChange,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final ProductChangeHistoryAction? changeType;
  final String summary;
  final ProductChangeCategory changeCategory;
  final String source;
  final bool isSensitiveMasked;
  final String? valueBefore;
  final String? valueAfter;
  final String? reason;
  final ProductPriceBandHistoryChangeDto? priceBandChange;

  ProductChangeHistoryEntryDto toDto() => ProductChangeHistoryEntryDto(
    id: id,
    occurredAt: occurredAt,
    actorDisplayName: actorDisplayName,
    changeType: changeType,
    summary: summary,
    valueBefore: valueBefore,
    valueAfter: valueAfter,
    changeCategory: changeCategory,
    source: source,
    isSensitiveMasked: isSensitiveMasked,
    reason: reason,
    priceBandChange: priceBandChange,
  );
}

final class ProductChangeHistoryPage {
  const ProductChangeHistoryPage({
    required this.items,
    required this.totalCount,
  });

  final List<ProductChangeHistoryReadRow> items;
  final int totalCount;

  factory ProductChangeHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => readRowFromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <ProductChangeHistoryReadRow>[];

    return ProductChangeHistoryPage(
      items: items,
      totalCount: json['total_count'] as int? ?? items.length,
    );
  }

  static ProductChangeHistoryReadRow readRowFromJson(Map<String, dynamic> item) {
    final action = ProductChangeHistoryAction.tryParse(item['change_type'] as String?);
    final category = ProductChangeCategory.tryParse(item['change_category'] as String?) ??
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
      priceBandChange: isSensitiveMasked ? null : _priceBandChangeFromJson(item['price_band_change']),
    );
  }

  static ProductPriceBandHistoryChangeDto? _priceBandChangeFromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);

    final productUnitId = json['product_unit_id'];
    final unitName = json['unit_name'];
    final currency = json['currency'];
    final trigger = ProductPriceBandHistoryTrigger.tryParse(json['trigger'] as String?);
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

  static ProductPriceBandHistorySnapshotDto? _priceBandSnapshotFromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);

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
}

final class ProductChangeHistoryResultDto {
  const ProductChangeHistoryResultDto({
    required this.productId,
    required this.items,
    required this.totalCount,
  });

  final String productId;
  final List<ProductChangeHistoryEntryDto> items;
  final int totalCount;
}

