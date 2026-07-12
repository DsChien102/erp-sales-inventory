import 'product_change_history_read_row.dart';

/// Paginated change history page from gateway.
final class ProductChangeHistoryPage {
  const ProductChangeHistoryPage({
    required this.items,
    required this.totalCount,
  });

  final List<ProductChangeHistoryReadRow> items;
  final int totalCount;
}
