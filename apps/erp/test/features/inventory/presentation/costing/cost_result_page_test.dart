import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/presentation/costing/cost_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeCostingRepository extends Fake implements CostingRepository {
  CostRunView? runResult;

  @override
  Future<CostRunView> getRun(String runId) async => runResult!;
}

CostRunView _run({required CostRunStatus status, DateTime? periodMonth}) {
  return CostRunView(
    runId: 'run-1',
    code: 'GV-2611-01',
    kind: CostRunKind.periodClose,
    periodMonth: periodMonth ?? DateTime(2026, 11, 1),
    status: status,
    method: CostMethod.periodic,
    fromSequence: 1,
    cutOffSequence: 20,
    cutOffAt: DateTime(2026, 11, 12, 14, 0),
    createdAt: DateTime(2026, 11, 12, 14, 0),
    publishedAt: DateTime(2026, 11, 12, 14, 5),
    blockers: const [],
    productCount: 10,
    changedCount: 4,
    totals: const CostTotals(
      closingValue: 880000,
      cogsValue: 750000,
      cogsAdjust: 15000,
      valueAdjust: -20000,
      balanceOk: true,
    ),
    alt: const CostAlt(
      method: CostMethod.moving,
      closingValue: 900000,
      cogsValue: 730000,
    ),
    lines: const [],
  );
}

void main() {
  late _FakeCostingRepository repository;

  setUp(() async {
    await GetIt.I.reset();
    repository = _FakeCostingRepository();
    GetIt.I.registerSingleton<CostingRepository>(repository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildApp({
    required Size size,
    VoidCallback? onToList,
    VoidCallback? onBack,
    ValueChanged<String>? onOpenReport,
  }) {
    useInventoryTestSurface(size);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
      home: CostResultPage(
        runId: 'run-1',
        onToList: onToList ?? () {},
        onBack: onBack,
        onOpenReport: onOpenReport ?? (_) {},
        clock: () => DateTime(2026, 11, 13),
      ),
    );
  }

  group('CostResultPage', () {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets(
        'result_completed_${size.width.toInt()} renders 6 facts and the three next actions',
        (tester) async {
          repository.runResult = _run(status: CostRunStatus.published);
          var wentToList = false;

          await tester.pumpWidget(
            buildApp(size: size, onToList: () => wentToList = true),
          );
          await tester.pumpAndSettle();

          expect(find.text('Đã công bố giá vốn 11/2026'), findsOneWidget);
          expect(find.text('Kỳ ghi nhận'), findsOneWidget);
          expect(find.text('11/2026'), findsOneWidget);
          expect(find.text('Phương pháp'), findsOneWidget);
          expect(find.text('Bình quân cuối kỳ'), findsOneWidget);
          expect(find.text('Sản phẩm có giá vốn mới'), findsOneWidget);
          expect(find.text('4'), findsOneWidget);
          expect(find.text('Điều chỉnh giá vốn xuất'), findsOneWidget);
          expect(find.text('+15.000 đ'), findsOneWidget);
          expect(find.text('Điều chỉnh giá trị tồn'), findsOneWidget);
          expect(find.text('−20.000 đ'), findsOneWidget);
          expect(find.text('Công bố lúc'), findsOneWidget);
          expect(find.text('12/11/2026 · 14:05'), findsOneWidget);

          expect(find.text('Về giá vốn'), findsOneWidget);
          expect(find.text('Xem báo cáo lãi gộp'), findsOneWidget);
          expect(find.text('Xem báo cáo tồn'), findsOneWidget);

          await tester.ensureVisible(find.text('Về giá vốn'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Về giá vốn'));
          await tester.pumpAndSettle();
          expect(wentToList, isTrue);
        },
      );
    }

    testWidgets('result_page_report_links', (tester) async {
      repository.runResult = _run(
        status: CostRunStatus.published,
        periodMonth: DateTime(2026, 10, 1),
      );
      final opened = <String>[];
      await tester.pumpWidget(
        buildApp(size: const Size(390, 844), onOpenReport: opened.add),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Xem báo cáo tồn'));
      await tester.tap(find.text('Xem báo cáo tồn'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xem báo cáo lãi gộp'));
      await tester.tap(find.text('Xem báo cáo lãi gộp'));
      await tester.pumpAndSettle();

      expect(opened, [
        '/warehouse/reports/stock?from=2026-10-01&to=2026-10-31',
        '/warehouse/reports/gross-profit?from=2026-10-01&to=2026-10-31',
      ]);
    });

    testWidgets('result_page_current_month_caps_at_today', (tester) async {
      repository.runResult = _run(status: CostRunStatus.published);
      final opened = <String>[];
      await tester.pumpWidget(
        buildApp(size: const Size(390, 844), onOpenReport: opened.add),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Xem báo cáo tồn'));
      await tester.tap(find.text('Xem báo cáo tồn'));
      await tester.pumpAndSettle();
      expect(opened.single, '/warehouse/reports/stock?from=2026-11-01&to=2026-11-13');
    });

    testWidgets(
      'result_rejected_when_not_published renders warning K4ResultPage',
      (tester) async {
        repository.runResult = _run(status: CostRunStatus.readyForReview);

        await tester.pumpWidget(buildApp(size: const Size(390, 844)));
        await tester.pumpAndSettle();

        expect(find.text('Chưa công bố giá vốn'), findsOneWidget);
        expect(
          find.text('Không có điều chỉnh hoặc phiên bản giá vốn mới.'),
          findsOneWidget,
        );
        expect(find.text('Kỳ ghi nhận'), findsOneWidget);
        expect(find.text('Về giá vốn'), findsOneWidget);
      },
    );

    testWidgets('result_page_back_button_triggers_on_back', (tester) async {
      repository.runResult = _run(status: CostRunStatus.published);
      var backed = false;

      await tester.pumpWidget(
        buildApp(
          size: const Size(390, 844),
          onBack: () => backed = true,
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(backed, isTrue);
    });

    testWidgets('result_page_back_button_fallback_to_on_to_list', (tester) async {
      repository.runResult = _run(status: CostRunStatus.published);
      var wentToList = false;

      await tester.pumpWidget(
        buildApp(
          size: const Size(390, 844),
          onToList: () => wentToList = true,
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(wentToList, isTrue);
    });
  });
}
