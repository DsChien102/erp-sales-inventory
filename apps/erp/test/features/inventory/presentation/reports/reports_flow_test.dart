import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_area_page.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';
import 'package:erp/features/inventory/presentation/reports/reports_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';
import 'reports_test_support.dart';

void main() {
  late FakeReportsRepository repo;

  setUp(() async {
    await GetIt.I.reset();
    repo = FakeReportsRepository()
      ..stockReportResult = stockReportOf([stockRow()])
      ..stockCardResult = stockCardOf(lotTracked: false)
      ..movementResult = movementDetailOf();
    GetIt.I.registerSingleton<ReportsRepository>(repo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('reports_flow: Hub -> 055 -> thẻ kho -> 056 -> Mở phiếu gốc', (
    tester,
  ) async {
    useInventoryTestSurface(const Size(390, 844));
    final router = GoRouter(
      initialLocation: '/warehouse/area/history',
      routes: [
        GoRoute(
          path: '/warehouse',
          builder: (_, _) => const Scaffold(body: Text('HUB')),
        ),
        GoRoute(
          path: '/warehouse/area/history',
          builder: (_, _) => const WarehouseAreaPage(
            area: WarehouseArea.history,
            isOwner: true,
          ),
        ),
        GoRoute(
          path: '/warehouse/receipts/:id',
          builder: (_, state) =>
              Scaffold(body: Text('RECEIPT:${state.pathParameters['id']}')),
        ),
        ...reportsRoutes(),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    // Hub -> báo cáo
    await tester.tap(find.text('Báo cáo tồn & thẻ kho'));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo nhập – xuất – tồn'), findsOneWidget);
    expect(find.text('Vắc xin Dại'), findsOneWidget);

    // dòng sản phẩm -> thẻ kho
    await tester.tap(find.text('Vắc xin Dại'));
    await tester.pumpAndSettle();
    expect(find.text('Thẻ kho'), findsOneWidget);
    expect(find.text('Nhận hàng PN-260904-08'), findsOneWidget);

    // dòng nhận hàng -> 056
    await tester.tap(find.text('Nhận hàng PN-260904-08'));
    await tester.pumpAndSettle();
    expect(repo.movementIds, ['m1']);
    expect(find.text('Mở phiếu gốc'), findsOneWidget);

    // Mở phiếu gốc -> màn phiếu nhận
    await tester.tap(find.text('Mở phiếu gốc'));
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT:r1'), findsOneWidget);
  });

  testWidgets('reports_routes: gross profit route reads mode and period from query', (
    tester,
  ) async {
    useInventoryTestSurface(const Size(390, 844));
    repo
      ..grossProductResult = grossProductOf()
      ..grossOrderResult = grossOrderOf();
    final router = GoRouter(
      initialLocation:
          '/warehouse/reports/gross-profit?from=2026-10-01&to=2026-10-31&mode=ORDER',
      routes: [...reportsRoutes()],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(repo.grossPeriods, hasLength(1));
    expect(repo.grossPeriods.single.from, DateTime(2026, 10, 1));
    expect(repo.grossPeriods.single.to, DateTime(2026, 10, 31));
    expect(find.text('DH-0001'), findsOneWidget);
  });
}
