import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

/// Hôm nay cố định của mọi test báo cáo.
final reportsToday = DateTime(2026, 11, 13);

final _asOf = DateTime(2026, 11, 13, 10, 20);

StockReportRow stockRow({
  String id = 'p1',
  String name = 'Vắc xin Dại',
  String code = 'VX-01',
  String uom = 'hộp',
  num opening = 122,
  num inQty = 10,
  num outQty = 12,
  num closing = 120,
  num? available = 118,
  int? value = 18026000,
}) =>
    StockReportRow(
      productId: id,
      name: name,
      code: code,
      uom: uom,
      openingQty: opening,
      inQty: inQty,
      outQty: outQty,
      closingQty: closing,
      available: available,
      closingValue: value,
    );

StockReport stockReportOf(
  List<StockReportRow> rows, {
  bool masked = false,
  bool showAvailable = true,
}) =>
    StockReport(
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 13),
      asOf: _asOf,
      showAvailable: showAvailable,
      financialMasked: masked,
      rows: rows,
      totalClosingValue:
          masked ? null : rows.fold<int>(0, (a, r) => a + (r.closingValue ?? 0)),
    );

StockCardLine cardLine({
  String id = 'm1',
  DateTime? date,
  String kind = 'RECEIPT',
  String intent = 'GOODS_RECEIPT',
  String? reason,
  String doc = 'PN-260904-08',
  String? lot,
  num delta = 20,
  num balance = 48,
  String actor = 'Chủ cửa hàng',
}) =>
    StockCardLine(
      movementId: id,
      businessDate: date ?? DateTime(2026, 11, 2),
      recordedAt: DateTime(2026, 11, 2, 9, 30),
      movementKind: kind,
      reason: reason,
      intentType: intent,
      docCode: doc,
      lotCode: lot,
      quantityDelta: delta,
      balanceAfter: balance,
      actorName: actor,
    );

StockCard stockCardOf({
  bool lotTracked = true,
  bool masked = false,
  List<StockCardLine>? rows,
  int? closingValue = 1300000,
}) =>
    StockCard(
      product: StockCardProduct(
        productId: 'p1',
        name: 'Vắc xin Dại',
        code: 'VX-01',
        uom: 'hộp',
        isLotTracked: lotTracked,
      ),
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 13),
      asOf: _asOf,
      financialMasked: masked,
      lots: lotTracked
          ? const [
              StockCardLot(lotId: 'la', lotCode: 'A', closingQty: 9),
              StockCardLot(lotId: 'lb', lotCode: 'B', closingQty: 4),
            ]
          : const [],
      summary: const StockCardSummary(
        openingQty: 28,
        inQty: 20,
        outQty: 2,
        closingQty: 46,
      ),
      closingValue: masked ? null : closingValue,
      rows: rows ??
          [
            cardLine(lot: lotTracked ? 'A' : null),
            cardLine(
              id: 'm2',
              kind: 'SALE',
              intent: 'SALES_ORDER',
              doc: 'DH-0001',
              delta: -2,
              balance: 46,
              lot: lotTracked ? 'A' : null,
            ),
          ],
    );

/// Repo giả cho test màn: trả dữ liệu đặt sẵn, ghi lại tham số gọi.
class FakeReportsRepository extends Fake implements ReportsRepository {
  StockReport stockReportResult = stockReportOf([stockRow()]);
  StockCard stockCardResult = stockCardOf();
  MovementDetail? movementResult;
  GrossProfitByProduct? grossProductResult;
  GrossProfitByOrder? grossOrderResult;
  SupplierPurchaseReport? supplierResult;
  Object? error;

  final stockReportPeriods = <ReportPeriod>[];
  final stockReportSearches = <String?>[];
  final stockCardLots = <String?>[];
  final stockCardPeriods = <ReportPeriod>[];
  final movementIds = <String>[];
  final grossPeriods = <ReportPeriod>[];
  final supplierPeriods = <ReportPeriod>[];

  /// Lọc theo tên khi có `search` (giả lập server).
  bool filterBySearch = true;

  void _maybeThrow() {
    if (error != null) throw error!;
  }

  @override
  Future<StockReport> stockReport(ReportPeriod p, {String? search}) async {
    stockReportPeriods.add(p);
    stockReportSearches.add(search);
    _maybeThrow();
    final term = (search ?? '').trim().toLowerCase();
    if (!filterBySearch || term.isEmpty) return stockReportResult;
    final rows = stockReportResult.rows
        .where((r) => r.name.toLowerCase().contains(term))
        .toList();
    return StockReport(
      from: stockReportResult.from,
      to: stockReportResult.to,
      asOf: stockReportResult.asOf,
      showAvailable: stockReportResult.showAvailable,
      financialMasked: stockReportResult.financialMasked,
      rows: rows,
      totalClosingValue: stockReportResult.totalClosingValue,
    );
  }

  @override
  Future<StockCard> stockCard(
    String productId,
    ReportPeriod p, {
    String? lotId,
  }) async {
    stockCardPeriods.add(p);
    stockCardLots.add(lotId);
    _maybeThrow();
    return stockCardResult;
  }

  @override
  Future<MovementDetail> movementDetail(String movementId) async {
    movementIds.add(movementId);
    _maybeThrow();
    return movementResult!;
  }

  @override
  Future<GrossProfitByProduct> grossProfitByProduct(ReportPeriod p) async {
    grossPeriods.add(p);
    _maybeThrow();
    return grossProductResult!;
  }

  @override
  Future<GrossProfitByOrder> grossProfitByOrder(ReportPeriod p) async {
    grossPeriods.add(p);
    _maybeThrow();
    return grossOrderResult!;
  }

  @override
  Future<SupplierPurchaseReport> supplierPurchases(ReportPeriod p) async {
    supplierPeriods.add(p);
    _maybeThrow();
    return supplierResult!;
  }
}

