import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/features/dashboard/presentation/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// e2e_th01_s0_session — sign-in → session query → dashboard (S0).
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> setPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'e2e_th01_s0_session: sign in then session query opens dashboard',
    (tester) async {
      await setPhone(tester);

      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.authSignInOk),
      );
      getIt
        ..registerSingleton<IExecutionContext>(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(iamModule: module),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => DashboardPage(
              iamModule: module,
              autoBootstrap: true,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'lan@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret-123');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      expect(module.commandsOf<SignInCommand>(), hasLength(1));
      expect(module.queriesOf<GetCurrentSessionQuery>(), hasLength(1));
      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_th01_s0_session: invalid credentials stay on login',
    (tester) async {
      await setPhone(tester);

      final module = FakeIamModule(scenario: FakeIamScenario.authInvalid);
      getIt
        ..registerSingleton<IExecutionContext>(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(iamModule: module),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('HOME_OK')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'bad@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('HOME_OK'), findsNothing);
      expect(find.text('Đăng nhập'), findsWidgets);
    },
  );
}
