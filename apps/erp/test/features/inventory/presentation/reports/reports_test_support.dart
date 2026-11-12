import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

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
