import 'package:admin/features/organizations/presentation/pages/platform_onboarding_page.dart';
import 'package:admin/features/users/presentation/pages/platform_user_detail_page.dart';
import 'package:admin/features/users/presentation/pages/platform_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// e2e_e01_u01_fr01_01 — Admin platform users flow via Fake IIamModule.
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('list → detail loads user via IIamModule', (tester) async {
    final module = FakeIamModule(scenario: FakeIamScenario.usersSearchOk);
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IIamModule>(module);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: PlatformUsersPage(iamModule: module),
          ),
          routes: [
            GoRoute(
              path: 'users/:userId',
              name: 'user_detail',
              builder: (context, state) => PlatformUserDetailPage(
                userId: state.pathParameters['userId']!,
                iamModule: module,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Lê Thị Lan'), findsOneWidget);
    await tester.tap(find.text('Lê Thị Lan'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết người dùng'), findsOneWidget);
    expect(find.text('Thao tác'), findsOneWidget);
  });

  testWidgets('onboarding selects existing owner and advances to org step', (
    tester,
  ) async {
    final module = FakeIamModule(
      scenario: FakeIamScenario.onboardingExistingUserOk,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformOnboardingPage(iamModule: module),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(VSearchBar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lê Thị Lan').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tổ chức'), findsWidgets);
  });
}
