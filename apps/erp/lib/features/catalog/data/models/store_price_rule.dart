/// Store price rule and rule change history models (EPIC-06).
library;

double? _asDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

enum StorePriceCalculationType {
  markup,
}

enum StorePriceRuleStatus {
  active,
  inactive,
}

final class StorePriceRuleDto {
  const StorePriceRuleDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.status,
    required this.calculationType,
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
    this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String name;
  final StorePriceRuleStatus status;
  final StorePriceCalculationType calculationType;
  final double listMarkupRatio;
  final double floorMarkupRatio;
  final DateTime? updatedAt;

  bool get isActive => status == StorePriceRuleStatus.active;

  static StorePriceRuleDto? fromRow(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null || id.isEmpty) {
      return null;
    }
    return StorePriceRuleDto(
      id: id,
      tenantId: row['tenant_id'] as String,
      name: row['name'] as String,
      status: switch (row['status'] as String?) {
        'inactive' => StorePriceRuleStatus.inactive,
        _ => StorePriceRuleStatus.active,
      },
      calculationType: StorePriceCalculationType.markup,
      listMarkupRatio: (row['list_markup_ratio'] as num).toDouble(),
      floorMarkupRatio: (row['floor_markup_ratio'] as num).toDouble(),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }
}

/// Kết quả phân trang lịch sử Store Price Rule.
final class StorePriceRuleChangeHistoryResultDto {
  const StorePriceRuleChangeHistoryResultDto({
    required this.items,
    required this.totalCount,
  });

  final List<StorePriceRuleChangeHistoryEntryDto> items;
  final int totalCount;

  factory StorePriceRuleChangeHistoryResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => StorePriceRuleChangeHistoryEntryDto.fromJson(item.cast<String, dynamic>()))
            .toList(growable: false)
        : const <StorePriceRuleChangeHistoryEntryDto>[];

    return StorePriceRuleChangeHistoryResultDto(
      items: items,
      totalCount: json['total_count'] as int? ?? items.length,
    );
  }
}

/// Một dòng lịch sử thay đổi Store Price Rule (EPIC-06/US-02 extension).
final class StorePriceRuleChangeHistoryEntryDto {
  const StorePriceRuleChangeHistoryEntryDto({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.summary,
    this.listMarkupBefore,
    required this.listMarkupAfter,
    this.floorMarkupBefore,
    required this.floorMarkupAfter,
    this.isCurrent = false,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final String summary;
  final double? listMarkupBefore;
  final double listMarkupAfter;
  final double? floorMarkupBefore;
  final double floorMarkupAfter;
  final bool isCurrent;

  factory StorePriceRuleChangeHistoryEntryDto.fromJson(Map<String, dynamic> item) {
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
}

