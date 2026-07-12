import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_entry_dto.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_application/src/product/queries/check_product_deletion_eligibility/product_deletion_issue_dto.dart';

final class ChangeProductSoftDeleteResult {
  const ChangeProductSoftDeleteResult({
    required this.productId,
    required this.businessStatus,
    required this.readinessSummary,
    required this.version,
    this.reason,
    this.issues = const [],
    this.historyEntry,
  });

  final String productId;
  final ProductBusinessStatus businessStatus;
  final ReadinessSummaryDto readinessSummary;
  final int version;
  final String? reason;
  final List<ProductDeletionIssueDto> issues;
  final ProductChangeHistoryEntryDto? historyEntry;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;
}
