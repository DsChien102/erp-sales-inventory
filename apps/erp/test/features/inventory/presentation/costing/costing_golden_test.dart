import 'dart:io';

import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/presentation/costing/cost_overview_page.dart';
import 'package:erp/features/inventory/presentation/costing/cost_result_page.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

String _goldenPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-6/$fileName';
}

class _GoldenCostingRepository extends Fake implements CostingRepository {
  static final _readyRunRow = CostRunRow(
    runId: 'run-ready',
    code: 'GV-2611-02',
    kind: CostRunKind.midPeriod,
    periodMonth: DateTime(2026, 11, 1),
    status: CostRunStatus.readyForReview,
    productCount: 4,
    blockerCount: 0,
    valueAdjustVnd: 20000,
    publishedAt: null,
    createdAt: DateTime(2026, 11, 12, 10, 0),
  );

  static final _blockedRunRow = CostRunRow(
    runId: 'run-blocked',
    code: 'GV-2611-01',
    kind: CostRunKind.periodClose,
    periodMonth: DateTime(2026, 10, 1),
    status: CostRunStatus.blocked,
    productCount: 4,
    blockerCount: 2,
    valueAdjustVnd: null,
    publishedAt: null,
    createdAt: DateTime(2026, 11, 1, 9, 0),
  );

  static final _publishedRunRow = CostRunRow(
    runId: 'run-pub',
    code: 'GV-2610-01',
    kind: CostRunKind.periodClose,
    periodMonth: DateTime(2026, 9, 1),
    status: CostRunStatus.published,
    productCount: 4,
    blockerCount: 0,
    valueAdjustVnd: -15000,
    publishedAt: DateTime(2026, 10, 2, 8, 30),
    createdAt: DateTime(2026, 10, 2, 8, 0),
  );

  static const _lines = [
    CostRunLineView(
      productId: 'p1',
      name: 'Amox 500',
      code: 'SP-01',
      uom: 'hộp',
      oldOfficialUnitCost: null,
      newUnitCost: 11000,
      openingQty: 0,
      openingValue: 0,
      inboundQty: 100,
      inboundValue: 1100000,
      rebateValue: 0,
      saleQty: 40,
      saleValueRecorded: 420000,
      lossQty: 0,
      lossValueRecorded: 0,
      closingQty: 60,
      movingAvgEnd: 11000,
      periodicAvg: 11000,
      cogsTrueUp: 20000,
      lossTrueUp: 0,
      roundingAdjust: 0,
      closingValueAfter: 660000,
      lineAdjust: 20000,
      balanceDiff: 0,
    ),
    CostRunLineView(
      productId: 'p2',
      name: 'Nobivac DHPPi',
      code: 'NBV-01',
      uom: 'liều',
      oldOfficialUnitCost: 95000,
      newUnitCost: 95000,
      openingQty: 20,
      openingValue: 1900000,
      inboundQty: 0,
      inboundValue: 0,
      rebateValue: 0,
      saleQty: 10,
      saleValueRecorded: 950000,
      lossQty: 0,
      lossValueRecorded: 0,
      closingQty: 10,
      movingAvgEnd: 95000,
      periodicAvg: 95000,
      cogsTrueUp: 0,
      lossTrueUp: 0,
      roundingAdjust: 0,
      closingValueAfter: 950000,
      lineAdjust: 0,
      balanceDiff: 0,
    ),
  ];

