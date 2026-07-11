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

    return ProductChangeHistoryReadRow(
      id: item['id'] as String,
      occurredAt: DateTime.parse(item['occurred_at'] as String),
      actorDisplayName: item['actor_display_name'] as String? ?? '',
      changeType: action,
      summary: item['summary'] as String? ?? '',
      changeCategory: category,
      source: item['source'] as String? ?? 'user',
      isSensitiveMasked: item['is_sensitive_masked'] as bool? ?? false,
      valueBefore: item['value_before'] as String?,
      valueAfter: item['value_after'] as String?,
      reason: item['reason'] as String?,
    );
  }
}
