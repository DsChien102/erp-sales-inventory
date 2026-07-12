import 'product_deletion_issue_severity.dart';

final class ProductDeletionIssueDto {
  const ProductDeletionIssueDto({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final ProductDeletionIssueSeverity severity;
}