  late final Map<String, CostRunView> _runs = {
    'run-ready': CostRunView(
      runId: 'run-ready',
      code: 'GV-2611-02',
      kind: CostRunKind.midPeriod,
      periodMonth: DateTime(2026, 11, 1),
      status: CostRunStatus.readyForReview,
      method: CostMethod.periodic,
      fromSequence: 1,
      cutOffSequence: 25,
      cutOffAt: DateTime(2026, 11, 12, 10, 0),
      createdAt: DateTime(2026, 11, 12, 10, 0),
      blockers: const [],
      productCount: 2,
      changedCount: 1,
      totals: const CostTotals(
        closingValue: 1610000,
        cogsValue: 1390000,
        cogsAdjust: 20000,
        valueAdjust: -20000,
        balanceOk: true,
      ),
      alt: const CostAlt(
        method: CostMethod.moving,
        closingValue: 1620000,
        cogsValue: 1380000,
      ),
      lines: _lines,
    ),
    'run-blocked': CostRunView(
      runId: 'run-blocked',
      code: 'GV-2611-01',
      kind: CostRunKind.periodClose,
      periodMonth: DateTime(2026, 10, 1),
      status: CostRunStatus.blocked,
      method: CostMethod.periodic,
      fromSequence: 1,
      cutOffSequence: 20,
      cutOffAt: DateTime(2026, 11, 1, 9, 0),
      createdAt: DateTime(2026, 11, 1, 9, 0),
      blockers: [
        CostBlocker(code: 'PREVIOUS_PERIOD_OPEN', periodMonth: DateTime(2026, 9, 1)),
        const CostBlocker(code: 'STOCKTAKE_OPEN'),
      ],
      productCount: 2,
      changedCount: 0,
      totals: const CostTotals(
        closingValue: 0,
        cogsValue: 0,
        cogsAdjust: 0,
        valueAdjust: 0,
        balanceOk: true,
      ),
      alt: const CostAlt(
        method: CostMethod.moving,
        closingValue: 0,
        cogsValue: 0,
      ),
      lines: const [],
    ),
    'run-pub': CostRunView(
      runId: 'run-pub',
      code: 'GV-2610-01',
      kind: CostRunKind.periodClose,
      periodMonth: DateTime(2026, 9, 1),
      status: CostRunStatus.published,
      method: CostMethod.periodic,
      fromSequence: 1,
      cutOffSequence: 15,
      cutOffAt: DateTime(2026, 10, 2, 8, 0),
      createdAt: DateTime(2026, 10, 2, 8, 0),
      publishedAt: DateTime(2026, 10, 2, 8, 30),
      blockers: const [],
      productCount: 4,
      changedCount: 2,
      totals: const CostTotals(
        closingValue: 880000,
        cogsValue: 750000,
        cogsAdjust: 15000,
        valueAdjust: -15000,
        balanceOk: true,
      ),
      alt: const CostAlt(
        method: CostMethod.moving,
        closingValue: 895000,
        cogsValue: 735000,
      ),
      lines: _lines,
    ),
  };

  @override
  Future<CostOverview> overview() async {
    return CostOverview(
      method: CostMethod.periodic,
      methodLocked: false,
      openPeriod: DateTime(2026, 11, 1),
      periodToClose: DateTime(2026, 10, 1),
      hasPendingRun: false,
      runs: [_readyRunRow, _blockedRunRow, _publishedRunRow],
    );
  }

  @override
  Future<CostRunView> getRun(String runId) async => _runs[runId]!;
}

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<CostingRepository>(_GoldenCostingRepository());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required Widget page,
    required String fileName,
  }) async {
    useInventoryTestSurface(size);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: child!,
        ),
        home: RepaintBoundary(key: key, child: page),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile(_goldenPath(fileName)),
    );
  }

  group('Costing Golden Screenshots (G5-6 Task 9)', () {
    testWidgets('072_READY_390_and_1280', (tester) async {
      await capture(
        tester,
        size: const Size(390, 844),
        page: const CostOverviewPage(),
        fileName: 'flutter-072-READY-390.png',
      );
      await capture(
        tester,
        size: const Size(1280, 800),
        page: const CostOverviewPage(),
        fileName: 'flutter-072-READY-1280.png',
      );
    });

    testWidgets('074_READY_FOR_REVIEW_390_and_1280', (tester) async {
      await capture(
        tester,
        size: const Size(390, 844),
        page: const CostRunPage(runId: 'run-ready', kind: CostRunKind.midPeriod),
        fileName: 'flutter-074-READY_FOR_REVIEW-390.png',
      );
      await capture(
        tester,
        size: const Size(1280, 800),
        page: const CostRunPage(runId: 'run-ready', kind: CostRunKind.midPeriod),
        fileName: 'flutter-074-READY_FOR_REVIEW-1280.png',
      );
    });

    testWidgets('074_BLOCKED_390_and_1280', (tester) async {
      await capture(
        tester,
        size: const Size(390, 844),
        page: const CostRunPage(
          runId: 'run-blocked',
          kind: CostRunKind.periodClose,
        ),
        fileName: 'flutter-074-BLOCKED-390.png',
      );
      await capture(
        tester,
        size: const Size(1280, 800),
        page: const CostRunPage(
          runId: 'run-blocked',
          kind: CostRunKind.periodClose,
        ),
        fileName: 'flutter-074-BLOCKED-1280.png',
      );
    });

    testWidgets('077_COMPLETED_390_and_1280', (tester) async {
      await capture(
        tester,
        size: const Size(390, 844),
        page: const CostResultPage(runId: 'run-pub'),
        fileName: 'flutter-077-COMPLETED-390.png',
      );
      await capture(
        tester,
        size: const Size(1280, 800),
        page: const CostResultPage(runId: 'run-pub'),
        fileName: 'flutter-077-COMPLETED-1280.png',
      );
    });
  });
}

