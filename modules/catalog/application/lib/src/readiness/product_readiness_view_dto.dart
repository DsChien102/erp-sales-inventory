import 'contextual_action_dto.dart';
import 'readiness_checklist_item_dto.dart';
import 'readiness_summary_dto.dart';

/// Readiness view for post-create result screen and refresh (EPIC-02/US-03).
final class ProductReadinessViewDto {
  const ProductReadinessViewDto({
    required this.productId,
    required this.productName,
    required this.readinessSummary,
    this.checklist = const [],
    this.suggestedActions = const [],
    this.primaryActionId,
  });

  final String productId;
  final String productName;
  final ReadinessSummaryDto readinessSummary;
  final List<ReadinessChecklistItemDto> checklist;
  final List<ContextualActionDto> suggestedActions;
  final String? primaryActionId;
}
