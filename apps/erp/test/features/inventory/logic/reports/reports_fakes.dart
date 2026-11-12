import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';

StockReport sampleStockReport({bool masked = false}) => StockReport(
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 13),
      asOf: DateTime(2026, 11, 13, 10, 20),
      showAvailable: true,
      financialMasked: masked,
      rows: [
        StockReportRow(
          productId: 'p1',
          name: 'Vắc xin',
          code: 'VX',
          uom: 'hộp',
          openingQty: 122,
          inQty: 10,
          outQty: 12,
          closingQty: 120,
          available: 118,
          closingValue: masked ? null : 18026000,
        ),
      ],
      totalClosingValue: masked ? null : 18026000,
    );

StockCard sampleStockCard({String? lotId}) => StockCard(
      product: const StockCardProduct(
        productId: 'p1',
        name: 'Vắc xin',
        code: 'VX',
        uom: 'hộp',
        isLotTracked: true,
      ),
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 13),
      asOf: DateTime(2026, 11, 13, 10, 20),
      financialMasked: false,
      lots: const [
        StockCardLot(lotId: 'la', lotCode: 'A', closingQty: 9),
        StockCardLot(lotId: 'lb', lotCode: 'B', closingQty: 4),
      ],
      summary: const StockCardSummary(
        openingQty: 0,
        inQty: 19,
        outQty: 6,
        closingQty: 13,
      ),
      closingValue: lotId == null ? 1300000 : null,
      rows: const [],
    );

/// Repo giả: ghi lại tham số, ném lỗi nếu `error` đặt.
class FakeReportsRepository implements ReportsRepository {
  Object? error;
  final calls = <String>[];
  ReportPeriod? lastPeriod;
  String? lastSearch;
  String? lastLotId;

  void _record(String name, ReportPeriod p) {
    calls.add(name);
    lastPeriod = p;
    if (error != null) throw error!;
  }

  @override
  Future<StockReport> stockReport(ReportPeriod p, {String? search}) async {
    _record('stockReport', p);
    lastSearch = search;
    return sampleStockReport();
  }

  @override
  Future<StockCard> stockCard(
    String productId,
    ReportPeriod p, {
    String? lotId,
  }) async {
    _record('stockCard', p);
    lastLotId = lotId;
    return sampleStockCard(lotId: lotId);
  }

  @override
  Future<GrossProfitByProduct> grossProfitByProduct(ReportPeriod p) async {
    _record('grossProfitByProduct', p);
    return GrossProfitByProduct(
      from: p.from,
      to: p.to,
      asOf: DateTime(2026, 11, 13),
      rows: const [],
      lossVnd: 0,
      totals: const GrossProfitTotals(
        revenue: 0,
        deduction: 0,
        netRevenue: 0,
        cogsAtSale: 0,
        cogsAdjust: 0,
        rebate: 0,
        cogsAfter: 0,
        grossProfit: 0,
        loss: 0,
        profitAfterLoss: 0,
      ),
    );
  }

  @override
  Future<GrossProfitByOrder> grossProfitByOrder(ReportPeriod p) async {
    _record('grossProfitByOrder', p);
    return GrossProfitByOrder(
      from: p.from,
      to: p.to,
      asOf: DateTime(2026, 11, 13),
      rows: const [],
      totals: const GrossProfitOrderTotals(revenue: 0, cogs: 0, grossProfit: 0),
    );
  }

  @override
  Future<SupplierPurchaseReport> supplierPurchases(ReportPeriod p) async {
    _record('supplierPurchases', p);
    return SupplierPurchaseReport(
      from: p.from,
      to: p.to,
      asOf: DateTime(2026, 11, 13),
      suppliers: const [],
      totals: const SupplierPurchaseTotals(
        purchase: 0,
        freight: 0,
        tradeDiscount: 0,
        landed: 0,
        rebate: 0,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
