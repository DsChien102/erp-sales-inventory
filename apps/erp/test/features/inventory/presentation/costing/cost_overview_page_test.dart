import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/presentation/costing/cost_overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeCostingRepository extends Fake implements CostingRepository {
  CostOverview? overviewResult;
  Object? overviewError;
  Object? setPolicyError;
  final List<CostMethod> setPolicyCalls = [];
  int getOverviewCalls = 0;

  @override
  Future<CostOverview> overview() async {
    getOverviewCalls++;
    final error = overviewError;
    if (error != null) throw error;
    return overviewResult!;
  }

  @override
  Future<({CostMethod method, bool methodLocked})> setPolicy({
    required String idempotencyKey,
    required CostMethod method,
  }) async {
    setPolicyCalls.add(method);
    final error = setPolicyError;
    if (error != null) throw error;
    overviewResult = CostOverview(
      method: method,
      methodLocked: overviewResult?.methodLocked ?? false,
      openPeriod: overviewResult?.openPeriod,
      periodToClose: overviewResult?.periodToClose,
      hasPendingRun: overviewResult?.hasPendingRun ?? false,
      runs: overviewResult?.runs ?? const [],
    );
    return (method: method, methodLocked: overviewResult!.methodLocked);
  }
}

void main() {
  late _FakeCostingRepository repository;

  final readyRow = CostRunRow(
    runId: 'run-ready-1',
    code: 'GV-2611-01',
    kind: CostRunKind.midPeriod,
    periodMonth: DateTime(2026, 11, 1),
    status: CostRunStatus.readyForReview,
    productCount: 12,
    blockerCount: 0,
    valueAdjustVnd: 50400,
    publishedAt: null,
    createdAt: DateTime(2026, 11, 12, 9, 0),
  );

  final blockedRow = CostRunRow(
    runId: 'run-blocked-1',
    code: 'GV-2611-02',
    kind: CostRunKind.periodClose,
    periodMonth: DateTime(2026, 11, 1),
    status: CostRunStatus.blocked,
    productCount: 12,
    blockerCount: 2,
    valueAdjustVnd: null,
    publishedAt: null,
    createdAt: DateTime(2026, 11, 12, 10, 0),
  );

  final publishedRow = CostRunRow(
    runId: 'run-pub-1',
    code: 'GV-2610-01',
    kind: CostRunKind.periodClose,
    periodMonth: DateTime(2026, 10, 1),
    status: CostRunStatus.published,
    productCount: 10,
    blockerCount: 0,
    valueAdjustVnd: -25000,
    publishedAt: DateTime(2026, 11, 1, 8, 0),
    createdAt: DateTime(2026, 11, 1, 7, 30),
  );

  CostOverview buildOverview({
    CostMethod method = CostMethod.moving,
    bool methodLocked = false,
    DateTime? periodToClose,
    bool hasPendingRun = false,
    List<CostRunRow>? runs,
  }) {
    return CostOverview(
      method: method,
      methodLocked: methodLocked,
      openPeriod: DateTime(2026, 11, 1),
      periodToClose: periodToClose,
      hasPendingRun: hasPendingRun,
      runs: runs ?? [readyRow, blockedRow, publishedRow],
    );
  }

  setUp(() async {
    await GetIt.I.reset();
    repository = _FakeCostingRepository()..overviewResult = buildOverview();
    GetIt.I.registerSingleton<CostingRepository>(repository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildApp({
    Size size = const Size(390, 844),
    ValueChanged<CostRunRow>? onOpenRun,
    ValueChanged<CostRunKind>? onCreateRun,
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
      home: CostOverviewPage(
        onOpenRun: onOpenRun ?? (_) {},
        onCreateRun: onCreateRun ?? (_) {},
        onBack: onBack ?? () {},
      ),
    );
  }

  group('CostOverviewPage', () {
    testWidgets('overview_ready_390 renders mobile layout, chips, and badges', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.text('Giá vốn'), findsOneWidget);
      expect(find.text('Chính sách: Bình quân liên hoàn'), findsOneWidget);
      expect(find.text('Đổi'), findsOneWidget);
      expect(find.text('Cần làm'), findsOneWidget);
      expect(find.text('Đã công bố'), findsOneWidget);
      expect(find.text('Cập nhật giá vốn 11/2026'), findsOneWidget);
      expect(find.text('Chốt kỳ 11/2026'), findsOneWidget);
      expect(find.text('Sẵn sàng công bố'), findsOneWidget);
      expect(find.text('Cần xử lý'), findsOneWidget);
      expect(find.text('Cập nhật giữa kỳ'), findsOneWidget);
    });

    testWidgets('overview_ready_1280 renders 5-column table', (tester) async {
      await tester.pumpWidget(buildApp(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('LẦN TÍNH'), findsOneWidget);
      expect(find.text('KỲ'), findsOneWidget);
      expect(find.text('PHẠM VI'), findsOneWidget);
      expect(find.text('CHÊNH LỆCH SẼ GHI'), findsOneWidget);
      expect(find.text('TÌNH TRẠNG'), findsOneWidget);
      expect(find.text('Toàn bộ sản phẩm'), findsNWidgets(2));
      expect(find.text('+50.400 đ'), findsOneWidget);
    });

    testWidgets(
      'overview_close_footer shows period close primary CTA when periodToClose != null',
      (tester) async {
        repository.overviewResult = buildOverview(
          periodToClose: DateTime(2026, 10, 1),
          hasPendingRun: false,
        );

        CostRunKind? createdKind;
        await tester.pumpWidget(
          buildApp(
            size: const Size(390, 844),
            onCreateRun: (k) => createdKind = k,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cập nhật giữa kỳ'), findsOneWidget);
        expect(find.text('Chốt kỳ 10/2026'), findsOneWidget);

        await tester.tap(find.text('Chốt kỳ 10/2026'));
        await tester.pumpAndSettle();
        expect(createdKind, CostRunKind.periodClose);
      },
    );

    testWidgets(
      'overview_change_hidden_when_locked hides Đổi button when methodLocked',
      (tester) async {
        repository.overviewResult = buildOverview(methodLocked: true);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Đổi'), findsNothing);
      },
    );

    testWidgets('method_sheet_saves opens sheet, selects periodic, and saves', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đổi'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn phương pháp giá vốn'), findsOneWidget);
      expect(
        find.text('Chỉ đổi được trước lần công bố giá vốn đầu tiên.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Bình quân cuối kỳ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(repository.setPolicyCalls, [CostMethod.periodic]);
      expect(find.text('Chọn phương pháp giá vốn'), findsNothing);
      expect(find.text('Chính sách: Bình quân cuối kỳ'), findsOneWidget);
    });

    testWidgets('overview_empty renders empty state copy', (tester) async {
      repository.overviewResult = buildOverview(runs: const []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Không có công việc giá vốn'), findsOneWidget);
      expect(
        find.text('Chưa có phạm vi cần cập nhật hoặc chốt kỳ.'),
        findsOneWidget,
      );
    });

    testWidgets('overview_denied_390 renders InventoryDenied on forbidden', (
      tester,
    ) async {
      repository.overviewError = const AppException(
        InventoryErrorCode.permissionDenied,
      );

      var exited = false;
      await tester.pumpWidget(buildApp(onBack: () => exited = true));
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa có quyền xem giá vốn'), findsOneWidget);
      expect(
        find.text('Chỉ chủ cửa hàng xem và công bố giá vốn.'),
        findsOneWidget,
      );
      expect(find.text('Về Kho'), findsOneWidget);

      await tester.tap(find.text('Về Kho'));
      await tester.pumpAndSettle();
      expect(exited, isTrue);
    });

    testWidgets(
      'open_published_goes_result navigates to /result for published run',
      (tester) async {
        useInventoryTestSurface(const Size(390, 844));
        String? navigatedLocation;
        final router = GoRouter(
          initialLocation: '/warehouse/costing',
          routes: [
            GoRoute(
              path: '/warehouse/costing',
              builder: (_, _) => const CostOverviewPage(),
            ),
            GoRoute(
              path: '/warehouse/costing/runs/:id/result',
              builder: (_, state) {
                navigatedLocation = state.uri.toString();
                return const Scaffold(body: Text('Result Page'));
              },
            ),
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

        await tester.tap(find.text('Đã công bố'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chốt kỳ 10/2026'));
        await tester.pumpAndSettle();

        expect(
          navigatedLocation,
          '/warehouse/costing/runs/${publishedRow.runId}/result',
        );
      },
    );

    testWidgets(
      'period_close_passes_period_query_param to /warehouse/costing/new',
      (tester) async {
        repository.overviewResult = buildOverview(
          periodToClose: DateTime(2026, 10, 1),
          hasPendingRun: false,
        );
        useInventoryTestSurface(const Size(390, 844));
        String? navigatedLocation;
        final router = GoRouter(
          initialLocation: '/warehouse/costing',
          routes: [
            GoRoute(
              path: '/warehouse/costing',
              builder: (_, _) => const CostOverviewPage(),
            ),
            GoRoute(
              path: '/warehouse/costing/new',
              builder: (_, state) {
                navigatedLocation = state.uri.toString();
                return const Scaffold(body: Text('New Run Page'));
              },
            ),
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

        await tester.tap(find.text('Chốt kỳ 10/2026'));
        await tester.pumpAndSettle();

        expect(
          navigatedLocation,
          '/warehouse/costing/new?kind=PERIOD_CLOSE&period=2026-10',
        );
      },
    );
  });
}
