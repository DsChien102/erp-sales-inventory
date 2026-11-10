import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';

class StockRepository {
  final InventoryRpc _rpc;

  StockRepository({required InventoryRpc rpc}) : _rpc = rpc;

  /// Đọc tổng quan danh sách tồn kho (SCR-001).
  Future<StockOverview> loadOverview() async {
    final res = await _rpc.query('list_stock_overview');
    return StockOverview.fromJson(res);
  }

  /// Đọc chi tiết tồn kho một sản phẩm (SCR-003).
  Future<StockDetail> loadDetail(String productId) async {
    final res = await _rpc.query(
      'get_stock_detail',
      {'p_product_id': productId},
    );
    return StockDetail.fromJson(res);
  }
}

