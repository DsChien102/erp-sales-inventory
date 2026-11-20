import 'actor_snapshot_dto.dart';
import 'money_dto.dart';

final class SalesOrderTimelineDto {
  SalesOrderTimelineDto({
    required this.salesOrderId,
    required List<SalesOrderTimelineEntryDto> entries,
  }) : entries = List.unmodifiable(entries);

  final String salesOrderId;
  final List<SalesOrderTimelineEntryDto> entries;
}

final class SalesOrderTimelineEntryDto {
  const SalesOrderTimelineEntryDto({
    required this.eventId,
    required this.eventType,
    required this.occurredAt,
    required this.sourceVersion,
    this.actor,
    this.description,
    this.amount,
  });

  final String eventId;
  final String eventType;
  final DateTime occurredAt;
  final int sourceVersion;
  final ActorSnapshotDto? actor;
  final String? description;
  final MoneyDto? amount;
}
