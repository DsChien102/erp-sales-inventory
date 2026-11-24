import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';

class ReportsRepository {
  ReportsRepository({required InventoryRpc rpc}) : _rpc = rpc;

  final InventoryRpc _rpc;

  Map<String, dynamic> _range(ReportPeriod p) => {
        'p_from': reportIsoDate(p.from),
        'p_to': reportIsoDate(p.to),
      };

  Future<StockReport> stockReport(ReportPeriod p, {String? search}) async {
    final term = search?.trim();
    final res = await _rpc.query('get_stock_report', {
      ..._range(p),
      if (term != null && term.isNotEmpty) 'p_search': term,
    });
    return StockReport.fromJson(res);
  }

  Future<StockCard> stockCard(
    String productId,
    ReportPeriod p, {
    String? lotId,
  }) async {
    final res = await _rpc.query('get_stock_card', {
      'p_product_id': productId,
      ..._range(p),
      'p_lot_id': ?lotId,
    });
    return StockCard.fromJson(res);
  }

  Future<MovementDetail> movementDetail(String movementId) async {
    final res = await _rpc.query('get_movement_detail', {
      'p_movement_id': movementId,
    });
    return MovementDetail.fromJson(res);
  }

  Future<GrossProfitByProduct> grossProfitByProduct(ReportPeriod p) async {
    final res = await _rpc.query('get_gross_profit_report', {
      ..._range(p),
      'p_mode': 'PRODUCT',
    });
    return GrossProfitByProduct.fromJson(res);
  }

  Future<GrossProfitByOrder> grossProfitByOrder(ReportPeriod p) async {
    final res = await _rpc.query('get_gross_profit_report', {
      ..._range(p),
      'p_mode': 'ORDER',
    });
    return GrossProfitByOrder.fromJson(res);
  }

  Future<SupplierPurchaseReport> supplierPurchases(ReportPeriod p) async {
    final res = await _rpc.query('get_supplier_purchase_report', _range(p));
    return SupplierPurchaseReport.fromJson(res);
  }
}
