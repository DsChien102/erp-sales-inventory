import '../product_stock_movement_read_row.dart';

abstract interface class IProductStockReadPort {
  Future<List<ProductStockMovementReadRow>> listMovements({
    required String tenantId,
    required String productId,
    int limit = 50,
  });
}
