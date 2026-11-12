import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/presentation/costing/costing_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FlowFakeCostingRepository extends Fake implements CostingRepository {
  final List<CostRunRow> _runs = [];
  CostRunView? _currentRun;

  CostRunView _buildRun({required CostRunStatus status}) {
    return CostRunView(
      runId: 'run-flow-1',
      code: 'GV-2611-01',
      kind: CostRunKind.midPeriod,
      periodMonth: DateTime(2026, 11, 1),
      status: status,
      method: CostMethod.periodic,
      fromSequence: 1,
      cutOffSequence: 15,
      cutOffAt: DateTime(2026, 11, 12, 15, 0),
      createdAt: DateTime(2026, 11, 12, 15, 0),
      publishedAt: status == CostRunStatus.published
          ? DateTime(2026, 11, 12, 15, 1)
          : null,
      blockers: const [],
      productCount: 2,
      changedCount: 1,
      totals: const CostTotals(
        closingValue: 880000,
        cogsValue: 750000,
        cogsAdjust: 15000,
        valueAdjust: 20000,
        balanceOk: true,
      ),
      alt: const CostAlt(
        method: CostMethod.moving,
        closingValue: 890000,
        cogsValue: 740000,
      ),
      lines: const [
        CostRunLineView(
          productId: 'p1',
          name: 'Amox 500',
          code: 'SP-01',
          uom: 'hộp',
          oldOfficialUnitCost: 10000,
          newUnitCost: 11000,
          openingQty: 10,
          openingValue: 100000,
          inboundQty: 10,
          inboundValue: 120000,
          rebateValue: 0,
          saleQty: 5,
          saleValueRecorded: 50000,
          lossQty: 0,
          lossValueRecorded: 0,
          closingQty: 15,
          movingAvgEnd: 11000,
          periodicAvg: 11000,
          cogsTrueUp: 15000,
          lossTrueUp: 0,
          roundingAdjust: 0,
          closingValueAfter: 165000,
          lineAdjust: 15000,
          balanceDiff: 0,
        ),
      ],
    );
  }

  @override
  Future<CostOverview> overview() async {
    return CostOverview(
      method: CostMethod.periodic,
      methodLocked: false,
      openPeriod: DateTime(2026, 11, 1),
      periodToClose: null,
      hasPendingRun: _runs.any((r) => r.status != CostRunStatus.published),
      runs: List<CostRunRow>.unmodifiable(_runs),
    );
  }

  @override
  Future<CostRunView> createRun({
    required String idempotencyKey,
    required CostRunKind kind,
  }) async {
    final run = _buildRun(status: CostRunStatus.readyForReview);
    _currentRun = run;
    _runs
      ..clear()
      ..add(
        CostRunRow(
          runId: run.runId,
          code: run.code,
          kind: run.kind,
          periodMonth: run.periodMonth,
          status: run.status,
          productCount: run.productCount,
          blockerCount: 0,
          valueAdjustVnd: run.totals.valueAdjust,
          createdAt: run.createdAt,
        ),
      );
    return run;
  }

  @override
  Future<CostRunView> getRun(String runId) async => _currentRun!;

  @override
  Future<CostRunView> publish({
    required String idempotencyKey,
    required String runId,
  }) async {
    final run = _buildRun(status: CostRunStatus.published);
    _currentRun = run;
    _runs
      ..clear()
      ..add(
        CostRunRow(
          runId: run.runId,
          code: run.code,
          kind: run.kind,
          periodMonth: run.periodMonth,
          status: CostRunStatus.published,
          productCount: run.productCount,
          blockerCount: 0,
          valueAdjustVnd: run.totals.valueAdjust,
          publishedAt: run.publishedAt,
          createdAt: run.createdAt,
        ),
      );
    return run;
  }
}

void main() {
  testWidgets('costing_flow_mid_period runs 072 -> 074 -> publish -> 077 -> 072',
      (tester) async {
    useInventoryTestSurface(const Size(390, 844));
    final repo = _FlowFakeCostingRepository();

    final router = GoRouter(
      initialLocation: '/warehouse/costing',
      routes: [
        GoRoute(
          path: '/warehouse',
          builder: (_, _) => const Scaffold(body: Text('Hub')),
        ),
        ...costingRoutes(repository: repo),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // 072 rỗng
    expect(find.text('Không có công việc giá vốn'), findsOneWidget);

    // => "Cập nhật giữa kỳ" => 074 draft
    await tester.tap(find.text('Cập nhật giữa kỳ'));
    await tester.pumpAndSettle();
    expect(find.text('Tính giá vốn'), findsOneWidget);

    // => "Tính giá vốn" => 074 READY
    await tester.tap(find.text('Tính giá vốn'));
    await tester.pumpAndSettle();
    expect(find.text('Công bố giá vốn'), findsOneWidget);

    // => sheet => "Công bố giá vốn" => 077
    await tester.tap(find.text('Công bố giá vốn'));
    await tester.pumpAndSettle();
    expect(find.text('Công bố giá vốn?'), findsOneWidget);
    await tester.tap(find.text('Công bố giá vốn').last);
    await tester.pumpAndSettle();

    expect(find.text('Đã công bố giá vốn 11/2026'), findsOneWidget);

    // => "Về giá vốn" => 072 => chip "Đã công bố"
    await tester.ensureVisible(find.text('Về giá vốn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Về giá vốn'));
    await tester.pumpAndSettle();

    expect(find.text('Đã công bố'), findsOneWidget);
    await tester.tap(find.text('Đã công bố'));
    await tester.pumpAndSettle();

    expect(find.text('Cập nhật giá vốn 11/2026'), findsOneWidget);
  });
}

