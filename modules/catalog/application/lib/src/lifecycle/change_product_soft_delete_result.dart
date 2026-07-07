import 'package:vet45_catalog_domain/domain.dart';

import '../control_center/product_change_history_entry_dto.dart';
import '../readiness/readiness_summary_dto.dart';
import 'product_deletion_issue_dto.dart';

final class ChangeProductSoftDeleteResult {
  const ChangeProductSoftDeleteResult({
    required this.productId,
    required this.isSoftDeleted,
    required this.businessStatus,
    required this.readinessSummary,
    required this.version,
    this.reason,
    this.issues = const [],
    this.historyEntry,
  });

  final String productId;
  final bool isSoftDeleted;
  final ProductStatus businessStatus;
  final ReadinessSummaryDto readinessSummary;
  final int version;
  final String? reason;
  final List<ProductDeletionIssueDto> issues;
  final ProductChangeHistoryEntryDto? historyEntry;
}
