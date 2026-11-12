import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeCostingRepository extends Fake implements CostingRepository {
  CostRunView? getRunResult;
  CostRunView? createRunResult;
  CostRunView? publishResult;
  Object? getRunError;
  Object? createRunError;
  Object? publishError;
  Future<CostRunView> Function(CostRunKind kind)? onCreateRun;
  int createRunCalls = 0;
  int publishCalls = 0;
  int discardCalls = 0;

  @override
  Future<CostRunView> getRun(String runId) async {
    if (getRunError != null) throw getRunError!;
    return getRunResult!;
  }

  @override
  Future<CostRunView> createRun({
    required String idempotencyKey,
    required CostRunKind kind,
  }) async {
    createRunCalls++;
    if (onCreateRun != null) return onCreateRun!(kind);
    if (createRunError != null) throw createRunError!;
    return createRunResult!;
  }

  @override
  Future<CostRunView> publish({
    required String idempotencyKey,
    required String runId,
  }) async {
    publishCalls++;
    if (publishError != null) throw publishError!;
    return publishResult!;
  }

  @override
  Future<void> discard({
    required String idempotencyKey,
    required String runId,
  }) async {
    discardCalls++;
  }
}

CostRunLineView _line({
  required String id,
  required String name,
  required String code,
  num? oldCost = 10000,
  num? newCost = 11000,
  int lineAdjust = 20000,
}) {
  return CostRunLineView(
    productId: id,
    name: name,
    code: code,
    uom: 'hộp',
    oldOfficialUnitCost: oldCost,
    newUnitCost: newCost,
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
    cogsTrueUp: lineAdjust > 0 ? 5000 : 0,
    lossTrueUp: 0,
    roundingAdjust: 0,
    closingValueAfter: 165000,
    lineAdjust: lineAdjust,
    balanceDiff: 0,
  );
}

CostRunView _run({
  String runId = 'run-1',
  CostRunStatus status = CostRunStatus.readyForReview,
  CostRunKind kind = CostRunKind.midPeriod,
  List<CostBlocker> blockers = const [],
  List<CostRunLineView>? lines,
}) {
  final effectiveLines = lines ??
      [
        _line(id: 'p1', name: 'Amox 500', code: 'SP-01', oldCost: null, newCost: 11000, lineAdjust: 20000),
        _line(id: 'p2', name: 'Cefixim', code: 'SP-02', oldCost: 10000, newCost: 10000, lineAdjust: 0),
        _line(id: 'p3', name: 'Doxy', code: 'SP-03', oldCost: 12000, newCost: 13000, lineAdjust: 10000),
        _line(id: 'p4', name: 'Genta', code: 'SP-04', oldCost: 15000, newCost: 14000, lineAdjust: -5000),
        _line(id: 'p5', name: 'Tylo', code: 'SP-05', oldCost: 20000, newCost: 20000, lineAdjust: 0),
      ];
  return CostRunView(
    runId: runId,
    code: 'GV-2611-01',
    kind: kind,
    periodMonth: DateTime(2026, 11, 1),
    status: status,
    method: CostMethod.periodic,
    fromSequence: 1,
    cutOffSequence: 25,
    cutOffAt: DateTime(2026, 11, 12, 14, 30),
    createdAt: DateTime(2026, 11, 12, 14, 30),
    blockers: blockers,
    productCount: effectiveLines.length,
    changedCount: 3,
    totals: const CostTotals(
      closingValue: 880000,
      cogsValue: 750000,
      cogsAdjust: 15000,
      valueAdjust: 25000,
      balanceOk: true,
    ),
    alt: const CostAlt(
      method: CostMethod.moving,
      closingValue: 890000,
      cogsValue: 740000,
    ),
    lines: effectiveLines,
  );
}

