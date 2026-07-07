import '../../control_center/product_change_history_entry_dto.dart';

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
