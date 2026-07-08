import 'product_deletion_issue_dto.dart';
import 'product_deletion_issue_severity.dart';

final class ProductDeletionEligibilityDto {
  const ProductDeletionEligibilityDto({
    required this.productId,
    required this.canDelete,
    this.issues = const [],
    this.suggestedActionId,
  });

  final String productId;
  final bool canDelete;
  final List<ProductDeletionIssueDto> issues;
  final String? suggestedActionId;

  List<ProductDeletionIssueDto> get blockers => issues
      .where((issue) => issue.severity == ProductDeletionIssueSeverity.blocker)
      .toList(growable: false);

  List<ProductDeletionIssueDto> get warnings => issues
      .where((issue) => issue.severity == ProductDeletionIssueSeverity.warning)
      .toList(growable: false);
}
