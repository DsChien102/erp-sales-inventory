import 'package:vet45_catalog_application/src/product_stock_profile/queries/get_product_stock_history/product_stock_movement_read_row.dart';

abstract interface class IProductStockReadPort {
  Future<List<ProductStockMovementReadRow>> listMovements({
    required String tenantId,
    required String productId,
    int limit = 50,
  });
}
