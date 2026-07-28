import 'package:erp/features/dashboard/presentation/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// e2e_e05_u01/u02/u03 — ERP tenant context via FakeIamModule (Group A).
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  void registerModule(FakeIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IIamModule>(module);
  }

  Widget wrap(FakeIamModule module) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DashboardPage(
            iamModule: module,
            autoBootstrap: true,
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> openSelectorFromHeader(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.storefront_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Chọn tổ chức'), findsOneWidget);
  }

  testWidgets('e2e_e05_u01_fr01_01: bootstrap valid → header shows tenant', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.bootstrapValid);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thú y Minh Phát'), findsWidgets);
    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
  });

  testWidgets('e2e_e05_u01_fr01_02: open selector → multi tenants', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.tenantsMulti);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await openSelectorFromHeader(tester);

    expect(find.text('Chọn tổ chức'), findsOneWidget);
    expect(find.text('Phòng khám Minh Tâm'), findsOneWidget);
    expect(find.text('ASC Commerce'), findsOneWidget);
  });

  testWidgets('e2e_e05_u02_fr01_01: switch tenant → header updates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.switchOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await openSelectorFromHeader(tester);
    await tester.tap(find.text('Phòng khám Minh Tâm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển tổ chức'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.textContaining('Phòng khám Minh Tâm'), findsWidgets);
    expect(module.currentTenantId, 'org-002');
    expect(find.textContaining('Đã chuyển sang'), findsOneWidget);
  });

  testWidgets('e2e_e05_u03_fr01_01: bootstrap none → blocked + selector CTA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.bootstrapNone);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có tổ chức được cấp quyền'), findsOneWidget);
    expect(find.text('Kiểm tra lại'), findsOneWidget);

    await tester.tap(find.text('Kiểm tra lại'));
    await tester.pumpAndSettle();

    // Header placeholder + sheet title both say "Chọn tổ chức".
    expect(find.text('Chọn tổ chức'), findsWidgets);
    expect(find.text('Thú y Minh Phát'), findsOneWidget);
  });

  testWidgets('e2e_e05_u02_fr01_02: switch suspended → reject', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.switchSuspended);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await openSelectorFromHeader(tester);

    expect(find.text('ASC Commerce'), findsWidgets);
    await tester.tap(find.text('ASC Commerce').first);
    await tester.pumpAndSettle();
    expect(find.text('Chọn tổ chức'), findsOneWidget);
    expect(find.textContaining('Chuyển sang ASC'), findsNothing);
    expect(module.switchTenantCount, 0);
  });
}
