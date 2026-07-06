/// Change history preview row on Product Control Center (EPIC-01/US-02/FR-06).
final class ProductChangeHistoryEntryDto {
  const ProductChangeHistoryEntryDto({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.changeType,
    required this.summary,
    this.valueBefore,
    this.valueAfter,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final String changeType;
  final String summary;
  final String? valueBefore;
  final String? valueAfter;
}
