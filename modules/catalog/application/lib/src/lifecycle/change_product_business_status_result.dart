import 'package:vet45_catalog_domain/domain.dart';

import '../control_center/product_change_history_entry_dto.dart';
import '../readiness/readiness_summary_dto.dart';
import 'product_business_status_warning_dto.dart';

final class ChangeProductBusinessStatusResult {
  const ChangeProductBusinessStatusResult({
    required this.productId,
    required this.previousStatus,
    required this.currentStatus,
    required this.readinessSummary,
    required this.version,
    this.reason,
    this.warnings = const [],
    this.historyEntry,
  });

  final String productId;
  final ProductStatus previousStatus;
  final ProductStatus currentStatus;
  final ReadinessSummaryDto readinessSummary;
  final int version;
  final String? reason;
  final List<ProductBusinessStatusWarningDto> warnings;
  final ProductChangeHistoryEntryDto? historyEntry;
}