/// Dựng một màn trong `MaterialApp` có theme thật và mặt vẽ đúng cỡ.
Widget reportsApp(Widget home, {Size size = const Size(390, 844)}) {
  useInventoryTestSurface(size);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: VTheme.lightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: size),
      child: child!,
    ),
    home: home,
  );
}

/// Có chuỗi tiền ("… đ" ngay sau chữ số) nào trên cây widget không.
Finder findMoneyText() {
  final money = RegExp(r'\d[\s ]*đ');
  return find.byWidgetPredicate(
    (w) => w is RichText && money.hasMatch(w.text.toPlainText()),
  );
}

MovementDetail movementDetailOf({
  String kind = 'RECEIPT',
  String intent = 'GOODS_RECEIPT',
  String? reason,
  num delta = 20,
  num before = 28,
  int? value = 840000,
  String? lot,
  bool lotTracked = false,
  MovementSource? source,
}) =>
    MovementDetail(
      movementId: 'm1',
      product: StockCardProduct(
        productId: 'p1',
        name: 'Vắc xin Dại',
        code: 'VX-01',
        uom: 'hộp',
        isLotTracked: lotTracked,
      ),
      lotCode: lot,
      movementKind: kind,
      reason: reason,
      intentType: intent,
      quantityDelta: delta,
      beforeQty: before,
      afterQty: before + delta,
      businessDate: DateTime(2026, 9, 4),
      recordedAt: DateTime(2026, 9, 4, 8, 15),
      actorName: 'Chủ cửa hàng',
      valueAmount: value,
      source: source ??
          const MovementSource(
            kind: 'RECEIPT',
            docCode: 'PN-260904-08',
            receiptId: 'r1',
          ),
    );

GrossProfitRow grossRow({
  String id = 'p1',
  String name = 'Amoxicillin 500mg',
}) =>
    GrossProfitRow(
      productId: id,
      name: name,
      code: 'AM-500',
      uom: 'hộp',
      revenueVnd: 6000000,
      deductionVnd: 800000,
      netRevenueVnd: 5200000,
      cogsAtSaleVnd: 6860000,
      cogsAdjustVnd: 20000,
      rebateVnd: 3500000,
      cogsAfterVnd: 3380000,
      grossProfitVnd: 1820000,
      marginPct: 35.0,
    );

GrossProfitByProduct grossProductOf({List<GrossProfitRow>? rows, int loss = 150000}) {
  final list = rows ?? [grossRow()];
  return GrossProfitByProduct(
    from: DateTime(2026, 11, 1),
    to: DateTime(2026, 11, 13),
    asOf: _asOf,
    rows: list,
    lossVnd: loss,
    totals: GrossProfitTotals(
      revenue: 6000000,
      deduction: 800000,
      netRevenue: 5200000,
      cogsAtSale: 6860000,
      cogsAdjust: 20000,
      rebate: 3500000,
      cogsAfter: 3380000,
      grossProfit: 1820000,
      marginPct: 35.0,
      loss: loss,
      profitAfterLoss: 1820000 - loss,
    ),
  );
}

GrossProfitByOrder grossOrderOf({List<GrossProfitOrderRow>? rows}) {
  final list = rows ??
      [
        GrossProfitOrderRow(
          orderId: 'o1',
          orderCode: 'DH-0001',
          completedOn: DateTime(2026, 11, 2),
          revenueVnd: 300000,
          cogsVnd: 200000,
          grossProfitVnd: 100000,
          marginPct: 33.3,
          hasProvisional: true,
        ),
        GrossProfitOrderRow(
          orderId: 'o2',
          orderCode: 'DH-0002',
          completedOn: DateTime(2026, 11, 1),
          revenueVnd: 160000,
          cogsVnd: 100000,
          grossProfitVnd: 60000,
          marginPct: 37.5,
          hasProvisional: false,
        ),
      ];
  return GrossProfitByOrder(
    from: DateTime(2026, 11, 1),
    to: DateTime(2026, 11, 13),
    asOf: _asOf,
    rows: list,
    totals: const GrossProfitOrderTotals(
      revenue: 460000,
      cogs: 300000,
      grossProfit: 160000,
      marginPct: 34.8,
    ),
  );
}

SupplierPurchaseReport supplierReportOf({bool empty = false}) =>
    SupplierPurchaseReport(
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 13),
      asOf: _asOf,
      suppliers: empty
          ? const []
          : const [
              SupplierPurchaseRow(
                supplierId: 's1',
                name: 'Cty Thú y A',
                isSystem: false,
                receiptCount: 3,
                purchaseVnd: 30000000,
                freightVnd: 100000,
                tradeDiscountVnd: 20000,
                landedVnd: 30080000,
                rebateVnd: 500000,
                products: [
                  SupplierPurchaseProduct(
                    productId: 'p1',
                    name: 'Nobivac DHPPi',
                    code: 'NB-01',
                    uom: 'hộp',
                    paidQty: 10,
                    freeQty: 1,
                    purchaseVnd: 1000000,
                    landedVnd: 1030000,
                    avgLandedUnitCost: 93636.3636,
                  ),
                ],
              ),
              SupplierPurchaseRow(
                supplierId: 's2',
                name: 'Mua lẻ / khác',
                isSystem: true,
                receiptCount: 1,
                purchaseVnd: 15000000,
                freightVnd: 0,
                tradeDiscountVnd: 0,
                landedVnd: 15120000,
                rebateVnd: 0,
                products: [],
              ),
            ],
      totals: const SupplierPurchaseTotals(
        purchase: 45000000,
        freight: 100000,
        tradeDiscount: 20000,
        landed: 45200000,
        rebate: 500000,
      ),
    );
