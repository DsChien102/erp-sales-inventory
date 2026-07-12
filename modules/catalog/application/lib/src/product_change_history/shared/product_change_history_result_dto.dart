import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_entry_dto.dart';

/// Full product change history list (EPIC-07/US-04).
final class ProductChangeHistoryResultDto {
  const ProductChangeHistoryResultDto({
    required this.productId,
    required this.items,
    required this.totalCount,
  });

  final String productId;
  final List<ProductChangeHistoryEntryDto> items;
  final int totalCount;
}
