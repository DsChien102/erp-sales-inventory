import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

CostRunView _buildRun({required bool balanceOk, required int balanceDiff}) {
  return CostRunView(
    runId: 'run-1',
    code: 'GV-2611-01',
    kind: CostRunKind.periodClose,
    periodMonth: DateTime(2026, 11, 1),
    status: CostRunStatus.readyForReview,
    method: CostMethod.periodic,
    fromSequence: 1,
    cutOffSequence: 10,
    cutOffAt: DateTime(2026, 11, 12, 10, 0),
    createdAt: DateTime(2026, 11, 12, 10, 0),
    blockers: const [],
    productCount: 1,
    changedCount: 1,
    totals: CostTotals(
      closingValue: 880000,
      cogsValue: 750000,
      cogsAdjust: -20000,
      valueAdjust: -20000,
      balanceOk: balanceOk,
    ),
    alt: const CostAlt(
      method: CostMethod.moving,
      closingValue: 900000,
      cogsValue: 730000,
    ),
    lines: [
      CostRunLineView(
        productId: 'p1',
        name: 'Nobivac DHPPi',
        code: 'SP-01',
        uom: 'liều',
        oldOfficialUnitCost: 11250,
        newUnitCost: 11000,
        openingQty: 0,
        openingValue: 0,
        inboundQty: 150,
        inboundValue: 1650000,
        rebateValue: 0,
        saleQty: 70,
        saleValueRecorded: 750000,
        lossQty: 0,
        lossValueRecorded: 0,
        closingQty: 80,
        movingAvgEnd: 11250,
        periodicAvg: 11000,
        cogsTrueUp: -20000,
        lossTrueUp: 0,
        roundingAdjust: 0,
        closingValueAfter: 880000,
        lineAdjust: -20000,
        balanceDiff: balanceDiff,
      ),
    ],
  );
}

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required Size size,
    required CostRunView run,
  }) async {
    useInventoryTestSurface(size);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCostRunDetailSheet(context, run: run),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('CostRunDetailSheet', () {
    testWidgets('detail_sheet_balance_ok renders web table and Khớp badge',
        (tester) async {
      await openSheet(
        tester,
        size: const Size(1280, 800),
        run: _buildRun(balanceOk: true, balanceDiff: 0),
      );

      expect(find.text('Chi tiết tính'), findsOneWidget);
      expect(find.text('Nobivac DHPPi'), findsOneWidget);
      expect(find.text('BÌNH QUÂN LIÊN HOÀN'), findsOneWidget);
      expect(find.text('BÌNH QUÂN CUỐI KỲ'), findsOneWidget);
      expect(find.text('Kiểm cân bằng: Khớp'), findsOneWidget);
      expect(
        find.text(
          'Tồn đầu + Nhập − Chiết khấu NCC = Giá vốn xuất + Hao hụt + Tồn cuối',
        ),
        findsOneWidget,
      );
    });

    testWidgets('detail_sheet_balance_off renders mobile groups and Lệch badge',
        (tester) async {
      await openSheet(
        tester,
        size: const Size(390, 844),
        run: _buildRun(balanceOk: false, balanceDiff: -3),
      );

      expect(find.text('Nobivac DHPPi'), findsOneWidget);
      expect(find.text('Kiểm cân bằng: Lệch −3 đ'), findsOneWidget);
    });
  });
}

