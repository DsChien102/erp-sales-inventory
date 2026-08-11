import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// e2e_e01_u04/u05 — readiness + activate (S11).
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget wrapReadiness({
    required IIamModule module,
    required String tenantId,
  }) {
    final router = GoRouter(
      initialLocation: '/more/readiness',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('DASHBOARD')),
        ),
        GoRoute(
          path: '/more/readiness',
          builder: (context, state) => TenantReadinessPage(
            iamModule: module,
            executionContext: FakeExecutionContext(tenantId: tenantId),
            keyFactory: FakeIdempotencyKeyFactory(),
            canActivateTenant: true,
          ),
        ),
      ],
    );
    return MaterialApp.router(
      theme: VTheme.lightTheme,
      routerConfig: router,
    );
  }

  testWidgets(
    'e2e_e01_u05_fr01_01: readiness warning-only → activate via IIamModule',
    (tester) async {
      await phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.readinessWarningOnly),
      );
      getIt
        ..registerSingleton<IExecutionContext>(
          FakeExecutionContext(tenantId: 'org-002'),
        )
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        wrapReadiness(module: module, tenantId: 'org-002'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_activate_tenant')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_activate_tenant')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Kích hoạt'));
      await tester.pumpAndSettle();

      expect(module.commandsOf<ActivateTenantCommand>(), hasLength(1));
      expect(find.text('DASHBOARD'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u05_fr01_02: readiness blocked hides activate CTA',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(scenario: FakeIamScenario.readinessBlocked);
      getIt
        ..registerSingleton<IExecutionContext>(
          FakeExecutionContext(tenantId: 'org-001'),
        )
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        wrapReadiness(module: module, tenantId: 'org-001'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_activate_tenant')), findsNothing);
      expect(find.byKey(const Key('btn_complete_tenant_setup')), findsOneWidget);
      expect(find.text('Thiếu thông tin'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u05_fr01_03: activateReadinessBlocked keeps page wired',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.activateReadinessBlocked,
      );
      getIt
        ..registerSingleton<IExecutionContext>(
          FakeExecutionContext(tenantId: 'org-002'),
        )
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        wrapReadiness(module: module, tenantId: 'org-002'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('kích hoạt'), findsWidgets);
    },
  );
}
