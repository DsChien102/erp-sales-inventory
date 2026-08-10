import 'package:admin/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  void registerDeps({
    required FakeIamModule iam,
    required FakePermissionChecker permissionChecker,
    required IamSession session,
  }) {
    getIt
      ..registerSingleton<IIamModule>(iam)
      ..registerSingleton<IPermissionChecker>(permissionChecker)
      ..registerSingleton<IamSession>(session)
      ..registerSingleton<ICurrentUser>(session)
      ..registerSingleton<IExecutionContext>(FakeExecutionContext());
  }

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = getIt<ICurrentUser>().userId != null;
        final isLoginRoute = state.matchedLocation == '/login';
        if (!isAuthenticated && !isLoginRoute) return '/login';
        if (isAuthenticated && isLoginRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('admin-home')),
        ),
      ],
    );
    return MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router);
  }

  testWidgets('shows Admin branding', (tester) async {
    final session = IamSession();
    registerDeps(
      iam: FakeIamModule(scenario: FakeIamScenario.authSignInOk),
      permissionChecker: FakePermissionChecker(),
      session: session,
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Nền tảng quản trị'), findsOneWidget);
    expect(find.text('© VET45 · Admin'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('successful sign-in navigates home', (tester) async {
    final session = IamSession();
    final iam = FakeIamModule(
      scenario: FakeIamScenario.authSignInOk,
      onSignedIn: (_) {
        session.applyAuthenticatedUser('admin-1');
      },
    );
    registerDeps(
      iam: iam,
      permissionChecker: FakePermissionChecker(),
      session: session,
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'admin@vet45.local');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.pump();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('admin-home'), findsOneWidget);
    expect(iam.signInCount, 1);
    expect(iam.lastSignInRequireTenantContext, isFalse);
  });

  testWidgets('invalid credentials show failure toast', (tester) async {
    final session = IamSession();
    registerDeps(
      iam: FakeIamModule(scenario: FakeIamScenario.authInvalid),
      permissionChecker: FakePermissionChecker(),
      session: session,
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'bad@x.y');
    await tester.enterText(find.byType(TextField).at(1), 'nope');
    await tester.pump();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Invalid login'), findsOneWidget);
    expect(find.text('admin-home'), findsNothing);
  });

  testWidgets('non-platform admin is signed out with message', (tester) async {
    final session = IamSession();
    final iam = FakeIamModule(
      scenario: FakeIamScenario.authSignInOk,
      onSignedIn: (_) {
        session.apply(
          const PrincipalAccessDto(
            userId: 'tenant-user',
            tenantId: 't-1',
            role: 'staff',
            isOwner: false,
            permissions: [],
          ),
        );
      },
      onSignedOut: session.clear,
    );
    registerDeps(
      iam: iam,
      permissionChecker: FakePermissionChecker(
        deny: {IamPlatformPermissions.userView},
      ),
      session: session,
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@tenant.local');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.pump();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Platform Admin'), findsOneWidget);
    expect(iam.signOutCount, 1);
    expect(session.userId, isNull);
    expect(find.text('admin-home'), findsNothing);
  });
}
