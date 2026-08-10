import 'package:erp/features/auth/presentation/bloc/login_cubit.dart';
import 'package:erp/features/auth/presentation/bloc/login_state.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    appRouter.go('/login');
    await getIt.reset();
  });

  test(
    'wgt_th01_s0_login_session_sequence submits sign-in then queries the session snapshot',
    () async {
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.authSignInOk),
      );
      final cubit = LoginCubit(iamModule: module);

      await cubit.submit(email: 'lan@example.com', password: 'secret-123');

      expect(module.commands, hasLength(1));
      expect(module.commands.first, isA<SignInCommand>());
      expect(module.queries, hasLength(1));
      expect(module.queries.first, isA<GetCurrentSessionQuery>());
      expect(cubit.state.status, LoginStatus.success);
      expect(cubit.state.session?.isAuthenticated, isTrue);
      await cubit.close();
    },
  );

  test(
    'wgt_th01_s0_login_session_sequence keeps failure when session is unauthenticated',
    () async {
      final module = RecordingIamModule(
        _UnauthenticatedAfterSignInModule(),
      );
      final cubit = LoginCubit(iamModule: module);

      await cubit.submit(email: 'lan@example.com', password: 'secret-123');

      expect(module.commandsOf<SignInCommand>(), hasLength(1));
      expect(module.queriesOf<GetCurrentSessionQuery>(), hasLength(1));
      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.failure?.code, IamBlockedCodes.authenticationRequired);
      await cubit.close();
    },
  );

  testWidgets(
    'wgt_th01_s0_login_session_sequence navigates only after authenticated session',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.authSignInOk),
      );
      final cubit = LoginCubit(iamModule: module);
      addTearDown(cubit.close);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(cubit: cubit),
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

      await tester.enterText(find.byType(TextField).first, 'lan@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret-123');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('HOME_OK'), findsOneWidget);
      expect(module.commands.first, isA<SignInCommand>());
      expect(module.queries.first, isA<GetCurrentSessionQuery>());
    },
  );

  testWidgets(
    'wgt_th01_s0_login_activation_link_opens_invitation',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = LoginCubit(
        iamModule: FakeIamModule(scenario: FakeIamScenario.authSignInOk),
      );
      addTearDown(cubit.close);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(cubit: cubit),
          ),
          GoRoute(
            path: '/owner-activation',
            builder: (context, state) => const Scaffold(body: Text('OWNER_ACTIVATION_ROUTE')),
          ),
          GoRoute(
            path: '/invitation',
            builder: (context, state) => const Scaffold(body: Text('INVITATION_ROUTE')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('Kích hoạt tài khoản'));
      await tester.pumpAndSettle();

      expect(find.text('INVITATION_ROUTE'), findsOneWidget);
      expect(find.text('OWNER_ACTIVATION_ROUTE'), findsNothing);
    },
  );

  testWidgets(
    'wgt_th01_s0_owner_activation_redirects_to_login_until_defined',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      getIt
        ..registerSingleton<ICurrentUser>(_NoCurrentUser())
        ..registerSingleton<IIamModule>(
          FakeIamModule(scenario: FakeIamScenario.authSignInOk),
        );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/owner-activation');
      await tester.pumpAndSettle();

      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        '/login',
      );
    },
  );
}

final class _UnauthenticatedAfterSignInModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    return null as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return const SessionDto(isAuthenticated: false) as TResult;
  }
}

final class _NoCurrentUser implements ICurrentUser {
  @override
  String? get userId => null;
}
