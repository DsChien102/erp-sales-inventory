import 'package:erp/features/dashboard/presentation/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../../dashboard/presentation/ready_default_pair_inventory_module.dart';
import '../../../core/session/fake_session_repository.dart';

/// e2e_e05_u01/u02/u03 — ERP tenant context via FakeIamModule (Group A).
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<IInventoryModule>(
      const ReadyDefaultPairInventoryModule(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  void registerModule(FakeIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IIamModule>(module);
  }

  Widget wrap(FakeSessionRepository repository) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DashboardPage(
            repository: repository,
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

    final repository = FakeSessionRepository(scenario: FakeIamScenario.bootstrapValid);
    registerModule(FakeIamModule(scenario: repository.scenario));

    await tester.pumpWidget(wrap(repository));
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

    final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti);
    registerModule(FakeIamModule(scenario: repository.scenario));

    await tester.pumpWidget(wrap(repository));
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

    final repository = FakeSessionRepository(scenario: FakeIamScenario.switchOk);
    registerModule(FakeIamModule(scenario: repository.scenario));

    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    await openSelectorFromHeader(tester);
    await tester.tap(find.text('Phòng khám Minh Tâm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển tổ chức'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.textContaining('Phòng khám Minh Tâm'), findsWidgets);
    expect(repository.lastSelectedTenantId, 'org-002');
    expect(find.textContaining('Đã chuyển sang'), findsOneWidget);
  });

  testWidgets('e2e_e05_u03_fr01_01: bootstrap none → blocked + selector CTA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeSessionRepository(scenario: FakeIamScenario.contextNone);
    registerModule(FakeIamModule(scenario: repository.scenario));

    await tester.pumpWidget(wrap(repository));
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

    final repository = FakeSessionRepository(scenario: FakeIamScenario.switchSuspended);
    registerModule(FakeIamModule(scenario: repository.scenario));

    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    await openSelectorFromHeader(tester);

    expect(find.text('ASC Commerce'), findsWidgets);
    await tester.tap(find.text('ASC Commerce').first);
    await tester.pumpAndSettle();
    expect(find.text('Chọn tổ chức'), findsOneWidget);
    expect(find.textContaining('Chuyển sang ASC'), findsNothing);
    expect(repository.switchCount, 0);
  });

  testWidgets('e2e_e05_u01_fr01_03: closed tenant badge and not tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeSessionRepository(scenario: FakeIamScenario.tenantsClosedDisabled);
    registerModule(FakeIamModule(scenario: repository.scenario));

    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    await openSelectorFromHeader(tester);

    expect(find.text('Closed Clinic'), findsOneWidget);
    expect(find.textContaining('Đã đóng'), findsOneWidget);
    await tester.tap(find.text('Closed Clinic'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chuyển sang'), findsNothing);
    expect(repository.switchCount, 0);
  });
}
