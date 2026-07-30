import 'product_list_item_dto.dart';

/// Paginated product search result (EPIC-01/US-01).
final class ProductSearchResultDto {
  const ProductSearchResultDto({
    required this.items,
    required this.totalCount,
    this.readyToSellCount,
    this.incompleteCount,
    this.inactiveCount,
  });

  final List<ProductListItemDto> items;
  final int totalCount;
  final int? readyToSellCount;
  final int? incompleteCount;
  final int? inactiveCount;
}
