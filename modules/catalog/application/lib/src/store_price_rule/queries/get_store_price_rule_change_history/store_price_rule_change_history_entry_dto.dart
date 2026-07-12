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
}
