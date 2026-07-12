import 'product_stock_movement_dto.dart';

final class ProductStockHistoryDto {
  const ProductStockHistoryDto({
    required this.productId,
    this.unitName,
    this.isHistoricalBasicOnly = true,
    this.movements = const [],
  });

  final String productId;
  final String? unitName;
  final bool isHistoricalBasicOnly;
  final List<ProductStockMovementDto> movements;
}
