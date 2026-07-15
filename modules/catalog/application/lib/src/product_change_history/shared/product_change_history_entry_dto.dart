import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_category.dart';
import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_action.dart';
import 'package:vet45_catalog_application/src/product_change_history/shared/product_price_band_history_change_dto.dart';

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
    this.changeCategory,
    this.source = 'user',
    this.isSensitiveMasked = false,
    this.reason,
    this.priceBandChange,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final ProductChangeHistoryAction? changeType;
  final String summary;
  final String? valueBefore;
  final String? valueAfter;
  final ProductChangeCategory? changeCategory;
  final String source;
  final bool isSensitiveMasked;
  final String? reason;
  final ProductPriceBandHistoryChangeDto? priceBandChange;
}
