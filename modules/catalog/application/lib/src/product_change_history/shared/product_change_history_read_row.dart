import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_entry_dto.dart';
import 'product_change_category.dart';
import 'product_change_history_action.dart';

/// Gateway read row before mapping to [ProductChangeHistoryEntryDto].
final class ProductChangeHistoryReadRow {
  const ProductChangeHistoryReadRow({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.changeType,
    required this.summary,
    required this.changeCategory,
    required this.source,
    required this.isSensitiveMasked,
    this.valueBefore,
    this.valueAfter,
    this.reason,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final ProductChangeHistoryAction? changeType;
  final String summary;
  final ProductChangeCategory changeCategory;
  final String source;
  final bool isSensitiveMasked;
  final String? valueBefore;
  final String? valueAfter;
  final String? reason;

  ProductChangeHistoryEntryDto toDto() => ProductChangeHistoryEntryDto(
    id: id,
    occurredAt: occurredAt,
    actorDisplayName: actorDisplayName,
    changeType: changeType,
    summary: summary,
    valueBefore: valueBefore,
    valueAfter: valueAfter,
    changeCategory: changeCategory,
    source: source,
    isSensitiveMasked: isSensitiveMasked,
    reason: reason,
  );
}