void main() {
  late _FakeCostingRepository repository;

  setUp(() async {
    await GetIt.I.reset();
    repository = _FakeCostingRepository()..getRunResult = _run();
    GetIt.I.registerSingleton<CostingRepository>(repository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildApp({
    Size size = const Size(390, 844),
    String? runId,
    CostRunKind kind = CostRunKind.midPeriod,
    DateTime? initialPeriod,
    ValueChanged<String>? onNavigate,
    VoidCallback? onBack,
  }) {
    useInventoryTestSurface(size);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
      home: CostRunPage(
        runId: runId,
        kind: kind,
        initialPeriod: initialPeriod ?? DateTime(2026, 11, 1),
        onNavigate: onNavigate,
        onBack: onBack,
      ),
    );
  }

  group('CostRunPage', () {
    testWidgets('draft_mid_shows_period_scope_method', (tester) async {
      await tester.pumpWidget(buildApp(runId: null, kind: CostRunKind.midPeriod));
      await tester.pumpAndSettle();

      expect(find.text('Cập nhật giá vốn 11/2026'), findsOneWidget);
      expect(find.text('11/2026'), findsOneWidget);
      expect(find.text('Toàn bộ sản phẩm'), findsOneWidget);
      expect(find.text('Phương pháp'), findsOneWidget);
      expect(find.text('Tính giá vốn'), findsOneWidget);
    });

    testWidgets('calculating_shows_note while awaiting createRun', (tester) async {
      repository.onCreateRun = (_) => Future<CostRunView>.delayed(
            const Duration(milliseconds: 500),
            () => _run(),
          );
      await tester.pumpWidget(buildApp(runId: null, onNavigate: (_) {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tính giá vốn'));
      await tester.pump();

      expect(
        find.text(
          'Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('ready_390 renders cards, writes, 3 mobile rows, compare, footer',
        (tester) async {
      await tester.pumpWidget(buildApp(runId: 'run-1', size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.text('Giá trị tồn cuối'), findsOneWidget);
      expect(find.text('880.000 đ'), findsOneWidget);
      expect(find.text('Giá vốn xuất'), findsOneWidget);
      expect(find.text('750.000 đ'), findsOneWidget);
      expect(find.text('+15.000 đ'), findsOneWidget);
      expect(find.text('+25.000 đ'), findsOneWidget);
      expect(find.text('Amox 500'), findsOneWidget);
      expect(find.text('Doxy'), findsOneWidget);
      expect(find.text('Genta'), findsOneWidget);
      expect(find.text('Xem 5 sản phẩm'), findsOneWidget);
      expect(find.text('Xem đối chiếu theo Bình quân liên hoàn'), findsOneWidget);
      expect(find.text('Bỏ lần tính'), findsOneWidget);
      expect(find.text('Công bố giá vốn'), findsOneWidget);
    });

    testWidgets('ready_1280 renders K7Split summary and table with Giá tạm',
        (tester) async {
      await tester.pumpWidget(buildApp(runId: 'run-1', size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Tóm tắt'), findsOneWidget);
      expect(find.text('Thời điểm chốt'), findsOneWidget);
      expect(find.text('Giá tạm'), findsOneWidget);
      expect(find.text('Không đổi'), findsNWidgets(2));
      expect(find.text('Xem 5 sản phẩm'), findsNothing);
    });

    testWidgets('blocked_390 shows banner, blocker actions, and LEDGER_MISMATCH',
        (tester) async {
      repository.getRunResult = _run(
        status: CostRunStatus.blocked,
        blockers: [
          CostBlocker(code: 'PREVIOUS_PERIOD_OPEN', periodMonth: DateTime(2026, 10, 1)),
          const CostBlocker(code: 'LEDGER_MISMATCH', productCount: 2),
        ],
      );
      String? navigated;
      await tester.pumpWidget(
        buildApp(
          runId: 'run-1',
          size: const Size(390, 844),
          onNavigate: (r) => navigated = r,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa công bố được'), findsOneWidget);
      expect(find.text('Xử lý 2 việc dưới đây rồi tính lại.'), findsOneWidget);
      expect(find.text('Chốt kỳ 10/2026'), findsOneWidget);
      expect(find.text('Liên hệ hỗ trợ; không tự sửa.'), findsOneWidget);
      expect(find.text('Tính lại'), findsOneWidget);

      await tester.tap(find.text('Chốt kỳ 10/2026'));
      await tester.pumpAndSettle();
      expect(navigated, '/warehouse/costing/new?kind=PERIOD_CLOSE');
    });

    testWidgets('publish_sheet_facts_and_confirm navigates to result',
        (tester) async {
      repository.publishResult = _run(status: CostRunStatus.published);
      String? navigated;
      await tester.pumpWidget(
        buildApp(
          runId: 'run-1',
          size: const Size(390, 844),
          onNavigate: (r) => navigated = r,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Công bố giá vốn'));
      await tester.pumpAndSettle();

      expect(find.text('Công bố giá vốn?'), findsOneWidget);
      expect(find.text('Kỳ ghi nhận'), findsOneWidget);

      await tester.tap(find.text('Công bố giá vốn').last);
      await tester.pumpAndSettle();

      expect(repository.publishCalls, 1);
      expect(navigated, '/warehouse/costing/runs/run-1/result');
    });

    testWidgets('publish_stale_shows_input_changed_390', (tester) async {
      repository.publishError = const AppException(
        InventoryErrorCode.costRunStale,
      );
      await tester.pumpWidget(buildApp(runId: 'run-1', size: const Size(390, 844)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Công bố giá vốn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công bố giá vốn').last);
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu đầu vào đã thay đổi'), findsOneWidget);
      expect(find.text('Tạo lần tính kế tiếp'), findsOneWidget);
    });

    testWidgets('compare_sheet_alt_totals opens compare sheet', (tester) async {
      await tester.pumpWidget(buildApp(runId: 'run-1', size: const Size(390, 844)));
      await tester.pumpAndSettle();

      final compareFinder = find.text('Xem đối chiếu theo Bình quân liên hoàn');
      await tester.ensureVisible(compareFinder);
      await tester.pumpAndSettle();
      await tester.tap(compareFinder);
      await tester.pumpAndSettle();

      expect(find.text('Đối chiếu theo Bình quân liên hoàn'), findsOneWidget);
      expect(find.text('Chỉ để đối chiếu; không dùng để công bố.'), findsOneWidget);
      expect(find.text('890.000 đ'), findsOneWidget);
      expect(find.text('740.000 đ'), findsOneWidget);
    });

    testWidgets('denied_390 renders InventoryDenied', (tester) async {
      repository.getRunError = const AppException(
        InventoryErrorCode.permissionDenied,
      );
      await tester.pumpWidget(buildApp(runId: 'run-1', size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn chưa có quyền tính và công bố giá vốn'),
        findsOneWidget,
      );
    });

    testWidgets('recalculate_from_blocked_replaces_url', (tester) async {
      repository.getRunResult = _run(
        runId: 'run-1',
        status: CostRunStatus.blocked,
        blockers: const [
          CostBlocker(code: 'LEDGER_MISMATCH', productCount: 2),
        ],
      );
      repository.createRunResult = _run(
        runId: 'run-2',
        status: CostRunStatus.readyForReview,
      );

      final navigated = <String>[];
      await tester.pumpWidget(
        buildApp(
          runId: 'run-1',
          size: const Size(390, 844),
          onNavigate: navigated.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tính lại'));
      await tester.pumpAndSettle();

      expect(navigated, contains('/warehouse/costing/runs/run-2'));
    });

    testWidgets('open_pending_run_navigates_to_run_id', (tester) async {
      repository.getRunResult = _run(
        runId: 'run-1',
        status: CostRunStatus.blocked,
        blockers: const [
          CostBlocker(
            code: 'RUN_PENDING_REVIEW',
            pendingRunId: 'run-pending-9',
          ),
        ],
      );

      final navigated = <String>[];
      await tester.pumpWidget(
        buildApp(
          runId: 'run-1',
          size: const Size(390, 844),
          onNavigate: navigated.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mở lần tính'));
      await tester.pumpAndSettle();

      expect(navigated, ['/warehouse/costing/runs/run-pending-9']);
    });

    testWidgets('superseded_shows_replaced_state', (tester) async {
      repository.getRunResult = _run(
        runId: 'run-1',
        status: CostRunStatus.superseded,
      );

      var wentBack = false;
      await tester.pumpWidget(
        buildApp(
          runId: 'run-1',
          size: const Size(390, 844),
          onBack: () => wentBack = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lần tính đã được thay'), findsOneWidget);
      expect(find.text('Về giá vốn'), findsOneWidget);

      await tester.tap(find.text('Về giá vốn'));
      await tester.pumpAndSettle();
      expect(wentBack, isTrue);
    });
  });
}
