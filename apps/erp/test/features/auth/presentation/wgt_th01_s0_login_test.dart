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
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/testing.dart';
import 'package:vet45_shared_application/application.dart';

import '../../iam/support/scripted_iam_repositories.dart';

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
      expect(module.commands.first, isA<SignInTenantUserCommand>());
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

      expect(module.commandsOf<SignInTenantUserCommand>(), hasLength(1));
      expect(module.queriesOf<GetCurrentSessionQuery>(), hasLength(1));
      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.failure?.code, IamBlockedCodes.authenticationRequired);
      await cubit.close();
    },
  );

  test(
    'wgt_th01_s0_login_blocks_when_sign_in_has_no_active_membership',
    () async {
      final cubit = LoginCubit(iamModule: _NoActiveMembershipModule());

      await cubit.submit(email: 'lan@example.com', password: 'secret-123');

      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.failure?.code, IamBlockedCodes.noActiveMembership);
      expect(
        cubit.state.failure?.message,
        'Tài khoản chưa thuộc tổ chức nào đang hoạt động.',
      );
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
      expect(module.commands.first, isA<SignInTenantUserCommand>());
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
    'wgt_th01_s0_forgot_password_opens_public_reset_with_email',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.passwordResetByEmailOk),
      );
      final auth = RecordingAuthRepository();
      final cubit = LoginCubit(iamModule: module);
      addTearDown(cubit.close);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(cubit: cubit),
            routes: [
              GoRoute(
                path: 'reset-password',
                builder: (context, state) => ResetPasswordPage(
                  authRepository: auth,
                  requestEmail: state.extra as String? ?? '',
                ),
              ),
            ],
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
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Xác minh email'), findsOneWidget);
      expect(auth.calls, ['requestByEmail:lan@example.com']);
    },
  );

  testWidgets(
    'LoginPage displays organization name in success banner when showSuccessBanner is true (cubit branch)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = LoginCubit(
        iamModule: FakeIamModule(scenario: FakeIamScenario.authSignInOk),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: LoginPage(
              cubit: cubit,
              showSuccessBanner: true,
              organizationName: 'Mậu Hiên',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tham gia tổ chức thành công'), findsOneWidget);
      expect(
        find.text('Đã tham gia tổ chức "Mậu Hiên" thành công. Đăng nhập để vào VET45.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LoginPage displays organization name in success banner when showSuccessBanner is true (BlocProvider production branch)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: LoginPage(
              iamModule: FakeIamModule(scenario: FakeIamScenario.authSignInOk),
              showSuccessBanner: true,
              organizationName: 'Mậu Hiên',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tham gia tổ chức thành công'), findsOneWidget);
      expect(
        find.text('Đã tham gia tổ chức "Mậu Hiên" thành công. Đăng nhập để vào VET45.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LoginPage falls back to default message when organizationName is null',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: LoginPage(
              iamModule: FakeIamModule(scenario: FakeIamScenario.authSignInOk),
              showSuccessBanner: true,
              organizationName: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tham gia tổ chức thành công'), findsOneWidget);
      expect(
        find.text('Đã tham gia tổ chức thành công. Đăng nhập để vào VET45.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LoginPage falls back to default message when organizationName is empty string',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: LoginPage(
              iamModule: FakeIamModule(scenario: FakeIamScenario.authSignInOk),
              showSuccessBanner: true,
              organizationName: '   ',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tham gia tổ chức thành công'), findsOneWidget);
      expect(
        find.text('Đã tham gia tổ chức thành công. Đăng nhập để vào VET45.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LoginPage does not render success banner when showSuccessBanner is false',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: LoginPage(
              iamModule: FakeIamModule(scenario: FakeIamScenario.authSignInOk),
              showSuccessBanner: false,
              organizationName: 'Mậu Hiên',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tham gia tổ chức thành công'), findsNothing);
    },
  );
}

final class _NoActiveMembershipModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    throw const IamBlockedException(IamBlockedCodes.noActiveMembership);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    throw StateError('query should not run after sign-in failure');
  }
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
