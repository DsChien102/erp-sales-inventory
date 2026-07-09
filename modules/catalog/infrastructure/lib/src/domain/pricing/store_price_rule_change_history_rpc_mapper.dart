import 'package:vet45_catalog_application/application.dart';

abstract final class StorePriceRuleChangeHistoryRpcMapper {
  static Map<String, dynamic> params({
    required String tenantId,
    required int limit,
    required int offset,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_limit': limit,
      'p_offset': offset,
    };
  }

  static StorePriceRuleChangeHistoryResultDto resultFromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => entryFromJson(item.cast<String, dynamic>()),
              )
              .toList(growable: false)
        : const <StorePriceRuleChangeHistoryEntryDto>[];

    return StorePriceRuleChangeHistoryResultDto(
      items: items,
      totalCount: json['total_count'] as int? ?? items.length,
    );
  }

  static StorePriceRuleChangeHistoryEntryDto entryFromJson(
    Map<String, dynamic> item,
  ) {
    return StorePriceRuleChangeHistoryEntryDto(
      id: item['id'] as String,
      occurredAt: DateTime.parse(item['occurred_at'] as String),
      actorDisplayName: item['actor_display_name'] as String? ?? '',
      summary: item['summary'] as String? ?? '',
      listMarkupBefore: _asDouble(item['list_markup_before']),
      listMarkupAfter: _asDouble(item['list_markup_after']) ?? 0,
      floorMarkupBefore: _asDouble(item['floor_markup_before']),
      floorMarkupAfter: _asDouble(item['floor_markup_after']) ?? 0,
      isCurrent: item['is_current'] as bool? ?? false,
    );
  }

  static double? _asDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
