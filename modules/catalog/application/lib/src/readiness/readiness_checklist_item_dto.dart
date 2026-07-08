import 'readiness_checklist_group.dart';
import 'readiness_checklist_item_status.dart';
import 'readiness_item_kind.dart';

final class ReadinessChecklistItemDto {
  const ReadinessChecklistItemDto({
    required this.group,
    required this.label,
    required this.status,
    required this.kind,
    this.blockerCode,
    this.description,
  });

  final ReadinessChecklistGroup group;
  final String label;
  final ReadinessChecklistItemStatus status;
  final ReadinessItemKind kind;
  final String? blockerCode;
  final String? description;
}
